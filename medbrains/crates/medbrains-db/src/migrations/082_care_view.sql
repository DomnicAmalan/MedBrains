-- 082_care_view.sql — Care View / Ward Dashboard
-- Adds nursing task classification enums and indexes for real-time ward aggregation queries.
-- No new tables — the Care View is a read-heavy aggregation layer over existing IPD tables.

-- ── Enums ─────────────────────────────────────────────────

CREATE TYPE nursing_task_priority AS ENUM ('routine', 'urgent', 'stat');

CREATE TYPE nursing_task_category AS ENUM (
  'vital_check', 'wound_care', 'catheter_care', 'repositioning',
  'mouth_care', 'hygiene', 'mobilization', 'teaching',
  'drain_care', 'tracheostomy_care', 'medication', 'other'
);

-- ── ALTER existing tables ─────────────────────────────────

ALTER TABLE nursing_tasks
  ADD COLUMN priority nursing_task_priority NOT NULL DEFAULT 'routine',
  ADD COLUMN category nursing_task_category;

ALTER TABLE admissions
  ADD COLUMN primary_nurse_id UUID REFERENCES users(id);

-- ── Partial indexes for ward dashboard aggregate queries ──

CREATE INDEX idx_nursing_tasks_due_incomplete
  ON nursing_tasks (tenant_id, admission_id, due_at)
  WHERE is_completed = false;

CREATE INDEX idx_nursing_tasks_assigned_due
  ON nursing_tasks (tenant_id, assigned_to, due_at)
  WHERE is_completed = false;

CREATE INDEX idx_mar_pending
  ON ipd_medication_administration (tenant_id, admission_id, scheduled_at)
  WHERE status = 'scheduled';

CREATE INDEX idx_vitals_latest
  ON vitals (tenant_id, encounter_id, recorded_at DESC);

CREATE INDEX idx_admissions_primary_nurse
  ON admissions (tenant_id, primary_nurse_id)
  WHERE status = 'admitted' AND primary_nurse_id IS NOT NULL;
