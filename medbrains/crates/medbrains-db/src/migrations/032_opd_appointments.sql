-- ============================================================
-- 032: OPD Appointments — Doctor Schedules & Appointment Booking
-- ============================================================

-- Appointment status enum
CREATE TYPE appointment_status AS ENUM (
    'scheduled',
    'confirmed',
    'checked_in',
    'in_consultation',
    'completed',
    'cancelled',
    'no_show'
);

-- Appointment type enum
CREATE TYPE appointment_type AS ENUM (
    'new_visit',
    'follow_up',
    'consultation',
    'procedure',
    'walk_in'
);

-- ============================================================
-- 1. Doctor Schedules — weekly availability slots
-- ============================================================

CREATE TABLE doctor_schedules (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    doctor_id           UUID NOT NULL REFERENCES users(id),
    department_id       UUID NOT NULL REFERENCES departments(id),
    day_of_week         INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sunday, 6=Saturday
    start_time          TIME NOT NULL,
    end_time            TIME NOT NULL,
    slot_duration_mins  INT NOT NULL DEFAULT 15 CHECK (slot_duration_mins > 0),
    max_patients        INT NOT NULL DEFAULT 20 CHECK (max_patients > 0),
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_schedule_time CHECK (end_time > start_time),
    UNIQUE (tenant_id, doctor_id, department_id, day_of_week)
);

ALTER TABLE doctor_schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_doctor_schedules ON doctor_schedules
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_doctor_schedules_doctor ON doctor_schedules(tenant_id, doctor_id);
CREATE INDEX idx_doctor_schedules_dept ON doctor_schedules(tenant_id, department_id);

-- ============================================================
-- 2. Doctor Schedule Exceptions — holidays, leaves, overrides
-- ============================================================

CREATE TABLE doctor_schedule_exceptions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    exception_date  DATE NOT NULL,
    is_available    BOOLEAN NOT NULL DEFAULT false,  -- false=unavailable, true=extra availability
    start_time      TIME,           -- if is_available=true, override slot times
    end_time        TIME,
    reason          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, doctor_id, exception_date)
);

ALTER TABLE doctor_schedule_exceptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_doctor_schedule_exceptions ON doctor_schedule_exceptions
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_doctor_schedule_exceptions_date ON doctor_schedule_exceptions(tenant_id, doctor_id, exception_date);

-- ============================================================
-- 3. Appointments — booked patient visits
-- ============================================================

CREATE TABLE appointments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    doctor_id           UUID NOT NULL REFERENCES users(id),
    department_id       UUID NOT NULL REFERENCES departments(id),
    appointment_date    DATE NOT NULL,
    slot_start          TIME NOT NULL,
    slot_end            TIME NOT NULL,
    appointment_type    appointment_type NOT NULL DEFAULT 'new_visit',
    status              appointment_status NOT NULL DEFAULT 'scheduled',
    token_number        INT,
    reason              TEXT,               -- reason for visit
    cancel_reason       TEXT,               -- reason for cancellation
    notes               TEXT,               -- admin/reception notes
    encounter_id        UUID REFERENCES encounters(id),  -- linked after check-in
    checked_in_at       TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    cancelled_at        TIMESTAMPTZ,
    created_by          UUID NOT NULL REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_appointments ON appointments
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_appointments_date ON appointments(tenant_id, appointment_date);
CREATE INDEX idx_appointments_doctor ON appointments(tenant_id, doctor_id, appointment_date);
CREATE INDEX idx_appointments_patient ON appointments(tenant_id, patient_id);
CREATE INDEX idx_appointments_status ON appointments(tenant_id, status) WHERE status NOT IN ('completed', 'cancelled');
CREATE INDEX idx_appointments_encounter ON appointments(encounter_id) WHERE encounter_id IS NOT NULL;
