-- MedBrains HMS — Form Master / Field Master / Module Linker
-- Configuration-driven form system with regulatory body links.
-- Fields have per-body requirement levels; forms are resolved per-tenant.

-- ============================================================
-- New enum types
-- ============================================================

CREATE TYPE field_data_type AS ENUM (
    'text', 'email', 'phone', 'date', 'datetime', 'time',
    'select', 'multiselect', 'checkbox', 'radio', 'textarea',
    'number', 'decimal', 'file', 'hidden', 'computed',
    'boolean', 'uuid_fk', 'json'
);

CREATE TYPE requirement_level AS ENUM (
    'optional', 'recommended', 'conditional', 'mandatory'
);

CREATE TYPE form_status AS ENUM (
    'draft', 'active', 'deprecated'
);

-- ============================================================
-- Field Masters (global — no RLS)
-- Central registry of all fields with metadata.
-- ============================================================

CREATE TABLE field_masters (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    description     TEXT,
    data_type       field_data_type NOT NULL DEFAULT 'text',
    default_value   TEXT,
    placeholder     TEXT,
    validation      JSONB,
    ui_component    TEXT,
    ui_width        TEXT DEFAULT 'half',
    fhir_path       TEXT,
    db_table        TEXT,
    db_column       TEXT,
    condition       JSONB,
    is_system       BOOLEAN NOT NULL DEFAULT false,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_field_masters_code ON field_masters(code);
CREATE INDEX idx_field_masters_active ON field_masters(is_active) WHERE is_active;
CREATE INDEX idx_field_masters_db ON field_masters(db_table, db_column);

-- ============================================================
-- Field Regulatory Links (global — no RLS)
-- Maps fields to regulatory bodies with requirement levels.
-- ============================================================

CREATE TABLE field_regulatory_links (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    field_id            UUID NOT NULL REFERENCES field_masters(id) ON DELETE CASCADE,
    regulatory_body_id  UUID NOT NULL REFERENCES regulatory_bodies(id) ON DELETE CASCADE,
    requirement_level   requirement_level NOT NULL DEFAULT 'optional',
    clause_reference    TEXT,
    clause_code         TEXT,
    description         TEXT,
    condition_override  JSONB,
    UNIQUE (field_id, regulatory_body_id)
);

CREATE INDEX idx_frl_field ON field_regulatory_links(field_id);
CREATE INDEX idx_frl_body ON field_regulatory_links(regulatory_body_id);
CREATE INDEX idx_frl_level ON field_regulatory_links(requirement_level);

-- ============================================================
-- Form Masters (global — no RLS)
-- Form definitions with versioning.
-- ============================================================

CREATE TABLE form_masters (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    version     INT NOT NULL DEFAULT 1,
    status      form_status NOT NULL DEFAULT 'draft',
    config      JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Only one active form per code
CREATE UNIQUE INDEX idx_form_masters_active_code ON form_masters(code) WHERE status = 'active';
CREATE INDEX idx_form_masters_code ON form_masters(code);

-- ============================================================
-- Form Sections (global)
-- Sections within a form for visual grouping.
-- ============================================================

CREATE TABLE form_sections (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id         UUID NOT NULL REFERENCES form_masters(id) ON DELETE CASCADE,
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    sort_order      INT NOT NULL DEFAULT 0,
    is_collapsible  BOOLEAN NOT NULL DEFAULT true,
    is_default_open BOOLEAN NOT NULL DEFAULT true,
    icon            TEXT,
    UNIQUE (form_id, code)
);

CREATE INDEX idx_form_sections_form ON form_sections(form_id);

-- ============================================================
-- Form Fields (global)
-- Links fields to forms within sections.
-- ============================================================

CREATE TABLE form_fields (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id         UUID NOT NULL REFERENCES form_masters(id) ON DELETE CASCADE,
    section_id      UUID NOT NULL REFERENCES form_sections(id) ON DELETE CASCADE,
    field_id        UUID NOT NULL REFERENCES field_masters(id) ON DELETE CASCADE,
    sort_order      INT NOT NULL DEFAULT 0,
    label_override  TEXT,
    is_quick_mode   BOOLEAN NOT NULL DEFAULT false,
    UNIQUE (form_id, field_id)
);

CREATE INDEX idx_form_fields_form ON form_fields(form_id);
CREATE INDEX idx_form_fields_section ON form_fields(section_id);
CREATE INDEX idx_form_fields_field ON form_fields(field_id);
CREATE INDEX idx_form_fields_quick ON form_fields(form_id, is_quick_mode) WHERE is_quick_mode;

-- ============================================================
-- Module Form Links (global)
-- Connects forms to modules with a usage context.
-- ============================================================

CREATE TABLE module_form_links (
    module_code TEXT NOT NULL,
    form_id     UUID NOT NULL REFERENCES form_masters(id) ON DELETE CASCADE,
    context     TEXT NOT NULL DEFAULT 'primary',
    UNIQUE (module_code, form_id, context)
);

CREATE INDEX idx_module_form_links_module ON module_form_links(module_code);

-- ============================================================
-- Tenant Field Overrides (tenant-scoped, RLS)
-- Per-tenant customization of fields (can only upgrade, never downgrade).
-- ============================================================

CREATE TABLE tenant_field_overrides (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    field_id                UUID NOT NULL REFERENCES field_masters(id) ON DELETE CASCADE,
    form_id                 UUID REFERENCES form_masters(id) ON DELETE CASCADE,
    label_override          TEXT,
    requirement_override    requirement_level,
    is_hidden               BOOLEAN NOT NULL DEFAULT false,
    validation_override     JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, field_id, form_id)
);

CREATE INDEX idx_tfo_tenant ON tenant_field_overrides(tenant_id);
CREATE INDEX idx_tfo_field ON tenant_field_overrides(field_id);

-- ============================================================
-- Row-Level Security — tenant_field_overrides only
-- (All other tables are global — no RLS needed)
-- ============================================================

ALTER TABLE tenant_field_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_tfo ON tenant_field_overrides
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers
-- ============================================================

CREATE TRIGGER trg_field_masters_updated_at BEFORE UPDATE ON field_masters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_form_masters_updated_at BEFORE UPDATE ON form_masters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_tenant_field_overrides_updated_at BEFORE UPDATE ON tenant_field_overrides
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Seed Data (generated from Patient_Registration_Fields.xlsx)
-- ============================================================

-- Auto-generated seed data from Patient_Registration_Fields.xlsx
-- 60 fields, 167 regulatory links

-- Additional regulatory bodies for international support
INSERT INTO regulatory_bodies (id, code, name, level, country_id, description) VALUES
    ('f0000000-0000-0000-0000-000000000025', 'HIPAA', 'Health Insurance Portability and Accountability Act', 'international', NULL, 'US health data privacy and security'),
    ('f0000000-0000-0000-0000-000000000026', 'NHS', 'National Health Service', 'national', (SELECT id FROM geo_countries WHERE code = 'IN'), 'UK national health system'),
    ('f0000000-0000-0000-0000-000000000027', 'CBAHI', 'Saudi Central Board for Accreditation of Healthcare Institutions', 'international', NULL, 'Saudi healthcare accreditation'),
    ('f0000000-0000-0000-0000-000000000028', 'NABIDH', 'National Backbone for Integrated Dubai Health', 'international', NULL, 'UAE Dubai health information exchange'),
    ('f0000000-0000-0000-0000-000000000029', 'EHDS', 'European Health Data Space', 'international', NULL, 'EU health data interoperability framework')
ON CONFLICT (code) DO NOTHING;

-- Form: Patient Registration
INSERT INTO form_masters (id, code, name, version, status, config) VALUES
    ('a2000000-0000-0000-0000-000000000001', 'patient_registration', 'Patient Registration', 1, 'active', '{"submit_label": "Register Patient", "supports_quick_mode": true}');

-- Form sections
INSERT INTO form_sections (id, form_id, code, name, sort_order, is_collapsible, is_default_open, icon) VALUES
    ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'core_identity', 'Core Identity', 1, false, true, 'IconUser'),
    ('a3000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'demographics', 'Demographics', 2, true, true, 'IconId'),
    ('a3000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000001', 'contact', 'Contact', 3, true, true, 'IconPhone'),
    ('a3000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000001', 'emergency_contact', 'Emergency Contact', 4, true, true, 'IconHeartbeat'),
    ('a3000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000001', 'address', 'Address', 5, true, true, 'IconMapPin'),
    ('a3000000-0000-0000-0000-000000000006', 'a2000000-0000-0000-0000-000000000001', 'insurance', 'Insurance', 6, true, false, 'IconShield'),
    ('a3000000-0000-0000-0000-000000000007', 'a2000000-0000-0000-0000-000000000001', 'government_id', 'Government ID', 7, true, false, 'IconCreditCard'),
    ('a3000000-0000-0000-0000-000000000008', 'a2000000-0000-0000-0000-000000000001', 'consent', 'Consent', 8, true, true, 'IconClipboard'),
    ('a3000000-0000-0000-0000-000000000009', 'a2000000-0000-0000-0000-000000000001', 'registration', 'Registration', 9, true, true, 'IconForms'),
    ('a3000000-0000-0000-0000-000000000010', 'a2000000-0000-0000-0000-000000000001', 'allergies', 'Allergies', 10, true, true, 'IconAlertTriangle');

-- Field masters
INSERT INTO field_masters (id, code, name, description, data_type, default_value, placeholder, validation, ui_component, ui_width, fhir_path, db_table, db_column, condition, is_system, is_active) VALUES
    ('a1000000-0000-0000-0000-000000000001', 'patient.prefix', 'Prefix / Title', 'Honorific prefix for the patient''s name', 'text', NULL, NULL, '{"options": ["Mr", "Mrs", "Ms", "Dr", "Prof", "Master", "Baby", "Mx"]}', NULL, 'half', 'Patient.name.prefix', 'patients', 'prefix', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000002', 'patient.first_name', 'First Name', 'Required by NABH AAC.2, JCI IPSG.1, ABDM, NHS PDS. Primary patient identifier.', 'text', NULL, NULL, '{"min_length": 1}', NULL, 'half', 'Patient.name.given[0]', 'patients', 'first_name', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000003', 'patient.middle_name', 'Middle Name', 'Recommended by USCDI v2, ABDM. Improves MPI matching accuracy.', 'text', NULL, NULL, '{"max_length": 100}', NULL, 'half', 'Patient.name.given[1]', 'patients', 'middle_name', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000004', 'patient.last_name', 'Last Name / Surname', 'Required by NABH AAC.2, JCI IPSG.1, ABDM, NHS PDS, IPS.', 'text', NULL, NULL, '{"min_length": 1}', NULL, 'half', 'Patient.name.family', 'patients', 'last_name', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000005', 'patient.suffix', 'Suffix', 'Name suffix for formal records.', 'text', NULL, NULL, '{"options": ["Jr", "Sr", "II", "III", "PhD"]}', NULL, 'half', 'Patient.name.suffix', 'patients', 'suffix', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000006', 'patient.full_name_local', 'Full Name (Local Script)', 'Required for regional language hospitals per NABH. Stores name in local script (Hindi, Tamil, etc.)', 'text', NULL, NULL, '{"max_length": 200}', NULL, 'half', NULL, 'patients', 'full_name_local', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000007', 'patient.father_name', 'Father''s Name', 'Required for minors per NABH. Used in Aadhaar e-KYC verification. Common in Indian insurance claims.', 'text', NULL, NULL, '{"max_length": 100}', NULL, 'half', NULL, 'patients', 'father_name', '{"field": "_tenant.patient_is_minor", "operator": "eq", "value": true}', true, true),
    ('a1000000-0000-0000-0000-000000000008', 'patient.mother_name', 'Mother''s Name', 'Used for birth certificate linkage and some insurance forms.', 'text', NULL, NULL, '{"max_length": 100}', NULL, 'half', NULL, 'patients', 'mother_name', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000009', 'patient.spouse_name', 'Spouse Name', 'Required for married patients in insurance claims and medico-legal cases.', 'text', NULL, NULL, NULL, NULL, 'half', NULL, 'patients', 'spouse_name', '{"field": "patient.marital_status", "operator": "in", "values": ["married", "separated", "widowed"]}', true, true),
    ('a1000000-0000-0000-0000-000000000010', 'patient.guardian_name', 'Guardian Name', 'Required per NABH COP.5 for minors. Per JCI PFR.6, guardian consent is mandatory for pediatric patients.', 'text', NULL, NULL, NULL, NULL, 'half', NULL, 'patients', 'guardian_name', '{"field": "_tenant.patient_is_minor", "operator": "eq", "value": true}', true, true),
    ('a1000000-0000-0000-0000-000000000011', 'patient.guardian_relation', 'Guardian Relation', 'Relationship of guardian to patient. Required with guardian name.', 'text', NULL, NULL, '{"options": ["parent", "grandparent", "legal_guardian", "spouse", "sibling", "other"]}', NULL, 'half', NULL, 'patients', 'guardian_relation', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000012', 'patient.date_of_birth', 'Date of Birth', 'Required by NABH AAC.2 (2nd identifier), JCI IPSG.1, NHS PDS, IPS (mandatory). ABDM allows partial (year only).', 'date', NULL, NULL, NULL, NULL, 'half', 'Patient.birthDate', 'patients', 'date_of_birth', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000013', 'patient.is_dob_estimated', 'DOB Estimated Flag', 'Set to true when DOB is estimated from stated age. Per NABH for patients who cannot provide exact DOB.', 'boolean', NULL, NULL, NULL, NULL, 'quarter', NULL, 'patients', 'is_dob_estimated', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000014', 'patient.biological_sex', 'Biological Sex', 'Required by all standards. NABH AAC.2, JCI IPSG.1, ABDM, NHS, CBAHI, UAE NABIDH.', 'select', NULL, NULL, '{"options": ["male", "female", "other", "unknown. Maps to FHIR administrative-gender"]}', NULL, 'half', 'Patient.gender (administrative)', 'patients', 'biological_sex', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000015', 'patient.gender_identity', 'Gender Identity', 'USCDI v3 requirement. Separate from biological sex for clinical accuracy per WPATH standards.', 'text', NULL, NULL, '{"options": ["man", "woman", "non_binary", "transgender_male", "transgender_female", "other", "prefer_not_to_say"]}', NULL, 'half', 'Patient.extension[gender-identity]', 'patients', 'gender_identity', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000016', 'patient.marital_status', 'Marital Status', 'Per HL7 v3 MaritalStatus value set. Required for some insurance claims.', 'select', NULL, NULL, '{"options": ["single", "married", "divorced", "widowed", "separated", "domestic_partner", "unknown"]}', NULL, 'half', 'Patient.maritalStatus', 'patients', 'marital_status', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000017', 'patient.religion', 'Religion', 'Per NABH COP.6 for spiritual care. Per JCI PFR.1.1 for respecting cultural values.', 'text', NULL, NULL, '{"fk_table": "master_religions"}', NULL, 'half', 'Patient.extension[religion]', 'patients', 'religion', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000018', 'patient.nationality_id', 'Nationality', 'Required by CBAHI (Saudi) and UAE NABIDH. Determines ID document requirements.', 'uuid_fk', NULL, NULL, '{"fk_table": "geo_countries"}', NULL, 'half', 'Patient.extension[nationality]', 'patients', 'nationality_id', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000019', 'patient.preferred_language', 'Preferred Language', 'Per NABH PRE.2, JCI PFR.2. Used for consent forms, discharge summaries, interpreter needs.', 'text', NULL, NULL, NULL, NULL, 'half', 'Patient.communication.language', 'patients', 'preferred_language', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000020', 'patient.birth_place', 'Birth Place', 'Used for epidemiological reporting and passport linkage.', 'text', NULL, NULL, '{"max_length": 100}', NULL, 'half', NULL, 'patients', 'birth_place', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000021', 'patient.blood_group', 'Blood Group', 'Per NABH COP.6. Per JCI IPSG.5 for safe blood transfusion. Must be lab-verified before clinical use.', 'select', NULL, NULL, '{"options": ["a_positive ... o_negative", "unknown. 9 values"]}', NULL, 'half', 'Observation (LOINC 882-1)', 'patients', 'blood_group', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000022', 'patient.blood_group_verified', 'Blood Group Verified', 'Per JCI IPSG.5: self-reported blood group must be re-verified before transfusion.', 'boolean', NULL, NULL, NULL, NULL, 'quarter', NULL, 'patients', 'blood_group_verified', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000023', 'patient.no_known_allergies', 'No Known Allergies (NKDA)', 'Per NABH COP.6, JCI IPSG.5. Allergy status must be actively confirmed, not left blank. Critical for patient safety.', 'boolean', NULL, NULL, NULL, NULL, 'quarter', 'AllergyIntolerance with code=no-known-allergy', 'patients', 'no_known_allergies', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000024', 'patient.is_deceased', 'Deceased Flag', 'FHIR modifier element. When true, restricts further clinical encounters.', 'boolean', NULL, NULL, NULL, NULL, 'quarter', 'Patient.deceased[x]', 'patients', 'is_deceased', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000025', 'patient.deceased_date', 'Deceased Date', 'USCDI v2 data element. Required for mortality reporting (ICD-11 Chapter 22+).', 'datetime', NULL, NULL, NULL, NULL, 'half', 'Patient.deceasedDateTime', 'patients', 'deceased_date', '{"field": "patient.is_deceased", "operator": "eq", "value": true}', true, true),
    ('a1000000-0000-0000-0000-000000000026', 'patient.phone_primary', 'Phone Primary (Mobile)', 'Required by NABH AAC.2, JCI ACC.2, ABDM, CBAHI, UAE NABIDH.', 'text', NULL, NULL, NULL, NULL, 'half', 'Patient.telecom (system=phone, use=mobile)', 'patients', 'phone_primary', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000027', 'patient.phone_secondary', 'Phone Secondary', 'Alternate contact number. Recommended by NABH for reachability.', 'text', NULL, NULL, NULL, NULL, 'half', 'Patient.telecom (system=phone, rank=2)', 'patients', 'phone_secondary', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000028', 'patient.email', 'Email', 'PHI per HIPAA. USCDI v2 data element.', 'text', NULL, NULL, '{"max_length": 254}', NULL, 'half', 'Patient.telecom (system=email)', 'patients', 'email', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000029', 'patient.preferred_contact_method', 'Preferred Contact Method', 'Per JCI PFR.2 for effective communication.', 'text', NULL, NULL, '{"options": ["phone", "sms", "email", "whatsapp", "postal"]}', NULL, 'half', NULL, 'patients', 'preferred_contact_method', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000030', 'patient_contacts.contact_name', 'Contact Name', 'Required by NABH AAC.2, JCI COP.2, CBAHI ESR. At least one emergency contact must be recorded.', 'text', NULL, NULL, '{"min_length": 1}', NULL, 'half', 'Patient.contact.name', 'patient_contacts', 'contact_name', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000031', 'patient_contacts.relation', 'Contact Relation', 'Required with emergency contact name.', 'text', NULL, NULL, '{"fk_table": "master_relations"}', NULL, 'half', 'Patient.contact.relationship', 'patient_contacts', 'relation', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000032', 'patient_contacts.phone', 'Contact Phone', 'Required with emergency contact name.', 'text', NULL, NULL, NULL, NULL, 'half', 'Patient.contact.telecom', 'patient_contacts', 'phone', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000033', 'patient_addresses.address_line1', 'Address Line 1', 'Required by NABH AAC.2, JCI ACC.2, NHS PDS, CBAHI, UAE NABIDH.', 'text', NULL, NULL, '{"max_length": 200}', NULL, 'full', 'Patient.address.line', 'patient_addresses', 'address_line1', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000034', 'patient_addresses.city', 'City', 'Required for all major standards.', 'text', NULL, NULL, '{"max_length": 100}', NULL, 'half', 'Patient.address.city', 'patient_addresses', 'city', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000035', 'patient_addresses.state_id', 'State', 'Required. ABDM uses numeric state codes (mapped to geo_states).', 'uuid_fk', NULL, NULL, '{"fk_table": "geo_states"}', NULL, 'half', 'Patient.address.state', 'patient_addresses', 'state_id', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000036', 'patient_addresses.country_id', 'Country', 'Per IPS specification: must be ISO 3166.', 'uuid_fk', NULL, NULL, '{"fk_table": "geo_countries"}', NULL, 'half', 'Patient.address.country', 'patient_addresses', 'country_id', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000037', 'patient_addresses.postal_code', 'Postal Code / PIN', 'Required by NABH, NHS PDS, ABDM. HIPAA restricts sharing for small populations.', 'text', NULL, NULL, '{"regex": "^[1-9]\\d{5}$"}', NULL, 'half', 'Patient.address.postalCode', 'patient_addresses', 'postal_code', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000038', 'patient.financial_class', 'Financial Class', 'Required by NABH AAC.5, JCI ACC.2.4. Determines billing workflow. In Saudi/UAE, insurance is legally mandatory.', 'select', NULL, NULL, '{"options": ["self_pay", "insurance", "government_scheme", "corporate", "charity", "research"]}', NULL, 'half', 'Coverage resource', 'patients', 'financial_class', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000039', 'patient_insurance.insurance_provider', 'Insurance Provider', 'Required when patient is insured. Per NABH AAC.5, JCI ACC.2.4.', 'text', NULL, NULL, '{"fk_table": "master_insurance_providers"}', NULL, 'half', 'Coverage.payor', 'patient_insurance', 'insurance_provider', '{"field": "patient.financial_class", "operator": "eq", "value": "insurance"}', true, true),
    ('a1000000-0000-0000-0000-000000000040', 'patient_insurance.policy_number', 'Policy Number', 'Required for insurance claims processing.', 'text', NULL, NULL, '{"max_length": 50}', NULL, 'half', 'Coverage.identifier', 'patient_insurance', 'policy_number', '{"field": "patient.financial_class", "operator": "eq", "value": "insurance"}', true, true),
    ('a1000000-0000-0000-0000-000000000041', 'patient_identifiers.aadhaar', 'Aadhaar Number', 'Per ABDM: primary Aadhaar-based ABHA enrollment. Per Indian law: voluntary, cannot deny services. Store only hash per privacy guidelines.', 'text', NULL, NULL, '{"max_length": 12}', NULL, 'half', 'Patient.identifier (type=NI, system=UIDAI)', 'patient_identifiers', 'patient_identifiers (type=aadhaar)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000042', 'patient_identifiers.abha', 'ABHA Number', 'Per ABDM: national health identifier for India. Optional for registration but required for health record exchange.', 'text', NULL, NULL, '{"regex": "^\\d{2}-\\d{4}-\\d{4}-\\d{4}$", "max_length": 14}', NULL, 'half', 'Patient.identifier (type=ABHA, system=ABDM)', 'patient_identifiers', 'patient_identifiers (type=abha)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000043', 'patient_identifiers.abha_address', 'ABHA Address', 'Per ABDM: user-friendly handle for health record access and consent management.', 'text', NULL, NULL, NULL, NULL, 'half', 'Patient.identifier (type=PHR, system=ABDM)', 'patient_identifiers', 'patient_identifiers (type=abha_address)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000044', 'patient_identifiers.pan', 'PAN Card', 'Indian Income Tax PAN. Required for billing above Rs 50,000 threshold.', 'text', NULL, NULL, '{"regex": "^[A-Z]{5}[0-9]{4}[A-Z]$", "max_length": 10}', NULL, 'half', NULL, 'patient_identifiers', 'patient_identifiers (type=pan)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000045', 'patient_identifiers.passport', 'Passport', 'Required for international/foreign patients per NABH, JCI, CBAHI, UAE.', 'text', NULL, NULL, '{"max_length": 20}', NULL, 'half', 'Patient.identifier (type=PPN)', 'patient_identifiers', 'patient_identifiers (type=passport)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000046', 'patient_identifiers.ssn', 'SSN (USA)', 'PHI per HIPAA. Required for US insurance claims. Must be encrypted at rest per HIPAA Security Rule.', 'text', NULL, NULL, '{"max_length": 11}', NULL, 'half', 'Patient.identifier (type=SS)', 'patient_identifiers', 'patient_identifiers (type=ssn)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000047', 'patient_identifiers.nhs_number', 'NHS Number (UK)', 'Per NHS PDS: primary patient identifier in UK. Allocated at birth (England/Wales/IoM).', 'text', NULL, NULL, '{"max_length": 10}', NULL, 'half', 'Patient.identifier (type=NI, system=NHS)', 'patient_identifiers', 'patient_identifiers (type=nhs_number)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000048', 'patient_identifiers.emirates_id', 'Emirates ID (UAE)', 'Legally mandatory for all UAE healthcare per DHA/DOH. Links to unified NABIDH patient record.', 'text', NULL, NULL, '{"max_length": 15}', NULL, 'half', 'Patient.identifier (type=NI)', 'patient_identifiers', 'patient_identifiers (type=emirates_id)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000049', 'patient_identifiers.national_id_iqama', 'Saudi National ID / Iqama', 'Per CBAHI: mandatory patient identifier in Saudi Arabia. National ID for citizens, Iqama for residents.', 'text', NULL, NULL, '{"max_length": 10}', NULL, 'half', 'Patient.identifier (type=NI)', 'patient_identifiers', 'patient_identifiers (type=national_id/iqama)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000050', 'patient_consents.general_treatment', 'General Treatment Consent', 'Mandatory per NABH PRE.1, JCI PFR.5.1, HIPAA Privacy Rule, CBAHI, GDPR. Must be captured at registration.', 'json', NULL, NULL, NULL, NULL, 'full', 'Consent resource', 'patient_consents', 'patient_consents (type=general_treatment)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000051', 'patient_consents.abdm_linking', 'ABDM Data Sharing Consent', 'Per ABDM: specific consent for linking health records to ABHA. Uses DEPA (Data Empowerment & Protection Architecture) framework.', 'json', NULL, NULL, NULL, NULL, 'full', 'Consent resource', 'patient_consents', 'patient_consents (type=abdm_linking)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000052', 'patient_consents.research_participation', 'Research Participation Consent', 'Per JCI COP.9, HIPAA 45 CFR 46: research consent must be distinct from treatment consent.', 'json', NULL, NULL, NULL, NULL, 'full', 'Consent resource', 'patient_consents', 'patient_consents (type=research_participation)', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000053', 'patient.category', 'Patient Category', 'Per NABH AAC.5. Determines billing rules, priority, and reporting workflow.', 'select', NULL, NULL, '{"options": ["general", "private", "insurance", "pmjay", "cghs", "esi", "staff", "staff_dependent", "vip", "mlc", "free", "charity", "corporate", "research_subject"]}', NULL, 'half', NULL, 'patients', 'category', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000054', 'patient.registration_type', 'Registration Type', 'Per NABH AAC.1, JCI ACC.1. Determines workflow (new patient vs follow-up).', 'select', NULL, NULL, '{"options": ["new", "revisit", "transfer_in", "referral", "emergency", "camp", "telemedicine", "pre_registration"]}', NULL, 'half', NULL, 'patients', 'registration_type', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000055', 'patient.is_medico_legal', 'Medico-Legal Case Flag', 'Per Indian Penal Code (IPC) and CrPC. Triggers police intimation, special documentation, restricted access.', 'boolean', NULL, NULL, NULL, NULL, 'quarter', NULL, 'patients', 'is_medico_legal', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000056', 'patient.uhid', 'UHID (Auto-Generated)', 'Auto-generated. Required by all standards. NABH AAC.1, JCI IPSG.1, NHS, CBAHI, UAE NABIDH.', 'text', NULL, NULL, NULL, NULL, 'half', 'Patient.identifier (type=MR)', 'patients', 'uhid', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000057', 'patient.photo_url', 'Photo', 'Recommended by NABH AAC.2, JCI IPSG.1 for visual identification. PHI per HIPAA.', 'text', NULL, NULL, NULL, NULL, 'half', 'Patient.photo', 'patients', 'photo_url', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000058', 'patient_allergies.allergy_type', 'Allergy Type', 'Per NABH COP.6, JCI IPSG.5. Category of allergen for clinical decision support.', 'select', NULL, NULL, '{"options": ["drug", "food", "environmental", "latex", "contrast_dye", "biological", "other"]}', NULL, 'half', 'AllergyIntolerance.category', 'patient_allergies', 'allergy_type', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000059', 'patient_allergies.allergen_name', 'Allergen Name', 'Per NABH COP.6, JCI IPSG.5. Name of the allergen (drug name, food item, substance).', 'text', NULL, NULL, NULL, NULL, 'half', 'AllergyIntolerance.code', 'patient_allergies', 'allergen_name', NULL, true, true),
    ('a1000000-0000-0000-0000-000000000060', 'patient_allergies.severity', 'Severity', 'Per JCI IPSG.5. Severity drives alert priority in CPOE and medication ordering.', 'select', NULL, NULL, '{"options": ["mild", "moderate", "severe", "life_threatening"]}', NULL, 'half', 'AllergyIntolerance.criticality', 'patient_allergies', 'severity', NULL, true, true);

-- Form fields (linking fields to form sections)
INSERT INTO form_fields (id, form_id, section_id, field_id, sort_order, label_override, is_quick_mode) VALUES
    ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 1, NULL, false),
    ('a4000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 2, NULL, true),
    ('a4000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000003', 3, NULL, false),
    ('a4000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000004', 4, NULL, true),
    ('a4000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000005', 5, NULL, false),
    ('a4000000-0000-0000-0000-000000000006', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000006', 6, NULL, false),
    ('a4000000-0000-0000-0000-000000000007', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000007', 7, NULL, false),
    ('a4000000-0000-0000-0000-000000000008', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000008', 8, NULL, false),
    ('a4000000-0000-0000-0000-000000000009', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000009', 9, NULL, false),
    ('a4000000-0000-0000-0000-000000000010', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000010', 10, NULL, false),
    ('a4000000-0000-0000-0000-000000000011', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000011', 11, NULL, false),
    ('a4000000-0000-0000-0000-000000000012', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000012', 12, NULL, true),
    ('a4000000-0000-0000-0000-000000000013', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000013', 13, NULL, false),
    ('a4000000-0000-0000-0000-000000000014', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000014', 14, NULL, true),
    ('a4000000-0000-0000-0000-000000000015', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000015', 15, NULL, false),
    ('a4000000-0000-0000-0000-000000000016', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000016', 16, NULL, false),
    ('a4000000-0000-0000-0000-000000000017', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000017', 17, NULL, false),
    ('a4000000-0000-0000-0000-000000000018', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000018', 18, NULL, false),
    ('a4000000-0000-0000-0000-000000000019', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000019', 19, NULL, false),
    ('a4000000-0000-0000-0000-000000000020', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000020', 20, NULL, false),
    ('a4000000-0000-0000-0000-000000000021', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000021', 21, NULL, false),
    ('a4000000-0000-0000-0000-000000000022', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000022', 22, NULL, false),
    ('a4000000-0000-0000-0000-000000000023', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000023', 23, NULL, false),
    ('a4000000-0000-0000-0000-000000000024', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000024', 24, NULL, false),
    ('a4000000-0000-0000-0000-000000000025', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000025', 25, NULL, false),
    ('a4000000-0000-0000-0000-000000000026', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000026', 26, NULL, true),
    ('a4000000-0000-0000-0000-000000000027', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000027', 27, NULL, false),
    ('a4000000-0000-0000-0000-000000000028', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000028', 28, NULL, false),
    ('a4000000-0000-0000-0000-000000000029', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000029', 29, NULL, false),
    ('a4000000-0000-0000-0000-000000000030', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000030', 30, NULL, false),
    ('a4000000-0000-0000-0000-000000000031', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000031', 31, NULL, false),
    ('a4000000-0000-0000-0000-000000000032', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000032', 32, NULL, false),
    ('a4000000-0000-0000-0000-000000000033', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000033', 33, NULL, false),
    ('a4000000-0000-0000-0000-000000000034', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000034', 34, NULL, false),
    ('a4000000-0000-0000-0000-000000000035', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000035', 35, NULL, false),
    ('a4000000-0000-0000-0000-000000000036', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000036', 36, NULL, false),
    ('a4000000-0000-0000-0000-000000000037', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000037', 37, NULL, false),
    ('a4000000-0000-0000-0000-000000000038', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000038', 38, NULL, false),
    ('a4000000-0000-0000-0000-000000000039', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000039', 39, NULL, false),
    ('a4000000-0000-0000-0000-000000000040', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000040', 40, NULL, false),
    ('a4000000-0000-0000-0000-000000000041', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000041', 41, NULL, false),
    ('a4000000-0000-0000-0000-000000000042', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000042', 42, NULL, false),
    ('a4000000-0000-0000-0000-000000000043', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000043', 43, NULL, false),
    ('a4000000-0000-0000-0000-000000000044', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000044', 44, NULL, false),
    ('a4000000-0000-0000-0000-000000000045', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000045', 45, NULL, false),
    ('a4000000-0000-0000-0000-000000000046', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000046', 46, NULL, false),
    ('a4000000-0000-0000-0000-000000000047', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000047', 47, NULL, false),
    ('a4000000-0000-0000-0000-000000000048', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000048', 48, NULL, false),
    ('a4000000-0000-0000-0000-000000000049', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000049', 49, NULL, false),
    ('a4000000-0000-0000-0000-000000000050', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000050', 50, NULL, false),
    ('a4000000-0000-0000-0000-000000000051', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000051', 51, NULL, false),
    ('a4000000-0000-0000-0000-000000000052', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000052', 52, NULL, false),
    ('a4000000-0000-0000-0000-000000000053', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000053', 53, NULL, true),
    ('a4000000-0000-0000-0000-000000000054', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000054', 54, NULL, true),
    ('a4000000-0000-0000-0000-000000000055', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000055', 55, NULL, false),
    ('a4000000-0000-0000-0000-000000000056', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000056', 56, NULL, false),
    ('a4000000-0000-0000-0000-000000000057', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000057', 57, NULL, false),
    ('a4000000-0000-0000-0000-000000000058', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000058', 58, NULL, false),
    ('a4000000-0000-0000-0000-000000000059', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000059', 59, NULL, false),
    ('a4000000-0000-0000-0000-000000000060', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000060', 60, NULL, false);

-- Field regulatory links
INSERT INTO field_regulatory_links (id, field_id, regulatory_body_id, requirement_level, clause_reference, clause_code, description, condition_override) VALUES
    ('a5000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — Patient must be identifiable by name', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'IPSG.1 ME1 — Use at least 2 identifiers (name is primary)', 'IPSG.1 ME1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000025', 'mandatory', '45 CFR 164.514(b) — Name is PHI identifier #1', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: firstName (mandatory)', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Given Name (mandatory for NHS Number allocation)', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR — Correct Patient Identification requires full name', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Patient Name (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS Patient: name.given (must-support)', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000025', 'recommended', 'USCDI v2 — Middle Name added as data element', 'USCDI v2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABHA Profile: middleName', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000011', 'a1000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000029', 'recommended', 'IPS Patient: name.given (must-support)', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — Patient must be identifiable by name', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000013', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'IPSG.1 ME1 — Name as patient identifier', 'IPSG.1 ME1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000014', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000025', 'mandatory', '45 CFR 164.514(b) — Name is PHI identifier #1', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: lastName', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000016', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Family Name (mandatory for NHS Number allocation)', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000017', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR — Correct Patient Identification', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000018', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Patient Name (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000019', 'a1000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS Patient: name.family (must-support, min 1 if no text)', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000020', 'a1000000-0000-0000-0000-000000000006', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'AAC.2 — Regional language documentation', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000021', 'a1000000-0000-0000-0000-000000000006', 'f0000000-0000-0000-0000-000000000016', 'conditional', 'ABHA: name field may be in Devanagari/regional', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000022', 'a1000000-0000-0000-0000-000000000007', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'NABH — Required for minors, insurance claims in India', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000023', 'a1000000-0000-0000-0000-000000000007', 'f0000000-0000-0000-0000-000000000016', 'conditional', 'ABDM/Aadhaar KYC: father''s name captured in e-KYC', 'ABDM', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000024', 'a1000000-0000-0000-0000-000000000008', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABDM may include from Aadhaar KYC', 'ABDM', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000025', 'a1000000-0000-0000-0000-000000000010', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'NABH COP.5 — Pediatric care requires guardian details', 'COP.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000026', 'a1000000-0000-0000-0000-000000000010', 'f0000000-0000-0000-0000-000000000001', 'conditional', 'JCI PFR.6 — Guardian consent for minors', 'PFR.6', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000027', 'a1000000-0000-0000-0000-000000000011', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'NABH COP.5', 'COP.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000028', 'a1000000-0000-0000-0000-000000000011', 'f0000000-0000-0000-0000-000000000001', 'conditional', 'JCI PFR.6', 'PFR.6', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000029', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — DOB is one of the 2 required identifiers', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000030', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'IPSG.1 ME1 — DOB as second patient identifier', 'IPSG.1 ME1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000031', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000025', 'mandatory', '45 CFR 164.514(b) — Date elements are PHI identifier #3', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000032', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: yearOfBirth/monthOfBirth/dayOfBirth (year mandatory)', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000033', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Date of Birth (mandatory for NHS Number allocation)', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000034', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR — Patient Identification requires DOB', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000035', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Date of Birth (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000036', 'a1000000-0000-0000-0000-000000000012', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS Patient: birthDate (1..1, mandatory)', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000037', 'a1000000-0000-0000-0000-000000000013', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH — For illiterate patients who don''t know exact DOB', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000038', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — Gender is part of patient demographics', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000039', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'IPSG.1 — Gender used for clinical identification', 'IPSG.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000040', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000025', 'mandatory', 'X12 837 DMG segment — Gender Code (M/F/U)', NULL, NULL, NULL),
    ('a5000000-0000-0000-0000-000000000041', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: gender (M/F/O, mandatory)', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000042', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Gender (mandatory)', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000043', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR — Correct Patient Identification', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000044', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Gender (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000045', 'a1000000-0000-0000-0000-000000000014', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS Patient: gender (must-support)', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000046', 'a1000000-0000-0000-0000-000000000015', 'f0000000-0000-0000-0000-000000000025', 'recommended', 'USCDI v3 — Gender Identity added', 'USCDI v3', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000047', 'a1000000-0000-0000-0000-000000000016', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH — Part of social history', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000048', 'a1000000-0000-0000-0000-000000000017', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH COP.6 — Cultural/spiritual needs assessment', 'COP.6', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000049', 'a1000000-0000-0000-0000-000000000017', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'JCI PFR.1.1 — Cultural and spiritual values', 'PFR.1.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000050', 'a1000000-0000-0000-0000-000000000018', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'NABH — Required for international patients', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000051', 'a1000000-0000-0000-0000-000000000018', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'CBAHI — Nationality mandatory (citizens vs residents vs visitors)', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000052', 'a1000000-0000-0000-0000-000000000018', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Nationality (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000053', 'a1000000-0000-0000-0000-000000000019', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH PRE.2 — Communication in language patient understands', 'PRE.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000054', 'a1000000-0000-0000-0000-000000000019', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'JCI PFR.2 — Identify and address communication barriers', 'PFR.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000055', 'a1000000-0000-0000-0000-000000000019', 'f0000000-0000-0000-0000-000000000026', 'recommended', 'PDS: may link to interpreter services', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000056', 'a1000000-0000-0000-0000-000000000019', 'f0000000-0000-0000-0000-000000000029', 'recommended', 'IPS Patient: communication.language (must-support)', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000057', 'a1000000-0000-0000-0000-000000000020', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABDM may capture from Aadhaar', 'ABDM', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000058', 'a1000000-0000-0000-0000-000000000021', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH COP.6 — Part of clinical assessment', 'COP.6', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000059', 'a1000000-0000-0000-0000-000000000021', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'JCI IPSG.5 — Transfusion safety', 'IPSG.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000060', 'a1000000-0000-0000-0000-000000000022', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'JCI IPSG.5 — Self-reported blood group must be re-verified before transfusion', 'IPSG.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000061', 'a1000000-0000-0000-0000-000000000023', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'NABH COP.6 — Allergy status must be documented', 'COP.6', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000062', 'a1000000-0000-0000-0000-000000000023', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'JCI IPSG.5 — Drug allergy assessment mandatory', 'IPSG.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000063', 'a1000000-0000-0000-0000-000000000025', 'f0000000-0000-0000-0000-000000000025', 'conditional', 'USCDI v2 — Date of Death', 'USCDI v2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000064', 'a1000000-0000-0000-0000-000000000026', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — Contact information mandatory at registration', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000065', 'a1000000-0000-0000-0000-000000000026', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'ACC.2 — Registration must capture contact details', 'ACC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000066', 'a1000000-0000-0000-0000-000000000026', 'f0000000-0000-0000-0000-000000000025', 'mandatory', '45 CFR 164.514(b) — Phone numbers are PHI identifier #4', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000067', 'a1000000-0000-0000-0000-000000000026', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: mobile (mandatory)', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000068', 'a1000000-0000-0000-0000-000000000026', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'CBAHI — Contact details mandatory', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000069', 'a1000000-0000-0000-0000-000000000026', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Mobile Number (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000070', 'a1000000-0000-0000-0000-000000000027', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH — Alternate contact recommended', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000071', 'a1000000-0000-0000-0000-000000000028', 'f0000000-0000-0000-0000-000000000025', 'recommended', '45 CFR 164.514(b) — Email is PHI identifier #6', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000072', 'a1000000-0000-0000-0000-000000000028', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABHA Profile: email (optional)', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000073', 'a1000000-0000-0000-0000-000000000028', 'f0000000-0000-0000-0000-000000000029', 'recommended', 'USCDI v2 — Email Address', 'USCDI v2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000074', 'a1000000-0000-0000-0000-000000000029', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'JCI PFR.2 — Address communication barriers', 'PFR.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000075', 'a1000000-0000-0000-0000-000000000030', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — Emergency contact mandatory at registration', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000076', 'a1000000-0000-0000-0000-000000000030', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'COP.2 — Emergency contact for care continuity', 'COP.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000077', 'a1000000-0000-0000-0000-000000000030', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR — Emergency contact required', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000078', 'a1000000-0000-0000-0000-000000000031', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000079', 'a1000000-0000-0000-0000-000000000031', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'COP.2', 'COP.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000080', 'a1000000-0000-0000-0000-000000000031', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000081', 'a1000000-0000-0000-0000-000000000032', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000082', 'a1000000-0000-0000-0000-000000000032', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'COP.2', 'COP.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000083', 'a1000000-0000-0000-0000-000000000032', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000084', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — Address mandatory at registration', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000085', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'ACC.2 — Registration captures address', 'ACC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000086', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000025', 'mandatory', '45 CFR 164.514(b) — Geographic data is PHI identifier #2', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000087', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: address (conditional)', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000088', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Address + Postcode (mandatory)', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000089', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'ESR — Address required for identification', 'ESR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000090', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Address (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000091', 'a1000000-0000-0000-0000-000000000033', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS Patient: address (must-support)', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000092', 'a1000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000093', 'a1000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'ACC.2', 'ACC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000094', 'a1000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000000000025', 'mandatory', 'PHI', 'PHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000095', 'a1000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA: derived from district/state', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000096', 'a1000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Address (mandatory)', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000097', 'a1000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: City', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000098', 'a1000000-0000-0000-0000-000000000034', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS: address.city', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000099', 'a1000000-0000-0000-0000-000000000035', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000100', 'a1000000-0000-0000-0000-000000000035', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: stateCode', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000101', 'a1000000-0000-0000-0000-000000000035', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Address', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000102', 'a1000000-0000-0000-0000-000000000035', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Emirate', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000103', 'a1000000-0000-0000-0000-000000000036', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS: address.country (ISO 3166 Alpha-2/3)', 'ISO 3166', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000104', 'a1000000-0000-0000-0000-000000000037', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.2 — Part of address', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000105', 'a1000000-0000-0000-0000-000000000037', 'f0000000-0000-0000-0000-000000000025', 'mandatory', '45 CFR 164.514(b) — ZIP codes restricted (populations <20k)', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000106', 'a1000000-0000-0000-0000-000000000037', 'f0000000-0000-0000-0000-000000000016', 'mandatory', 'ABHA Profile: pincode', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000107', 'a1000000-0000-0000-0000-000000000037', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: Postcode (mandatory)', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000108', 'a1000000-0000-0000-0000-000000000037', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: Makani Number / PO Box', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000109', 'a1000000-0000-0000-0000-000000000038', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.5 — Financial assessment at registration', 'AAC.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000110', 'a1000000-0000-0000-0000-000000000038', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'ACC.2.4 — Financial information at admission', 'ACC.2.4', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000111', 'a1000000-0000-0000-0000-000000000038', 'f0000000-0000-0000-0000-000000000025', 'mandatory', 'X12 837 — Payer information required for claims', NULL, NULL, NULL),
    ('a5000000-0000-0000-0000-000000000112', 'a1000000-0000-0000-0000-000000000038', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'CBAHI — Insurance mandatory in Saudi Arabia (CCHI law)', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000113', 'a1000000-0000-0000-0000-000000000038', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH — Insurance details mandatory (UAE law)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000114', 'a1000000-0000-0000-0000-000000000039', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'AAC.5', 'AAC.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000115', 'a1000000-0000-0000-0000-000000000039', 'f0000000-0000-0000-0000-000000000001', 'conditional', 'ACC.2.4', 'ACC.2.4', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000116', 'a1000000-0000-0000-0000-000000000039', 'f0000000-0000-0000-0000-000000000025', 'conditional', 'X12 837 Loop 2010BB — Payer Name', NULL, NULL, NULL),
    ('a5000000-0000-0000-0000-000000000117', 'a1000000-0000-0000-0000-000000000039', 'f0000000-0000-0000-0000-000000000027', 'conditional', 'CBAHI — Insurance verification mandatory', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000118', 'a1000000-0000-0000-0000-000000000039', 'f0000000-0000-0000-0000-000000000028', 'conditional', 'NABIDH MDS: Insurance Details', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000119', 'a1000000-0000-0000-0000-000000000040', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'AAC.5', 'AAC.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000120', 'a1000000-0000-0000-0000-000000000040', 'f0000000-0000-0000-0000-000000000025', 'conditional', 'X12 837 — Member ID required for claims', NULL, NULL, NULL),
    ('a5000000-0000-0000-0000-000000000121', 'a1000000-0000-0000-0000-000000000040', 'f0000000-0000-0000-0000-000000000027', 'conditional', 'CBAHI', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000122', 'a1000000-0000-0000-0000-000000000040', 'f0000000-0000-0000-0000-000000000028', 'conditional', 'NABIDH', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000123', 'a1000000-0000-0000-0000-000000000041', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'NABH — Accepted as valid ID proof for registration', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000124', 'a1000000-0000-0000-0000-000000000041', 'f0000000-0000-0000-0000-000000000016', 'conditional', 'ABDM: Primary KYC method for ABHA creation. Verhoeff checksum.', 'ABDM', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000125', 'a1000000-0000-0000-0000-000000000042', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH — ABHA linkage recommended for digital health', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000126', 'a1000000-0000-0000-0000-000000000042', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABDM: 14-digit national health ID (XX-XXXX-XXXX-XXXX). Mandatory for ABDM ecosystem participation.', 'ABDM', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000127', 'a1000000-0000-0000-0000-000000000043', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABDM: Human-readable PHR address (username@abdm). Used for consent and record linking.', 'ABDM', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000128', 'a1000000-0000-0000-0000-000000000044', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH — Accepted as valid ID proof', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000129', 'a1000000-0000-0000-0000-000000000045', 'f0000000-0000-0000-0000-000000000003', 'conditional', 'NABH — Required for international patients', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000130', 'a1000000-0000-0000-0000-000000000045', 'f0000000-0000-0000-0000-000000000001', 'conditional', 'ACC.1 — Identity verification for international patients', 'ACC.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000131', 'a1000000-0000-0000-0000-000000000045', 'f0000000-0000-0000-0000-000000000027', 'conditional', 'CBAHI — Passport for visitors', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000132', 'a1000000-0000-0000-0000-000000000045', 'f0000000-0000-0000-0000-000000000028', 'conditional', 'NABIDH — Passport for non-Emirates ID holders', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000133', 'a1000000-0000-0000-0000-000000000046', 'f0000000-0000-0000-0000-000000000025', 'conditional', '45 CFR 164.514(b) — SSN is PHI identifier #7. Must be encrypted at rest.', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000134', 'a1000000-0000-0000-0000-000000000047', 'f0000000-0000-0000-0000-000000000026', 'conditional', 'PDS: NHS Number (mandatory for all UK patients). 10-digit, modulus 11 check digit.', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000135', 'a1000000-0000-0000-0000-000000000048', 'f0000000-0000-0000-0000-000000000028', 'conditional', 'NABIDH: Emirates ID mandatory for all UAE residents. Links to NABIDH UHID.', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000136', 'a1000000-0000-0000-0000-000000000049', 'f0000000-0000-0000-0000-000000000027', 'conditional', 'CBAHI ESR — National ID/Iqama mandatory for all Saudi patients.', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000137', 'a1000000-0000-0000-0000-000000000050', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'NABH PRE.1 — General consent at registration', 'PRE.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000138', 'a1000000-0000-0000-0000-000000000050', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'JCI PFR.5.1 — General consent for treatment must be obtained', 'PFR.5.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000139', 'a1000000-0000-0000-0000-000000000050', 'f0000000-0000-0000-0000-000000000025', 'mandatory', '45 CFR 164.508 — Authorization for use/disclosure of PHI', 'CFR 164.508', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000140', 'a1000000-0000-0000-0000-000000000050', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'CBAHI — Consent at admission mandatory', 'CBAHI', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000141', 'a1000000-0000-0000-0000-000000000050', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'GDPR Art. 6/9 — Consent for health data processing', 'GDPR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000142', 'a1000000-0000-0000-0000-000000000051', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABDM Consent Framework: consent_code=abha-enrollment, version=1.4. Required for ABHA linking.', 'ABDM', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000143', 'a1000000-0000-0000-0000-000000000052', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH — Research ethics committee requirements', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000144', 'a1000000-0000-0000-0000-000000000052', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'JCI COP.9 — Research consent separate from treatment consent', 'COP.9', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000145', 'a1000000-0000-0000-0000-000000000052', 'f0000000-0000-0000-0000-000000000025', 'recommended', '45 CFR 46 — Common Rule for human subjects research', 'CFR 46', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000146', 'a1000000-0000-0000-0000-000000000052', 'f0000000-0000-0000-0000-000000000029', 'recommended', 'GDPR Art. 9(2)(j) — Research consent', 'GDPR', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000147', 'a1000000-0000-0000-0000-000000000053', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.5 — Patient categorization at registration', 'AAC.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000148', 'a1000000-0000-0000-0000-000000000053', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'ACC.2 — Registration process standardized', 'ACC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000149', 'a1000000-0000-0000-0000-000000000054', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.1 — Registration and admission process documented', 'AAC.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000150', 'a1000000-0000-0000-0000-000000000054', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'ACC.1 — Standardized admission criteria', 'ACC.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000151', 'a1000000-0000-0000-0000-000000000055', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'NABH — MLC documentation per IPC/CrPC', 'NABH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000152', 'a1000000-0000-0000-0000-000000000056', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'AAC.1 — UHID generated at end of registration', 'AAC.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000153', 'a1000000-0000-0000-0000-000000000056', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'IPSG.1 — Unique MRN for patient identification', 'IPSG.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000154', 'a1000000-0000-0000-0000-000000000056', 'f0000000-0000-0000-0000-000000000025', 'mandatory', 'X12 837 — Patient Account Number', NULL, NULL, NULL),
    ('a5000000-0000-0000-0000-000000000155', 'a1000000-0000-0000-0000-000000000056', 'f0000000-0000-0000-0000-000000000026', 'mandatory', 'PDS: NHS Number', 'PDS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000156', 'a1000000-0000-0000-0000-000000000056', 'f0000000-0000-0000-0000-000000000027', 'mandatory', 'CBAHI QM.17 — MRN', 'QM.17', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000157', 'a1000000-0000-0000-0000-000000000056', 'f0000000-0000-0000-0000-000000000028', 'mandatory', 'NABIDH MDS: MRN (mandatory)', 'NABIDH', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000158', 'a1000000-0000-0000-0000-000000000056', 'f0000000-0000-0000-0000-000000000029', 'mandatory', 'IPS: identifier', 'IPS', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000159', 'a1000000-0000-0000-0000-000000000057', 'f0000000-0000-0000-0000-000000000003', 'recommended', 'AAC.2 — Photograph recommended for patient identification', 'AAC.2', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000160', 'a1000000-0000-0000-0000-000000000057', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'IPSG.1 — Visual identification supported', 'IPSG.1', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000161', 'a1000000-0000-0000-0000-000000000057', 'f0000000-0000-0000-0000-000000000025', 'recommended', '45 CFR 164.514(b) — Full face photos are PHI identifier #17', 'CFR 164.514', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000162', 'a1000000-0000-0000-0000-000000000057', 'f0000000-0000-0000-0000-000000000016', 'recommended', 'ABHA Profile: profilePhoto (optional, base64)', 'ABHA', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000163', 'a1000000-0000-0000-0000-000000000058', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'NABH COP.6 — Allergy documentation', 'COP.6', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000164', 'a1000000-0000-0000-0000-000000000058', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'JCI IPSG.5 — Medication safety includes allergy check', 'IPSG.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000165', 'a1000000-0000-0000-0000-000000000059', 'f0000000-0000-0000-0000-000000000003', 'mandatory', 'NABH COP.6', 'COP.6', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000166', 'a1000000-0000-0000-0000-000000000059', 'f0000000-0000-0000-0000-000000000001', 'mandatory', 'JCI IPSG.5', 'IPSG.5', NULL, NULL),
    ('a5000000-0000-0000-0000-000000000167', 'a1000000-0000-0000-0000-000000000060', 'f0000000-0000-0000-0000-000000000001', 'recommended', 'JCI IPSG.5 — Severity affects clinical alerts', 'IPSG.5', NULL, NULL);

-- Module form link
INSERT INTO module_form_links (module_code, form_id, context) VALUES
    ('registration', 'a2000000-0000-0000-0000-000000000001', 'primary');
