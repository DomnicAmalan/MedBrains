-- ============================================================
-- Migration 054: Operation Theatre (OT) Module
-- Complete surgical workflow: bookings, pre-op assessment,
-- WHO surgical safety checklists, case records, anesthesia
-- records, post-op recovery (PACU), surgeon preference cards.
-- ============================================================

-- ── New Enums ───────────────────────────────────────────────

CREATE TYPE ot_booking_status AS ENUM (
    'requested',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled',
    'postponed'
);

CREATE TYPE ot_case_priority AS ENUM (
    'elective',
    'urgent',
    'emergency'
);

CREATE TYPE anesthesia_type AS ENUM (
    'general',
    'spinal',
    'epidural',
    'regional_block',
    'local',
    'sedation',
    'combined'
);

CREATE TYPE asa_classification AS ENUM (
    'asa_1',
    'asa_2',
    'asa_3',
    'asa_4',
    'asa_5',
    'asa_6'
);

CREATE TYPE checklist_phase AS ENUM (
    'sign_in',
    'time_out',
    'sign_out'
);

CREATE TYPE ot_room_status AS ENUM (
    'available',
    'in_use',
    'cleaning',
    'maintenance',
    'reserved'
);

CREATE TYPE preop_clearance_status AS ENUM (
    'pending',
    'cleared',
    'not_cleared',
    'conditional'
);

CREATE TYPE postop_recovery_status AS ENUM (
    'in_recovery',
    'stable',
    'shifted_to_ward',
    'shifted_to_icu',
    'discharged'
);

-- ── Table: ot_rooms ─────────────────────────────────────────

CREATE TABLE ot_rooms (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    location_id     UUID REFERENCES locations(id),
    name            TEXT NOT NULL,
    code            VARCHAR(30) NOT NULL,
    status          ot_room_status NOT NULL DEFAULT 'available',
    specialties     JSONB NOT NULL DEFAULT '[]',
    equipment       JSONB NOT NULL DEFAULT '[]',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_ot_rooms_tenant ON ot_rooms(tenant_id);
CREATE INDEX idx_ot_rooms_status ON ot_rooms(tenant_id, status);

ALTER TABLE ot_rooms ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_rooms ON ot_rooms
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_rooms_updated
    BEFORE UPDATE ON ot_rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ot_bookings ──────────────────────────────────────

CREATE TABLE ot_bookings (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    admission_id        UUID REFERENCES admissions(id),
    ot_room_id          UUID NOT NULL REFERENCES ot_rooms(id),
    primary_surgeon_id  UUID NOT NULL REFERENCES users(id),
    anesthetist_id      UUID REFERENCES users(id),
    scheduled_date      DATE NOT NULL,
    scheduled_start     TIMESTAMPTZ NOT NULL,
    scheduled_end       TIMESTAMPTZ NOT NULL,
    actual_start        TIMESTAMPTZ,
    actual_end          TIMESTAMPTZ,
    procedure_name      TEXT NOT NULL,
    procedure_code      VARCHAR(20),
    laterality          VARCHAR(10),
    priority            ot_case_priority NOT NULL DEFAULT 'elective',
    status              ot_booking_status NOT NULL DEFAULT 'requested',
    consent_obtained    BOOLEAN NOT NULL DEFAULT false,
    site_marked         BOOLEAN NOT NULL DEFAULT false,
    blood_arranged      BOOLEAN NOT NULL DEFAULT false,
    assistant_surgeons  JSONB NOT NULL DEFAULT '[]',
    scrub_nurses        JSONB NOT NULL DEFAULT '[]',
    circulating_nurses  JSONB NOT NULL DEFAULT '[]',
    estimated_duration_min INTEGER,
    cancellation_reason TEXT,
    postpone_reason     TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ot_bookings_tenant ON ot_bookings(tenant_id);
CREATE INDEX idx_ot_bookings_patient ON ot_bookings(patient_id);
CREATE INDEX idx_ot_bookings_date ON ot_bookings(tenant_id, scheduled_date);
CREATE INDEX idx_ot_bookings_room ON ot_bookings(ot_room_id, scheduled_date);
CREATE INDEX idx_ot_bookings_surgeon ON ot_bookings(primary_surgeon_id, scheduled_date);
CREATE INDEX idx_ot_bookings_status ON ot_bookings(tenant_id, status);

ALTER TABLE ot_bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_bookings ON ot_bookings
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_bookings_updated
    BEFORE UPDATE ON ot_bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ot_preop_assessments ─────────────────────────────

CREATE TABLE ot_preop_assessments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    booking_id          UUID NOT NULL REFERENCES ot_bookings(id),
    clearance_status    preop_clearance_status NOT NULL DEFAULT 'pending',
    asa_class           asa_classification,
    airway_assessment   JSONB NOT NULL DEFAULT '{}',
    cardiac_assessment  JSONB NOT NULL DEFAULT '{}',
    pulmonary_assessment JSONB NOT NULL DEFAULT '{}',
    lab_results_reviewed BOOLEAN NOT NULL DEFAULT false,
    imaging_reviewed    BOOLEAN NOT NULL DEFAULT false,
    blood_group_confirmed BOOLEAN NOT NULL DEFAULT false,
    fasting_status      BOOLEAN NOT NULL DEFAULT false,
    npo_since           TIMESTAMPTZ,
    allergies_noted     TEXT,
    current_medications TEXT,
    conditions          TEXT,
    assessed_by         UUID NOT NULL REFERENCES users(id),
    assessed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ot_preop_tenant ON ot_preop_assessments(tenant_id);
CREATE INDEX idx_ot_preop_booking ON ot_preop_assessments(booking_id);

ALTER TABLE ot_preop_assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_preop ON ot_preop_assessments
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_preop_updated
    BEFORE UPDATE ON ot_preop_assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ot_surgical_safety_checklists ────────────────────
-- WHO Surgical Safety Checklist: sign_in, time_out, sign_out

CREATE TABLE ot_surgical_safety_checklists (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    booking_id      UUID NOT NULL REFERENCES ot_bookings(id),
    phase           checklist_phase NOT NULL,
    items           JSONB NOT NULL DEFAULT '[]',
    completed       BOOLEAN NOT NULL DEFAULT false,
    completed_by    UUID REFERENCES users(id),
    completed_at    TIMESTAMPTZ,
    verified_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, booking_id, phase)
);

CREATE INDEX idx_ot_safety_tenant ON ot_surgical_safety_checklists(tenant_id);
CREATE INDEX idx_ot_safety_booking ON ot_surgical_safety_checklists(booking_id);

ALTER TABLE ot_surgical_safety_checklists ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_safety ON ot_surgical_safety_checklists
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_safety_updated
    BEFORE UPDATE ON ot_surgical_safety_checklists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ot_case_records ──────────────────────────────────

CREATE TABLE ot_case_records (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    booking_id              UUID NOT NULL REFERENCES ot_bookings(id),
    surgeon_id              UUID NOT NULL REFERENCES users(id),
    patient_in_time         TIMESTAMPTZ,
    patient_out_time        TIMESTAMPTZ,
    incision_time           TIMESTAMPTZ,
    closure_time            TIMESTAMPTZ,
    procedure_performed     TEXT NOT NULL,
    findings                TEXT,
    technique               TEXT,
    complications           TEXT,
    blood_loss_ml           INTEGER,
    specimens               JSONB NOT NULL DEFAULT '[]',
    implants                JSONB NOT NULL DEFAULT '[]',
    drains                  JSONB NOT NULL DEFAULT '[]',
    instrument_count_correct_before BOOLEAN,
    instrument_count_correct_after  BOOLEAN,
    sponge_count_correct    BOOLEAN,
    cssd_issuance_ids       JSONB NOT NULL DEFAULT '[]',
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ot_case_records_tenant ON ot_case_records(tenant_id);
CREATE INDEX idx_ot_case_records_booking ON ot_case_records(booking_id);

ALTER TABLE ot_case_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_case_records ON ot_case_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_case_records_updated
    BEFORE UPDATE ON ot_case_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ot_anesthesia_records ────────────────────────────

CREATE TABLE ot_anesthesia_records (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    booking_id          UUID NOT NULL REFERENCES ot_bookings(id),
    anesthetist_id      UUID NOT NULL REFERENCES users(id),
    anesthesia_type     anesthesia_type NOT NULL,
    asa_class           asa_classification,
    induction_time      TIMESTAMPTZ,
    intubation_time     TIMESTAMPTZ,
    extubation_time     TIMESTAMPTZ,
    airway_details      JSONB NOT NULL DEFAULT '{}',
    drugs_administered  JSONB NOT NULL DEFAULT '[]',
    monitoring_events   JSONB NOT NULL DEFAULT '[]',
    fluids_given        JSONB NOT NULL DEFAULT '[]',
    blood_products      JSONB NOT NULL DEFAULT '[]',
    adverse_events      JSONB NOT NULL DEFAULT '[]',
    complications       TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ot_anesthesia_tenant ON ot_anesthesia_records(tenant_id);
CREATE INDEX idx_ot_anesthesia_booking ON ot_anesthesia_records(booking_id);

ALTER TABLE ot_anesthesia_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_anesthesia ON ot_anesthesia_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_anesthesia_updated
    BEFORE UPDATE ON ot_anesthesia_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ot_postop_records ────────────────────────────────

CREATE TABLE ot_postop_records (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    booking_id              UUID NOT NULL REFERENCES ot_bookings(id),
    destination_bed_id      UUID REFERENCES locations(id),
    recovery_status         postop_recovery_status NOT NULL DEFAULT 'in_recovery',
    arrival_time            TIMESTAMPTZ,
    discharge_time          TIMESTAMPTZ,
    aldrete_score_arrival   INTEGER,
    aldrete_score_discharge INTEGER,
    vitals_on_arrival       JSONB NOT NULL DEFAULT '{}',
    monitoring_entries      JSONB NOT NULL DEFAULT '[]',
    pain_assessment         TEXT,
    fluid_orders            TEXT,
    diet_orders             TEXT,
    activity_orders         TEXT,
    disposition             TEXT,
    postop_orders           JSONB NOT NULL DEFAULT '[]',
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ot_postop_tenant ON ot_postop_records(tenant_id);
CREATE INDEX idx_ot_postop_booking ON ot_postop_records(booking_id);

ALTER TABLE ot_postop_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_postop ON ot_postop_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_postop_updated
    BEFORE UPDATE ON ot_postop_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Table: ot_surgeon_preferences ───────────────────────────

CREATE TABLE ot_surgeon_preferences (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    surgeon_id          UUID NOT NULL REFERENCES users(id),
    procedure_name      TEXT NOT NULL,
    position            TEXT,
    skin_prep           TEXT,
    draping             TEXT,
    instruments         JSONB NOT NULL DEFAULT '[]',
    sutures             JSONB NOT NULL DEFAULT '[]',
    implants            JSONB NOT NULL DEFAULT '[]',
    equipment           JSONB NOT NULL DEFAULT '[]',
    medications         JSONB NOT NULL DEFAULT '[]',
    special_instructions TEXT,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, surgeon_id, procedure_name)
);

CREATE INDEX idx_ot_surgeon_prefs_tenant ON ot_surgeon_preferences(tenant_id);
CREATE INDEX idx_ot_surgeon_prefs_surgeon ON ot_surgeon_preferences(surgeon_id);

ALTER TABLE ot_surgeon_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ot_surgeon_prefs ON ot_surgeon_preferences
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_ot_surgeon_prefs_updated
    BEFORE UPDATE ON ot_surgeon_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
