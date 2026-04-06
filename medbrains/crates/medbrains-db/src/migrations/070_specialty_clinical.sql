-- Migration 070: Specialty Clinical Module
-- Covers: Cath Lab, Endoscopy, Psychiatry, PMR/Audiology,
--         Palliative/Mortuary/Nuclear Medicine, Maternity/OB-GYN, Other Specialties
-- Regulatory: AERB (radiation), MHCA 2017 (psychiatry), PCPNDT Act (maternity),
--             NDPS Act (palliative opioids), IPC/CrPC (mortuary MLC)

-- ══════════════════════════════════════════════════════════
--  ENUMS
-- ══════════════════════════════════════════════════════════

CREATE TYPE cath_procedure_type AS ENUM (
    'diagnostic_cath', 'pci', 'pacemaker', 'icd', 'eps',
    'ablation', 'valve_intervention', 'structural', 'peripheral'
);

CREATE TYPE stemi_pathway_status AS ENUM (
    'door', 'ecg', 'cath_lab_activation', 'arterial_access',
    'balloon_inflation', 'completed'
);

CREATE TYPE hemodynamic_site AS ENUM (
    'aorta', 'lv', 'rv', 'ra', 'la', 'pa', 'pcwp',
    'svg', 'lm', 'lad', 'lcx', 'rca', 'other'
);

CREATE TYPE cath_device_type AS ENUM (
    'stent', 'balloon', 'guidewire', 'catheter', 'closure_device',
    'pacemaker', 'icd', 'lead', 'other'
);

CREATE TYPE scope_status AS ENUM (
    'available', 'in_use', 'reprocessing', 'quarantine', 'decommissioned'
);

CREATE TYPE hld_result AS ENUM ('pass', 'fail', 'pending');

CREATE TYPE psych_admission_category AS ENUM (
    'independent', 'supported', 'minor_supported', 'emergency'
);

CREATE TYPE ect_laterality AS ENUM (
    'bilateral', 'right_unilateral', 'left_unilateral'
);

CREATE TYPE restraint_type AS ENUM (
    'physical', 'chemical', 'seclusion'
);

CREATE TYPE rehab_discipline AS ENUM (
    'physiotherapy', 'occupational_therapy', 'speech_therapy',
    'psychology', 'prosthetics_orthotics'
);

CREATE TYPE hearing_test_type AS ENUM (
    'pta', 'bera', 'oae', 'tympanometry', 'speech_audiometry'
);

CREATE TYPE dnr_status AS ENUM ('active', 'expired', 'revoked');

CREATE TYPE body_status AS ENUM (
    'received', 'cold_storage', 'inquest_pending', 'pm_scheduled',
    'pm_completed', 'released', 'unclaimed', 'disposed'
);

CREATE TYPE radiopharmaceutical_type AS ENUM ('diagnostic', 'therapeutic');

CREATE TYPE anc_risk_category AS ENUM (
    'low', 'moderate', 'high', 'very_high'
);

CREATE TYPE delivery_type AS ENUM (
    'normal_vaginal', 'assisted_vaginal', 'lscs_elective',
    'lscs_emergency', 'breech'
);

CREATE TYPE labor_stage AS ENUM (
    'first_latent', 'first_active', 'second', 'third', 'completed'
);

-- ══════════════════════════════════════════════════════════
--  CATH LAB TABLES (5)
-- ══════════════════════════════════════════════════════════

CREATE TABLE cath_procedures (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    procedure_type          cath_procedure_type NOT NULL,
    operator_id             UUID NOT NULL REFERENCES users(id),
    assistant_ids           UUID[] NOT NULL DEFAULT '{}',
    is_stemi                BOOLEAN NOT NULL DEFAULT false,
    door_time               TIMESTAMPTZ,
    balloon_time            TIMESTAMPTZ,
    door_to_balloon_minutes INTEGER,
    fluoroscopy_time_seconds INTEGER,
    total_dap               DECIMAL(12,4),
    total_air_kerma         DECIMAL(12,4),
    contrast_type           TEXT,
    contrast_volume_ml      DECIMAL(8,2),
    access_site             TEXT,
    findings                JSONB NOT NULL DEFAULT '{}'::jsonb,
    complications           TEXT,
    status                  TEXT NOT NULL DEFAULT 'scheduled',
    scheduled_at            TIMESTAMPTZ,
    started_at              TIMESTAMPTZ,
    completed_at            TIMESTAMPTZ,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cath_procedures ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON cath_procedures
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_cath_procedures_tenant ON cath_procedures(tenant_id);
CREATE INDEX idx_cath_procedures_patient ON cath_procedures(tenant_id, patient_id);
CREATE INDEX idx_cath_procedures_stemi ON cath_procedures(tenant_id, is_stemi) WHERE is_stemi = true;
CREATE TRIGGER trg_cath_procedures_updated_at
    BEFORE UPDATE ON cath_procedures
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE cath_hemodynamics (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    procedure_id    UUID NOT NULL REFERENCES cath_procedures(id) ON DELETE CASCADE,
    site            hemodynamic_site NOT NULL,
    systolic_mmhg   DECIMAL(6,2),
    diastolic_mmhg  DECIMAL(6,2),
    mean_mmhg       DECIMAL(6,2),
    saturation_pct  DECIMAL(5,2),
    gradient_mmhg   DECIMAL(6,2),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cath_hemodynamics ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON cath_hemodynamics
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_cath_hemodynamics_tenant ON cath_hemodynamics(tenant_id);
CREATE INDEX idx_cath_hemodynamics_procedure ON cath_hemodynamics(procedure_id);
CREATE TRIGGER trg_cath_hemodynamics_updated_at
    BEFORE UPDATE ON cath_hemodynamics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE cath_devices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    procedure_id    UUID NOT NULL REFERENCES cath_procedures(id) ON DELETE CASCADE,
    device_type     cath_device_type NOT NULL,
    manufacturer    TEXT,
    model           TEXT,
    lot_number      TEXT,
    barcode         TEXT,
    size            TEXT,
    is_consignment  BOOLEAN NOT NULL DEFAULT false,
    vendor_id       UUID,
    unit_cost       DECIMAL(12,2),
    billed          BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cath_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON cath_devices
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_cath_devices_tenant ON cath_devices(tenant_id);
CREATE INDEX idx_cath_devices_procedure ON cath_devices(procedure_id);
CREATE TRIGGER trg_cath_devices_updated_at
    BEFORE UPDATE ON cath_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE cath_stemi_timeline (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    procedure_id    UUID NOT NULL REFERENCES cath_procedures(id) ON DELETE CASCADE,
    event           stemi_pathway_status NOT NULL,
    event_time      TIMESTAMPTZ NOT NULL,
    recorded_by     UUID NOT NULL REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cath_stemi_timeline ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON cath_stemi_timeline
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_cath_stemi_timeline_tenant ON cath_stemi_timeline(tenant_id);
CREATE INDEX idx_cath_stemi_timeline_procedure ON cath_stemi_timeline(procedure_id);
CREATE TRIGGER trg_cath_stemi_timeline_updated_at
    BEFORE UPDATE ON cath_stemi_timeline
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE cath_post_monitoring (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    procedure_id        UUID NOT NULL REFERENCES cath_procedures(id) ON DELETE CASCADE,
    monitored_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    sheath_status       TEXT,
    access_site_status  TEXT,
    vitals              JSONB NOT NULL DEFAULT '{}'::jsonb,
    ambulation_started  BOOLEAN NOT NULL DEFAULT false,
    monitored_by        UUID NOT NULL REFERENCES users(id),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cath_post_monitoring ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON cath_post_monitoring
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_cath_post_monitoring_tenant ON cath_post_monitoring(tenant_id);
CREATE INDEX idx_cath_post_monitoring_procedure ON cath_post_monitoring(procedure_id);
CREATE TRIGGER trg_cath_post_monitoring_updated_at
    BEFORE UPDATE ON cath_post_monitoring
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  ENDOSCOPY TABLES (4)
-- ══════════════════════════════════════════════════════════

CREATE TABLE endoscopy_scopes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    serial_number       TEXT NOT NULL,
    model               TEXT NOT NULL,
    scope_type          TEXT NOT NULL,
    manufacturer        TEXT,
    status              scope_status NOT NULL DEFAULT 'available',
    last_hld_at         TIMESTAMPTZ,
    total_uses          INTEGER NOT NULL DEFAULT 0,
    last_culture_date   DATE,
    last_culture_result TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, serial_number)
);

ALTER TABLE endoscopy_scopes ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON endoscopy_scopes
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_endoscopy_scopes_tenant ON endoscopy_scopes(tenant_id);
CREATE INDEX idx_endoscopy_scopes_status ON endoscopy_scopes(tenant_id, status);
CREATE TRIGGER trg_endoscopy_scopes_updated_at
    BEFORE UPDATE ON endoscopy_scopes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE endoscopy_procedures (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    scope_id            UUID REFERENCES endoscopy_scopes(id),
    procedure_type      TEXT NOT NULL,
    operator_id         UUID NOT NULL REFERENCES users(id),
    sedation_type       TEXT,
    sedation_drugs      JSONB NOT NULL DEFAULT '[]'::jsonb,
    findings            JSONB NOT NULL DEFAULT '{}'::jsonb,
    biopsy_taken        BOOLEAN NOT NULL DEFAULT false,
    aldrete_score_pre   INTEGER,
    aldrete_score_post  INTEGER,
    status              TEXT NOT NULL DEFAULT 'scheduled',
    scheduled_at        TIMESTAMPTZ,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE endoscopy_procedures ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON endoscopy_procedures
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_endoscopy_procedures_tenant ON endoscopy_procedures(tenant_id);
CREATE INDEX idx_endoscopy_procedures_patient ON endoscopy_procedures(tenant_id, patient_id);
CREATE TRIGGER trg_endoscopy_procedures_updated_at
    BEFORE UPDATE ON endoscopy_procedures
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE endoscopy_reprocessing (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    scope_id            UUID NOT NULL REFERENCES endoscopy_scopes(id),
    procedure_id        UUID REFERENCES endoscopy_procedures(id),
    leak_test_passed    BOOLEAN NOT NULL DEFAULT true,
    hld_chemical        TEXT NOT NULL,
    hld_concentration   DECIMAL(6,3),
    hld_soak_minutes    INTEGER NOT NULL,
    hld_temperature     DECIMAL(5,2),
    hld_result          hld_result NOT NULL DEFAULT 'pending',
    reprocessed_by      UUID NOT NULL REFERENCES users(id),
    reprocessed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE endoscopy_reprocessing ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON endoscopy_reprocessing
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_endoscopy_reprocessing_tenant ON endoscopy_reprocessing(tenant_id);
CREATE INDEX idx_endoscopy_reprocessing_scope ON endoscopy_reprocessing(scope_id);
CREATE TRIGGER trg_endoscopy_reprocessing_updated_at
    BEFORE UPDATE ON endoscopy_reprocessing
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE endoscopy_biopsy_specimens (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    procedure_id        UUID NOT NULL REFERENCES endoscopy_procedures(id) ON DELETE CASCADE,
    site                TEXT NOT NULL,
    container_label     TEXT NOT NULL,
    fixative            TEXT,
    chain_of_custody    JSONB NOT NULL DEFAULT '[]'::jsonb,
    pathology_result    TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE endoscopy_biopsy_specimens ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON endoscopy_biopsy_specimens
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_endoscopy_biopsy_tenant ON endoscopy_biopsy_specimens(tenant_id);
CREATE INDEX idx_endoscopy_biopsy_procedure ON endoscopy_biopsy_specimens(procedure_id);
CREATE TRIGGER trg_endoscopy_biopsy_specimens_updated_at
    BEFORE UPDATE ON endoscopy_biopsy_specimens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  PSYCHIATRY TABLES (6) — MHCA 2017 compliant
-- ══════════════════════════════════════════════════════════

CREATE TABLE psych_patients (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    admission_category      psych_admission_category NOT NULL DEFAULT 'independent',
    advance_directive_text  TEXT,
    nominated_rep_name      TEXT,
    nominated_rep_relation  TEXT,
    nominated_rep_contact   TEXT,
    substance_abuse_flag    BOOLEAN NOT NULL DEFAULT false,
    is_restricted           BOOLEAN NOT NULL DEFAULT true,
    treating_psychiatrist_id UUID REFERENCES users(id),
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, patient_id)
);

ALTER TABLE psych_patients ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON psych_patients
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_psych_patients_tenant ON psych_patients(tenant_id);
CREATE INDEX idx_psych_patients_patient ON psych_patients(tenant_id, patient_id);
CREATE TRIGGER trg_psych_patients_updated_at
    BEFORE UPDATE ON psych_patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE psych_assessments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    psych_patient_id    UUID NOT NULL REFERENCES psych_patients(id),
    assessment_type     TEXT NOT NULL,
    mental_status_exam  JSONB NOT NULL DEFAULT '{}'::jsonb,
    ham_d_score         INTEGER,
    bprs_score          INTEGER,
    gaf_score           INTEGER,
    risk_assessment     JSONB NOT NULL DEFAULT '{}'::jsonb,
    assessed_by         UUID NOT NULL REFERENCES users(id),
    assessed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE psych_assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON psych_assessments
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_psych_assessments_tenant ON psych_assessments(tenant_id);
CREATE INDEX idx_psych_assessments_patient ON psych_assessments(psych_patient_id);
CREATE TRIGGER trg_psych_assessments_updated_at
    BEFORE UPDATE ON psych_assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE psych_ect_register (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    psych_patient_id    UUID NOT NULL REFERENCES psych_patients(id),
    session_number      INTEGER NOT NULL,
    consent_obtained    BOOLEAN NOT NULL DEFAULT true,
    laterality          ect_laterality NOT NULL,
    stimulus_dose       DECIMAL(6,2),
    seizure_duration_sec INTEGER,
    anesthetic          TEXT,
    muscle_relaxant     TEXT,
    performed_by        UUID NOT NULL REFERENCES users(id),
    anesthetist_id      UUID REFERENCES users(id),
    session_date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    complications       TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE psych_ect_register ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON psych_ect_register
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_psych_ect_register_tenant ON psych_ect_register(tenant_id);
CREATE INDEX idx_psych_ect_register_patient ON psych_ect_register(psych_patient_id);
CREATE TRIGGER trg_psych_ect_register_updated_at
    BEFORE UPDATE ON psych_ect_register
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE psych_seclusion_restraint (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    psych_patient_id    UUID NOT NULL REFERENCES psych_patients(id),
    restraint_type      restraint_type NOT NULL,
    reason              TEXT NOT NULL,
    start_time          TIMESTAMPTZ NOT NULL DEFAULT now(),
    review_due_at       TIMESTAMPTZ NOT NULL,
    reviewed_at         TIMESTAMPTZ,
    end_time            TIMESTAMPTZ,
    ordered_by          UUID NOT NULL REFERENCES users(id),
    released_by         UUID REFERENCES users(id),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE psych_seclusion_restraint ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON psych_seclusion_restraint
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_psych_seclusion_tenant ON psych_seclusion_restraint(tenant_id);
CREATE INDEX idx_psych_seclusion_patient ON psych_seclusion_restraint(psych_patient_id);
CREATE INDEX idx_psych_seclusion_active ON psych_seclusion_restraint(tenant_id, end_time) WHERE end_time IS NULL;
CREATE TRIGGER trg_psych_seclusion_restraint_updated_at
    BEFORE UPDATE ON psych_seclusion_restraint
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE psych_mhrb_notifications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    psych_patient_id    UUID NOT NULL REFERENCES psych_patients(id),
    notification_type   TEXT NOT NULL,
    reference_number    TEXT,
    status              TEXT NOT NULL DEFAULT 'pending',
    sent_at             TIMESTAMPTZ,
    acknowledged_at     TIMESTAMPTZ,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE psych_mhrb_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON psych_mhrb_notifications
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_psych_mhrb_tenant ON psych_mhrb_notifications(tenant_id);
CREATE INDEX idx_psych_mhrb_patient ON psych_mhrb_notifications(psych_patient_id);
CREATE TRIGGER trg_psych_mhrb_notifications_updated_at
    BEFORE UPDATE ON psych_mhrb_notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE psych_counseling_sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    psych_patient_id    UUID NOT NULL REFERENCES psych_patients(id),
    session_type        TEXT NOT NULL,
    therapist_id        UUID NOT NULL REFERENCES users(id),
    modality            TEXT,
    duration_minutes    INTEGER,
    outcome_rating      INTEGER,
    session_date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE psych_counseling_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON psych_counseling_sessions
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_psych_counseling_tenant ON psych_counseling_sessions(tenant_id);
CREATE INDEX idx_psych_counseling_patient ON psych_counseling_sessions(psych_patient_id);
CREATE TRIGGER trg_psych_counseling_sessions_updated_at
    BEFORE UPDATE ON psych_counseling_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  PMR / AUDIOLOGY TABLES (4)
-- ══════════════════════════════════════════════════════════

CREATE TABLE rehab_plans (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    discipline          rehab_discipline NOT NULL,
    diagnosis           TEXT,
    goals               TEXT NOT NULL,
    plan_details        JSONB NOT NULL DEFAULT '{}'::jsonb,
    fim_score_initial   INTEGER,
    barthel_score_initial INTEGER,
    status              TEXT NOT NULL DEFAULT 'active',
    therapist_id        UUID REFERENCES users(id),
    start_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    target_end_date     DATE,
    actual_end_date     DATE,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE rehab_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON rehab_plans
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_rehab_plans_tenant ON rehab_plans(tenant_id);
CREATE INDEX idx_rehab_plans_patient ON rehab_plans(tenant_id, patient_id);
CREATE TRIGGER trg_rehab_plans_updated_at
    BEFORE UPDATE ON rehab_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE rehab_sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    plan_id             UUID NOT NULL REFERENCES rehab_plans(id),
    session_number      INTEGER NOT NULL,
    therapist_id        UUID NOT NULL REFERENCES users(id),
    intervention        TEXT NOT NULL,
    pain_score          INTEGER,
    rom_data            JSONB NOT NULL DEFAULT '{}'::jsonb,
    strength_data       JSONB NOT NULL DEFAULT '{}'::jsonb,
    fim_score           INTEGER,
    barthel_score       INTEGER,
    session_date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    duration_minutes    INTEGER,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE rehab_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON rehab_sessions
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_rehab_sessions_tenant ON rehab_sessions(tenant_id);
CREATE INDEX idx_rehab_sessions_plan ON rehab_sessions(plan_id);
CREATE TRIGGER trg_rehab_sessions_updated_at
    BEFORE UPDATE ON rehab_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE audiology_tests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    test_type           hearing_test_type NOT NULL,
    right_ear_results   JSONB NOT NULL DEFAULT '{}'::jsonb,
    left_ear_results    JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_nhsp             BOOLEAN NOT NULL DEFAULT false,
    nhsp_referral_needed BOOLEAN NOT NULL DEFAULT false,
    audiogram_data      JSONB NOT NULL DEFAULT '{}'::jsonb,
    performed_by        UUID NOT NULL REFERENCES users(id),
    test_date           TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE audiology_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON audiology_tests
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_audiology_tests_tenant ON audiology_tests(tenant_id);
CREATE INDEX idx_audiology_tests_patient ON audiology_tests(tenant_id, patient_id);
CREATE TRIGGER trg_audiology_tests_updated_at
    BEFORE UPDATE ON audiology_tests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE psychometric_tests (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    test_name               TEXT NOT NULL,
    raw_data_encrypted      JSONB NOT NULL DEFAULT '{}'::jsonb,
    summary_for_clinician   TEXT,
    is_restricted           BOOLEAN NOT NULL DEFAULT true,
    administered_by         UUID NOT NULL REFERENCES users(id),
    test_date               TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE psychometric_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON psychometric_tests
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_psychometric_tests_tenant ON psychometric_tests(tenant_id);
CREATE INDEX idx_psychometric_tests_patient ON psychometric_tests(tenant_id, patient_id);
CREATE TRIGGER trg_psychometric_tests_updated_at
    BEFORE UPDATE ON psychometric_tests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  PALLIATIVE / MORTUARY / NUCLEAR MEDICINE TABLES (5)
-- ══════════════════════════════════════════════════════════

CREATE TABLE dnr_orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    admission_id        UUID,
    status              dnr_status NOT NULL DEFAULT 'active',
    scope               TEXT NOT NULL,
    authorized_by       UUID NOT NULL REFERENCES users(id),
    witness_name        TEXT,
    review_due_at       TIMESTAMPTZ NOT NULL,
    revoked_at          TIMESTAMPTZ,
    revoked_by          UUID REFERENCES users(id),
    revocation_reason   TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE dnr_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON dnr_orders
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_dnr_orders_tenant ON dnr_orders(tenant_id);
CREATE INDEX idx_dnr_orders_patient ON dnr_orders(tenant_id, patient_id);
CREATE INDEX idx_dnr_orders_active ON dnr_orders(tenant_id, status) WHERE status = 'active';
CREATE TRIGGER trg_dnr_orders_updated_at
    BEFORE UPDATE ON dnr_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE pain_assessments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    pain_score              INTEGER NOT NULL,
    pain_location           TEXT,
    pain_character          TEXT,
    who_ladder_step         INTEGER,
    opioid_dose_morphine_eq DECIMAL(8,2),
    breakthrough_doses      INTEGER NOT NULL DEFAULT 0,
    current_medications     JSONB NOT NULL DEFAULT '[]'::jsonb,
    assessed_by             UUID NOT NULL REFERENCES users(id),
    assessed_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pain_assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON pain_assessments
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_pain_assessments_tenant ON pain_assessments(tenant_id);
CREATE INDEX idx_pain_assessments_patient ON pain_assessments(tenant_id, patient_id);
CREATE TRIGGER trg_pain_assessments_updated_at
    BEFORE UPDATE ON pain_assessments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE mortuary_records (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                   UUID NOT NULL REFERENCES tenants(id),
    body_receipt_number         TEXT NOT NULL,
    deceased_name               TEXT NOT NULL,
    deceased_age                INTEGER,
    deceased_gender             TEXT,
    date_of_death               TIMESTAMPTZ,
    cause_of_death              TEXT,
    is_mlc                      BOOLEAN NOT NULL DEFAULT false,
    mlc_case_id                 UUID,
    cold_storage_slot           TEXT,
    temperature_log             JSONB NOT NULL DEFAULT '[]'::jsonb,
    status                      body_status NOT NULL DEFAULT 'received',
    pm_requested                BOOLEAN NOT NULL DEFAULT false,
    pm_performed_by             TEXT,
    pm_date                     TIMESTAMPTZ,
    pm_findings                 TEXT,
    viscera_preserved           BOOLEAN NOT NULL DEFAULT false,
    viscera_chain_of_custody    JSONB NOT NULL DEFAULT '[]'::jsonb,
    organ_donation_status       TEXT,
    released_to                 TEXT,
    released_at                 TIMESTAMPTZ,
    released_by                 UUID REFERENCES users(id),
    identification_marks        TEXT,
    unclaimed_notice_date       DATE,
    unclaimed_disposal_date     DATE,
    notes                       TEXT,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, body_receipt_number)
);

ALTER TABLE mortuary_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mortuary_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_mortuary_records_tenant ON mortuary_records(tenant_id);
CREATE INDEX idx_mortuary_records_status ON mortuary_records(tenant_id, status);
CREATE TRIGGER trg_mortuary_records_updated_at
    BEFORE UPDATE ON mortuary_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE nuclear_med_sources (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    isotope             TEXT NOT NULL,
    activity_mci        DECIMAL(10,4) NOT NULL,
    half_life_hours     DECIMAL(10,4) NOT NULL,
    source_type         radiopharmaceutical_type NOT NULL,
    aerb_license_number TEXT,
    batch_number        TEXT,
    calibration_date    TIMESTAMPTZ,
    expiry_date         TIMESTAMPTZ,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE nuclear_med_sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON nuclear_med_sources
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_nuclear_med_sources_tenant ON nuclear_med_sources(tenant_id);
CREATE INDEX idx_nuclear_med_sources_active ON nuclear_med_sources(tenant_id, is_active) WHERE is_active = true;
CREATE TRIGGER trg_nuclear_med_sources_updated_at
    BEFORE UPDATE ON nuclear_med_sources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE nuclear_med_administrations (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    source_id           UUID NOT NULL REFERENCES nuclear_med_sources(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    dose_mci            DECIMAL(10,4) NOT NULL,
    route               TEXT NOT NULL,
    indication          TEXT NOT NULL,
    administered_by     UUID NOT NULL REFERENCES users(id),
    administered_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    waste_disposed      BOOLEAN NOT NULL DEFAULT false,
    waste_disposal_date TIMESTAMPTZ,
    isolation_required  BOOLEAN NOT NULL DEFAULT false,
    isolation_end       TIMESTAMPTZ,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE nuclear_med_administrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON nuclear_med_administrations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_nuclear_med_admin_tenant ON nuclear_med_administrations(tenant_id);
CREATE INDEX idx_nuclear_med_admin_patient ON nuclear_med_administrations(tenant_id, patient_id);
CREATE INDEX idx_nuclear_med_admin_source ON nuclear_med_administrations(source_id);
CREATE TRIGGER trg_nuclear_med_administrations_updated_at
    BEFORE UPDATE ON nuclear_med_administrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  MATERNITY / OB-GYN TABLES (5) — PCPNDT Act compliant
-- ══════════════════════════════════════════════════════════

CREATE TABLE maternity_registrations (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    patient_id              UUID NOT NULL REFERENCES patients(id),
    registration_number     TEXT NOT NULL,
    lmp_date                DATE NOT NULL,
    edd_date                DATE NOT NULL,
    gravida                 INTEGER NOT NULL DEFAULT 1,
    para                    INTEGER NOT NULL DEFAULT 0,
    abortion                INTEGER NOT NULL DEFAULT 0,
    living                  INTEGER NOT NULL DEFAULT 0,
    risk_category           anc_risk_category NOT NULL DEFAULT 'low',
    blood_group             TEXT,
    rh_factor               TEXT,
    is_high_risk            BOOLEAN NOT NULL DEFAULT false,
    high_risk_reasons       JSONB NOT NULL DEFAULT '[]'::jsonb,
    status                  TEXT NOT NULL DEFAULT 'active',
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, registration_number)
);

ALTER TABLE maternity_registrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON maternity_registrations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_maternity_reg_tenant ON maternity_registrations(tenant_id);
CREATE INDEX idx_maternity_reg_patient ON maternity_registrations(tenant_id, patient_id);
CREATE INDEX idx_maternity_reg_high_risk ON maternity_registrations(tenant_id, is_high_risk) WHERE is_high_risk = true;
CREATE TRIGGER trg_maternity_registrations_updated_at
    BEFORE UPDATE ON maternity_registrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE anc_visits (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    registration_id         UUID NOT NULL REFERENCES maternity_registrations(id),
    visit_number            INTEGER NOT NULL,
    gestational_weeks       DECIMAL(4,1) NOT NULL,
    weight_kg               DECIMAL(5,2),
    bp_systolic             INTEGER,
    bp_diastolic            INTEGER,
    fundal_height_cm        DECIMAL(5,2),
    fetal_heart_rate        INTEGER,
    hemoglobin              DECIMAL(4,1),
    urine_protein           TEXT,
    urine_sugar             TEXT,
    pcpndt_form_f_filed     BOOLEAN NOT NULL DEFAULT false,
    pcpndt_form_f_number    TEXT,
    ultrasound_done         BOOLEAN NOT NULL DEFAULT false,
    examined_by             UUID NOT NULL REFERENCES users(id),
    visit_date              DATE NOT NULL DEFAULT CURRENT_DATE,
    next_visit_date         DATE,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE anc_visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON anc_visits
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_anc_visits_tenant ON anc_visits(tenant_id);
CREATE INDEX idx_anc_visits_registration ON anc_visits(registration_id);
CREATE TRIGGER trg_anc_visits_updated_at
    BEFORE UPDATE ON anc_visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE labor_records (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    registration_id         UUID NOT NULL REFERENCES maternity_registrations(id),
    admission_id            UUID,
    labor_onset_time        TIMESTAMPTZ,
    current_stage           labor_stage NOT NULL DEFAULT 'first_latent',
    partograph_data         JSONB NOT NULL DEFAULT '{}'::jsonb,
    cervical_dilation_log   JSONB NOT NULL DEFAULT '[]'::jsonb,
    delivery_type           delivery_type,
    delivery_time           TIMESTAMPTZ,
    placenta_delivery_time  TIMESTAMPTZ,
    blood_loss_ml           INTEGER,
    episiotomy              BOOLEAN NOT NULL DEFAULT false,
    perineal_tear_grade     INTEGER,
    apgar_1min              INTEGER,
    apgar_5min              INTEGER,
    baby_weight_gm          INTEGER,
    attending_doctor_id     UUID REFERENCES users(id),
    midwife_id              UUID REFERENCES users(id),
    complications           TEXT,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE labor_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON labor_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_labor_records_tenant ON labor_records(tenant_id);
CREATE INDEX idx_labor_records_registration ON labor_records(registration_id);
CREATE TRIGGER trg_labor_records_updated_at
    BEFORE UPDATE ON labor_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE newborn_records (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    labor_id                UUID NOT NULL REFERENCES labor_records(id),
    birth_date              TIMESTAMPTZ NOT NULL,
    gender                  TEXT NOT NULL,
    weight_gm               INTEGER NOT NULL,
    length_cm               DECIMAL(5,2),
    head_circumference_cm   DECIMAL(5,2),
    apgar_1min              INTEGER,
    apgar_5min              INTEGER,
    apgar_10min             INTEGER,
    resuscitation_needed    BOOLEAN NOT NULL DEFAULT false,
    bcg_given               BOOLEAN NOT NULL DEFAULT false,
    opv_given               BOOLEAN NOT NULL DEFAULT false,
    hep_b_given             BOOLEAN NOT NULL DEFAULT false,
    vitamin_k_given         BOOLEAN NOT NULL DEFAULT false,
    nicu_admission_needed   BOOLEAN NOT NULL DEFAULT false,
    nicu_admission_reason   TEXT,
    birth_certificate_number TEXT,
    congenital_anomalies    TEXT,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE newborn_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON newborn_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_newborn_records_tenant ON newborn_records(tenant_id);
CREATE INDEX idx_newborn_records_labor ON newborn_records(labor_id);
CREATE TRIGGER trg_newborn_records_updated_at
    BEFORE UPDATE ON newborn_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE postnatal_records (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    registration_id         UUID NOT NULL REFERENCES maternity_registrations(id),
    day_postpartum          INTEGER NOT NULL,
    mother_vitals           JSONB NOT NULL DEFAULT '{}'::jsonb,
    uterus_involution       TEXT,
    lochia                  TEXT,
    breast_feeding_status   TEXT,
    baby_vitals             JSONB NOT NULL DEFAULT '{}'::jsonb,
    baby_weight_gm          INTEGER,
    baby_feeding            TEXT,
    examined_by             UUID NOT NULL REFERENCES users(id),
    visit_date              DATE NOT NULL DEFAULT CURRENT_DATE,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE postnatal_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON postnatal_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_postnatal_records_tenant ON postnatal_records(tenant_id);
CREATE INDEX idx_postnatal_records_registration ON postnatal_records(registration_id);
CREATE TRIGGER trg_postnatal_records_updated_at
    BEFORE UPDATE ON postnatal_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  OTHER SPECIALTIES TABLES (4)
-- ══════════════════════════════════════════════════════════

CREATE TABLE specialty_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    specialty       TEXT NOT NULL,
    template_name   TEXT NOT NULL,
    template_code   TEXT NOT NULL,
    form_schema     JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, template_code)
);

ALTER TABLE specialty_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON specialty_templates
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_specialty_templates_tenant ON specialty_templates(tenant_id);
CREATE INDEX idx_specialty_templates_specialty ON specialty_templates(tenant_id, specialty);
CREATE TRIGGER trg_specialty_templates_updated_at
    BEFORE UPDATE ON specialty_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE specialty_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    specialty       TEXT NOT NULL,
    template_id     UUID REFERENCES specialty_templates(id),
    form_data       JSONB NOT NULL DEFAULT '{}'::jsonb,
    recorded_by     UUID NOT NULL REFERENCES users(id),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE specialty_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON specialty_records
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_specialty_records_tenant ON specialty_records(tenant_id);
CREATE INDEX idx_specialty_records_patient ON specialty_records(tenant_id, patient_id);
CREATE INDEX idx_specialty_records_specialty ON specialty_records(tenant_id, specialty);
CREATE TRIGGER trg_specialty_records_updated_at
    BEFORE UPDATE ON specialty_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE dialysis_sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    machine_number      TEXT,
    access_type         TEXT NOT NULL,
    dialyzer_type       TEXT,
    pre_weight_kg       DECIMAL(6,2),
    post_weight_kg      DECIMAL(6,2),
    uf_goal_ml          INTEGER,
    uf_achieved_ml      INTEGER,
    duration_minutes    INTEGER,
    pre_vitals          JSONB NOT NULL DEFAULT '{}'::jsonb,
    post_vitals         JSONB NOT NULL DEFAULT '{}'::jsonb,
    intradialytic_events JSONB NOT NULL DEFAULT '[]'::jsonb,
    kt_v                DECIMAL(4,2),
    urr_pct             DECIMAL(5,2),
    heparin_dose        TEXT,
    performed_by        UUID NOT NULL REFERENCES users(id),
    session_date        TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE dialysis_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON dialysis_sessions
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_dialysis_sessions_tenant ON dialysis_sessions(tenant_id);
CREATE INDEX idx_dialysis_sessions_patient ON dialysis_sessions(tenant_id, patient_id);
CREATE TRIGGER trg_dialysis_sessions_updated_at
    BEFORE UPDATE ON dialysis_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TABLE chemo_protocols (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    patient_id          UUID NOT NULL REFERENCES patients(id),
    protocol_name       TEXT NOT NULL,
    cancer_type         TEXT NOT NULL,
    staging             TEXT,
    regimen             JSONB NOT NULL DEFAULT '[]'::jsonb,
    cycle_number        INTEGER NOT NULL DEFAULT 1,
    total_cycles        INTEGER,
    toxicity_grade      INTEGER,
    recist_response     TEXT,
    tumor_board_discussed BOOLEAN NOT NULL DEFAULT false,
    tumor_board_date    DATE,
    tumor_board_recommendation TEXT,
    treating_oncologist_id UUID REFERENCES users(id),
    cycle_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    next_cycle_date     DATE,
    status              TEXT NOT NULL DEFAULT 'active',
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE chemo_protocols ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON chemo_protocols
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_chemo_protocols_tenant ON chemo_protocols(tenant_id);
CREATE INDEX idx_chemo_protocols_patient ON chemo_protocols(tenant_id, patient_id);
CREATE TRIGGER trg_chemo_protocols_updated_at
    BEFORE UPDATE ON chemo_protocols
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
