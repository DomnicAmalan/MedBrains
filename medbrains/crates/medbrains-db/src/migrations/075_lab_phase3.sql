-- Migration 075: Lab Phase 3
-- Sample management, specialized reporting, enhanced QC/NABL, B2B foundation,
-- report dispatch/templates, STAT monitoring, EQAS/proficiency testing

-- ══════════════════════════════════════════════════════════
--  ENUMS
-- ══════════════════════════════════════════════════════════

CREATE TYPE lab_home_collection_status AS ENUM (
    'scheduled', 'assigned', 'in_transit', 'arrived',
    'collected', 'returned_to_lab', 'cancelled'
);

CREATE TYPE lab_collection_center_type AS ENUM (
    'hospital', 'satellite', 'partner', 'camp'
);

CREATE TYPE lab_sample_archive_status AS ENUM (
    'stored', 'retrieved', 'discarded', 'expired'
);

CREATE TYPE lab_dispatch_method AS ENUM (
    'counter', 'email', 'sms', 'whatsapp', 'portal', 'courier'
);

CREATE TYPE lab_eqas_evaluation AS ENUM (
    'acceptable', 'marginal', 'unacceptable', 'pending'
);

-- ══════════════════════════════════════════════════════════
--  A. SAMPLE MANAGEMENT
-- ══════════════════════════════════════════════════════════

-- A1. Home collections
CREATE TABLE lab_home_collections (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES lab_orders(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    scheduled_date  DATE NOT NULL,
    scheduled_time_slot VARCHAR(50),
    address_line    TEXT NOT NULL,
    city            VARCHAR(100),
    pincode         VARCHAR(20),
    contact_phone   VARCHAR(20),
    assigned_phlebotomist UUID REFERENCES users(id),
    status          lab_home_collection_status NOT NULL DEFAULT 'scheduled',
    special_instructions TEXT,
    collected_at    TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_lab_home_collections_updated
    BEFORE UPDATE ON lab_home_collections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_home_collections ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_home_collections_tenant ON lab_home_collections
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_home_collections_tenant_status
    ON lab_home_collections (tenant_id, status);
CREATE INDEX idx_lab_home_collections_date
    ON lab_home_collections (tenant_id, scheduled_date);

-- A2. Collection centers
CREATE TABLE lab_collection_centers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            VARCHAR(50) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    center_type     lab_collection_center_type NOT NULL DEFAULT 'hospital',
    address         TEXT,
    city            VARCHAR(100),
    phone           VARCHAR(20),
    contact_person  VARCHAR(200),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    operating_hours JSONB,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE TRIGGER trg_lab_collection_centers_updated
    BEFORE UPDATE ON lab_collection_centers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_collection_centers ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_collection_centers_tenant ON lab_collection_centers
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- A3. Sample archive
CREATE TABLE lab_sample_archive (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES lab_orders(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    sample_barcode  VARCHAR(100),
    storage_location VARCHAR(200),
    stored_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_by     UUID NOT NULL REFERENCES users(id),
    status          lab_sample_archive_status NOT NULL DEFAULT 'stored',
    retrieved_at    TIMESTAMPTZ,
    retrieved_by    UUID REFERENCES users(id),
    disposal_date   DATE,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_sample_archive ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_sample_archive_tenant ON lab_sample_archive
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_sample_archive_tenant_status
    ON lab_sample_archive (tenant_id, status);
CREATE INDEX idx_lab_sample_archive_barcode
    ON lab_sample_archive (tenant_id, sample_barcode);

-- ══════════════════════════════════════════════════════════
--  B. REPORTING
-- ══════════════════════════════════════════════════════════

-- B1. Report dispatches
CREATE TABLE lab_report_dispatches (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES lab_orders(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    dispatch_method lab_dispatch_method NOT NULL,
    dispatched_to   TEXT,
    dispatched_by   UUID NOT NULL REFERENCES users(id),
    dispatched_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    received_confirmation BOOLEAN NOT NULL DEFAULT false,
    confirmed_at    TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_report_dispatches ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_report_dispatches_tenant ON lab_report_dispatches
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_report_dispatches_order
    ON lab_report_dispatches (tenant_id, order_id);

-- B2. Report templates
CREATE TABLE lab_report_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    department_id   UUID REFERENCES departments(id),
    template_name   VARCHAR(200) NOT NULL,
    header_html     TEXT,
    footer_html     TEXT,
    logo_url        TEXT,
    report_format   JSONB,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, department_id, template_name)
);

CREATE TRIGGER trg_lab_report_templates_updated
    BEFORE UPDATE ON lab_report_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_report_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_report_templates_tenant ON lab_report_templates
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ══════════════════════════════════════════════════════════
--  C. QC & NABL
-- ══════════════════════════════════════════════════════════

-- C1. EQAS results
CREATE TABLE lab_eqas_results (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    program_name    VARCHAR(200) NOT NULL,
    provider        VARCHAR(200),
    test_id         UUID NOT NULL REFERENCES lab_test_catalog(id),
    cycle           VARCHAR(50),
    sample_number   VARCHAR(50),
    expected_value  NUMERIC(12,4),
    reported_value  NUMERIC(12,4),
    evaluation      lab_eqas_evaluation NOT NULL DEFAULT 'pending',
    bias_percent    NUMERIC(8,2),
    z_score         NUMERIC(6,2),
    report_date     DATE,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_lab_eqas_results_updated
    BEFORE UPDATE ON lab_eqas_results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_eqas_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_eqas_results_tenant ON lab_eqas_results
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_eqas_test_cycle
    ON lab_eqas_results (tenant_id, test_id, cycle);

-- C2. Proficiency tests
CREATE TABLE lab_proficiency_tests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    program         VARCHAR(200) NOT NULL,
    test_id         UUID NOT NULL REFERENCES lab_test_catalog(id),
    survey_round    VARCHAR(50),
    sample_id       VARCHAR(50),
    assigned_value  NUMERIC(12,4),
    reported_value  NUMERIC(12,4),
    acceptable_range_low  NUMERIC(12,4),
    acceptable_range_high NUMERIC(12,4),
    is_acceptable   BOOLEAN,
    evaluation_date DATE,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_proficiency_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_proficiency_tests_tenant ON lab_proficiency_tests
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_proficiency_test
    ON lab_proficiency_tests (tenant_id, test_id);

-- C3. NABL documents
CREATE TABLE lab_nabl_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    document_type   VARCHAR(100) NOT NULL,
    document_number VARCHAR(100) NOT NULL,
    title           VARCHAR(500) NOT NULL,
    version         VARCHAR(20),
    effective_date  DATE,
    review_date     DATE,
    approved_by     UUID REFERENCES users(id),
    file_path       TEXT,
    is_current      BOOLEAN NOT NULL DEFAULT true,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, document_number, version)
);

CREATE TRIGGER trg_lab_nabl_documents_updated
    BEFORE UPDATE ON lab_nabl_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_nabl_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_nabl_documents_tenant ON lab_nabl_documents
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_nabl_documents_current
    ON lab_nabl_documents (tenant_id, is_current);

-- ══════════════════════════════════════════════════════════
--  D. SPECIALIZED REPORTING
-- ══════════════════════════════════════════════════════════

-- D1. Histopathology reports
CREATE TABLE lab_histopath_reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES lab_orders(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    specimen_type   VARCHAR(200),
    clinical_history TEXT,
    gross_description TEXT,
    microscopy_findings TEXT,
    special_stains  JSONB,
    immunohistochemistry JSONB,
    synoptic_data   JSONB,
    diagnosis       TEXT,
    icd_code        VARCHAR(20),
    pathologist_id  UUID REFERENCES users(id),
    reported_at     TIMESTAMPTZ,
    notes           TEXT,
    turnaround_days INT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_lab_histopath_reports_updated
    BEFORE UPDATE ON lab_histopath_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_histopath_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_histopath_reports_tenant ON lab_histopath_reports
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_histopath_order
    ON lab_histopath_reports (tenant_id, order_id);

-- D2. Cytology reports
CREATE TABLE lab_cytology_reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES lab_orders(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    specimen_type   VARCHAR(100),
    clinical_indication TEXT,
    adequacy        VARCHAR(100),
    screening_findings TEXT,
    diagnosis       TEXT,
    bethesda_category VARCHAR(100),
    cytopathologist_id UUID REFERENCES users(id),
    reported_at     TIMESTAMPTZ,
    icd_code        VARCHAR(20),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_lab_cytology_reports_updated
    BEFORE UPDATE ON lab_cytology_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_cytology_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_cytology_reports_tenant ON lab_cytology_reports
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_cytology_order
    ON lab_cytology_reports (tenant_id, order_id);

-- D3. Molecular / PCR reports
CREATE TABLE lab_molecular_reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES lab_orders(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    test_method     VARCHAR(100),
    target_gene     VARCHAR(200),
    primer_details  TEXT,
    amplification_data JSONB,
    ct_value        NUMERIC(8,2),
    result_interpretation VARCHAR(200),
    quantitative_value NUMERIC(15,4),
    quantitative_unit VARCHAR(50),
    kit_name        VARCHAR(200),
    kit_lot         VARCHAR(100),
    performed_by    UUID REFERENCES users(id),
    reported_at     TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_lab_molecular_reports_updated
    BEFORE UPDATE ON lab_molecular_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_molecular_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_molecular_reports_tenant ON lab_molecular_reports
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_molecular_order
    ON lab_molecular_reports (tenant_id, order_id);

-- ══════════════════════════════════════════════════════════
--  E. B2B
-- ══════════════════════════════════════════════════════════

-- E1. B2B clients
CREATE TABLE lab_b2b_clients (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            VARCHAR(50) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    client_type     VARCHAR(50),
    address         TEXT,
    city            VARCHAR(100),
    phone           VARCHAR(20),
    email           VARCHAR(200),
    contact_person  VARCHAR(200),
    credit_limit    NUMERIC(12,2),
    payment_terms_days INT NOT NULL DEFAULT 30,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE TRIGGER trg_lab_b2b_clients_updated
    BEFORE UPDATE ON lab_b2b_clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_b2b_clients ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_b2b_clients_tenant ON lab_b2b_clients
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- E2. B2B rates
CREATE TABLE lab_b2b_rates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    client_id       UUID NOT NULL REFERENCES lab_b2b_clients(id),
    test_id         UUID NOT NULL REFERENCES lab_test_catalog(id),
    agreed_price    NUMERIC(10,2),
    discount_percent NUMERIC(5,2),
    effective_from  DATE,
    effective_to    DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, client_id, test_id)
);

CREATE TRIGGER trg_lab_b2b_rates_updated
    BEFORE UPDATE ON lab_b2b_rates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lab_b2b_rates ENABLE ROW LEVEL SECURITY;
CREATE POLICY lab_b2b_rates_tenant ON lab_b2b_rates
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_lab_b2b_rates_client
    ON lab_b2b_rates (tenant_id, client_id);

-- ══════════════════════════════════════════════════════════
--  ALTER TABLES
-- ══════════════════════════════════════════════════════════

ALTER TABLE lab_reagent_lots
    ADD COLUMN IF NOT EXISTS reorder_level NUMERIC(10,2),
    ADD COLUMN IF NOT EXISTS consumption_per_test NUMERIC(10,4);

ALTER TABLE lab_orders
    ADD COLUMN IF NOT EXISTS is_stat BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS collection_center_id UUID REFERENCES lab_collection_centers(id);
