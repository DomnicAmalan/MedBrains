-- Migration 086: Clinical Completion — Retrospective Data Entry
-- Adds retrospective entry approval workflow for backdated records

-- ── Enum ──────────────────────────────────────────────
CREATE TYPE retrospective_entry_status AS ENUM ('pending', 'approved', 'rejected');

-- ── Table ─────────────────────────────────────────────
CREATE TABLE retrospective_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    source_table    TEXT NOT NULL,
    source_record_id UUID NOT NULL,
    clinical_event_date TIMESTAMPTZ NOT NULL,
    entry_date      TIMESTAMPTZ NOT NULL DEFAULT now(),
    entered_by      UUID NOT NULL REFERENCES users(id),
    reason          TEXT NOT NULL,
    status          retrospective_entry_status NOT NULL DEFAULT 'pending',
    reviewed_by     UUID REFERENCES users(id),
    reviewed_at     TIMESTAMPTZ,
    review_notes    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── RLS ───────────────────────────────────────────────
ALTER TABLE retrospective_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON retrospective_entries
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ── Indexes ───────────────────────────────────────────
CREATE INDEX idx_retro_entries_pending
    ON retrospective_entries (tenant_id, status) WHERE status = 'pending';

CREATE INDEX idx_retro_entries_source
    ON retrospective_entries (tenant_id, source_table, source_record_id);

-- ── ALTER existing tables ─────────────────────────────
ALTER TABLE encounters
    ADD COLUMN is_retrospective BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN retrospective_entry_id UUID REFERENCES retrospective_entries(id);

ALTER TABLE vitals
    ADD COLUMN is_retrospective BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE prescriptions
    ADD COLUMN is_retrospective BOOLEAN NOT NULL DEFAULT false;

-- Index for querying retrospective encounters
CREATE INDEX idx_encounters_retrospective
    ON encounters (tenant_id, is_retrospective) WHERE is_retrospective = true;

-- ── Seed tenant settings ──────────────────────────────
INSERT INTO tenant_settings (tenant_id, category, key, value)
SELECT id, 'retrospective', 'max_backdate_hours', '"72"'::jsonb FROM tenants
ON CONFLICT (tenant_id, category, key) DO NOTHING;

INSERT INTO tenant_settings (tenant_id, category, key, value)
SELECT id, 'retrospective', 'requires_approval', '"true"'::jsonb FROM tenants
ON CONFLICT (tenant_id, category, key) DO NOTHING;
