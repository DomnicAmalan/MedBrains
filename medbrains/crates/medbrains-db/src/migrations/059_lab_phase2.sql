-- 059_lab_phase2.sql — Lab Phase 2: Enhanced Results, QC/NABL, Operations, Catalog
-- Delta checks, critical alerts, report workflow, QC/Levey-Jennings,
-- phlebotomy queue, outsourced tests, catalog regulatory fields

-- ══════════════════════════════════════════════════════════
--  New Enums
-- ══════════════════════════════════════════════════════════

CREATE TYPE lab_report_status AS ENUM ('preliminary', 'final', 'amended');
CREATE TYPE lab_qc_status AS ENUM ('accepted', 'rejected', 'warning');
CREATE TYPE lab_outsource_status AS ENUM ('pending_send', 'sent', 'result_received', 'cancelled');
CREATE TYPE lab_phlebotomy_status AS ENUM ('waiting', 'in_progress', 'completed', 'skipped');
CREATE TYPE lab_westgard_rule AS ENUM ('1_2s', '1_3s', '2_2s', 'r_4s', '4_1s', '10x');

-- ══════════════════════════════════════════════════════════
--  ALTER lab_test_catalog — regulatory + advanced fields
-- ══════════════════════════════════════════════════════════

ALTER TABLE lab_test_catalog
  ADD COLUMN IF NOT EXISTS loinc_code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS method VARCHAR(200),
  ADD COLUMN IF NOT EXISTS specimen_volume VARCHAR(50),
  ADD COLUMN IF NOT EXISTS critical_low NUMERIC(12,4),
  ADD COLUMN IF NOT EXISTS critical_high NUMERIC(12,4),
  ADD COLUMN IF NOT EXISTS delta_check_percent NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS auto_validation_rules JSONB,
  ADD COLUMN IF NOT EXISTS allows_add_on BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_lab_test_catalog_loinc
  ON lab_test_catalog (loinc_code) WHERE loinc_code IS NOT NULL;

-- ══════════════════════════════════════════════════════════
--  ALTER lab_orders — report workflow + outsource + add-on
-- ══════════════════════════════════════════════════════════

ALTER TABLE lab_orders
  ADD COLUMN IF NOT EXISTS sample_barcode VARCHAR(100),
  ADD COLUMN IF NOT EXISTS is_outsourced BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS report_status lab_report_status,
  ADD COLUMN IF NOT EXISTS is_report_locked BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS expected_tat_minutes INT,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS parent_order_id UUID REFERENCES lab_orders(id);

CREATE INDEX IF NOT EXISTS idx_lab_orders_barcode
  ON lab_orders (tenant_id, sample_barcode) WHERE sample_barcode IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_lab_orders_parent
  ON lab_orders (parent_order_id) WHERE parent_order_id IS NOT NULL;

-- ══════════════════════════════════════════════════════════
--  ALTER lab_results — delta checks + auto-validation
-- ══════════════════════════════════════════════════════════

ALTER TABLE lab_results
  ADD COLUMN IF NOT EXISTS previous_value TEXT,
  ADD COLUMN IF NOT EXISTS delta_percent NUMERIC(8,2),
  ADD COLUMN IF NOT EXISTS is_delta_flagged BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_auto_validated BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS entered_by UUID REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TRIGGER set_lab_results_updated_at
  BEFORE UPDATE ON lab_results
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  lab_result_amendments — audit trail for amended results
-- ══════════════════════════════════════════════════════════

CREATE TABLE lab_result_amendments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  result_id     UUID NOT NULL REFERENCES lab_results(id),
  order_id      UUID NOT NULL REFERENCES lab_orders(id),
  original_value TEXT,
  amended_value  TEXT,
  original_flag  lab_result_flag,
  amended_flag   lab_result_flag,
  reason        TEXT NOT NULL,
  amended_by    UUID NOT NULL REFERENCES users(id),
  amended_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_result_amendments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_lab_result_amendments ON lab_result_amendments
  USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  lab_critical_alerts — critical value notification log
-- ══════════════════════════════════════════════════════════

CREATE TABLE lab_critical_alerts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  order_id        UUID NOT NULL REFERENCES lab_orders(id),
  result_id       UUID NOT NULL REFERENCES lab_results(id),
  patient_id      UUID NOT NULL REFERENCES patients(id),
  parameter_name  TEXT NOT NULL,
  value           TEXT NOT NULL,
  flag            lab_result_flag NOT NULL,
  notified_to     UUID REFERENCES users(id),
  notified_at     TIMESTAMPTZ,
  acknowledged_by UUID REFERENCES users(id),
  acknowledged_at TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_critical_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_lab_critical_alerts ON lab_critical_alerts
  USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_lab_critical_alerts_unack
  ON lab_critical_alerts (tenant_id, acknowledged_at)
  WHERE acknowledged_at IS NULL;

-- ══════════════════════════════════════════════════════════
--  lab_reagent_lots — reagent tracking with expiry
-- ══════════════════════════════════════════════════════════

CREATE TABLE lab_reagent_lots (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  reagent_name  TEXT NOT NULL,
  lot_number    VARCHAR(100) NOT NULL,
  manufacturer  VARCHAR(200),
  test_id       UUID REFERENCES lab_test_catalog(id),
  received_date DATE,
  expiry_date   DATE,
  quantity      NUMERIC(10,2),
  quantity_unit VARCHAR(50),
  is_active     BOOLEAN NOT NULL DEFAULT true,
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, lot_number)
);

ALTER TABLE lab_reagent_lots ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_lab_reagent_lots ON lab_reagent_lots
  USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_lab_reagent_lots_updated_at
  BEFORE UPDATE ON lab_reagent_lots
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_lab_reagent_lots_expiry
  ON lab_reagent_lots (tenant_id, expiry_date);

-- ══════════════════════════════════════════════════════════
--  lab_qc_results — QC run data points (Levey-Jennings)
-- ══════════════════════════════════════════════════════════

CREATE TABLE lab_qc_results (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id),
  test_id         UUID NOT NULL REFERENCES lab_test_catalog(id),
  lot_id          UUID NOT NULL REFERENCES lab_reagent_lots(id),
  level           VARCHAR(20) NOT NULL,
  target_mean     NUMERIC(12,4),
  target_sd       NUMERIC(12,4),
  observed_value  NUMERIC(12,4),
  sd_index        NUMERIC(6,2),
  status          lab_qc_status NOT NULL DEFAULT 'accepted',
  westgard_violations lab_westgard_rule[],
  run_date        DATE,
  run_time        TIMESTAMPTZ NOT NULL DEFAULT now(),
  performed_by    UUID REFERENCES users(id),
  reviewer_notes  TEXT,
  reviewed_by     UUID REFERENCES users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_qc_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_lab_qc_results ON lab_qc_results
  USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_lab_qc_results_test_lot_date
  ON lab_qc_results (tenant_id, test_id, lot_id, run_date);

-- ══════════════════════════════════════════════════════════
--  lab_calibrations — calibration records per test/instrument
-- ══════════════════════════════════════════════════════════

CREATE TABLE lab_calibrations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL REFERENCES tenants(id),
  test_id               UUID NOT NULL REFERENCES lab_test_catalog(id),
  instrument_name       VARCHAR(200),
  calibrator_lot        VARCHAR(100),
  calibration_date      DATE,
  next_calibration_date DATE,
  result_summary        JSONB,
  is_passed             BOOLEAN NOT NULL DEFAULT true,
  performed_by          UUID REFERENCES users(id),
  notes                 TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_calibrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_lab_calibrations ON lab_calibrations
  USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ══════════════════════════════════════════════════════════
--  lab_outsourced_orders — external lab order tracking
-- ══════════════════════════════════════════════════════════

CREATE TABLE lab_outsourced_orders (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           UUID NOT NULL REFERENCES tenants(id),
  order_id            UUID NOT NULL REFERENCES lab_orders(id),
  external_lab_name   VARCHAR(200) NOT NULL,
  external_lab_code   VARCHAR(50),
  sent_date           DATE,
  expected_return_date DATE,
  actual_return_date  DATE,
  external_ref_number VARCHAR(100),
  status              lab_outsource_status NOT NULL DEFAULT 'pending_send',
  cost                NUMERIC(10,2),
  notes               TEXT,
  sent_by             UUID REFERENCES users(id),
  received_by         UUID REFERENCES users(id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_outsourced_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_lab_outsourced_orders ON lab_outsourced_orders
  USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_lab_outsourced_orders_updated_at
  BEFORE UPDATE ON lab_outsourced_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════
--  lab_phlebotomy_queue — collection worklist
-- ══════════════════════════════════════════════════════════

CREATE TABLE lab_phlebotomy_queue (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID NOT NULL REFERENCES tenants(id),
  order_id     UUID NOT NULL REFERENCES lab_orders(id),
  patient_id   UUID NOT NULL REFERENCES patients(id),
  priority     lab_priority NOT NULL DEFAULT 'routine',
  queue_number INT,
  status       lab_phlebotomy_status NOT NULL DEFAULT 'waiting',
  assigned_to  UUID REFERENCES users(id),
  location_id  UUID REFERENCES locations(id),
  queued_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at   TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lab_phlebotomy_queue ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_lab_phlebotomy_queue ON lab_phlebotomy_queue
  USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_lab_phlebotomy_queue_updated_at
  BEFORE UPDATE ON lab_phlebotomy_queue
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_lab_phlebotomy_queue_status
  ON lab_phlebotomy_queue (tenant_id, status, assigned_to);
