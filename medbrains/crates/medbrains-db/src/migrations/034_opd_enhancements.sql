-- OPD clinical workflow enhancements:
-- 1. Prescription templates (favourite prescriptions)
-- 2. Medical certificates
-- 3. Patient prescription history (cross-encounter lookup index)

-- ── Prescription Templates ─────────────────────────────────
CREATE TABLE prescription_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    created_by      UUID NOT NULL REFERENCES users(id),
    name            TEXT NOT NULL,
    description     TEXT,
    department_id   UUID REFERENCES departments(id),
    is_shared       BOOLEAN NOT NULL DEFAULT false,
    items           JSONB NOT NULL DEFAULT '[]',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, created_by, name)
);

-- items JSONB structure: [{ drug_name, dosage, frequency, duration, route, instructions }]

ALTER TABLE prescription_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY prescription_templates_tenant ON prescription_templates
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_prescription_templates_tenant ON prescription_templates(tenant_id);
CREATE INDEX idx_prescription_templates_user ON prescription_templates(tenant_id, created_by);

CREATE TRIGGER set_updated_at_prescription_templates
    BEFORE UPDATE ON prescription_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Medical Certificates ───────────────────────────────────
CREATE TABLE medical_certificates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID REFERENCES encounters(id),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    certificate_type TEXT NOT NULL
                    CHECK (certificate_type IN ('medical', 'fitness', 'sick_leave', 'disability', 'death', 'birth', 'custom')),
    certificate_number TEXT,
    issued_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_from      DATE,
    valid_to        DATE,
    diagnosis       TEXT,
    remarks         TEXT,
    body            JSONB NOT NULL DEFAULT '{}',
    is_void         BOOLEAN NOT NULL DEFAULT false,
    voided_by       UUID REFERENCES users(id),
    voided_at       TIMESTAMPTZ,
    void_reason     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- body JSONB for type-specific data:
-- medical:    { purpose, findings, recommendations }
-- fitness:    { fitness_for, conditions_met, restrictions }
-- sick_leave: { leave_from, leave_to, leave_days, nature_of_illness }
-- disability: { disability_type, percentage, permanent }

ALTER TABLE medical_certificates ENABLE ROW LEVEL SECURITY;
CREATE POLICY medical_certificates_tenant ON medical_certificates
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_medical_certificates_tenant ON medical_certificates(tenant_id);
CREATE INDEX idx_medical_certificates_patient ON medical_certificates(tenant_id, patient_id);
CREATE INDEX idx_medical_certificates_encounter ON medical_certificates(encounter_id)
    WHERE encounter_id IS NOT NULL;

CREATE TRIGGER set_updated_at_medical_certificates
    BEFORE UPDATE ON medical_certificates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Cross-encounter prescription lookup ──────────────────────
-- Add patient_id column to prescriptions for direct lookup
-- (denormalized from encounter for fast patient Rx history)
ALTER TABLE prescriptions
    ADD COLUMN IF NOT EXISTS patient_id UUID REFERENCES patients(id);

-- Backfill patient_id from encounters
UPDATE prescriptions p
SET patient_id = e.patient_id
FROM encounters e
WHERE p.encounter_id = e.id
  AND p.patient_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON prescriptions(tenant_id, patient_id)
    WHERE patient_id IS NOT NULL;

-- ── Certificate sequence ───────────────────────────────────
INSERT INTO sequences (tenant_id, seq_type, prefix, current_val, pad_width)
SELECT t.id, 'CERT', 'CERT-', 0, 6
FROM tenants t
ON CONFLICT DO NOTHING;
