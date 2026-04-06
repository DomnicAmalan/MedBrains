-- 072_regulatory.sql
-- Regulatory & Compliance module — centralized compliance management
-- PCPNDT Form F, ADR reporting (PvPI), Materiovigilance (CDSCO),
-- department-wise checklists, compliance calendar

-- ══════════════════════════════════════════════════════════
--  ENUMS
-- ══════════════════════════════════════════════════════════

CREATE TYPE compliance_checklist_status AS ENUM (
    'not_started',
    'in_progress',
    'compliant',
    'non_compliant',
    'not_applicable'
);

CREATE TYPE adverse_event_severity AS ENUM (
    'mild',
    'moderate',
    'severe',
    'fatal'
);

CREATE TYPE adverse_event_status AS ENUM (
    'draft',
    'submitted',
    'under_review',
    'closed',
    'withdrawn'
);

CREATE TYPE pcpndt_form_status AS ENUM (
    'draft',
    'submitted',
    'registered',
    'expired'
);

-- ══════════════════════════════════════════════════════════
--  TABLES
-- ══════════════════════════════════════════════════════════

-- ── 1. compliance_checklists ─────────────────────────────

CREATE TABLE compliance_checklists (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    department_id           UUID REFERENCES departments(id),
    accreditation_body      accreditation_body NOT NULL,
    standard_code           TEXT NOT NULL,
    name                    TEXT NOT NULL,
    description             TEXT,
    assessment_period_start DATE NOT NULL,
    assessment_period_end   DATE NOT NULL,
    overall_status          compliance_checklist_status NOT NULL DEFAULT 'not_started',
    compliance_score        NUMERIC(5,2),
    total_items             INT NOT NULL DEFAULT 0,
    compliant_items         INT NOT NULL DEFAULT 0,
    non_compliant_items     INT NOT NULL DEFAULT 0,
    assessed_by             UUID REFERENCES users(id),
    assessed_at             TIMESTAMPTZ,
    next_review_date        DATE,
    notes                   TEXT,
    created_by              UUID NOT NULL REFERENCES users(id),
    updated_by              UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, department_id, accreditation_body, standard_code, assessment_period_start)
);

ALTER TABLE compliance_checklists ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON compliance_checklists
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_compliance_checklists
    BEFORE UPDATE ON compliance_checklists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_compliance_checklists_tenant ON compliance_checklists(tenant_id);
CREATE INDEX idx_compliance_checklists_dept ON compliance_checklists(tenant_id, department_id);
CREATE INDEX idx_compliance_checklists_body ON compliance_checklists(tenant_id, accreditation_body);
CREATE INDEX idx_compliance_checklists_status ON compliance_checklists(tenant_id, overall_status);

-- ── 2. compliance_checklist_items ────────────────────────

CREATE TABLE compliance_checklist_items (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    checklist_id        UUID NOT NULL REFERENCES compliance_checklists(id) ON DELETE CASCADE,
    item_number         INT NOT NULL,
    criterion           TEXT NOT NULL,
    status              compliance_checklist_status NOT NULL DEFAULT 'not_started',
    evidence_summary    TEXT,
    evidence_documents  JSONB NOT NULL DEFAULT '[]',
    gap_description     TEXT,
    corrective_action   TEXT,
    target_date         DATE,
    responsible_user_id UUID REFERENCES users(id),
    verified_by         UUID REFERENCES users(id),
    verified_at         TIMESTAMPTZ,
    created_by          UUID NOT NULL REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE compliance_checklist_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON compliance_checklist_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_compliance_checklist_items
    BEFORE UPDATE ON compliance_checklist_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_checklist_items_checklist ON compliance_checklist_items(checklist_id);
CREATE INDEX idx_checklist_items_status ON compliance_checklist_items(tenant_id, status);

-- ── 3. adr_reports ───────────────────────────────────────

CREATE TABLE adr_reports (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    report_number           TEXT NOT NULL,
    patient_id              UUID REFERENCES patients(id),
    reporter_id             UUID NOT NULL REFERENCES users(id),
    reporter_type           TEXT NOT NULL DEFAULT 'doctor',
    drug_name               TEXT NOT NULL,
    drug_generic_name       TEXT,
    drug_batch_number       TEXT,
    manufacturer            TEXT,
    reaction_description    TEXT NOT NULL,
    onset_date              DATE,
    reaction_date           DATE NOT NULL,
    severity                adverse_event_severity NOT NULL,
    outcome                 TEXT,
    causality_assessment    TEXT,
    status                  adverse_event_status NOT NULL DEFAULT 'draft',
    seriousness_criteria    JSONB NOT NULL DEFAULT '[]',
    dechallenge             TEXT,
    rechallenge             TEXT,
    concomitant_drugs       JSONB NOT NULL DEFAULT '[]',
    relevant_history        TEXT,
    submitted_to_pvpi       BOOLEAN NOT NULL DEFAULT false,
    pvpi_reference          TEXT,
    submitted_at            TIMESTAMPTZ,
    created_by              UUID NOT NULL REFERENCES users(id),
    updated_by              UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, report_number)
);

ALTER TABLE adr_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON adr_reports
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_adr_reports
    BEFORE UPDATE ON adr_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_adr_reports_tenant ON adr_reports(tenant_id);
CREATE INDEX idx_adr_reports_patient ON adr_reports(tenant_id, patient_id);
CREATE INDEX idx_adr_reports_status ON adr_reports(tenant_id, status);
CREATE INDEX idx_adr_reports_severity ON adr_reports(tenant_id, severity);

-- ── 4. materiovigilance_reports ──────────────────────────

CREATE TABLE materiovigilance_reports (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    report_number           TEXT NOT NULL,
    patient_id              UUID REFERENCES patients(id),
    reporter_id             UUID NOT NULL REFERENCES users(id),
    device_name             TEXT NOT NULL,
    device_manufacturer     TEXT,
    device_model            TEXT,
    device_batch            TEXT,
    event_description       TEXT NOT NULL,
    event_date              DATE NOT NULL,
    severity                adverse_event_severity NOT NULL,
    patient_outcome         TEXT,
    device_action           TEXT DEFAULT 'none',
    status                  adverse_event_status NOT NULL DEFAULT 'draft',
    submitted_to_cdsco      BOOLEAN NOT NULL DEFAULT false,
    cdsco_reference         TEXT,
    submitted_at            TIMESTAMPTZ,
    investigation_findings  TEXT,
    corrective_action       TEXT,
    created_by              UUID NOT NULL REFERENCES users(id),
    updated_by              UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, report_number)
);

ALTER TABLE materiovigilance_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON materiovigilance_reports
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_materiovigilance_reports
    BEFORE UPDATE ON materiovigilance_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_mv_reports_tenant ON materiovigilance_reports(tenant_id);
CREATE INDEX idx_mv_reports_patient ON materiovigilance_reports(tenant_id, patient_id);
CREATE INDEX idx_mv_reports_status ON materiovigilance_reports(tenant_id, status);

-- ── 5. pcpndt_forms ─────────────────────────────────────

CREATE TABLE pcpndt_forms (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                   UUID NOT NULL REFERENCES tenants(id),
    form_number                 TEXT NOT NULL,
    patient_id                  UUID NOT NULL REFERENCES patients(id),
    referral_doctor_id          UUID REFERENCES users(id),
    performing_doctor_id        UUID NOT NULL REFERENCES users(id),
    procedure_type              TEXT NOT NULL,
    indication                  TEXT NOT NULL,
    gestational_age_weeks       INT,
    lmp_date                    DATE,
    declaration_text            TEXT,
    status                      pcpndt_form_status NOT NULL DEFAULT 'draft',
    form_signed_at              TIMESTAMPTZ,
    patient_consent_id          UUID REFERENCES patient_consents(id),
    registered_with             TEXT,
    registration_date           DATE,
    quarterly_report_included   BOOLEAN NOT NULL DEFAULT false,
    gender_disclosure_blocked   BOOLEAN NOT NULL DEFAULT true,
    created_by                  UUID NOT NULL REFERENCES users(id),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, form_number)
);

ALTER TABLE pcpndt_forms ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON pcpndt_forms
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_pcpndt_forms
    BEFORE UPDATE ON pcpndt_forms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_pcpndt_forms_tenant ON pcpndt_forms(tenant_id);
CREATE INDEX idx_pcpndt_forms_patient ON pcpndt_forms(tenant_id, patient_id);
CREATE INDEX idx_pcpndt_forms_status ON pcpndt_forms(tenant_id, status);

-- ── 6. compliance_calendar ───────────────────────────────

CREATE TABLE compliance_calendar (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    title               TEXT NOT NULL,
    description         TEXT,
    regulatory_body_id  UUID REFERENCES regulatory_bodies(id),
    event_type          TEXT NOT NULL DEFAULT 'custom',
    due_date            DATE NOT NULL,
    reminder_days       INT[] NOT NULL DEFAULT '{30,7,1}',
    department_id       UUID REFERENCES departments(id),
    assigned_to         UUID REFERENCES users(id),
    status              TEXT NOT NULL DEFAULT 'upcoming',
    completed_at        TIMESTAMPTZ,
    completed_by        UUID REFERENCES users(id),
    recurrence          TEXT NOT NULL DEFAULT 'once',
    source_table        TEXT,
    source_id           UUID,
    created_by          UUID NOT NULL REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE compliance_calendar ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON compliance_calendar
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_compliance_calendar
    BEFORE UPDATE ON compliance_calendar
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_compliance_calendar_tenant ON compliance_calendar(tenant_id);
CREATE INDEX idx_compliance_calendar_due ON compliance_calendar(tenant_id, due_date);
CREATE INDEX idx_compliance_calendar_status ON compliance_calendar(tenant_id, status);
CREATE INDEX idx_compliance_calendar_dept ON compliance_calendar(tenant_id, department_id);
