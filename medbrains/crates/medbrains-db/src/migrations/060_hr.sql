-- 060_hr.sql — HR & Staff Management module
-- Enums, tables, RLS policies, indexes, triggers

-- ══════════════════════════════════════════════════════
--  ENUMS
-- ══════════════════════════════════════════════════════

CREATE TYPE employment_type AS ENUM (
    'permanent', 'contract', 'visiting', 'intern', 'resident',
    'fellow', 'volunteer', 'outsourced'
);

CREATE TYPE employee_status AS ENUM (
    'active', 'on_leave', 'suspended', 'resigned',
    'terminated', 'retired', 'absconding'
);

CREATE TYPE credential_type AS ENUM (
    'medical_council', 'nursing_council', 'pharmacy_council',
    'dental_council', 'other_council',
    'bls', 'acls', 'pals', 'nals',
    'fire_safety', 'radiation_safety', 'nabh_orientation'
);

CREATE TYPE credential_status AS ENUM (
    'active', 'expired', 'suspended', 'revoked', 'pending_renewal'
);

CREATE TYPE leave_type AS ENUM (
    'casual', 'earned', 'medical', 'maternity', 'paternity',
    'compensatory', 'study', 'special', 'loss_of_pay'
);

CREATE TYPE leave_status AS ENUM (
    'draft', 'pending_hod', 'pending_admin', 'approved',
    'rejected', 'cancelled'
);

CREATE TYPE shift_type AS ENUM (
    'morning', 'afternoon', 'evening', 'night',
    'general', 'split', 'on_call', 'custom'
);

CREATE TYPE training_status AS ENUM (
    'scheduled', 'in_progress', 'completed', 'cancelled', 'failed'
);

-- ══════════════════════════════════════════════════════
--  TABLES
-- ══════════════════════════════════════════════════════

-- 1. Designations
CREATE TABLE designations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    level       INT NOT NULL DEFAULT 0,
    category    TEXT NOT NULL DEFAULT 'clinical',
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

ALTER TABLE designations ENABLE ROW LEVEL SECURITY;
CREATE POLICY designations_tenant ON designations
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_designations_tenant ON designations (tenant_id);
CREATE TRIGGER trg_designations_updated_at BEFORE UPDATE ON designations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. Employees
CREATE TABLE employees (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    user_id          UUID REFERENCES users(id),
    employee_code    TEXT NOT NULL,
    first_name       TEXT NOT NULL,
    last_name        TEXT,
    date_of_birth    DATE,
    gender           TEXT,
    phone            TEXT,
    email            TEXT,
    employment_type  employment_type NOT NULL DEFAULT 'permanent',
    status           employee_status NOT NULL DEFAULT 'active',
    department_id    UUID REFERENCES departments(id),
    designation_id   UUID REFERENCES designations(id),
    reporting_to     UUID REFERENCES employees(id),
    date_of_joining  DATE NOT NULL DEFAULT CURRENT_DATE,
    date_of_leaving  DATE,
    qualifications   JSONB NOT NULL DEFAULT '[]',
    blood_group      TEXT,
    address          JSONB NOT NULL DEFAULT '{}',
    emergency_contact JSONB NOT NULL DEFAULT '{}',
    bank_name        TEXT,
    bank_account     TEXT,
    bank_ifsc        TEXT,
    pf_number        TEXT,
    esi_number       TEXT,
    uan_number       TEXT,
    pan_number       TEXT,
    aadhaar_number   TEXT,
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, employee_code)
);

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY employees_tenant ON employees
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_employees_tenant ON employees (tenant_id);
CREATE INDEX idx_employees_department ON employees (tenant_id, department_id);
CREATE INDEX idx_employees_status ON employees (tenant_id, status);
CREATE INDEX idx_employees_user ON employees (tenant_id, user_id);
CREATE TRIGGER trg_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. Employee Credentials (NMC/IMC registration, certifications)
CREATE TABLE employee_credentials (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    employee_id      UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    credential_type  credential_type NOT NULL,
    issuing_body     TEXT NOT NULL,
    registration_no  TEXT NOT NULL,
    state_code       TEXT,
    issued_date      DATE,
    expiry_date      DATE,
    status           credential_status NOT NULL DEFAULT 'active',
    verified_by      UUID REFERENCES users(id),
    verified_at      TIMESTAMPTZ,
    document_url     TEXT,
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE employee_credentials ENABLE ROW LEVEL SECURITY;
CREATE POLICY employee_credentials_tenant ON employee_credentials
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_employee_credentials_tenant ON employee_credentials (tenant_id);
CREATE INDEX idx_employee_credentials_employee ON employee_credentials (tenant_id, employee_id);
CREATE INDEX idx_employee_credentials_expiry ON employee_credentials (tenant_id, expiry_date)
    WHERE status = 'active';
CREATE TRIGGER trg_employee_credentials_updated_at BEFORE UPDATE ON employee_credentials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. Shift Definitions
CREATE TABLE shift_definitions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    code           TEXT NOT NULL,
    name           TEXT NOT NULL,
    shift_type     shift_type NOT NULL DEFAULT 'general',
    start_time     TIME NOT NULL,
    end_time       TIME NOT NULL,
    break_minutes  INT NOT NULL DEFAULT 0,
    is_night       BOOLEAN NOT NULL DEFAULT FALSE,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

ALTER TABLE shift_definitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY shift_definitions_tenant ON shift_definitions
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_shift_definitions_tenant ON shift_definitions (tenant_id);
CREATE TRIGGER trg_shift_definitions_updated_at BEFORE UPDATE ON shift_definitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 5. Duty Rosters
CREATE TABLE duty_rosters (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    employee_id    UUID NOT NULL REFERENCES employees(id),
    department_id  UUID REFERENCES departments(id),
    shift_id       UUID NOT NULL REFERENCES shift_definitions(id),
    roster_date    DATE NOT NULL,
    is_on_call     BOOLEAN NOT NULL DEFAULT FALSE,
    swap_with      UUID REFERENCES employees(id),
    swap_approved  BOOLEAN NOT NULL DEFAULT FALSE,
    notes          TEXT,
    created_by     UUID NOT NULL REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, employee_id, roster_date)
);

ALTER TABLE duty_rosters ENABLE ROW LEVEL SECURITY;
CREATE POLICY duty_rosters_tenant ON duty_rosters
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_duty_rosters_tenant ON duty_rosters (tenant_id);
CREATE INDEX idx_duty_rosters_date ON duty_rosters (tenant_id, roster_date);
CREATE INDEX idx_duty_rosters_employee ON duty_rosters (tenant_id, employee_id, roster_date);
CREATE TRIGGER trg_duty_rosters_updated_at BEFORE UPDATE ON duty_rosters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 6. Attendance Records
CREATE TABLE attendance_records (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    employee_id      UUID NOT NULL REFERENCES employees(id),
    attendance_date  DATE NOT NULL,
    shift_id         UUID REFERENCES shift_definitions(id),
    check_in         TIMESTAMPTZ,
    check_out        TIMESTAMPTZ,
    is_late          BOOLEAN NOT NULL DEFAULT FALSE,
    late_minutes     INT NOT NULL DEFAULT 0,
    is_early_out     BOOLEAN NOT NULL DEFAULT FALSE,
    early_minutes    INT NOT NULL DEFAULT 0,
    overtime_minutes INT NOT NULL DEFAULT 0,
    status           TEXT NOT NULL DEFAULT 'present',
    source           TEXT NOT NULL DEFAULT 'manual',
    notes            TEXT,
    recorded_by      UUID NOT NULL REFERENCES users(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, employee_id, attendance_date)
);

ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY attendance_records_tenant ON attendance_records
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_attendance_records_tenant ON attendance_records (tenant_id);
CREATE INDEX idx_attendance_records_date ON attendance_records (tenant_id, attendance_date);
CREATE INDEX idx_attendance_records_employee ON attendance_records (tenant_id, employee_id, attendance_date);
CREATE TRIGGER trg_attendance_records_updated_at BEFORE UPDATE ON attendance_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 7. Leave Balances
CREATE TABLE leave_balances (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    employee_id    UUID NOT NULL REFERENCES employees(id),
    leave_type     leave_type NOT NULL,
    year           INT NOT NULL,
    opening        NUMERIC(5,1) NOT NULL DEFAULT 0,
    earned         NUMERIC(5,1) NOT NULL DEFAULT 0,
    used           NUMERIC(5,1) NOT NULL DEFAULT 0,
    balance        NUMERIC(5,1) NOT NULL DEFAULT 0,
    carry_forward  NUMERIC(5,1) NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, employee_id, leave_type, year)
);

ALTER TABLE leave_balances ENABLE ROW LEVEL SECURITY;
CREATE POLICY leave_balances_tenant ON leave_balances
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_leave_balances_tenant ON leave_balances (tenant_id);
CREATE INDEX idx_leave_balances_employee ON leave_balances (tenant_id, employee_id, year);
CREATE TRIGGER trg_leave_balances_updated_at BEFORE UPDATE ON leave_balances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 8. Leave Requests
CREATE TABLE leave_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    employee_id     UUID NOT NULL REFERENCES employees(id),
    leave_type      leave_type NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    days            NUMERIC(4,1) NOT NULL DEFAULT 1,
    is_half_day     BOOLEAN NOT NULL DEFAULT FALSE,
    reason          TEXT,
    status          leave_status NOT NULL DEFAULT 'draft',
    hod_id          UUID REFERENCES users(id),
    hod_action_at   TIMESTAMPTZ,
    hod_remarks     TEXT,
    admin_id        UUID REFERENCES users(id),
    admin_action_at TIMESTAMPTZ,
    admin_remarks   TEXT,
    cancelled_by    UUID REFERENCES users(id),
    cancelled_at    TIMESTAMPTZ,
    cancel_reason   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY leave_requests_tenant ON leave_requests
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_leave_requests_tenant ON leave_requests (tenant_id);
CREATE INDEX idx_leave_requests_employee ON leave_requests (tenant_id, employee_id);
CREATE INDEX idx_leave_requests_status ON leave_requests (tenant_id, status);
CREATE TRIGGER trg_leave_requests_updated_at BEFORE UPDATE ON leave_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 9. On-Call Schedules
CREATE TABLE on_call_schedules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    employee_id     UUID NOT NULL REFERENCES employees(id),
    department_id   UUID REFERENCES departments(id),
    schedule_date   DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    is_primary      BOOLEAN NOT NULL DEFAULT TRUE,
    contact_number  TEXT,
    notes           TEXT,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE on_call_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY on_call_schedules_tenant ON on_call_schedules
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_on_call_schedules_tenant ON on_call_schedules (tenant_id);
CREATE INDEX idx_on_call_schedules_date ON on_call_schedules (tenant_id, schedule_date);
CREATE TRIGGER trg_on_call_schedules_updated_at BEFORE UPDATE ON on_call_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 10. Training Programs
CREATE TABLE training_programs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    code             TEXT NOT NULL,
    name             TEXT NOT NULL,
    description      TEXT,
    is_mandatory     BOOLEAN NOT NULL DEFAULT FALSE,
    frequency_months INT,
    duration_hours   NUMERIC(5,1),
    target_roles     JSONB NOT NULL DEFAULT '[]',
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

ALTER TABLE training_programs ENABLE ROW LEVEL SECURITY;
CREATE POLICY training_programs_tenant ON training_programs
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_training_programs_tenant ON training_programs (tenant_id);
CREATE TRIGGER trg_training_programs_updated_at BEFORE UPDATE ON training_programs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 11. Training Records
CREATE TABLE training_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    employee_id     UUID NOT NULL REFERENCES employees(id),
    program_id      UUID NOT NULL REFERENCES training_programs(id),
    training_date   DATE NOT NULL,
    status          training_status NOT NULL DEFAULT 'scheduled',
    score           NUMERIC(5,1),
    certificate_no  TEXT,
    expiry_date     DATE,
    trainer_name    TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE training_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY training_records_tenant ON training_records
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_training_records_tenant ON training_records (tenant_id);
CREATE INDEX idx_training_records_employee ON training_records (tenant_id, employee_id);
CREATE TRIGGER trg_training_records_updated_at BEFORE UPDATE ON training_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 12. Appraisals
CREATE TABLE appraisals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    employee_id     UUID NOT NULL REFERENCES employees(id),
    appraisal_year  INT NOT NULL,
    appraiser_id    UUID REFERENCES users(id),
    rating          NUMERIC(3,1),
    strengths       TEXT,
    improvements    TEXT,
    goals           JSONB NOT NULL DEFAULT '[]',
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, employee_id, appraisal_year)
);

ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;
CREATE POLICY appraisals_tenant ON appraisals
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_appraisals_tenant ON appraisals (tenant_id);
CREATE INDEX idx_appraisals_employee ON appraisals (tenant_id, employee_id);
CREATE TRIGGER trg_appraisals_updated_at BEFORE UPDATE ON appraisals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 13. Statutory Records (POSH, fire safety, etc.)
CREATE TABLE statutory_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    employee_id     UUID NOT NULL REFERENCES employees(id),
    record_type     TEXT NOT NULL,
    title           TEXT NOT NULL,
    compliance_date DATE,
    expiry_date     DATE,
    details         JSONB NOT NULL DEFAULT '{}',
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE statutory_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY statutory_records_tenant ON statutory_records
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_statutory_records_tenant ON statutory_records (tenant_id);
CREATE INDEX idx_statutory_records_employee ON statutory_records (tenant_id, employee_id);
CREATE TRIGGER trg_statutory_records_updated_at BEFORE UPDATE ON statutory_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
