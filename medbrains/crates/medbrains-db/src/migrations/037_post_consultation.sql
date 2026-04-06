-- Migration 037: Post-Consultation Features
-- Adds doctor dockets, patient reminders, feedback collection, and procedure consents.

-- ============================================================
-- Doctor Dockets — daily case summary
-- ============================================================

CREATE TABLE IF NOT EXISTS doctor_dockets (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    docket_date     DATE NOT NULL,
    total_patients  INT NOT NULL DEFAULT 0,
    new_patients    INT NOT NULL DEFAULT 0,
    follow_ups      INT NOT NULL DEFAULT 0,
    referrals_made  INT NOT NULL DEFAULT 0,
    procedures_done INT NOT NULL DEFAULT 0,
    notes           TEXT,
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, doctor_id, docket_date)
);

CREATE INDEX idx_dockets_tenant ON doctor_dockets(tenant_id);
CREATE INDEX idx_dockets_doctor_date ON doctor_dockets(doctor_id, docket_date DESC);

ALTER TABLE doctor_dockets ENABLE ROW LEVEL SECURITY;
CREATE POLICY doctor_dockets_tenant ON doctor_dockets
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ============================================================
-- Patient Reminders — follow-up review reminders
-- ============================================================

CREATE TABLE IF NOT EXISTS patient_reminders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID REFERENCES encounters(id),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    reminder_type   VARCHAR(30) NOT NULL CHECK (reminder_type IN (
        'follow_up', 'lab_review', 'medication_review',
        'vaccination', 'screening', 'custom'
    )),
    reminder_date   DATE NOT NULL,
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    priority        VARCHAR(10) NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'sent', 'acknowledged', 'completed', 'cancelled', 'overdue'
    )),
    notification_channels TEXT[] DEFAULT '{}'::text[],
    completed_at    TIMESTAMPTZ,
    cancelled_at    TIMESTAMPTZ,
    cancel_reason   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reminders_tenant ON patient_reminders(tenant_id);
CREATE INDEX idx_reminders_patient ON patient_reminders(patient_id);
CREATE INDEX idx_reminders_doctor_date ON patient_reminders(doctor_id, reminder_date);
CREATE INDEX idx_reminders_status_date ON patient_reminders(status, reminder_date);

ALTER TABLE patient_reminders ENABLE ROW LEVEL SECURITY;
CREATE POLICY patient_reminders_tenant ON patient_reminders
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ============================================================
-- Patient Feedback — post-visit feedback collection
-- ============================================================

CREATE TABLE IF NOT EXISTS patient_feedback (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID REFERENCES encounters(id),
    doctor_id       UUID REFERENCES users(id),
    department_id   UUID REFERENCES departments(id),
    rating          INT CHECK (rating BETWEEN 1 AND 5),
    wait_time_rating INT CHECK (wait_time_rating BETWEEN 1 AND 5),
    staff_rating    INT CHECK (staff_rating BETWEEN 1 AND 5),
    cleanliness_rating INT CHECK (cleanliness_rating BETWEEN 1 AND 5),
    overall_experience TEXT,
    suggestions     TEXT,
    would_recommend BOOLEAN,
    is_anonymous    BOOLEAN NOT NULL DEFAULT false,
    submitted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_feedback_tenant ON patient_feedback(tenant_id);
CREATE INDEX idx_feedback_doctor ON patient_feedback(doctor_id);
CREATE INDEX idx_feedback_encounter ON patient_feedback(encounter_id);

ALTER TABLE patient_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY patient_feedback_tenant ON patient_feedback
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ============================================================
-- Procedure Consents — digital consent workflow
-- ============================================================

CREATE TABLE IF NOT EXISTS procedure_consents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID REFERENCES encounters(id),
    procedure_order_id UUID REFERENCES procedure_orders(id),
    procedure_name  VARCHAR(200) NOT NULL,
    consent_type    VARCHAR(30) NOT NULL DEFAULT 'procedure' CHECK (consent_type IN (
        'procedure', 'anesthesia', 'blood_transfusion',
        'surgery', 'investigation', 'general'
    )),
    risks_explained TEXT,
    alternatives_explained TEXT,
    benefits_explained TEXT,
    patient_questions TEXT,
    consented_by_name VARCHAR(200),
    consented_by_relation VARCHAR(50),
    witness_name    VARCHAR(200),
    witness_designation VARCHAR(100),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'signed', 'refused', 'withdrawn', 'expired'
    )),
    signed_at       TIMESTAMPTZ,
    refused_at      TIMESTAMPTZ,
    refusal_reason  TEXT,
    withdrawn_at    TIMESTAMPTZ,
    withdrawal_reason TEXT,
    expires_at      TIMESTAMPTZ,
    body            JSONB DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_consents_tenant ON procedure_consents(tenant_id);
CREATE INDEX idx_consents_patient ON procedure_consents(patient_id);
CREATE INDEX idx_consents_encounter ON procedure_consents(encounter_id);
CREATE INDEX idx_consents_procedure_order ON procedure_consents(procedure_order_id);

ALTER TABLE procedure_consents ENABLE ROW LEVEL SECURITY;
CREATE POLICY procedure_consents_tenant ON procedure_consents
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
