-- MedBrains HMS — Migration 031
-- 1) Add base_price to services table
-- 2) Add index on geo_towns.pincode for PIN-code reverse lookup

-- ============================================================
-- Services: add base_price column
-- ============================================================
ALTER TABLE services ADD COLUMN IF NOT EXISTS base_price NUMERIC(12,2) NOT NULL DEFAULT 0;

-- ============================================================
-- Geo Towns: add index on pincode for fast lookups
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_geo_towns_pincode ON geo_towns(pincode) WHERE pincode IS NOT NULL;
