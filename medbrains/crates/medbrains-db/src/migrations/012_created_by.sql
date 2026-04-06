-- Add created_by column to track record ownership.
-- Used for ownership-aware access control: non-admin users
-- can be restricted to records they created or are assigned to.

ALTER TABLE patients ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
ALTER TABLE encounters ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
ALTER TABLE opd_queues ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
ALTER TABLE lab_orders ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
ALTER TABLE admissions ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);

-- Index for efficient ownership queries
CREATE INDEX IF NOT EXISTS idx_patients_created_by ON patients(created_by);
CREATE INDEX IF NOT EXISTS idx_encounters_created_by ON encounters(created_by);
CREATE INDEX IF NOT EXISTS idx_lab_orders_created_by ON lab_orders(created_by);
CREATE INDEX IF NOT EXISTS idx_invoices_created_by ON invoices(created_by);
CREATE INDEX IF NOT EXISTS idx_admissions_created_by ON admissions(created_by);
