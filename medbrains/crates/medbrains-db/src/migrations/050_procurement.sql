-- Migration 050: Procurement — Vendors, Purchase Orders, GRN, Batch Tracking, Rate Contracts, Store Locations
-- Extends the existing indent/store module with procurement capabilities

-- ── Enums ──────────────────────────────────────────────────────

CREATE TYPE po_status AS ENUM (
    'draft',
    'submitted',
    'approved',
    'sent_to_vendor',
    'partially_received',
    'fully_received',
    'closed',
    'cancelled'
);

CREATE TYPE grn_status AS ENUM (
    'draft',
    'inspecting',
    'accepted',
    'partially_accepted',
    'rejected',
    'completed'
);

CREATE TYPE vendor_status AS ENUM (
    'active',
    'inactive',
    'blacklisted',
    'pending_approval'
);

CREATE TYPE rate_contract_status AS ENUM (
    'draft',
    'active',
    'expired',
    'terminated'
);

-- ── Vendors ────────────────────────────────────────────────────

CREATE TABLE vendors (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    display_name TEXT,
    vendor_type TEXT NOT NULL DEFAULT 'supplier',
    status      vendor_status NOT NULL DEFAULT 'active',
    -- Contact
    contact_person TEXT,
    phone       TEXT,
    email       TEXT,
    website     TEXT,
    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city        TEXT,
    state       TEXT,
    pincode     TEXT,
    country     TEXT DEFAULT 'India',
    -- Tax & Registration
    gst_number  TEXT,
    pan_number  TEXT,
    drug_license_number TEXT,
    fssai_license TEXT,
    -- Bank
    bank_name   TEXT,
    bank_account TEXT,
    bank_ifsc   TEXT,
    -- Terms
    payment_terms TEXT DEFAULT 'net_30',
    credit_limit  NUMERIC(14,2) DEFAULT 0,
    credit_days   INT DEFAULT 30,
    -- Rating
    rating      NUMERIC(3,2) DEFAULT 0,
    -- Metadata
    categories  JSONB DEFAULT '[]'::jsonb,
    notes       TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, code)
);

ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
CREATE POLICY vendors_tenant ON vendors
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_vendors_tenant ON vendors(tenant_id);
CREATE INDEX idx_vendors_status ON vendors(tenant_id, status);

-- ── Store Locations (multi-location stores/warehouses) ─────────

CREATE TABLE store_locations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    code        TEXT NOT NULL,
    name        TEXT NOT NULL,
    location_type TEXT NOT NULL DEFAULT 'main_store',
    department_id UUID REFERENCES departments(id),
    facility_id UUID REFERENCES facilities(id),
    address     TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, code)
);

ALTER TABLE store_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY store_locations_tenant ON store_locations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_store_locations_tenant ON store_locations(tenant_id);

-- ── Purchase Orders ────────────────────────────────────────────

CREATE TABLE purchase_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    po_number       TEXT NOT NULL,
    vendor_id       UUID NOT NULL REFERENCES vendors(id),
    store_location_id UUID REFERENCES store_locations(id),
    status          po_status NOT NULL DEFAULT 'draft',
    -- References
    indent_requisition_id UUID REFERENCES indent_requisitions(id),
    rate_contract_id UUID,
    -- Amounts
    subtotal        NUMERIC(14,2) NOT NULL DEFAULT 0,
    tax_amount      NUMERIC(14,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
    -- Dates
    order_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery DATE,
    -- Terms
    payment_terms   TEXT,
    delivery_terms  TEXT,
    -- Tracking
    created_by      UUID NOT NULL REFERENCES users(id),
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    sent_at         TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, po_number)
);

ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY purchase_orders_tenant ON purchase_orders
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_po_tenant ON purchase_orders(tenant_id);
CREATE INDEX idx_po_vendor ON purchase_orders(tenant_id, vendor_id);
CREATE INDEX idx_po_status ON purchase_orders(tenant_id, status);

-- ── Purchase Order Items ───────────────────────────────────────

CREATE TABLE purchase_order_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    po_id           UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    catalog_item_id UUID REFERENCES store_catalog(id),
    item_name       TEXT NOT NULL,
    item_code       TEXT,
    unit            TEXT NOT NULL DEFAULT 'unit',
    quantity_ordered INT NOT NULL,
    quantity_received INT NOT NULL DEFAULT 0,
    unit_price      NUMERIC(14,2) NOT NULL DEFAULT 0,
    tax_percent     NUMERIC(5,2) NOT NULL DEFAULT 0,
    tax_amount      NUMERIC(14,2) NOT NULL DEFAULT 0,
    discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
    indent_item_id  UUID REFERENCES indent_items(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY po_items_tenant ON purchase_order_items
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_po_items_po ON purchase_order_items(po_id);

-- ── Goods Receipt Notes ────────────────────────────────────────

CREATE TABLE goods_receipt_notes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    grn_number      TEXT NOT NULL,
    po_id           UUID NOT NULL REFERENCES purchase_orders(id),
    vendor_id       UUID NOT NULL REFERENCES vendors(id),
    store_location_id UUID REFERENCES store_locations(id),
    status          grn_status NOT NULL DEFAULT 'draft',
    -- Amounts
    total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
    -- Dates
    receipt_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    invoice_number  TEXT,
    invoice_date    DATE,
    invoice_amount  NUMERIC(14,2),
    -- Tracking
    received_by     UUID NOT NULL REFERENCES users(id),
    inspected_by    UUID REFERENCES users(id),
    inspected_at    TIMESTAMPTZ,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, grn_number)
);

ALTER TABLE goods_receipt_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY grn_tenant ON goods_receipt_notes
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_grn_tenant ON goods_receipt_notes(tenant_id);
CREATE INDEX idx_grn_po ON goods_receipt_notes(po_id);
CREATE INDEX idx_grn_status ON goods_receipt_notes(tenant_id, status);

-- ── GRN Items ──────────────────────────────────────────────────

CREATE TABLE grn_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    grn_id          UUID NOT NULL REFERENCES goods_receipt_notes(id) ON DELETE CASCADE,
    po_item_id      UUID REFERENCES purchase_order_items(id),
    catalog_item_id UUID REFERENCES store_catalog(id),
    item_name       TEXT NOT NULL,
    -- Quantities
    quantity_received INT NOT NULL,
    quantity_accepted INT NOT NULL DEFAULT 0,
    quantity_rejected INT NOT NULL DEFAULT 0,
    -- Batch tracking
    batch_number    TEXT,
    expiry_date     DATE,
    manufacture_date DATE,
    -- Pricing
    unit_price      NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
    -- Quality
    rejection_reason TEXT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE grn_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY grn_items_tenant ON grn_items
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_grn_items_grn ON grn_items(grn_id);

-- ── Batch Stock (batch-level inventory with expiry tracking) ───

CREATE TABLE batch_stock (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES store_catalog(id),
    store_location_id UUID REFERENCES store_locations(id),
    batch_number    TEXT NOT NULL,
    expiry_date     DATE,
    manufacture_date DATE,
    quantity        INT NOT NULL DEFAULT 0,
    unit_cost       NUMERIC(14,2) NOT NULL DEFAULT 0,
    grn_id          UUID REFERENCES goods_receipt_notes(id),
    vendor_id       UUID REFERENCES vendors(id),
    is_consignment  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE batch_stock ENABLE ROW LEVEL SECURITY;
CREATE POLICY batch_stock_tenant ON batch_stock
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_batch_stock_item ON batch_stock(tenant_id, catalog_item_id);
CREATE INDEX idx_batch_stock_expiry ON batch_stock(tenant_id, expiry_date) WHERE quantity > 0;
CREATE INDEX idx_batch_stock_location ON batch_stock(tenant_id, store_location_id);

-- ── Rate Contracts ─────────────────────────────────────────────

CREATE TABLE rate_contracts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    contract_number TEXT NOT NULL,
    vendor_id       UUID NOT NULL REFERENCES vendors(id),
    status          rate_contract_status NOT NULL DEFAULT 'draft',
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    payment_terms   TEXT,
    notes           TEXT,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, contract_number)
);

ALTER TABLE rate_contracts ENABLE ROW LEVEL SECURITY;
CREATE POLICY rate_contracts_tenant ON rate_contracts
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_rc_tenant ON rate_contracts(tenant_id);
CREATE INDEX idx_rc_vendor ON rate_contracts(tenant_id, vendor_id);
CREATE INDEX idx_rc_active ON rate_contracts(tenant_id, status, end_date);

-- ── Rate Contract Items ────────────────────────────────────────

CREATE TABLE rate_contract_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    contract_id     UUID NOT NULL REFERENCES rate_contracts(id) ON DELETE CASCADE,
    catalog_item_id UUID NOT NULL REFERENCES store_catalog(id),
    contracted_price NUMERIC(14,2) NOT NULL,
    max_quantity    INT,
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE rate_contract_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY rc_items_tenant ON rate_contract_items
    USING (tenant_id = current_setting('app.tenant_id')::uuid);
CREATE INDEX idx_rc_items_contract ON rate_contract_items(contract_id);

-- ── Deferred FK for rate_contract_id on purchase_orders ────────
ALTER TABLE purchase_orders
    ADD CONSTRAINT fk_po_rate_contract
    FOREIGN KEY (rate_contract_id) REFERENCES rate_contracts(id);

-- ── Triggers ───────────────────────────────────────────────────

CREATE TRIGGER set_vendors_updated_at BEFORE UPDATE ON vendors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_store_locations_updated_at BEFORE UPDATE ON store_locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_purchase_orders_updated_at BEFORE UPDATE ON purchase_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_grn_updated_at BEFORE UPDATE ON goods_receipt_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_batch_stock_updated_at BEFORE UPDATE ON batch_stock
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_rate_contracts_updated_at BEFORE UPDATE ON rate_contracts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
