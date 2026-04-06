-- 018: Form & Field Versioning
-- Adds publish-based versioning with immutable active forms, JSONB snapshots,
-- and field master audit logging.

-- ── form_version_snapshots: historical published versions ────────────

CREATE TABLE IF NOT EXISTS form_version_snapshots (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id         UUID NOT NULL REFERENCES form_masters(id) ON DELETE CASCADE,
    version         INT NOT NULL,
    name            TEXT NOT NULL,
    status          form_status NOT NULL,
    config          JSONB,
    snapshot        JSONB NOT NULL,
    change_summary  TEXT,
    created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (form_id, version)
);

CREATE INDEX IF NOT EXISTS idx_fvs_form ON form_version_snapshots(form_id);
CREATE INDEX IF NOT EXISTS idx_fvs_form_version ON form_version_snapshots(form_id, version DESC);

-- ── field_master_audit_log: track changes to field masters ──────────

CREATE TABLE IF NOT EXISTS field_master_audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field_id        UUID NOT NULL REFERENCES field_masters(id) ON DELETE CASCADE,
    action          TEXT NOT NULL,
    previous_state  JSONB,
    new_state       JSONB NOT NULL,
    changed_fields  TEXT[],
    changed_by      UUID REFERENCES users(id) ON DELETE SET NULL,
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fmal_field ON field_master_audit_log(field_id);
CREATE INDEX IF NOT EXISTS idx_fmal_time ON field_master_audit_log(changed_at DESC);

-- ── Extend form_masters with publish metadata ───────────────────────

ALTER TABLE form_masters
    ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS published_by UUID REFERENCES users(id) ON DELETE SET NULL;
