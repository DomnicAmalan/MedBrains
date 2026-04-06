-- Migration 040: Clinical Decision Support & Batch 8 Features
-- Drug interactions, CDS rules, clinical protocols, antibiotic stewardship,
-- pre-authorization, PG/intern integration, multi-doctor appointments.

-- ============================================================
-- 1. Drug Interactions Table
-- ============================================================

CREATE TABLE drug_interactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    drug_a_name     TEXT NOT NULL,
    drug_b_name     TEXT NOT NULL,
    severity        TEXT NOT NULL CHECK (severity IN ('minor', 'moderate', 'major', 'contraindicated')),
    description     TEXT NOT NULL,
    mechanism       TEXT,
    management      TEXT,
    source          TEXT DEFAULT 'manual',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_drug_interactions_tenant ON drug_interactions(tenant_id);
CREATE INDEX idx_drug_interactions_drug_a ON drug_interactions(tenant_id, lower(drug_a_name));
CREATE INDEX idx_drug_interactions_drug_b ON drug_interactions(tenant_id, lower(drug_b_name));

ALTER TABLE drug_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY drug_interactions_tenant ON drug_interactions
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_drug_interactions
    BEFORE UPDATE ON drug_interactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 2. Critical Value Rules
-- ============================================================

CREATE TABLE critical_value_rules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    test_code       TEXT NOT NULL,
    test_name       TEXT NOT NULL,
    low_critical    DECIMAL(12,4),
    high_critical   DECIMAL(12,4),
    unit            TEXT,
    age_min         INT,
    age_max         INT,
    gender          TEXT CHECK (gender IS NULL OR gender IN ('male', 'female')),
    alert_message   TEXT NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_critical_value_rules_tenant ON critical_value_rules(tenant_id);
CREATE INDEX idx_critical_value_rules_test ON critical_value_rules(tenant_id, test_code);

ALTER TABLE critical_value_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY critical_value_rules_tenant ON critical_value_rules
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_critical_value_rules
    BEFORE UPDATE ON critical_value_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 3. Clinical Protocols / Guidelines
-- ============================================================

CREATE TABLE clinical_protocols (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            TEXT NOT NULL,
    code            TEXT,
    category        TEXT NOT NULL CHECK (category IN ('sepsis', 'dvt_prophylaxis', 'diabetes', 'hypertension', 'cardiac', 'respiratory', 'renal', 'infection', 'surgical', 'other')),
    description     TEXT,
    trigger_conditions JSONB NOT NULL DEFAULT '[]',
    steps           JSONB NOT NULL DEFAULT '[]',
    department_id   UUID REFERENCES departments(id),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_clinical_protocols_tenant ON clinical_protocols(tenant_id);
CREATE INDEX idx_clinical_protocols_category ON clinical_protocols(tenant_id, category);

ALTER TABLE clinical_protocols ENABLE ROW LEVEL SECURITY;
CREATE POLICY clinical_protocols_tenant ON clinical_protocols
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_clinical_protocols
    BEFORE UPDATE ON clinical_protocols
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 4. Restricted Drug Approvals (Antibiotic Stewardship)
-- ============================================================

CREATE TABLE restricted_drug_approvals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    prescription_id UUID REFERENCES prescriptions(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    drug_name       TEXT NOT NULL,
    catalog_item_id UUID REFERENCES pharmacy_catalog(id),
    reason          TEXT NOT NULL,
    requested_by    UUID NOT NULL REFERENCES users(id),
    approved_by     UUID REFERENCES users(id),
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'denied', 'expired')),
    approved_at     TIMESTAMPTZ,
    denied_reason   TEXT,
    expires_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_restricted_drug_approvals_tenant ON restricted_drug_approvals(tenant_id);
CREATE INDEX idx_restricted_drug_approvals_status ON restricted_drug_approvals(tenant_id, status);
CREATE INDEX idx_restricted_drug_approvals_encounter ON restricted_drug_approvals(encounter_id);

ALTER TABLE restricted_drug_approvals ENABLE ROW LEVEL SECURITY;
CREATE POLICY restricted_drug_approvals_tenant ON restricted_drug_approvals
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_restricted_drug_approvals
    BEFORE UPDATE ON restricted_drug_approvals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 5. Pre-Authorization Requests (Insurance)
-- ============================================================

CREATE TABLE pre_authorization_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    insurance_provider TEXT NOT NULL,
    policy_number   TEXT,
    procedure_codes TEXT[] NOT NULL DEFAULT '{}',
    diagnosis_codes TEXT[] NOT NULL DEFAULT '{}',
    estimated_cost  DECIMAL(12,2),
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'submitted', 'approved', 'denied', 'expired')),
    auth_number     TEXT,
    approved_amount DECIMAL(12,2),
    valid_from      DATE,
    valid_until     DATE,
    notes           TEXT,
    submitted_by    UUID NOT NULL REFERENCES users(id),
    reviewed_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pre_auth_requests_tenant ON pre_authorization_requests(tenant_id);
CREATE INDEX idx_pre_auth_requests_patient ON pre_authorization_requests(tenant_id, patient_id);
CREATE INDEX idx_pre_auth_requests_status ON pre_authorization_requests(tenant_id, status);

ALTER TABLE pre_authorization_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY pre_auth_requests_tenant ON pre_authorization_requests
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_pre_auth_requests
    BEFORE UPDATE ON pre_authorization_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 6. PG Logbook Entries
-- ============================================================

CREATE TABLE pg_logbook_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    encounter_id    UUID REFERENCES encounters(id),
    entry_type      TEXT NOT NULL CHECK (entry_type IN ('case', 'procedure', 'ward_round', 'emergency', 'seminar', 'other')),
    title           TEXT NOT NULL,
    description     TEXT,
    diagnosis_codes TEXT[] DEFAULT '{}',
    procedure_codes TEXT[] DEFAULT '{}',
    department_id   UUID REFERENCES departments(id),
    supervisor_id   UUID REFERENCES users(id),
    supervisor_verified BOOLEAN NOT NULL DEFAULT false,
    verified_at     TIMESTAMPTZ,
    entry_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pg_logbook_tenant ON pg_logbook_entries(tenant_id);
CREATE INDEX idx_pg_logbook_user ON pg_logbook_entries(tenant_id, user_id);
CREATE INDEX idx_pg_logbook_supervisor ON pg_logbook_entries(tenant_id, supervisor_id)
    WHERE supervisor_id IS NOT NULL;

ALTER TABLE pg_logbook_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY pg_logbook_entries_tenant ON pg_logbook_entries
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_pg_logbook
    BEFORE UPDATE ON pg_logbook_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 7. Co-Signature Requests
-- ============================================================

CREATE TABLE co_signature_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    order_type      TEXT NOT NULL CHECK (order_type IN ('prescription', 'procedure', 'lab_order', 'referral', 'other')),
    order_id        UUID NOT NULL,
    requested_by    UUID NOT NULL REFERENCES users(id),
    approver_id     UUID NOT NULL REFERENCES users(id),
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'denied')),
    approved_at     TIMESTAMPTZ,
    denied_reason   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_co_signature_tenant ON co_signature_requests(tenant_id);
CREATE INDEX idx_co_signature_approver ON co_signature_requests(tenant_id, approver_id, status);

ALTER TABLE co_signature_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY co_signature_requests_tenant ON co_signature_requests
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_co_signature
    BEFORE UPDATE ON co_signature_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 8. Multi-Doctor Appointments
-- ============================================================

CREATE TABLE multi_doctor_appointments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    appointment_id  UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    doctor_id       UUID NOT NULL REFERENCES users(id),
    department_id   UUID REFERENCES departments(id),
    slot_start      TIME,
    slot_end        TIME,
    status          TEXT NOT NULL DEFAULT 'scheduled'
                    CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_multi_doctor_appt_tenant ON multi_doctor_appointments(tenant_id);
CREATE INDEX idx_multi_doctor_appt_appointment ON multi_doctor_appointments(appointment_id);

ALTER TABLE multi_doctor_appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY multi_doctor_appointments_tenant ON multi_doctor_appointments
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- 9. Add SNOMED CT code field to consultation findings
-- ============================================================

ALTER TABLE consultations ADD COLUMN IF NOT EXISTS snomed_codes JSONB DEFAULT '[]';

-- ============================================================
-- 10. Supervision hierarchy (user → supervisor mapping)
-- ============================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS supervisor_id UUID REFERENCES users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_level TEXT
    CHECK (user_level IS NULL OR user_level IN ('intern', 'resident', 'senior_resident', 'consultant', 'hod'));
