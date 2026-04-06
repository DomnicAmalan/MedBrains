-- 061_housekeeping.sql
-- Housekeeping module: cleaning, room turnaround, pest control, linen & laundry
-- Regulatory: BMW Rules 2016, NABH standards (cleaning frequencies), infection prevention

-- ── Enums ───────────────────────────────────────────────────

CREATE TYPE cleaning_area_type AS ENUM (
    'icu', 'ward', 'ot', 'er', 'lab', 'pharmacy',
    'corridor', 'lobby', 'washroom', 'kitchen', 'general'
);

CREATE TYPE cleaning_task_status AS ENUM (
    'pending', 'assigned', 'in_progress', 'completed', 'verified', 'rejected'
);

CREATE TYPE linen_status AS ENUM (
    'clean', 'in_use', 'soiled', 'washing', 'condemned'
);

CREATE TYPE linen_contamination_type AS ENUM (
    'regular', 'contaminated', 'isolation'
);

-- ── Tables ──────────────────────────────────────────────────

-- 1. Cleaning schedules — area-specific frequencies and checklists
CREATE TABLE cleaning_schedules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    area_type       cleaning_area_type NOT NULL,
    location_id     UUID REFERENCES locations(id),
    department_id   UUID REFERENCES departments(id),
    frequency_hours INT NOT NULL DEFAULT 24,
    checklist_items JSONB NOT NULL DEFAULT '[]',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Cleaning tasks — individual task assignments and completion
CREATE TABLE cleaning_tasks (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    schedule_id       UUID REFERENCES cleaning_schedules(id),
    location_id       UUID REFERENCES locations(id),
    department_id     UUID REFERENCES departments(id),
    area_type         cleaning_area_type NOT NULL,
    task_date         DATE NOT NULL DEFAULT CURRENT_DATE,
    assigned_to       TEXT,
    status            cleaning_task_status NOT NULL DEFAULT 'pending',
    started_at        TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    verified_by       UUID REFERENCES users(id),
    verified_at       TIMESTAMPTZ,
    checklist_results JSONB NOT NULL DEFAULT '[]',
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Room turnaround tracking — discharge-to-ready time
CREATE TABLE room_turnarounds (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    location_id          UUID REFERENCES locations(id),
    patient_id           UUID REFERENCES patients(id),
    discharge_at         TIMESTAMPTZ,
    dirty_at             TIMESTAMPTZ,
    cleaning_started_at  TIMESTAMPTZ,
    cleaning_completed_at TIMESTAMPTZ,
    ready_at             TIMESTAMPTZ,
    turnaround_minutes   INT,
    cleaned_by           TEXT,
    verified_by          UUID REFERENCES users(id),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Pest control schedules
CREATE TABLE pest_control_schedules (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    location_id      UUID REFERENCES locations(id),
    department_id    UUID REFERENCES departments(id),
    pest_type        TEXT NOT NULL,
    frequency_months INT NOT NULL DEFAULT 3,
    last_done        DATE,
    next_due         DATE,
    vendor_name      TEXT,
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Pest control logs
CREATE TABLE pest_control_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    schedule_id     UUID REFERENCES pest_control_schedules(id),
    treatment_date  DATE NOT NULL,
    treatment_type  TEXT NOT NULL,
    chemicals_used  TEXT,
    areas_treated   JSONB NOT NULL DEFAULT '[]',
    vendor_name     TEXT,
    certificate_no  TEXT,
    next_due        DATE,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Linen items — individual linen tracking
CREATE TABLE linen_items (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    barcode           TEXT,
    item_type         TEXT NOT NULL,
    current_status    linen_status NOT NULL DEFAULT 'clean',
    ward_id           UUID REFERENCES locations(id),
    wash_count        INT NOT NULL DEFAULT 0,
    max_washes        INT NOT NULL DEFAULT 150,
    commissioned_date DATE,
    condemned_date    DATE,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_linen_barcode UNIQUE (tenant_id, barcode)
);

-- 7. Linen movements — collection, washing, distribution
CREATE TABLE linen_movements (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES tenants(id),
    linen_item_id      UUID REFERENCES linen_items(id),
    movement_type      TEXT NOT NULL,
    from_ward          UUID REFERENCES locations(id),
    to_ward            UUID REFERENCES locations(id),
    quantity           INT NOT NULL DEFAULT 1,
    weight_kg          NUMERIC(8,2),
    contamination_type linen_contamination_type NOT NULL DEFAULT 'regular',
    batch_id           UUID,
    recorded_by        TEXT,
    movement_date      TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. Laundry batches — wash cycle tracking
CREATE TABLE laundry_batches (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    batch_number      TEXT NOT NULL,
    items_count       INT NOT NULL DEFAULT 0,
    total_weight      NUMERIC(8,2),
    contamination_type linen_contamination_type NOT NULL DEFAULT 'regular',
    wash_formula      TEXT,
    wash_temperature  INT,
    cycle_minutes     INT,
    started_at        TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    status            TEXT NOT NULL DEFAULT 'pending',
    operator_name     TEXT,
    notes             TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. Linen par levels — ward-wise stock thresholds
CREATE TABLE linen_par_levels (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    ward_id       UUID REFERENCES locations(id),
    item_type     TEXT NOT NULL,
    par_level     INT NOT NULL DEFAULT 0,
    current_stock INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_linen_par UNIQUE (tenant_id, ward_id, item_type)
);

-- 10. Linen condemnations — lifecycle end tracking
CREATE TABLE linen_condemnations (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES tenants(id),
    linen_item_id         UUID REFERENCES linen_items(id),
    reason                TEXT NOT NULL,
    wash_count_at_condemn INT,
    condemned_by          UUID REFERENCES users(id),
    condemned_date        DATE NOT NULL DEFAULT CURRENT_DATE,
    replacement_requested BOOLEAN NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── RLS Policies ────────────────────────────────────────────

ALTER TABLE cleaning_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON cleaning_schedules
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE cleaning_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON cleaning_tasks
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE room_turnarounds ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON room_turnarounds
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE pest_control_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON pest_control_schedules
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE pest_control_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON pest_control_logs
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE linen_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON linen_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE linen_movements ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON linen_movements
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE laundry_batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON laundry_batches
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE linen_par_levels ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON linen_par_levels
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE linen_condemnations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON linen_condemnations
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ── Indexes ─────────────────────────────────────────────────

CREATE INDEX idx_cleaning_schedules_tenant ON cleaning_schedules(tenant_id);
CREATE INDEX idx_cleaning_tasks_tenant ON cleaning_tasks(tenant_id);
CREATE INDEX idx_cleaning_tasks_date ON cleaning_tasks(tenant_id, task_date);
CREATE INDEX idx_cleaning_tasks_status ON cleaning_tasks(tenant_id, status);
CREATE INDEX idx_room_turnarounds_tenant ON room_turnarounds(tenant_id);
CREATE INDEX idx_pest_control_schedules_tenant ON pest_control_schedules(tenant_id);
CREATE INDEX idx_pest_control_logs_tenant ON pest_control_logs(tenant_id);
CREATE INDEX idx_linen_items_tenant ON linen_items(tenant_id);
CREATE INDEX idx_linen_items_status ON linen_items(tenant_id, current_status);
CREATE INDEX idx_linen_movements_tenant ON linen_movements(tenant_id);
CREATE INDEX idx_laundry_batches_tenant ON laundry_batches(tenant_id);
CREATE INDEX idx_linen_par_levels_tenant ON linen_par_levels(tenant_id);
CREATE INDEX idx_linen_condemnations_tenant ON linen_condemnations(tenant_id);

-- ── Triggers ────────────────────────────────────────────────

CREATE TRIGGER set_cleaning_schedules_updated_at BEFORE UPDATE ON cleaning_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_cleaning_tasks_updated_at BEFORE UPDATE ON cleaning_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_room_turnarounds_updated_at BEFORE UPDATE ON room_turnarounds
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_pest_control_schedules_updated_at BEFORE UPDATE ON pest_control_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_pest_control_logs_updated_at BEFORE UPDATE ON pest_control_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_linen_items_updated_at BEFORE UPDATE ON linen_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_linen_movements_updated_at BEFORE UPDATE ON linen_movements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_laundry_batches_updated_at BEFORE UPDATE ON laundry_batches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_linen_par_levels_updated_at BEFORE UPDATE ON linen_par_levels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_linen_condemnations_updated_at BEFORE UPDATE ON linen_condemnations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
