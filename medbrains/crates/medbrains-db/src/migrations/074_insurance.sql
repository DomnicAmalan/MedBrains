-- Migration 074: Insurance & TPA Module
-- Eligibility verification, prior authorization, appeals, PA rules

-- ══════════════════════════════════════════════════════════
--  Enums
-- ══════════════════════════════════════════════════════════

CREATE TYPE verification_status AS ENUM (
    'pending', 'active', 'inactive', 'unknown', 'error'
);

CREATE TYPE prior_auth_status AS ENUM (
    'draft', 'pending_info', 'submitted', 'in_review',
    'approved', 'partially_approved', 'denied', 'expired', 'cancelled'
);

CREATE TYPE pa_urgency AS ENUM (
    'standard', 'urgent', 'retrospective'
);

CREATE TYPE appeal_status AS ENUM (
    'draft', 'submitted', 'in_review', 'upheld', 'overturned', 'withdrawn'
);

-- ══════════════════════════════════════════════════════════
--  Table 1: insurance_verifications (immutable/append-only)
-- ══════════════════════════════════════════════════════════

CREATE TABLE insurance_verifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    patient_insurance_id UUID NOT NULL REFERENCES patient_insurance(id),

    -- Trigger context
    trigger_point   TEXT NOT NULL,  -- scheduling / check_in / admission / manual
    trigger_entity_id UUID,

    -- Verification result
    status          verification_status NOT NULL DEFAULT 'pending',
    verified_at     TIMESTAMPTZ,

    -- Payer info snapshot
    payer_name      TEXT,
    payer_id        TEXT,
    member_id       TEXT,
    group_number    TEXT,
    subscriber_name TEXT,
    relationship_to_subscriber TEXT,

    -- Coverage dates
    coverage_start  DATE,
    coverage_end    DATE,

    -- Benefits breakdown
    benefits        JSONB,

    -- Financial details
    individual_deductible       NUMERIC(12,2),
    individual_deductible_met   NUMERIC(12,2),
    family_deductible           NUMERIC(12,2),
    family_deductible_met       NUMERIC(12,2),
    co_pay_percent              NUMERIC(5,2),
    co_insurance_percent        NUMERIC(5,2),
    out_of_pocket_max           NUMERIC(12,2),
    out_of_pocket_met           NUMERIC(12,2),

    -- Scheme
    scheme_type     insurance_scheme_type,
    scheme_balance  NUMERIC(14,2),

    -- Error info
    error_code      TEXT,
    error_message   TEXT,
    raw_response    JSONB,

    -- Audit
    notes           TEXT,
    verified_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
    -- No updated_at: immutable/append-only
);

CREATE INDEX idx_verifications_tenant ON insurance_verifications(tenant_id);
CREATE INDEX idx_verifications_patient ON insurance_verifications(tenant_id, patient_id);
CREATE INDEX idx_verifications_status ON insurance_verifications(tenant_id, status);
CREATE INDEX idx_verifications_created ON insurance_verifications(tenant_id, created_at DESC);

ALTER TABLE insurance_verifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY insurance_verifications_rls ON insurance_verifications
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Table 2: prior_auth_requests
-- ══════════════════════════════════════════════════════════

CREATE TABLE prior_auth_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    pa_number       TEXT NOT NULL,

    -- Patient & insurance
    patient_id      UUID NOT NULL REFERENCES patients(id),
    patient_insurance_id UUID NOT NULL REFERENCES patient_insurance(id),

    -- Service details
    service_type    TEXT NOT NULL,
    service_code    TEXT,
    service_description TEXT,
    diagnosis_codes TEXT[],

    -- Context links
    ordering_doctor_id UUID REFERENCES users(id),
    department_id   UUID REFERENCES departments(id),
    encounter_id    UUID,
    invoice_id      UUID REFERENCES invoices(id),
    insurance_claim_id UUID REFERENCES insurance_claims(id),

    -- Status & urgency
    status          prior_auth_status NOT NULL DEFAULT 'draft',
    urgency         pa_urgency NOT NULL DEFAULT 'standard',

    -- Request details
    requested_start DATE,
    requested_end   DATE,
    requested_units INT,
    estimated_cost  NUMERIC(12,2),

    -- Payer response
    auth_number     TEXT,
    approved_start  DATE,
    approved_end    DATE,
    approved_units  INT,
    approved_amount NUMERIC(12,2),

    -- Denial info
    denial_reason   TEXT,
    denial_code     TEXT,

    -- Tracking
    submitted_at    TIMESTAMPTZ,
    responded_at    TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    expected_tat_hours INT,
    escalated       BOOLEAN NOT NULL DEFAULT false,
    escalated_at    TIMESTAMPTZ,

    -- Audit
    created_by      UUID REFERENCES users(id),
    submitted_by    UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_pa_number UNIQUE (tenant_id, pa_number)
);

CREATE INDEX idx_pa_tenant ON prior_auth_requests(tenant_id);
CREATE INDEX idx_pa_patient ON prior_auth_requests(tenant_id, patient_id);
CREATE INDEX idx_pa_status ON prior_auth_requests(tenant_id, status);
CREATE INDEX idx_pa_created ON prior_auth_requests(tenant_id, created_at DESC);
CREATE INDEX idx_pa_expires ON prior_auth_requests(tenant_id, expires_at)
    WHERE expires_at IS NOT NULL;

ALTER TABLE prior_auth_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY prior_auth_requests_rls ON prior_auth_requests
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER trg_prior_auth_requests_updated
    BEFORE UPDATE ON prior_auth_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  Table 3: prior_auth_documents (immutable)
-- ══════════════════════════════════════════════════════════

CREATE TABLE prior_auth_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    prior_auth_id   UUID NOT NULL REFERENCES prior_auth_requests(id) ON DELETE CASCADE,

    document_type   TEXT NOT NULL,
    file_name       TEXT,
    file_path       TEXT,
    file_size_bytes BIGINT,
    mime_type       TEXT,

    -- Inline clinical data snapshot
    content_text    TEXT,
    content_json    JSONB,

    -- Source entity for auto-attach
    source_entity   TEXT,
    source_id       UUID,

    -- Audit
    uploaded_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
    -- No updated_at: immutable
);

CREATE INDEX idx_pa_docs_tenant ON prior_auth_documents(tenant_id);
CREATE INDEX idx_pa_docs_pa ON prior_auth_documents(prior_auth_id);

ALTER TABLE prior_auth_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY prior_auth_documents_rls ON prior_auth_documents
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Table 4: prior_auth_status_log (append-only audit)
-- ══════════════════════════════════════════════════════════

CREATE TABLE prior_auth_status_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    prior_auth_id   UUID NOT NULL REFERENCES prior_auth_requests(id) ON DELETE CASCADE,

    from_status     prior_auth_status,
    to_status       prior_auth_status NOT NULL,
    notes           TEXT,
    changed_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
    -- No updated_at: append-only
);

CREATE INDEX idx_pa_log_tenant ON prior_auth_status_log(tenant_id);
CREATE INDEX idx_pa_log_pa ON prior_auth_status_log(prior_auth_id);

ALTER TABLE prior_auth_status_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY prior_auth_status_log_rls ON prior_auth_status_log
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Table 5: prior_auth_appeals
-- ══════════════════════════════════════════════════════════

CREATE TABLE prior_auth_appeals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    prior_auth_id   UUID NOT NULL REFERENCES prior_auth_requests(id),
    appeal_number   TEXT NOT NULL,

    level           INT NOT NULL DEFAULT 1,
    status          appeal_status NOT NULL DEFAULT 'draft',

    -- Content
    reason          TEXT,
    clinical_rationale TEXT,
    supporting_evidence TEXT,
    letter_content  TEXT,

    -- Payer response
    payer_decision  TEXT,
    payer_response_date DATE,
    payer_notes     TEXT,

    -- Tracking
    submitted_at    TIMESTAMPTZ,
    resolved_at     TIMESTAMPTZ,
    deadline        DATE,

    -- Audit
    created_by      UUID REFERENCES users(id),
    submitted_by    UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_appeal_number UNIQUE (tenant_id, appeal_number)
);

CREATE INDEX idx_appeals_tenant ON prior_auth_appeals(tenant_id);
CREATE INDEX idx_appeals_pa ON prior_auth_appeals(prior_auth_id);
CREATE INDEX idx_appeals_status ON prior_auth_appeals(tenant_id, status);

ALTER TABLE prior_auth_appeals ENABLE ROW LEVEL SECURITY;
CREATE POLICY prior_auth_appeals_rls ON prior_auth_appeals
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER trg_prior_auth_appeals_updated
    BEFORE UPDATE ON prior_auth_appeals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  Table 6: pa_requirement_rules
-- ══════════════════════════════════════════════════════════

CREATE TABLE pa_requirement_rules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    rule_name       TEXT NOT NULL,
    description     TEXT,

    -- Match criteria (NULL = all)
    insurance_provider TEXT,
    scheme_type     insurance_scheme_type,
    tpa_name        TEXT,

    -- Service criteria
    service_type    TEXT,
    charge_code     TEXT,
    charge_code_pattern TEXT,

    -- Thresholds
    cost_threshold  NUMERIC(12,2),
    los_threshold   INT,

    priority        INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,

    -- Audit
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pa_rules_tenant ON pa_requirement_rules(tenant_id);
CREATE INDEX idx_pa_rules_active ON pa_requirement_rules(tenant_id, is_active)
    WHERE is_active = true;

ALTER TABLE pa_requirement_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY pa_requirement_rules_rls ON pa_requirement_rules
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER trg_pa_requirement_rules_updated
    BEFORE UPDATE ON pa_requirement_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
