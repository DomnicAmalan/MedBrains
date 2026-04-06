-- Add permission version column to users table.
-- Incremented whenever role, permissions, or access_matrix changes.
-- JWT tokens carry this version; auth middleware rejects stale tokens.

ALTER TABLE users ADD COLUMN IF NOT EXISTS perm_version INT NOT NULL DEFAULT 1;
