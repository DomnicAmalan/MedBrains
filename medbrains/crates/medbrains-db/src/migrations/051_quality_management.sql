-- Migration 051: Quality Management
-- Quality indicators, controlled documents/SOPs, incident reporting, CAPA,
-- committees, accreditation compliance, and internal audits.

-- ============================================================
-- Enums
-- ============================================================

CREATE TYPE document_status AS ENUM (
    'draft',
    'under_review',
    'approved',
    'released',
    'revised',
    'obsolete'
);

CREATE TYPE incident_severity AS ENUM (
    'near_miss',
    'minor',
    'moderate',
    'major',
    'sentinel'
);

CREATE TYPE incident_status AS ENUM (
    'reported',
    'acknowledged',
    'investigating',
    'rca_complete',
    'capa_assigned',
    'capa_in_progress',
    'closed',
    'reopened'
);

CREATE TYPE capa_status AS ENUM (
    'open',
    'in_progress',
    'completed',
    'verified',
    'overdue'
);

CREATE TYPE indicator_frequency AS ENUM (
    'daily',
    'weekly',
    'monthly',
    'quarterly',
    'annually'
);

CREATE TYPE accreditation_body AS ENUM (
    'nabh',
    'nmc',
    'nabl',
    'jci',
    'abdm',
    'naac',
    'other'
);

CREATE TYPE compliance_status AS ENUM (
    'compliant',
    'partially_compliant',
    'non_compliant',
    'not_applicable'
);

CREATE TYPE committee_frequency AS ENUM (
    'weekly',
    'biweekly',
    'monthly',
    'quarterly',
    'biannual',
    'annual',
    'as_needed'
);

-- ============================================================
-- 1. Quality Indicators — indicator definitions
-- ============================================================

CREATE TABLE quality_indicators (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    code                    VARCHAR(50) NOT NULL,
    name                    VARCHAR(200) NOT NULL,
    description             TEXT,
    category                VARCHAR(50) NOT NULL,
    sub_category            VARCHAR(100),
    numerator_description   TEXT,
    denominator_description TEXT,
    unit                    VARCHAR(50),
    frequency               indicator_frequency,
    target_value            NUMERIC(10,4),
    threshold_warning       NUMERIC(10,4),
    threshold_critical      NUMERIC(10,4),
    benchmark_national      NUMERIC(10,4),
    benchmark_international NUMERIC(10,4),
    auto_calculated         BOOLEAN NOT NULL DEFAULT false,
    calculation_query       TEXT,
    is_active               BOOLEAN NOT NULL DEFAULT true,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, code)
);

ALTER TABLE quality_indicators ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_indicators_tenant ON quality_indicators
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_indicators_tenant ON quality_indicators(tenant_id);

-- ============================================================
-- 2. Quality Indicator Values — recorded/calculated values
-- ============================================================

CREATE TABLE quality_indicator_values (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    indicator_id      UUID NOT NULL REFERENCES quality_indicators(id),
    period_start      DATE NOT NULL,
    period_end        DATE NOT NULL,
    numerator_value   NUMERIC(12,4),
    denominator_value NUMERIC(12,4),
    calculated_value  NUMERIC(10,4),
    department_id     UUID,
    notes             TEXT,
    recorded_by       UUID REFERENCES users(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, indicator_id, period_start, period_end, department_id)
);

ALTER TABLE quality_indicator_values ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_indicator_values_tenant ON quality_indicator_values
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_indicator_values_tenant ON quality_indicator_values(tenant_id);
CREATE INDEX idx_quality_indicator_values_lookup ON quality_indicator_values(tenant_id, indicator_id, period_start);

-- ============================================================
-- 3. Quality Documents — controlled documents / SOPs
-- ============================================================

CREATE TABLE quality_documents (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    document_number      VARCHAR(50) NOT NULL,
    title                VARCHAR(300) NOT NULL,
    category             VARCHAR(100),
    department_id        UUID,
    current_version      INTEGER NOT NULL DEFAULT 1,
    status               document_status NOT NULL DEFAULT 'draft',
    content              TEXT,
    summary              TEXT,
    author_id            UUID REFERENCES users(id),
    reviewer_id          UUID REFERENCES users(id),
    approver_id          UUID REFERENCES users(id),
    released_at          TIMESTAMPTZ,
    next_review_date     DATE,
    review_cycle_months  INTEGER DEFAULT 12,
    is_training_required BOOLEAN NOT NULL DEFAULT false,
    attachments          JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, document_number)
);

ALTER TABLE quality_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_documents_tenant ON quality_documents
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_documents_tenant ON quality_documents(tenant_id);
CREATE INDEX idx_quality_documents_status ON quality_documents(tenant_id, status);
CREATE INDEX idx_quality_documents_dept ON quality_documents(tenant_id, department_id);

-- ============================================================
-- 4. Quality Document Versions — version history
-- ============================================================

CREATE TABLE quality_document_versions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    document_id    UUID NOT NULL REFERENCES quality_documents(id),
    version_number INTEGER NOT NULL,
    change_summary TEXT,
    content        TEXT,
    created_by     UUID REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE quality_document_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_document_versions_tenant ON quality_document_versions
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_document_versions_tenant ON quality_document_versions(tenant_id);
CREATE INDEX idx_quality_document_versions_doc ON quality_document_versions(tenant_id, document_id);

-- ============================================================
-- 5. Quality Document Acknowledgments — read acknowledgments
-- ============================================================

CREATE TABLE quality_document_acknowledgments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    document_id     UUID NOT NULL REFERENCES quality_documents(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, document_id, user_id)
);

ALTER TABLE quality_document_acknowledgments ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_document_acknowledgments_tenant ON quality_document_acknowledgments
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_doc_acks_tenant ON quality_document_acknowledgments(tenant_id);
CREATE INDEX idx_quality_doc_acks_doc ON quality_document_acknowledgments(tenant_id, document_id);

-- ============================================================
-- 6. Quality Incidents — incident reports
-- ============================================================

CREATE TABLE quality_incidents (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES tenants(id),
    incident_number       VARCHAR(50) NOT NULL,
    title                 VARCHAR(300) NOT NULL,
    description           TEXT,
    incident_type         VARCHAR(100),
    severity              incident_severity,
    status                incident_status NOT NULL DEFAULT 'reported',
    department_id         UUID,
    location              VARCHAR(200),
    incident_date         TIMESTAMPTZ,
    reported_by           UUID REFERENCES users(id),
    is_anonymous          BOOLEAN NOT NULL DEFAULT false,
    patient_id            UUID,
    affected_persons      JSONB NOT NULL DEFAULT '[]'::jsonb,
    immediate_action      TEXT,
    root_cause            TEXT,
    contributing_factors  JSONB NOT NULL DEFAULT '[]'::jsonb,
    assigned_to           UUID REFERENCES users(id),
    closed_at             TIMESTAMPTZ,
    closed_by             UUID REFERENCES users(id),
    is_reportable         BOOLEAN NOT NULL DEFAULT false,
    regulatory_body       VARCHAR(100),
    regulatory_reported_at TIMESTAMPTZ,
    attachments           JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, incident_number)
);

ALTER TABLE quality_incidents ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_incidents_tenant ON quality_incidents
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_incidents_tenant ON quality_incidents(tenant_id);
CREATE INDEX idx_quality_incidents_status ON quality_incidents(tenant_id, status);
CREATE INDEX idx_quality_incidents_severity ON quality_incidents(tenant_id, severity);
CREATE INDEX idx_quality_incidents_date ON quality_incidents(tenant_id, incident_date);

-- ============================================================
-- 7. Quality CAPA — Corrective & Preventive Actions
-- ============================================================

CREATE TABLE quality_capa (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    incident_id         UUID REFERENCES quality_incidents(id),
    capa_number         VARCHAR(50) NOT NULL,
    capa_type           VARCHAR(20),
    description         TEXT,
    action_plan         TEXT,
    status              capa_status NOT NULL DEFAULT 'open',
    assigned_to         UUID REFERENCES users(id),
    due_date            DATE,
    completed_at        TIMESTAMPTZ,
    verified_by         UUID REFERENCES users(id),
    verified_at         TIMESTAMPTZ,
    effectiveness_check TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, capa_number)
);

ALTER TABLE quality_capa ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_capa_tenant ON quality_capa
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_capa_tenant ON quality_capa(tenant_id);
CREATE INDEX idx_quality_capa_incident ON quality_capa(tenant_id, incident_id);

-- ============================================================
-- 8. Quality Committees — committee definitions
-- ============================================================

CREATE TABLE quality_committees (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    name              VARCHAR(200) NOT NULL,
    code              VARCHAR(50) NOT NULL,
    description       TEXT,
    committee_type    VARCHAR(100),
    chairperson_id    UUID REFERENCES users(id),
    secretary_id      UUID REFERENCES users(id),
    members           JSONB NOT NULL DEFAULT '[]'::jsonb,
    meeting_frequency committee_frequency,
    charter           TEXT,
    is_mandatory      BOOLEAN NOT NULL DEFAULT true,
    is_active         BOOLEAN NOT NULL DEFAULT true,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, code)
);

ALTER TABLE quality_committees ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_committees_tenant ON quality_committees
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_committees_tenant ON quality_committees(tenant_id);

-- ============================================================
-- 9. Quality Committee Meetings — meeting records
-- ============================================================

CREATE TABLE quality_committee_meetings (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    committee_id   UUID NOT NULL REFERENCES quality_committees(id),
    meeting_number VARCHAR(50),
    scheduled_date TIMESTAMPTZ,
    actual_date    TIMESTAMPTZ,
    venue          VARCHAR(200),
    agenda         JSONB NOT NULL DEFAULT '[]'::jsonb,
    minutes        TEXT,
    attendees      JSONB NOT NULL DEFAULT '[]'::jsonb,
    absentees      JSONB NOT NULL DEFAULT '[]'::jsonb,
    decisions      JSONB NOT NULL DEFAULT '[]'::jsonb,
    status         VARCHAR(20) NOT NULL DEFAULT 'scheduled',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE quality_committee_meetings ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_committee_meetings_tenant ON quality_committee_meetings
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_committee_meetings_tenant ON quality_committee_meetings(tenant_id);
CREATE INDEX idx_quality_committee_meetings_lookup ON quality_committee_meetings(tenant_id, committee_id, scheduled_date);

-- ============================================================
-- 10. Quality Action Items — from meetings, incidents, audits
-- ============================================================

CREATE TABLE quality_action_items (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID NOT NULL REFERENCES tenants(id),
    source_type  VARCHAR(50),
    source_id    UUID,
    description  TEXT,
    assigned_to  UUID REFERENCES users(id),
    due_date     DATE,
    status       VARCHAR(20) NOT NULL DEFAULT 'open',
    completed_at TIMESTAMPTZ,
    remarks      TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE quality_action_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_action_items_tenant ON quality_action_items
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_action_items_tenant ON quality_action_items(tenant_id);
CREATE INDEX idx_quality_action_items_source ON quality_action_items(tenant_id, source_type, source_id);

-- ============================================================
-- 11. Quality Accreditation Standards — standard definitions
-- ============================================================

CREATE TABLE quality_accreditation_standards (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    body                accreditation_body NOT NULL,
    standard_code       VARCHAR(50) NOT NULL,
    standard_name       VARCHAR(300) NOT NULL,
    chapter             VARCHAR(100),
    description         TEXT,
    measurable_elements JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, body, standard_code)
);

ALTER TABLE quality_accreditation_standards ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_accreditation_standards_tenant ON quality_accreditation_standards
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_accred_standards_tenant ON quality_accreditation_standards(tenant_id);

-- ============================================================
-- 12. Quality Accreditation Compliance — per-standard tracking
-- ============================================================

CREATE TABLE quality_accreditation_compliance (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES tenants(id),
    standard_id           UUID NOT NULL REFERENCES quality_accreditation_standards(id),
    compliance            compliance_status NOT NULL DEFAULT 'not_applicable',
    evidence_summary      TEXT,
    evidence_documents    JSONB NOT NULL DEFAULT '[]'::jsonb,
    gap_description       TEXT,
    action_plan           TEXT,
    responsible_person_id UUID REFERENCES users(id),
    target_date           DATE,
    assessed_at           TIMESTAMPTZ,
    assessed_by           UUID REFERENCES users(id),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, standard_id)
);

ALTER TABLE quality_accreditation_compliance ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_accreditation_compliance_tenant ON quality_accreditation_compliance
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_accred_compliance_tenant ON quality_accreditation_compliance(tenant_id);
CREATE INDEX idx_quality_accred_compliance_standard ON quality_accreditation_compliance(tenant_id, standard_id);

-- ============================================================
-- 13. Quality Audits — internal audit records
-- ============================================================

CREATE TABLE quality_audits (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    audit_number      VARCHAR(50) NOT NULL,
    audit_type        VARCHAR(50),
    title             VARCHAR(300) NOT NULL,
    scope             TEXT,
    department_id     UUID,
    auditor_id        UUID REFERENCES users(id),
    audit_date        DATE,
    report_date       DATE,
    findings          JSONB NOT NULL DEFAULT '[]'::jsonb,
    non_conformities  INTEGER NOT NULL DEFAULT 0,
    observations      INTEGER NOT NULL DEFAULT 0,
    opportunities     INTEGER NOT NULL DEFAULT 0,
    overall_score     NUMERIC(5,2),
    status            VARCHAR(20) NOT NULL DEFAULT 'planned',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, audit_number)
);

ALTER TABLE quality_audits ENABLE ROW LEVEL SECURITY;
CREATE POLICY quality_audits_tenant ON quality_audits
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_quality_audits_tenant ON quality_audits(tenant_id);
CREATE INDEX idx_quality_audits_status ON quality_audits(tenant_id, status);
CREATE INDEX idx_quality_audits_dept ON quality_audits(tenant_id, department_id);

-- ============================================================
-- Triggers — updated_at
-- ============================================================

CREATE TRIGGER set_quality_indicators_updated_at BEFORE UPDATE ON quality_indicators
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_indicator_values_updated_at BEFORE UPDATE ON quality_indicator_values
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_documents_updated_at BEFORE UPDATE ON quality_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_document_versions_updated_at BEFORE UPDATE ON quality_document_versions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_document_acks_updated_at BEFORE UPDATE ON quality_document_acknowledgments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_incidents_updated_at BEFORE UPDATE ON quality_incidents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_capa_updated_at BEFORE UPDATE ON quality_capa
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_committees_updated_at BEFORE UPDATE ON quality_committees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_committee_meetings_updated_at BEFORE UPDATE ON quality_committee_meetings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_action_items_updated_at BEFORE UPDATE ON quality_action_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_accred_standards_updated_at BEFORE UPDATE ON quality_accreditation_standards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_accred_compliance_updated_at BEFORE UPDATE ON quality_accreditation_compliance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_quality_audits_updated_at BEFORE UPDATE ON quality_audits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
