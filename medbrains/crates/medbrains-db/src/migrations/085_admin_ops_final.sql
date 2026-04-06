-- ═══════════════════════════════════════════════════════════════
--  Migration 085 — Admin & Operations Final (4 modules)
--  Occupational Health, Utilization Review, Case Management,
--  Scheduling / No-Show AI
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
--  1. ENUMS
-- ═══════════════════════════════════════════════════════════════

CREATE TYPE drug_screen_status AS ENUM (
    'ordered',
    'collected',
    'sent_to_lab',
    'mro_review',
    'positive',
    'negative',
    'inconclusive',
    'cancelled'
);

CREATE TYPE rtw_clearance_status AS ENUM (
    'pending_evaluation',
    'cleared_full',
    'cleared_with_restrictions',
    'not_cleared',
    'follow_up_required'
);

CREATE TYPE ur_review_type AS ENUM (
    'pre_admission',
    'admission',
    'continued_stay',
    'retrospective'
);

CREATE TYPE ur_decision AS ENUM (
    'approved',
    'denied',
    'pending_info',
    'modified',
    'escalated'
);

CREATE TYPE case_mgmt_status AS ENUM (
    'assigned',
    'active',
    'pending_discharge',
    'discharged',
    'closed'
);

CREATE TYPE discharge_barrier_type AS ENUM (
    'insurance_auth',
    'placement',
    'equipment',
    'family',
    'transport',
    'financial',
    'clinical',
    'documentation',
    'other'
);

-- ═══════════════════════════════════════════════════════════════
--  2. TABLES — Occupational Health
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE occ_health_screenings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    employee_id         UUID NOT NULL REFERENCES employees(id),
    examiner_id         UUID REFERENCES users(id),
    screening_type      TEXT NOT NULL CHECK (screening_type IN ('pre_employment', 'periodic', 'special', 'exit')),
    screening_date      DATE NOT NULL,
    fitness_status      TEXT NOT NULL DEFAULT 'pending' CHECK (fitness_status IN ('pending', 'fit', 'fit_with_restrictions', 'unfit', 'referred')),
    findings            JSONB NOT NULL DEFAULT '{}',
    restrictions        JSONB NOT NULL DEFAULT '[]',
    next_due_date       DATE,
    notes               TEXT,
    created_by          UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE occ_health_drug_screens (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    employee_id         UUID NOT NULL REFERENCES employees(id),
    screening_id        UUID REFERENCES occ_health_screenings(id),
    specimen_id         TEXT,
    status              drug_screen_status NOT NULL DEFAULT 'ordered',
    chain_of_custody    JSONB NOT NULL DEFAULT '{}',
    panel               TEXT NOT NULL DEFAULT 'standard_5',
    results             JSONB NOT NULL DEFAULT '{}',
    mro_reviewer_id     UUID REFERENCES users(id),
    mro_decision        TEXT,
    mro_reviewed_at     TIMESTAMPTZ,
    collected_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE occ_health_vaccinations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    employee_id         UUID NOT NULL REFERENCES employees(id),
    vaccine_name        TEXT NOT NULL,
    dose_number         INT NOT NULL DEFAULT 1,
    administered_date   DATE NOT NULL,
    batch_number        TEXT,
    administered_by     UUID REFERENCES users(id),
    next_due_date       DATE,
    is_compliant        BOOLEAN NOT NULL DEFAULT true,
    exemption_type      TEXT,
    exemption_reason    TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE occ_health_injury_reports (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    employee_id             UUID NOT NULL REFERENCES employees(id),
    report_number           TEXT NOT NULL,
    injury_date             DATE NOT NULL,
    injury_type             TEXT NOT NULL,
    injury_description      TEXT,
    body_part_affected      TEXT,
    location_of_incident    TEXT,
    is_osha_recordable      BOOLEAN NOT NULL DEFAULT false,
    lost_work_days          INT NOT NULL DEFAULT 0,
    restricted_days         INT NOT NULL DEFAULT 0,
    workers_comp_claim_number TEXT,
    workers_comp_status     TEXT,
    rtw_status              rtw_clearance_status NOT NULL DEFAULT 'pending_evaluation',
    rtw_restrictions        JSONB NOT NULL DEFAULT '[]',
    rtw_cleared_date        DATE,
    rtw_cleared_by          UUID REFERENCES users(id),
    employer_access_notes   TEXT,
    reported_by             UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════
--  3. TABLES — Utilization Review
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE utilization_reviews (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    admission_id        UUID NOT NULL REFERENCES admissions(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    reviewer_id         UUID REFERENCES users(id),
    review_type         ur_review_type NOT NULL,
    review_date         DATE NOT NULL DEFAULT CURRENT_DATE,
    patient_status      TEXT NOT NULL DEFAULT 'inpatient' CHECK (patient_status IN ('inpatient', 'observation')),
    decision            ur_decision NOT NULL DEFAULT 'pending_info',
    criteria_source     TEXT,
    criteria_met        JSONB NOT NULL DEFAULT '[]',
    clinical_summary    TEXT,
    expected_los_days   INT,
    actual_los_days     INT,
    is_outlier          BOOLEAN NOT NULL DEFAULT false,
    approved_days       INT,
    next_review_date    DATE,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ur_payer_communications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    review_id           UUID NOT NULL REFERENCES utilization_reviews(id),
    communication_type  TEXT NOT NULL CHECK (communication_type IN ('initial_auth', 'continued_stay', 'denial_appeal', 'peer_review', 'info_request', 'response')),
    payer_name          TEXT NOT NULL,
    reference_number    TEXT,
    communicated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    summary             TEXT,
    response            TEXT,
    attachments         JSONB NOT NULL DEFAULT '[]',
    communicated_by     UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ur_status_conversions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    admission_id        UUID NOT NULL REFERENCES admissions(id),
    from_status         TEXT NOT NULL,
    to_status           TEXT NOT NULL,
    conversion_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    reason              TEXT,
    effective_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
    converted_by        UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════
--  4. TABLES — Case Management
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE case_assignments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    admission_id            UUID NOT NULL REFERENCES admissions(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    case_manager_id         UUID NOT NULL REFERENCES users(id),
    status                  case_mgmt_status NOT NULL DEFAULT 'assigned',
    priority                TEXT NOT NULL DEFAULT 'routine' CHECK (priority IN ('routine', 'urgent', 'complex')),
    target_discharge_date   DATE,
    actual_discharge_date   DATE,
    discharge_disposition   TEXT,
    disposition_details     JSONB NOT NULL DEFAULT '{}',
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, admission_id)
);

CREATE TABLE discharge_barriers (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    case_assignment_id      UUID NOT NULL REFERENCES case_assignments(id) ON DELETE CASCADE,
    barrier_type            discharge_barrier_type NOT NULL,
    description             TEXT NOT NULL,
    identified_date         DATE NOT NULL DEFAULT CURRENT_DATE,
    is_resolved             BOOLEAN NOT NULL DEFAULT false,
    resolved_date           DATE,
    resolved_by             UUID REFERENCES users(id),
    escalated_to            TEXT,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE case_referrals (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    case_assignment_id      UUID NOT NULL REFERENCES case_assignments(id) ON DELETE CASCADE,
    referral_type           TEXT NOT NULL CHECK (referral_type IN ('post_acute', 'rehab', 'home_health', 'social_work', 'hospice', 'snf', 'other')),
    referred_to             TEXT NOT NULL,
    status                  TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'cancelled')),
    facility_details        JSONB NOT NULL DEFAULT '{}',
    outcome                 TEXT,
    referred_by             UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════
--  5. TABLES — Scheduling / No-Show AI
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE noshow_prediction_scores (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                   UUID NOT NULL REFERENCES tenants(id),
    appointment_id              UUID NOT NULL REFERENCES appointments(id),
    patient_id                  UUID NOT NULL REFERENCES patients(id),
    predicted_noshow_probability NUMERIC(5,4) NOT NULL,
    risk_level                  TEXT NOT NULL CHECK (risk_level IN ('low', 'medium', 'high')),
    features_used               JSONB NOT NULL DEFAULT '{}',
    model_version               TEXT NOT NULL DEFAULT 'v0-stub',
    scored_at                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE scheduling_waitlist (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    doctor_id               UUID REFERENCES users(id),
    department_id           UUID REFERENCES departments(id),
    preferred_date_from     DATE,
    preferred_date_to       DATE,
    preferred_time_from     TIME,
    preferred_time_to       TIME,
    priority                TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    status                  TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'offered', 'booked', 'expired', 'cancelled')),
    offered_appointment_id  UUID REFERENCES appointments(id),
    reason                  TEXT,
    created_by              UUID REFERENCES users(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE scheduling_overbooking_rules (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                       UUID NOT NULL REFERENCES tenants(id),
    doctor_id                       UUID NOT NULL REFERENCES users(id),
    department_id                   UUID NOT NULL REFERENCES departments(id),
    day_of_week                     INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    max_overbook_slots              INT NOT NULL DEFAULT 2,
    overbook_threshold_probability  NUMERIC(3,2) NOT NULL DEFAULT 0.30,
    is_active                       BOOLEAN NOT NULL DEFAULT true,
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, doctor_id, department_id, day_of_week)
);

-- ═══════════════════════════════════════════════════════════════
--  6. ROW-LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE occ_health_screenings ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON occ_health_screenings
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE occ_health_drug_screens ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON occ_health_drug_screens
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE occ_health_vaccinations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON occ_health_vaccinations
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE occ_health_injury_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON occ_health_injury_reports
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE utilization_reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON utilization_reviews
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE ur_payer_communications ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ur_payer_communications
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE ur_status_conversions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ur_status_conversions
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE case_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON case_assignments
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE discharge_barriers ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON discharge_barriers
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE case_referrals ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON case_referrals
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE noshow_prediction_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON noshow_prediction_scores
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE scheduling_waitlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON scheduling_waitlist
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

ALTER TABLE scheduling_overbooking_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON scheduling_overbooking_rules
    USING (tenant_id = (current_setting('app.tenant_id')::uuid));

-- ═══════════════════════════════════════════════════════════════
--  7. TRIGGERS
-- ═══════════════════════════════════════════════════════════════

CREATE TRIGGER set_updated_at_occ_health_screenings
    BEFORE UPDATE ON occ_health_screenings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_occ_health_drug_screens
    BEFORE UPDATE ON occ_health_drug_screens FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_occ_health_vaccinations
    BEFORE UPDATE ON occ_health_vaccinations FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_occ_health_injury_reports
    BEFORE UPDATE ON occ_health_injury_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_utilization_reviews
    BEFORE UPDATE ON utilization_reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_ur_payer_communications
    BEFORE UPDATE ON ur_payer_communications FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_ur_status_conversions
    BEFORE UPDATE ON ur_status_conversions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_case_assignments
    BEFORE UPDATE ON case_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_discharge_barriers
    BEFORE UPDATE ON discharge_barriers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_case_referrals
    BEFORE UPDATE ON case_referrals FOR EACH ROW EXECUTE FUNCTION update_updated_at();
-- noshow_prediction_scores is IMMUTABLE — no update trigger
CREATE TRIGGER set_updated_at_scheduling_waitlist
    BEFORE UPDATE ON scheduling_waitlist FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at_scheduling_overbooking_rules
    BEFORE UPDATE ON scheduling_overbooking_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ═══════════════════════════════════════════════════════════════
--  8. INDEXES
-- ═══════════════════════════════════════════════════════════════

-- Occupational Health
CREATE INDEX idx_occ_screenings_employee ON occ_health_screenings(tenant_id, employee_id);
CREATE INDEX idx_occ_screenings_due ON occ_health_screenings(tenant_id, next_due_date) WHERE next_due_date IS NOT NULL;
CREATE INDEX idx_occ_drug_screens_employee ON occ_health_drug_screens(tenant_id, employee_id);
CREATE INDEX idx_occ_vaccinations_employee ON occ_health_vaccinations(tenant_id, employee_id, is_compliant);
CREATE INDEX idx_occ_injuries_employee ON occ_health_injury_reports(tenant_id, employee_id);
CREATE INDEX idx_occ_injuries_rtw ON occ_health_injury_reports(tenant_id, rtw_status) WHERE rtw_status != 'cleared_full';

-- Utilization Review
CREATE INDEX idx_ur_reviews_admission ON utilization_reviews(tenant_id, admission_id);
CREATE INDEX idx_ur_reviews_outlier ON utilization_reviews(tenant_id, is_outlier) WHERE is_outlier = true;
CREATE INDEX idx_ur_reviews_next_review ON utilization_reviews(tenant_id, next_review_date) WHERE next_review_date IS NOT NULL;
CREATE INDEX idx_ur_communications_review ON ur_payer_communications(tenant_id, review_id);
CREATE INDEX idx_ur_conversions_admission ON ur_status_conversions(tenant_id, admission_id);

-- Case Management
CREATE INDEX idx_case_assignments_manager ON case_assignments(tenant_id, case_manager_id, status);
CREATE INDEX idx_case_assignments_status ON case_assignments(tenant_id, status);
CREATE INDEX idx_discharge_barriers_case ON discharge_barriers(tenant_id, case_assignment_id, is_resolved);
CREATE INDEX idx_case_referrals_case ON case_referrals(tenant_id, case_assignment_id);

-- Scheduling
CREATE INDEX idx_noshow_predictions_appt ON noshow_prediction_scores(tenant_id, appointment_id);
CREATE INDEX idx_noshow_predictions_patient ON noshow_prediction_scores(tenant_id, patient_id);
CREATE INDEX idx_waitlist_doctor ON scheduling_waitlist(tenant_id, doctor_id, status);
CREATE INDEX idx_waitlist_status ON scheduling_waitlist(tenant_id, status) WHERE status = 'waiting';
CREATE INDEX idx_overbooking_rules_doctor ON scheduling_overbooking_rules(tenant_id, doctor_id, department_id);
