-- Migration 079: IPD Phase 3b — Specialty clinical doc types + billing thresholds
-- Adds new ipd_clinical_doc_type enum values for specialty nursing workflows
-- and billing threshold columns to ip_type_configurations.

-- New clinical doc types for specialty nursing
ALTER TYPE ipd_clinical_doc_type ADD VALUE IF NOT EXISTS 'elopement_risk';
ALTER TYPE ipd_clinical_doc_type ADD VALUE IF NOT EXISTS 'dialysis';
ALTER TYPE ipd_clinical_doc_type ADD VALUE IF NOT EXISTS 'endoscopy';
ALTER TYPE ipd_clinical_doc_type ADD VALUE IF NOT EXISTS 'chemotherapy';
ALTER TYPE ipd_clinical_doc_type ADD VALUE IF NOT EXISTS 'blood_transfusion_checklist';

-- Billing thresholds on IP type config
ALTER TABLE ip_type_configurations
    ADD COLUMN IF NOT EXISTS billing_alert_threshold NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS auto_billing_enabled BOOLEAN NOT NULL DEFAULT false;
