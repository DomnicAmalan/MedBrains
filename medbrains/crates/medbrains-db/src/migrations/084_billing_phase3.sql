-- 084_billing_phase3.sql — Multi-Currency, Credit Patients, Double-Entry Accounting,
--   Bank Reconciliation, TDS, GST Returns, Financial MIS, ERP Export

-- ═══════════════════════════════════════════════════════════════
--  1. ENUMS
-- ═══════════════════════════════════════════════════════════════

CREATE TYPE currency_code AS ENUM (
    'INR', 'USD', 'EUR', 'GBP', 'AED', 'SAR', 'SGD', 'BDT', 'NPR', 'LKR'
);

CREATE TYPE credit_patient_status AS ENUM (
    'active', 'overdue', 'suspended', 'closed'
);

CREATE TYPE journal_entry_type AS ENUM (
    'manual', 'auto_invoice', 'auto_payment', 'auto_refund', 'auto_write_off', 'auto_advance'
);

CREATE TYPE journal_entry_status AS ENUM (
    'draft', 'posted', 'reversed'
);

CREATE TYPE recon_status AS ENUM (
    'unmatched', 'matched', 'discrepancy', 'excluded'
);

CREATE TYPE gstr_filing_status AS ENUM (
    'draft', 'validated', 'filed', 'accepted', 'error'
);

CREATE TYPE tds_status AS ENUM (
    'deducted', 'deposited', 'certificate_issued'
);

CREATE TYPE erp_export_status AS ENUM (
    'pending', 'exported', 'failed', 'acknowledged'
);

-- Extend audit_action with new values
ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'journal_entry_posted';
ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'tds_deducted';
ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'bank_reconciled';
ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'gstr_filed';
ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'threshold_alert';
ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'erp_exported';

-- Extend charge_source with OT
ALTER TYPE charge_source ADD VALUE IF NOT EXISTS 'ot';

-- ═══════════════════════════════════════════════════════════════
--  2. ALTER EXISTING TABLES
-- ═══════════════════════════════════════════════════════════════

-- Multi-currency support on invoices
ALTER TABLE invoices
    ADD COLUMN IF NOT EXISTS currency currency_code NOT NULL DEFAULT 'INR',
    ADD COLUMN IF NOT EXISTS exchange_rate NUMERIC(10,4) NOT NULL DEFAULT 1.0,
    ADD COLUMN IF NOT EXISTS base_total_amount NUMERIC(12,2);

-- Insurance claims — reimbursement + dual insurance
ALTER TABLE insurance_claims
    ADD COLUMN IF NOT EXISTS reimbursement_docs JSONB DEFAULT '[]',
    ADD COLUMN IF NOT EXISTS claim_amount NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS secondary_payout NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS coordination_of_benefits TEXT;

-- ═══════════════════════════════════════════════════════════════
--  3. NEW TABLES
-- ═══════════════════════════════════════════════════════════════

-- 3a. Exchange rates (immutable)
CREATE TABLE exchange_rates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    from_currency   currency_code NOT NULL,
    to_currency     currency_code NOT NULL DEFAULT 'INR',
    rate            NUMERIC(12,6) NOT NULL,
    effective_date  DATE NOT NULL,
    source          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, from_currency, to_currency, effective_date)
);

-- 3b. Credit patients
CREATE TABLE credit_patients (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    credit_limit    NUMERIC(12,2) NOT NULL DEFAULT 0,
    current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
    status          credit_patient_status NOT NULL DEFAULT 'active',
    approved_by     UUID REFERENCES users(id),
    overdue_since   TIMESTAMPTZ,
    reason          TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, patient_id)
);

-- 3c. GL Chart of Accounts (hierarchical)
CREATE TABLE gl_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    account_type    TEXT NOT NULL CHECK (account_type IN (
        'asset', 'liability', 'equity', 'revenue', 'expense'
    )),
    parent_id       UUID REFERENCES gl_accounts(id),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    description     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

-- 3d. Journal entry headers
CREATE TABLE journal_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    entry_number    TEXT NOT NULL,
    entry_date      DATE NOT NULL,
    entry_type      journal_entry_type NOT NULL DEFAULT 'manual',
    status          journal_entry_status NOT NULL DEFAULT 'draft',
    total_debit     NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_credit    NUMERIC(14,2) NOT NULL DEFAULT 0,
    description     TEXT,
    reference_type  TEXT,
    reference_id    UUID,
    posted_by       UUID REFERENCES users(id),
    posted_at       TIMESTAMPTZ,
    reversal_of_id  UUID REFERENCES journal_entries(id),
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, entry_number)
);

-- 3e. Journal entry lines (immutable once posted)
CREATE TABLE journal_entry_lines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id      UUID NOT NULL REFERENCES gl_accounts(id),
    department_id   UUID REFERENCES departments(id),
    debit_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
    credit_amount   NUMERIC(14,2) NOT NULL DEFAULT 0,
    narration       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3f. Bank transactions (imported statements)
CREATE TABLE bank_transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    bank_name       TEXT NOT NULL,
    account_number  TEXT NOT NULL,
    transaction_date DATE NOT NULL,
    value_date      DATE,
    description     TEXT,
    debit_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
    credit_amount   NUMERIC(12,2) NOT NULL DEFAULT 0,
    running_balance NUMERIC(14,2),
    reference_number TEXT,
    recon_status    recon_status NOT NULL DEFAULT 'unmatched',
    matched_payment_id UUID REFERENCES payments(id),
    matched_refund_id UUID REFERENCES refunds(id),
    import_batch    TEXT,
    matched_by      UUID REFERENCES users(id),
    matched_at      TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3g. TDS deductions
CREATE TABLE tds_deductions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    invoice_id      UUID REFERENCES invoices(id),
    deductee_name   TEXT NOT NULL,
    deductee_pan    TEXT NOT NULL,
    tds_section     TEXT NOT NULL,
    tds_rate        NUMERIC(5,2) NOT NULL,
    base_amount     NUMERIC(12,2) NOT NULL,
    tds_amount      NUMERIC(12,2) NOT NULL,
    status          tds_status NOT NULL DEFAULT 'deducted',
    deducted_date   DATE NOT NULL,
    challan_number  TEXT,
    challan_date    DATE,
    certificate_number TEXT,
    certificate_date DATE,
    financial_year  TEXT NOT NULL,
    quarter         TEXT NOT NULL CHECK (quarter IN ('Q1', 'Q2', 'Q3', 'Q4')),
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3h. GST return summaries
CREATE TABLE gst_return_summaries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    return_type     TEXT NOT NULL CHECK (return_type IN ('GSTR-1', 'GSTR-2B', 'GSTR-3B')),
    period          TEXT NOT NULL,
    filing_status   gstr_filing_status NOT NULL DEFAULT 'draft',
    total_taxable   NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_cgst      NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_sgst      NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_igst      NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_cess      NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_tax       NUMERIC(14,2) NOT NULL DEFAULT 0,
    hsn_summary     JSONB DEFAULT '[]',
    invoice_count   INT NOT NULL DEFAULT 0,
    arn             TEXT,
    filed_by        UUID REFERENCES users(id),
    filed_at        TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, return_type, period)
);

-- 3i. ERP export log (immutable)
CREATE TABLE erp_export_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    target_system   TEXT NOT NULL,
    export_type     TEXT NOT NULL,
    record_ids      UUID[] NOT NULL DEFAULT '{}',
    date_from       DATE,
    date_to         DATE,
    status          erp_export_status NOT NULL DEFAULT 'pending',
    payload         JSONB,
    response        JSONB,
    error_message   TEXT,
    exported_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════
--  4. RLS POLICIES
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;
CREATE POLICY exchange_rates_tenant ON exchange_rates
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE credit_patients ENABLE ROW LEVEL SECURITY;
CREATE POLICY credit_patients_tenant ON credit_patients
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE gl_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY gl_accounts_tenant ON gl_accounts
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY journal_entries_tenant ON journal_entries
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE journal_entry_lines ENABLE ROW LEVEL SECURITY;
CREATE POLICY journal_entry_lines_tenant ON journal_entry_lines
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY bank_transactions_tenant ON bank_transactions
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE tds_deductions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tds_deductions_tenant ON tds_deductions
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE gst_return_summaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY gst_return_summaries_tenant ON gst_return_summaries
    USING (tenant_id::text = current_setting('app.tenant_id', true));

ALTER TABLE erp_export_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY erp_export_log_tenant ON erp_export_log
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ═══════════════════════════════════════════════════════════════
--  5. INDEXES
-- ═══════════════════════════════════════════════════════════════

CREATE INDEX idx_exchange_rates_tenant ON exchange_rates (tenant_id);
CREATE INDEX idx_exchange_rates_lookup ON exchange_rates (tenant_id, from_currency, to_currency, effective_date DESC);

CREATE INDEX idx_credit_patients_tenant ON credit_patients (tenant_id);
CREATE INDEX idx_credit_patients_status ON credit_patients (tenant_id, status);

CREATE INDEX idx_gl_accounts_tenant ON gl_accounts (tenant_id);
CREATE INDEX idx_gl_accounts_type ON gl_accounts (tenant_id, account_type);

CREATE INDEX idx_journal_entries_tenant ON journal_entries (tenant_id);
CREATE INDEX idx_journal_entries_date ON journal_entries (tenant_id, entry_date);
CREATE INDEX idx_journal_entries_status ON journal_entries (tenant_id, status);

CREATE INDEX idx_journal_entry_lines_entry ON journal_entry_lines (journal_entry_id);
CREATE INDEX idx_journal_entry_lines_account ON journal_entry_lines (account_id);

CREATE INDEX idx_bank_transactions_tenant ON bank_transactions (tenant_id);
CREATE INDEX idx_bank_transactions_recon ON bank_transactions (tenant_id, recon_status);
CREATE INDEX idx_bank_transactions_date ON bank_transactions (tenant_id, transaction_date);

CREATE INDEX idx_tds_deductions_tenant ON tds_deductions (tenant_id);
CREATE INDEX idx_tds_deductions_fy ON tds_deductions (tenant_id, financial_year, quarter);

CREATE INDEX idx_gst_return_summaries_tenant ON gst_return_summaries (tenant_id);

CREATE INDEX idx_erp_export_log_tenant ON erp_export_log (tenant_id);

-- ═══════════════════════════════════════════════════════════════
--  6. TRIGGERS (mutable tables only)
-- ═══════════════════════════════════════════════════════════════

CREATE TRIGGER trg_credit_patients_updated_at
    BEFORE UPDATE ON credit_patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_gl_accounts_updated_at
    BEFORE UPDATE ON gl_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_journal_entries_updated_at
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_bank_transactions_updated_at
    BEFORE UPDATE ON bank_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_tds_deductions_updated_at
    BEFORE UPDATE ON tds_deductions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_gst_return_summaries_updated_at
    BEFORE UPDATE ON gst_return_summaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════════
--  7. SEED SEQUENCES for existing tenants
-- ═══════════════════════════════════════════════════════════════

INSERT INTO sequences (tenant_id, seq_type, prefix, pad_width, current_val)
SELECT t.id, 'JOURNAL_ENTRY', 'JE', 6, 0
FROM tenants t
WHERE NOT EXISTS (
    SELECT 1 FROM sequences s WHERE s.tenant_id = t.id AND s.seq_type = 'JOURNAL_ENTRY'
);
