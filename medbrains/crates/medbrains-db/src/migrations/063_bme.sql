-- 063 BME / CMMS — Biomedical Equipment Management
-- Tables: bme_equipment, bme_pm_schedules, bme_work_orders,
--         bme_calibrations, bme_contracts, bme_breakdowns, bme_vendor_evaluations

-- ══════════════════════════════════════════════════════════
--  Enums
-- ══════════════════════════════════════════════════════════

CREATE TYPE bme_equipment_status AS ENUM (
    'active', 'under_maintenance', 'out_of_service', 'condemned', 'disposed'
);

CREATE TYPE bme_risk_category AS ENUM (
    'critical', 'high', 'medium', 'low'
);

CREATE TYPE bme_work_order_status AS ENUM (
    'open', 'assigned', 'in_progress', 'completed', 'cancelled'
);

CREATE TYPE bme_work_order_type AS ENUM (
    'preventive', 'corrective', 'calibration', 'installation', 'inspection'
);

CREATE TYPE bme_pm_frequency AS ENUM (
    'monthly', 'quarterly', 'semi_annual', 'annual'
);

CREATE TYPE bme_calibration_status AS ENUM (
    'calibrated', 'due', 'overdue', 'out_of_tolerance', 'exempted'
);

CREATE TYPE bme_contract_type AS ENUM (
    'amc', 'cmc', 'warranty', 'camc'
);

CREATE TYPE bme_breakdown_priority AS ENUM (
    'critical', 'high', 'medium', 'low'
);

CREATE TYPE bme_breakdown_status AS ENUM (
    'reported', 'acknowledged', 'in_progress', 'parts_awaited', 'resolved', 'closed'
);

-- ══════════════════════════════════════════════════════════
--  1. bme_equipment
-- ══════════════════════════════════════════════════════════

CREATE TABLE bme_equipment (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            TEXT NOT NULL,
    make            TEXT,
    model           TEXT,
    serial_number   TEXT,
    asset_tag       TEXT,
    barcode_value   TEXT,
    category        TEXT,
    sub_category    TEXT,
    risk_category   bme_risk_category NOT NULL DEFAULT 'medium',
    is_critical     BOOLEAN NOT NULL DEFAULT false,
    department_id   UUID REFERENCES departments(id),
    location_description TEXT,
    facility_id     UUID REFERENCES facilities(id),
    status          bme_equipment_status NOT NULL DEFAULT 'active',
    purchase_date   DATE,
    purchase_cost   DECIMAL(14,2),
    installation_date   DATE,
    commissioned_date   DATE,
    installed_by    TEXT,
    commissioning_notes TEXT,
    expected_life_years INT,
    condemned_date  DATE,
    disposal_date   DATE,
    disposal_method TEXT,
    warranty_start_date DATE,
    warranty_end_date   DATE,
    warranty_terms  TEXT,
    vendor_id       UUID REFERENCES vendors(id),
    manufacturer_contact TEXT,
    specifications  JSONB DEFAULT '{}'::jsonb,
    notes           TEXT,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tenant_id, asset_tag)
);

ALTER TABLE bme_equipment ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bme_equipment
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_bme_equipment_tenant ON bme_equipment (tenant_id);
CREATE INDEX idx_bme_equipment_status ON bme_equipment (tenant_id, status);
CREATE INDEX idx_bme_equipment_dept ON bme_equipment (tenant_id, department_id);

CREATE TRIGGER trg_bme_equipment_updated_at
    BEFORE UPDATE ON bme_equipment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  2. bme_pm_schedules
-- ══════════════════════════════════════════════════════════

CREATE TABLE bme_pm_schedules (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    equipment_id        UUID NOT NULL REFERENCES bme_equipment(id),
    frequency           bme_pm_frequency NOT NULL,
    checklist           JSONB DEFAULT '[]'::jsonb,
    next_due_date       DATE,
    last_completed_date DATE,
    assigned_to         UUID REFERENCES users(id),
    is_active           BOOLEAN NOT NULL DEFAULT true,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bme_pm_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bme_pm_schedules
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_bme_pm_schedules_tenant ON bme_pm_schedules (tenant_id);
CREATE INDEX idx_bme_pm_schedules_equip ON bme_pm_schedules (tenant_id, equipment_id);
CREATE INDEX idx_bme_pm_schedules_due ON bme_pm_schedules (tenant_id, next_due_date);

CREATE TRIGGER trg_bme_pm_schedules_updated_at
    BEFORE UPDATE ON bme_pm_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  3. bme_work_orders
-- ══════════════════════════════════════════════════════════

CREATE TABLE bme_work_orders (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    work_order_number       TEXT NOT NULL,
    equipment_id            UUID NOT NULL REFERENCES bme_equipment(id),
    order_type              bme_work_order_type NOT NULL,
    status                  bme_work_order_status NOT NULL DEFAULT 'open',
    priority                bme_breakdown_priority NOT NULL DEFAULT 'medium',
    assigned_to             UUID REFERENCES users(id),
    assigned_at             TIMESTAMPTZ,
    scheduled_date          DATE,
    started_at              TIMESTAMPTZ,
    completed_at            TIMESTAMPTZ,
    description             TEXT,
    findings                TEXT,
    actions_taken           TEXT,
    checklist_results       JSONB DEFAULT '[]'::jsonb,
    labor_cost              DECIMAL(12,2),
    parts_cost              DECIMAL(12,2),
    vendor_cost             DECIMAL(12,2),
    total_cost              DECIMAL(12,2),
    technician_sign_off_by  UUID REFERENCES users(id),
    technician_sign_off_at  TIMESTAMPTZ,
    supervisor_sign_off_by  UUID REFERENCES users(id),
    supervisor_sign_off_at  TIMESTAMPTZ,
    pm_schedule_id          UUID REFERENCES bme_pm_schedules(id),
    breakdown_id            UUID,  -- FK added after bme_breakdowns table
    notes                   TEXT,
    created_by              UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tenant_id, work_order_number)
);

ALTER TABLE bme_work_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bme_work_orders
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_bme_work_orders_tenant ON bme_work_orders (tenant_id);
CREATE INDEX idx_bme_work_orders_equip ON bme_work_orders (tenant_id, equipment_id);
CREATE INDEX idx_bme_work_orders_status ON bme_work_orders (tenant_id, status);

CREATE TRIGGER trg_bme_work_orders_updated_at
    BEFORE UPDATE ON bme_work_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  4. bme_calibrations
-- ══════════════════════════════════════════════════════════

CREATE TABLE bme_calibrations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    equipment_id        UUID NOT NULL REFERENCES bme_equipment(id),
    calibration_status  bme_calibration_status NOT NULL DEFAULT 'due',
    frequency           bme_pm_frequency NOT NULL DEFAULT 'annual',
    last_calibrated_date DATE,
    next_due_date       DATE,
    calibrated_by       TEXT,
    calibration_vendor_id UUID REFERENCES vendors(id),
    certificate_number  TEXT,
    certificate_url     TEXT,
    is_in_tolerance     BOOLEAN,
    deviation_notes     TEXT,
    reference_standard  TEXT,
    is_locked           BOOLEAN NOT NULL DEFAULT false,
    locked_at           TIMESTAMPTZ,
    locked_reason       TEXT,
    notes               TEXT,
    created_by          UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bme_calibrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bme_calibrations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_bme_calibrations_tenant ON bme_calibrations (tenant_id);
CREATE INDEX idx_bme_calibrations_equip ON bme_calibrations (tenant_id, equipment_id);
CREATE INDEX idx_bme_calibrations_due ON bme_calibrations (tenant_id, next_due_date);

CREATE TRIGGER trg_bme_calibrations_updated_at
    BEFORE UPDATE ON bme_calibrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  5. bme_contracts
-- ══════════════════════════════════════════════════════════

CREATE TABLE bme_contracts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    contract_number     TEXT NOT NULL,
    equipment_id        UUID NOT NULL REFERENCES bme_equipment(id),
    contract_type       bme_contract_type NOT NULL,
    vendor_id           UUID NOT NULL REFERENCES vendors(id),
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    contract_value      DECIMAL(14,2),
    payment_terms       TEXT,
    coverage_details    TEXT,
    exclusions          TEXT,
    sla_response_hours  INT,
    sla_resolution_hours INT,
    renewal_alert_days  INT NOT NULL DEFAULT 60,
    is_renewed          BOOLEAN NOT NULL DEFAULT false,
    renewed_contract_id UUID REFERENCES bme_contracts(id),
    is_active           BOOLEAN NOT NULL DEFAULT true,
    notes               TEXT,
    created_by          UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tenant_id, contract_number)
);

ALTER TABLE bme_contracts ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bme_contracts
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_bme_contracts_tenant ON bme_contracts (tenant_id);
CREATE INDEX idx_bme_contracts_equip ON bme_contracts (tenant_id, equipment_id);
CREATE INDEX idx_bme_contracts_end ON bme_contracts (tenant_id, end_date);

CREATE TRIGGER trg_bme_contracts_updated_at
    BEFORE UPDATE ON bme_contracts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  6. bme_breakdowns
-- ══════════════════════════════════════════════════════════

CREATE TABLE bme_breakdowns (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    equipment_id            UUID NOT NULL REFERENCES bme_equipment(id),
    reported_by             UUID REFERENCES users(id),
    reported_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    department_id           UUID REFERENCES departments(id),
    priority                bme_breakdown_priority NOT NULL DEFAULT 'medium',
    status                  bme_breakdown_status NOT NULL DEFAULT 'reported',
    description             TEXT NOT NULL,
    acknowledged_at         TIMESTAMPTZ,
    acknowledged_by         UUID REFERENCES users(id),
    resolution_started_at   TIMESTAMPTZ,
    resolved_at             TIMESTAMPTZ,
    resolved_by             UUID REFERENCES users(id),
    resolution_notes        TEXT,
    downtime_start          TIMESTAMPTZ,
    downtime_end            TIMESTAMPTZ,
    downtime_minutes        INT,
    spare_parts_used        TEXT,
    spare_parts_cost        DECIMAL(12,2),
    vendor_visit_required   BOOLEAN NOT NULL DEFAULT false,
    vendor_visit_date       DATE,
    vendor_cost             DECIMAL(12,2),
    total_repair_cost       DECIMAL(12,2),
    vendor_id               UUID REFERENCES vendors(id),
    vendor_response_at      TIMESTAMPTZ,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bme_breakdowns ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bme_breakdowns
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_bme_breakdowns_tenant ON bme_breakdowns (tenant_id);
CREATE INDEX idx_bme_breakdowns_equip ON bme_breakdowns (tenant_id, equipment_id);
CREATE INDEX idx_bme_breakdowns_status ON bme_breakdowns (tenant_id, status);

CREATE TRIGGER trg_bme_breakdowns_updated_at
    BEFORE UPDATE ON bme_breakdowns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Add deferred FK from work_orders to breakdowns
ALTER TABLE bme_work_orders
    ADD CONSTRAINT fk_bme_work_orders_breakdown
    FOREIGN KEY (breakdown_id) REFERENCES bme_breakdowns(id);

-- ══════════════════════════════════════════════════════════
--  7. bme_vendor_evaluations
-- ══════════════════════════════════════════════════════════

CREATE TABLE bme_vendor_evaluations (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                       UUID NOT NULL REFERENCES tenants(id),
    vendor_id                       UUID NOT NULL REFERENCES vendors(id),
    contract_id                     UUID REFERENCES bme_contracts(id),
    evaluation_date                 DATE NOT NULL,
    period_from                     DATE,
    period_to                       DATE,
    response_time_score             INT CHECK (response_time_score BETWEEN 1 AND 5),
    resolution_quality_score        INT CHECK (resolution_quality_score BETWEEN 1 AND 5),
    spare_parts_availability_score  INT CHECK (spare_parts_availability_score BETWEEN 1 AND 5),
    professionalism_score           INT CHECK (professionalism_score BETWEEN 1 AND 5),
    overall_score                   DECIMAL(3,1),
    total_calls                     INT,
    calls_within_sla                INT,
    comments                        TEXT,
    evaluated_by                    UUID REFERENCES users(id),
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bme_vendor_evaluations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bme_vendor_evaluations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_bme_vendor_evaluations_tenant ON bme_vendor_evaluations (tenant_id);
CREATE INDEX idx_bme_vendor_evaluations_vendor ON bme_vendor_evaluations (tenant_id, vendor_id);

CREATE TRIGGER trg_bme_vendor_evaluations_updated_at
    BEFORE UPDATE ON bme_vendor_evaluations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
