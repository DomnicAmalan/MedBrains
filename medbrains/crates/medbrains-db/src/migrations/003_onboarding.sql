-- MedBrains HMS — Onboarding & Setup Module
-- Wizard state, facilities hierarchy, geospatial data, regulatory compliance,
-- module config, roles, tenant settings, branding.

-- ============================================================
-- New enum types
-- ============================================================

CREATE TYPE facility_type AS ENUM (
    'main_hospital',
    'medical_college',
    'dental_college',
    'nursing_college',
    'pharmacy_college',
    'ayush_hospital',
    'research_center',
    'blood_bank',
    'dialysis_center',
    'trauma_center',
    'burn_center',
    'rehabilitation_center',
    'palliative_care',
    'psychiatric_hospital',
    'eye_hospital',
    'maternity_hospital',
    'pediatric_hospital',
    'cancer_center',
    'cardiac_center',
    'neuro_center',
    'ortho_center',
    'day_care_center',
    'diagnostic_center',
    'telemedicine_hub',
    'community_health_center',
    'primary_health_center',
    'sub_center',
    'urban_health_center',
    'mobile_health_unit',
    'other'
);

CREATE TYPE facility_status AS ENUM (
    'active',
    'inactive',
    'under_construction',
    'closed'
);

CREATE TYPE module_status AS ENUM (
    'available',
    'enabled',
    'disabled',
    'coming_soon'
);

CREATE TYPE regulatory_level AS ENUM (
    'international',
    'national',
    'state',
    'education'
);

-- ============================================================
-- Geospatial hierarchy (global — no RLS, shared across tenants)
-- ============================================================

CREATE TABLE geo_countries (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code        TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    phone_code  TEXT,
    currency    TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE geo_states (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_id  UUID NOT NULL REFERENCES geo_countries(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (country_id, code)
);

CREATE INDEX idx_geo_states_country ON geo_states(country_id);

CREATE TABLE geo_districts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state_id    UUID NOT NULL REFERENCES geo_states(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (state_id, code)
);

CREATE INDEX idx_geo_districts_state ON geo_districts(state_id);

CREATE TABLE geo_subdistricts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district_id UUID NOT NULL REFERENCES geo_districts(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (district_id, code)
);

CREATE INDEX idx_geo_subdistricts_district ON geo_subdistricts(district_id);

CREATE TABLE geo_towns (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subdistrict_id  UUID NOT NULL REFERENCES geo_subdistricts(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    pincode         TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (subdistrict_id, code)
);

CREATE INDEX idx_geo_towns_subdistrict ON geo_towns(subdistrict_id);

-- ============================================================
-- Regulatory Bodies (global — no RLS)
-- ============================================================

CREATE TABLE regulatory_bodies (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    level           regulatory_level NOT NULL,
    country_id      UUID REFERENCES geo_countries(id),
    state_id        UUID REFERENCES geo_states(id),
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX idx_regulatory_bodies_level ON regulatory_bodies(level);
CREATE INDEX idx_regulatory_bodies_country ON regulatory_bodies(country_id);

-- ============================================================
-- ALTER tenants — add address, contact, geo, branding columns
-- ============================================================

ALTER TABLE tenants
    ADD COLUMN address_line1    TEXT,
    ADD COLUMN address_line2    TEXT,
    ADD COLUMN city             TEXT,
    ADD COLUMN pincode          TEXT,
    ADD COLUMN phone            TEXT,
    ADD COLUMN email            TEXT,
    ADD COLUMN website          TEXT,
    ADD COLUMN logo_url         TEXT,
    ADD COLUMN registration_no  TEXT,
    ADD COLUMN accreditation    TEXT,
    ADD COLUMN timezone         TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    ADD COLUMN locale           TEXT NOT NULL DEFAULT 'en-IN',
    ADD COLUMN currency         TEXT NOT NULL DEFAULT 'INR',
    ADD COLUMN fy_start_month   INT NOT NULL DEFAULT 4,
    ADD COLUMN latitude         NUMERIC(10,7),
    ADD COLUMN longitude        NUMERIC(10,7),
    ADD COLUMN country_id       UUID REFERENCES geo_countries(id),
    ADD COLUMN state_id         UUID REFERENCES geo_states(id),
    ADD COLUMN district_id      UUID REFERENCES geo_districts(id);

-- ============================================================
-- Onboarding Progress — wizard state per tenant
-- ============================================================

CREATE TABLE onboarding_progress (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) UNIQUE,
    current_step    INT NOT NULL DEFAULT 1,
    completed_steps JSONB NOT NULL DEFAULT '[]',
    is_complete     BOOLEAN NOT NULL DEFAULT false,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_onboarding_progress_tenant ON onboarding_progress(tenant_id);

-- ============================================================
-- Tenant Settings — key-value config per tenant
-- ============================================================

CREATE TABLE tenant_settings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    category    TEXT NOT NULL,
    key         TEXT NOT NULL,
    value       JSONB NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, category, key)
);

CREATE INDEX idx_tenant_settings_tenant ON tenant_settings(tenant_id);
CREATE INDEX idx_tenant_settings_category ON tenant_settings(tenant_id, category);

-- ============================================================
-- Module Config — module enable/disable per tenant
-- ============================================================

CREATE TABLE module_config (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    description TEXT,
    status      module_status NOT NULL DEFAULT 'available',
    config      JSONB NOT NULL DEFAULT '{}',
    depends_on  TEXT[] NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_module_config_tenant ON module_config(tenant_id);

-- ============================================================
-- Roles — custom roles (system + tenant-specific)
-- ============================================================

CREATE TABLE roles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',
    is_system   BOOLEAN NOT NULL DEFAULT false,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_roles_tenant ON roles(tenant_id);

-- ============================================================
-- Facilities — institutional hierarchy (self-ref tree)
-- ============================================================

CREATE TABLE facilities (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    parent_id       UUID REFERENCES facilities(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    facility_type   facility_type NOT NULL,
    status          facility_status NOT NULL DEFAULT 'active',
    address_line1   TEXT,
    address_line2   TEXT,
    city            TEXT,
    pincode         TEXT,
    phone           TEXT,
    email           TEXT,
    country_id      UUID REFERENCES geo_countries(id),
    state_id        UUID REFERENCES geo_states(id),
    district_id     UUID REFERENCES geo_districts(id),
    latitude        NUMERIC(10,7),
    longitude       NUMERIC(10,7),
    bed_count       INT NOT NULL DEFAULT 0,
    shared_billing  BOOLEAN NOT NULL DEFAULT true,
    shared_pharmacy BOOLEAN NOT NULL DEFAULT true,
    shared_lab      BOOLEAN NOT NULL DEFAULT true,
    shared_hr       BOOLEAN NOT NULL DEFAULT true,
    config          JSONB NOT NULL DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_facilities_tenant ON facilities(tenant_id);
CREATE INDEX idx_facilities_parent ON facilities(parent_id);
CREATE INDEX idx_facilities_type ON facilities(tenant_id, facility_type);

-- ============================================================
-- Facility Regulatory Compliance
-- ============================================================

CREATE TABLE facility_regulatory_compliance (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    facility_id         UUID NOT NULL REFERENCES facilities(id),
    regulatory_body_id  UUID NOT NULL REFERENCES regulatory_bodies(id),
    license_number      TEXT,
    valid_from          DATE,
    valid_until         DATE,
    status              TEXT NOT NULL DEFAULT 'pending',
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, facility_id, regulatory_body_id)
);

CREATE INDEX idx_frc_tenant ON facility_regulatory_compliance(tenant_id);
CREATE INDEX idx_frc_facility ON facility_regulatory_compliance(facility_id);

-- ============================================================
-- Row-Level Security — tenant-scoped tables
-- ============================================================

ALTER TABLE onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE facility_regulatory_compliance ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_onboarding_progress ON onboarding_progress
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_tenant_settings ON tenant_settings
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_module_config ON module_config
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_roles ON roles
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_facilities ON facilities
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_frc ON facility_regulatory_compliance
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers
-- ============================================================

CREATE TRIGGER trg_onboarding_progress_updated_at BEFORE UPDATE ON onboarding_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_tenant_settings_updated_at BEFORE UPDATE ON tenant_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_module_config_updated_at BEFORE UPDATE ON module_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_facilities_updated_at BEFORE UPDATE ON facilities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_frc_updated_at BEFORE UPDATE ON facility_regulatory_compliance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
