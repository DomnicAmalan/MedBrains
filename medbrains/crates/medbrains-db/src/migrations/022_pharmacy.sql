-- Pharmacy module tables

CREATE TABLE pharmacy_catalog (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    generic_name    TEXT,
    category        TEXT,
    manufacturer    TEXT,
    unit            TEXT,
    base_price      DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_percent     DECIMAL(5,2) NOT NULL DEFAULT 0,
    current_stock   INT NOT NULL DEFAULT 0,
    reorder_level   INT NOT NULL DEFAULT 10,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, code)
);

CREATE TABLE pharmacy_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    prescription_id UUID REFERENCES prescriptions(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID REFERENCES encounters(id),
    ordered_by      UUID NOT NULL REFERENCES users(id),
    status          TEXT NOT NULL DEFAULT 'ordered'
                    CHECK (status IN ('ordered', 'dispensed', 'cancelled', 'returned')),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE pharmacy_order_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES pharmacy_orders(id) ON DELETE CASCADE,
    catalog_item_id UUID REFERENCES pharmacy_catalog(id),
    drug_name       TEXT NOT NULL,
    quantity        INT NOT NULL DEFAULT 1,
    unit_price      DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_price     DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE pharmacy_stock_transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES pharmacy_catalog(id),
    transaction_type TEXT NOT NULL
                    CHECK (transaction_type IN ('receipt', 'issue', 'return', 'adjustment')),
    quantity        INT NOT NULL,
    reference_id    UUID,
    notes           TEXT,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_pharmacy_catalog_tenant ON pharmacy_catalog(tenant_id);
CREATE INDEX idx_pharmacy_orders_tenant ON pharmacy_orders(tenant_id);
CREATE INDEX idx_pharmacy_orders_patient ON pharmacy_orders(tenant_id, patient_id);
CREATE INDEX idx_pharmacy_orders_status ON pharmacy_orders(tenant_id, status);
CREATE INDEX idx_pharmacy_order_items_order ON pharmacy_order_items(order_id);
CREATE INDEX idx_pharmacy_stock_tx_item ON pharmacy_stock_transactions(catalog_item_id);

-- RLS policies
ALTER TABLE pharmacy_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacy_stock_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY pharmacy_catalog_tenant ON pharmacy_catalog
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY pharmacy_orders_tenant ON pharmacy_orders
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY pharmacy_order_items_tenant ON pharmacy_order_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE POLICY pharmacy_stock_transactions_tenant ON pharmacy_stock_transactions
    USING (tenant_id::text = current_setting('app.tenant_id', true));

-- Updated_at triggers
CREATE TRIGGER set_updated_at_pharmacy_catalog
    BEFORE UPDATE ON pharmacy_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_pharmacy_orders
    BEFORE UPDATE ON pharmacy_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
