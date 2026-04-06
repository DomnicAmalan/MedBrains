-- 026: Screen Masters — Config-driven page layout system
-- Tables: screen_masters, screen_form_refs, tenant_screen_overrides,
--         screen_version_snapshots, screen_sidecars, screen_audit_log

-- ── Screen Type Enum ──────────────────────────────────────
CREATE TYPE screen_type AS ENUM (
    'form',        -- Data entry page (patient registration, lab order)
    'list',        -- Data table with filters (patient list, OPD queue)
    'detail',      -- Single record view (patient profile)
    'composite',   -- Mixed layout: form + table + stats (OPD consultation)
    'wizard',      -- Multi-step workflow (onboarding, discharge)
    'dashboard',   -- Widget grid (department dashboard)
    'calendar',    -- Schedule/appointment views
    'kanban'       -- Status board (lab pipeline, bed management)
);

-- ── Sidecar Trigger Enum ──────────────────────────────────
CREATE TYPE sidecar_trigger AS ENUM (
    'screen_load',      -- Screen opens
    'screen_exit',      -- User navigates away
    'form_submit',      -- Form submitted successfully
    'form_validate',    -- Before form submission
    'form_save_draft',  -- Auto-save or manual draft save
    'field_change',     -- Specific field value changed
    'row_select',       -- User selects a row in data table
    'row_action',       -- User clicks a row action button
    'interval',         -- Periodic (polling, auto-refresh)
    'step_enter',       -- Entering a wizard step
    'step_leave'        -- Leaving a wizard step
);

-- ── Screen Masters ────────────────────────────────────────
-- Full page definitions. tenant_id NULL = global system screen.
CREATE TABLE IF NOT EXISTS screen_masters (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    description     TEXT,
    screen_type     screen_type NOT NULL,
    module_code     TEXT,
    status          form_status NOT NULL DEFAULT 'draft',
    version         INT NOT NULL DEFAULT 1,
    layout          JSONB NOT NULL DEFAULT '{}',
    config          JSONB NOT NULL DEFAULT '{}',
    route_path      TEXT,
    icon            TEXT,
    permission_code TEXT,
    is_system       BOOLEAN NOT NULL DEFAULT false,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INT NOT NULL DEFAULT 0,
    published_at    TIMESTAMPTZ,
    published_by    UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Only one active screen per code per tenant (NULL tenant = system)
CREATE UNIQUE INDEX idx_screen_masters_active_code
    ON screen_masters (code, COALESCE(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid))
    WHERE status = 'active';

CREATE INDEX idx_screen_masters_tenant ON screen_masters(tenant_id);
CREATE INDEX idx_screen_masters_code ON screen_masters(code);
CREATE INDEX idx_screen_masters_module ON screen_masters(module_code);
CREATE INDEX idx_screen_masters_type ON screen_masters(screen_type);
CREATE INDEX idx_screen_masters_status ON screen_masters(status);

ALTER TABLE screen_masters ENABLE ROW LEVEL SECURITY;
CREATE POLICY screen_masters_tenant ON screen_masters
    USING (
        tenant_id IS NULL
        OR tenant_id::text = current_setting('app.tenant_id', true)
    );

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_screen_masters_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_screen_masters_updated_at
    BEFORE UPDATE ON screen_masters
    FOR EACH ROW
    EXECUTE FUNCTION update_screen_masters_updated_at();

-- ── Screen Form Refs ──────────────────────────────────────
-- Denormalized tracking of which forms a screen uses.
CREATE TABLE IF NOT EXISTS screen_form_refs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_id   UUID NOT NULL REFERENCES screen_masters(id) ON DELETE CASCADE,
    form_code   TEXT NOT NULL,
    zone_key    TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_screen_form_refs_screen ON screen_form_refs(screen_id);
CREATE INDEX idx_screen_form_refs_form ON screen_form_refs(form_code);

-- ── Tenant Screen Overrides ───────────────────────────────
-- Per-tenant customization of system screen layouts.
CREATE TABLE IF NOT EXISTS tenant_screen_overrides (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    screen_id       UUID NOT NULL REFERENCES screen_masters(id) ON DELETE CASCADE,
    layout_patch    JSONB NOT NULL DEFAULT '{}',
    config_patch    JSONB NOT NULL DEFAULT '{}',
    hidden_zones    JSONB NOT NULL DEFAULT '[]',
    extra_actions   JSONB NOT NULL DEFAULT '[]',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, screen_id)
);

ALTER TABLE tenant_screen_overrides ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_screen_overrides_tenant ON tenant_screen_overrides
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_tso_tenant ON tenant_screen_overrides(tenant_id);
CREATE INDEX idx_tso_screen ON tenant_screen_overrides(screen_id);

-- ── Screen Version Snapshots ──────────────────────────────
-- Immutable published versions of screens.
CREATE TABLE IF NOT EXISTS screen_version_snapshots (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_id       UUID NOT NULL REFERENCES screen_masters(id) ON DELETE CASCADE,
    version         INT NOT NULL,
    name            TEXT NOT NULL,
    screen_type     screen_type NOT NULL,
    status          form_status NOT NULL,
    layout          JSONB NOT NULL,
    config          JSONB NOT NULL DEFAULT '{}',
    form_refs       JSONB NOT NULL DEFAULT '[]',
    sidecars        JSONB NOT NULL DEFAULT '[]',
    change_summary  TEXT,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (screen_id, version)
);

CREATE INDEX idx_svs_screen ON screen_version_snapshots(screen_id);
CREATE INDEX idx_svs_screen_version ON screen_version_snapshots(screen_id, version DESC);

-- ── Screen Sidecars ───────────────────────────────────────
-- Pipeline triggers linked to screens.
CREATE TABLE IF NOT EXISTS screen_sidecars (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_id       UUID NOT NULL REFERENCES screen_masters(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    description     TEXT,
    trigger_event   sidecar_trigger NOT NULL,
    trigger_config  JSONB NOT NULL DEFAULT '{}',
    pipeline_id     UUID REFERENCES integration_pipelines(id) ON DELETE SET NULL,
    inline_action   JSONB,
    condition       JSONB,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_screen_sidecars_screen ON screen_sidecars(screen_id);
CREATE INDEX idx_screen_sidecars_trigger ON screen_sidecars(trigger_event);
CREATE INDEX idx_screen_sidecars_pipeline ON screen_sidecars(pipeline_id)
    WHERE pipeline_id IS NOT NULL;

-- ── Screen Audit Log ──────────────────────────────────────
-- Change tracking for screen definitions.
CREATE TABLE IF NOT EXISTS screen_audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_id       UUID NOT NULL REFERENCES screen_masters(id) ON DELETE CASCADE,
    action          TEXT NOT NULL,
    previous_state  JSONB,
    new_state       JSONB NOT NULL,
    changed_fields  TEXT[],
    changed_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_screen_audit_screen ON screen_audit_log(screen_id);
CREATE INDEX idx_screen_audit_time ON screen_audit_log(changed_at DESC);
