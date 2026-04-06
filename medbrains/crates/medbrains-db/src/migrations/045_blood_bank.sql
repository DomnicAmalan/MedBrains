-- Blood Bank & Transfusion Medicine module
-- Donor management, blood processing, cross-match, transfusion tracking

-- ============================================================
-- Enums
-- ============================================================

CREATE TYPE donation_type AS ENUM ('whole_blood', 'apheresis_platelets', 'apheresis_plasma');

CREATE TYPE blood_component_type AS ENUM (
    'whole_blood', 'prbc', 'ffp', 'platelets', 'cryoprecipitate', 'granulocytes'
);

CREATE TYPE blood_bag_status AS ENUM (
    'collected', 'processing', 'tested', 'available', 'reserved',
    'crossmatched', 'issued', 'transfused', 'returned', 'expired', 'discarded'
);

CREATE TYPE crossmatch_status AS ENUM (
    'requested', 'testing', 'compatible', 'incompatible', 'issued', 'cancelled'
);

CREATE TYPE transfusion_reaction_severity AS ENUM ('mild', 'moderate', 'severe', 'fatal');

-- ============================================================
-- 1. Blood Donors
-- ============================================================

CREATE TABLE blood_donors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    donor_number    VARCHAR(50) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE,
    gender          VARCHAR(20),
    blood_group     blood_group NOT NULL,
    phone           VARCHAR(20),
    email           VARCHAR(200),
    address         TEXT,
    id_type         VARCHAR(50),
    id_number       VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    is_deferred     BOOLEAN NOT NULL DEFAULT false,
    deferral_reason TEXT,
    deferral_until  DATE,
    last_donation   TIMESTAMPTZ,
    total_donations INTEGER NOT NULL DEFAULT 0,
    medical_history JSONB DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, donor_number)
);

CREATE INDEX idx_blood_donors_tenant ON blood_donors(tenant_id);
CREATE INDEX idx_blood_donors_blood_group ON blood_donors(blood_group);

-- ============================================================
-- 2. Donations — individual donation events
-- ============================================================

CREATE TABLE blood_donations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    donor_id        UUID NOT NULL REFERENCES blood_donors(id),
    bag_number      VARCHAR(50) NOT NULL,
    donation_type   donation_type NOT NULL DEFAULT 'whole_blood',
    volume_ml       INTEGER NOT NULL,
    donated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    collected_by    UUID REFERENCES users(id),
    camp_name       VARCHAR(200),
    adverse_reaction TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, bag_number)
);

CREATE INDEX idx_blood_donations_tenant ON blood_donations(tenant_id);
CREATE INDEX idx_blood_donations_donor ON blood_donations(donor_id);

-- ============================================================
-- 3. Blood Components — components derived from donations
-- ============================================================

CREATE TABLE blood_components (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    donation_id         UUID NOT NULL REFERENCES blood_donations(id),
    component_type      blood_component_type NOT NULL,
    bag_number          VARCHAR(50) NOT NULL,
    blood_group         blood_group NOT NULL,
    volume_ml           INTEGER NOT NULL,
    status              blood_bag_status NOT NULL DEFAULT 'collected',
    collected_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    expiry_at           TIMESTAMPTZ NOT NULL,
    storage_location    VARCHAR(100),
    storage_temperature VARCHAR(50),
    tti_status          VARCHAR(20) DEFAULT 'pending',
    tti_tested_at       TIMESTAMPTZ,
    issued_to_patient   UUID REFERENCES patients(id),
    issued_at           TIMESTAMPTZ,
    issued_by           UUID REFERENCES users(id),
    discarded_at        TIMESTAMPTZ,
    discard_reason      VARCHAR(500),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, bag_number)
);

CREATE INDEX idx_blood_components_tenant ON blood_components(tenant_id);
CREATE INDEX idx_blood_components_status ON blood_components(status);
CREATE INDEX idx_blood_components_blood_group ON blood_components(blood_group);
CREATE INDEX idx_blood_components_expiry ON blood_components(expiry_at);
CREATE INDEX idx_blood_components_donation ON blood_components(donation_id);

-- ============================================================
-- 4. Cross-match Requests
-- ============================================================

CREATE TABLE crossmatch_requests (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    component_id    UUID REFERENCES blood_components(id),
    requested_by    UUID NOT NULL REFERENCES users(id),
    blood_group     blood_group NOT NULL,
    component_type  blood_component_type NOT NULL DEFAULT 'prbc',
    units_requested INTEGER NOT NULL DEFAULT 1,
    clinical_indication TEXT,
    status          crossmatch_status NOT NULL DEFAULT 'requested',
    result          VARCHAR(50),
    tested_by       UUID REFERENCES users(id),
    tested_at       TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_crossmatch_tenant ON crossmatch_requests(tenant_id);
CREATE INDEX idx_crossmatch_patient ON crossmatch_requests(patient_id);
CREATE INDEX idx_crossmatch_status ON crossmatch_requests(status);

-- ============================================================
-- 5. Transfusion Records
-- ============================================================

CREATE TABLE transfusion_records (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    component_id    UUID NOT NULL REFERENCES blood_components(id),
    crossmatch_id   UUID REFERENCES crossmatch_requests(id),
    administered_by UUID NOT NULL REFERENCES users(id),
    verified_by     UUID REFERENCES users(id),
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    volume_transfused_ml INTEGER,
    has_reaction    BOOLEAN NOT NULL DEFAULT false,
    reaction_type   VARCHAR(200),
    reaction_severity transfusion_reaction_severity,
    reaction_details TEXT,
    reaction_reported_at TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_transfusion_tenant ON transfusion_records(tenant_id);
CREATE INDEX idx_transfusion_patient ON transfusion_records(patient_id);
CREATE INDEX idx_transfusion_component ON transfusion_records(component_id);

-- ============================================================
-- Row-Level Security
-- ============================================================

ALTER TABLE blood_donors ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE crossmatch_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfusion_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY blood_donors_tenant ON blood_donors
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY blood_donations_tenant ON blood_donations
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY blood_components_tenant ON blood_components
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY crossmatch_requests_tenant ON crossmatch_requests
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY transfusion_records_tenant ON transfusion_records
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers
-- ============================================================

CREATE TRIGGER set_updated_at_blood_donors
    BEFORE UPDATE ON blood_donors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_blood_components
    BEFORE UPDATE ON blood_components
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_crossmatch_requests
    BEFORE UPDATE ON crossmatch_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_transfusion_records
    BEFORE UPDATE ON transfusion_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
