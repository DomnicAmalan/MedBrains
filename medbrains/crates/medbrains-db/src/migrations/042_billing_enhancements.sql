-- Billing enhancements — packages, rate plans, discounts, refunds,
-- credit notes, receipts, and insurance claims.
-- Builds on existing billing tables from migration 002:
--   charge_master, invoices, invoice_items, payments

-- ============================================================
-- 1. Billing Packages — service bundles
-- ============================================================

CREATE TABLE billing_packages (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    code             TEXT NOT NULL,
    name             TEXT NOT NULL,
    description      TEXT,
    total_price      NUMERIC(12,2) NOT NULL,
    discount_percent NUMERIC(4,2) NOT NULL DEFAULT 0,
    is_active        BOOLEAN NOT NULL DEFAULT true,
    valid_from       TIMESTAMPTZ,
    valid_to         TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_billing_packages_tenant ON billing_packages(tenant_id);

-- ============================================================
-- 2. Billing Package Items — items within a package
-- ============================================================

CREATE TABLE billing_package_items (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    package_id  UUID NOT NULL REFERENCES billing_packages(id) ON DELETE CASCADE,
    charge_code TEXT NOT NULL,
    description TEXT NOT NULL,
    quantity    INT NOT NULL DEFAULT 1,
    unit_price  NUMERIC(10,2) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_billing_package_items_package ON billing_package_items(package_id);

-- ============================================================
-- 3. Rate Plans — differential pricing plans
-- ============================================================

CREATE TABLE rate_plans (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    name             TEXT NOT NULL,
    description      TEXT,
    patient_category TEXT,
    is_default       BOOLEAN NOT NULL DEFAULT false,
    is_active        BOOLEAN NOT NULL DEFAULT true,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, name)
);

CREATE INDEX idx_rate_plans_tenant ON rate_plans(tenant_id);

-- ============================================================
-- 4. Rate Plan Items — per-charge overrides within a rate plan
-- ============================================================

CREATE TABLE rate_plan_items (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id          UUID NOT NULL REFERENCES tenants(id),
    rate_plan_id       UUID NOT NULL REFERENCES rate_plans(id) ON DELETE CASCADE,
    charge_code        TEXT NOT NULL,
    override_price     NUMERIC(10,2) NOT NULL,
    override_tax_percent NUMERIC(4,2),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (rate_plan_id, charge_code)
);

CREATE INDEX idx_rate_plan_items_rate_plan ON rate_plan_items(rate_plan_id);

-- ============================================================
-- 5. Invoice Discounts — discounts applied to invoices
-- ============================================================

CREATE TABLE invoice_discounts (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    invoice_id     UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    discount_type  TEXT NOT NULL,
    discount_value NUMERIC(10,2) NOT NULL,
    reason         TEXT,
    approved_by    UUID REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invoice_discounts_invoice ON invoice_discounts(invoice_id);

-- ============================================================
-- 6. Refunds — refund records
-- ============================================================

CREATE TABLE refunds (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    invoice_id       UUID NOT NULL REFERENCES invoices(id),
    payment_id       UUID REFERENCES payments(id),
    refund_number    TEXT NOT NULL,
    amount           NUMERIC(12,2) NOT NULL,
    reason           TEXT NOT NULL,
    mode             payment_mode NOT NULL,
    reference_number TEXT,
    refunded_by      UUID REFERENCES users(id),
    refunded_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, refund_number)
);

CREATE INDEX idx_refunds_tenant ON refunds(tenant_id);
CREATE INDEX idx_refunds_invoice ON refunds(invoice_id);

-- ============================================================
-- 7. Credit Notes
-- ============================================================

CREATE TABLE credit_notes (
    id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id              UUID NOT NULL REFERENCES tenants(id),
    credit_note_number     TEXT NOT NULL,
    invoice_id             UUID NOT NULL REFERENCES invoices(id),
    amount                 NUMERIC(12,2) NOT NULL,
    reason                 TEXT NOT NULL,
    status                 TEXT NOT NULL DEFAULT 'active',
    used_against_invoice_id UUID REFERENCES invoices(id),
    created_by             UUID REFERENCES users(id),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, credit_note_number)
);

CREATE INDEX idx_credit_notes_tenant ON credit_notes(tenant_id);
CREATE INDEX idx_credit_notes_invoice ON credit_notes(invoice_id);

-- ============================================================
-- 8. Receipts — payment receipts
-- ============================================================

CREATE TABLE receipts (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    receipt_number TEXT NOT NULL,
    invoice_id     UUID NOT NULL REFERENCES invoices(id),
    payment_id     UUID NOT NULL REFERENCES payments(id),
    amount         NUMERIC(12,2) NOT NULL,
    receipt_date   TIMESTAMPTZ NOT NULL DEFAULT now(),
    printed_at     TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, receipt_number)
);

CREATE INDEX idx_receipts_tenant ON receipts(tenant_id);
CREATE INDEX idx_receipts_invoice ON receipts(invoice_id);
CREATE INDEX idx_receipts_payment ON receipts(payment_id);

-- ============================================================
-- 9. Insurance Claims — insurance/TPA claim tracking
-- ============================================================

CREATE TABLE insurance_claims (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id          UUID NOT NULL REFERENCES tenants(id),
    invoice_id         UUID NOT NULL REFERENCES invoices(id),
    patient_id         UUID NOT NULL REFERENCES patients(id),
    insurance_provider TEXT NOT NULL,
    policy_number      TEXT,
    claim_number       TEXT,
    claim_type         TEXT NOT NULL DEFAULT 'cashless',
    status             TEXT NOT NULL DEFAULT 'initiated',
    pre_auth_amount    NUMERIC(12,2),
    approved_amount    NUMERIC(12,2),
    settled_amount     NUMERIC(12,2),
    tpa_name           TEXT,
    notes              TEXT,
    submitted_at       TIMESTAMPTZ,
    settled_at         TIMESTAMPTZ,
    created_by         UUID REFERENCES users(id),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_insurance_claims_tenant ON insurance_claims(tenant_id);
CREATE INDEX idx_insurance_claims_invoice ON insurance_claims(invoice_id);
CREATE INDEX idx_insurance_claims_patient ON insurance_claims(patient_id);
CREATE INDEX idx_insurance_claims_status ON insurance_claims(status);

-- ============================================================
-- Row-Level Security
-- ============================================================

ALTER TABLE billing_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_package_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE insurance_claims ENABLE ROW LEVEL SECURITY;

CREATE POLICY billing_packages_tenant_isolation ON billing_packages
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY billing_package_items_tenant_isolation ON billing_package_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY rate_plans_tenant_isolation ON rate_plans
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY rate_plan_items_tenant_isolation ON rate_plan_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY invoice_discounts_tenant_isolation ON invoice_discounts
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY refunds_tenant_isolation ON refunds
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY credit_notes_tenant_isolation ON credit_notes
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY receipts_tenant_isolation ON receipts
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY insurance_claims_tenant_isolation ON insurance_claims
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers (tables with updated_at column)
-- ============================================================

CREATE TRIGGER set_updated_at_billing_packages
    BEFORE UPDATE ON billing_packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_rate_plans
    BEFORE UPDATE ON rate_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_credit_notes
    BEFORE UPDATE ON credit_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_insurance_claims
    BEFORE UPDATE ON insurance_claims
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
