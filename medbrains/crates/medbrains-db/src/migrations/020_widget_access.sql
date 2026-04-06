-- 020: Add widget_access_defaults to roles table for per-role widget-level access control.
-- Maps widget template UUIDs to "visible" | "hidden".
-- User-level overrides are stored in users.access_matrix.widget_access (JSONB, no schema change needed).
ALTER TABLE roles ADD COLUMN widget_access_defaults JSONB NOT NULL DEFAULT '{}';
