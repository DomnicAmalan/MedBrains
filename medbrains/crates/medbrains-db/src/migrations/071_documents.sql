-- Migration 071: Printing, Forms & Document Output Module
-- Central document template + output tracking system for all printable outputs

-- ══════════════════════════════════════════════════════════
--  ENUMS
-- ══════════════════════════════════════════════════════════

CREATE TYPE document_template_category AS ENUM (
    'prescription',
    'consultation_summary',
    'discharge_summary',
    'death_certificate',
    'consent_form',
    'lab_report',
    'radiology_report',
    'opd_bill',
    'ipd_bill',
    'receipt',
    'case_sheet_cover',
    'progress_note',
    'nursing_assessment',
    'mar_chart',
    'vitals_chart',
    'surgical_checklist',
    'anesthesia_record',
    'operation_note',
    'employee_id_card',
    'purchase_order',
    'patient_card',
    'wristband',
    'queue_token',
    'bmw_manifest',
    'pcpndt_form_f',
    'mlc_certificate',
    'referral_letter',
    'medical_certificate',
    'fitness_certificate',
    'blood_requisition',
    'diet_chart',
    'investigation_report',
    'transfer_summary',
    'admission_form',
    'against_medical_advice',
    'medico_legal_report',
    'birth_certificate',
    'duty_roster',
    'indent_form',
    'grn_form',
    'custom'
);

CREATE TYPE document_output_status AS ENUM (
    'draft',
    'generated',
    'printed',
    'downloaded',
    'voided',
    'superseded'
);

CREATE TYPE print_format AS ENUM (
    'a4_portrait',
    'a4_landscape',
    'a5_portrait',
    'a5_landscape',
    'thermal_80mm',
    'thermal_58mm',
    'label_50x25mm',
    'wristband',
    'custom'
);

CREATE TYPE watermark_type AS ENUM (
    'none',
    'draft',
    'confidential',
    'copy',
    'duplicate',
    'uncontrolled',
    'sample',
    'cancelled'
);

CREATE TYPE print_job_status AS ENUM (
    'queued',
    'printing',
    'completed',
    'failed',
    'cancelled'
);

-- ══════════════════════════════════════════════════════════
--  TABLES
-- ══════════════════════════════════════════════════════════

-- 1. Document Templates
CREATE TABLE document_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),

    -- Identity
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    category        document_template_category NOT NULL DEFAULT 'custom',
    module_code     TEXT,
    description     TEXT,

    -- Versioning
    version         INT NOT NULL DEFAULT 1,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    is_default      BOOLEAN NOT NULL DEFAULT false,

    -- Layout
    print_format    print_format NOT NULL DEFAULT 'a4_portrait',
    header_layout   JSONB,
    body_layout     JSONB,
    footer_layout   JSONB,

    -- Branding
    show_logo       BOOLEAN NOT NULL DEFAULT true,
    logo_position   TEXT DEFAULT 'left',
    show_hospital_name BOOLEAN NOT NULL DEFAULT true,
    show_hospital_address BOOLEAN NOT NULL DEFAULT true,
    show_hospital_phone BOOLEAN NOT NULL DEFAULT true,
    show_registration_no BOOLEAN NOT NULL DEFAULT false,
    show_accreditation BOOLEAN NOT NULL DEFAULT false,

    -- Typography
    font_family     TEXT DEFAULT 'Arial',
    font_size_pt    INT DEFAULT 10,

    -- Margins (mm)
    margin_top_mm   INT DEFAULT 15,
    margin_bottom_mm INT DEFAULT 15,
    margin_left_mm  INT DEFAULT 15,
    margin_right_mm INT DEFAULT 15,

    -- Features
    show_page_numbers BOOLEAN NOT NULL DEFAULT true,
    show_print_metadata BOOLEAN NOT NULL DEFAULT true,
    show_qr_code    BOOLEAN NOT NULL DEFAULT false,
    default_watermark watermark_type NOT NULL DEFAULT 'none',
    signature_blocks JSONB,
    required_context TEXT[],

    -- Audit
    created_by      UUID REFERENCES users(id),
    updated_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tenant_id, code)
);

ALTER TABLE document_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY document_templates_tenant ON document_templates
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_document_templates_updated_at
    BEFORE UPDATE ON document_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. Document Template Versions
CREATE TABLE document_template_versions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    template_id     UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
    version_number  INT NOT NULL,
    snapshot        JSONB NOT NULL,
    change_summary  TEXT,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (template_id, version_number)
);

ALTER TABLE document_template_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY document_template_versions_tenant ON document_template_versions
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- 3. Document Outputs
CREATE TABLE document_outputs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),

    -- Template link
    template_id     UUID REFERENCES document_templates(id),
    template_version INT,

    -- Source reference
    module_code     TEXT,
    source_table    TEXT,
    source_id       UUID,

    -- Patient context (nullable for non-patient docs)
    patient_id      UUID REFERENCES patients(id),
    visit_id        UUID,
    admission_id    UUID,

    -- Document metadata
    document_number TEXT NOT NULL,
    title           TEXT NOT NULL,
    category        document_template_category NOT NULL DEFAULT 'custom',
    status          document_output_status NOT NULL DEFAULT 'generated',

    -- File
    file_url        TEXT,
    file_size_bytes BIGINT,
    mime_type       TEXT DEFAULT 'text/html',
    page_count      INT,

    -- Print tracking
    print_count     INT NOT NULL DEFAULT 0,
    first_printed_at TIMESTAMPTZ,
    last_printed_at TIMESTAMPTZ,

    -- Features
    watermark       watermark_type NOT NULL DEFAULT 'none',
    language_code   TEXT DEFAULT 'en',
    context_snapshot JSONB,
    qr_code_data    TEXT,
    document_hash   TEXT,

    -- Audit
    generated_by    UUID REFERENCES users(id),
    voided_by       UUID REFERENCES users(id),
    voided_at       TIMESTAMPTZ,
    voided_reason   TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE document_outputs ENABLE ROW LEVEL SECURITY;
CREATE POLICY document_outputs_tenant ON document_outputs
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_document_outputs_updated_at
    BEFORE UPDATE ON document_outputs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_document_outputs_patient ON document_outputs(tenant_id, patient_id) WHERE patient_id IS NOT NULL;
CREATE INDEX idx_document_outputs_category ON document_outputs(tenant_id, category);
CREATE INDEX idx_document_outputs_module ON document_outputs(tenant_id, module_code);
CREATE INDEX idx_document_outputs_source ON document_outputs(tenant_id, source_table, source_id);
CREATE INDEX idx_document_outputs_doc_number ON document_outputs(tenant_id, document_number);

-- 4. Document Output Signatures
CREATE TABLE document_output_signatures (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    document_output_id  UUID NOT NULL REFERENCES document_outputs(id) ON DELETE CASCADE,

    signer_role         TEXT NOT NULL,
    signer_name         TEXT,
    designation         TEXT,
    registration_number TEXT,

    signature_type      signature_type NOT NULL DEFAULT 'pen_on_paper',
    signature_image_url TEXT,
    biometric_hash      TEXT,
    aadhaar_ref         TEXT,
    thumb_impression    BOOLEAN NOT NULL DEFAULT false,

    signed_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    captured_by         UUID REFERENCES users(id),

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE document_output_signatures ENABLE ROW LEVEL SECURITY;
CREATE POLICY document_output_signatures_tenant ON document_output_signatures
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE INDEX idx_doc_output_sigs_doc ON document_output_signatures(document_output_id);

-- 5. Document Form Review Schedule (NABH annual review tracking)
CREATE TABLE document_form_review_schedule (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    template_id         UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
    review_cycle_months INT NOT NULL DEFAULT 12,
    last_reviewed_at    TIMESTAMPTZ,
    last_reviewed_by    UUID REFERENCES users(id),
    next_review_due     DATE,
    review_status       TEXT DEFAULT 'pending',
    notes               TEXT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (tenant_id, template_id)
);

ALTER TABLE document_form_review_schedule ENABLE ROW LEVEL SECURITY;
CREATE POLICY document_form_review_schedule_tenant ON document_form_review_schedule
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_document_form_review_schedule_updated_at
    BEFORE UPDATE ON document_form_review_schedule
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 6. Printer Configs (Phase 2)
CREATE TABLE printer_configs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            TEXT NOT NULL,
    printer_type    TEXT NOT NULL DEFAULT 'laser',
    connection_type TEXT DEFAULT 'network',
    connection_string TEXT,
    department_id   UUID REFERENCES departments(id),
    default_format  print_format NOT NULL DEFAULT 'a4_portrait',
    capabilities    JSONB,
    is_active       BOOLEAN NOT NULL DEFAULT true,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE printer_configs ENABLE ROW LEVEL SECURITY;
CREATE POLICY printer_configs_tenant ON printer_configs
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_printer_configs_updated_at
    BEFORE UPDATE ON printer_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 7. Print Jobs (Phase 2)
CREATE TABLE print_jobs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    document_output_id  UUID NOT NULL REFERENCES document_outputs(id),
    printer_id          UUID REFERENCES printer_configs(id),
    status              print_job_status NOT NULL DEFAULT 'queued',
    copies              INT NOT NULL DEFAULT 1,
    priority            INT NOT NULL DEFAULT 0,
    department_id       UUID REFERENCES departments(id),
    submitted_by        UUID REFERENCES users(id),
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    error_message       TEXT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE print_jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY print_jobs_tenant ON print_jobs
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

CREATE TRIGGER trg_print_jobs_updated_at
    BEFORE UPDATE ON print_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_print_jobs_status ON print_jobs(tenant_id, status);
CREATE INDEX idx_print_jobs_printer ON print_jobs(printer_id, status);
