-- 017: Add icon and icon_position to form_fields for per-field icon display
ALTER TABLE form_fields
  ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS icon_position TEXT DEFAULT 'left';

COMMENT ON COLUMN form_fields.icon IS 'Icon name for the field input (e.g., phone, mail, hi-cardiology)';
COMMENT ON COLUMN form_fields.icon_position IS 'Where the icon appears: left or right of the input';
