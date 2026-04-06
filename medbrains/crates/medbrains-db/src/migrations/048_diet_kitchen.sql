-- 048_diet_kitchen.sql — Diet & Kitchen module
-- Diet orders, therapeutic templates, menu planning, meal prep, delivery tracking, FSSAI compliance

-- ── Enums ────────────────────────────────────────────────

CREATE TYPE diet_type AS ENUM (
    'regular',
    'diabetic',
    'renal',
    'cardiac',
    'liquid',
    'soft',
    'high_protein',
    'low_sodium',
    'npo',
    'custom'
);

CREATE TYPE meal_type AS ENUM (
    'breakfast',
    'morning_snack',
    'lunch',
    'afternoon_snack',
    'dinner',
    'bedtime_snack'
);

CREATE TYPE diet_order_status AS ENUM (
    'active',
    'modified',
    'completed',
    'cancelled'
);

CREATE TYPE meal_prep_status AS ENUM (
    'pending',
    'preparing',
    'ready',
    'dispatched',
    'delivered'
);

-- ── Diet Templates ──────────────────────────────────────

CREATE TABLE diet_templates (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  UUID NOT NULL REFERENCES tenants(id),
    name       TEXT NOT NULL,
    diet_type  diet_type NOT NULL DEFAULT 'custom',
    description TEXT,
    calories_target   INT,
    protein_g         NUMERIC(6,1),
    carbs_g           NUMERIC(6,1),
    fat_g             NUMERIC(6,1),
    fiber_g           NUMERIC(6,1),
    sodium_mg         NUMERIC(7,1),
    restrictions      JSONB DEFAULT '[]',       -- ["gluten_free","lactose_free"]
    suitable_for      JSONB DEFAULT '[]',       -- ["vegetarian","vegan","halal"]
    is_active  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Diet Orders ─────────────────────────────────────────

CREATE TABLE diet_orders (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    patient_id       UUID NOT NULL,
    admission_id     UUID,                      -- NULL for day-care/outpatient
    template_id      UUID REFERENCES diet_templates(id),
    diet_type        diet_type NOT NULL DEFAULT 'regular',
    status           diet_order_status NOT NULL DEFAULT 'active',
    ordered_by       UUID,                      -- doctor/dietician
    special_instructions TEXT,
    allergies_flagged JSONB DEFAULT '[]',        -- copied from patient record
    is_npo           BOOLEAN NOT NULL DEFAULT FALSE,
    npo_reason       TEXT,
    start_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date         DATE,
    calories_target  INT,
    protein_g        NUMERIC(6,1),
    carbs_g          NUMERIC(6,1),
    fat_g            NUMERIC(6,1),
    preferences      JSONB DEFAULT '{}',        -- {"vegetarian":true,"no_onion":true}
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Kitchen Menus (weekly rotation) ─────────────────────

CREATE TABLE kitchen_menus (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    name        TEXT NOT NULL,                  -- "Week 1 - Summer Menu"
    week_number INT,
    season      TEXT,                           -- summer/winter/monsoon
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    valid_from  DATE,
    valid_until DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE kitchen_menu_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    menu_id     UUID NOT NULL REFERENCES kitchen_menus(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sun
    meal_type   meal_type NOT NULL,
    diet_type   diet_type NOT NULL DEFAULT 'regular',
    item_name   TEXT NOT NULL,
    description TEXT,
    calories    INT,
    protein_g   NUMERIC(6,1),
    carbs_g     NUMERIC(6,1),
    fat_g       NUMERIC(6,1),
    is_vegetarian BOOLEAN NOT NULL DEFAULT FALSE,
    allergens   JSONB DEFAULT '[]'              -- ["dairy","nuts","gluten"]
);

-- ── Meal Preparations ───────────────────────────────────

CREATE TABLE meal_preparations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    diet_order_id   UUID NOT NULL REFERENCES diet_orders(id),
    meal_type       meal_type NOT NULL,
    meal_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    status          meal_prep_status NOT NULL DEFAULT 'pending',
    prepared_by     UUID,
    prepared_at     TIMESTAMPTZ,
    dispatched_at   TIMESTAMPTZ,
    delivered_at    TIMESTAMPTZ,
    delivered_to_ward TEXT,
    delivered_to_bed  TEXT,
    patient_feedback  TEXT,
    feedback_rating   INT CHECK (feedback_rating BETWEEN 1 AND 5),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Meal Counts (auto-calculated snapshots) ─────────────

CREATE TABLE meal_counts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    count_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    meal_type   meal_type NOT NULL,
    ward        TEXT NOT NULL,
    total_beds  INT NOT NULL DEFAULT 0,
    occupied    INT NOT NULL DEFAULT 0,
    npo_count   INT NOT NULL DEFAULT 0,
    regular_count   INT NOT NULL DEFAULT 0,
    special_count   INT NOT NULL DEFAULT 0,
    notes       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, count_date, meal_type, ward)
);

-- ── Kitchen Inventory ───────────────────────────────────

CREATE TABLE kitchen_inventory (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    item_name     TEXT NOT NULL,
    category      TEXT,                           -- grain, vegetable, dairy, spice, etc.
    unit          TEXT NOT NULL DEFAULT 'kg',
    current_stock NUMERIC(10,2) NOT NULL DEFAULT 0,
    reorder_level NUMERIC(10,2),
    supplier      TEXT,
    last_procured_at TIMESTAMPTZ,
    expiry_date   DATE,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── FSSAI Compliance Audits ─────────────────────────────

CREATE TABLE kitchen_audits (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    audit_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    auditor_name    TEXT NOT NULL,
    audit_type      TEXT NOT NULL DEFAULT 'routine',  -- routine, surprise, external
    temperature_log JSONB DEFAULT '{}',               -- {"fridge":4,"freezer":-18,"hothold":65}
    hygiene_score   INT CHECK (hygiene_score BETWEEN 0 AND 100),
    findings        TEXT,
    corrective_actions TEXT,
    is_compliant    BOOLEAN NOT NULL DEFAULT TRUE,
    next_audit_date DATE,
    attachments     JSONB DEFAULT '[]',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── RLS Policies ────────────────────────────────────────

ALTER TABLE diet_templates       ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_orders          ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_menus        ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_menu_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_preparations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_counts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_inventory    ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_audits       ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_diet_templates      ON diet_templates      USING (tenant_id::text = current_setting('app.tenant_id', TRUE));
CREATE POLICY tenant_diet_orders         ON diet_orders         USING (tenant_id::text = current_setting('app.tenant_id', TRUE));
CREATE POLICY tenant_kitchen_menus       ON kitchen_menus       USING (tenant_id::text = current_setting('app.tenant_id', TRUE));
CREATE POLICY tenant_kitchen_menu_items  ON kitchen_menu_items  USING (tenant_id::text = current_setting('app.tenant_id', TRUE));
CREATE POLICY tenant_meal_preparations   ON meal_preparations   USING (tenant_id::text = current_setting('app.tenant_id', TRUE));
CREATE POLICY tenant_meal_counts         ON meal_counts         USING (tenant_id::text = current_setting('app.tenant_id', TRUE));
CREATE POLICY tenant_kitchen_inventory   ON kitchen_inventory   USING (tenant_id::text = current_setting('app.tenant_id', TRUE));
CREATE POLICY tenant_kitchen_audits      ON kitchen_audits      USING (tenant_id::text = current_setting('app.tenant_id', TRUE));

-- ── Indexes ─────────────────────────────────────────────

CREATE INDEX idx_diet_orders_patient     ON diet_orders(tenant_id, patient_id);
CREATE INDEX idx_diet_orders_admission   ON diet_orders(tenant_id, admission_id) WHERE admission_id IS NOT NULL;
CREATE INDEX idx_diet_orders_status      ON diet_orders(tenant_id, status);
CREATE INDEX idx_meal_prep_order         ON meal_preparations(tenant_id, diet_order_id);
CREATE INDEX idx_meal_prep_date          ON meal_preparations(tenant_id, meal_date, meal_type);
CREATE INDEX idx_meal_counts_date        ON meal_counts(tenant_id, count_date);
CREATE INDEX idx_kitchen_inventory_name  ON kitchen_inventory(tenant_id, item_name);
CREATE INDEX idx_kitchen_audits_date     ON kitchen_audits(tenant_id, audit_date);
CREATE INDEX idx_kitchen_menu_items_menu ON kitchen_menu_items(tenant_id, menu_id);

-- ── Triggers ────────────────────────────────────────────

CREATE TRIGGER set_diet_templates_updated    BEFORE UPDATE ON diet_templates      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_diet_orders_updated       BEFORE UPDATE ON diet_orders         FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_kitchen_menus_updated     BEFORE UPDATE ON kitchen_menus       FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_kitchen_inventory_updated BEFORE UPDATE ON kitchen_inventory   FOR EACH ROW EXECUTE FUNCTION update_updated_at();
