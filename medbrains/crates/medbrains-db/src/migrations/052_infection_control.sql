-- Migration 052: Infection Control
-- HAI Surveillance, Antibiotic Stewardship, Bio-Waste Management,
-- Hand Hygiene, and Outbreak Management.

-- ============================================================
-- Enums
-- ============================================================

CREATE TYPE hai_type AS ENUM (
    'clabsi',
    'cauti',
    'vap',
    'ssi',
    'cdiff',
    'mrsa',
    'other'
);

CREATE TYPE infection_status AS ENUM (
    'suspected',
    'confirmed',
    'ruled_out'
);

CREATE TYPE antibiotic_request_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);

CREATE TYPE antibiotic_action AS ENUM (
    'initiate',
    'escalate',
    'de_escalate',
    'stop'
);

CREATE TYPE waste_category AS ENUM (
    'yellow',
    'red',
    'white_translucent',
    'blue',
    'cytotoxic',
    'chemical',
    'radioactive'
);

CREATE TYPE outbreak_status AS ENUM (
    'suspected',
    'confirmed',
    'contained',
    'closed'
);

CREATE TYPE hygiene_moment AS ENUM (
    'before_patient',
    'before_aseptic',
    'after_body_fluid',
    'after_patient',
    'after_surroundings'
);

-- ============================================================
-- 1. infection_surveillance_events
-- ============================================================

CREATE TABLE infection_surveillance_events (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID NOT NULL REFERENCES tenants(id),
    patient_id             UUID NOT NULL REFERENCES patients(id),
    admission_id           UUID,
    hai_type               hai_type NOT NULL,
    infection_status       infection_status NOT NULL DEFAULT 'suspected',
    organism               TEXT,
    susceptibility_pattern JSONB,
    device_type            TEXT,
    insertion_date         TIMESTAMPTZ,
    infection_date         TIMESTAMPTZ NOT NULL,
    location_id            UUID REFERENCES locations(id),
    department_id          UUID REFERENCES departments(id),
    nhsn_criteria          TEXT,
    contributing_factors   JSONB,
    notes                  TEXT,
    reported_by            UUID NOT NULL REFERENCES users(id),
    confirmed_by           UUID REFERENCES users(id),
    confirmed_at           TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE infection_surveillance_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY infection_surveillance_events_tenant ON infection_surveillance_events
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_infection_surv_tenant ON infection_surveillance_events(tenant_id);
CREATE INDEX idx_infection_surv_patient ON infection_surveillance_events(tenant_id, patient_id);
CREATE INDEX idx_infection_surv_hai_type ON infection_surveillance_events(tenant_id, hai_type);
CREATE INDEX idx_infection_surv_status ON infection_surveillance_events(tenant_id, infection_status);
CREATE INDEX idx_infection_surv_dept ON infection_surveillance_events(tenant_id, department_id);

-- ============================================================
-- 2. infection_device_days
-- ============================================================

CREATE TABLE infection_device_days (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES tenants(id),
    location_id           UUID NOT NULL REFERENCES locations(id),
    department_id         UUID REFERENCES departments(id),
    record_date           DATE NOT NULL,
    patient_days          INT NOT NULL DEFAULT 0,
    central_line_days     INT NOT NULL DEFAULT 0,
    urinary_catheter_days INT NOT NULL DEFAULT 0,
    ventilator_days       INT NOT NULL DEFAULT 0,
    recorded_by           UUID NOT NULL REFERENCES users(id),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, location_id, record_date)
);

ALTER TABLE infection_device_days ENABLE ROW LEVEL SECURITY;
CREATE POLICY infection_device_days_tenant ON infection_device_days
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_infection_dd_tenant ON infection_device_days(tenant_id);
CREATE INDEX idx_infection_dd_date ON infection_device_days(tenant_id, record_date);
CREATE INDEX idx_infection_dd_dept ON infection_device_days(tenant_id, department_id);

-- ============================================================
-- 3. antibiotic_stewardship_requests
-- ============================================================

CREATE TABLE antibiotic_stewardship_requests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    patient_id        UUID NOT NULL REFERENCES patients(id),
    antibiotic_name   TEXT NOT NULL,
    dose              TEXT,
    route             TEXT,
    frequency         TEXT,
    duration_days     INT,
    indication        TEXT NOT NULL,
    culture_sent      BOOLEAN NOT NULL DEFAULT false,
    culture_result    TEXT,
    request_status    antibiotic_request_status NOT NULL DEFAULT 'pending',
    requested_by      UUID NOT NULL REFERENCES users(id),
    requested_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_by       UUID REFERENCES users(id),
    reviewed_at       TIMESTAMPTZ,
    review_notes      TEXT,
    escalation_reason TEXT,
    auto_stop_date    DATE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE antibiotic_stewardship_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY antibiotic_stewardship_requests_tenant ON antibiotic_stewardship_requests
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_abx_steward_tenant ON antibiotic_stewardship_requests(tenant_id);
CREATE INDEX idx_abx_steward_patient ON antibiotic_stewardship_requests(tenant_id, patient_id);
CREATE INDEX idx_abx_steward_status ON antibiotic_stewardship_requests(tenant_id, request_status);

-- ============================================================
-- 4. antibiotic_consumption_records
-- ============================================================

CREATE TABLE antibiotic_consumption_records (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                 UUID NOT NULL REFERENCES tenants(id),
    department_id             UUID REFERENCES departments(id),
    antibiotic_name           TEXT NOT NULL,
    atc_code                  TEXT,
    record_month              DATE NOT NULL,
    quantity_used             NUMERIC NOT NULL,
    ddd                       NUMERIC,
    patient_days              INT NOT NULL DEFAULT 0,
    ddd_per_1000_patient_days NUMERIC,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, department_id, antibiotic_name, record_month)
);

ALTER TABLE antibiotic_consumption_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY antibiotic_consumption_records_tenant ON antibiotic_consumption_records
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_abx_consumption_tenant ON antibiotic_consumption_records(tenant_id);
CREATE INDEX idx_abx_consumption_dept ON antibiotic_consumption_records(tenant_id, department_id);

-- ============================================================
-- 5. biowaste_records
-- ============================================================

CREATE TABLE biowaste_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    department_id   UUID NOT NULL REFERENCES departments(id),
    waste_category  waste_category NOT NULL,
    weight_kg       NUMERIC(10,3) NOT NULL,
    record_date     DATE NOT NULL,
    container_count INT NOT NULL DEFAULT 1,
    disposal_vendor TEXT,
    manifest_number TEXT,
    notes           TEXT,
    recorded_by     UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE biowaste_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY biowaste_records_tenant ON biowaste_records
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_biowaste_tenant ON biowaste_records(tenant_id);
CREATE INDEX idx_biowaste_date ON biowaste_records(tenant_id, record_date);
CREATE INDEX idx_biowaste_dept ON biowaste_records(tenant_id, department_id);

-- ============================================================
-- 6. needle_stick_incidents
-- ============================================================

CREATE TABLE needle_stick_incidents (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES tenants(id),
    incident_number    TEXT NOT NULL,
    staff_id           UUID NOT NULL REFERENCES users(id),
    incident_date      TIMESTAMPTZ NOT NULL,
    location_id        UUID REFERENCES locations(id),
    department_id      UUID REFERENCES departments(id),
    device_type        TEXT NOT NULL,
    procedure_during   TEXT,
    body_part          TEXT,
    depth              TEXT,
    source_patient_id  UUID REFERENCES patients(id),
    hiv_status         TEXT,
    hbv_status         TEXT,
    hcv_status         TEXT,
    pep_initiated      BOOLEAN NOT NULL DEFAULT false,
    pep_details        TEXT,
    follow_up_schedule JSONB,
    outcome            TEXT,
    reported_by        UUID NOT NULL REFERENCES users(id),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE needle_stick_incidents ENABLE ROW LEVEL SECURITY;
CREATE POLICY needle_stick_incidents_tenant ON needle_stick_incidents
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_needle_stick_tenant ON needle_stick_incidents(tenant_id);
CREATE INDEX idx_needle_stick_patient ON needle_stick_incidents(tenant_id, source_patient_id);
CREATE INDEX idx_needle_stick_dept ON needle_stick_incidents(tenant_id, department_id);

-- ============================================================
-- 7. hand_hygiene_audits
-- ============================================================

CREATE TABLE hand_hygiene_audits (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    audit_date       TIMESTAMPTZ NOT NULL,
    location_id      UUID REFERENCES locations(id),
    department_id    UUID NOT NULL REFERENCES departments(id),
    auditor_id       UUID NOT NULL REFERENCES users(id),
    observations     INT NOT NULL DEFAULT 0,
    compliant        INT NOT NULL DEFAULT 0,
    non_compliant    INT NOT NULL DEFAULT 0,
    compliance_rate  NUMERIC(5,2),
    moment_breakdown JSONB,
    staff_category   TEXT,
    findings         TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE hand_hygiene_audits ENABLE ROW LEVEL SECURITY;
CREATE POLICY hand_hygiene_audits_tenant ON hand_hygiene_audits
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_hand_hygiene_tenant ON hand_hygiene_audits(tenant_id);
CREATE INDEX idx_hand_hygiene_dept ON hand_hygiene_audits(tenant_id, department_id);

-- ============================================================
-- 8. culture_surveillance
-- ============================================================

CREATE TABLE culture_surveillance (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    culture_type    TEXT NOT NULL,
    sample_site     TEXT NOT NULL,
    location_id     UUID REFERENCES locations(id),
    department_id   UUID REFERENCES departments(id),
    collection_date TIMESTAMPTZ NOT NULL,
    result          TEXT,
    organism        TEXT,
    colony_count    INT,
    acceptable      BOOLEAN,
    action_taken    TEXT,
    collected_by    UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE culture_surveillance ENABLE ROW LEVEL SECURITY;
CREATE POLICY culture_surveillance_tenant ON culture_surveillance
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_culture_surv_tenant ON culture_surveillance(tenant_id);
CREATE INDEX idx_culture_surv_dept ON culture_surveillance(tenant_id, department_id);

-- ============================================================
-- 9. outbreak_events
-- ============================================================

CREATE TABLE outbreak_events (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    outbreak_number  TEXT NOT NULL,
    organism         TEXT NOT NULL,
    outbreak_status  outbreak_status NOT NULL DEFAULT 'suspected',
    detected_date    TIMESTAMPTZ NOT NULL,
    location_id      UUID REFERENCES locations(id),
    department_id    UUID REFERENCES departments(id),
    initial_cases    INT NOT NULL DEFAULT 1,
    total_cases      INT NOT NULL DEFAULT 1,
    description      TEXT,
    control_measures JSONB,
    hicc_notified    BOOLEAN NOT NULL DEFAULT false,
    hicc_notified_at TIMESTAMPTZ,
    containment_date TIMESTAMPTZ,
    closure_date     TIMESTAMPTZ,
    root_cause       TEXT,
    lessons_learned  TEXT,
    reported_by      UUID NOT NULL REFERENCES users(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE outbreak_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY outbreak_events_tenant ON outbreak_events
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_outbreak_events_tenant ON outbreak_events(tenant_id);
CREATE INDEX idx_outbreak_events_status ON outbreak_events(tenant_id, outbreak_status);
CREATE INDEX idx_outbreak_events_dept ON outbreak_events(tenant_id, department_id);

-- ============================================================
-- 10. outbreak_contacts
-- ============================================================

CREATE TABLE outbreak_contacts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    outbreak_id         UUID NOT NULL REFERENCES outbreak_events(id) ON DELETE CASCADE,
    patient_id          UUID REFERENCES patients(id),
    staff_id            UUID REFERENCES users(id),
    contact_type        TEXT NOT NULL,
    exposure_date       TIMESTAMPTZ,
    screening_date      TIMESTAMPTZ,
    screening_result    TEXT,
    quarantine_required BOOLEAN NOT NULL DEFAULT false,
    quarantine_start    DATE,
    quarantine_end      DATE,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE outbreak_contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY outbreak_contacts_tenant ON outbreak_contacts
    USING (tenant_id = current_setting('app.tenant_id')::UUID);

CREATE INDEX idx_outbreak_contacts_tenant ON outbreak_contacts(tenant_id);
CREATE INDEX idx_outbreak_contacts_outbreak ON outbreak_contacts(tenant_id, outbreak_id);

-- ============================================================
-- Triggers
-- ============================================================

CREATE TRIGGER set_infection_surveillance_events_updated_at BEFORE UPDATE ON infection_surveillance_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_infection_device_days_updated_at BEFORE UPDATE ON infection_device_days
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_antibiotic_stewardship_requests_updated_at BEFORE UPDATE ON antibiotic_stewardship_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_antibiotic_consumption_records_updated_at BEFORE UPDATE ON antibiotic_consumption_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_biowaste_records_updated_at BEFORE UPDATE ON biowaste_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_needle_stick_incidents_updated_at BEFORE UPDATE ON needle_stick_incidents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_hand_hygiene_audits_updated_at BEFORE UPDATE ON hand_hygiene_audits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_culture_surveillance_updated_at BEFORE UPDATE ON culture_surveillance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_outbreak_events_updated_at BEFORE UPDATE ON outbreak_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_outbreak_contacts_updated_at BEFORE UPDATE ON outbreak_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
