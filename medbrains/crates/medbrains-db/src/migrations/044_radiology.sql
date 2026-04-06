-- Radiology / Imaging (RIS) module
-- Order management, modality masters, reporting, radiation dose tracking

-- ============================================================
-- Enums
-- ============================================================

CREATE TYPE radiology_order_status AS ENUM (
    'ordered',
    'scheduled',
    'in_progress',
    'completed',
    'reported',
    'verified',
    'cancelled'
);

CREATE TYPE radiology_priority AS ENUM (
    'routine',
    'urgent',
    'stat'
);

CREATE TYPE radiology_report_status AS ENUM (
    'draft',
    'preliminary',
    'final',
    'amended'
);

-- ============================================================
-- 1. Radiology Modalities — master table for imaging types
-- ============================================================

CREATE TABLE radiology_modalities (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            VARCHAR(20) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_radiology_modalities_tenant ON radiology_modalities(tenant_id);

-- ============================================================
-- 2. Radiology Orders — imaging requests from OPD/IPD/ER
-- ============================================================

CREATE TABLE radiology_orders (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    encounter_id        UUID REFERENCES encounters(id),
    modality_id         UUID NOT NULL REFERENCES radiology_modalities(id),
    ordered_by          UUID NOT NULL REFERENCES users(id),
    body_part           VARCHAR(200),
    clinical_indication TEXT,
    priority            radiology_priority NOT NULL DEFAULT 'routine',
    status              radiology_order_status NOT NULL DEFAULT 'ordered',
    scheduled_at        TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    notes               TEXT,
    contrast_required   BOOLEAN NOT NULL DEFAULT false,
    pregnancy_checked   BOOLEAN NOT NULL DEFAULT false,
    allergy_flagged     BOOLEAN NOT NULL DEFAULT false,
    cancellation_reason VARCHAR(500),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_radiology_orders_tenant ON radiology_orders(tenant_id);
CREATE INDEX idx_radiology_orders_patient ON radiology_orders(patient_id);
CREATE INDEX idx_radiology_orders_status ON radiology_orders(status);
CREATE INDEX idx_radiology_orders_modality ON radiology_orders(modality_id);
CREATE INDEX idx_radiology_orders_scheduled ON radiology_orders(scheduled_at);

-- ============================================================
-- 3. Radiology Reports — radiologist findings and interpretations
-- ============================================================

CREATE TABLE radiology_reports (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES radiology_orders(id),
    reported_by     UUID NOT NULL REFERENCES users(id),
    verified_by     UUID REFERENCES users(id),
    status          radiology_report_status NOT NULL DEFAULT 'draft',
    findings        TEXT NOT NULL,
    impression      TEXT,
    recommendations TEXT,
    is_critical     BOOLEAN NOT NULL DEFAULT false,
    template_name   VARCHAR(200),
    verified_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_radiology_reports_tenant ON radiology_reports(tenant_id);
CREATE INDEX idx_radiology_reports_order ON radiology_reports(order_id);
CREATE INDEX idx_radiology_reports_status ON radiology_reports(status);

-- ============================================================
-- 4. Radiation Dose Tracking — cumulative patient dose records
-- ============================================================

CREATE TABLE radiation_dose_records (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES radiology_orders(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    modality_code   VARCHAR(20) NOT NULL,
    body_part       VARCHAR(200),
    dose_value      DECIMAL(12,4),
    dose_unit       VARCHAR(20) NOT NULL DEFAULT 'mGy',
    dlp             DECIMAL(12,4),
    ctdi_vol        DECIMAL(12,4),
    dap             DECIMAL(12,4),
    fluoroscopy_time_seconds INTEGER,
    recorded_by     UUID REFERENCES users(id),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_radiation_dose_tenant ON radiation_dose_records(tenant_id);
CREATE INDEX idx_radiation_dose_patient ON radiation_dose_records(patient_id);
CREATE INDEX idx_radiation_dose_order ON radiation_dose_records(order_id);

-- ============================================================
-- Row-Level Security
-- ============================================================

ALTER TABLE radiology_modalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE radiology_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE radiology_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE radiation_dose_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY radiology_modalities_tenant_isolation ON radiology_modalities
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY radiology_orders_tenant_isolation ON radiology_orders
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY radiology_reports_tenant_isolation ON radiology_reports
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY radiation_dose_records_tenant_isolation ON radiation_dose_records
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers
-- ============================================================

CREATE TRIGGER set_updated_at_radiology_modalities
    BEFORE UPDATE ON radiology_modalities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_radiology_orders
    BEFORE UPDATE ON radiology_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_radiology_reports
    BEFORE UPDATE ON radiology_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
