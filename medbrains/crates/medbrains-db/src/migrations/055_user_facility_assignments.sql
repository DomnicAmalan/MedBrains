-- Migration 055: User-to-Facility Assignment
-- P0 feature: Allows assigning users to specific facilities in multi-hospital setups

CREATE TABLE user_facility_assignments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    facility_id     UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    is_primary      BOOLEAN NOT NULL DEFAULT false,
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, user_id, facility_id)
);

CREATE INDEX idx_ufa_tenant ON user_facility_assignments(tenant_id);
CREATE INDEX idx_ufa_user ON user_facility_assignments(user_id);
CREATE INDEX idx_ufa_facility ON user_facility_assignments(facility_id);

ALTER TABLE user_facility_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_ufa ON user_facility_assignments
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE TRIGGER set_updated_at_ufa
    BEFORE UPDATE ON user_facility_assignments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
