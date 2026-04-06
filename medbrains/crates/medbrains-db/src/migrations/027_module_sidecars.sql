-- Module-level sidecars: allow clinical pages (hardcoded, non-ScreenRenderer pages)
-- to participate in the sidecar/pipeline system.
--
-- A module_sidecar ties a trigger event to a specific module + context combination
-- (e.g. module_code = 'opd', context_code = 'opd-queue') so that when the clinical
-- page emits that trigger, matching sidecars fire (pipeline or inline action).

CREATE TABLE module_sidecars (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    module_code     TEXT NOT NULL,
    context_code    TEXT NOT NULL,
    name            TEXT NOT NULL,
    trigger_event   sidecar_trigger NOT NULL,
    pipeline_id     UUID REFERENCES integration_pipelines(id) ON DELETE SET NULL,
    inline_action   JSONB,
    condition       JSONB,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INT NOT NULL DEFAULT 0,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_module_sidecars_lookup
    ON module_sidecars (tenant_id, module_code, context_code)
    WHERE is_active;

CREATE INDEX idx_module_sidecars_tenant
    ON module_sidecars (tenant_id);

-- RLS
ALTER TABLE module_sidecars ENABLE ROW LEVEL SECURITY;

CREATE POLICY module_sidecars_tenant_isolation
    ON module_sidecars
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
