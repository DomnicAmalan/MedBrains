-- ============================================================
-- Migration 053: IPD Clinical Expansion
-- Adds clinical documentation, nursing workflows, medication
-- administration, intake/output tracking, care plans, handover,
-- and discharge checklists. Also extends admissions and bed_states.
-- ============================================================

-- ── New Enums ───────────────────────────────────────────────

CREATE TYPE progress_note_type AS ENUM (
    'doctor_round',
    'nursing_note',
    'specialist_opinion',
    'dietitian_note',
    'physiotherapy_note',
    'social_worker_note',
    'discharge_note'
);

CREATE TYPE clinical_assessment_type AS ENUM (
    'morse_fall_scale',
    'braden_scale',
    'gcs',
    'pain_vas',
    'pain_nrs',
    'pain_flacc',
    'barthel_adl',
    'norton_scale',
    'waterlow_score',
    'rass',
    'cam',
    'news2',
    'mews',
    'custom'
);

CREATE TYPE mar_status AS ENUM (
    'scheduled',
    'given',
    'held',
    'refused',
    'missed',
    'self_administered'
);

CREATE TYPE intake_type AS ENUM (
    'oral',
    'iv_fluid',
    'iv_medication',
    'blood_product',
    'enteral_feed',
    'parenteral',
    'irrigation',
    'other'
);

CREATE TYPE output_type AS ENUM (
    'urine',
    'drain',
    'nasogastric',
    'vomit',
    'stool',
    'blood_loss',
    'wound_drainage',
    'chest_tube',
    'other'
);

CREATE TYPE care_plan_status AS ENUM (
    'active',
    'resolved',
    'discontinued'
);

CREATE TYPE nursing_shift AS ENUM (
    'morning',
    'afternoon',
    'night'
);

-- ── ALTER TABLE: admissions ─────────────────────────────────

ALTER TABLE admissions
    ADD COLUMN IF NOT EXISTS provisional_diagnosis TEXT,
    ADD COLUMN IF NOT EXISTS comorbidities JSONB NOT NULL DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS estimated_los_days INTEGER,
    ADD COLUMN IF NOT EXISTS deposit_amount NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS deposit_paid BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS priority VARCHAR(20) NOT NULL DEFAULT 'routine';

-- ── ALTER TABLE: bed_states ─────────────────────────────────

ALTER TABLE bed_states
    ADD COLUMN IF NOT EXISTS cleaning_started_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS cleaning_completed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS expected_discharge_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS blocked_reason TEXT,
    ADD COLUMN IF NOT EXISTS reserved_for_patient UUID,
    ADD COLUMN IF NOT EXISTS reserved_until TIMESTAMPTZ;

-- ── Table: ipd_progress_notes ───────────────────────────────

CREATE TABLE ipd_progress_notes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    encounter_id    UUID REFERENCES encounters(id),
    note_type       progress_note_type NOT NULL,
    author_id       UUID NOT NULL REFERENCES users(id),
    note_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    subjective      TEXT,
    objective        TEXT,
    assessment      TEXT,
    plan            TEXT,
    is_addendum     BOOLEAN NOT NULL DEFAULT false,
    parent_note_id  UUID REFERENCES ipd_progress_notes(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ipd_progress_notes_tenant ON ipd_progress_notes(tenant_id);
CREATE INDEX idx_ipd_progress_notes_admission ON ipd_progress_notes(admission_id);
CREATE INDEX idx_ipd_progress_notes_date ON ipd_progress_notes(admission_id, note_date DESC);

ALTER TABLE ipd_progress_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_progress_notes ON ipd_progress_notes
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ipd_progress_notes_updated
    BEFORE UPDATE ON ipd_progress_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ipd_clinical_assessments ─────────────────────────

CREATE TABLE ipd_clinical_assessments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    assessment_type clinical_assessment_type NOT NULL,
    score_value     NUMERIC(8,2),
    risk_level      VARCHAR(20),
    score_details   JSONB NOT NULL DEFAULT '{}',
    assessed_by     UUID NOT NULL REFERENCES users(id),
    assessed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ipd_clinical_assessments_tenant ON ipd_clinical_assessments(tenant_id);
CREATE INDEX idx_ipd_clinical_assessments_admission ON ipd_clinical_assessments(admission_id);
CREATE INDEX idx_ipd_clinical_assessments_type ON ipd_clinical_assessments(admission_id, assessment_type);

ALTER TABLE ipd_clinical_assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_clinical_assessments ON ipd_clinical_assessments
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ipd_clinical_assessments_updated
    BEFORE UPDATE ON ipd_clinical_assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ipd_medication_administration ────────────────────

CREATE TABLE ipd_medication_administration (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    admission_id        UUID NOT NULL REFERENCES admissions(id),
    prescription_item_id UUID,
    drug_name           TEXT NOT NULL,
    dose                TEXT NOT NULL,
    route               VARCHAR(30) NOT NULL,
    frequency           VARCHAR(50),
    scheduled_at        TIMESTAMPTZ NOT NULL,
    administered_at     TIMESTAMPTZ,
    status              mar_status NOT NULL DEFAULT 'scheduled',
    administered_by     UUID REFERENCES users(id),
    witnessed_by        UUID REFERENCES users(id),
    barcode_verified    BOOLEAN NOT NULL DEFAULT false,
    is_high_alert       BOOLEAN NOT NULL DEFAULT false,
    hold_reason         TEXT,
    refused_reason      TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ipd_mar_tenant ON ipd_medication_administration(tenant_id);
CREATE INDEX idx_ipd_mar_admission ON ipd_medication_administration(admission_id);
CREATE INDEX idx_ipd_mar_scheduled ON ipd_medication_administration(admission_id, scheduled_at);
CREATE INDEX idx_ipd_mar_status ON ipd_medication_administration(admission_id, status);

ALTER TABLE ipd_medication_administration ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_mar ON ipd_medication_administration
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ipd_mar_updated
    BEFORE UPDATE ON ipd_medication_administration
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ipd_intake_output ────────────────────────────────

CREATE TABLE ipd_intake_output (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    is_intake       BOOLEAN NOT NULL,
    category        VARCHAR(50) NOT NULL,
    volume_ml       NUMERIC(10,2) NOT NULL,
    description     TEXT,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by     UUID NOT NULL REFERENCES users(id),
    shift           nursing_shift NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ipd_io_tenant ON ipd_intake_output(tenant_id);
CREATE INDEX idx_ipd_io_admission ON ipd_intake_output(admission_id);
CREATE INDEX idx_ipd_io_recorded ON ipd_intake_output(admission_id, recorded_at);
CREATE INDEX idx_ipd_io_shift ON ipd_intake_output(admission_id, shift);

ALTER TABLE ipd_intake_output ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_io ON ipd_intake_output
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- ── Table: ipd_nursing_assessments ──────────────────────────

CREATE TABLE ipd_nursing_assessments (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    admission_id            UUID NOT NULL REFERENCES admissions(id),
    assessed_by             UUID NOT NULL REFERENCES users(id),
    assessed_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    general_appearance      JSONB NOT NULL DEFAULT '{}',
    skin_assessment         JSONB NOT NULL DEFAULT '{}',
    pain_assessment         JSONB NOT NULL DEFAULT '{}',
    nutritional_status      JSONB NOT NULL DEFAULT '{}',
    elimination_status      JSONB NOT NULL DEFAULT '{}',
    respiratory_status      JSONB NOT NULL DEFAULT '{}',
    psychosocial_status     JSONB NOT NULL DEFAULT '{}',
    fall_risk_assessment    JSONB NOT NULL DEFAULT '{}',
    allergies               TEXT,
    medications_on_admission TEXT,
    personal_belongings     JSONB NOT NULL DEFAULT '[]',
    patient_education_needs TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ipd_nursing_assess_tenant ON ipd_nursing_assessments(tenant_id);
CREATE INDEX idx_ipd_nursing_assess_admission ON ipd_nursing_assessments(admission_id);

ALTER TABLE ipd_nursing_assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_nursing_assess ON ipd_nursing_assessments
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ipd_nursing_assess_updated
    BEFORE UPDATE ON ipd_nursing_assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ipd_care_plans ───────────────────────────────────

CREATE TABLE ipd_care_plans (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    admission_id        UUID NOT NULL REFERENCES admissions(id),
    nursing_diagnosis   TEXT NOT NULL,
    goals               TEXT,
    interventions       JSONB NOT NULL DEFAULT '[]',
    evaluation          TEXT,
    status              care_plan_status NOT NULL DEFAULT 'active',
    initiated_by        UUID NOT NULL REFERENCES users(id),
    initiated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at         TIMESTAMPTZ,
    resolved_by         UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ipd_care_plans_tenant ON ipd_care_plans(tenant_id);
CREATE INDEX idx_ipd_care_plans_admission ON ipd_care_plans(admission_id);
CREATE INDEX idx_ipd_care_plans_status ON ipd_care_plans(admission_id, status);

ALTER TABLE ipd_care_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_care_plans ON ipd_care_plans
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ipd_care_plans_updated
    BEFORE UPDATE ON ipd_care_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ipd_handover_reports ─────────────────────────────

CREATE TABLE ipd_handover_reports (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    admission_id        UUID NOT NULL REFERENCES admissions(id),
    shift               nursing_shift NOT NULL,
    handover_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    outgoing_nurse      UUID NOT NULL REFERENCES users(id),
    incoming_nurse      UUID NOT NULL REFERENCES users(id),
    identification      TEXT,
    situation           TEXT,
    background          TEXT,
    assessment          TEXT,
    recommendation      TEXT,
    pending_tasks       JSONB NOT NULL DEFAULT '[]',
    acknowledged_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ipd_handover_tenant ON ipd_handover_reports(tenant_id);
CREATE INDEX idx_ipd_handover_admission ON ipd_handover_reports(admission_id);
CREATE INDEX idx_ipd_handover_date ON ipd_handover_reports(admission_id, handover_date DESC);

ALTER TABLE ipd_handover_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_handover ON ipd_handover_reports
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ipd_handover_updated
    BEFORE UPDATE ON ipd_handover_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ipd_discharge_checklists ─────────────────────────

CREATE TABLE ipd_discharge_checklists (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    item_code       VARCHAR(50) NOT NULL,
    item_label      TEXT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    completed_by    UUID REFERENCES users(id),
    completed_at    TIMESTAMPTZ,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, admission_id, item_code)
);

CREATE INDEX idx_ipd_discharge_cl_tenant ON ipd_discharge_checklists(tenant_id);
CREATE INDEX idx_ipd_discharge_cl_admission ON ipd_discharge_checklists(admission_id);

ALTER TABLE ipd_discharge_checklists ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ipd_discharge_cl ON ipd_discharge_checklists
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ipd_discharge_cl_updated
    BEFORE UPDATE ON ipd_discharge_checklists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
