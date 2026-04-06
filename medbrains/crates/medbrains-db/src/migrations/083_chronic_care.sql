-- 083_chronic_care.sql — Chronic Care / Drug-o-gram Module
-- Program enrollment, medication timeline, adherence tracking, outcome monitoring.

-- ── Enums ─────────────────────────────────────────────────

CREATE TYPE chronic_program_type AS ENUM (
  'tb_dots', 'hiv_art', 'diabetes', 'hypertension', 'ckd', 'copd',
  'asthma', 'cancer_chemo', 'mental_health', 'epilepsy', 'thyroid', 'rheumatic', 'other'
);

CREATE TYPE enrollment_status AS ENUM (
  'active', 'completed', 'discontinued', 'transferred', 'lost_to_followup', 'deceased'
);

CREATE TYPE medication_event_type AS ENUM (
  'started', 'dose_changed', 'switched', 'discontinued', 'resumed', 'held'
);

CREATE TYPE adherence_event_type AS ENUM (
  'dose_taken', 'dose_missed', 'dose_late',
  'refill_on_time', 'refill_late', 'refill_missed',
  'appointment_attended', 'appointment_missed', 'appointment_rescheduled'
);

-- ── Tables ─────────────────────────────────────────────────

-- 1. Program catalog
CREATE TABLE chronic_programs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  name            TEXT NOT NULL,
  code            TEXT NOT NULL,
  program_type    chronic_program_type NOT NULL,
  description     TEXT,
  protocol_id     UUID REFERENCES clinical_protocols(id),
  default_duration_months INT,
  target_outcomes JSONB NOT NULL DEFAULT '[]',
  monitoring_schedule JSONB NOT NULL DEFAULT '[]',
  is_active       BOOLEAN NOT NULL DEFAULT true,
  created_by      UUID NOT NULL REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code)
);

-- 2. Patient enrollment
CREATE TABLE chronic_enrollments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         UUID NOT NULL REFERENCES tenants(id),
  patient_id        UUID NOT NULL REFERENCES patients(id),
  program_id        UUID NOT NULL REFERENCES chronic_programs(id),
  enrolled_by       UUID NOT NULL REFERENCES users(id),
  primary_doctor_id UUID REFERENCES users(id),
  enrollment_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  expected_end_date DATE,
  actual_end_date   DATE,
  status            enrollment_status NOT NULL DEFAULT 'active',
  status_reason     TEXT,
  diagnosis_id      UUID REFERENCES diagnoses(id),
  icd_code          TEXT,
  target_overrides  JSONB,
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Medication timeline events (append-only)
CREATE TABLE medication_timeline_events (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL REFERENCES tenants(id),
  patient_id            UUID NOT NULL REFERENCES patients(id),
  enrollment_id         UUID REFERENCES chronic_enrollments(id),
  prescription_item_id  UUID REFERENCES prescription_items(id),
  encounter_id          UUID REFERENCES encounters(id),
  event_type            medication_event_type NOT NULL,
  drug_name             TEXT NOT NULL,
  generic_name          TEXT,
  atc_code              TEXT,
  catalog_item_id       UUID REFERENCES pharmacy_catalog(id),
  dosage                TEXT,
  frequency             TEXT,
  route                 TEXT,
  previous_dosage       TEXT,
  previous_frequency    TEXT,
  change_reason         TEXT,
  switched_from_drug    TEXT,
  ordered_by            UUID NOT NULL REFERENCES users(id),
  effective_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date              DATE,
  is_auto_generated     BOOLEAN NOT NULL DEFAULT false,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Adherence records (append-only)
CREATE TABLE adherence_records (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         UUID NOT NULL REFERENCES tenants(id),
  patient_id        UUID NOT NULL REFERENCES patients(id),
  enrollment_id     UUID NOT NULL REFERENCES chronic_enrollments(id),
  event_type        adherence_event_type NOT NULL,
  event_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  drug_name         TEXT,
  appointment_id    UUID REFERENCES appointments(id),
  pharmacy_order_id UUID REFERENCES pharmacy_orders(id),
  recorded_by       UUID NOT NULL REFERENCES users(id),
  notes             TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Patient outcome targets
CREATE TABLE patient_outcome_targets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  patient_id      UUID NOT NULL REFERENCES patients(id),
  enrollment_id   UUID REFERENCES chronic_enrollments(id),
  parameter_name  TEXT NOT NULL,
  loinc_code      TEXT,
  target_value    DECIMAL NOT NULL,
  unit            TEXT NOT NULL,
  comparison      TEXT NOT NULL CHECK (comparison IN ('<', '<=', '=', '>=', '>')),
  set_by          UUID NOT NULL REFERENCES users(id),
  effective_from  DATE NOT NULL DEFAULT CURRENT_DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Polypharmacy interaction alerts
CREATE TABLE polypharmacy_interaction_alerts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  patient_id      UUID NOT NULL REFERENCES patients(id),
  enrollment_id   UUID REFERENCES chronic_enrollments(id),
  drug_a_name     TEXT NOT NULL,
  drug_b_name     TEXT NOT NULL,
  interaction_id  UUID REFERENCES drug_interactions(id),
  severity        TEXT NOT NULL CHECK (severity IN ('minor', 'moderate', 'major', 'contraindicated')),
  description     TEXT,
  management      TEXT,
  status          TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'overridden', 'resolved')),
  acknowledged_by UUID REFERENCES users(id),
  acknowledged_at TIMESTAMPTZ,
  override_reason TEXT,
  detected_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── ALTER existing tables ─────────────────────────────────

ALTER TABLE prescription_items
  ADD COLUMN item_status TEXT NOT NULL DEFAULT 'active'
    CHECK (item_status IN ('active', 'discontinued', 'changed', 'completed', 'held')),
  ADD COLUMN discontinued_at TIMESTAMPTZ,
  ADD COLUMN discontinued_by UUID REFERENCES users(id),
  ADD COLUMN discontinue_reason TEXT,
  ADD COLUMN catalog_item_id UUID REFERENCES pharmacy_catalog(id);

-- ── RLS ───────────────────────────────────────────────────

ALTER TABLE chronic_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE chronic_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE adherence_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_outcome_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE polypharmacy_interaction_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON chronic_programs
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE POLICY tenant_isolation ON chronic_enrollments
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE POLICY tenant_isolation ON medication_timeline_events
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE POLICY tenant_isolation ON adherence_records
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE POLICY tenant_isolation ON patient_outcome_targets
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE POLICY tenant_isolation ON polypharmacy_interaction_alerts
  USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- ── Triggers ──────────────────────────────────────────────

CREATE TRIGGER trg_chronic_programs_updated_at
  BEFORE UPDATE ON chronic_programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_chronic_enrollments_updated_at
  BEFORE UPDATE ON chronic_enrollments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patient_outcome_targets_updated_at
  BEFORE UPDATE ON patient_outcome_targets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Indexes ───────────────────────────────────────────────

CREATE INDEX idx_med_timeline_patient_date
  ON medication_timeline_events (tenant_id, patient_id, effective_date);

CREATE INDEX idx_med_timeline_enrollment
  ON medication_timeline_events (enrollment_id)
  WHERE enrollment_id IS NOT NULL;

CREATE INDEX idx_med_timeline_drug
  ON medication_timeline_events (tenant_id, patient_id, drug_name, effective_date);

CREATE INDEX idx_chronic_enrollments_active
  ON chronic_enrollments (tenant_id, patient_id, status)
  WHERE status = 'active';

CREATE INDEX idx_adherence_enrollment_date
  ON adherence_records (tenant_id, enrollment_id, event_date);

CREATE INDEX idx_outcome_targets_patient
  ON patient_outcome_targets (tenant_id, patient_id);

CREATE INDEX idx_polypharmacy_alerts_active
  ON polypharmacy_interaction_alerts (tenant_id, patient_id, status)
  WHERE status = 'active';

CREATE INDEX idx_prescription_items_status
  ON prescription_items (tenant_id, item_status)
  WHERE item_status != 'active';

CREATE INDEX idx_chronic_programs_type
  ON chronic_programs (tenant_id, program_type);
