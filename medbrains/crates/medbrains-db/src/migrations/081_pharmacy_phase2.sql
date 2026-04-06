-- Migration 081: Pharmacy Phase 2
-- Dispensing enhancements, NDPS register, batch tracking, multi-store, returns, analytics

-- ════════════════════════════════════════════════════════
--  ENUMS
-- ════════════════════════════════════════════════════════

CREATE TYPE pharmacy_dispensing_type AS ENUM (
    'prescription', 'otc', 'discharge', 'package', 'emergency'
);

CREATE TYPE ndps_register_action AS ENUM (
    'receipt', 'dispensed', 'destroyed', 'transferred', 'adjustment'
);

CREATE TYPE pharmacy_return_status AS ENUM (
    'requested', 'approved', 'returned_to_stock', 'destroyed', 'rejected'
);

-- ════════════════════════════════════════════════════════
--  ALTER pharmacy_orders — dispensing context
-- ════════════════════════════════════════════════════════

ALTER TABLE pharmacy_orders
    ADD COLUMN IF NOT EXISTS dispensing_type pharmacy_dispensing_type NOT NULL DEFAULT 'prescription',
    ADD COLUMN IF NOT EXISTS discharge_summary_id UUID REFERENCES ipd_discharge_summaries(id),
    ADD COLUMN IF NOT EXISTS billing_package_id UUID REFERENCES billing_packages(id),
    ADD COLUMN IF NOT EXISTS store_location_id UUID REFERENCES store_locations(id),
    ADD COLUMN IF NOT EXISTS interaction_check_result JSONB,
    ADD COLUMN IF NOT EXISTS dispensed_by UUID REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS dispensed_at TIMESTAMPTZ;

-- ════════════════════════════════════════════════════════
--  ALTER pharmacy_order_items — batch tracking
-- ════════════════════════════════════════════════════════

ALTER TABLE pharmacy_order_items
    ADD COLUMN IF NOT EXISTS batch_number TEXT,
    ADD COLUMN IF NOT EXISTS expiry_date DATE,
    ADD COLUMN IF NOT EXISTS batch_stock_id UUID REFERENCES batch_stock(id),
    ADD COLUMN IF NOT EXISTS quantity_prescribed INTEGER,
    ADD COLUMN IF NOT EXISTS quantity_returned INTEGER NOT NULL DEFAULT 0;

-- ════════════════════════════════════════════════════════
--  NEW TABLE: pharmacy_batches
-- ════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pharmacy_batches (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES pharmacy_catalog(id),
    batch_number   TEXT NOT NULL,
    expiry_date    DATE NOT NULL,
    manufacture_date DATE,
    quantity_received  INTEGER NOT NULL DEFAULT 0,
    quantity_dispensed  INTEGER NOT NULL DEFAULT 0,
    quantity_on_hand   INTEGER NOT NULL DEFAULT 0,
    store_location_id  UUID REFERENCES store_locations(id),
    supplier_info  TEXT,
    grn_item_id    UUID,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pharmacy_batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY pharmacy_batches_tenant ON pharmacy_batches
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_pharmacy_batches_updated_at
    BEFORE UPDATE ON pharmacy_batches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_pharmacy_batches_tenant_catalog_expiry
    ON pharmacy_batches (tenant_id, catalog_item_id, expiry_date);
CREATE INDEX idx_pharmacy_batches_tenant_location
    ON pharmacy_batches (tenant_id, store_location_id);

-- ════════════════════════════════════════════════════════
--  NEW TABLE: pharmacy_ndps_register
-- ════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pharmacy_ndps_register (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES pharmacy_catalog(id),
    action         ndps_register_action NOT NULL,
    quantity       INTEGER NOT NULL,
    balance_after  INTEGER NOT NULL,
    patient_id     UUID REFERENCES patients(id),
    prescription_id UUID,
    dispensed_by   UUID REFERENCES users(id),
    witnessed_by   UUID REFERENCES users(id),
    register_number TEXT,
    page_number    TEXT,
    notes          TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pharmacy_ndps_register ENABLE ROW LEVEL SECURITY;
CREATE POLICY pharmacy_ndps_register_tenant ON pharmacy_ndps_register
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_pharmacy_ndps_register_updated_at
    BEFORE UPDATE ON pharmacy_ndps_register
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_pharmacy_ndps_register_tenant_catalog
    ON pharmacy_ndps_register (tenant_id, catalog_item_id, created_at);

-- ════════════════════════════════════════════════════════
--  NEW TABLE: pharmacy_returns
-- ════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pharmacy_returns (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(id),
    order_item_id  UUID NOT NULL REFERENCES pharmacy_order_items(id),
    patient_id     UUID NOT NULL REFERENCES patients(id),
    quantity_returned INTEGER NOT NULL,
    reason         TEXT,
    status         pharmacy_return_status NOT NULL DEFAULT 'requested',
    approved_by    UUID REFERENCES users(id),
    return_batch_id UUID REFERENCES pharmacy_batches(id),
    restocked      BOOLEAN NOT NULL DEFAULT false,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pharmacy_returns ENABLE ROW LEVEL SECURITY;
CREATE POLICY pharmacy_returns_tenant ON pharmacy_returns
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_pharmacy_returns_updated_at
    BEFORE UPDATE ON pharmacy_returns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_pharmacy_returns_tenant_status
    ON pharmacy_returns (tenant_id, status);

-- ════════════════════════════════════════════════════════
--  NEW TABLE: pharmacy_store_assignments
-- ════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pharmacy_store_assignments (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    store_location_id UUID NOT NULL REFERENCES store_locations(id) UNIQUE,
    is_central        BOOLEAN NOT NULL DEFAULT false,
    serves_departments UUID[],
    operating_hours   JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pharmacy_store_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY pharmacy_store_assignments_tenant ON pharmacy_store_assignments
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_pharmacy_store_assignments_updated_at
    BEFORE UPDATE ON pharmacy_store_assignments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_pharmacy_store_assignments_tenant
    ON pharmacy_store_assignments (tenant_id);

-- ════════════════════════════════════════════════════════
--  NEW TABLE: pharmacy_transfer_requests
-- ════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS pharmacy_transfer_requests (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id),
    from_location_id UUID NOT NULL REFERENCES store_locations(id),
    to_location_id   UUID NOT NULL REFERENCES store_locations(id),
    status           TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'transferred', 'cancelled')),
    items            JSONB NOT NULL DEFAULT '[]',
    requested_by     UUID NOT NULL REFERENCES users(id),
    approved_by      UUID REFERENCES users(id),
    notes            TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pharmacy_transfer_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY pharmacy_transfer_requests_tenant ON pharmacy_transfer_requests
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE TRIGGER trg_pharmacy_transfer_requests_updated_at
    BEFORE UPDATE ON pharmacy_transfer_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_pharmacy_transfer_requests_tenant_status
    ON pharmacy_transfer_requests (tenant_id, status);

-- ════════════════════════════════════════════════════════
--  ADDITIONAL INDEXES on pharmacy_orders
-- ════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_dispensing_type
    ON pharmacy_orders (tenant_id, dispensing_type);
CREATE INDEX IF NOT EXISTS idx_pharmacy_orders_store_location
    ON pharmacy_orders (tenant_id, store_location_id);
CREATE INDEX IF NOT EXISTS idx_pharmacy_order_items_batch_stock
    ON pharmacy_order_items (batch_stock_id);
