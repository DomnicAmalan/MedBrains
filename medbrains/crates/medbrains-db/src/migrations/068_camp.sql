-- 068_camp.sql — Camp Management Module
-- Hospital outreach camps: planning, registration, screening, lab, billing, follow-up
-- NABH community engagement, health screening drives, blood donation camps

-- ═══════════════════════════════════════════════════════════
--  ENUMS
-- ═══════════════════════════════════════════════════════════

CREATE TYPE camp_type AS ENUM (
    'general_health', 'blood_donation', 'vaccination', 'eye_screening',
    'dental', 'awareness', 'specialized'
);

CREATE TYPE camp_status AS ENUM (
    'planned', 'approved', 'setup', 'active', 'completed', 'cancelled'
);

CREATE TYPE camp_registration_status AS ENUM (
    'registered', 'screened', 'referred', 'converted', 'no_show'
);

CREATE TYPE camp_followup_status AS ENUM (
    'scheduled', 'completed', 'missed', 'cancelled'
);

-- ═══════════════════════════════════════════════════════════
--  TABLES
-- ═══════════════════════════════════════════════════════════

-- ── 1. Camps (master record) ─────────────────────────────

CREATE TABLE camps (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                UUID NOT NULL REFERENCES tenants(id),
    camp_code                TEXT NOT NULL,
    name                     TEXT NOT NULL,
    camp_type                camp_type NOT NULL,
    status                   camp_status NOT NULL DEFAULT 'planned',
    organizing_department_id UUID REFERENCES departments(id),
    coordinator_id           UUID REFERENCES employees(id),
    scheduled_date           DATE NOT NULL,
    start_time               TEXT,
    end_time                 TEXT,
    venue_name               TEXT,
    venue_address            TEXT,
    venue_city               TEXT,
    venue_state              TEXT,
    venue_pincode            TEXT,
    venue_latitude           DOUBLE PRECISION,
    venue_longitude          DOUBLE PRECISION,
    expected_participants    INTEGER,
    actual_participants      INTEGER,
    budget_allocated         NUMERIC(12,2) DEFAULT 0,
    budget_spent             NUMERIC(12,2) DEFAULT 0,
    logistics_notes          TEXT,
    equipment_list           JSONB,
    is_free                  BOOLEAN NOT NULL DEFAULT TRUE,
    discount_percentage      NUMERIC(5,2) DEFAULT 0,
    approved_by              UUID REFERENCES users(id),
    approved_at              TIMESTAMPTZ,
    completed_at             TIMESTAMPTZ,
    cancellation_reason      TEXT,
    summary_notes            TEXT,
    created_by               UUID REFERENCES users(id),
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, camp_code)
);

ALTER TABLE camps ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON camps
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_camps_tenant ON camps(tenant_id);
CREATE INDEX idx_camps_status ON camps(tenant_id, status);
CREATE INDEX idx_camps_date ON camps(tenant_id, scheduled_date DESC);
CREATE TRIGGER trg_camps_updated_at
    BEFORE UPDATE ON camps FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 2. Camp Team Members ─────────────────────────────────

CREATE TABLE camp_team_members (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    camp_id       UUID NOT NULL REFERENCES camps(id) ON DELETE CASCADE,
    employee_id   UUID NOT NULL REFERENCES employees(id),
    role_in_camp  TEXT NOT NULL,
    is_confirmed  BOOLEAN NOT NULL DEFAULT FALSE,
    notes         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, camp_id, employee_id)
);

ALTER TABLE camp_team_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON camp_team_members
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_camp_team_tenant ON camp_team_members(tenant_id);
CREATE INDEX idx_camp_team_camp ON camp_team_members(tenant_id, camp_id);
CREATE TRIGGER trg_camp_team_updated_at
    BEFORE UPDATE ON camp_team_members FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 3. Camp Registrations ────────────────────────────────

CREATE TABLE camp_registrations (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    camp_id              UUID NOT NULL REFERENCES camps(id),
    registration_number  TEXT NOT NULL,
    person_name          TEXT NOT NULL,
    age                  INTEGER,
    gender               TEXT,
    phone                TEXT,
    address              TEXT,
    id_proof_type        TEXT,
    id_proof_number      TEXT,
    patient_id           UUID REFERENCES patients(id),
    status               camp_registration_status NOT NULL DEFAULT 'registered',
    chief_complaint      TEXT,
    is_walk_in           BOOLEAN NOT NULL DEFAULT TRUE,
    registered_by        UUID REFERENCES users(id),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE camp_registrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON camp_registrations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_camp_reg_tenant ON camp_registrations(tenant_id);
CREATE INDEX idx_camp_reg_camp ON camp_registrations(tenant_id, camp_id);
CREATE INDEX idx_camp_reg_patient ON camp_registrations(tenant_id, patient_id);
CREATE TRIGGER trg_camp_reg_updated_at
    BEFORE UPDATE ON camp_registrations FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 4. Camp Screenings ───────────────────────────────────

CREATE TABLE camp_screenings (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    registration_id      UUID NOT NULL REFERENCES camp_registrations(id),
    bp_systolic          INTEGER,
    bp_diastolic         INTEGER,
    pulse_rate           INTEGER,
    spo2                 INTEGER,
    temperature          NUMERIC(4,1),
    blood_sugar_random   NUMERIC(6,1),
    bmi                  NUMERIC(5,2),
    height_cm            NUMERIC(5,1),
    weight_kg            NUMERIC(5,1),
    visual_acuity_left   TEXT,
    visual_acuity_right  TEXT,
    findings             TEXT,
    diagnosis            TEXT,
    advice               TEXT,
    referred_to_hospital BOOLEAN NOT NULL DEFAULT FALSE,
    referral_department  TEXT,
    referral_urgency     TEXT,
    screened_by          UUID REFERENCES users(id),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE camp_screenings ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON camp_screenings
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_camp_scr_tenant ON camp_screenings(tenant_id);
CREATE INDEX idx_camp_scr_reg ON camp_screenings(tenant_id, registration_id);
CREATE TRIGGER trg_camp_scr_updated_at
    BEFORE UPDATE ON camp_screenings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 5. Camp Lab Samples ──────────────────────────────────

CREATE TABLE camp_lab_samples (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    registration_id   UUID NOT NULL REFERENCES camp_registrations(id),
    sample_type       TEXT NOT NULL,
    test_requested    TEXT,
    barcode           TEXT,
    collected_at      TIMESTAMPTZ DEFAULT now(),
    collected_by      UUID REFERENCES users(id),
    sent_to_lab       BOOLEAN NOT NULL DEFAULT FALSE,
    lab_order_id      UUID REFERENCES lab_orders(id),
    result_summary    TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE camp_lab_samples ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON camp_lab_samples
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_camp_lab_tenant ON camp_lab_samples(tenant_id);
CREATE INDEX idx_camp_lab_reg ON camp_lab_samples(tenant_id, registration_id);
CREATE TRIGGER trg_camp_lab_updated_at
    BEFORE UPDATE ON camp_lab_samples FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 6. Camp Billing Records ─────────────────────────────

CREATE TABLE camp_billing_records (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    registration_id      UUID NOT NULL REFERENCES camp_registrations(id),
    service_description  TEXT NOT NULL,
    standard_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount_percentage  NUMERIC(5,2) DEFAULT 0,
    charged_amount       NUMERIC(12,2) NOT NULL DEFAULT 0,
    is_free              BOOLEAN NOT NULL DEFAULT TRUE,
    payment_mode         TEXT,
    payment_reference    TEXT,
    billed_by            UUID REFERENCES users(id),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE camp_billing_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON camp_billing_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_camp_bill_tenant ON camp_billing_records(tenant_id);
CREATE INDEX idx_camp_bill_reg ON camp_billing_records(tenant_id, registration_id);
CREATE TRIGGER trg_camp_bill_updated_at
    BEFORE UPDATE ON camp_billing_records FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 7. Camp Follow-ups ──────────────────────────────────

CREATE TABLE camp_followups (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    registration_id         UUID NOT NULL REFERENCES camp_registrations(id),
    followup_date           DATE NOT NULL,
    followup_type           TEXT NOT NULL,
    status                  camp_followup_status NOT NULL DEFAULT 'scheduled',
    notes                   TEXT,
    outcome                 TEXT,
    converted_to_patient    BOOLEAN NOT NULL DEFAULT FALSE,
    converted_patient_id    UUID REFERENCES patients(id),
    converted_department_id UUID REFERENCES departments(id),
    followed_up_by          UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE camp_followups ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON camp_followups
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_camp_fu_tenant ON camp_followups(tenant_id);
CREATE INDEX idx_camp_fu_reg ON camp_followups(tenant_id, registration_id);
CREATE INDEX idx_camp_fu_date ON camp_followups(tenant_id, followup_date);
CREATE TRIGGER trg_camp_fu_updated_at
    BEFORE UPDATE ON camp_followups FOR EACH ROW EXECUTE FUNCTION update_updated_at();
