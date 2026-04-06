-- MedBrains HMS — Phase 1 Module Tables
-- Registration, OPD, Lab, Billing, IPD basics, Admin, Dashboard

-- ============================================================
-- New enum types for Phase 1
-- ============================================================

CREATE TYPE encounter_type AS ENUM ('opd', 'ipd', 'emergency');
CREATE TYPE encounter_status AS ENUM ('open', 'in_progress', 'completed', 'cancelled');
CREATE TYPE queue_status AS ENUM ('waiting', 'called', 'in_consultation', 'completed', 'no_show');
CREATE TYPE lab_order_status AS ENUM ('ordered', 'sample_collected', 'processing', 'completed', 'verified', 'cancelled');
CREATE TYPE lab_priority AS ENUM ('routine', 'urgent', 'stat');
CREATE TYPE lab_result_flag AS ENUM ('normal', 'low', 'high', 'critical_low', 'critical_high', 'abnormal');
CREATE TYPE invoice_status AS ENUM ('draft', 'issued', 'partially_paid', 'paid', 'cancelled', 'refunded');
CREATE TYPE payment_mode AS ENUM ('cash', 'card', 'upi', 'bank_transfer', 'cheque', 'insurance', 'credit');
CREATE TYPE charge_source AS ENUM ('opd', 'ipd', 'lab', 'pharmacy', 'procedure', 'manual');
CREATE TYPE admission_status AS ENUM ('admitted', 'transferred', 'discharged', 'absconded', 'deceased');
CREATE TYPE discharge_type AS ENUM ('normal', 'lama', 'dama', 'absconded', 'referred', 'deceased');

-- ============================================================
-- Sequences — atomic counters (replaces YottaDB ^SEQUENCE)
-- ============================================================

CREATE TABLE sequences (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    seq_type    TEXT NOT NULL,
    prefix      TEXT NOT NULL DEFAULT '',
    current_val BIGINT NOT NULL DEFAULT 0,
    pad_width   INT NOT NULL DEFAULT 5,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, seq_type)
);

-- ============================================================
-- Encounters — shared OPD/IPD/ER visit record
-- ============================================================

CREATE TABLE encounters (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_type  encounter_type NOT NULL,
    status          encounter_status NOT NULL DEFAULT 'open',
    department_id   UUID REFERENCES departments(id),
    doctor_id       UUID REFERENCES users(id),
    encounter_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    notes           TEXT,
    attributes      JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_encounters_tenant ON encounters(tenant_id);
CREATE INDEX idx_encounters_patient ON encounters(patient_id);
CREATE INDEX idx_encounters_date ON encounters(tenant_id, encounter_date);
CREATE INDEX idx_encounters_doctor ON encounters(doctor_id);

-- ============================================================
-- OPD Queue — token-based queue
-- ============================================================

CREATE TABLE opd_queues (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    department_id   UUID NOT NULL REFERENCES departments(id),
    doctor_id       UUID REFERENCES users(id),
    token_number    INT NOT NULL,
    status          queue_status NOT NULL DEFAULT 'waiting',
    queue_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    called_at       TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_opd_queues_tenant ON opd_queues(tenant_id);
CREATE INDEX idx_opd_queues_date ON opd_queues(tenant_id, queue_date);
CREATE INDEX idx_opd_queues_doctor ON opd_queues(doctor_id, queue_date);

-- ============================================================
-- Consultations — doctor consultation notes
-- ============================================================

CREATE TABLE consultations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    chief_complaint TEXT,
    history         TEXT,
    examination     TEXT,
    plan            TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_consultations_tenant ON consultations(tenant_id);
CREATE INDEX idx_consultations_encounter ON consultations(encounter_id);

-- ============================================================
-- Diagnoses — ICD-10 coded
-- ============================================================

CREATE TABLE diagnoses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    icd_code        TEXT,
    description     TEXT NOT NULL,
    is_primary      BOOLEAN NOT NULL DEFAULT false,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_diagnoses_tenant ON diagnoses(tenant_id);
CREATE INDEX idx_diagnoses_encounter ON diagnoses(encounter_id);

-- ============================================================
-- Prescriptions + Items
-- ============================================================

CREATE TABLE prescriptions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE prescription_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id),
    drug_name       TEXT NOT NULL,
    dosage          TEXT NOT NULL,
    frequency       TEXT NOT NULL,
    duration        TEXT NOT NULL,
    route           TEXT,
    instructions    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_prescriptions_tenant ON prescriptions(tenant_id);
CREATE INDEX idx_prescriptions_encounter ON prescriptions(encounter_id);
CREATE INDEX idx_prescription_items_prescription ON prescription_items(prescription_id);

-- ============================================================
-- Vitals — patient vital signs
-- ============================================================

CREATE TABLE vitals (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    recorded_by     UUID NOT NULL REFERENCES users(id),
    temperature     NUMERIC(4,1),
    pulse           INT,
    systolic_bp     INT,
    diastolic_bp    INT,
    respiratory_rate INT,
    spo2            INT,
    weight_kg       NUMERIC(5,2),
    height_cm       NUMERIC(5,1),
    bmi             NUMERIC(4,1),
    notes           TEXT,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_vitals_tenant ON vitals(tenant_id);
CREATE INDEX idx_vitals_encounter ON vitals(encounter_id);

-- ============================================================
-- Lab Test Catalog — master data
-- ============================================================

CREATE TABLE lab_test_catalog (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    department_id   UUID REFERENCES departments(id),
    sample_type     TEXT,
    normal_range    TEXT,
    unit            TEXT,
    price           NUMERIC(10,2) NOT NULL DEFAULT 0,
    tat_hours       INT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_lab_test_catalog_tenant ON lab_test_catalog(tenant_id);

-- ============================================================
-- Lab Orders
-- ============================================================

CREATE TABLE lab_orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    test_id         UUID NOT NULL REFERENCES lab_test_catalog(id),
    ordered_by      UUID NOT NULL REFERENCES users(id),
    status          lab_order_status NOT NULL DEFAULT 'ordered',
    priority        lab_priority NOT NULL DEFAULT 'routine',
    collected_at    TIMESTAMPTZ,
    collected_by    UUID REFERENCES users(id),
    verified_by     UUID REFERENCES users(id),
    verified_at     TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_lab_orders_tenant ON lab_orders(tenant_id);
CREATE INDEX idx_lab_orders_patient ON lab_orders(patient_id);
CREATE INDEX idx_lab_orders_status ON lab_orders(tenant_id, status);
CREATE INDEX idx_lab_orders_encounter ON lab_orders(encounter_id);

-- ============================================================
-- Lab Results — parameter values
-- ============================================================

CREATE TABLE lab_results (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES lab_orders(id),
    parameter_name  TEXT NOT NULL,
    value           TEXT NOT NULL,
    unit            TEXT,
    normal_range    TEXT,
    flag            lab_result_flag,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_lab_results_order ON lab_results(order_id);

-- ============================================================
-- Charge Master — service pricing catalog
-- ============================================================

CREATE TABLE charge_master (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    category        TEXT NOT NULL,
    base_price      NUMERIC(10,2) NOT NULL,
    tax_percent     NUMERIC(4,2) NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_charge_master_tenant ON charge_master(tenant_id);

-- ============================================================
-- Invoices + Items
-- ============================================================

CREATE TABLE invoices (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    invoice_number  TEXT NOT NULL,
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID REFERENCES encounters(id),
    status          invoice_status NOT NULL DEFAULT 'draft',
    subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0,
    tax_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
    paid_amount     NUMERIC(12,2) NOT NULL DEFAULT 0,
    notes           TEXT,
    issued_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, invoice_number)
);

CREATE TABLE invoice_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    invoice_id      UUID NOT NULL REFERENCES invoices(id),
    charge_code     TEXT NOT NULL,
    description     TEXT NOT NULL,
    source          charge_source NOT NULL DEFAULT 'manual',
    source_id       UUID,
    quantity        INT NOT NULL DEFAULT 1,
    unit_price      NUMERIC(10,2) NOT NULL,
    tax_percent     NUMERIC(4,2) NOT NULL DEFAULT 0,
    total_price     NUMERIC(12,2) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX idx_invoices_patient ON invoices(patient_id);
CREATE INDEX idx_invoices_status ON invoices(tenant_id, status);
CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);

-- ============================================================
-- Payments
-- ============================================================

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    invoice_id      UUID NOT NULL REFERENCES invoices(id),
    amount          NUMERIC(12,2) NOT NULL,
    mode            payment_mode NOT NULL,
    reference_number TEXT,
    received_by     UUID REFERENCES users(id),
    notes           TEXT,
    paid_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_tenant ON payments(tenant_id);
CREATE INDEX idx_payments_invoice ON payments(invoice_id);

-- ============================================================
-- Admissions — IPD
-- ============================================================

CREATE TABLE admissions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    bed_id          UUID REFERENCES locations(id),
    admitting_doctor UUID NOT NULL REFERENCES users(id),
    status          admission_status NOT NULL DEFAULT 'admitted',
    admitted_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    discharged_at   TIMESTAMPTZ,
    discharge_type  discharge_type,
    discharge_summary TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_admissions_tenant ON admissions(tenant_id);
CREATE INDEX idx_admissions_patient ON admissions(patient_id);
CREATE INDEX idx_admissions_status ON admissions(tenant_id, status);
CREATE INDEX idx_admissions_bed ON admissions(bed_id);

-- ============================================================
-- Nursing Tasks
-- ============================================================

CREATE TABLE nursing_tasks (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    admission_id    UUID NOT NULL REFERENCES admissions(id),
    assigned_to     UUID REFERENCES users(id),
    task_type       TEXT NOT NULL,
    description     TEXT NOT NULL,
    is_completed    BOOLEAN NOT NULL DEFAULT false,
    due_at          TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    completed_by    UUID REFERENCES users(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_nursing_tasks_tenant ON nursing_tasks(tenant_id);
CREATE INDEX idx_nursing_tasks_admission ON nursing_tasks(admission_id);
CREATE INDEX idx_nursing_tasks_assigned ON nursing_tasks(assigned_to);

-- ============================================================
-- Audit Log — tamper-evident hash chain
-- ============================================================

CREATE TABLE audit_log (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    user_id         UUID REFERENCES users(id),
    action          TEXT NOT NULL,
    entity_type     TEXT NOT NULL,
    entity_id       UUID,
    old_values      JSONB,
    new_values      JSONB,
    ip_address      TEXT,
    prev_hash       TEXT,
    hash            TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_tenant ON audit_log(tenant_id);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_audit_log_created ON audit_log(tenant_id, created_at);

-- ============================================================
-- Refresh Tokens — JWT refresh token storage
-- ============================================================

CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    token_hash      TEXT NOT NULL UNIQUE,
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked         BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- ============================================================
-- Master Config — PostgreSQL substitute for YottaDB ^CONFIG
-- ============================================================

CREATE TABLE master_config (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    module          TEXT NOT NULL,
    key             TEXT NOT NULL,
    value           JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, module, key)
);

CREATE INDEX idx_master_config_tenant ON master_config(tenant_id);

-- ============================================================
-- Row-Level Security — all new tenant-scoped tables
-- ============================================================

ALTER TABLE sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE encounters ENABLE ROW LEVEL SECURITY;
ALTER TABLE opd_queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnoses ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_test_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE charge_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE admissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE nursing_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_config ENABLE ROW LEVEL SECURITY;

-- RLS policies: tenant isolation
CREATE POLICY tenant_isolation_sequences ON sequences
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_encounters ON encounters
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_opd_queues ON opd_queues
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_consultations ON consultations
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_diagnoses ON diagnoses
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_prescriptions ON prescriptions
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_prescription_items ON prescription_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_vitals ON vitals
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_lab_test_catalog ON lab_test_catalog
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_lab_orders ON lab_orders
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_lab_results ON lab_results
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_charge_master ON charge_master
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_invoices ON invoices
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_invoice_items ON invoice_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_payments ON payments
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_admissions ON admissions
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_nursing_tasks ON nursing_tasks
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_audit_log ON audit_log
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_refresh_tokens ON refresh_tokens
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY tenant_isolation_master_config ON master_config
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers for new tables
-- ============================================================

CREATE TRIGGER trg_sequences_updated_at BEFORE UPDATE ON sequences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_encounters_updated_at BEFORE UPDATE ON encounters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_opd_queues_updated_at BEFORE UPDATE ON opd_queues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_consultations_updated_at BEFORE UPDATE ON consultations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_prescriptions_updated_at BEFORE UPDATE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_lab_test_catalog_updated_at BEFORE UPDATE ON lab_test_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_lab_orders_updated_at BEFORE UPDATE ON lab_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_charge_master_updated_at BEFORE UPDATE ON charge_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_admissions_updated_at BEFORE UPDATE ON admissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_nursing_tasks_updated_at BEFORE UPDATE ON nursing_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_master_config_updated_at BEFORE UPDATE ON master_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Full-text search index for patients
-- ============================================================

CREATE INDEX idx_patients_fulltext ON patients USING gin (
    to_tsvector('english', coalesce(first_name, '') || ' ' || coalesce(last_name, '') || ' ' || coalesce(phone, '') || ' ' || coalesce(uhid, ''))
);
