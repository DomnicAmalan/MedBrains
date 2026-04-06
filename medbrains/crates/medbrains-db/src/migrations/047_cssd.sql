-- 047_cssd.sql — Central Sterile Supply Department
-- Instrument tracking, set management, sterilization loads, indicators, issuance, equipment

-- ── Enums ────────────────────────────────────────────────

CREATE TYPE instrument_status AS ENUM (
    'available',
    'in_use',
    'decontaminating',
    'sterilizing',
    'sterile',
    'damaged',
    'condemned'
);

CREATE TYPE sterilization_method AS ENUM (
    'steam',
    'eto',
    'plasma',
    'dry_heat',
    'flash'
);

CREATE TYPE indicator_type AS ENUM (
    'chemical',
    'biological'
);

CREATE TYPE load_status AS ENUM (
    'loading',
    'running',
    'completed',
    'failed'
);

-- ── Sterilizers (equipment registry) ─────────────────────

CREATE TABLE cssd_sterilizers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    name        TEXT NOT NULL,
    model       TEXT,
    serial_number TEXT,
    method      sterilization_method NOT NULL DEFAULT 'steam',
    chamber_size_liters NUMERIC(10,2),
    location    TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    last_maintenance_at TIMESTAMPTZ,
    next_maintenance_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Instruments ──────────────────────────────────────────

CREATE TABLE cssd_instruments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    barcode     TEXT NOT NULL,
    name        TEXT NOT NULL,
    category    TEXT,
    manufacturer TEXT,
    status      instrument_status NOT NULL DEFAULT 'available',
    purchase_date DATE,
    lifecycle_uses INT NOT NULL DEFAULT 0,
    max_uses    INT,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, barcode)
);

-- ── Instrument Sets ──────────────────────────────────────

CREATE TABLE cssd_instrument_sets (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    set_code    TEXT NOT NULL,
    set_name    TEXT NOT NULL,
    department  TEXT,
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, set_code)
);

CREATE TABLE cssd_set_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    set_id          UUID NOT NULL REFERENCES cssd_instrument_sets(id) ON DELETE CASCADE,
    instrument_id   UUID NOT NULL REFERENCES cssd_instruments(id),
    quantity        INT NOT NULL DEFAULT 1,
    UNIQUE (set_id, instrument_id)
);

-- ── Sterilization Loads ──────────────────────────────────

CREATE TABLE cssd_sterilization_loads (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    load_number     TEXT NOT NULL,
    sterilizer_id   UUID NOT NULL REFERENCES cssd_sterilizers(id),
    method          sterilization_method NOT NULL,
    status          load_status NOT NULL DEFAULT 'loading',
    operator_id     UUID,
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    cycle_time_minutes INT,
    temperature_c   NUMERIC(5,1),
    pressure_psi    NUMERIC(5,1),
    is_flash        BOOLEAN NOT NULL DEFAULT FALSE,
    flash_reason    TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, load_number)
);

CREATE TABLE cssd_load_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    load_id     UUID NOT NULL REFERENCES cssd_sterilization_loads(id) ON DELETE CASCADE,
    set_id      UUID REFERENCES cssd_instrument_sets(id),
    instrument_id UUID REFERENCES cssd_instruments(id),
    quantity    INT NOT NULL DEFAULT 1,
    pack_expiry_date DATE
);

-- ── Indicator Results ────────────────────────────────────

CREATE TABLE cssd_indicator_results (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    load_id         UUID NOT NULL REFERENCES cssd_sterilization_loads(id),
    indicator_type  indicator_type NOT NULL,
    indicator_brand TEXT,
    indicator_lot   TEXT,
    result_pass     BOOLEAN NOT NULL,
    read_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_by         UUID,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Issuances ────────────────────────────────────────────

CREATE TABLE cssd_issuances (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    load_item_id    UUID REFERENCES cssd_load_items(id),
    set_id          UUID REFERENCES cssd_instrument_sets(id),
    issued_to_department TEXT NOT NULL,
    issued_to_patient_id UUID,
    issued_by       UUID,
    issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    returned_at     TIMESTAMPTZ,
    returned_by     UUID,
    is_recalled     BOOLEAN NOT NULL DEFAULT FALSE,
    recall_reason   TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Maintenance Logs ─────────────────────────────────────

CREATE TABLE cssd_maintenance_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    sterilizer_id   UUID NOT NULL REFERENCES cssd_sterilizers(id),
    maintenance_type TEXT NOT NULL,
    performed_by    TEXT,
    performed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    next_due_at     TIMESTAMPTZ,
    findings        TEXT,
    actions_taken   TEXT,
    cost            NUMERIC(12,2),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── RLS Policies ─────────────────────────────────────────

ALTER TABLE cssd_sterilizers ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_instruments ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_instrument_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_set_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_sterilization_loads ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_load_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_indicator_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_issuances ENABLE ROW LEVEL SECURITY;
ALTER TABLE cssd_maintenance_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_cssd_sterilizers ON cssd_sterilizers
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_instruments ON cssd_instruments
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_instrument_sets ON cssd_instrument_sets
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_set_items ON cssd_set_items
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_sterilization_loads ON cssd_sterilization_loads
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_load_items ON cssd_load_items
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_indicator_results ON cssd_indicator_results
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_issuances ON cssd_issuances
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE POLICY tenant_cssd_maintenance_logs ON cssd_maintenance_logs
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ── Indexes ──────────────────────────────────────────────

CREATE INDEX idx_cssd_instruments_tenant ON cssd_instruments(tenant_id);
CREATE INDEX idx_cssd_instruments_status ON cssd_instruments(tenant_id, status);
CREATE INDEX idx_cssd_instrument_sets_tenant ON cssd_instrument_sets(tenant_id);
CREATE INDEX idx_cssd_loads_tenant ON cssd_sterilization_loads(tenant_id);
CREATE INDEX idx_cssd_loads_sterilizer ON cssd_sterilization_loads(sterilizer_id);
CREATE INDEX idx_cssd_load_items_load ON cssd_load_items(load_id);
CREATE INDEX idx_cssd_indicators_load ON cssd_indicator_results(load_id);
CREATE INDEX idx_cssd_issuances_tenant ON cssd_issuances(tenant_id);
CREATE INDEX idx_cssd_issuances_department ON cssd_issuances(tenant_id, issued_to_department);
CREATE INDEX idx_cssd_maintenance_sterilizer ON cssd_maintenance_logs(sterilizer_id);

-- ── Triggers ─────────────────────────────────────────────

CREATE TRIGGER set_cssd_sterilizers_updated_at
    BEFORE UPDATE ON cssd_sterilizers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_cssd_instruments_updated_at
    BEFORE UPDATE ON cssd_instruments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_cssd_instrument_sets_updated_at
    BEFORE UPDATE ON cssd_instrument_sets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
