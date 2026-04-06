-- Migration 039: Recurring Appointments
-- Adds recurrence support to appointments table.

-- ============================================================
-- Add recurrence columns to appointments
-- ============================================================

ALTER TABLE appointments ADD COLUMN IF NOT EXISTS recurrence_pattern VARCHAR(20)
    CHECK (recurrence_pattern IS NULL OR recurrence_pattern IN ('weekly', 'biweekly', 'monthly'));

ALTER TABLE appointments ADD COLUMN IF NOT EXISTS recurrence_group_id UUID;

ALTER TABLE appointments ADD COLUMN IF NOT EXISTS recurrence_index INT DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_appointments_recurrence_group ON appointments(recurrence_group_id)
    WHERE recurrence_group_id IS NOT NULL;
