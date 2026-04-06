-- MedBrains HMS — Initial Schema
-- Multi-tenant with Row-Level Security on all tenant-scoped tables.

-- ============================================================
-- Custom enum types
-- ============================================================

CREATE TYPE hospital_type AS ENUM (
    'medical_college',
    'multi_specialty',
    'district_hospital',
    'community_health',
    'primary_health',
    'standalone_clinic',
    'eye_hospital',
    'dental_college'
);

CREATE TYPE location_level AS ENUM (
    'campus',
    'building',
    'floor',
    'wing',
    'zone',
    'room',
    'bed'
);

CREATE TYPE bed_status AS ENUM (
    'vacant_clean',
    'vacant_dirty',
    'reserved',
    'occupied',
    'occupied_transfer_pending',
    'maintenance',
    'blocked'
);

CREATE TYPE department_type AS ENUM (
    'clinical',
    'pre_clinical',
    'para_clinical',
    'administrative',
    'support',
    'academic'
);

CREATE TYPE service_type AS ENUM (
    'consultation',
    'procedure',
    'investigation',
    'surgery',
    'therapy',
    'nursing',
    'support',
    'administrative'
);

CREATE TYPE gender AS ENUM (
    'male',
    'female',
    'other',
    'unknown'
);

CREATE TYPE patient_category AS ENUM (
    'general',
    'private',
    'insurance',
    'pmjay',
    'cghs',
    'staff',
    'vip',
    'mlc'
);

CREATE TYPE user_role AS ENUM (
    'super_admin',
    'hospital_admin',
    'doctor',
    'nurse',
    'receptionist',
    'lab_technician',
    'pharmacist',
    'billing_clerk',
    'housekeeping_staff',
    'facilities_manager',
    'audit_officer'
);

CREATE TYPE workflow_status AS ENUM (
    'pending',
    'in_progress',
    'paused',
    'completed',
    'cancelled',
    'error'
);

-- ============================================================
-- Extensions
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- Tenants (global — no RLS)
-- ============================================================

CREATE TABLE tenants (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code        TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    hospital_type hospital_type NOT NULL,
    config      JSONB NOT NULL DEFAULT '{}',
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Locations — 6-level self-referencing tree (Layer 1)
-- ============================================================

CREATE TABLE locations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    parent_id   UUID REFERENCES locations(id),
    level       location_level NOT NULL,
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    attributes  JSONB NOT NULL DEFAULT '{}',
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_locations_tenant ON locations(tenant_id);
CREATE INDEX idx_locations_parent ON locations(parent_id);
CREATE INDEX idx_locations_level ON locations(tenant_id, level);

-- ============================================================
-- Bed States — state machine (Layer 1)
-- ============================================================

CREATE TABLE bed_states (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    location_id UUID NOT NULL REFERENCES locations(id),
    status      bed_status NOT NULL DEFAULT 'vacant_clean',
    patient_id  UUID,
    changed_by  UUID,
    reason      TEXT,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, location_id)
);

CREATE INDEX idx_bed_states_tenant ON bed_states(tenant_id);
CREATE INDEX idx_bed_states_status ON bed_states(tenant_id, status);

-- ============================================================
-- Departments — tree structure (Layer 2)
-- ============================================================

CREATE TABLE departments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    parent_id       UUID REFERENCES departments(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    department_type department_type NOT NULL,
    config          JSONB NOT NULL DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_departments_tenant ON departments(tenant_id);
CREATE INDEX idx_departments_parent ON departments(parent_id);

-- ============================================================
-- Services — catalog linked to departments (Layer 2)
-- ============================================================

CREATE TABLE services (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id),
    department_id           UUID NOT NULL REFERENCES departments(id),
    code                    TEXT NOT NULL,
    name                    TEXT NOT NULL,
    service_type            service_type NOT NULL,
    config                  JSONB NOT NULL DEFAULT '{}',
    workflow_template_id    UUID,  -- FK added after workflow_templates table
    is_active               BOOLEAN NOT NULL DEFAULT true,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_services_tenant ON services(tenant_id);
CREATE INDEX idx_services_department ON services(department_id);

-- ============================================================
-- Users — auth + ABAC
-- ============================================================

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    username        TEXT NOT NULL,
    email           TEXT NOT NULL,
    password_hash   TEXT NOT NULL,
    full_name       TEXT NOT NULL,
    role            user_role NOT NULL,
    access_matrix   JSONB NOT NULL DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, username),
    UNIQUE (tenant_id, email)
);

CREATE INDEX idx_users_tenant ON users(tenant_id);

-- ============================================================
-- Patients — demographics + UHID
-- ============================================================

CREATE TABLE patients (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    uhid            TEXT NOT NULL,
    abha_id         TEXT,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    date_of_birth   DATE,
    gender          gender NOT NULL,
    phone           TEXT NOT NULL,
    email           TEXT,
    address         JSONB,
    category        patient_category NOT NULL DEFAULT 'general',
    attributes      JSONB NOT NULL DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, uhid)
);

CREATE INDEX idx_patients_tenant ON patients(tenant_id);
CREATE INDEX idx_patients_phone ON patients(tenant_id, phone);
CREATE INDEX idx_patients_abha ON patients(abha_id) WHERE abha_id IS NOT NULL;

-- ============================================================
-- Workflow Templates — configurable blueprints (Layer 3)
-- ============================================================

CREATE TABLE workflow_templates (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    version     INT NOT NULL DEFAULT 1,
    steps       JSONB NOT NULL DEFAULT '[]',
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code, version)
);

CREATE INDEX idx_workflow_templates_tenant ON workflow_templates(tenant_id);

-- Add FK from services to workflow_templates now that the table exists
ALTER TABLE services
    ADD CONSTRAINT fk_services_workflow_template
    FOREIGN KEY (workflow_template_id) REFERENCES workflow_templates(id);

-- ============================================================
-- Workflow Instances — running state
-- ============================================================

CREATE TABLE workflow_instances (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    template_id     UUID NOT NULL REFERENCES workflow_templates(id),
    patient_id      UUID REFERENCES patients(id),
    status          workflow_status NOT NULL DEFAULT 'pending',
    current_step    INT NOT NULL DEFAULT 0,
    state           JSONB NOT NULL DEFAULT '{}',
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ
);

CREATE INDEX idx_workflow_instances_tenant ON workflow_instances(tenant_id);
CREATE INDEX idx_workflow_instances_patient ON workflow_instances(patient_id);
CREATE INDEX idx_workflow_instances_status ON workflow_instances(tenant_id, status);

-- ============================================================
-- Workflow Step Logs — audit trail
-- ============================================================

CREATE TABLE workflow_step_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    instance_id     UUID NOT NULL REFERENCES workflow_instances(id),
    step_index      INT NOT NULL,
    step_name       TEXT NOT NULL,
    actor_id        UUID REFERENCES users(id),
    action          TEXT NOT NULL,
    data            JSONB NOT NULL DEFAULT '{}',
    sla_met         BOOLEAN,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ
);

CREATE INDEX idx_workflow_step_logs_instance ON workflow_step_logs(instance_id);
CREATE INDEX idx_workflow_step_logs_tenant ON workflow_step_logs(tenant_id);

-- ============================================================
-- Row-Level Security — all tenant-scoped tables
-- ============================================================

ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bed_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_step_logs ENABLE ROW LEVEL SECURITY;

-- RLS policies: tenant isolation via app.tenant_id session variable
CREATE POLICY tenant_isolation_locations ON locations
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_bed_states ON bed_states
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_departments ON departments
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_services ON services
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_users ON users
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_patients ON patients
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_workflow_templates ON workflow_templates
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_workflow_instances ON workflow_instances
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE POLICY tenant_isolation_workflow_step_logs ON workflow_step_logs
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at trigger function
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_locations_updated_at BEFORE UPDATE ON locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_departments_updated_at BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_services_updated_at BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_workflow_templates_updated_at BEFORE UPDATE ON workflow_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
