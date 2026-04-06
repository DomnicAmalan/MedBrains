-- Pharmacy regulatory compliance fields
-- Adds drug scheduling, nomenclature, formulary, and safety fields to pharmacy_catalog.
-- Compliance enforcement is switchable via tenant_settings (category = 'compliance').

-- ── New columns on pharmacy_catalog ────────────────────────────
ALTER TABLE pharmacy_catalog
    ADD COLUMN IF NOT EXISTS drug_schedule       TEXT CHECK (drug_schedule IN ('H', 'H1', 'X', 'G', 'OTC', 'NDPS', NULL)),
    ADD COLUMN IF NOT EXISTS is_controlled       BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS inn_name            TEXT,
    ADD COLUMN IF NOT EXISTS atc_code            TEXT,
    ADD COLUMN IF NOT EXISTS rxnorm_code         TEXT,
    ADD COLUMN IF NOT EXISTS snomed_code         TEXT,
    ADD COLUMN IF NOT EXISTS formulary_status    TEXT NOT NULL DEFAULT 'approved'
                             CHECK (formulary_status IN ('approved', 'restricted', 'non_formulary')),
    ADD COLUMN IF NOT EXISTS aware_category      TEXT CHECK (aware_category IN ('access', 'watch', 'reserve', NULL)),
    ADD COLUMN IF NOT EXISTS is_lasa             BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS lasa_group          TEXT,
    ADD COLUMN IF NOT EXISTS max_dose_per_day    TEXT,
    ADD COLUMN IF NOT EXISTS batch_tracking_required BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS storage_conditions  TEXT,
    ADD COLUMN IF NOT EXISTS black_box_warning   TEXT;

-- Index for schedule-based queries (filtered dispense lists)
CREATE INDEX IF NOT EXISTS idx_pharmacy_catalog_schedule ON pharmacy_catalog(tenant_id, drug_schedule)
    WHERE drug_schedule IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_pharmacy_catalog_controlled ON pharmacy_catalog(tenant_id, is_controlled)
    WHERE is_controlled = true;
CREATE INDEX IF NOT EXISTS idx_pharmacy_catalog_formulary ON pharmacy_catalog(tenant_id, formulary_status);

-- ── Seed default compliance settings for ALL existing tenants ──
-- These are switchable toggles. All default to false (off) so existing
-- tenants are not disrupted. Hospital admins enable what they need.
INSERT INTO tenant_settings (tenant_id, category, key, value)
SELECT t.id, 'compliance', s.key, s.value::jsonb
FROM tenants t
CROSS JOIN (VALUES
    ('enforce_drug_scheduling',     'false'),
    ('enforce_ndps_tracking',       'false'),
    ('enforce_formulary',           'false'),
    ('enforce_drug_interactions',   'false'),
    ('enforce_antibiotic_stewardship', 'false'),
    ('enforce_lasa_warnings',       'false'),
    ('enforce_max_dose_check',      'false'),
    ('enforce_batch_tracking',      'false'),
    ('show_schedule_badges',        'true'),
    ('show_controlled_warnings',    'true'),
    ('show_formulary_status',       'true'),
    ('show_aware_category',         'true')
) AS s(key, value)
ON CONFLICT DO NOTHING;
