-- 058_ipd_phase2.sql — Wards, Bed Dashboard, Admission Enhancements, Discharge Summaries

-- ══════════════════════════════════════════════════════════
--  New Enums
-- ══════════════════════════════════════════════════════════

CREATE TYPE discharge_summary_status AS ENUM ('draft', 'finalized');
CREATE TYPE admission_source AS ENUM ('er', 'opd', 'direct', 'referral', 'transfer_in');

-- ══════════════════════════════════════════════════════════
--  New Tables
-- ══════════════════════════════════════════════════════════

-- Wards — logical ward groupings over physical beds
CREATE TABLE wards (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    department_id UUID REFERENCES departments(id),
    ward_type   TEXT NOT NULL DEFAULT 'general',
    total_beds  INT NOT NULL DEFAULT 0,
    gender_restriction TEXT NOT NULL DEFAULT 'any',
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

-- Ward-Bed mappings — link beds (locations where level='bed') to wards
CREATE TABLE ward_bed_mappings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    ward_id         UUID NOT NULL REFERENCES wards(id) ON DELETE CASCADE,
    bed_location_id UUID NOT NULL REFERENCES locations(id),
    bed_type_id     UUID REFERENCES bed_types(id),
    sort_order      INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, bed_location_id)
);

-- Admission attenders — next-of-kin & attender info per admission
CREATE TABLE admission_attenders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    relationship    TEXT NOT NULL,
    name            TEXT NOT NULL,
    phone           TEXT,
    alt_phone       TEXT,
    address         TEXT,
    id_proof_type   TEXT,
    id_proof_number TEXT,
    is_primary      BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Discharge summary templates — reusable
CREATE TABLE discharge_summary_templates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    sections    JSONB NOT NULL DEFAULT '[]',
    is_default  BOOLEAN NOT NULL DEFAULT false,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

-- Discharge summaries — one per admission
CREATE TABLE ipd_discharge_summaries (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                UUID NOT NULL REFERENCES tenants(id),
    admission_id             UUID NOT NULL REFERENCES admissions(id) UNIQUE,
    template_id              UUID REFERENCES discharge_summary_templates(id),
    status                   discharge_summary_status NOT NULL DEFAULT 'draft',
    final_diagnosis          TEXT,
    condition_at_discharge   TEXT,
    course_in_hospital       TEXT,
    treatment_given          TEXT,
    procedures_performed     JSONB NOT NULL DEFAULT '[]',
    investigation_summary    TEXT,
    medications_on_discharge JSONB NOT NULL DEFAULT '[]',
    follow_up_instructions   TEXT,
    follow_up_date           DATE,
    dietary_advice           TEXT,
    activity_restrictions    TEXT,
    warning_signs            TEXT,
    emergency_contact_info   TEXT,
    prepared_by              UUID REFERENCES users(id),
    verified_by              UUID REFERENCES users(id),
    finalized_at             TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ══════════════════════════════════════════════════════════
--  ALTER existing tables
-- ══════════════════════════════════════════════════════════

-- admissions — add Phase 2 fields
ALTER TABLE admissions
    ADD COLUMN IF NOT EXISTS admission_source admission_source DEFAULT 'direct',
    ADD COLUMN IF NOT EXISTS referral_from TEXT,
    ADD COLUMN IF NOT EXISTS referral_doctor TEXT,
    ADD COLUMN IF NOT EXISTS referral_notes TEXT,
    ADD COLUMN IF NOT EXISTS admission_weight_kg NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS admission_height_cm NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS expected_discharge_date DATE,
    ADD COLUMN IF NOT EXISTS ward_id UUID REFERENCES wards(id),
    ADD COLUMN IF NOT EXISTS mlc_case_id UUID;

-- bed_states — denormalized ward + admission links
ALTER TABLE bed_states
    ADD COLUMN IF NOT EXISTS ward_id UUID REFERENCES wards(id),
    ADD COLUMN IF NOT EXISTS admission_id UUID REFERENCES admissions(id);

-- ══════════════════════════════════════════════════════════
--  Row-Level Security
-- ══════════════════════════════════════════════════════════

ALTER TABLE wards ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON wards
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ward_bed_mappings ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ward_bed_mappings
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE admission_attenders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON admission_attenders
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE discharge_summary_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON discharge_summary_templates
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ipd_discharge_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ipd_discharge_summaries
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- ══════════════════════════════════════════════════════════
--  Triggers (updated_at)
-- ══════════════════════════════════════════════════════════

CREATE TRIGGER set_updated_at BEFORE UPDATE ON wards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON discharge_summary_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ipd_discharge_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  Indexes
-- ══════════════════════════════════════════════════════════

CREATE INDEX idx_ward_bed_mappings_ward ON ward_bed_mappings(ward_id);
CREATE INDEX idx_admission_attenders_admission ON admission_attenders(admission_id);
CREATE INDEX idx_ipd_discharge_summaries_admission ON ipd_discharge_summaries(admission_id);
CREATE INDEX idx_admissions_ward ON admissions(ward_id);
CREATE INDEX idx_bed_states_ward ON bed_states(ward_id);
