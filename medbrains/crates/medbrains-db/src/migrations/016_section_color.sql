-- 016: Add color column to form_sections for section icon theming
ALTER TABLE form_sections
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT NULL;

COMMENT ON COLUMN form_sections.color IS 'Mantine color name for section icon theming (e.g., blue, teal, red)';
