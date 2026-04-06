-- 019: Dashboard Widget Builder System
-- Tables: dashboards, dashboard_widgets, widget_templates
-- Supports role-based configurable dashboards with drag-and-drop widgets

-- ── Widget Type Enum ────────────────────────────────────
CREATE TYPE widget_type AS ENUM (
    'stat_card',
    'data_table',
    'list',
    'chart',
    'quick_actions',
    'module_embed',
    'form_embed',
    'system_health',
    'custom_html'
);

-- ── Dashboards ──────────────────────────────────────────
CREATE TABLE dashboards (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,   -- NULL = shared, set = personal
    name            TEXT NOT NULL,
    code            TEXT NOT NULL,
    description     TEXT,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    role_codes      JSONB NOT NULL DEFAULT '[]',       -- ["doctor", "nurse"] or [] for all
    department_ids  JSONB NOT NULL DEFAULT '[]',       -- department UUIDs this dashboard targets
    layout_config   JSONB NOT NULL DEFAULT '{"columns": 12, "row_height": 80, "gap": 16}',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    cloned_from     UUID REFERENCES dashboards(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_dashboards_tenant ON dashboards(tenant_id);
CREATE INDEX idx_dashboards_active ON dashboards(tenant_id, is_active) WHERE is_active = true;
CREATE INDEX idx_dashboards_user ON dashboards(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_dashboards_dept ON dashboards USING gin(department_ids jsonb_path_ops);

-- ── Dashboard Widgets ───────────────────────────────────
CREATE TABLE dashboard_widgets (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dashboard_id        UUID NOT NULL REFERENCES dashboards(id) ON DELETE CASCADE,
    widget_type         widget_type NOT NULL,
    title               TEXT NOT NULL,
    subtitle            TEXT,
    icon                TEXT,
    color               TEXT,
    config              JSONB NOT NULL DEFAULT '{}',
    data_source         JSONB NOT NULL DEFAULT '{}',
    position_x          INT NOT NULL DEFAULT 0,
    position_y          INT NOT NULL DEFAULT 0,
    width               INT NOT NULL DEFAULT 4,
    height              INT NOT NULL DEFAULT 2,
    min_width           INT NOT NULL DEFAULT 2,
    min_height          INT NOT NULL DEFAULT 1,
    refresh_interval    INT,
    is_visible          BOOLEAN NOT NULL DEFAULT true,
    permission_code     TEXT,
    sort_order          INT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_dw_dashboard ON dashboard_widgets(dashboard_id);

-- ── Widget Templates ────────────────────────────────────
CREATE TABLE widget_templates (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name                  TEXT NOT NULL,
    description           TEXT,
    widget_type           widget_type NOT NULL,
    icon                  TEXT,
    color                 TEXT,
    default_config        JSONB NOT NULL DEFAULT '{}',
    default_source        JSONB NOT NULL DEFAULT '{}',
    default_width         INT NOT NULL DEFAULT 4,
    default_height        INT NOT NULL DEFAULT 2,
    category              TEXT NOT NULL DEFAULT 'general',
    is_system             BOOLEAN NOT NULL DEFAULT false,
    required_permissions  JSONB NOT NULL DEFAULT '[]',  -- permissions user must have to see this template
    required_departments  JSONB NOT NULL DEFAULT '[]',  -- department UUIDs; [] = all departments
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_wt_tenant ON widget_templates(tenant_id);
CREATE INDEX idx_wt_category ON widget_templates(category);

-- ── RLS Policies ────────────────────────────────────────
ALTER TABLE dashboards ENABLE ROW LEVEL SECURITY;
CREATE POLICY dashboards_tenant ON dashboards
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

ALTER TABLE widget_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY wt_tenant ON widget_templates
    USING (tenant_id IS NULL OR tenant_id = current_setting('app.tenant_id')::uuid);

-- dashboard_widgets: accessed via join on dashboards (which has RLS)
-- No direct RLS needed — all access goes through dashboard_id FK

-- ── Seed System Widget Templates ────────────────────────
INSERT INTO widget_templates (name, description, widget_type, icon, color, default_config, default_source, default_width, default_height, category, is_system, required_permissions) VALUES
    ('Patient Count', 'Total registered patients', 'stat_card', 'users', 'primary',
     '{"format": "number"}',
     '{"type": "module_query", "module": "patients", "query": "count"}',
     3, 2, 'metrics', true, '["patients.list"]'),

    ('OPD Queue', 'Current OPD queue length', 'stat_card', 'stethoscope', 'teal',
     '{"format": "number"}',
     '{"type": "module_query", "module": "opd", "query": "queue_count"}',
     3, 2, 'metrics', true, '["opd.visit.list"]'),

    ('Lab Pending', 'Pending lab investigations', 'stat_card', 'test-pipe', 'orange',
     '{"format": "number"}',
     '{"type": "module_query", "module": "lab", "query": "pending_count"}',
     3, 2, 'metrics', true, '["lab.orders.list"]'),

    ('Revenue Today', 'Today''s billing revenue', 'stat_card', 'receipt', 'violet',
     '{"format": "currency"}',
     '{"type": "module_query", "module": "billing", "query": "today_revenue"}',
     3, 2, 'metrics', true, '["billing.invoices.list"]'),

    ('Bed Occupancy', 'Current bed occupancy', 'stat_card', 'bed', 'indigo',
     '{"format": "number"}',
     '{"type": "module_query", "module": "ipd", "query": "occupied_beds"}',
     3, 2, 'metrics', true, '["ipd.admission.list"]'),

    ('Quick Actions', 'Common task shortcuts', 'quick_actions', 'list-check', 'primary',
     '{"actions": [{"label": "Register Patient", "path": "/patients", "icon": "users", "color": "primary", "permission": "patients.create"}, {"label": "New OPD Visit", "path": "/opd", "icon": "stethoscope", "color": "teal", "permission": "opd.visit.create"}, {"label": "Lab Order", "path": "/lab", "icon": "test-pipe", "color": "orange", "permission": "lab.orders.create"}, {"label": "Generate Invoice", "path": "/billing", "icon": "receipt", "color": "violet", "permission": "billing.invoices.create"}]}',
     '{"type": "static"}',
     8, 3, 'actions', true, '[]'),

    ('Recent Patients', 'Recently registered patients', 'data_table', 'users', 'primary',
     '{"columns": [{"key": "uhid", "label": "UHID"}, {"key": "name", "label": "Name"}, {"key": "created_at", "label": "Registered"}], "page_size": 5}',
     '{"type": "module_query", "module": "patients", "query": "recent_registrations", "params": {"limit": 5}}',
     6, 4, 'data', true, '["patients.list"]'),

    ('OPD Tokens', 'Active OPD tokens today', 'data_table', 'stethoscope', 'teal',
     '{"columns": [{"key": "token_no", "label": "Token"}, {"key": "patient_name", "label": "Patient"}, {"key": "doctor_name", "label": "Doctor"}, {"key": "status", "label": "Status"}], "page_size": 5}',
     '{"type": "module_query", "module": "opd", "query": "active_tokens", "params": {"limit": 10}}',
     6, 4, 'data', true, '["opd.visit.list"]'),

    ('Lab Results', 'Recent lab results', 'list', 'test-pipe', 'orange',
     '{"max_items": 5, "show_timestamp": true}',
     '{"type": "module_query", "module": "lab", "query": "recent_results", "params": {"limit": 5}}',
     4, 3, 'data', true, '["lab.orders.list"]'),

    ('Billing Summary', 'Revenue summary chart', 'chart', 'receipt', 'violet',
     '{"chart_type": "bar"}',
     '{"type": "module_query", "module": "billing", "query": "revenue_summary"}',
     6, 4, 'data', true, '["billing.invoices.list"]'),

    ('Recent Activity', 'Latest system activity feed', 'list', 'activity', 'gray',
     '{"max_items": 8, "show_timestamp": true, "show_icon": true}',
     '{"type": "module_query", "module": "system", "query": "recent_activity", "params": {"limit": 8}}',
     4, 4, 'data', true, '[]'),

    ('System Health', 'API and database health status', 'system_health', 'settings', 'green',
     '{}',
     '{"type": "module_query", "module": "system", "query": "health_check"}',
     4, 3, 'system', true, '["admin.settings.general.manage"]'),

    ('Department Stats', 'Department-level summary', 'module_embed', 'hospital', 'blue',
     '{"module_code": "departments", "view_mode": "stats"}',
     '{"type": "module_query", "module": "departments", "query": "stats"}',
     6, 3, 'module', true, '["admin.settings.departments.manage"]'),

    ('IPD Admissions', 'Today''s admissions and discharges', 'module_embed', 'bed', 'indigo',
     '{"module_code": "ipd", "view_mode": "stats"}',
     '{"type": "module_query", "module": "ipd", "query": "today_admissions"}',
     6, 3, 'module', true, '["ipd.admission.list"]'),

    ('Custom HTML', 'Custom HTML/markdown content block', 'custom_html', 'notes', 'gray',
     '{"content": "Welcome to MedBrains HMS"}',
     '{"type": "static"}',
     6, 2, 'general', true, '[]');
