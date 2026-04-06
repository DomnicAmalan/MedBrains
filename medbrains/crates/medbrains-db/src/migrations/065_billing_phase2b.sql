-- 065_billing_phase2b.sql — Day Close, Write-Offs, TPA Rate Cards, Audit Log
-- Billing Phase 2b: revenue tracking, reconciliation, NABH-compliant audit trail

-- ═══════════════════════════════════════════════════════════
--  ENUMS
-- ═══════════════════════════════════════════════════════════

CREATE TYPE day_close_status AS ENUM ('open', 'verified', 'discrepancy');

CREATE TYPE write_off_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TYPE audit_action AS ENUM (
    'invoice_created', 'invoice_issued', 'invoice_cancelled',
    'payment_recorded', 'payment_voided',
    'refund_created',
    'discount_applied', 'discount_removed',
    'advance_collected', 'advance_adjusted', 'advance_refunded',
    'credit_note_created', 'credit_note_applied',
    'claim_created', 'claim_updated',
    'day_closed', 'write_off_created', 'write_off_approved',
    'invoice_cloned'
);

-- ═══════════════════════════════════════════════════════════
--  ALTER EXISTING TABLES
-- ═══════════════════════════════════════════════════════════

-- Invoice items: track ordering doctor + department for revenue reporting
ALTER TABLE invoice_items
    ADD COLUMN IF NOT EXISTS ordering_doctor_id UUID REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id);

-- Invoices: ER deferred billing + clone tracking
ALTER TABLE invoices
    ADD COLUMN IF NOT EXISTS is_er_deferred BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS cloned_from_id UUID REFERENCES invoices(id);

-- Insurance claims: secondary claims + TPA rate plan linkage
ALTER TABLE insurance_claims
    ADD COLUMN IF NOT EXISTS is_secondary BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS primary_claim_id UUID REFERENCES insurance_claims(id),
    ADD COLUMN IF NOT EXISTS tpa_rate_plan_id UUID REFERENCES rate_plans(id);

-- Extend charge_source with additional billing sources
ALTER TYPE charge_source ADD VALUE IF NOT EXISTS 'ot';
ALTER TYPE charge_source ADD VALUE IF NOT EXISTS 'emergency';
ALTER TYPE charge_source ADD VALUE IF NOT EXISTS 'diet';
ALTER TYPE charge_source ADD VALUE IF NOT EXISTS 'cssd';

-- ═══════════════════════════════════════════════════════════
--  NEW TABLE: day_end_closes
-- ═══════════════════════════════════════════════════════════

CREATE TABLE day_end_closes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    close_date      DATE NOT NULL,
    cashier_id      UUID NOT NULL REFERENCES users(id),
    expected_cash   NUMERIC(14,2) NOT NULL DEFAULT 0,
    actual_cash     NUMERIC(14,2) NOT NULL DEFAULT 0,
    cash_difference NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_card      NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_upi       NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_cheque    NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_bank_transfer NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_insurance NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_collected NUMERIC(14,2) NOT NULL DEFAULT 0,
    invoices_count  INT NOT NULL DEFAULT 0,
    payments_count  INT NOT NULL DEFAULT 0,
    refunds_total   NUMERIC(14,2) NOT NULL DEFAULT 0,
    advances_total  NUMERIC(14,2) NOT NULL DEFAULT 0,
    status          day_close_status NOT NULL DEFAULT 'open',
    verified_by     UUID REFERENCES users(id),
    verified_at     TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, close_date, cashier_id)
);

ALTER TABLE day_end_closes ENABLE ROW LEVEL SECURITY;
CREATE POLICY day_end_closes_tenant ON day_end_closes
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_day_end_closes_tenant ON day_end_closes (tenant_id);
CREATE INDEX idx_day_end_closes_date ON day_end_closes (tenant_id, close_date);
CREATE TRIGGER trg_day_end_closes_updated_at
    BEFORE UPDATE ON day_end_closes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════
--  NEW TABLE: bad_debt_write_offs
-- ═══════════════════════════════════════════════════════════

CREATE TABLE bad_debt_write_offs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    invoice_id      UUID NOT NULL REFERENCES invoices(id),
    write_off_number TEXT NOT NULL,
    amount          NUMERIC(14,2) NOT NULL,
    reason          TEXT NOT NULL,
    status          write_off_status NOT NULL DEFAULT 'pending',
    requested_by    UUID NOT NULL REFERENCES users(id),
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, write_off_number)
);

ALTER TABLE bad_debt_write_offs ENABLE ROW LEVEL SECURITY;
CREATE POLICY bad_debt_write_offs_tenant ON bad_debt_write_offs
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_bad_debt_write_offs_tenant ON bad_debt_write_offs (tenant_id);
CREATE INDEX idx_bad_debt_write_offs_invoice ON bad_debt_write_offs (tenant_id, invoice_id);
CREATE TRIGGER trg_bad_debt_write_offs_updated_at
    BEFORE UPDATE ON bad_debt_write_offs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════
--  NEW TABLE: billing_audit_log (IMMUTABLE — no update trigger)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE billing_audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    action          audit_action NOT NULL,
    entity_type     TEXT NOT NULL,
    entity_id       UUID NOT NULL,
    invoice_id      UUID REFERENCES invoices(id),
    patient_id      UUID REFERENCES patients(id),
    amount          NUMERIC(14,2),
    previous_state  JSONB,
    new_state       JSONB,
    performed_by    UUID NOT NULL REFERENCES users(id),
    ip_address      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE billing_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY billing_audit_log_tenant ON billing_audit_log
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_billing_audit_log_tenant ON billing_audit_log (tenant_id);
CREATE INDEX idx_billing_audit_log_invoice ON billing_audit_log (tenant_id, invoice_id);
CREATE INDEX idx_billing_audit_log_date ON billing_audit_log (tenant_id, created_at DESC);
-- NO update trigger — this table is append-only

-- ═══════════════════════════════════════════════════════════
--  NEW TABLE: tpa_rate_cards
-- ═══════════════════════════════════════════════════════════

CREATE TABLE tpa_rate_cards (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id          UUID NOT NULL REFERENCES tenants(id),
    tpa_name           TEXT NOT NULL,
    insurance_provider TEXT NOT NULL,
    rate_plan_id       UUID NOT NULL REFERENCES rate_plans(id),
    scheme_type        insurance_scheme_type NOT NULL DEFAULT 'private',
    valid_from         DATE,
    valid_to           DATE,
    is_active          BOOLEAN NOT NULL DEFAULT true,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, tpa_name, insurance_provider)
);

ALTER TABLE tpa_rate_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY tpa_rate_cards_tenant ON tpa_rate_cards
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_tpa_rate_cards_tenant ON tpa_rate_cards (tenant_id);
CREATE TRIGGER trg_tpa_rate_cards_updated_at
    BEFORE UPDATE ON tpa_rate_cards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════
--  SEED SEQUENCE TYPES
-- ═══════════════════════════════════════════════════════════

-- These will be seeded per-tenant by the seed module;
-- add to sequences if tenant already exists
INSERT INTO sequences (tenant_id, seq_type, prefix, pad_width, current_val)
SELECT t.id, 'WRITE_OFF', 'WO', 6, 0
FROM tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM sequences s WHERE s.tenant_id = t.id AND s.seq_type = 'WRITE_OFF'
);

INSERT INTO sequences (tenant_id, seq_type, prefix, pad_width, current_val)
SELECT t.id, 'DAY_CLOSE', 'DC', 6, 0
FROM tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM sequences s WHERE s.tenant_id = t.id AND s.seq_type = 'DAY_CLOSE'
);
