-- ============================================================
-- Migration 007: Onboarding Enhancements
-- Adds working hours, doctor profiles, bed types, tax categories,
-- payment methods for complete Day-1 hospital configuration.
-- ============================================================

-- ── ALTER departments: add working_hours JSONB ────────────
-- Shape: { "monday": { "morning": {"start":"09:00","end":"13:00"}, "evening": {"start":"16:00","end":"20:00"} }, "sunday": null }
ALTER TABLE departments ADD COLUMN IF NOT EXISTS working_hours JSONB NOT NULL DEFAULT '{}';

-- ── ALTER users: add doctor profile fields ────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS specialization TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS medical_registration_number TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS qualification TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS consultation_fee NUMERIC(10,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS department_ids UUID[] NOT NULL DEFAULT '{}';

-- ── ALTER services: make department_id optional for onboarding ──
ALTER TABLE services ALTER COLUMN department_id DROP NOT NULL;
-- Add description column for service categories
ALTER TABLE services ADD COLUMN IF NOT EXISTS description TEXT;

-- ============================================================
-- Bed Types — pricing for bed categories
-- ============================================================
CREATE TABLE bed_types (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    daily_rate  NUMERIC(10,2) NOT NULL DEFAULT 0,
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_bed_types_tenant ON bed_types(tenant_id);

ALTER TABLE bed_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY bed_types_tenant_isolation ON bed_types
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_bed_types_updated_at BEFORE UPDATE ON bed_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Tax Categories — GST slabs, exemptions
-- ============================================================
CREATE TYPE tax_applicability AS ENUM ('taxable', 'exempt', 'zero_rated');

CREATE TABLE tax_categories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    rate_percent    NUMERIC(5,2) NOT NULL DEFAULT 0,
    applicability   tax_applicability NOT NULL DEFAULT 'taxable',
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_tax_categories_tenant ON tax_categories(tenant_id);

ALTER TABLE tax_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY tax_categories_tenant_isolation ON tax_categories
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_tax_categories_updated_at BEFORE UPDATE ON tax_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Payment Methods — accepted payment modes
-- ============================================================
CREATE TABLE payment_methods (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    is_default  BOOLEAN NOT NULL DEFAULT false,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_payment_methods_tenant ON payment_methods(tenant_id);

ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
CREATE POLICY payment_methods_tenant_isolation ON payment_methods
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_payment_methods_updated_at BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
