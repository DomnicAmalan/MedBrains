# RFC-MODULE: Patient Registration

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Priority** | P1 (Core Clinical) |
| **Platform** | Web, Mobile |
| **Depends On** | Auth, Onboarding & Setup |
| **Blocks** | OPD, IPD, Lab, Billing, Pharmacy, Radiology, Emergency — all clinical modules |
| **Features** | ~65 (see Excel: Clinical → Patient Mgmt → Registration) |
| **Excel Sheet** | Clinical |

---

## 1. Overview

Patient Registration is the gateway to all clinical workflows. Every encounter (OPD visit, IPD admission, lab order, billing invoice) begins with a registered patient identified by a **UHID** (Unique Hospital Identifier).

### In Scope

1. **New patient registration** — capture demographics, identifiers, contacts, address, insurance, consent
2. **ABHA integration** — verify/create/link Ayushman Bharat Health Account (14-digit national health ID)
3. **Master Patient Index (MPI)** — duplicate detection via probabilistic matching before registration
4. **Quick registration** — emergency/walk-in minimal-field registration
5. **Patient search** — by UHID, ABHA, name, phone, DOB (full-text + fuzzy)
6. **Patient profile management** — view/edit demographics, add identifiers, manage contacts
7. **Patient merge** — merge duplicate records with full audit trail
8. **Unknown/unidentified patient** — temporary identity for unconscious/trauma patients
9. **Patient photo capture** — webcam capture at registration counter
10. **Consent capture** — general treatment consent, ABDM data sharing consent
11. **Wristband printing** — barcode wristband with UHID + name + DOB
12. **Patient card printing** — plastic/paper card with UHID, QR code, basic demographics
13. **Revisit/follow-up registration** — link new encounter to existing patient
14. **Transfer-in registration** — patient arriving from another facility with external MRN

### Out of Scope (Separate Modules)

- OPD visit creation (OPD module)
- IPD admission workflow (IPD module)
- Billing & invoicing (Billing module)
- Clinical assessments, vitals, prescriptions (OPD/IPD modules)
- ABDM Health Information Exchange (Phase 2 — HIP/HIU/consent manager)
- Biometric enrollment (Phase 3)
- Online self-registration portal (Phase 3)

---

## 2. Regulatory Standards Compliance

This module is designed to satisfy requirements from **8 major accreditation frameworks** simultaneously. A hospital using MedBrains can seek accreditation from any of these bodies without data model changes.

### 2.1 Standards Cross-Reference

| Requirement | NABH (IN) | JCI | HIPAA (US) | NHS (UK) | ACSQHC (AU) | EU/EHDS | CBAHI (SA) | UAE DOH/DHA |
|---|---|---|---|---|---|---|---|---|
| Minimum 2 identifiers | AAC.2 | IPSG.1 | — | — | — | — | ESR | ESR |
| Unique system ID (UHID/MRN) | AAC.1 | IPSG.1 | X12 837 | PDS | HI Act | IPS | QM.17 | NABIDH |
| National health ID | ABDM | — | SSN | NHS No. | IHI | eIDAS | NationalID | Emirates ID |
| Emergency contact | AAC.2 | COP.2 | — | — | — | — | ESR | — |
| Consent at registration | PRE.1 | PFR.5 | Privacy Rule | — | — | GDPR | ESR | — |
| Photo identification | AAC.2 | IPSG.1 | — | — | — | — | — | — |
| Wristband (inpatient) | AAC.2 | IPSG.1 | — | — | NSQHS 1 | — | ESR | — |
| Unknown patient protocol | AAC.2 | ACC.1 | — | — | — | — | — | — |
| MLC documentation | IPC/CrPC | — | — | — | — | — | — | — |
| Data encryption (PHI) | — | — | Security Rule | — | — | GDPR | — | — |

### 2.2 FHIR R4 Alignment

All patient data maps to the **HL7 FHIR R4 Patient resource** (required by ABDM for health record exchange):

| FHIR Element | MedBrains Field | Cardinality |
|---|---|---|
| `Patient.identifier` | `patient_identifiers` table | 1..* (UHID mandatory) |
| `Patient.name` | `first_name`, `middle_name`, `last_name`, `prefix`, `suffix` | 1..* |
| `Patient.telecom` | `phone_primary`, `email` | 0..* |
| `Patient.gender` | `biological_sex` | 0..1 |
| `Patient.birthDate` | `date_of_birth` | 0..1 |
| `Patient.address` | `patient_addresses` table | 0..* |
| `Patient.contact` | `patient_contacts` table | 0..* |
| `Patient.communication` | `preferred_language` | 0..* |
| `Patient.photo` | `photo_url` | 0..* |
| `Patient.managingOrganization` | `registered_at_facility` | 0..1 |
| `Patient.link` | `patient_merge_history` | 0..* |
| `Patient.deceased[x]` | `is_deceased`, `deceased_date` | 0..1 |

### 2.3 ABDM / ABHA Integration

**ABHA** (Ayushman Bharat Health Account) is India's 14-digit national health identifier under the ABDM ecosystem.

#### Integration Modes

| Mode | Trigger | Flow |
|---|---|---|
| **QR Scan** (preferred) | Patient shows ABHA QR on phone/card | Scan → `POST /v3/hip/patient/profile/share` → auto-populate demographics |
| **Facility QR** | Patient scans hospital QR with ABHA app | Hospital displays QR → patient shares profile via callback |
| **ABHA Number + OTP** | Patient provides 14-digit number verbally | `auth/fetch-modes` → `auth/init` → OTP verify → `auth/confirm` → profile |
| **ABHA Address Search** | Patient provides `username@abdm` | `patients/find` → auth flow → profile |
| **Create New ABHA (Aadhaar)** | Patient has no ABHA, has Aadhaar | `enrollment/request/otp` → Aadhaar OTP → `enrollment/enrol/byAadhaar` |
| **Create New ABHA (Mobile)** | No ABHA, no Aadhaar | `enrollment/enrol/byMobile` → enrollment number (needs KYC later) |
| **Skip ABHA** | Patient declines | Register with UHID only, ABHA can be linked later |

#### ABDM API Endpoints (Hospital Must Implement)

| Category | Endpoint | Method | Purpose |
|---|---|---|---|
| **Auth** | `/gateway/v0.5/sessions` | POST | Get JWT session token |
| **Enrollment** | `/v3/enrollment/request/otp` | POST | Aadhaar OTP for new ABHA |
| **Enrollment** | `/v3/enrollment/enrol/byAadhaar` | POST | Complete Aadhaar enrollment |
| **Enrollment** | `/v3/enrollment/enrol/byMobile` | POST | Mobile-only enrollment |
| **Verification** | `/v0.5/users/auth/fetch-modes` | POST | Get auth modes for existing ABHA |
| **Verification** | `/v0.5/users/auth/init` | POST | Initiate auth (triggers OTP) |
| **Verification** | `/v0.5/users/auth/confirm` | POST | Confirm OTP, get profile + linking token |
| **Profile Share** | `/v3/hip/patient/profile/share` | POST | Receive profile via QR scan |
| **Profile** | `/v3/profile/account` | GET | Fetch ABHA profile |
| **Care Context** | `/v0.5/links/context/notify` | POST | Link care context to ABHA (post-encounter) |
| **Discovery** | `/v0.5/care-contexts/discover` | POST | Respond to patient-initiated discovery |

#### ABDM Data Fields Received

| Field | ABDM Name | MedBrains Mapping |
|---|---|---|
| ABHA Number (14-digit) | `healthIdNumber` | `patient_identifiers.id_number` (type=`abha`) |
| ABHA Address | `healthId` | `patient_identifiers.id_number` (type=`abha_address`) |
| First Name | `firstName` | `patients.first_name` |
| Middle Name | `middleName` | `patients.middle_name` |
| Last Name | `lastName` | `patients.last_name` |
| Gender | `gender` (M/F/O) | `patients.biological_sex` |
| Year of Birth | `yearOfBirth` | `patients.date_of_birth` (may be partial) |
| Month of Birth | `monthOfBirth` | `patients.date_of_birth` |
| Day of Birth | `dayOfBirth` | `patients.date_of_birth` |
| Mobile | `mobile` | `patients.phone_primary` |
| Email | `email` | `patients.email` |
| Address | `address` | `patient_addresses` |
| State Code | `stateCode` | `patient_addresses.state_id` (map ABDM code → geo_states) |
| District Code | `districtCode` | `patient_addresses.district_id` |
| PIN Code | `pincode` | `patient_addresses.postal_code` |
| Photo | `profilePhoto` (Base64) | `patients.photo_url` (decode → store) |
| KYC Verified | `kycVerified` | `patient_identifiers.is_verified` |

---

## 3. Database Schema

### 3.1 Migration: `003_patient_registration.sql`

#### New Enums

```sql
-- Extend existing gender enum (already exists: male, female, other, unknown)

-- Extend patient_category (add new values)
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'esi';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'corporate';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'free';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'charity';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'research_subject';
ALTER TYPE patient_category ADD VALUE IF NOT EXISTS 'staff_dependent';

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
```

#### ALTER `patients` Table (Expand Core Fields)

```sql
ALTER TABLE patients
    ADD COLUMN prefix TEXT,
    ADD COLUMN middle_name TEXT,
    ADD COLUMN suffix TEXT,
    ADD COLUMN full_name_local TEXT,
    ADD COLUMN father_name TEXT,
    ADD COLUMN mother_name TEXT,
    ADD COLUMN spouse_name TEXT,
    ADD COLUMN guardian_name TEXT,
    ADD COLUMN guardian_relation TEXT,
    ADD COLUMN is_dob_estimated BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN biological_sex gender,  -- rename concept; keep column gender for now
    ADD COLUMN gender_identity TEXT,
    ADD COLUMN marital_status marital_status,
    ADD COLUMN religion TEXT,
    ADD COLUMN nationality_id UUID REFERENCES geo_countries(id),
    ADD COLUMN preferred_language TEXT,
    ADD COLUMN birth_place TEXT,
    ADD COLUMN blood_group blood_group,
    ADD COLUMN blood_group_verified BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN no_known_allergies BOOLEAN,
    ADD COLUMN occupation TEXT,
    ADD COLUMN education_level TEXT,
    ADD COLUMN phone_secondary TEXT,
    ADD COLUMN preferred_contact_method TEXT,
    ADD COLUMN registration_type registration_type NOT NULL DEFAULT 'new',
    ADD COLUMN registration_source registration_source,
    ADD COLUMN registered_by UUID REFERENCES users(id),
    ADD COLUMN registered_at_facility UUID REFERENCES facilities(id),
    ADD COLUMN financial_class financial_class NOT NULL DEFAULT 'self_pay',
    ADD COLUMN is_medico_legal BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN mlc_number TEXT,
    ADD COLUMN is_unknown_patient BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN temporary_name TEXT,
    ADD COLUMN is_vip BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN is_deceased BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN deceased_date TIMESTAMPTZ,
    ADD COLUMN photo_url TEXT,
    ADD COLUMN photo_captured_at TIMESTAMPTZ,
    ADD COLUMN data_quality_score SMALLINT,
    ADD COLUMN last_visit_date DATE,
    ADD COLUMN total_visits INT NOT NULL DEFAULT 0,
    ADD COLUMN is_merged BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN merged_into_patient_id UUID REFERENCES patients(id),
    ADD COLUMN source_system TEXT,
    ADD COLUMN legacy_id TEXT;
```

#### New Tables

```sql
-- Patient Identifiers (Government IDs, ABHA, external MRNs)
CREATE TABLE patient_identifiers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    id_type         identifier_type NOT NULL,
    id_number       TEXT NOT NULL,
    id_number_hash  TEXT,  -- SHA-256 for indexed lookup
    issuing_authority TEXT,
    issuing_country_id UUID REFERENCES geo_countries(id),
    valid_from      DATE,
    valid_until     DATE,
    is_verified     BOOLEAN NOT NULL DEFAULT false,
    verified_at     TIMESTAMPTZ,
    verification_mode TEXT,
    document_url    TEXT,
    is_primary      BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, patient_id, id_type, id_number)
);

ALTER TABLE patient_identifiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_identifiers ON patient_identifiers
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_patient_identifiers_patient ON patient_identifiers(tenant_id, patient_id);
CREATE INDEX idx_patient_identifiers_hash ON patient_identifiers(tenant_id, id_type, id_number_hash);
CREATE INDEX idx_patient_identifiers_number ON patient_identifiers(tenant_id, id_type, id_number);

-- Patient Addresses
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

-- Patient Contacts (Emergency + Next of Kin)
CREATE TABLE patient_contacts (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    contact_name        TEXT NOT NULL,
    relation            TEXT NOT NULL,
    phone               TEXT NOT NULL,
    phone_alt           TEXT,
    email               TEXT,
    address             JSONB,
    is_emergency_contact BOOLEAN NOT NULL DEFAULT false,
    is_next_of_kin      BOOLEAN NOT NULL DEFAULT false,
    is_legal_guardian   BOOLEAN NOT NULL DEFAULT false,
    priority            INT NOT NULL DEFAULT 1,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_contacts ON patient_contacts
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_patient_contacts_patient ON patient_contacts(tenant_id, patient_id);

-- Patient Insurance Policies
CREATE TABLE patient_insurance (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    insurance_provider  TEXT NOT NULL,
    policy_number       TEXT NOT NULL,
    group_number        TEXT,
    member_id           TEXT,
    plan_name           TEXT,
    policy_holder_name  TEXT,
    policy_holder_relation TEXT,
    valid_from          DATE NOT NULL,
    valid_until         DATE NOT NULL,
    sum_insured         NUMERIC(14,2),
    tpa_name            TEXT,
    tpa_id              TEXT,
    coverage_type       TEXT,
    priority            INT NOT NULL DEFAULT 1,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_insurance ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_insurance ON patient_insurance
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_patient_insurance_patient ON patient_insurance(tenant_id, patient_id);

-- Patient Allergies
CREATE TABLE patient_allergies (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    allergy_type    allergy_type NOT NULL,
    allergen_name   TEXT NOT NULL,
    allergen_code   TEXT,  -- SNOMED CT or RxNorm code
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

-- Patient Consents
CREATE TABLE patient_consents (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    consent_type        consent_type NOT NULL,
    consent_status      consent_status NOT NULL DEFAULT 'pending',
    consent_date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    consent_version     TEXT,
    consented_by        TEXT NOT NULL,
    consented_by_relation TEXT,
    witness_name        TEXT,
    capture_mode        consent_capture_mode NOT NULL,
    document_url        TEXT,
    valid_until         DATE,
    notes               TEXT,
    revoked_at          TIMESTAMPTZ,
    revoked_reason      TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_consents ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_consents ON patient_consents
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_patient_consents_patient ON patient_consents(tenant_id, patient_id);

-- Patient Merge History (MPI Audit Trail)
CREATE TABLE patient_merge_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    surviving_patient_id UUID NOT NULL REFERENCES patients(id),
    merged_patient_id    UUID NOT NULL REFERENCES patients(id),
    merged_by       UUID NOT NULL REFERENCES users(id),
    merge_reason    TEXT NOT NULL,
    merge_data      JSONB NOT NULL DEFAULT '{}',  -- snapshot of merged record
    unmerged_at     TIMESTAMPTZ,
    unmerged_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_merge_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_merge_history ON patient_merge_history
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- Patient Documents (ID proofs, photos, consent forms, referral letters)
CREATE TABLE patient_documents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    document_type   TEXT NOT NULL,  -- id_proof, consent_form, referral_letter, photo, report
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

-- ABHA Linking State (per-patient ABDM integration state)
CREATE TABLE patient_abha_links (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    abha_number     TEXT NOT NULL,  -- 14-digit XX-XXXX-XXXX-XXXX
    abha_address    TEXT,           -- username@abdm
    linking_token   TEXT,           -- valid 30 minutes
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
```

#### Master Tables

```sql
-- Religion Master (tenant-configurable)
CREATE TABLE master_religions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID REFERENCES tenants(id),  -- NULL = global default
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (tenant_id, code)
);

-- Occupation Master (tenant-configurable)
CREATE TABLE master_occupations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (tenant_id, code)
);

-- Relation Master (for contacts, guardians)
CREATE TABLE master_relations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    sort_order  INT NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (tenant_id, code)
);

-- Insurance Provider Master
CREATE TABLE master_insurance_providers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    provider_type   TEXT NOT NULL,  -- private, government, tpa
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
```

#### Indexes for MPI Matching

```sql
-- Trigram index for fuzzy name search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_patients_first_name_trgm ON patients USING gin (first_name gin_trgm_ops);
CREATE INDEX idx_patients_last_name_trgm ON patients USING gin (last_name gin_trgm_ops);
CREATE INDEX idx_patients_phone_primary ON patients(tenant_id, phone);
CREATE INDEX idx_patients_dob ON patients(tenant_id, date_of_birth);
CREATE INDEX idx_patients_abha ON patient_abha_links(abha_number);

-- Composite blocking index for MPI
CREATE INDEX idx_patients_mpi_block ON patients(tenant_id, date_of_birth, substring(first_name, 1, 3));
```

### 3.2 Schema Diagram (Normalized)

```
patients (core: ~45 columns)
  ├── patient_identifiers (1:N — Aadhaar, PAN, passport, etc.)
  ├── patient_addresses (1:N — current, permanent, correspondence)
  ├── patient_contacts (1:N — emergency, next of kin, guardian)
  ├── patient_insurance (1:N — primary, secondary policies)
  ├── patient_allergies (1:N — drug, food, environmental)
  ├── patient_consents (1:N — general, ABDM, research)
  ├── patient_documents (1:N — ID proofs, photos, consent forms)
  ├── patient_abha_links (1:1 — ABDM integration state)
  └── patient_merge_history (1:N — MPI merge audit)

Master tables:
  ├── master_religions (global + per-tenant)
  ├── master_occupations (global + per-tenant)
  ├── master_relations (global + per-tenant)
  └── master_insurance_providers (per-tenant)
```

---

## 4. API Endpoints

### 4.1 Patient CRUD

| Method | Path | Description | Auth |
|---|---|---|---|
| POST | `/api/patients` | Register new patient | Token |
| GET | `/api/patients` | List patients (paginated, filterable) | Token |
| GET | `/api/patients/:id` | Get patient full profile | Token |
| PUT | `/api/patients/:id` | Update patient demographics | Token |
| PATCH | `/api/patients/:id/status` | Activate/deactivate patient | Token |
| DELETE | `/api/patients/:id` | Soft-delete patient | Token (Admin) |

### 4.2 Patient Search & MPI

| Method | Path | Description | Auth |
|---|---|---|---|
| GET | `/api/patients/search` | Full-text + fuzzy search (name, phone, UHID, ABHA) | Token |
| POST | `/api/patients/match` | MPI duplicate check (returns scored matches) | Token |
| POST | `/api/patients/:id/merge` | Merge duplicate into surviving record | Token (Admin) |
| POST | `/api/patients/:id/unmerge` | Reverse a merge | Token (Admin) |

### 4.3 Patient Sub-Resources

| Method | Path | Description | Auth |
|---|---|---|---|
| GET | `/api/patients/:id/identifiers` | List patient's ID documents | Token |
| POST | `/api/patients/:id/identifiers` | Add identifier (Aadhaar, passport, etc.) | Token |
| PUT | `/api/patients/:id/identifiers/:iid` | Update identifier | Token |
| DELETE | `/api/patients/:id/identifiers/:iid` | Remove identifier | Token |
| GET | `/api/patients/:id/addresses` | List addresses | Token |
| POST | `/api/patients/:id/addresses` | Add address | Token |
| PUT | `/api/patients/:id/addresses/:aid` | Update address | Token |
| DELETE | `/api/patients/:id/addresses/:aid` | Remove address | Token |
| GET | `/api/patients/:id/contacts` | List emergency contacts | Token |
| POST | `/api/patients/:id/contacts` | Add contact | Token |
| PUT | `/api/patients/:id/contacts/:cid` | Update contact | Token |
| DELETE | `/api/patients/:id/contacts/:cid` | Remove contact | Token |
| GET | `/api/patients/:id/insurance` | List insurance policies | Token |
| POST | `/api/patients/:id/insurance` | Add insurance policy | Token |
| PUT | `/api/patients/:id/insurance/:pid` | Update policy | Token |
| DELETE | `/api/patients/:id/insurance/:pid` | Remove policy | Token |
| GET | `/api/patients/:id/allergies` | List allergies | Token |
| POST | `/api/patients/:id/allergies` | Add allergy | Token |
| PUT | `/api/patients/:id/allergies/:aid` | Update allergy | Token |
| DELETE | `/api/patients/:id/allergies/:aid` | Remove allergy | Token |
| GET | `/api/patients/:id/consents` | List consents | Token |
| POST | `/api/patients/:id/consents` | Record consent | Token |
| PUT | `/api/patients/:id/consents/:cid` | Update/revoke consent | Token |
| GET | `/api/patients/:id/documents` | List documents | Token |
| POST | `/api/patients/:id/documents` | Upload document | Token |
| DELETE | `/api/patients/:id/documents/:did` | Delete document | Token |

### 4.4 ABHA Integration

| Method | Path | Description | Auth |
|---|---|---|---|
| POST | `/api/abha/request-otp` | Generate Aadhaar OTP for enrollment | Token |
| POST | `/api/abha/enroll-aadhaar` | Complete ABHA enrollment via Aadhaar OTP | Token |
| POST | `/api/abha/enroll-mobile` | Mobile-only enrollment | Token |
| POST | `/api/abha/verify` | Verify existing ABHA (fetch-modes → init → confirm) | Token |
| POST | `/api/abha/link/:patient_id` | Link verified ABHA to patient | Token |
| DELETE | `/api/abha/link/:patient_id` | Unlink ABHA from patient | Token |
| GET | `/api/abha/profile/:abha_number` | Fetch ABHA profile from ABDM | Token |

### 4.5 Masters

| Method | Path | Description | Auth |
|---|---|---|---|
| GET | `/api/masters/religions` | List religions | Token |
| POST | `/api/masters/religions` | Add religion | Token (Admin) |
| GET | `/api/masters/occupations` | List occupations | Token |
| POST | `/api/masters/occupations` | Add occupation | Token (Admin) |
| GET | `/api/masters/relations` | List relations | Token |
| POST | `/api/masters/relations` | Add relation | Token (Admin) |
| GET | `/api/masters/insurance-providers` | List insurance providers | Token |
| POST | `/api/masters/insurance-providers` | Add provider | Token (Admin) |
| PUT | `/api/masters/insurance-providers/:id` | Update provider | Token (Admin) |

### 4.6 Quick Registration

| Method | Path | Description | Auth |
|---|---|---|---|
| POST | `/api/patients/quick` | Minimal-field emergency registration | Token |
| POST | `/api/patients/unknown` | Unknown/unidentified patient registration | Token |

---

## 5. Frontend Pages

### 5.1 Page Structure

```
apps/web/src/pages/patients/
├── index.tsx                    -- Patient list (search, filters, table)
├── register.tsx                 -- New patient registration form
├── [id].tsx                     -- Patient profile (tabbed detail view)
├── components/
│   ├── PatientSearchBar.tsx     -- Global search component
│   ├── PatientTable.tsx         -- Data table with sort/filter/pagination
│   ├── RegistrationForm.tsx     -- Multi-section registration form
│   ├── QuickRegisterModal.tsx   -- Minimal-field modal for emergency
│   ├── DuplicateCheckPanel.tsx  -- MPI match results side panel
│   ├── AbhaVerifyModal.tsx      -- ABHA verification flow modal
│   ├── AbhaEnrollModal.tsx      -- ABHA enrollment flow modal
│   ├── IdentifiersTab.tsx       -- ID documents management
│   ├── AddressesTab.tsx         -- Addresses management
│   ├── ContactsTab.tsx          -- Emergency contacts management
│   ├── InsuranceTab.tsx         -- Insurance policies management
│   ├── AllergiesTab.tsx         -- Allergies management
│   ├── ConsentsTab.tsx          -- Consents management
│   ├── DocumentsTab.tsx         -- Document uploads
│   ├── MergePatientModal.tsx    -- Patient merge UI
│   ├── PatientCard.tsx          -- Compact patient info card
│   └── PhotoCapture.tsx         -- Webcam photo capture component
```

### 5.2 Registration Form Sections

The registration form is divided into collapsible sections. **Section 1 (Core Identity)** is expanded by default; others are collapsed but can be filled in any order.

| Section | Fields | Required Fields |
|---|---|---|
| **1. Core Identity** | Prefix, First Name, Middle Name, Last Name, Suffix, Father's Name, Guardian Name/Relation | First Name, Last Name |
| **2. Demographics** | DOB, Gender, Marital Status, Blood Group, Religion, Nationality, Language | DOB or Age, Gender |
| **3. Contact** | Phone Primary, Phone Secondary, Email, Preferred Contact Method | Phone Primary |
| **4. Address** | Address Line 1, Line 2, City, District, State, Country, PIN Code | At least one address |
| **5. Emergency Contact** | Name, Relation, Phone, Alternate Phone | At least one contact |
| **6. Insurance** | Provider, Policy No, Member ID, Valid From/Until, Financial Class | Financial Class |
| **7. Government ID** | ID Type, ID Number, Verified | Optional |
| **8. ABHA** | ABHA Number, ABHA Address, KYC Status | Optional |
| **9. Allergies** | Type, Allergen, Severity, Reaction / NKDA flag | NKDA flag must be set |
| **10. Consent** | General Treatment consent | General Treatment mandatory |
| **11. Photo** | Webcam capture or upload | Optional |
| **12. Registration Info** | Category, MLC flag, Referral Source, Remarks | Category |

### 5.3 Patient Profile Tabs

| Tab | Content |
|---|---|
| **Overview** | Summary card: photo, name, UHID, ABHA, DOB, gender, phone, blood group, allergies, category |
| **Demographics** | Full demographics edit form |
| **Identifiers** | Government ID documents table (add/edit/verify) |
| **Addresses** | Address cards (current, permanent, etc.) |
| **Contacts** | Emergency contacts + next of kin table |
| **Insurance** | Insurance policies with validity indicators |
| **Allergies** | Allergy list with severity badges |
| **Consents** | Consent history timeline |
| **Documents** | Uploaded documents grid with preview |
| **ABHA** | ABHA linking status, verify/enroll buttons |
| **Encounters** | List of all OPD/IPD/Emergency encounters (read-only, links to encounter detail) |
| **Merge History** | Merge/unmerge audit log (Admin only) |

---

## 6. Business Rules

### 6.1 Registration Rules

| # | Rule |
|---|---|
| R1 | UHID is auto-generated from tenant's configured sequence (`sequences` table, type=`UHID`). Format: `{prefix}{zero-padded-number}`. Immutable once assigned. |
| R2 | At least **2 identifiers** must be verifiable at any clinical touchpoint (UHID + name, or UHID + DOB). This is enforced by JCI IPSG.1 and NABH AAC.2. |
| R3 | `first_name` and `last_name` are mandatory. `date_of_birth` OR manually entered age is mandatory. `gender` is mandatory. `phone_primary` is mandatory. |
| R4 | Before creating a new patient, the system MUST run MPI duplicate check. If score > upper threshold, user is warned and must confirm "Create Anyway" or select the existing match. |
| R5 | `no_known_allergies` (NKDA) must be explicitly set to `true` or at least one allergy must be recorded. It cannot be left as `null` after registration is complete. |
| R6 | `financial_class` determines the billing workflow. `self_pay` is default. If `insurance` is selected, at least one active `patient_insurance` record is required. |
| R7 | If `is_medico_legal = true`, `mlc_number` is required and the MLC workflow is triggered (police intimation, special documentation, restricted access). |
| R8 | If `is_unknown_patient = true`, `temporary_name` is auto-generated (e.g., "Unknown Male #47"). Real identity is merged when patient is identified. |
| R9 | Patients with `is_vip = true` have restricted record access — only designated staff can view/edit. |
| R10 | `is_merged = true` records are hidden from search results. All references (encounters, lab orders, invoices) are re-pointed to the surviving record. |

### 6.2 ABHA Rules

| # | Rule |
|---|---|
| A1 | ABHA linking is **optional**. No patient can be denied registration for not having ABHA. |
| A2 | If ABHA is verified via QR or OTP, demographics from ABDM auto-populate the form. The user can review and override local fields. |
| A3 | ABHA linking token is valid for 30 minutes. If expired, re-verification is required before linking care contexts. |
| A4 | One ABHA number can be linked to only one patient per tenant. The `patient_abha_links` table enforces this with a unique constraint. |
| A5 | Aadhaar number is **never stored in plaintext**. Only `SHA-256(aadhaar)` is stored in `patient_identifiers.id_number_hash`. The raw number is used only during verification. |

### 6.3 MPI Matching Rules

| # | Rule |
|---|---|
| M1 | **Blocking phase**: Candidates are filtered by `(DOB ± 1 year AND first 3 chars of last name)` OR `(phone_primary exact match)` OR `(Aadhaar hash exact match)`. |
| M2 | **Scoring phase** (Fellegi-Sunter probabilistic): Each field contributes a weight. Total score compared against upper (auto-match) and lower (no-match) thresholds. |
| M3 | **Field weights**: National ID (+20), DOB exact (+12), Phone exact (+13), Last name Jaro-Winkler (+7), First name Jaro-Winkler (+6), Gender exact (+1), Postal code exact (+6). |
| M4 | Score > 25: **Auto-match** — system suggests existing record with high confidence. |
| M5 | Score 12-25: **Possible match** — user reviews side-by-side comparison and decides. |
| M6 | Score < 12: **No match** — new record created. |
| M7 | Patient merge requires **Admin role**. Merged record snapshot is stored in `patient_merge_history.merge_data`. All FK references are updated to the surviving record. |

---

## 7. Master Data (Pre-Seeded)

### 7.1 Religions (India Default)

```
hindu, muslim, christian, sikh, buddhist, jain, jewish, parsi,
bahai, tribal_religion, no_religion, other, prefer_not_to_say
```

### 7.2 Relations

```
spouse, father, mother, son, daughter, brother, sister,
grandfather, grandmother, grandson, granddaughter,
uncle, aunt, nephew, niece, cousin,
friend, neighbor, employer, colleague,
legal_guardian, power_of_attorney, other
```

### 7.3 Occupations (ISCO-08 Based)

```
healthcare_worker, doctor, nurse, paramedic,
teacher, professor, researcher,
engineer, architect, lawyer, accountant,
farmer, laborer, driver, domestic_worker,
business_owner, shopkeeper, trader,
government_employee, military, police,
student, retired, homemaker, unemployed,
it_professional, banker, journalist, artist,
other
```

### 7.4 Education Levels

```
illiterate, primary, middle_school, high_school,
higher_secondary, diploma, graduate, post_graduate,
doctorate, professional, other
```

### 7.5 Government ID Types (by Country)

| Country | ID Types |
|---|---|
| India | aadhaar, pan, voter_id, driving_license, passport, ration_card, abha, disability_certificate |
| USA | ssn, driving_license, passport |
| UK | nhs_number, passport, driving_license |
| Australia | medicare_number, passport, driving_license |
| Saudi Arabia | national_id, iqama, passport |
| UAE | emirates_id, passport |
| All | passport, national_id, uhid_external |

---

## 8. Validation Rules (Zod Schemas)

### 8.1 Patient Registration Schema

```typescript
const patientRegistrationSchema = z.object({
  // Core Identity (Required)
  prefix: z.string().max(20).optional(),
  first_name: z.string().min(1).max(100),
  middle_name: z.string().max(100).optional(),
  last_name: z.string().min(1).max(100),
  suffix: z.string().max(20).optional(),

  // Demographics (Required)
  date_of_birth: z.string().date().optional(),  // YYYY-MM-DD
  age_years: z.number().min(0).max(150).optional(),
  is_dob_estimated: z.boolean().default(false),
  biological_sex: z.enum(['male', 'female', 'other', 'unknown']),

  // Demographics (Optional)
  marital_status: z.enum([...]).optional(),
  religion: z.string().optional(),
  nationality_id: z.string().uuid().optional(),
  preferred_language: z.string().max(10).optional(),
  blood_group: z.enum([...]).optional(),
  occupation: z.string().optional(),
  education_level: z.string().optional(),

  // Contact (Required)
  phone_primary: z.string().min(10).max(15),
  phone_secondary: z.string().max(15).optional(),
  email: z.string().email().optional(),

  // Family
  father_name: z.string().max(100).optional(),
  mother_name: z.string().max(100).optional(),
  spouse_name: z.string().max(100).optional(),
  guardian_name: z.string().max(100).optional(),
  guardian_relation: z.string().optional(),

  // Registration
  category: z.enum([...]).default('general'),
  financial_class: z.enum([...]).default('self_pay'),
  registration_type: z.enum([...]).default('new'),
  registration_source: z.enum([...]).optional(),
  is_medico_legal: z.boolean().default(false),
  mlc_number: z.string().optional(),
  is_vip: z.boolean().default(false),

  // Sub-resources (inline for quick registration)
  address: addressSchema.optional(),
  emergency_contact: contactSchema.optional(),
  consent_general_treatment: z.boolean(),
}).refine(
  data => data.date_of_birth || data.age_years,
  { message: "Either date of birth or age is required" }
);
```

### 8.2 ID Validation Patterns

| ID Type | Regex / Validation |
|---|---|
| Aadhaar | `^[2-9]\d{11}$` + Verhoeff checksum (never stored raw) |
| PAN | `^[A-Z]{5}[0-9]{4}[A-Z]$` |
| Voter ID | `^[A-Z]{3}[0-9]{7}$` |
| Passport | `^[A-Z][0-9]{7}$` (India) or alphanumeric max 20 |
| ABHA | `^\d{2}-\d{4}-\d{4}-\d{4}$` (14 digits with hyphens) |
| NHS Number | 10 digits + modulus 11 check |
| SSN | `^\d{3}-\d{2}-\d{4}$` |
| Emirates ID | `^784-\d{4}-\d{7}-\d$` |
| PIN Code (India) | `^[1-9]\d{5}$` |

---

## 9. Build Priority

### Sprint 1: Core Registration (P0)

| # | Task | Type |
|---|---|---|
| 1 | Migration 003: patients ALTER + new tables + enums | Backend |
| 2 | Rust domain types: Patient (expanded), identifiers, addresses, contacts, insurance, allergies, consents | Backend |
| 3 | CRUD routes: `/api/patients` (create, get, list, update) | Backend |
| 4 | Patient search endpoint (full-text + pg_trgm fuzzy) | Backend |
| 5 | MPI duplicate check endpoint (`/api/patients/match`) | Backend |
| 6 | UHID auto-generation (atomic sequence increment) | Backend |
| 7 | Sub-resource routes: identifiers, addresses, contacts | Backend |
| 8 | Zod schemas: registration, identifiers, addresses, contacts | Frontend |
| 9 | TypeScript types: Patient, identifiers, addresses, contacts | Frontend |
| 10 | API client methods | Frontend |
| 11 | Patient list page with search and table | Frontend |
| 12 | Registration form (multi-section, collapsible) | Frontend |
| 13 | Patient profile page (tabbed) | Frontend |
| 14 | Duplicate check panel in registration form | Frontend |
| 15 | Quick registration modal | Frontend |
| 16 | Seed master data: religions, occupations, relations | Backend |

### Sprint 2: Insurance, Allergies, Consents (P1)

| # | Task | Type |
|---|---|---|
| 17 | Insurance sub-resource routes | Backend |
| 18 | Allergies sub-resource routes | Backend |
| 19 | Consents sub-resource routes | Backend |
| 20 | Documents upload routes (file storage) | Backend |
| 21 | Insurance tab UI | Frontend |
| 22 | Allergies tab UI | Frontend |
| 23 | Consents tab UI | Frontend |
| 24 | Documents tab UI | Frontend |
| 25 | Insurance providers master CRUD | Backend + Frontend |
| 26 | Photo capture component (webcam) | Frontend |

### Sprint 3: ABHA Integration (P1)

| # | Task | Type |
|---|---|---|
| 27 | ABDM API client (Rust HTTP client for ABDM sandbox) | Backend |
| 28 | ABHA verification flow (fetch-modes → init → confirm) | Backend |
| 29 | ABHA enrollment flow (Aadhaar OTP + Mobile) | Backend |
| 30 | ABHA link/unlink routes | Backend |
| 31 | QR code scanning (profile share callback) | Backend |
| 32 | ABHA verify modal UI | Frontend |
| 33 | ABHA enroll modal UI | Frontend |
| 34 | ABHA tab in patient profile | Frontend |
| 35 | Auto-populate registration form from ABDM profile | Frontend |

### Sprint 4: MPI & Advanced (P2)

| # | Task | Type |
|---|---|---|
| 36 | Patient merge endpoint + UI | Backend + Frontend |
| 37 | Patient unmerge endpoint | Backend |
| 38 | Unknown patient registration flow | Backend + Frontend |
| 39 | MLC workflow triggers | Backend |
| 40 | VIP access restriction middleware | Backend |
| 41 | Wristband print template (barcode) | Frontend |
| 42 | Patient card print template (QR code) | Frontend |
| 43 | Data quality score calculation | Backend |
| 44 | Bulk patient import (CSV) | Backend |

---

## 10. Dependencies

### Depends On

| Module | Reason |
|---|---|
| Auth | JWT authentication, role-based access |
| Onboarding | Tenant, facilities, departments, sequences, geo tables must exist |

### Blocks

| Module | Reason |
|---|---|
| OPD | Encounters link to `patients.id` |
| IPD | Admissions link to `patients.id` |
| Lab | Lab orders link to `patients.id` |
| Billing | Invoices link to `patients.id` |
| Pharmacy | Prescriptions link to `patients.id` |
| Radiology | Imaging orders link to `patients.id` |
| Emergency | Triage entries link to `patients.id` |
| All clinical modules | Every clinical workflow begins with patient identification |

---

## 11. Open Questions

| # | Question | Options |
|---|---|---|
| Q1 | File storage for documents/photos? | Local filesystem vs S3-compatible (MinIO) vs database BYTEA |
| Q2 | ABDM sandbox vs production? | Start with sandbox (`dev.abdm.gov.in`), switch to production after ABDM certification |
| Q3 | Biometric enrollment (fingerprint/iris)? | Phase 3 — requires hardware (STQC-certified devices in India) |
| Q4 | Patient portal / self-registration? | Phase 3 — web portal for patients to pre-register before visit |
| Q5 | Aadhaar e-KYC integration? | Requires separate UIDAI license; store only hash, never raw number |
| Q6 | Multi-language name storage? | `full_name_local` column for local script; `first_name`/`last_name` always in English/Latin |
| Q7 | SMS/WhatsApp notification at registration? | Requires notification service (Phase 2); capture consent flag now |

---

## 12. Security Considerations

| Concern | Mitigation |
|---|---|
| **Aadhaar storage** | Never store raw 12-digit number. Store only `SHA-256(aadhaar)` in `id_number_hash`. Display masked: `XXXX XXXX 1234`. |
| **PHI encryption** | All patient data at rest is protected by PostgreSQL TDE + RLS. Sensitive fields (SSN, insurance IDs) use application-level encryption. |
| **Access control** | Role-based: `receptionist` can register, `doctor` can view, `admin` can merge/delete. VIP records have additional access restriction. |
| **Audit trail** | All create/update/delete operations logged in `audit_log` with SHA-256 chain. |
| **ABDM tokens** | ABHA linking tokens stored encrypted, auto-purged after expiry (30 min). |
| **Consent** | General treatment consent is mandatory before any clinical encounter. ABDM data sharing consent is separate and optional. |
| **Data retention** | Patient records are never hard-deleted. Soft-delete with `is_active = false`. Retention policy configurable per tenant. |
