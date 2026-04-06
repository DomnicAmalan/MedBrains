-- 069_consent.sql — Consent Management & Medico-Legal
-- Adds consent templates, audit trail, and digital signature metadata.
-- Extends existing patient_consents and procedure_consents tables.

-- ── Enums ─────────────────────────────────────────────────

CREATE TYPE consent_template_category AS ENUM (
    'general',
    'surgical',
    'anesthesia',
    'blood_transfusion',
    'investigation',
    'data_sharing',
    'research',
    'photography',
    'teaching',
    'refusal',
    'advance_directive',
    'organ_donation',
    'communication',
    'custom'
);

CREATE TYPE consent_audit_action AS ENUM (
    'created',
    'granted',
    'denied',
    'signed',
    'refused',
    'withdrawn',
    'revoked',
    'expired',
    'renewed',
    'amended'
);

CREATE TYPE signature_type AS ENUM (
    'pen_on_paper',
    'digital_pen',
    'aadhaar_esign',
    'biometric_thumb',
    'otp',
    'video_consent',
    'verbal_witness'
);

-- ── consent_templates ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS consent_templates (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    code                    TEXT NOT NULL,
    name                    TEXT NOT NULL,
    category                consent_template_category NOT NULL DEFAULT 'general',
    version                 INT NOT NULL DEFAULT 1,
    body_text               JSONB NOT NULL DEFAULT '{}'::jsonb,
    risks_section           JSONB,
    alternatives_section    JSONB,
    benefits_section        JSONB,
    required_fields         TEXT[] DEFAULT '{}',
    requires_witness        BOOLEAN NOT NULL DEFAULT false,
    requires_doctor         BOOLEAN NOT NULL DEFAULT true,
    validity_days           INT,
    applicable_departments  UUID[],
    is_read_aloud_required  BOOLEAN NOT NULL DEFAULT false,
    is_active               BOOLEAN NOT NULL DEFAULT true,
    sort_order              INT NOT NULL DEFAULT 0,
    created_by              UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

ALTER TABLE consent_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_consent_templates ON consent_templates
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_consent_templates_tenant ON consent_templates(tenant_id);
CREATE INDEX idx_consent_templates_category ON consent_templates(tenant_id, category);

CREATE TRIGGER trg_consent_templates_updated_at
    BEFORE UPDATE ON consent_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── consent_signature_metadata ────────────────────────────

CREATE TABLE IF NOT EXISTS consent_signature_metadata (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    consent_source          TEXT NOT NULL CHECK (consent_source IN ('patient_consent', 'procedure_consent')),
    consent_id              UUID NOT NULL,
    signature_type          signature_type NOT NULL,
    signature_image_url     TEXT,
    video_consent_url       TEXT,
    aadhaar_esign_ref       TEXT,
    aadhaar_esign_timestamp TIMESTAMPTZ,
    biometric_hash          TEXT,
    biometric_device_id     TEXT,
    witness_name            TEXT,
    witness_designation     TEXT,
    witness_signature_url   TEXT,
    doctor_signature_url    TEXT,
    captured_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    captured_by             UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE consent_signature_metadata ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_consent_sig ON consent_signature_metadata
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_consent_sig_tenant ON consent_signature_metadata(tenant_id);
CREATE INDEX idx_consent_sig_consent ON consent_signature_metadata(consent_source, consent_id);

-- ── consent_audit_log ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS consent_audit_log (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    consent_source          TEXT NOT NULL CHECK (consent_source IN ('patient_consent', 'procedure_consent')),
    consent_id              UUID NOT NULL,
    action                  consent_audit_action NOT NULL,
    old_status              TEXT,
    new_status              TEXT,
    changed_by              UUID REFERENCES users(id),
    change_reason           TEXT,
    ip_address              TEXT,
    user_agent              TEXT,
    metadata                JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE consent_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_consent_audit ON consent_audit_log
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_consent_audit_tenant ON consent_audit_log(tenant_id);
CREATE INDEX idx_consent_audit_patient ON consent_audit_log(tenant_id, patient_id);
CREATE INDEX idx_consent_audit_consent ON consent_audit_log(consent_source, consent_id);

-- ── ALTER existing tables ─────────────────────────────────

ALTER TABLE patient_consents
    ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES consent_templates(id),
    ADD COLUMN IF NOT EXISTS signature_metadata_id UUID REFERENCES consent_signature_metadata(id);

ALTER TABLE procedure_consents
    ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES consent_templates(id),
    ADD COLUMN IF NOT EXISTS signature_metadata_id UUID REFERENCES consent_signature_metadata(id);
