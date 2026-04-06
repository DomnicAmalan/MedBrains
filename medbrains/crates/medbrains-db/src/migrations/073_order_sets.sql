-- ============================================================
-- Migration 073: Order Sets Module
-- Reusable bundles of orders (labs, medications, nursing, diets)
-- activated with one click during patient encounters
-- ============================================================

-- ── Enums ────────────────────────────────────────────────────

CREATE TYPE order_set_context AS ENUM (
    'general',
    'admission',
    'pre_operative',
    'diagnosis_specific',
    'department_specific'
);

CREATE TYPE order_set_item_type AS ENUM (
    'lab',
    'medication',
    'nursing',
    'diet'
);

-- ── Tables ───────────────────────────────────────────────────

-- 1. order_set_templates — reusable template definitions
CREATE TABLE order_set_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            TEXT NOT NULL,
    code            TEXT,
    description     TEXT,
    context         order_set_context NOT NULL DEFAULT 'general',
    department_id   UUID REFERENCES departments(id),
    trigger_diagnoses TEXT[] DEFAULT '{}',
    surgery_type    TEXT,
    version         INT NOT NULL DEFAULT 1,
    is_current      BOOLEAN NOT NULL DEFAULT true,
    parent_template_id UUID REFERENCES order_set_templates(id),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_by      UUID REFERENCES users(id),
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE order_set_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_order_set_templates ON order_set_templates
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_order_set_templates_tenant_context
    ON order_set_templates (tenant_id, context);
CREATE INDEX idx_order_set_templates_tenant_current_active
    ON order_set_templates (tenant_id, is_current, is_active);
CREATE INDEX idx_order_set_templates_trigger_diagnoses
    ON order_set_templates USING GIN (trigger_diagnoses);
CREATE INDEX idx_order_set_templates_parent
    ON order_set_templates (parent_template_id) WHERE parent_template_id IS NOT NULL;

CREATE TRIGGER trg_order_set_templates_updated_at
    BEFORE UPDATE ON order_set_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. order_set_template_items — items within a template
CREATE TABLE order_set_template_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    template_id     UUID NOT NULL REFERENCES order_set_templates(id) ON DELETE CASCADE,
    item_type       order_set_item_type NOT NULL,
    sort_order      INT NOT NULL DEFAULT 0,
    is_mandatory    BOOLEAN NOT NULL DEFAULT false,
    default_selected BOOLEAN NOT NULL DEFAULT true,
    -- Lab fields
    lab_test_id     UUID REFERENCES lab_test_catalog(id),
    lab_priority    TEXT,
    lab_notes       TEXT,
    -- Medication fields
    drug_catalog_id UUID REFERENCES pharmacy_catalog(id),
    drug_name       TEXT,
    dosage          TEXT,
    frequency       TEXT,
    duration        TEXT,
    route           TEXT,
    med_instructions TEXT,
    -- Nursing fields
    task_type       TEXT,
    task_description TEXT,
    task_frequency  TEXT,
    -- Diet fields
    diet_template_id UUID REFERENCES diet_templates(id),
    diet_type       TEXT,
    diet_instructions TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE order_set_template_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_order_set_template_items ON order_set_template_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_order_set_template_items_template_sort
    ON order_set_template_items (template_id, sort_order);

-- 3. order_set_activations — instance of template activation per encounter
CREATE TABLE order_set_activations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    template_id     UUID NOT NULL REFERENCES order_set_templates(id),
    template_version INT NOT NULL,
    encounter_id    UUID REFERENCES encounters(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    admission_id    UUID REFERENCES admissions(id),
    activated_by    UUID REFERENCES users(id),
    diagnosis_icd   TEXT,
    total_items     INT NOT NULL DEFAULT 0,
    selected_items  INT NOT NULL DEFAULT 0,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE order_set_activations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_order_set_activations ON order_set_activations
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_order_set_activations_encounter
    ON order_set_activations (encounter_id);
CREATE INDEX idx_order_set_activations_template
    ON order_set_activations (template_id);
CREATE INDEX idx_order_set_activations_patient
    ON order_set_activations (patient_id);

-- 4. order_set_activation_items — per-item tracking with order references
CREATE TABLE order_set_activation_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    activation_id   UUID NOT NULL REFERENCES order_set_activations(id) ON DELETE CASCADE,
    template_item_id UUID REFERENCES order_set_template_items(id),
    item_type       order_set_item_type NOT NULL,
    was_selected    BOOLEAN NOT NULL DEFAULT true,
    skip_reason     TEXT,
    -- Polymorphic FKs to created orders
    lab_order_id    UUID,
    prescription_id UUID,
    nursing_task_id UUID,
    diet_order_id   UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE order_set_activation_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_order_set_activation_items ON order_set_activation_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_order_set_activation_items_activation
    ON order_set_activation_items (activation_id);

-- 5. order_set_usage_stats — denormalized analytics
CREATE TABLE order_set_usage_stats (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    template_id     UUID NOT NULL REFERENCES order_set_templates(id),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    activation_count INT NOT NULL DEFAULT 0,
    unique_doctors  INT NOT NULL DEFAULT 0,
    items_ordered   INT NOT NULL DEFAULT 0,
    items_skipped   INT NOT NULL DEFAULT 0,
    completion_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
    UNIQUE (tenant_id, template_id, period_start)
);

ALTER TABLE order_set_usage_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_order_set_usage_stats ON order_set_usage_stats
    USING (tenant_id::text = current_setting('app.tenant_id', true));
