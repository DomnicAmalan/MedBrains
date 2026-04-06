-- Migration 038: Queue visit_type + Consultation Templates
-- Adds visit_type to encounters/queues, adds consultation_templates table.

-- ============================================================
-- Add visit_type to encounters
-- ============================================================

ALTER TABLE encounters ADD COLUMN IF NOT EXISTS visit_type VARCHAR(20) DEFAULT 'walk_in'
    CHECK (visit_type IN ('walk_in', 'booked', 'follow_up', 'referral', 'emergency'));

-- ============================================================
-- Consultation Templates — specialty-specific casesheet templates
-- ============================================================

CREATE TABLE IF NOT EXISTS consultation_templates (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    created_by      UUID NOT NULL REFERENCES users(id),
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    specialty       VARCHAR(100),
    department_id   UUID REFERENCES departments(id),
    is_shared       BOOLEAN NOT NULL DEFAULT false,
    chief_complaints TEXT[] DEFAULT '{}'::text[],
    default_history JSONB DEFAULT '{}'::jsonb,
    default_examination JSONB DEFAULT '{}'::jsonb,
    default_ros     JSONB DEFAULT '{}'::jsonb,
    default_plan    TEXT,
    common_diagnoses TEXT[] DEFAULT '{}'::text[],
    common_medications JSONB DEFAULT '[]'::jsonb,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, name)
);

CREATE INDEX idx_consult_templates_tenant ON consultation_templates(tenant_id);
CREATE INDEX idx_consult_templates_specialty ON consultation_templates(specialty);
CREATE INDEX idx_consult_templates_dept ON consultation_templates(department_id);

ALTER TABLE consultation_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY consultation_templates_tenant ON consultation_templates
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
