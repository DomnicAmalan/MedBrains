-- 057 Billing Phase 2: GST, Advances, Interim Billing, Corporate, Reports, Insurance Enhancements
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── New Enums ────────────────────────────────────────────────────────────────

CREATE TYPE gst_type AS ENUM ('cgst_sgst', 'igst', 'exempt');

CREATE TYPE advance_purpose AS ENUM ('admission', 'prepaid', 'general', 'procedure');

CREATE TYPE advance_status AS ENUM ('active', 'partially_used', 'fully_used', 'refunded');

CREATE TYPE insurance_scheme_type AS ENUM (
    'private', 'cghs', 'echs', 'pmjay', 'esis', 'state_scheme'
);

-- ── ALTER charge_master ──────────────────────────────────────────────────────

ALTER TABLE charge_master
    ADD COLUMN IF NOT EXISTS hsn_sac_code TEXT,
    ADD COLUMN IF NOT EXISTS gst_category TEXT DEFAULT 'healthcare';

-- ── ALTER invoices ───────────────────────────────────────────────────────────

ALTER TABLE invoices
    ADD COLUMN IF NOT EXISTS cgst_amount NUMERIC(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sgst_amount NUMERIC(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS igst_amount NUMERIC(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cess_amount NUMERIC(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_interim BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS billing_period_start TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS billing_period_end TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS sequence_number INT,
    ADD COLUMN IF NOT EXISTS corporate_id UUID,
    ADD COLUMN IF NOT EXISTS place_of_supply TEXT;

-- ── ALTER invoice_items ──────────────────────────────────────────────────────

ALTER TABLE invoice_items
    ADD COLUMN IF NOT EXISTS gst_rate NUMERIC(5,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS gst_type gst_type DEFAULT 'exempt',
    ADD COLUMN IF NOT EXISTS cgst_amount NUMERIC(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sgst_amount NUMERIC(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS igst_amount NUMERIC(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS hsn_sac_code TEXT;

-- ── ALTER insurance_claims ───────────────────────────────────────────────────

ALTER TABLE insurance_claims
    ADD COLUMN IF NOT EXISTS scheme_type insurance_scheme_type DEFAULT 'private',
    ADD COLUMN IF NOT EXISTS co_pay_percent NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS deductible_amount NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS member_id TEXT,
    ADD COLUMN IF NOT EXISTS scheme_card_number TEXT;

-- ── New Table: corporate_clients ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS corporate_clients (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    gst_number  TEXT,
    billing_address TEXT,
    contact_email   TEXT,
    contact_phone   TEXT,
    credit_limit    NUMERIC(14,2) DEFAULT 0,
    credit_days     INT DEFAULT 30,
    agreed_discount_percent NUMERIC(5,2) DEFAULT 0,
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

-- FK for invoices.corporate_id (after corporate_clients exists)
DO $$ BEGIN
    ALTER TABLE invoices
        ADD CONSTRAINT fk_invoices_corporate
        FOREIGN KEY (corporate_id) REFERENCES corporate_clients(id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ── New Table: corporate_enrollments ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS corporate_enrollments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    corporate_id UUID NOT NULL REFERENCES corporate_clients(id) ON DELETE CASCADE,
    patient_id  UUID NOT NULL REFERENCES patients(id),
    employee_id TEXT,
    department  TEXT,
    is_active   BOOLEAN DEFAULT true,
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, corporate_id, patient_id)
);

-- ── New Table: patient_advances ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS patient_advances (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID,
    advance_number  TEXT NOT NULL,
    amount          NUMERIC(12,2) NOT NULL,
    balance         NUMERIC(12,2) NOT NULL,
    payment_mode    payment_mode NOT NULL DEFAULT 'cash',
    reference_number TEXT,
    purpose         advance_purpose NOT NULL DEFAULT 'general',
    status          advance_status NOT NULL DEFAULT 'active',
    received_by     UUID,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, advance_number)
);

-- ── New Table: advance_adjustments ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS advance_adjustments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    advance_id      UUID NOT NULL REFERENCES patient_advances(id),
    invoice_id      UUID NOT NULL REFERENCES invoices(id),
    amount_adjusted NUMERIC(12,2) NOT NULL,
    adjusted_by     UUID,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── RLS Policies ─────────────────────────────────────────────────────────────

ALTER TABLE corporate_clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_corporate_clients ON corporate_clients
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

ALTER TABLE corporate_enrollments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_corporate_enrollments ON corporate_enrollments
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

ALTER TABLE patient_advances ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_advances ON patient_advances
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

ALTER TABLE advance_adjustments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_advance_adjustments ON advance_adjustments
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ── Triggers ─────────────────────────────────────────────────────────────────

CREATE TRIGGER set_updated_at_corporate_clients
    BEFORE UPDATE ON corporate_clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_patient_advances
    BEFORE UPDATE ON patient_advances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Indexes ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_patient_advances_patient ON patient_advances(tenant_id, patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_advances_status ON patient_advances(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_advance_adjustments_advance ON advance_adjustments(tenant_id, advance_id);
CREATE INDEX IF NOT EXISTS idx_advance_adjustments_invoice ON advance_adjustments(tenant_id, invoice_id);
CREATE INDEX IF NOT EXISTS idx_corporate_enrollments_corporate ON corporate_enrollments(tenant_id, corporate_id);
CREATE INDEX IF NOT EXISTS idx_corporate_enrollments_patient ON corporate_enrollments(tenant_id, patient_id);
CREATE INDEX IF NOT EXISTS idx_invoices_corporate ON invoices(tenant_id, corporate_id) WHERE corporate_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoices_interim ON invoices(tenant_id, encounter_id, is_interim) WHERE is_interim = true;
