-- 009: Add field_access_defaults to roles table for per-role field-level access control.
-- user-level overrides are stored in users.access_matrix.field_access (JSONB, no schema change needed).
ALTER TABLE roles ADD COLUMN field_access_defaults JSONB NOT NULL DEFAULT '{}';
