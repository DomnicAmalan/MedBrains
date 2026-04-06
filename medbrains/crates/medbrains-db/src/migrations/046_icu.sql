-- ICU / Critical Care module
-- Extends IPD admission infrastructure with ICU-specific clinical tracking

-- ============================================================
-- Enums
-- ============================================================

CREATE TYPE icu_score_type AS ENUM (
    'apache_ii', 'apache_iv', 'sofa', 'gcs', 'prism', 'snappe', 'rass', 'cam_icu'
);

CREATE TYPE ventilator_mode AS ENUM (
    'cmv', 'acv', 'simv', 'psv', 'cpap', 'bipap', 'hfov', 'aprv', 'niv', 'other'
);

CREATE TYPE device_type AS ENUM (
    'central_line', 'urinary_catheter', 'ventilator', 'arterial_line',
    'peripheral_iv', 'nasogastric_tube', 'chest_tube', 'tracheostomy'
);

CREATE TYPE nutrition_route AS ENUM (
    'enteral', 'parenteral', 'oral', 'npo'
);

-- ============================================================
-- 1. ICU Flowsheets — hourly/periodic charting
-- ============================================================

CREATE TABLE icu_flowsheets (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by     UUID NOT NULL REFERENCES users(id),
    -- Vitals
    heart_rate      INTEGER,
    systolic_bp     INTEGER,
    diastolic_bp    INTEGER,
    mean_arterial_bp INTEGER,
    respiratory_rate INTEGER,
    spo2            NUMERIC(5,2),
    temperature     NUMERIC(5,2),
    cvp             NUMERIC(5,2),
    -- I/O balance
    intake_ml       INTEGER,
    output_ml       INTEGER,
    urine_ml        INTEGER,
    drain_ml        INTEGER,
    -- Infusion tracking
    infusions       JSONB DEFAULT '[]',
    -- Notes
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icu_flowsheets_tenant ON icu_flowsheets(tenant_id);
CREATE INDEX idx_icu_flowsheets_admission ON icu_flowsheets(admission_id);
CREATE INDEX idx_icu_flowsheets_time ON icu_flowsheets(recorded_at);

-- ============================================================
-- 2. Ventilator Records
-- ============================================================

CREATE TABLE icu_ventilator_records (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by     UUID NOT NULL REFERENCES users(id),
    mode            ventilator_mode NOT NULL,
    fio2            NUMERIC(5,2),
    peep            NUMERIC(5,2),
    tidal_volume    INTEGER,
    respiratory_rate INTEGER,
    pip             NUMERIC(5,2),
    plateau_pressure NUMERIC(5,2),
    -- ABG correlation
    ph              NUMERIC(5,3),
    pao2            NUMERIC(6,2),
    paco2           NUMERIC(6,2),
    hco3            NUMERIC(5,2),
    sao2            NUMERIC(5,2),
    lactate         NUMERIC(5,2),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icu_ventilator_tenant ON icu_ventilator_records(tenant_id);
CREATE INDEX idx_icu_ventilator_admission ON icu_ventilator_records(admission_id);

-- ============================================================
-- 3. Critical Care Scores
-- ============================================================

CREATE TABLE icu_scores (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    score_type      icu_score_type NOT NULL,
    score_value     INTEGER NOT NULL,
    score_details   JSONB DEFAULT '{}',
    predicted_mortality NUMERIC(5,2),
    scored_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    scored_by       UUID NOT NULL REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icu_scores_tenant ON icu_scores(tenant_id);
CREATE INDEX idx_icu_scores_admission ON icu_scores(admission_id);
CREATE INDEX idx_icu_scores_type ON icu_scores(score_type);

-- ============================================================
-- 4. Device / Bundle Tracking
-- ============================================================

CREATE TABLE icu_devices (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    device_type     device_type NOT NULL,
    inserted_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    inserted_by     UUID REFERENCES users(id),
    removed_at      TIMESTAMPTZ,
    removed_by      UUID REFERENCES users(id),
    site            VARCHAR(200),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icu_devices_tenant ON icu_devices(tenant_id);
CREATE INDEX idx_icu_devices_admission ON icu_devices(admission_id);
CREATE INDEX idx_icu_devices_active ON icu_devices(is_active);

-- ============================================================
-- 5. Bundle Compliance Checks
-- ============================================================

CREATE TABLE icu_bundle_checks (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    device_id       UUID NOT NULL REFERENCES icu_devices(id),
    checked_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    checked_by      UUID NOT NULL REFERENCES users(id),
    is_compliant    BOOLEAN NOT NULL,
    still_needed    BOOLEAN NOT NULL DEFAULT true,
    checklist       JSONB DEFAULT '{}',
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icu_bundle_tenant ON icu_bundle_checks(tenant_id);
CREATE INDEX idx_icu_bundle_device ON icu_bundle_checks(device_id);

-- ============================================================
-- 6. Nutrition Tracking
-- ============================================================

CREATE TABLE icu_nutrition (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by     UUID NOT NULL REFERENCES users(id),
    route           nutrition_route NOT NULL,
    formula_name    VARCHAR(200),
    rate_ml_hr      NUMERIC(6,2),
    calories_kcal   NUMERIC(8,2),
    protein_gm      NUMERIC(6,2),
    volume_ml       INTEGER,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icu_nutrition_tenant ON icu_nutrition(tenant_id);
CREATE INDEX idx_icu_nutrition_admission ON icu_nutrition(admission_id);

-- ============================================================
-- 7. NICU — Neonatal-specific records
-- ============================================================

CREATE TABLE icu_neonatal_records (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by     UUID NOT NULL REFERENCES users(id),
    gestational_age_weeks INTEGER,
    birth_weight_gm INTEGER,
    current_weight_gm INTEGER,
    -- Phototherapy
    bilirubin_total NUMERIC(6,2),
    bilirubin_direct NUMERIC(6,2),
    phototherapy_active BOOLEAN NOT NULL DEFAULT false,
    phototherapy_hours NUMERIC(6,2),
    -- Breast milk management
    breast_milk_type VARCHAR(50),
    breast_milk_volume_ml NUMERIC(6,2),
    -- Screening
    hearing_screen_result VARCHAR(50),
    sepsis_screen_result VARCHAR(100),
    mother_patient_id UUID REFERENCES patients(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icu_neonatal_tenant ON icu_neonatal_records(tenant_id);
CREATE INDEX idx_icu_neonatal_admission ON icu_neonatal_records(admission_id);

-- ============================================================
-- Row-Level Security
-- ============================================================

ALTER TABLE icu_flowsheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE icu_ventilator_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE icu_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE icu_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE icu_bundle_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE icu_nutrition ENABLE ROW LEVEL SECURITY;
ALTER TABLE icu_neonatal_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY icu_flowsheets_tenant ON icu_flowsheets
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY icu_ventilator_records_tenant ON icu_ventilator_records
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY icu_scores_tenant ON icu_scores
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY icu_devices_tenant ON icu_devices
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY icu_bundle_checks_tenant ON icu_bundle_checks
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY icu_nutrition_tenant ON icu_nutrition
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY icu_neonatal_records_tenant ON icu_neonatal_records
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers
-- ============================================================

CREATE TRIGGER set_updated_at_icu_devices
    BEFORE UPDATE ON icu_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
