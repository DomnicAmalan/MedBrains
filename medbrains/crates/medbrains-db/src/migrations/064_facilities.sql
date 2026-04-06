-- 064_facilities.sql — Facilities Management (FMS) Module
-- MGPS/Medical Gas, Fire Safety, Water Quality, Energy Management, Work Orders
-- NABH FMS accreditation, PESO compliance, CEA electrical safety

-- ═══════════════════════════════════════════════════════════
--  ENUMS
-- ═══════════════════════════════════════════════════════════

CREATE TYPE fms_gas_type AS ENUM (
    'oxygen', 'nitrous_oxide', 'nitrogen', 'medical_air', 'vacuum', 'co2', 'heliox'
);

CREATE TYPE fms_gas_source_type AS ENUM (
    'psa_plant', 'lmo_tank', 'cylinder_manifold', 'pipeline'
);

CREATE TYPE fms_fire_equipment_type AS ENUM (
    'extinguisher_abc', 'extinguisher_co2', 'extinguisher_water',
    'hydrant', 'hose_reel', 'smoke_detector', 'heat_detector',
    'sprinkler', 'fire_alarm_panel', 'emergency_light'
);

CREATE TYPE fms_drill_type AS ENUM (
    'fire', 'code_red', 'evacuation', 'chemical_spill', 'bomb_threat'
);

CREATE TYPE fms_water_source_type AS ENUM (
    'municipal', 'borewell', 'tanker', 'ro_plant', 'stp_recycled'
);

CREATE TYPE fms_water_test_type AS ENUM (
    'bacteriological', 'chemical', 'endotoxin', 'conductivity'
);

CREATE TYPE fms_energy_source_type AS ENUM (
    'grid', 'dg_set', 'ups', 'solar', 'inverter'
);

CREATE TYPE fms_work_order_status AS ENUM (
    'open', 'assigned', 'in_progress', 'on_hold', 'completed', 'cancelled'
);

-- ═══════════════════════════════════════════════════════════
--  TABLES
-- ═══════════════════════════════════════════════════════════

-- ── 1. Gas Readings ─────────────────────────────────────────

CREATE TABLE fms_gas_readings (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    gas_type      fms_gas_type NOT NULL,
    source_type   fms_gas_source_type NOT NULL,
    location_id   UUID REFERENCES locations(id),
    department_id UUID REFERENCES departments(id),
    purity_percent     DECIMAL(5,2),
    pressure_bar       DECIMAL(8,2),
    flow_lpm           DECIMAL(8,2),
    temperature_c      DECIMAL(5,1),
    tank_level_percent DECIMAL(5,2),
    cylinder_count     INTEGER,
    manifold_side      TEXT,
    is_alarm      BOOLEAN NOT NULL DEFAULT FALSE,
    alarm_reason  TEXT,
    reading_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    recorded_by   UUID REFERENCES users(id),
    notes         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fms_gas_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_gas_readings
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_gas_readings_tenant ON fms_gas_readings(tenant_id);
CREATE INDEX idx_fms_gas_readings_gas_type ON fms_gas_readings(tenant_id, gas_type);
CREATE INDEX idx_fms_gas_readings_reading_at ON fms_gas_readings(tenant_id, reading_at DESC);
CREATE TRIGGER trg_fms_gas_readings_updated_at
    BEFORE UPDATE ON fms_gas_readings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 2. Gas Compliance (PESO / Drug License) ─────────────────

CREATE TABLE fms_gas_compliance (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    facility_id          UUID REFERENCES facilities(id),
    gas_type             fms_gas_type NOT NULL,
    peso_license_number  TEXT,
    peso_valid_from      DATE,
    peso_valid_to        DATE,
    drug_license_number  TEXT,
    drug_license_valid_to DATE,
    last_inspection_date DATE,
    next_inspection_date DATE,
    inspector_name       TEXT,
    compliance_status    TEXT DEFAULT 'compliant',
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, facility_id, gas_type)
);

ALTER TABLE fms_gas_compliance ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_gas_compliance
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_gas_compliance_tenant ON fms_gas_compliance(tenant_id);
CREATE TRIGGER trg_fms_gas_compliance_updated_at
    BEFORE UPDATE ON fms_gas_compliance FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 3. Fire Equipment ───────────────────────────────────────

CREATE TABLE fms_fire_equipment (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    name             TEXT NOT NULL,
    equipment_type   fms_fire_equipment_type NOT NULL,
    location_id      UUID REFERENCES locations(id),
    department_id    UUID REFERENCES departments(id),
    serial_number    TEXT,
    make             TEXT,
    capacity         TEXT,
    installation_date DATE,
    expiry_date      DATE,
    last_refill_date DATE,
    next_refill_date DATE,
    barcode_value    TEXT,
    qr_code_value    TEXT,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fms_fire_equipment ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_fire_equipment
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_fire_equipment_tenant ON fms_fire_equipment(tenant_id);
CREATE INDEX idx_fms_fire_equipment_type ON fms_fire_equipment(tenant_id, equipment_type);
CREATE TRIGGER trg_fms_fire_equipment_updated_at
    BEFORE UPDATE ON fms_fire_equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 4. Fire Inspections ─────────────────────────────────────

CREATE TABLE fms_fire_inspections (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    equipment_id         UUID NOT NULL REFERENCES fms_fire_equipment(id),
    inspection_date      DATE NOT NULL,
    is_functional        BOOLEAN NOT NULL DEFAULT TRUE,
    findings             TEXT,
    corrective_action    TEXT,
    inspected_by         UUID REFERENCES users(id),
    next_inspection_date DATE,
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fms_fire_inspections ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_fire_inspections
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_fire_inspections_tenant ON fms_fire_inspections(tenant_id);
CREATE INDEX idx_fms_fire_inspections_equipment ON fms_fire_inspections(tenant_id, equipment_id);
CREATE TRIGGER trg_fms_fire_inspections_updated_at
    BEFORE UPDATE ON fms_fire_inspections FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 5. Fire Drills ──────────────────────────────────────────

CREATE TABLE fms_fire_drills (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    drill_type              fms_drill_type NOT NULL,
    facility_id             UUID REFERENCES facilities(id),
    drill_date              DATE NOT NULL,
    start_time              TIMESTAMPTZ,
    end_time                TIMESTAMPTZ,
    duration_minutes        INTEGER,
    zones_covered           TEXT[],
    participants_count      INTEGER,
    scenario_description    TEXT,
    evacuation_time_seconds INTEGER,
    response_time_seconds   INTEGER,
    findings                TEXT,
    improvement_actions     TEXT,
    drill_report_url        TEXT,
    conducted_by            UUID REFERENCES users(id),
    approved_by             UUID REFERENCES users(id),
    next_drill_due          DATE,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fms_fire_drills ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_fire_drills
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_fire_drills_tenant ON fms_fire_drills(tenant_id);
CREATE INDEX idx_fms_fire_drills_date ON fms_fire_drills(tenant_id, drill_date DESC);
CREATE TRIGGER trg_fms_fire_drills_updated_at
    BEFORE UPDATE ON fms_fire_drills FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 6. Fire NOC ─────────────────────────────────────────────

CREATE TABLE fms_fire_noc (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    facility_id       UUID REFERENCES facilities(id),
    noc_number        TEXT NOT NULL,
    issuing_authority TEXT,
    issue_date        DATE,
    valid_from        DATE,
    valid_to          DATE,
    renewal_alert_days INTEGER NOT NULL DEFAULT 90,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    document_url      TEXT,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, facility_id, noc_number)
);

ALTER TABLE fms_fire_noc ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_fire_noc
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_fire_noc_tenant ON fms_fire_noc(tenant_id);
CREATE TRIGGER trg_fms_fire_noc_updated_at
    BEFORE UPDATE ON fms_fire_noc FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 7. Water Tests ──────────────────────────────────────────

CREATE TABLE fms_water_tests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    source_type       fms_water_source_type NOT NULL,
    test_type         fms_water_test_type NOT NULL,
    location_id       UUID REFERENCES locations(id),
    sample_date       DATE NOT NULL,
    result_date       DATE,
    parameter_name    TEXT NOT NULL,
    result_value      DECIMAL(12,4),
    unit              TEXT,
    acceptable_min    DECIMAL(12,4),
    acceptable_max    DECIMAL(12,4),
    is_within_limits  BOOLEAN,
    corrective_action TEXT,
    tested_by         TEXT,
    lab_name          TEXT,
    certificate_number TEXT,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fms_water_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_water_tests
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_water_tests_tenant ON fms_water_tests(tenant_id);
CREATE INDEX idx_fms_water_tests_source ON fms_water_tests(tenant_id, source_type);
CREATE INDEX idx_fms_water_tests_date ON fms_water_tests(tenant_id, sample_date DESC);
CREATE TRIGGER trg_fms_water_tests_updated_at
    BEFORE UPDATE ON fms_water_tests FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 8. Water Schedules ──────────────────────────────────────

CREATE TABLE fms_water_schedules (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    location_id         UUID REFERENCES locations(id),
    schedule_type       TEXT NOT NULL,
    frequency           TEXT NOT NULL,
    last_completed_date DATE,
    next_due_date       DATE,
    assigned_to         UUID REFERENCES users(id),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fms_water_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_water_schedules
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_water_schedules_tenant ON fms_water_schedules(tenant_id);
CREATE TRIGGER trg_fms_water_schedules_updated_at
    BEFORE UPDATE ON fms_water_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 9. Energy Readings ──────────────────────────────────────

CREATE TABLE fms_energy_readings (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID NOT NULL REFERENCES tenants(id),
    source_type            fms_energy_source_type NOT NULL,
    location_id            UUID REFERENCES locations(id),
    equipment_name         TEXT,
    reading_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    voltage                DECIMAL(8,2),
    current_amps           DECIMAL(8,2),
    power_kw               DECIMAL(10,2),
    power_factor           DECIMAL(4,3),
    frequency_hz           DECIMAL(6,2),
    fuel_level_percent     DECIMAL(5,2),
    runtime_hours          DECIMAL(10,2),
    load_percent           DECIMAL(5,2),
    battery_voltage        DECIMAL(6,2),
    battery_health_percent DECIMAL(5,2),
    backup_minutes         INTEGER,
    switchover_time_seconds DECIMAL(6,2),
    is_alarm               BOOLEAN NOT NULL DEFAULT FALSE,
    alarm_reason           TEXT,
    recorded_by            UUID REFERENCES users(id),
    notes                  TEXT,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE fms_energy_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_energy_readings
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_energy_readings_tenant ON fms_energy_readings(tenant_id);
CREATE INDEX idx_fms_energy_readings_source ON fms_energy_readings(tenant_id, source_type);
CREATE INDEX idx_fms_energy_readings_at ON fms_energy_readings(tenant_id, reading_at DESC);
CREATE TRIGGER trg_fms_energy_readings_updated_at
    BEFORE UPDATE ON fms_energy_readings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 10. Work Orders ─────────────────────────────────────────

CREATE TABLE fms_work_orders (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    work_order_number TEXT NOT NULL,
    category          TEXT,
    location_id       UUID REFERENCES locations(id),
    department_id     UUID REFERENCES departments(id),
    requested_by      UUID REFERENCES users(id),
    requested_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    priority          TEXT NOT NULL DEFAULT 'medium',
    status            fms_work_order_status NOT NULL DEFAULT 'open',
    description       TEXT NOT NULL,
    assigned_to       UUID REFERENCES users(id),
    assigned_at       TIMESTAMPTZ,
    started_at        TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    findings          TEXT,
    actions_taken     TEXT,
    vendor_id         UUID REFERENCES vendors(id),
    vendor_report     TEXT,
    vendor_cost       DECIMAL(14,2),
    material_cost     DECIMAL(14,2),
    labor_cost        DECIMAL(14,2),
    total_cost        DECIMAL(14,2),
    completed_by      UUID REFERENCES users(id),
    sign_off_by       UUID REFERENCES users(id),
    sign_off_at       TIMESTAMPTZ,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, work_order_number)
);

ALTER TABLE fms_work_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON fms_work_orders
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_fms_work_orders_tenant ON fms_work_orders(tenant_id);
CREATE INDEX idx_fms_work_orders_status ON fms_work_orders(tenant_id, status);
CREATE INDEX idx_fms_work_orders_priority ON fms_work_orders(tenant_id, priority);
CREATE TRIGGER trg_fms_work_orders_updated_at
    BEFORE UPDATE ON fms_work_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
