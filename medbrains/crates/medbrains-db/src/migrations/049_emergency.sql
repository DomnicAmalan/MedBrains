-- Migration 049: Emergency Module
-- ER visits, triage, resuscitation, code activations, MLC management, mass casualty

-- ══════════════════════════════════════════════════════════
--  Enums
-- ══════════════════════════════════════════════════════════

CREATE TYPE triage_level AS ENUM (
    'immediate',    -- Red — life-threatening
    'emergent',     -- Orange — very urgent
    'urgent',       -- Yellow — urgent
    'less_urgent',  -- Green — less urgent
    'non_urgent',   -- Blue — non-urgent
    'expectant',    -- Black — deceased/expectant
    'unassigned'
);

CREATE TYPE er_visit_status AS ENUM (
    'registered',
    'triaged',
    'in_treatment',
    'observation',
    'admitted',
    'discharged',
    'transferred',
    'lama',
    'deceased'
);

CREATE TYPE mlc_status AS ENUM (
    'registered',
    'under_investigation',
    'opinion_given',
    'court_pending',
    'closed'
);

CREATE TYPE mass_casualty_status AS ENUM (
    'activated',
    'ongoing',
    'scaling_down',
    'deactivated'
);

-- ══════════════════════════════════════════════════════════
--  ER Visits
-- ══════════════════════════════════════════════════════════

CREATE TABLE er_visits (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    visit_number    TEXT NOT NULL,
    status          er_visit_status NOT NULL DEFAULT 'registered',
    arrival_mode    TEXT,                     -- ambulance, walk_in, police, referred
    arrival_time    TIMESTAMPTZ NOT NULL DEFAULT now(),
    chief_complaint TEXT,
    is_mlc          BOOLEAN NOT NULL DEFAULT false,
    is_brought_dead BOOLEAN NOT NULL DEFAULT false,
    triage_level    triage_level DEFAULT 'unassigned',
    attending_doctor_id UUID REFERENCES users(id),
    bay_number      TEXT,                     -- resuscitation bay assignment
    disposition     TEXT,                     -- admit, discharge, transfer, lama, deceased
    disposition_time TIMESTAMPTZ,
    disposition_notes TEXT,
    admitted_to     TEXT,                     -- IPD/ICU/OT ward
    admission_id    UUID,                     -- link to IPD admission
    door_to_doctor_mins INTEGER,              -- TAT: door to first doctor contact
    door_to_disposition_mins INTEGER,         -- TAT: door to disposition
    vitals          JSONB,                    -- initial vitals snapshot
    notes           TEXT,
    mass_casualty_event_id UUID,             -- link to mass casualty event
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_er_visits_tenant ON er_visits(tenant_id);
CREATE INDEX idx_er_visits_patient ON er_visits(tenant_id, patient_id);
CREATE INDEX idx_er_visits_status ON er_visits(tenant_id, status);
CREATE INDEX idx_er_visits_arrival ON er_visits(tenant_id, arrival_time);
CREATE INDEX idx_er_visits_mlc ON er_visits(tenant_id, is_mlc) WHERE is_mlc = true;

ALTER TABLE er_visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY er_visits_tenant ON er_visits
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Triage Assessments
-- ══════════════════════════════════════════════════════════

CREATE TABLE er_triage_assessments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    er_visit_id     UUID NOT NULL REFERENCES er_visits(id),
    triage_level    triage_level NOT NULL,
    triage_system   TEXT NOT NULL DEFAULT 'ESI',  -- ESI, START, MTS
    score           INTEGER,
    respiratory_rate INTEGER,
    pulse_rate      INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    spo2            INTEGER,
    gcs_score       INTEGER,                -- Glasgow Coma Scale (3-15)
    gcs_eye         INTEGER,
    gcs_verbal      INTEGER,
    gcs_motor       INTEGER,
    pain_score      INTEGER,                -- 0-10
    chief_complaint TEXT,
    presenting_symptoms JSONB,
    allergies       JSONB,
    is_pregnant     BOOLEAN DEFAULT false,
    disability_assessment TEXT,
    notes           TEXT,
    assessed_by     UUID REFERENCES users(id),
    assessed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_er_triage_tenant ON er_triage_assessments(tenant_id);
CREATE INDEX idx_er_triage_visit ON er_triage_assessments(er_visit_id);

ALTER TABLE er_triage_assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY er_triage_tenant ON er_triage_assessments
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Resuscitation Logs
-- ══════════════════════════════════════════════════════════

CREATE TABLE er_resuscitation_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    er_visit_id     UUID NOT NULL REFERENCES er_visits(id),
    log_type        TEXT NOT NULL,            -- medication, fluid, procedure, vitals, note
    timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
    medication_name TEXT,
    dose            TEXT,
    route           TEXT,                     -- IV, IM, SC, PO, ET
    fluid_name      TEXT,
    fluid_volume_ml INTEGER,
    procedure_name  TEXT,
    procedure_notes TEXT,
    vitals_snapshot JSONB,
    notes           TEXT,
    recorded_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_er_resus_tenant ON er_resuscitation_logs(tenant_id);
CREATE INDEX idx_er_resus_visit ON er_resuscitation_logs(er_visit_id);

ALTER TABLE er_resuscitation_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY er_resus_tenant ON er_resuscitation_logs
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Code Activations (Code Blue / Code Yellow)
-- ══════════════════════════════════════════════════════════

CREATE TABLE er_code_activations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    er_visit_id     UUID REFERENCES er_visits(id),
    code_type       TEXT NOT NULL,            -- blue, yellow, pink, orange
    activated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deactivated_at  TIMESTAMPTZ,
    location        TEXT,
    response_team   JSONB,                   -- array of { user_id, role, arrived_at }
    crash_cart_checklist JSONB,               -- { item: checked_at }
    outcome         TEXT,                     -- rosc, deceased, stabilized, transferred
    notes           TEXT,
    activated_by    UUID REFERENCES users(id),
    deactivated_by  UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_er_codes_tenant ON er_code_activations(tenant_id);
CREATE INDEX idx_er_codes_type ON er_code_activations(tenant_id, code_type);

ALTER TABLE er_code_activations ENABLE ROW LEVEL SECURITY;
CREATE POLICY er_codes_tenant ON er_code_activations
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  MLC Cases
-- ══════════════════════════════════════════════════════════

CREATE TABLE mlc_cases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    er_visit_id     UUID REFERENCES er_visits(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    mlc_number      TEXT NOT NULL,
    status          mlc_status NOT NULL DEFAULT 'registered',
    case_type       TEXT,                     -- assault, rta, burn, poisoning, sexual_assault, unknown
    fir_number      TEXT,
    police_station  TEXT,
    brought_by      TEXT,                     -- police, ambulance, bystander, self
    informant_name  TEXT,
    informant_relation TEXT,
    informant_contact TEXT,
    history_of_incident TEXT,
    examination_findings TEXT,
    medical_opinion TEXT,
    is_pocso        BOOLEAN NOT NULL DEFAULT false,
    is_death_case   BOOLEAN NOT NULL DEFAULT false,
    cause_of_death  TEXT,
    registered_by   UUID REFERENCES users(id),
    registered_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mlc_tenant ON mlc_cases(tenant_id);
CREATE INDEX idx_mlc_patient ON mlc_cases(tenant_id, patient_id);
CREATE INDEX idx_mlc_status ON mlc_cases(tenant_id, status);
CREATE UNIQUE INDEX idx_mlc_number ON mlc_cases(tenant_id, mlc_number);

ALTER TABLE mlc_cases ENABLE ROW LEVEL SECURITY;
CREATE POLICY mlc_tenant ON mlc_cases
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  MLC Documents (wound certs, age estimation, etc.)
-- ══════════════════════════════════════════════════════════

CREATE TABLE mlc_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    mlc_case_id     UUID NOT NULL REFERENCES mlc_cases(id),
    document_type   TEXT NOT NULL,            -- wound_certificate, age_estimation, sexual_assault, death_certificate, court_summons, opinion
    title           TEXT NOT NULL,
    body_diagram    JSONB,                   -- body region markers for wound certs
    content         JSONB NOT NULL,          -- structured document content
    generated_by    UUID REFERENCES users(id),
    verified_by     UUID REFERENCES users(id),
    verified_at     TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mlc_docs_tenant ON mlc_documents(tenant_id);
CREATE INDEX idx_mlc_docs_case ON mlc_documents(mlc_case_id);

ALTER TABLE mlc_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY mlc_docs_tenant ON mlc_documents
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  MLC Police Intimations
-- ══════════════════════════════════════════════════════════

CREATE TABLE mlc_police_intimations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    mlc_case_id     UUID NOT NULL REFERENCES mlc_cases(id),
    intimation_number TEXT NOT NULL,
    police_station  TEXT NOT NULL,
    officer_name    TEXT,
    officer_designation TEXT,
    officer_contact TEXT,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    sent_via        TEXT,                     -- phone, fax, email, in_person
    receipt_confirmed BOOLEAN NOT NULL DEFAULT false,
    receipt_confirmed_at TIMESTAMPTZ,
    receipt_number  TEXT,
    notes           TEXT,
    sent_by         UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mlc_police_tenant ON mlc_police_intimations(tenant_id);
CREATE INDEX idx_mlc_police_case ON mlc_police_intimations(mlc_case_id);

ALTER TABLE mlc_police_intimations ENABLE ROW LEVEL SECURITY;
CREATE POLICY mlc_police_tenant ON mlc_police_intimations
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Mass Casualty Events
-- ══════════════════════════════════════════════════════════

CREATE TABLE mass_casualty_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    event_name      TEXT NOT NULL,
    event_type      TEXT,                     -- natural_disaster, industrial, transport, violence, other
    status          mass_casualty_status NOT NULL DEFAULT 'activated',
    activated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deactivated_at  TIMESTAMPTZ,
    location        TEXT,
    estimated_casualties INTEGER,
    actual_casualties INTEGER,
    triage_summary  JSONB,                   -- { immediate: n, urgent: n, delayed: n, expectant: n }
    resources_deployed JSONB,                -- { beds: n, ventilators: n, blood_units: n, staff: n }
    notifications_sent JSONB,                -- array of { to, sent_at, channel }
    notes           TEXT,
    activated_by    UUID REFERENCES users(id),
    deactivated_by  UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_mass_casualty_tenant ON mass_casualty_events(tenant_id);
CREATE INDEX idx_mass_casualty_status ON mass_casualty_events(tenant_id, status);

ALTER TABLE mass_casualty_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY mass_casualty_tenant ON mass_casualty_events
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  Foreign key from er_visits to mass_casualty_events
-- ══════════════════════════════════════════════════════════

ALTER TABLE er_visits
    ADD CONSTRAINT fk_er_visits_mass_casualty
    FOREIGN KEY (mass_casualty_event_id) REFERENCES mass_casualty_events(id);

-- ══════════════════════════════════════════════════════════
--  Updated-at triggers
-- ══════════════════════════════════════════════════════════

CREATE TRIGGER set_er_visits_updated_at BEFORE UPDATE ON er_visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_er_triage_updated_at BEFORE UPDATE ON er_triage_assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_er_resus_updated_at BEFORE UPDATE ON er_resuscitation_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_er_codes_updated_at BEFORE UPDATE ON er_code_activations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_mlc_cases_updated_at BEFORE UPDATE ON mlc_cases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_mlc_docs_updated_at BEFORE UPDATE ON mlc_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_mlc_police_updated_at BEFORE UPDATE ON mlc_police_intimations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_mass_casualty_updated_at BEFORE UPDATE ON mass_casualty_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
