-- 015: Add data_source and actions JSONB columns to field_masters and form_fields
-- Supports: API-bound dropdowns, cascading selects, field action buttons

-- Add data_source and actions to field_masters (master-level defaults)
ALTER TABLE field_masters
  ADD COLUMN IF NOT EXISTS data_source JSONB DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS actions JSONB DEFAULT NULL;

-- Add per-form overrides to form_fields
ALTER TABLE form_fields
  ADD COLUMN IF NOT EXISTS data_source_override JSONB DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS actions_override JSONB DEFAULT NULL;

COMMENT ON COLUMN field_masters.data_source IS 'Data source binding: static | api | dependent';
COMMENT ON COLUMN field_masters.actions IS 'Field actions array: api_call | validate | lookup | copy_value';
COMMENT ON COLUMN form_fields.data_source_override IS 'Per-form override of field data_source';
COMMENT ON COLUMN form_fields.actions_override IS 'Per-form override of field actions';
