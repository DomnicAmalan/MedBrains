# RFC-MODULE-ONBOARDING — Onboarding & Setup Module

**Status**: Draft
**Priority**: P0 (Foundation — first thing users see)
**Platform**: Web only
**Features**: 102 base + geospatial/regulatory (25 P0, 31 P1, 27 P2, 19 P3)
**Excel Sheet**: "Onboarding & Setup"

---

## 1. Overview

The Onboarding module provides a guided setup wizard for new MedBrains deployments. Since this is an open-source HMS, the first-run experience must be self-service — no sales engineer or consultant required. A new user should go from `docker compose up` to a functioning hospital system in under 30 minutes.

### Scope

- Initial system setup (DB, env, admin account)
- Tenant/hospital configuration
- **Geospatial location & regulatory mapping** (country → state → district → subdistrict → town → facility)
- Organizational structure (campus, departments, services)
- User & role creation
- Module activation with per-module masters
- Numbering/sequence configuration
- Integration setup (email, SMS, payment)
- Print & branding
- Open-source specific (Docker, demo mode, API docs)

### Out of Scope (for now)

- Multi-tenant SaaS onboarding (P3)
- Kubernetes/Helm deployment (P3)
- Plugin/extension marketplace (P3)

---

## 2. User Flow

```
First Visit (no tenant exists)
  │
  ├─→ Step 1:  Welcome & Prerequisites Check
  ├─→ Step 2:  Create Super Admin Account
  ├─→ Step 3:  Hospital / Tenant Setup (org name, type, address)
  ├─→ Step 4:  Geospatial & Regulatory Setup (country/state/district, auto-detect regulators)
  ├─→ Step 5:  Facilities & Institutions (sub-bodies: colleges, branches, clinics, blood banks)
  ├─→ Step 6:  Campus & Location Hierarchy (per facility: buildings, floors, rooms, beds)
  ├─→ Step 7:  Department Setup (per facility)
  ├─→ Step 8:  User & Role Setup
  ├─→ Step 9:  Module Activation (per facility or org-wide)
  ├─→ Step 10: Numbering & Sequences
  ├─→ Step 11: Branding & Print
  ├─→ Step 12: Review & Launch
  │
  └─→ Dashboard (normal app)
```

The wizard is **sequential but skippable** — users can skip any step and configure later from Settings. Progress is tracked so they can resume where they left off.

**Step 4 flow**: After entering hospital address in Step 3, the system uses the address (or optional GPS coordinates) to auto-detect the geographic hierarchy and applicable regulatory bodies. The user can review, confirm, or override.

**Step 5 flow**: The user declares what institutions/facilities belong to the organization. Standalone hospitals just have one "Main Hospital" (auto-created). Medical colleges add their attached colleges, blood banks, etc. Multi-location chains add branches. Each facility gets its own address, regulatory requirements, and operational scope. Facilities that share a campus reuse the parent's location; facilities at different addresses enter their own geo hierarchy.

---

## 3. Database Changes

### 3.1 Existing Tables Used (no changes needed)

| Table | Usage in Onboarding |
|-------|---------------------|
| `tenants` | Hospital setup (step 3) |
| `users` | Admin + staff creation (steps 2, 6) |
| `locations` | Campus/building/floor/room/bed hierarchy (step 4) |
| `departments` | Department creation (step 5) |
| `services` | Service catalog (step 5) |
| `sequences` | UHID, invoice numbering config (step 8) |

### 3.2 New Table: `onboarding_progress`

Tracks wizard completion state per tenant.

```sql
CREATE TABLE onboarding_progress (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id) UNIQUE,
    current_step INT NOT NULL DEFAULT 1,
    completed_steps JSONB NOT NULL DEFAULT '[]',
    is_complete BOOLEAN NOT NULL DEFAULT false,
    started_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 3.3 New Table: `tenant_settings`

Extended hospital configuration beyond the `tenants.config` JSONB.

```sql
CREATE TABLE tenant_settings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    category    TEXT NOT NULL,        -- 'general', 'branding', 'print', 'integration', 'numbering'
    key         TEXT NOT NULL,
    value       JSONB NOT NULL DEFAULT '{}',
    updated_by  UUID REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, category, key)
);
```

### 3.4 New Table: `module_config`

Tracks which modules are enabled and their configuration.

```sql
CREATE TYPE module_status AS ENUM ('disabled', 'enabled', 'setup_pending');

CREATE TABLE module_config (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    module_code TEXT NOT NULL,         -- 'opd', 'ipd', 'lab', 'pharmacy', 'billing', etc.
    status      module_status NOT NULL DEFAULT 'disabled',
    config      JSONB NOT NULL DEFAULT '{}',
    enabled_at  TIMESTAMPTZ,
    enabled_by  UUID REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, module_code)
);
```

### 3.5 New Table: `roles`

Custom roles beyond the hard-coded `user_role` enum. Needed for Step 6.

```sql
CREATE TABLE roles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',  -- {"patients": ["view","create","edit"], "opd": ["view"]}
    is_system   BOOLEAN NOT NULL DEFAULT false, -- true for built-in roles
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);
```

### 3.6 New Table: `facilities` (Institutional Hierarchy)

A tenant (parent organization) can have multiple facilities/institutions. A medical college hospital may have an attached pharmacy college, nursing college, dental wing, research institute, satellite clinics, standalone blood banks, retail pharmacies, etc. Each facility has its own location, regulatory requirements, and operational scope.

```sql
CREATE TYPE facility_type AS ENUM (
    -- Hospital types
    'main_hospital',           -- Primary hospital / headquarters
    'branch_hospital',         -- Branch / satellite hospital
    'super_specialty_center',  -- Standalone super-specialty wing
    'day_care_center',         -- Day surgery / day care
    'satellite_clinic',        -- OPD-only clinic in another area
    'community_health_center', -- CHC
    'primary_health_center',   -- PHC
    'health_wellness_center',  -- HWC (sub-center level)

    -- Academic institutions
    'medical_college',         -- Attached / standalone medical college
    'pharmacy_college',        -- D.Pharm / B.Pharm / M.Pharm college
    'nursing_college',         -- Nursing school / college
    'dental_college',          -- BDS / MDS college
    'ayush_college',           -- Ayurveda / Yoga / Unani / Siddha / Homeopathy
    'paramedical_college',     -- Allied health sciences
    'research_institute',      -- R&D / clinical research wing

    -- Diagnostic & support
    'diagnostic_center',       -- Standalone lab + radiology
    'blood_bank',              -- Standalone blood bank / blood center
    'eye_bank',                -- Cornea / eye bank
    'organ_retrieval_center',  -- Organ procurement organization

    -- Pharmacy & retail
    'retail_pharmacy',         -- Attached or standalone pharmacy outlet
    'drug_warehouse',          -- Central drug store / warehouse

    -- Emergency & transport
    'trauma_center',           -- Designated trauma center
    'ambulance_service',       -- Fleet / dispatch center
    'telemedicine_hub',        -- Telemedicine consultation center

    -- Residential & support
    'hostel',                  -- Staff / student hostel
    'residential_quarters',    -- Staff quarters
    'mortuary',                -- Standalone mortuary
    'kitchen_central',         -- Central kitchen (multi-facility)
    'laundry_central',         -- Central laundry
    'cssd_central'             -- Central sterile services
);

CREATE TYPE facility_status AS ENUM ('active', 'inactive', 'under_construction', 'temporarily_closed');

CREATE TABLE facilities (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    parent_id       UUID REFERENCES facilities(id),  -- NULL = top-level; enables tree hierarchy
    code            TEXT NOT NULL,                    -- 'MAIN', 'PHARM_COLLEGE', 'BRANCH_MG_ROAD'
    name            TEXT NOT NULL,
    facility_type   facility_type NOT NULL,
    status          facility_status NOT NULL DEFAULT 'active',

    -- Location (each facility can be at a different address)
    address         JSONB DEFAULT '{}',              -- {line1, line2, city, state, pin}
    latitude        DOUBLE PRECISION,
    longitude       DOUBLE PRECISION,
    country_id      UUID REFERENCES geo_countries(id),
    state_id        UUID REFERENCES geo_states(id),
    district_id     UUID REFERENCES geo_districts(id),
    subdistrict_id  UUID REFERENCES geo_subdistricts(id),
    town_id         UUID REFERENCES geo_towns(id),

    -- Registration / licensing
    registration_no TEXT,                            -- Facility-specific reg number
    bed_count       INT DEFAULT 0,
    established_date DATE,

    -- Academic (for colleges)
    affiliated_university TEXT,                      -- 'Rajiv Gandhi University of Health Sciences'
    recognition_body     TEXT,                       -- 'NMC', 'PCI', 'INC', 'DCI'
    recognition_number   TEXT,
    intake_capacity      INT,                        -- Student intake per year

    -- Operational scope
    modules_enabled JSONB DEFAULT '[]',              -- Which HMS modules this facility uses
    shared_billing  BOOLEAN NOT NULL DEFAULT true,   -- Share billing with parent?
    shared_pharmacy BOOLEAN NOT NULL DEFAULT true,   -- Share pharmacy stock with parent?
    shared_lab      BOOLEAN NOT NULL DEFAULT true,   -- Share lab with parent?
    shared_hr       BOOLEAN NOT NULL DEFAULT true,   -- Share staff records with parent?

    -- Contact
    phone           TEXT,
    email           TEXT,
    head_name       TEXT,                            -- Dean / Director / In-charge
    head_designation TEXT,                           -- 'Dean', 'Medical Director', 'Principal'

    config          JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

-- Index for hierarchy traversal
CREATE INDEX idx_facilities_parent ON facilities(parent_id);
CREATE INDEX idx_facilities_tenant ON facilities(tenant_id);
CREATE INDEX idx_facilities_type ON facilities(facility_type);
```

**Example hierarchy** for a typical Medical College Hospital:

```
Acme Medical College & Hospital (tenant)
├── Main Hospital (main_hospital)
│   ├── Trauma Center (trauma_center)
│   ├── Blood Bank (blood_bank)
│   └── Central Kitchen (kitchen_central)
├── Medical College (medical_college)
├── Pharmacy College (pharmacy_college)
├── Nursing College (nursing_college)
├── Dental College & Hospital (dental_college)
├── Research Institute (research_institute)
├── MG Road Satellite Clinic (satellite_clinic)  ← different city
├── Ambulance Service (ambulance_service)
├── Central Drug Store (drug_warehouse)
├── Staff Hostel (hostel)
└── Retail Pharmacy - Gate 1 (retail_pharmacy)
```

**Example** for a multi-location hospital chain:

```
HealthCorp Hospitals (tenant)
├── Bangalore Main (main_hospital)
│   ├── Diagnostic Center (diagnostic_center)
│   └── Retail Pharmacy (retail_pharmacy)
├── Chennai Branch (branch_hospital)
│   └── Retail Pharmacy (retail_pharmacy)
├── Hyderabad Branch (branch_hospital)
├── Mysore Day Care (day_care_center)
└── Telemedicine Hub (telemedicine_hub)
```

### 3.7 Alter `tenants` Table

Add columns for extended hospital info including geospatial linkage.

```sql
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS
    address         JSONB DEFAULT '{}',        -- {line1, line2, city, state, pin, country}
    phone           TEXT,
    email           TEXT,
    website         TEXT,
    logo_url        TEXT,
    registration_no TEXT,
    accreditation   TEXT,                       -- NABH/JCI number
    timezone        TEXT DEFAULT 'Asia/Kolkata',
    locale          TEXT DEFAULT 'en-IN',
    currency        TEXT DEFAULT 'INR',
    fy_start_month  INT DEFAULT 4,             -- April for India
    latitude        DOUBLE PRECISION,          -- GPS coordinate (HQ / main campus)
    longitude       DOUBLE PRECISION,          -- GPS coordinate (HQ / main campus)
    country_id      UUID REFERENCES geo_countries(id),
    state_id        UUID REFERENCES geo_states(id),
    district_id     UUID REFERENCES geo_districts(id),
    subdistrict_id  UUID REFERENCES geo_subdistricts(id),
    town_id         UUID REFERENCES geo_towns(id);
```

### 3.8 Geospatial Hierarchy Tables

Six-layer geographic hierarchy. Pre-seeded with country-specific data (India ships with all states, districts, subdistricts, and towns from Census/LGDIR data). Other countries can be added via CSV import.

```sql
-- Level 1: Countries
CREATE TABLE geo_countries (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code        TEXT NOT NULL UNIQUE,          -- ISO 3166-1 alpha-2: 'IN', 'US', 'GB'
    name        TEXT NOT NULL,
    dial_code   TEXT,                          -- '+91', '+1'
    currency    TEXT DEFAULT 'INR',
    timezone    TEXT DEFAULT 'Asia/Kolkata',
    locale      TEXT DEFAULT 'en-IN',
    fy_start_month INT DEFAULT 4,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Level 2: States / Provinces / Regions
CREATE TABLE geo_states (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_id  UUID NOT NULL REFERENCES geo_countries(id),
    code        TEXT NOT NULL,                 -- 'KA', 'MH', 'TN' (ISO 3166-2 subdivision)
    name        TEXT NOT NULL,
    name_local  TEXT,                          -- Name in local script: 'கர்நாடகா'
    state_type  TEXT DEFAULT 'state',          -- 'state', 'union_territory', 'province', 'region'
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (country_id, code)
);

-- Level 3: Districts
CREATE TABLE geo_districts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state_id    UUID NOT NULL REFERENCES geo_states(id),
    code        TEXT NOT NULL,                 -- Census district code
    name        TEXT NOT NULL,
    name_local  TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (state_id, code)
);

-- Level 4: Sub-districts / Taluks / Tehsils / Blocks
CREATE TABLE geo_subdistricts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    district_id UUID NOT NULL REFERENCES geo_districts(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    name_local  TEXT,
    subdistrict_type TEXT DEFAULT 'taluk',     -- 'taluk', 'tehsil', 'block', 'mandal', 'circle'
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (district_id, code)
);

-- Level 5: Towns / Villages / Cities
CREATE TABLE geo_towns (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subdistrict_id UUID NOT NULL REFERENCES geo_subdistricts(id),
    code        TEXT NOT NULL,                 -- Census town code or PIN code
    name        TEXT NOT NULL,
    name_local  TEXT,
    town_type   TEXT DEFAULT 'town',           -- 'metro', 'city', 'town', 'village', 'census_town'
    pin_code    TEXT,                          -- Postal code: '560001'
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (subdistrict_id, code)
);
```

### 3.9 Regulatory Bodies & Facility Mapping

Regulatory bodies are linked to geographic levels AND facility types. When a hospital sets its location and declares its facilities, applicable regulators are auto-detected based on both geography and facility type.

```sql
-- Regulatory body types
CREATE TYPE regulatory_level AS ENUM (
    'international',   -- WHO, JCI
    'national',        -- NMC, CDSCO, NABH, AERB, PNDT, PCPNDT
    'state',           -- State Medical Council, Drug Controller, PCB
    'district',        -- District Health Officer, CMHO
    'local'            -- Municipal Health Officer, local bodies
);

-- Master list of regulatory bodies
CREATE TABLE regulatory_bodies (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            TEXT NOT NULL UNIQUE,       -- 'NMC', 'NABH', 'KA_SMC', 'CDSCO', 'PCI', 'INC', 'DCI'
    name            TEXT NOT NULL,
    short_name      TEXT,
    level           regulatory_level NOT NULL,
    -- Geographic scope (NULL = applies everywhere at that level)
    country_id      UUID REFERENCES geo_countries(id),   -- NULL for international
    state_id        UUID REFERENCES geo_states(id),      -- NULL for national+
    district_id     UUID REFERENCES geo_districts(id),   -- NULL for state+
    -- What this body regulates
    category        TEXT NOT NULL,              -- 'accreditation', 'licensing', 'drug_control',
                                               -- 'radiation_safety', 'environment', 'biomedical_waste',
                                               -- 'clinical_establishment', 'blood_bank', 'organ_transplant',
                                               -- 'medical_education', 'pharmacy_education', 'nursing_education',
                                               -- 'dental_education', 'paramedical_education'
    -- Which facility types this regulator applies to (NULL = all facilities)
    applicable_facility_types JSONB,           -- ["main_hospital","branch_hospital"] or NULL for all
    applicable_modules JSONB,                  -- ["radiology"] for AERB, ["blood_bank"] for NACO, NULL for all
    website         TEXT,
    description     TEXT,
    -- Requirements
    renewal_period_months INT,                 -- License renewal cycle
    is_mandatory    BOOLEAN NOT NULL DEFAULT true,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tracks regulatory compliance per facility (not just per tenant)
-- A medical college hospital needs separate compliance for the hospital, pharmacy college, etc.
CREATE TABLE facility_regulatory_compliance (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    facility_id     UUID REFERENCES facilities(id),        -- NULL = tenant-level (org-wide)
    regulatory_body_id UUID NOT NULL REFERENCES regulatory_bodies(id),
    -- Compliance status
    status          TEXT NOT NULL DEFAULT 'not_started',  -- 'not_started', 'in_progress', 'compliant', 'expired', 'exempt'
    license_number  TEXT,
    issued_date     DATE,
    expiry_date     DATE,
    -- Documents
    certificate_url TEXT,
    notes           TEXT,
    -- Audit trail
    last_reviewed_by UUID REFERENCES users(id),
    last_reviewed_at TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, facility_id, regulatory_body_id)
);
```

### 3.10 Indexes for Geographic, Facility & Regulatory Lookups

```sql
-- Fast hierarchy traversal
CREATE INDEX idx_geo_states_country ON geo_states(country_id);
CREATE INDEX idx_geo_districts_state ON geo_districts(state_id);
CREATE INDEX idx_geo_subdistricts_district ON geo_subdistricts(district_id);
CREATE INDEX idx_geo_towns_subdistrict ON geo_towns(subdistrict_id);
CREATE INDEX idx_geo_towns_pin ON geo_towns(pin_code);

-- Facility hierarchy
CREATE INDEX idx_facilities_parent ON facilities(parent_id);
CREATE INDEX idx_facilities_tenant ON facilities(tenant_id);
CREATE INDEX idx_facilities_type ON facilities(facility_type);

-- Fast regulatory lookup by geography
CREATE INDEX idx_regulatory_bodies_country ON regulatory_bodies(country_id);
CREATE INDEX idx_regulatory_bodies_state ON regulatory_bodies(state_id);
CREATE INDEX idx_regulatory_bodies_district ON regulatory_bodies(district_id);
CREATE INDEX idx_regulatory_bodies_level ON regulatory_bodies(level);

-- Facility compliance
CREATE INDEX idx_facility_compliance_tenant ON facility_regulatory_compliance(tenant_id);
CREATE INDEX idx_facility_compliance_facility ON facility_regulatory_compliance(facility_id);
CREATE INDEX idx_facility_compliance_expiry ON facility_regulatory_compliance(expiry_date)
    WHERE status = 'compliant';
```

---

## 4. API Endpoints

All onboarding endpoints are under `/api/onboarding/`.

### 4.1 Setup Wizard

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/api/onboarding/status` | Check if onboarding needed (no tenant = show wizard) | Public |
| POST | `/api/onboarding/init` | Create first tenant + super admin (step 1-3) | Public (one-time) |
| GET | `/api/onboarding/progress` | Get current wizard step & completion state | Protected |
| PUT | `/api/onboarding/progress` | Update current step | Protected |
| POST | `/api/onboarding/complete` | Mark onboarding as complete | Protected |

### 4.2 Organizational Structure (used during wizard + later in settings)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/setup/locations` | List all locations |
| POST | `/api/setup/locations` | Create location |
| PUT | `/api/setup/locations/{id}` | Update location |
| DELETE | `/api/setup/locations/{id}` | Deactivate location |
| POST | `/api/setup/locations/import` | Bulk import from CSV |
| GET | `/api/setup/departments` | List departments |
| POST | `/api/setup/departments` | Create department |
| PUT | `/api/setup/departments/{id}` | Update department |
| DELETE | `/api/setup/departments/{id}` | Deactivate department |
| POST | `/api/setup/departments/import` | Bulk import from CSV |
| GET | `/api/setup/services` | List services |
| POST | `/api/setup/services` | Create service |
| PUT | `/api/setup/services/{id}` | Update service |

### 4.3 Users & Roles

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/setup/roles` | List roles (system + custom) |
| POST | `/api/setup/roles` | Create custom role |
| PUT | `/api/setup/roles/{id}` | Update role permissions |
| GET | `/api/setup/users` | List users |
| POST | `/api/setup/users` | Create user |
| PUT | `/api/setup/users/{id}` | Update user |
| POST | `/api/setup/users/import` | Bulk import from CSV |

### 4.4 Module & Settings

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/setup/modules` | List all modules with enabled/disabled status |
| PUT | `/api/setup/modules/{code}` | Enable/disable module |
| GET | `/api/setup/settings` | List all tenant settings |
| PUT | `/api/setup/settings/{category}/{key}` | Update a setting |
| GET | `/api/setup/sequences` | List all sequences |
| PUT | `/api/setup/sequences/{type}` | Update sequence config |

### 4.5 Facilities & Institutions

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/setup/facilities` | List all facilities for tenant (tree or flat) |
| POST | `/api/setup/facilities` | Create a facility |
| PUT | `/api/setup/facilities/{id}` | Update facility details |
| DELETE | `/api/setup/facilities/{id}` | Deactivate facility |
| GET | `/api/setup/facilities/{id}/compliance` | List regulatory compliance for a specific facility |
| POST | `/api/setup/facilities/import` | Bulk import facilities from CSV |

### 4.6 Geospatial & Regulatory

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/geo/countries` | List all countries |
| GET | `/api/geo/countries/{id}/states` | List states for a country |
| GET | `/api/geo/states/{id}/districts` | List districts for a state |
| GET | `/api/geo/districts/{id}/subdistricts` | List subdistricts for a district |
| GET | `/api/geo/subdistricts/{id}/towns` | List towns for a subdistrict |
| GET | `/api/geo/lookup/pin/{pin_code}` | Reverse-lookup: PIN code → full hierarchy |
| GET | `/api/geo/regulators` | List all regulatory bodies |
| GET | `/api/geo/regulators/for-location` | Auto-detect applicable regulators for a given country/state/district |
| GET | `/api/setup/compliance` | List tenant's regulatory compliance records |
| POST | `/api/setup/compliance` | Add/update compliance record (license number, dates, cert) |
| PUT | `/api/setup/compliance/{id}` | Update a compliance record |
| POST | `/api/geo/import` | Admin: bulk import geographic data from CSV |

### 4.7 Branding

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/setup/branding/logo` | Upload hospital logo |
| PUT | `/api/setup/branding/theme` | Update brand colors |
| GET | `/api/setup/branding` | Get current branding |

---

## 5. Frontend Pages

### 5.1 Onboarding Wizard (`/onboarding`)

**Route**: `/onboarding` (public if no tenant exists, otherwise protected)

Multi-step wizard with stepper UI (Mantine `Stepper` component):

| Step | Component | Description |
|------|-----------|-------------|
| 1 | `WelcomeStep` | System check, welcome message |
| 2 | `AdminStep` | Super admin account creation |
| 3 | `HospitalStep` | Organization name, type, HQ address, logo |
| 4 | `GeoRegulatoryStep` | Country/state/district selection, PIN lookup, auto-detected regulators |
| 5 | `FacilitiesStep` | Add sub-institutions: colleges, branches, clinics, labs, pharmacies |
| 6 | `LocationsStep` | Per-facility campus → building → floor → room → bed hierarchy |
| 7 | `DepartmentsStep` | Department creation with types (per facility) |
| 8 | `UsersStep` | Role setup + user creation (assign to facilities) |
| 9 | `ModulesStep` | Enable/disable modules toggle (org-wide or per facility) |
| 10 | `SequencesStep` | UHID, invoice number format |
| 11 | `BrandingStep` | Logo, colors, print templates |
| 12 | `ReviewStep` | Summary + launch button |

### 5.2 Settings Page (`/admin/settings`)

After onboarding, the same configuration is accessible from Settings with tabs:
- General (organization info)
- Facilities & Institutions
- Geography & Regulatory (compliance tracking per facility)
- Locations (per facility)
- Departments (per facility)
- Services
- Users & Roles
- Modules
- Sequences
- Branding
- Integrations

### 5.3 File Structure

```
apps/web/src/pages/
├── onboarding/
│   ├── index.tsx              # Wizard container with Stepper
│   ├── WelcomeStep.tsx
│   ├── AdminStep.tsx
│   ├── HospitalStep.tsx
│   ├── GeoRegulatoryStep.tsx  # Country/state/district + regulator auto-detect
│   ├── FacilitiesStep.tsx     # Sub-institutions: colleges, branches, clinics
│   ├── LocationsStep.tsx
│   ├── DepartmentsStep.tsx
│   ├── UsersStep.tsx
│   ├── ModulesStep.tsx
│   ├── SequencesStep.tsx
│   ├── BrandingStep.tsx
│   ├── ReviewStep.tsx
│   └── onboarding.module.scss
└── admin/
    └── settings.tsx           # Post-onboarding settings (same data, different UI)
```

---

## 6. Business Rules

1. **One-time init**: `/api/onboarding/init` can only be called if no tenants exist. Returns 403 after first tenant is created.
2. **Step skipping**: All steps after admin creation (step 2) are skippable. Skipped steps show a reminder badge in Settings.
3. **Module dependencies**: Enabling a module checks its dependencies (e.g., Billing needs Patient module enabled). Backend enforces this.
4. **Role permissions**: Permission matrix is `{ module_code: [action_list] }` where actions are `view`, `create`, `edit`, `delete`, `approve`, `export`.
5. **Sequence uniqueness**: Each sequence type is unique per tenant. Prefix + padding are configurable but cannot create duplicate formats.
6. **Logo storage**: Uploaded to local filesystem (`/data/uploads/logos/`) with UUID filename. Served via static file handler.
7. **Geographic auto-detection**: When the user enters a PIN code or selects a state, the system auto-fills the full geographic hierarchy (district → subdistrict → town) via cascading dropdowns.
8. **Regulator auto-mapping**: Based on the hospital's geographic location, the system automatically identifies all applicable regulatory bodies at every level (international → national → state → district → local). The user can review and toggle overrides (e.g., mark a regulator as "exempt" with a reason).
9. **Country-aware defaults**: Selecting a country auto-sets timezone, locale, currency, and fiscal year start month from the `geo_countries` table. User can override.
10. **Compliance tracking**: Once regulators are mapped, the system creates `tenant_regulatory_compliance` records with `not_started` status. These serve as a persistent compliance checklist visible in Settings > Geography & Regulatory.
11. **License expiry alerts**: Compliance records with `expiry_date` within 90 days trigger dashboard warnings (implemented in the Dashboard module, not here — but the data model supports it).
12. **Geo data is read-only for tenants**: Only super_admin can import/modify the geographic hierarchy. Tenants select from the pre-seeded data.
13. **Auto-created main facility**: When a tenant is created, a "Main Hospital" facility is auto-created with the tenant's address. The user can rename it or change its type.
14. **Facility-level regulatory mapping**: Each facility gets its own set of applicable regulators. A pharmacy college gets PCI (Pharmacy Council of India), a nursing college gets INC (Indian Nursing Council), a dental college gets DCI (Dental Council of India) — all in addition to the org-wide regulators.
15. **Shared vs independent operations**: Facilities can share billing, pharmacy, lab, and HR with their parent or operate independently. This controls whether data flows across facilities.
16. **Facility-scoped locations/departments**: Locations (buildings, floors, rooms) and departments are scoped to a specific facility. A medical college has different departments than the attached hospital.
17. **User-facility assignment**: Users can be assigned to one or more facilities. A doctor may practice at both the main hospital and a satellite clinic.
18. **Module activation per facility**: Modules can be enabled org-wide or per-facility. The blood bank module only needs to be active for the blood_bank facility, not the entire organization.

---

## 7. Module List (for activation step)

| Code | Name | Dependencies | Default |
|------|------|-------------|---------|
| `patients` | Patient Management | — | Enabled |
| `opd` | Outpatient | patients | Enabled |
| `ipd` | Inpatient | patients | Disabled |
| `lab` | Laboratory | patients | Disabled |
| `pharmacy` | Pharmacy | patients | Disabled |
| `billing` | Billing & Finance | patients | Enabled |
| `radiology` | Radiology/PACS | patients, lab | Disabled |
| `blood_bank` | Blood Bank | patients | Disabled |
| `ot` | Operation Theatre | patients, ipd | Disabled |
| `emergency` | Emergency | patients | Disabled |
| `diet` | Diet & Kitchen | ipd | Disabled |
| `cssd` | CSSD | — | Disabled |
| `hr` | Human Resources | — | Disabled |
| `quality` | Quality / NABH | — | Disabled |
| `mrd` | Medical Records | patients | Disabled |

---

## 8. Pre-seeded Regulatory Bodies (India)

The following regulators are seeded by default for India. Other countries can be added via CSV import.

### International (apply to all)

| Code | Name | Category | Mandatory |
|------|------|----------|-----------|
| `WHO` | World Health Organization | guidelines | No |
| `JCI` | Joint Commission International | accreditation | No |

### National (India-wide)

| Code | Name | Category | Mandatory |
|------|------|----------|-----------|
| `NMC` | National Medical Commission | licensing | Yes |
| `NABH` | National Accreditation Board for Hospitals | accreditation | No |
| `NABL` | National Accreditation Board for Testing & Calibration Labs | lab_accreditation | No |
| `CDSCO` | Central Drugs Standard Control Organisation | drug_control | Yes |
| `AERB` | Atomic Energy Regulatory Board | radiation_safety | Conditional (if radiology/nuclear) |
| `PCPNDT` | Pre-Conception & Pre-Natal Diagnostic Techniques Act | prenatal_diagnostics | Conditional (if ultrasound/genetics) |
| `NOTTO` | National Organ & Tissue Transplant Organisation | organ_transplant | Conditional (if transplant) |
| `NACO` | National AIDS Control Organisation | blood_bank | Conditional (if blood bank) |
| `CPCB` | Central Pollution Control Board | biomedical_waste | Yes |
| `CEA` | Clinical Establishments Act (Registration) | clinical_establishment | Yes |
| `IRDAI` | Insurance Regulatory & Development Authority | insurance_empanelment | No |
| `FSSAI` | Food Safety & Standards Authority | food_safety | Conditional (if kitchen/diet) |
| `POSH` | Prevention of Sexual Harassment Act | workplace_compliance | Yes |
| `FIRE` | Fire Safety (National Building Code) | fire_safety | Yes |

### National — Education & Academic (apply per facility type)

| Code | Name | Category | Applies To |
|------|------|----------|------------|
| `PCI` | Pharmacy Council of India | pharmacy_education | pharmacy_college |
| `INC` | Indian Nursing Council | nursing_education | nursing_college |
| `DCI` | Dental Council of India | dental_education | dental_college |
| `CCIM` | Central Council of Indian Medicine | ayush_education | ayush_college |
| `CCH` | Central Council of Homoeopathy | homeopathy_education | ayush_college |
| `UGC` | University Grants Commission | higher_education | medical_college, pharmacy_college, nursing_college, dental_college |
| `AICTE` | All India Council for Technical Education | technical_education | paramedical_college |
| `NAAC` | National Assessment and Accreditation Council | academic_accreditation | medical_college, nursing_college, pharmacy_college |

### State-level (per state, seeded for all 36 states/UTs)

| Code Pattern | Name | Category |
|-------------|------|----------|
| `{STATE}_SMC` | State Medical Council (e.g., Karnataka Medical Council) | doctor_registration |
| `{STATE}_NRC` | State Nursing Registration Council | nurse_registration |
| `{STATE}_DC` | State Drug Controller | drug_licensing |
| `{STATE}_PCB` | State Pollution Control Board | biomedical_waste |
| `{STATE}_CEA` | State Clinical Establishment Authority | clinical_establishment |

### District-level

| Code Pattern | Name | Category |
|-------------|------|----------|
| `{DIST}_DHO` | District Health Officer | health_oversight |
| `{DIST}_CMHO` | Chief Medical & Health Officer | public_health |

> **Note**: Conditional regulators are auto-included only when the corresponding module is enabled (e.g., AERB is auto-mapped only if Radiology module is active). The module activation step (Step 8) triggers a re-check of applicable regulators.

---

## 9. Geographic Seed Data

### India (ships by default)

| Level | Source | Approximate Count |
|-------|--------|--------------------|
| Country | Manual | 1 (India) + ~10 common countries |
| States | Census of India | 36 (28 states + 8 UTs) |
| Districts | Census 2011 + updates | ~780 |
| Subdistricts | LGDIR / Census | ~6,700 |
| Towns | Census 2011 | ~8,000 statutory towns |
| PIN codes | India Post | ~30,000 mapped to towns |

Seed data is loaded from a SQL file (`seed_geo_india.sql`) during migration. It is NOT tenant-scoped — geographic data is global (shared across all tenants).

### Adding Other Countries

1. Admin uploads CSV with columns: `level, parent_code, code, name, name_local, type`
2. Backend validates hierarchy integrity (every child has a valid parent)
3. Regulatory bodies for the new country must be added separately

---

## 10. Build Priority (Sprint Plan)

### Sprint 1 — Core Wizard (P0)
- [ ] Migration: `onboarding_progress`, `tenant_settings`, `module_config`, `roles`, alter `tenants`
- [ ] Migration: `facilities` table + `facility_type` / `facility_status` enums
- [ ] Migration: `geo_countries`, `geo_states`, `geo_districts`, `geo_subdistricts`, `geo_towns`
- [ ] Migration: `regulatory_bodies`, `facility_regulatory_compliance`
- [ ] Seed: India geographic data (`seed_geo_india.sql` — states, districts, subdistricts, towns, PIN codes)
- [ ] Seed: Regulatory bodies (international + national + education + state-level patterns for India)
- [ ] Backend: `/api/onboarding/*` routes (status, init, progress)
- [ ] Backend: `/api/setup/facilities` routes (CRUD, tree listing)
- [ ] Backend: `/api/geo/*` routes (cascading lookups, PIN reverse-lookup, regulator auto-detect)
- [ ] Backend: `/api/setup/locations`, `/api/setup/departments`, `/api/setup/users`, `/api/setup/roles`
- [ ] Backend: `/api/setup/compliance` routes (per-facility)
- [ ] Frontend: Wizard container with Stepper (12 steps)
- [ ] Frontend: Steps 1-3 (Welcome, Admin, Hospital/Organization)
- [ ] Frontend: Step 4 (GeoRegulatoryStep — cascading dropdowns, PIN lookup, regulator checklist)
- [ ] Frontend: Step 5 (FacilitiesStep — add sub-institutions, set types, addresses)
- [ ] Frontend: Steps 6-7 (Locations per facility, Departments per facility)
- [ ] Frontend: Step 8 (Users & Roles, assign to facilities)
- [ ] Frontend: Step 9 (Module activation — org-wide or per facility)
- [ ] Frontend: Step 12 (Review & Launch)
- [ ] Routing: redirect to `/onboarding` when no tenant exists

### Sprint 2 — Extended Setup (P1)
- [ ] Frontend: Step 9 (Sequences)
- [ ] Frontend: Step 10 (Branding)
- [ ] Backend: `/api/setup/modules`, `/api/setup/sequences`, `/api/setup/branding`
- [ ] Settings page (post-onboarding access to same data)
- [ ] Settings: Geography & Regulatory tab (compliance tracking, license upload, expiry dates)
- [ ] CSV import for locations, departments, users
- [ ] CSV import for geographic data (other countries)
- [ ] Pre-built department templates

### Sprint 3 — Polish (P2-P3)
- [ ] Demo mode with sample data
- [ ] In-app guided tours
- [ ] Integration setup (email, SMS)
- [ ] API docs generation
- [ ] Docker one-command setup refinement
- [ ] Compliance expiry dashboard widget
- [ ] Geo data for additional countries (US, UK, UAE, etc.)

---

## 11. Dependencies

| Depends On | Why |
|-----------|-----|
| Auth module | Login/JWT for protected wizard steps |
| Database migrations 001+002 | Base tables (tenants, users, locations, departments, services, sequences) |

| Blocks | Why |
|--------|-----|
| Every other module | Modules can't function without tenant, users, departments, locations |

---

## 12. Open Questions

1. **Multi-tenant onboarding**: Should additional tenants be created from a "super-admin" panel or from the same wizard? → Deferred to P3.
2. **Custom roles vs enum**: Currently `user_role` is a Postgres enum. The new `roles` table adds flexibility. Should we migrate away from the enum? → Yes, gradually. Keep enum for backward compat, add `role_id` FK to users table pointing to `roles`.
3. **File storage**: Local filesystem for now. S3-compatible storage deferred to Technical Infrastructure module.
4. **PostGIS vs plain columns**: Should we use PostGIS `GEOMETRY(Point, 4326)` for hospital coordinates (enables spatial queries like "find nearest facility") or keep simple `latitude`/`longitude` DOUBLE PRECISION? → Start with plain columns. PostGIS can be added later without breaking changes; it's an extension dependency we don't want to mandate for all deployments.
5. **Geo data freshness**: Indian Census data is from 2011 with periodic updates. Who maintains the seed data? → Community-maintained seed files in the repo. Users can submit PRs to update district/subdistrict data. The system also supports admin CSV import for corrections.
6. **State-specific regulatory variations**: Some states have unique regulatory requirements (e.g., Kerala has additional clinical establishment rules). How granular should we go? → Start with the common national + state pattern. State-specific overrides can be added as `config` JSONB on the regulatory body record.
7. **Multi-country deployment**: A hospital chain operating across countries needs different regulatory mappings per location. → Handled by the `tenant → geo hierarchy` linkage. Each tenant has one country/state/district. Multi-location chains use separate tenants per location (multi-tenant by design).
