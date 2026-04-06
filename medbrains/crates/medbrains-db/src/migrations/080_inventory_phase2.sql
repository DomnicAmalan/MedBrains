-- Migration 080: Inventory Phase 2
-- Analytics, patient consumables, implant registry, condemnations,
-- supplier payments, reorder alerts, enhanced catalog/PO/batch fields

-- ══════════════════════════════════════════════════════════
--  New enums
-- ══════════════════════════════════════════════════════════

CREATE TYPE ved_class AS ENUM ('vital', 'essential', 'desirable');
CREATE TYPE condemnation_status AS ENUM ('initiated', 'committee_review', 'approved', 'condemned', 'rejected');
CREATE TYPE supplier_payment_status AS ENUM ('pending', 'partially_paid', 'paid', 'overdue', 'disputed');
CREATE TYPE consumable_issue_status AS ENUM ('issued', 'returned', 'billed');

-- ══════════════════════════════════════════════════════════
--  ALTER existing tables
-- ══════════════════════════════════════════════════════════

-- store_catalog: analytics + tracking columns
ALTER TABLE store_catalog
    ADD COLUMN IF NOT EXISTS is_implant BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS is_high_value BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS ved_class ved_class,
    ADD COLUMN IF NOT EXISTS hsn_code TEXT,
    ADD COLUMN IF NOT EXISTS bin_location TEXT,
    ADD COLUMN IF NOT EXISTS last_issue_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_receipt_date TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS min_stock INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS max_stock INTEGER NOT NULL DEFAULT 0;

-- store_stock_movements: department/location/patient context
ALTER TABLE store_stock_movements
    ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id),
    ADD COLUMN IF NOT EXISTS store_location_id UUID REFERENCES store_locations(id),
    ADD COLUMN IF NOT EXISTS batch_stock_id UUID REFERENCES batch_stock(id),
    ADD COLUMN IF NOT EXISTS patient_id UUID REFERENCES patients(id);

CREATE INDEX IF NOT EXISTS idx_stock_movements_department ON store_stock_movements(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_stock_movements_patient ON store_stock_movements(patient_id) WHERE patient_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON store_stock_movements(created_at);
CREATE INDEX IF NOT EXISTS idx_stock_movements_location ON store_stock_movements(store_location_id) WHERE store_location_id IS NOT NULL;

-- purchase_orders: emergency flag
ALTER TABLE purchase_orders
    ADD COLUMN IF NOT EXISTS is_emergency BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS emergency_reason TEXT;

-- batch_stock: serial number tracking
ALTER TABLE batch_stock
    ADD COLUMN IF NOT EXISTS serial_number TEXT,
    ADD COLUMN IF NOT EXISTS barcode TEXT;

-- ══════════════════════════════════════════════════════════
--  New tables
-- ══════════════════════════════════════════════════════════

-- Patient consumable issues (patient-level item tracking + billing)
CREATE TABLE IF NOT EXISTS patient_consumable_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    patient_id UUID NOT NULL REFERENCES patients(id),
    catalog_item_id UUID NOT NULL REFERENCES store_catalog(id),
    batch_stock_id UUID REFERENCES batch_stock(id),
    department_id UUID REFERENCES departments(id),
    encounter_id UUID,
    admission_id UUID,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    returned_qty INTEGER NOT NULL DEFAULT 0,
    unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    status consumable_issue_status NOT NULL DEFAULT 'issued',
    is_chargeable BOOLEAN NOT NULL DEFAULT TRUE,
    invoice_item_id UUID,
    issued_by UUID NOT NULL REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE patient_consumable_issues ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON patient_consumable_issues
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_consumable_issues_patient ON patient_consumable_issues(patient_id);
CREATE INDEX idx_consumable_issues_tenant ON patient_consumable_issues(tenant_id);

CREATE TRIGGER trg_patient_consumable_issues_updated_at
    BEFORE UPDATE ON patient_consumable_issues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Implant registry (implant-to-patient linkage)
CREATE TABLE IF NOT EXISTS implant_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES store_catalog(id),
    batch_stock_id UUID REFERENCES batch_stock(id),
    patient_id UUID NOT NULL REFERENCES patients(id),
    serial_number TEXT,
    implant_date DATE NOT NULL,
    implant_site TEXT,
    surgeon_id UUID REFERENCES users(id),
    manufacturer TEXT,
    model_number TEXT,
    warranty_expiry DATE,
    removal_date DATE,
    removal_reason TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE implant_registry ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON implant_registry
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_implant_registry_patient ON implant_registry(patient_id);
CREATE INDEX idx_implant_registry_tenant ON implant_registry(tenant_id);

CREATE TRIGGER trg_implant_registry_updated_at
    BEFORE UPDATE ON implant_registry
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Equipment condemnations (condemnation workflow)
CREATE TABLE IF NOT EXISTS equipment_condemnations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES store_catalog(id),
    condemnation_number TEXT NOT NULL,
    status condemnation_status NOT NULL DEFAULT 'initiated',
    reason TEXT NOT NULL,
    current_value NUMERIC(12,2) NOT NULL DEFAULT 0,
    purchase_value NUMERIC(12,2) NOT NULL DEFAULT 0,
    committee_remarks TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    disposal_method TEXT,
    disposed_at TIMESTAMPTZ,
    initiated_by UUID NOT NULL REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE equipment_condemnations ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON equipment_condemnations
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_condemnations_tenant ON equipment_condemnations(tenant_id);
CREATE INDEX idx_condemnations_status ON equipment_condemnations(status);

CREATE TRIGGER trg_equipment_condemnations_updated_at
    BEFORE UPDATE ON equipment_condemnations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Supplier payments (vendor payment tracking)
CREATE TABLE IF NOT EXISTS supplier_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    vendor_id UUID NOT NULL REFERENCES vendors(id),
    po_id UUID REFERENCES purchase_orders(id),
    grn_id UUID REFERENCES goods_receipt_notes(id),
    payment_number TEXT NOT NULL,
    invoice_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    paid_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    balance_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    status supplier_payment_status NOT NULL DEFAULT 'pending',
    payment_date DATE,
    due_date DATE,
    payment_method TEXT,
    reference_number TEXT,
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE supplier_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON supplier_payments
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_supplier_payments_vendor ON supplier_payments(vendor_id);
CREATE INDEX idx_supplier_payments_tenant ON supplier_payments(tenant_id);
CREATE INDEX idx_supplier_payments_status ON supplier_payments(status);

CREATE TRIGGER trg_supplier_payments_updated_at
    BEFORE UPDATE ON supplier_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Reorder alerts
CREATE TABLE IF NOT EXISTS reorder_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    catalog_item_id UUID NOT NULL REFERENCES store_catalog(id),
    alert_type TEXT NOT NULL DEFAULT 'below_reorder',
    current_stock INTEGER NOT NULL DEFAULT 0,
    threshold_level INTEGER NOT NULL DEFAULT 0,
    is_acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE reorder_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON reorder_alerts
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

CREATE INDEX idx_reorder_alerts_tenant ON reorder_alerts(tenant_id);
CREATE INDEX idx_reorder_alerts_item ON reorder_alerts(catalog_item_id);
CREATE INDEX idx_reorder_alerts_unack ON reorder_alerts(is_acknowledged) WHERE is_acknowledged = FALSE;

CREATE TRIGGER trg_reorder_alerts_updated_at
    BEFORE UPDATE ON reorder_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
