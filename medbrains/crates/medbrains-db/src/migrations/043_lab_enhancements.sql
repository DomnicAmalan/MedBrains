-- Lab enhancements — test panels/profiles, panel-test junction,
-- sample rejection tracking, and order rejection reason.
-- Builds on existing lab tables from migration 002:
--   lab_test_catalog, lab_orders, lab_results

-- ============================================================
-- 1. Lab Test Panels — grouped test profiles (CBC, LFT, KFT, etc.)
-- ============================================================

CREATE TABLE lab_test_panels (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        VARCHAR(50) NOT NULL,
    name        VARCHAR(200) NOT NULL,
    description TEXT,
    price       DECIMAL(12,2) NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

CREATE INDEX idx_lab_test_panels_tenant ON lab_test_panels(tenant_id);

-- ============================================================
-- 2. Lab Panel Tests — junction linking panels to individual tests
-- ============================================================

CREATE TABLE lab_panel_tests (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id  UUID NOT NULL REFERENCES tenants(id),
    panel_id   UUID NOT NULL REFERENCES lab_test_panels(id) ON DELETE CASCADE,
    test_id    UUID NOT NULL REFERENCES lab_test_catalog(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    UNIQUE (panel_id, test_id)
);

CREATE INDEX idx_lab_panel_tests_tenant ON lab_panel_tests(tenant_id);
CREATE INDEX idx_lab_panel_tests_panel ON lab_panel_tests(panel_id);

-- ============================================================
-- 3. Lab Sample Rejections — sample rejection tracking
-- ============================================================

CREATE TABLE lab_sample_rejections (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    order_id         UUID NOT NULL REFERENCES lab_orders(id),
    rejected_by      UUID NOT NULL REFERENCES users(id),
    rejection_reason VARCHAR(500) NOT NULL,
    rejected_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_lab_sample_rejections_tenant ON lab_sample_rejections(tenant_id);
CREATE INDEX idx_lab_sample_rejections_order ON lab_sample_rejections(order_id);

-- ============================================================
-- 4. ALTER lab_orders — add rejection_reason for quick access
-- ============================================================

ALTER TABLE lab_orders ADD COLUMN rejection_reason VARCHAR(500);

-- ============================================================
-- Row-Level Security
-- ============================================================

ALTER TABLE lab_test_panels ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_panel_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_sample_rejections ENABLE ROW LEVEL SECURITY;

CREATE POLICY lab_test_panels_tenant_isolation ON lab_test_panels
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY lab_panel_tests_tenant_isolation ON lab_panel_tests
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY lab_sample_rejections_tenant_isolation ON lab_sample_rejections
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- ============================================================
-- Updated-at triggers (tables with updated_at column)
-- ============================================================

CREATE TRIGGER set_updated_at_lab_test_panels
    BEFORE UPDATE ON lab_test_panels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
