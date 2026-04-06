-- OPD Round 3: Referrals, Procedure Ordering, Duplicate Order Detection
-- Also: patient vitals history view for trend charts

-- ══ Referrals ══════════════════════════════════════════════

CREATE TABLE referrals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID REFERENCES encounters(id),
    from_department_id UUID NOT NULL REFERENCES departments(id),
    to_department_id   UUID NOT NULL REFERENCES departments(id),
    from_doctor_id  UUID REFERENCES users(id),
    to_doctor_id    UUID REFERENCES users(id),
    urgency         TEXT NOT NULL DEFAULT 'routine'
                    CHECK (urgency IN ('routine', 'urgent', 'emergency')),
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'cancelled')),
    reason          TEXT NOT NULL,
    clinical_notes  TEXT,
    response_notes  TEXT,
    responded_at    TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
CREATE POLICY referrals_tenant ON referrals
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_referrals_tenant ON referrals(tenant_id);
CREATE INDEX idx_referrals_patient ON referrals(tenant_id, patient_id);
CREATE INDEX idx_referrals_from_dept ON referrals(tenant_id, from_department_id);
CREATE INDEX idx_referrals_to_dept ON referrals(tenant_id, to_department_id);
CREATE INDEX idx_referrals_status ON referrals(tenant_id, status)
    WHERE status IN ('pending', 'accepted');

CREATE TRIGGER set_updated_at_referrals
    BEFORE UPDATE ON referrals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══ Procedure Catalog ══════════════════════════════════════

CREATE TABLE procedure_catalog (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    description     TEXT,
    department_id   UUID REFERENCES departments(id),
    category        TEXT,
    base_price      NUMERIC(12,2),
    duration_minutes INTEGER,
    requires_consent BOOLEAN NOT NULL DEFAULT false,
    requires_anesthesia BOOLEAN NOT NULL DEFAULT false,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(tenant_id, code)
);

ALTER TABLE procedure_catalog ENABLE ROW LEVEL SECURITY;
CREATE POLICY procedure_catalog_tenant ON procedure_catalog
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_procedure_catalog_tenant ON procedure_catalog(tenant_id);
CREATE INDEX idx_procedure_catalog_active ON procedure_catalog(tenant_id)
    WHERE is_active = true;

CREATE TRIGGER set_updated_at_procedure_catalog
    BEFORE UPDATE ON procedure_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══ Procedure Orders ═══════════════════════════════════════

CREATE TABLE procedure_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    encounter_id    UUID NOT NULL REFERENCES encounters(id),
    procedure_id    UUID NOT NULL REFERENCES procedure_catalog(id),
    ordered_by      UUID NOT NULL REFERENCES users(id),
    performed_by    UUID REFERENCES users(id),
    priority        TEXT NOT NULL DEFAULT 'routine'
                    CHECK (priority IN ('routine', 'urgent', 'stat')),
    status          TEXT NOT NULL DEFAULT 'ordered'
                    CHECK (status IN ('ordered', 'scheduled', 'in_progress', 'completed', 'cancelled')),
    scheduled_date  DATE,
    scheduled_time  TIME,
    notes           TEXT,
    findings        TEXT,
    complications   TEXT,
    completed_at    TIMESTAMPTZ,
    cancelled_at    TIMESTAMPTZ,
    cancel_reason   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE procedure_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY procedure_orders_tenant ON procedure_orders
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_procedure_orders_tenant ON procedure_orders(tenant_id);
CREATE INDEX idx_procedure_orders_patient ON procedure_orders(tenant_id, patient_id);
CREATE INDEX idx_procedure_orders_encounter ON procedure_orders(encounter_id);
CREATE INDEX idx_procedure_orders_status ON procedure_orders(tenant_id, status)
    WHERE status IN ('ordered', 'scheduled', 'in_progress');

CREATE TRIGGER set_updated_at_procedure_orders
    BEFORE UPDATE ON procedure_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══ Seed default procedure catalog ═════════════════════════

INSERT INTO procedure_catalog (tenant_id, code, name, category, base_price, duration_minutes, requires_consent, requires_anesthesia)
SELECT t.id, v.code, v.name, v.category, v.price, v.duration, v.consent, v.anesthesia
FROM tenants t
CROSS JOIN (VALUES
    ('PROC-001', 'Wound Suturing',        'Minor Surgery',    500.00,  30, true,  true),
    ('PROC-002', 'Incision & Drainage',    'Minor Surgery',    800.00,  30, true,  true),
    ('PROC-003', 'ECG Recording',          'Cardiology',       200.00,  15, false, false),
    ('PROC-004', 'Echocardiography',       'Cardiology',      1500.00,  30, false, false),
    ('PROC-005', 'Stress Test (TMT)',      'Cardiology',      2000.00,  45, true,  false),
    ('PROC-006', 'Spirometry / PFT',       'Pulmonology',      800.00,  20, false, false),
    ('PROC-007', 'Nebulization',           'Pulmonology',      150.00,  15, false, false),
    ('PROC-008', 'Dressing Change',        'Wound Care',       300.00,  20, false, false),
    ('PROC-009', 'Plaster Application',    'Orthopedics',      500.00,  30, false, false),
    ('PROC-010', 'Joint Injection',        'Orthopedics',     1000.00,  15, true,  true),
    ('PROC-011', 'Catheterization',        'Urology',          500.00,  15, true,  false),
    ('PROC-012', 'NG Tube Insertion',      'General',          300.00,  10, true,  false),
    ('PROC-013', 'Lumbar Puncture',        'Neurology',       2000.00,  30, true,  true),
    ('PROC-014', 'Skin Biopsy',            'Dermatology',     1500.00,  20, true,  true),
    ('PROC-015', 'Audiometry',             'ENT',              500.00,  20, false, false),
    ('PROC-016', 'Endoscopy (Upper GI)',   'Gastroenterology', 5000.00, 30, true,  true),
    ('PROC-017', 'Colonoscopy',            'Gastroenterology', 7000.00, 45, true,  true),
    ('PROC-018', 'Ultrasonography',        'Radiology',       1000.00,  20, false, false),
    ('PROC-019', 'Eye Fundoscopy',         'Ophthalmology',    300.00,  10, false, false),
    ('PROC-020', 'Visual Acuity Test',     'Ophthalmology',    100.00,  10, false, false)
) AS v(code, name, category, price, duration, consent, anesthesia)
ON CONFLICT (tenant_id, code) DO NOTHING;
