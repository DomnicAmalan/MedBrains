-- ============================================================
-- Migration 008: Add timestamp columns to regulatory_bodies
-- The table was created in 003 without created_at / updated_at,
-- but the admin CRUD handlers (admin_forms.rs) expect them.
-- ============================================================

ALTER TABLE regulatory_bodies
    ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TRIGGER set_updated_at_regulatory_bodies
    BEFORE UPDATE ON regulatory_bodies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
