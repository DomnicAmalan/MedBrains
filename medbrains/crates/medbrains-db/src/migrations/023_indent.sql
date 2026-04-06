-- 023_indent.sql — Store Catalog, Indent Requisitions, Items & Stock Movements

-- ── Store Catalog ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS store_catalog (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    category        TEXT,
    sub_category    TEXT,
    unit            TEXT NOT NULL DEFAULT 'unit',
    base_price      NUMERIC(12,2) NOT NULL DEFAULT 0,
    current_stock   INTEGER NOT NULL DEFAULT 0,
    reorder_level   INTEGER NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

ALTER TABLE store_catalog ENABLE ROW LEVEL SECURITY;
CREATE POLICY store_catalog_tenant ON store_catalog
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_store_catalog_tenant ON store_catalog(tenant_id);
CREATE INDEX idx_store_catalog_category ON store_catalog(tenant_id, category);
CREATE INDEX idx_store_catalog_active ON store_catalog(tenant_id, is_active) WHERE is_active;

-- ── Indent Requisitions ───────────────────────────────────
CREATE TABLE IF NOT EXISTS indent_requisitions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    indent_number   TEXT NOT NULL,
    department_id   UUID NOT NULL REFERENCES departments(id),
    requested_by    UUID NOT NULL REFERENCES users(id),
    indent_type     TEXT NOT NULL CHECK (indent_type IN (
                        'general', 'pharmacy', 'lab', 'surgical',
                        'housekeeping', 'emergency'
                    )),
    priority        TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN (
                        'normal', 'urgent', 'emergency'
                    )),
    status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
                        'draft', 'submitted', 'approved', 'partially_approved',
                        'rejected', 'issued', 'partially_issued',
                        'closed', 'cancelled'
                    )),
    total_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    context         JSONB NOT NULL DEFAULT '{}',
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, indent_number)
);

ALTER TABLE indent_requisitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY indent_requisitions_tenant ON indent_requisitions
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_indent_req_tenant ON indent_requisitions(tenant_id);
CREATE INDEX idx_indent_req_status ON indent_requisitions(tenant_id, status);
CREATE INDEX idx_indent_req_dept ON indent_requisitions(tenant_id, department_id);
CREATE INDEX idx_indent_req_type ON indent_requisitions(tenant_id, indent_type);
CREATE INDEX idx_indent_req_requested_by ON indent_requisitions(tenant_id, requested_by);

-- ── Indent Items ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS indent_items (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    requisition_id      UUID NOT NULL REFERENCES indent_requisitions(id) ON DELETE CASCADE,
    catalog_item_id     UUID REFERENCES store_catalog(id),
    item_name           TEXT NOT NULL,
    quantity_requested  INTEGER NOT NULL CHECK (quantity_requested > 0),
    quantity_approved   INTEGER NOT NULL DEFAULT 0,
    quantity_issued     INTEGER NOT NULL DEFAULT 0,
    unit_price          NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_price         NUMERIC(12,2) NOT NULL DEFAULT 0,
    item_context        JSONB NOT NULL DEFAULT '{}',
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE indent_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY indent_items_tenant ON indent_items
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_indent_items_req ON indent_items(requisition_id);
CREATE INDEX idx_indent_items_catalog ON indent_items(catalog_item_id) WHERE catalog_item_id IS NOT NULL;

-- ── Store Stock Movements (Ledger) ────────────────────────
CREATE TABLE IF NOT EXISTS store_stock_movements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES store_catalog(id),
    movement_type   TEXT NOT NULL CHECK (movement_type IN (
                        'receipt', 'issue', 'return', 'adjustment', 'transfer'
                    )),
    quantity        INTEGER NOT NULL,
    reference_type  TEXT,
    reference_id    UUID,
    notes           TEXT,
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE store_stock_movements ENABLE ROW LEVEL SECURITY;
CREATE POLICY store_stock_movements_tenant ON store_stock_movements
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_stock_movements_tenant ON store_stock_movements(tenant_id);
CREATE INDEX idx_stock_movements_item ON store_stock_movements(catalog_item_id);
CREATE INDEX idx_stock_movements_ref ON store_stock_movements(reference_type, reference_id)
    WHERE reference_id IS NOT NULL;
