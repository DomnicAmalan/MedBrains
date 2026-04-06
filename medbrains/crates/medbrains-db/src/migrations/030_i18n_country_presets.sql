-- Migration 030: i18n & Country Presets
-- Adds locale/measurement columns to geo_countries, seeds 13 additional countries,
-- and seeds 8 new regulatory bodies for international support.

-- ── 1. Extend geo_countries with locale/measurement columns ──

ALTER TABLE geo_countries
  ADD COLUMN IF NOT EXISTS default_locale TEXT NOT NULL DEFAULT 'en',
  ADD COLUMN IF NOT EXISTS default_timezone TEXT NOT NULL DEFAULT 'UTC',
  ADD COLUMN IF NOT EXISTS date_format TEXT NOT NULL DEFAULT 'DD/MM/YYYY',
  ADD COLUMN IF NOT EXISTS measurement_system TEXT NOT NULL DEFAULT 'metric';

-- Update existing India row
UPDATE geo_countries
SET default_locale = 'en',
    default_timezone = 'Asia/Kolkata',
    date_format = 'DD/MM/YYYY',
    measurement_system = 'metric'
WHERE code = 'IN';

-- ── 2. Seed additional countries ──

INSERT INTO geo_countries (id, code, name, phone_code, currency, is_active, default_locale, default_timezone, date_format, measurement_system) VALUES
  (gen_random_uuid(), 'US', 'United States',       '+1',   'USD', true, 'en', 'America/New_York',   'MM/DD/YYYY', 'imperial'),
  (gen_random_uuid(), 'GB', 'United Kingdom',       '+44',  'GBP', true, 'en', 'Europe/London',      'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'AE', 'United Arab Emirates', '+971', 'AED', true, 'en', 'Asia/Dubai',         'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'SA', 'Saudi Arabia',         '+966', 'SAR', true, 'ar', 'Asia/Riyadh',        'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'QA', 'Qatar',                '+974', 'QAR', true, 'ar', 'Asia/Qatar',         'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'OM', 'Oman',                 '+968', 'OMR', true, 'ar', 'Asia/Muscat',        'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'BH', 'Bahrain',              '+973', 'BHD', true, 'ar', 'Asia/Bahrain',       'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'KW', 'Kuwait',               '+965', 'KWD', true, 'ar', 'Asia/Kuwait',        'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'BD', 'Bangladesh',            '+880', 'BDT', true, 'bn', 'Asia/Dhaka',         'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'LK', 'Sri Lanka',             '+94',  'LKR', true, 'en', 'Asia/Colombo',       'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'NP', 'Nepal',                 '+977', 'NPR', true, 'ne', 'Asia/Kathmandu',     'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'SG', 'Singapore',             '+65',  'SGD', true, 'en', 'Asia/Singapore',     'DD/MM/YYYY', 'metric'),
  (gen_random_uuid(), 'AU', 'Australia',             '+61',  'AUD', true, 'en', 'Australia/Sydney',   'DD/MM/YYYY', 'metric')
ON CONFLICT (code) DO NOTHING;

-- ── 3. Seed additional regulatory bodies ──

INSERT INTO regulatory_bodies (id, code, name, level, description, is_active) VALUES
  -- US
  (gen_random_uuid(), 'HIPAA',    'Health Insurance Portability and Accountability Act', 'national'::regulatory_level,
   'US federal law for health data privacy and security', true),
  (gen_random_uuid(), 'TJC',      'The Joint Commission', 'international'::regulatory_level,
   'US-based healthcare accreditation organization', true),
  (gen_random_uuid(), 'CMS',      'Centers for Medicare & Medicaid Services', 'national'::regulatory_level,
   'US federal agency administering Medicare/Medicaid', true),
  -- UAE
  (gen_random_uuid(), 'DHA',      'Dubai Health Authority', 'national'::regulatory_level,
   'Regulatory authority for healthcare in Dubai', true),
  (gen_random_uuid(), 'HAAD',     'Health Authority Abu Dhabi', 'national'::regulatory_level,
   'Healthcare regulatory authority for Abu Dhabi', true),
  (gen_random_uuid(), 'MOH-UAE',  'Ministry of Health UAE', 'national'::regulatory_level,
   'UAE Ministry of Health and Prevention', true),
  -- International
  (gen_random_uuid(), 'ISO-15189', 'ISO 15189 Medical Laboratories', 'international'::regulatory_level,
   'International standard for quality and competence in medical labs', true),
  (gen_random_uuid(), 'ISO-9001',  'ISO 9001 Quality Management', 'international'::regulatory_level,
   'International standard for quality management systems', true)
ON CONFLICT (code) DO NOTHING;

-- Link US bodies to US country
UPDATE regulatory_bodies
SET country_id = (SELECT id FROM geo_countries WHERE code = 'US')
WHERE code IN ('HIPAA', 'TJC', 'CMS') AND country_id IS NULL;

-- Link UAE bodies to UAE country
UPDATE regulatory_bodies
SET country_id = (SELECT id FROM geo_countries WHERE code = 'AE')
WHERE code IN ('DHA', 'HAAD', 'MOH-UAE') AND country_id IS NULL;
