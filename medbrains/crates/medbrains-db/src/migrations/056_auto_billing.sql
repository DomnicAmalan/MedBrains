-- Auto-billing integration: idempotency index, charge_source extension, settings seed

-- 1. Add 'radiology' to charge_source enum
ALTER TYPE charge_source ADD VALUE IF NOT EXISTS 'radiology';

-- 2. Idempotency index: prevent double-charging same source entity on an invoice
CREATE UNIQUE INDEX IF NOT EXISTS idx_invoice_items_source_idempotency
  ON invoice_items (invoice_id, source, source_id)
  WHERE source_id IS NOT NULL;

-- 3. Seed auto-billing settings for all existing tenants (all disabled by default)
INSERT INTO tenant_settings (tenant_id, category, key, value)
SELECT t.id, 'billing', s.key, s.value::jsonb
FROM tenants t
CROSS JOIN (VALUES
  ('auto_charge_opd',       'false'),
  ('auto_charge_lab',       'false'),
  ('auto_charge_pharmacy',  'false'),
  ('auto_charge_radiology', 'false'),
  ('auto_charge_ipd_room',  'false')
) AS s(key, value)
ON CONFLICT (tenant_id, category, key) DO NOTHING;
