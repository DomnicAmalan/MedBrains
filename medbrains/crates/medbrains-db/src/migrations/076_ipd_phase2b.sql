-- 076_ipd_phase2b.sql — IPD Phase 2b: IP types, bed reservations, clinical docs,
-- restraint monitoring, transfers, death/birth records, OT consumables, discharge TAT

-- ══════════════════════════════════════════════════════════
--  New Enums
-- ══════════════════════════════════════════════════════════

CREATE TYPE ip_type AS ENUM (
    'general', 'semi_private', 'private', 'deluxe', 'suite',
    'icu', 'nicu', 'picu', 'hdu', 'isolation'
);

CREATE TYPE bed_reservation_status AS ENUM (
    'active', 'confirmed', 'cancelled', 'expired', 'fulfilled'
);

CREATE TYPE ipd_clinical_doc_type AS ENUM (
    'wound_care', 'central_line', 'catheter', 'drain',
    'restraint', 'transfusion', 'clinical_pathway', 'other'
);

CREATE TYPE restraint_check_status AS ENUM (
    'circulation_ok', 'skin_intact', 'repositioned', 'released', 'escalated'
);

CREATE TYPE transfer_type AS ENUM (
    'inter_ward', 'inter_department', 'inter_hospital'
);

CREATE TYPE death_cert_form_type AS ENUM (
    'form_4', 'form_4a'
);

CREATE TYPE ot_consumable_category AS ENUM (
    'surgical_instrument', 'implant', 'disposable', 'suture',
    'drug', 'blood_product', 'other'
);

-- ══════════════════════════════════════════════════════════
--  New Tables
-- ══════════════════════════════════════════════════════════

-- A. IP Type Configuration — Ward/room type pricing
CREATE TABLE ip_type_configurations (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    ip_type          ip_type NOT NULL,
    label            VARCHAR(100) NOT NULL,
    daily_rate       NUMERIC(10,2) NOT NULL DEFAULT 0,
    nursing_charge   NUMERIC(10,2) NOT NULL DEFAULT 0,
    deposit_required NUMERIC(10,2) NOT NULL DEFAULT 0,
    description      TEXT,
    is_active        BOOLEAN NOT NULL DEFAULT true,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, ip_type)
);

-- B. Admission Checklists — Per-admission checklist items
CREATE TABLE admission_checklists (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    admission_id  UUID NOT NULL REFERENCES admissions(id),
    item_label    VARCHAR(300) NOT NULL,
    category      VARCHAR(100),
    is_completed  BOOLEAN NOT NULL DEFAULT false,
    completed_by  UUID REFERENCES users(id),
    completed_at  TIMESTAMPTZ,
    sort_order    INT NOT NULL DEFAULT 0,
    notes         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- C. Bed Reservations — Bed blocking/reservation
CREATE TABLE bed_reservations (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    bed_id        UUID NOT NULL REFERENCES locations(id),
    patient_id    UUID NOT NULL REFERENCES patients(id),
    reserved_by   UUID NOT NULL REFERENCES users(id),
    status        bed_reservation_status NOT NULL DEFAULT 'active',
    reserved_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    reserved_until TIMESTAMPTZ NOT NULL,
    purpose       VARCHAR(200),
    notes         TEXT,
    cancelled_by  UUID REFERENCES users(id),
    cancelled_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- D. Bed Turnaround Log — Cleaning/turnover tracking
CREATE TABLE bed_turnaround_log (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    bed_id               UUID NOT NULL REFERENCES locations(id),
    admission_id         UUID REFERENCES admissions(id),
    vacated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    cleaning_started_at  TIMESTAMPTZ,
    cleaning_completed_at TIMESTAMPTZ,
    ready_at             TIMESTAMPTZ,
    turnaround_minutes   INT,
    cleaned_by           UUID REFERENCES users(id),
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- E. IPD Clinical Documentations — Wound care, line tracking, drains, etc.
CREATE TABLE ipd_clinical_documentations (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    admission_id   UUID NOT NULL REFERENCES admissions(id),
    patient_id     UUID NOT NULL REFERENCES patients(id),
    doc_type       ipd_clinical_doc_type NOT NULL,
    title          VARCHAR(300) NOT NULL,
    body           JSONB NOT NULL DEFAULT '{}',
    recorded_by    UUID NOT NULL REFERENCES users(id),
    recorded_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    next_review_at TIMESTAMPTZ,
    is_resolved    BOOLEAN NOT NULL DEFAULT false,
    resolved_at    TIMESTAMPTZ,
    resolved_by    UUID REFERENCES users(id),
    notes          TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- F. Restraint Monitoring Logs — 30-minute restraint checks
CREATE TABLE restraint_monitoring_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    clinical_doc_id UUID NOT NULL REFERENCES ipd_clinical_documentations(id),
    check_time      TIMESTAMPTZ NOT NULL DEFAULT now(),
    status          restraint_check_status NOT NULL,
    circulation_status TEXT,
    skin_status     TEXT,
    patient_response TEXT,
    checked_by      UUID NOT NULL REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- G. IPD Transfer Logs — Inter-ward/dept/hospital transfer history
CREATE TABLE ipd_transfer_logs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    admission_id     UUID NOT NULL REFERENCES admissions(id),
    transfer_type    transfer_type NOT NULL,
    from_ward_id     UUID REFERENCES wards(id),
    to_ward_id       UUID REFERENCES wards(id),
    from_bed_id      UUID REFERENCES locations(id),
    to_bed_id        UUID REFERENCES locations(id),
    reason           TEXT,
    clinical_summary TEXT,
    transferred_by   UUID NOT NULL REFERENCES users(id),
    transferred_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- H. IPD Death Summaries — Death certificate & summary
CREATE TABLE ipd_death_summaries (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                 UUID NOT NULL REFERENCES tenants(id),
    admission_id              UUID NOT NULL REFERENCES admissions(id) UNIQUE,
    patient_id                UUID NOT NULL REFERENCES patients(id),
    date_of_death             DATE NOT NULL,
    time_of_death             TIME NOT NULL,
    cause_of_death_primary    TEXT NOT NULL,
    cause_of_death_secondary  TEXT,
    cause_of_death_tertiary   TEXT,
    cause_of_death_underlying TEXT,
    manner_of_death           VARCHAR(100),
    duration_of_illness       TEXT,
    autopsy_requested         BOOLEAN NOT NULL DEFAULT false,
    is_medico_legal           BOOLEAN NOT NULL DEFAULT false,
    form_type                 death_cert_form_type NOT NULL DEFAULT 'form_4',
    certifying_doctor_id      UUID REFERENCES users(id),
    witness_name              VARCHAR(200),
    notes                     TEXT,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- I. IPD Birth Records — Birth registration
CREATE TABLE ipd_birth_records (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID NOT NULL REFERENCES tenants(id),
    admission_id           UUID NOT NULL REFERENCES admissions(id),
    mother_patient_id      UUID NOT NULL REFERENCES patients(id),
    baby_patient_id        UUID REFERENCES patients(id),
    date_of_birth          DATE NOT NULL,
    time_of_birth          TIME NOT NULL,
    gender                 VARCHAR(20) NOT NULL,
    weight_grams           NUMERIC(7,1),
    length_cm              NUMERIC(5,1),
    head_circumference_cm  NUMERIC(5,1),
    apgar_1min             INT,
    apgar_5min             INT,
    delivery_type          VARCHAR(100),
    is_live_birth          BOOLEAN NOT NULL DEFAULT true,
    birth_certificate_number VARCHAR(100),
    complications          TEXT,
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- J. OT Consumable Usage — Consumables per surgery
CREATE TABLE ot_consumable_usage (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID NOT NULL REFERENCES tenants(id),
    booking_id   UUID NOT NULL REFERENCES ot_bookings(id),
    item_name    VARCHAR(200) NOT NULL,
    category     ot_consumable_category NOT NULL DEFAULT 'other',
    quantity     NUMERIC(10,2) NOT NULL DEFAULT 1,
    unit         VARCHAR(50),
    unit_price   NUMERIC(10,2),
    batch_number VARCHAR(100),
    recorded_by  UUID NOT NULL REFERENCES users(id),
    notes        TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- K. Discharge TAT Log — Discharge process milestones
CREATE TABLE ipd_discharge_tat_log (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID NOT NULL REFERENCES tenants(id),
    admission_id           UUID NOT NULL REFERENCES admissions(id) UNIQUE,
    discharge_initiated_at TIMESTAMPTZ,
    billing_cleared_at     TIMESTAMPTZ,
    pharmacy_cleared_at    TIMESTAMPTZ,
    nursing_cleared_at     TIMESTAMPTZ,
    doctor_cleared_at      TIMESTAMPTZ,
    discharge_completed_at TIMESTAMPTZ,
    total_tat_minutes      INT,
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ══════════════════════════════════════════════════════════
--  ALTER existing tables
-- ══════════════════════════════════════════════════════════

ALTER TABLE admissions
    ADD COLUMN IF NOT EXISTS ip_type ip_type,
    ADD COLUMN IF NOT EXISTS estimated_cost NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS is_critical BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS isolation_required BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS isolation_reason TEXT;

ALTER TABLE ipd_medication_administration
    ADD COLUMN IF NOT EXISTS prn_reason TEXT,
    ADD COLUMN IF NOT EXISTS missed_reason TEXT,
    ADD COLUMN IF NOT EXISTS double_checked_by UUID REFERENCES users(id);

ALTER TABLE ot_bookings
    ADD COLUMN IF NOT EXISTS actual_start_time TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS actual_end_time TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS turnaround_minutes INT;

ALTER TABLE bed_states
    ADD COLUMN IF NOT EXISTS is_isolation BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE ot_case_records
    ADD COLUMN IF NOT EXISTS surgical_site_infection BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS ssi_detected_at DATE;

-- ══════════════════════════════════════════════════════════
--  Row-Level Security
-- ══════════════════════════════════════════════════════════

ALTER TABLE ip_type_configurations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ip_type_configurations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE admission_checklists ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON admission_checklists
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE bed_reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bed_reservations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE bed_turnaround_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bed_turnaround_log
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ipd_clinical_documentations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ipd_clinical_documentations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE restraint_monitoring_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON restraint_monitoring_logs
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ipd_transfer_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ipd_transfer_logs
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ipd_death_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ipd_death_summaries
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ipd_birth_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ipd_birth_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ot_consumable_usage ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ot_consumable_usage
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE ipd_discharge_tat_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ipd_discharge_tat_log
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- ══════════════════════════════════════════════════════════
--  Triggers (updated_at)
-- ══════════════════════════════════════════════════════════

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ip_type_configurations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON admission_checklists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON bed_reservations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ipd_clinical_documentations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ipd_death_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ipd_birth_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON ipd_discharge_tat_log
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  Indexes
-- ══════════════════════════════════════════════════════════

CREATE INDEX idx_admission_checklists_admission ON admission_checklists(admission_id);
CREATE INDEX idx_bed_reservations_bed ON bed_reservations(bed_id, status);
CREATE INDEX idx_bed_reservations_patient ON bed_reservations(patient_id);
CREATE INDEX idx_bed_turnaround_bed ON bed_turnaround_log(bed_id);
CREATE INDEX idx_ipd_clinical_docs_admission ON ipd_clinical_documentations(admission_id);
CREATE INDEX idx_ipd_clinical_docs_type ON ipd_clinical_documentations(admission_id, doc_type);
CREATE INDEX idx_restraint_logs_doc ON restraint_monitoring_logs(clinical_doc_id);
CREATE INDEX idx_ipd_transfers_admission ON ipd_transfer_logs(admission_id);
CREATE INDEX idx_ipd_death_summaries_admission ON ipd_death_summaries(admission_id);
CREATE INDEX idx_ipd_birth_records_admission ON ipd_birth_records(admission_id);
CREATE INDEX idx_ot_consumables_booking ON ot_consumable_usage(booking_id);
CREATE INDEX idx_ipd_discharge_tat_admission ON ipd_discharge_tat_log(admission_id);
