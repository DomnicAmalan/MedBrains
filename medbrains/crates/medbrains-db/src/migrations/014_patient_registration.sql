-- MedBrains HMS — Patient Registration Module
-- Expands the patients table with full demographics, adds normalized sub-resource
-- tables (identifiers, addresses, contacts, insurance, allergies, consents,
-- documents, ABHA links, merge history), creates master lookup tables, and seeds
-- global default master data.
--
-- Prerequisites: migrations 001 (patients, gender, patient_category),
--                003 (geo_countries, geo_states, geo_districts, facilities, users).
--
-- RFC reference: RFCs/modules/RFC-MODULE-patient-registration.md

-- ============================================================
-- 1. Extend existing enum types
-- ============================================================

ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'esi';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'corporate';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'free';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'charity';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'research_subject';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'staff_dependent';

-- ============================================================
-- 2. New enum types
-- ============================================================

CREATE TYPE marital_status AS ENUM (
    'single', 'married', 'divorced', 'widowed', 'separated',
    'domestic_partner', 'unknown'
);

CREATE TYPE registration_type AS ENUM (
    'new', 'revisit', 'transfer_in', 'referral', 'emergency',
    'camp', 'telemedicine', 'pre_registration'
);

CREATE TYPE registration_source AS ENUM (
    'walk_in', 'phone', 'online_portal', 'mobile_app', 'kiosk',
    'referral', 'ambulance', 'camp', 'telemedicine'
);

CREATE TYPE address_type AS ENUM (
    'current', 'permanent', 'correspondence', 'workplace', 'temporary'
);

CREATE TYPE identifier_type AS ENUM (
    'aadhaar', 'pan', 'voter_id', 'driving_license', 'passport',
    'ration_card', 'ssn', 'nhs_number', 'medicare_number',
    'national_id', 'birth_certificate', 'employee_id',
    'disability_certificate', 'abha', 'abha_address',
    'emirates_id', 'iqama', 'uhid_external'
);

CREATE TYPE blood_group AS ENUM (
    'a_positive', 'a_negative', 'b_positive', 'b_negative',
    'ab_positive', 'ab_negative', 'o_positive', 'o_negative', 'unknown'
);

CREATE TYPE allergy_type AS ENUM (
    'drug', 'food', 'environmental', 'latex', 'contrast_dye',
    'biological', 'other'
);

CREATE TYPE allergy_severity AS ENUM (
    'mild', 'moderate', 'severe', 'life_threatening'
);

CREATE TYPE consent_type AS ENUM (
    'general_treatment', 'data_sharing', 'abdm_linking',
    'research_participation', 'sms_communication', 'email_communication',
    'photography', 'advance_directive', 'organ_donation', 'hie_participation'
);

CREATE TYPE consent_status AS ENUM (
    'granted', 'denied', 'withdrawn', 'pending'
);

CREATE TYPE consent_capture_mode AS ENUM (
    'paper_signed', 'digital_signature', 'biometric',
    'otp_verified', 'verbal_recorded'
);

CREATE TYPE financial_class AS ENUM (
    'self_pay', 'insurance', 'government_scheme', 'corporate',
    'charity', 'research'
);

-- ============================================================
-- 3. ALTER patients table — add ~35 new columns
-- ============================================================

ALTER TABLE patients
    -- Name extensions (FHIR Patient.name)
    ADD COLUMN IF NOT EXISTS prefix              TEXT,
    ADD COLUMN IF NOT EXISTS middle_name          TEXT,
    ADD COLUMN IF NOT EXISTS suffix               TEXT,
    ADD COLUMN IF NOT EXISTS full_name_local      TEXT,       -- name in local script (Hindi, Tamil, etc.)

    -- Family information
    ADD COLUMN IF NOT EXISTS father_name          TEXT,
    ADD COLUMN IF NOT EXISTS mother_name          TEXT,
    ADD COLUMN IF NOT EXISTS spouse_name          TEXT,
    ADD COLUMN IF NOT EXISTS guardian_name         TEXT,
    ADD COLUMN IF NOT EXISTS guardian_relation     TEXT,

    -- DOB / age
    ADD COLUMN IF NOT EXISTS is_dob_estimated     BOOLEAN NOT NULL DEFAULT false,

    -- Sex / gender (FHIR Patient.gender maps to biological_sex)
    ADD COLUMN IF NOT EXISTS biological_sex       gender,     -- clinical sex; keep existing 'gender' column for backward compat
    ADD COLUMN IF NOT EXISTS gender_identity      TEXT,        -- self-reported gender identity (free-text)

    -- Demographics
    ADD COLUMN IF NOT EXISTS marital_status       marital_status,
    ADD COLUMN IF NOT EXISTS religion             TEXT,
    ADD COLUMN IF NOT EXISTS nationality_id       UUID REFERENCES geo_countries(id),
    ADD COLUMN IF NOT EXISTS preferred_language    TEXT,
    ADD COLUMN IF NOT EXISTS birth_place           TEXT,

    -- Clinical quick-reference
    ADD COLUMN IF NOT EXISTS blood_group          blood_group,
    ADD COLUMN IF NOT EXISTS blood_group_verified BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS no_known_allergies   BOOLEAN,     -- NKDA flag; NULL = not yet assessed

    -- Socioeconomic
    ADD COLUMN IF NOT EXISTS occupation           TEXT,
    ADD COLUMN IF NOT EXISTS education_level      TEXT,

    -- Contact extensions
    ADD COLUMN IF NOT EXISTS phone_secondary      TEXT,
    ADD COLUMN IF NOT EXISTS preferred_contact_method TEXT,

    -- Registration metadata
    ADD COLUMN IF NOT EXISTS registration_type    registration_type NOT NULL DEFAULT 'new',
    ADD COLUMN IF NOT EXISTS registration_source  registration_source,
    ADD COLUMN IF NOT EXISTS registered_by        UUID REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS registered_at_facility UUID REFERENCES facilities(id),

    -- Financial
    ADD COLUMN IF NOT EXISTS financial_class      financial_class NOT NULL DEFAULT 'self_pay',

    -- Medico-legal
    ADD COLUMN IF NOT EXISTS is_medico_legal      BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS mlc_number           TEXT,        -- required when is_medico_legal = true

    -- Unknown / unidentified patient
    ADD COLUMN IF NOT EXISTS is_unknown_patient   BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS temporary_name       TEXT,        -- e.g. "Unknown Male #47"

    -- VIP
    ADD COLUMN IF NOT EXISTS is_vip               BOOLEAN NOT NULL DEFAULT false,

    -- Deceased
    ADD COLUMN IF NOT EXISTS is_deceased          BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS deceased_date        TIMESTAMPTZ,

    -- Photo
    ADD COLUMN IF NOT EXISTS photo_url            TEXT,
    ADD COLUMN IF NOT EXISTS photo_captured_at    TIMESTAMPTZ,

    -- Data quality
    ADD COLUMN IF NOT EXISTS data_quality_score   SMALLINT,    -- 0-100 completeness score

    -- Visit tracking (denormalized for quick display)
    ADD COLUMN IF NOT EXISTS last_visit_date      DATE,
    ADD COLUMN IF NOT EXISTS total_visits         INT NOT NULL DEFAULT 0,

    -- MPI merge state
    ADD COLUMN IF NOT EXISTS is_merged            BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS merged_into_patient_id UUID REFERENCES patients(id),

    -- Legacy / migration
    ADD COLUMN IF NOT EXISTS source_system        TEXT,        -- external system name for migrated records
    ADD COLUMN IF NOT EXISTS legacy_id            TEXT;        -- MRN/ID from source system

-- ============================================================
-- 4. New tables — Patient sub-resources
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Patient Identifiers (Government IDs, ABHA, external MRNs)
-- ------------------------------------------------------------

CREATE TABLE patient_identifiers (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    id_type             identifier_type NOT NULL,
    id_number           TEXT NOT NULL,
    id_number_hash      TEXT,                -- SHA-256 hash for indexed lookup (Aadhaar never stored raw)
    issuing_authority   TEXT,
    issuing_country_id  UUID REFERENCES geo_countries(id),
    valid_from          DATE,
    valid_until         DATE,
    is_verified         BOOLEAN NOT NULL DEFAULT false,
    verified_at         TIMESTAMPTZ,
    verification_mode   TEXT,                -- how verification was done (otp, manual, kyc, etc.)
    document_url        TEXT,                -- link to scanned document
    is_primary          BOOLEAN NOT NULL DEFAULT false,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, patient_id, id_type, id_number)
);

ALTER TABLE patient_identifiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_identifiers ON patient_identifiers
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_identifiers_patient ON patient_identifiers(tenant_id, patient_id);
CREATE INDEX idx_patient_identifiers_hash ON patient_identifiers(tenant_id, id_type, id_number_hash);
CREATE INDEX idx_patient_identifiers_number ON patient_identifiers(tenant_id, id_type, id_number);

-- ------------------------------------------------------------
-- 4.2 Patient Addresses
-- ------------------------------------------------------------

CREATE TABLE patient_addresses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    address_type    address_type NOT NULL,
    address_line1   TEXT NOT NULL,
    address_line2   TEXT,
    village_town    TEXT,
    city            TEXT NOT NULL,
    district_id     UUID REFERENCES geo_districts(id),
    state_id        UUID REFERENCES geo_states(id),
    country_id      UUID NOT NULL REFERENCES geo_countries(id),
    postal_code     TEXT NOT NULL,
    latitude        NUMERIC(10,7),
    longitude       NUMERIC(10,7),
    is_primary      BOOLEAN NOT NULL DEFAULT false,
    valid_from      DATE,
    valid_until     DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, patient_id, address_type)
);

ALTER TABLE patient_addresses ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_addresses ON patient_addresses
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_addresses_patient ON patient_addresses(tenant_id, patient_id);

-- ------------------------------------------------------------
-- 4.3 Patient Contacts (Emergency + Next of Kin)
-- ------------------------------------------------------------

CREATE TABLE patient_contacts (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    contact_name            TEXT NOT NULL,
    relation                TEXT NOT NULL,
    phone                   TEXT NOT NULL,
    phone_alt               TEXT,
    email                   TEXT,
    address                 JSONB,
    is_emergency_contact    BOOLEAN NOT NULL DEFAULT false,
    is_next_of_kin          BOOLEAN NOT NULL DEFAULT false,
    is_legal_guardian       BOOLEAN NOT NULL DEFAULT false,
    priority                INT NOT NULL DEFAULT 1,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_contacts ON patient_contacts
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_contacts_patient ON patient_contacts(tenant_id, patient_id);

-- ------------------------------------------------------------
-- 4.4 Patient Insurance Policies
-- ------------------------------------------------------------

CREATE TABLE patient_insurance (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    insurance_provider      TEXT NOT NULL,
    policy_number           TEXT NOT NULL,
    group_number            TEXT,
    member_id               TEXT,
    plan_name               TEXT,
    policy_holder_name      TEXT,
    policy_holder_relation  TEXT,
    valid_from              DATE NOT NULL,
    valid_until             DATE NOT NULL,
    sum_insured             NUMERIC(14,2),
    tpa_name                TEXT,
    tpa_id                  TEXT,
    coverage_type           TEXT,          -- individual, family, group
    priority                INT NOT NULL DEFAULT 1,  -- 1 = primary, 2 = secondary
    is_active               BOOLEAN NOT NULL DEFAULT true,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_insurance ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_insurance ON patient_insurance
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_insurance_patient ON patient_insurance(tenant_id, patient_id);

-- ------------------------------------------------------------
-- 4.5 Patient Allergies
-- ------------------------------------------------------------

CREATE TABLE patient_allergies (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    allergy_type    allergy_type NOT NULL,
    allergen_name   TEXT NOT NULL,
    allergen_code   TEXT,            -- SNOMED CT or RxNorm code for interoperability
    reaction        TEXT,
    severity        allergy_severity,
    onset_date      DATE,
    reported_by     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_allergies ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_allergies ON patient_allergies
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_allergies_patient ON patient_allergies(tenant_id, patient_id);

-- ------------------------------------------------------------
-- 4.6 Patient Consents
-- ------------------------------------------------------------

CREATE TABLE patient_consents (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    consent_type            consent_type NOT NULL,
    consent_status          consent_status NOT NULL DEFAULT 'pending',
    consent_date            TIMESTAMPTZ NOT NULL DEFAULT now(),
    consent_version         TEXT,          -- version of the consent form template
    consented_by            TEXT NOT NULL, -- name of person giving consent
    consented_by_relation   TEXT,          -- e.g. "self", "father", "legal_guardian"
    witness_name            TEXT,
    capture_mode            consent_capture_mode NOT NULL,
    document_url            TEXT,          -- link to signed consent document
    valid_until             DATE,
    notes                   TEXT,
    revoked_at              TIMESTAMPTZ,
    revoked_reason          TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_consents ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_consents ON patient_consents
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_consents_patient ON patient_consents(tenant_id, patient_id);

-- ------------------------------------------------------------
-- 4.7 Patient Merge History (MPI Audit Trail)
-- ------------------------------------------------------------

CREATE TABLE patient_merge_history (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    surviving_patient_id    UUID NOT NULL REFERENCES patients(id),
    merged_patient_id       UUID NOT NULL REFERENCES patients(id),
    merged_by               UUID NOT NULL REFERENCES users(id),
    merge_reason            TEXT NOT NULL,
    merge_data              JSONB NOT NULL DEFAULT '{}',  -- full snapshot of merged record before merge
    unmerged_at             TIMESTAMPTZ,
    unmerged_by             UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_merge_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_merge_history ON patient_merge_history
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ------------------------------------------------------------
-- 4.8 Patient Documents (ID proofs, photos, consent forms, referral letters)
-- ------------------------------------------------------------

CREATE TABLE patient_documents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    document_type   TEXT NOT NULL,    -- id_proof, consent_form, referral_letter, photo, report
    document_name   TEXT NOT NULL,
    file_url        TEXT NOT NULL,
    file_size       BIGINT,
    mime_type       TEXT,
    uploaded_by     UUID REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_documents ON patient_documents
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_documents_patient ON patient_documents(tenant_id, patient_id);

-- ------------------------------------------------------------
-- 4.9 ABHA Linking State (per-patient ABDM integration state)
-- ------------------------------------------------------------

CREATE TABLE patient_abha_links (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    abha_number     TEXT NOT NULL,        -- 14-digit XX-XXXX-XXXX-XXXX
    abha_address    TEXT,                 -- username@abdm
    linking_token   TEXT,                 -- ABDM linking token, valid 30 minutes
    token_expiry    TIMESTAMPTZ,
    kyc_verified    BOOLEAN NOT NULL DEFAULT false,
    status          TEXT NOT NULL DEFAULT 'linked',  -- linked, unlinked, pending
    linked_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    unlinked_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, patient_id),
    UNIQUE (tenant_id, abha_number)
);

ALTER TABLE patient_abha_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_abha_links ON patient_abha_links
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_abha_links_abha ON patient_abha_links(abha_number);

-- ============================================================
-- 5. Master tables
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Religion Master (tenant-configurable; NULL tenant_id = global default)
-- ------------------------------------------------------------

CREATE TABLE master_religions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID REFERENCES tenants(id),   -- NULL = global default
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (tenant_id, code)
);

-- No RLS on master_religions: rows with tenant_id = NULL are global defaults
-- visible to all tenants. Tenant-specific rows are filtered in application queries.

-- ------------------------------------------------------------
-- 5.2 Occupation Master (tenant-configurable; NULL tenant_id = global default)
-- ------------------------------------------------------------

CREATE TABLE master_occupations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (tenant_id, code)
);

-- ------------------------------------------------------------
-- 5.3 Relation Master (for contacts, guardians; NULL tenant_id = global default)
-- ------------------------------------------------------------

CREATE TABLE master_relations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (tenant_id, code)
);

-- ------------------------------------------------------------
-- 5.4 Insurance Provider Master (per-tenant, RLS enforced)
-- ------------------------------------------------------------

CREATE TABLE master_insurance_providers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    provider_type   TEXT NOT NULL,        -- private, government, tpa
    contact_phone   TEXT,
    contact_email   TEXT,
    website         TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

ALTER TABLE master_insurance_providers ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_master_insurance_providers ON master_insurance_providers
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- 6. Indexes for MPI matching & fuzzy search
-- ============================================================

-- pg_trgm extension for trigram-based fuzzy matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Trigram indexes for fuzzy name search (supports % and similarity())
CREATE INDEX idx_patients_first_name_trgm ON patients USING gin (first_name gin_trgm_ops);
CREATE INDEX idx_patients_last_name_trgm ON patients USING gin (last_name gin_trgm_ops);

-- DOB index for MPI blocking phase and date range queries
CREATE INDEX idx_patients_dob ON patients(tenant_id, date_of_birth);

-- Phone index for MPI blocking (exact match on primary phone)
-- Note: idx_patients_phone already exists from 001 on (tenant_id, phone)

-- Composite blocking index for MPI candidate selection:
-- Blocks on (tenant_id, DOB, first 3 chars of first_name)
CREATE INDEX idx_patients_mpi_block ON patients(tenant_id, date_of_birth, substring(first_name, 1, 3));

-- ============================================================
-- 7. Updated-at triggers for new tables
-- ============================================================

CREATE TRIGGER trg_patient_identifiers_updated_at BEFORE UPDATE ON patient_identifiers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patient_addresses_updated_at BEFORE UPDATE ON patient_addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patient_contacts_updated_at BEFORE UPDATE ON patient_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patient_insurance_updated_at BEFORE UPDATE ON patient_insurance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patient_allergies_updated_at BEFORE UPDATE ON patient_allergies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patient_consents_updated_at BEFORE UPDATE ON patient_consents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patient_abha_links_updated_at BEFORE UPDATE ON patient_abha_links
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Note: patient_merge_history and patient_documents do not have updated_at columns
-- (merge history is append-only; documents are immutable once uploaded).

-- ============================================================
-- 8. Seed global master data (tenant_id = NULL)
-- ============================================================

-- ------------------------------------------------------------
-- 8.1 Religions (India default — 13 values, RFC section 7.1)
-- ------------------------------------------------------------

INSERT INTO master_religions (tenant_id, code, name, sort_order) VALUES
    (NULL, 'hindu',              'Hindu',                1),
    (NULL, 'muslim',             'Muslim',               2),
    (NULL, 'christian',          'Christian',             3),
    (NULL, 'sikh',               'Sikh',                 4),
    (NULL, 'buddhist',           'Buddhist',             5),
    (NULL, 'jain',               'Jain',                 6),
    (NULL, 'jewish',             'Jewish',               7),
    (NULL, 'parsi',              'Parsi',                8),
    (NULL, 'bahai',              'Bahai',                9),
    (NULL, 'tribal_religion',    'Tribal Religion',      10),
    (NULL, 'no_religion',        'No Religion',          11),
    (NULL, 'other',              'Other',                12),
    (NULL, 'prefer_not_to_say',  'Prefer Not to Say',    13);

-- ------------------------------------------------------------
-- 8.2 Relations (23 values, RFC section 7.2)
-- ------------------------------------------------------------

INSERT INTO master_relations (tenant_id, code, name, sort_order) VALUES
    (NULL, 'spouse',                'Spouse',               1),
    (NULL, 'father',                'Father',               2),
    (NULL, 'mother',                'Mother',               3),
    (NULL, 'son',                   'Son',                  4),
    (NULL, 'daughter',              'Daughter',             5),
    (NULL, 'brother',               'Brother',              6),
    (NULL, 'sister',                'Sister',               7),
    (NULL, 'grandfather',           'Grandfather',          8),
    (NULL, 'grandmother',           'Grandmother',          9),
    (NULL, 'grandson',              'Grandson',             10),
    (NULL, 'granddaughter',         'Granddaughter',        11),
    (NULL, 'uncle',                 'Uncle',                12),
    (NULL, 'aunt',                  'Aunt',                 13),
    (NULL, 'nephew',                'Nephew',               14),
    (NULL, 'niece',                 'Niece',                15),
    (NULL, 'cousin',                'Cousin',               16),
    (NULL, 'friend',                'Friend',               17),
    (NULL, 'neighbor',              'Neighbor',             18),
    (NULL, 'employer',              'Employer',             19),
    (NULL, 'colleague',             'Colleague',            20),
    (NULL, 'legal_guardian',        'Legal Guardian',        21),
    (NULL, 'power_of_attorney',     'Power of Attorney',    22),
    (NULL, 'other',                 'Other',                23);

-- ------------------------------------------------------------
-- 8.3 Occupations (ISCO-08 based — 29 values, RFC section 7.3)
-- ------------------------------------------------------------

INSERT INTO master_occupations (tenant_id, code, name, sort_order) VALUES
    (NULL, 'healthcare_worker',  'Healthcare Worker',     1),
    (NULL, 'doctor',             'Doctor',                2),
    (NULL, 'nurse',              'Nurse',                 3),
    (NULL, 'paramedic',          'Paramedic',             4),
    (NULL, 'teacher',            'Teacher',               5),
    (NULL, 'professor',          'Professor',             6),
    (NULL, 'researcher',         'Researcher',            7),
    (NULL, 'engineer',           'Engineer',              8),
    (NULL, 'architect',          'Architect',             9),
    (NULL, 'lawyer',             'Lawyer',                10),
    (NULL, 'accountant',         'Accountant',            11),
    (NULL, 'farmer',             'Farmer',                12),
    (NULL, 'laborer',            'Laborer',               13),
    (NULL, 'driver',             'Driver',                14),
    (NULL, 'domestic_worker',    'Domestic Worker',       15),
    (NULL, 'business_owner',     'Business Owner',        16),
    (NULL, 'shopkeeper',         'Shopkeeper',            17),
    (NULL, 'trader',             'Trader',                18),
    (NULL, 'government_employee','Government Employee',   19),
    (NULL, 'military',           'Military',              20),
    (NULL, 'police',             'Police',                21),
    (NULL, 'student',            'Student',               22),
    (NULL, 'retired',            'Retired',               23),
    (NULL, 'homemaker',          'Homemaker',             24),
    (NULL, 'unemployed',         'Unemployed',            25),
    (NULL, 'it_professional',    'IT Professional',       26),
    (NULL, 'banker',             'Banker',                27),
    (NULL, 'journalist',         'Journalist',            28),
    (NULL, 'artist',             'Artist',                29),
    (NULL, 'other',              'Other',                 30);
