-- 066_mrd.sql — Medical Records Department
-- Tables: mrd_medical_records, mrd_record_movements, mrd_birth_register,
--         mrd_death_register, mrd_retention_policies

-- ── Enums ──────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE mrd_record_status AS ENUM ('active', 'archived', 'destroyed', 'missing');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE mrd_movement_status AS ENUM ('issued', 'returned', 'overdue');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE mrd_register_type AS ENUM ('birth', 'death');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ── mrd_medical_records ────────────────────────────────────

CREATE TABLE IF NOT EXISTS mrd_medical_records (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL REFERENCES tenants(id),
  patient_id    UUID NOT NULL REFERENCES patients(id),
  record_number TEXT NOT NULL,
  record_type   TEXT NOT NULL DEFAULT 'opd',
  volume_number INT NOT NULL DEFAULT 1,
  total_pages   INT,
  shelf_location TEXT,
  status        mrd_record_status NOT NULL DEFAULT 'active',
  last_accessed_at TIMESTAMPTZ,
  retention_years INT NOT NULL DEFAULT 5,
  destruction_due_date DATE,
  notes         TEXT,
  created_by    UUID REFERENCES users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, record_number)
);

ALTER TABLE mrd_medical_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mrd_medical_records_tenant ON mrd_medical_records;
CREATE POLICY mrd_medical_records_tenant ON mrd_medical_records
  USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX IF NOT EXISTS idx_mrd_medical_records_tenant ON mrd_medical_records(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mrd_medical_records_patient ON mrd_medical_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_mrd_medical_records_status ON mrd_medical_records(tenant_id, status);
DROP TRIGGER IF EXISTS trg_mrd_medical_records_updated ON mrd_medical_records;
CREATE TRIGGER trg_mrd_medical_records_updated BEFORE UPDATE ON mrd_medical_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── mrd_record_movements ───────────────────────────────────

CREATE TABLE IF NOT EXISTS mrd_record_movements (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           UUID NOT NULL REFERENCES tenants(id),
  medical_record_id   UUID NOT NULL REFERENCES mrd_medical_records(id),
  issued_to_user_id   UUID REFERENCES users(id),
  issued_to_department_id UUID REFERENCES departments(id),
  issued_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  due_date            DATE,
  returned_at         TIMESTAMPTZ,
  status              mrd_movement_status NOT NULL DEFAULT 'issued',
  purpose             TEXT,
  notes               TEXT,
  created_by          UUID REFERENCES users(id),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE mrd_record_movements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mrd_record_movements_tenant ON mrd_record_movements;
CREATE POLICY mrd_record_movements_tenant ON mrd_record_movements
  USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX IF NOT EXISTS idx_mrd_record_movements_tenant ON mrd_record_movements(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mrd_record_movements_record ON mrd_record_movements(medical_record_id);
CREATE INDEX IF NOT EXISTS idx_mrd_record_movements_status ON mrd_record_movements(tenant_id, status);
DROP TRIGGER IF EXISTS trg_mrd_record_movements_updated ON mrd_record_movements;
CREATE TRIGGER trg_mrd_record_movements_updated BEFORE UPDATE ON mrd_record_movements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── mrd_birth_register ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS mrd_birth_register (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL REFERENCES tenants(id),
  patient_id            UUID NOT NULL REFERENCES patients(id),
  admission_id          UUID REFERENCES admissions(id),
  register_number       TEXT NOT NULL,
  birth_date            DATE NOT NULL,
  birth_time            TIME,
  baby_gender           TEXT NOT NULL,
  baby_weight_grams     INT,
  birth_type            TEXT NOT NULL DEFAULT 'normal',
  apgar_1min            SMALLINT,
  apgar_5min            SMALLINT,
  complications         TEXT,
  attending_doctor_id   UUID REFERENCES users(id),
  certificate_number    TEXT,
  certificate_issued    BOOLEAN NOT NULL DEFAULT false,
  father_name           TEXT,
  mother_age            INT,
  created_by            UUID REFERENCES users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, register_number)
);

ALTER TABLE mrd_birth_register ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mrd_birth_register_tenant ON mrd_birth_register;
CREATE POLICY mrd_birth_register_tenant ON mrd_birth_register
  USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX IF NOT EXISTS idx_mrd_birth_register_tenant ON mrd_birth_register(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mrd_birth_register_patient ON mrd_birth_register(patient_id);
CREATE INDEX IF NOT EXISTS idx_mrd_birth_register_date ON mrd_birth_register(tenant_id, birth_date);
DROP TRIGGER IF EXISTS trg_mrd_birth_register_updated ON mrd_birth_register;
CREATE TRIGGER trg_mrd_birth_register_updated BEFORE UPDATE ON mrd_birth_register
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── mrd_death_register ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS mrd_death_register (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id             UUID NOT NULL REFERENCES tenants(id),
  patient_id            UUID NOT NULL REFERENCES patients(id),
  admission_id          UUID REFERENCES admissions(id),
  er_visit_id           UUID REFERENCES er_visits(id),
  mlc_case_id           UUID REFERENCES mlc_cases(id),
  register_number       TEXT NOT NULL,
  death_date            DATE NOT NULL,
  death_time            TIME,
  cause_of_death        TEXT,
  immediate_cause       TEXT,
  antecedent_cause      TEXT,
  underlying_cause      TEXT,
  manner_of_death       TEXT NOT NULL DEFAULT 'natural',
  is_medico_legal       BOOLEAN NOT NULL DEFAULT false,
  is_brought_dead       BOOLEAN NOT NULL DEFAULT false,
  certifying_doctor_id  UUID REFERENCES users(id),
  certificate_number    TEXT,
  certificate_issued    BOOLEAN NOT NULL DEFAULT false,
  reported_to_municipality BOOLEAN NOT NULL DEFAULT false,
  municipality_report_date DATE,
  created_by            UUID REFERENCES users(id),
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, register_number)
);

ALTER TABLE mrd_death_register ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mrd_death_register_tenant ON mrd_death_register;
CREATE POLICY mrd_death_register_tenant ON mrd_death_register
  USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX IF NOT EXISTS idx_mrd_death_register_tenant ON mrd_death_register(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mrd_death_register_patient ON mrd_death_register(patient_id);
CREATE INDEX IF NOT EXISTS idx_mrd_death_register_date ON mrd_death_register(tenant_id, death_date);
DROP TRIGGER IF EXISTS trg_mrd_death_register_updated ON mrd_death_register;
CREATE TRIGGER trg_mrd_death_register_updated BEFORE UPDATE ON mrd_death_register
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── mrd_retention_policies ─────────────────────────────────

CREATE TABLE IF NOT EXISTS mrd_retention_policies (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         UUID NOT NULL REFERENCES tenants(id),
  record_type       TEXT NOT NULL,
  category          TEXT NOT NULL,
  retention_years   INT NOT NULL DEFAULT 5,
  legal_reference   TEXT,
  destruction_method TEXT,
  is_active         BOOLEAN NOT NULL DEFAULT true,
  created_by        UUID REFERENCES users(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id, record_type, category)
);

ALTER TABLE mrd_retention_policies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mrd_retention_policies_tenant ON mrd_retention_policies;
CREATE POLICY mrd_retention_policies_tenant ON mrd_retention_policies
  USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX IF NOT EXISTS idx_mrd_retention_policies_tenant ON mrd_retention_policies(tenant_id);
DROP TRIGGER IF EXISTS trg_mrd_retention_policies_updated ON mrd_retention_policies;
CREATE TRIGGER trg_mrd_retention_policies_updated BEFORE UPDATE ON mrd_retention_policies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Seed MRD sequence types ────────────────────────────────

INSERT INTO sequences (tenant_id, seq_type, prefix, current_val, pad_width)
SELECT t.id, s.seq_type, s.prefix, 0, s.pad_width
FROM tenants t
CROSS JOIN (VALUES
  ('MRD_RECORD', 'MRD-', 6),
  ('MRD_BIRTH', 'BR-', 6),
  ('MRD_DEATH', 'DR-', 6)
) AS s(seq_type, prefix, pad_width)
WHERE NOT EXISTS (
  SELECT 1 FROM sequences sq WHERE sq.tenant_id = t.id AND sq.seq_type = s.seq_type
);
