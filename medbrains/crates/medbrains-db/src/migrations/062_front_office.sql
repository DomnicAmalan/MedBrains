-- 062_front_office.sql — Front Office & Reception
-- Visitor management, queue priority rules, display config, enquiry desk

-- ── Enums ──────────────────────────────────────────────────

CREATE TYPE visitor_pass_status AS ENUM ('active', 'expired', 'revoked');

CREATE TYPE visitor_category AS ENUM (
    'general', 'legal_counsel', 'religious', 'vip',
    'media', 'vendor', 'emergency'
);

CREATE TYPE queue_priority AS ENUM (
    'normal', 'elderly', 'disabled', 'pregnant',
    'emergency_referral', 'vip'
);

-- ── Tables ─────────────────────────────────────────────────

-- 1. Visiting hours per ward (NULL ward_id = hospital-wide default)
CREATE TABLE visiting_hours (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    ward_id     UUID REFERENCES locations(id),
    day_of_week INT  NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time  TIME NOT NULL,
    end_time    TIME NOT NULL,
    max_visitors_per_patient INT NOT NULL DEFAULT 2,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE visiting_hours ENABLE ROW LEVEL SECURITY;
CREATE POLICY visiting_hours_tenant ON visiting_hours
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_visiting_hours_tenant ON visiting_hours(tenant_id);
CREATE TRIGGER trg_visiting_hours_updated_at BEFORE UPDATE ON visiting_hours
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. Visitor registrations
CREATE TABLE visitor_registrations (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    visitor_name  TEXT NOT NULL,
    phone         TEXT,
    id_type       TEXT,
    id_number     TEXT,
    photo_url     TEXT,
    relationship  TEXT,
    category      visitor_category NOT NULL DEFAULT 'general',
    patient_id    UUID REFERENCES patients(id),
    ward_id       UUID REFERENCES locations(id),
    purpose       TEXT,
    created_by    UUID REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE visitor_registrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY visitor_registrations_tenant ON visitor_registrations
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_visitor_registrations_tenant ON visitor_registrations(tenant_id);
CREATE INDEX idx_visitor_registrations_patient ON visitor_registrations(patient_id);
CREATE TRIGGER trg_visitor_registrations_updated_at BEFORE UPDATE ON visitor_registrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. Visitor passes (time-limited, ward-specific, QR code)
CREATE TABLE visitor_passes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    registration_id UUID NOT NULL REFERENCES visitor_registrations(id),
    pass_number     TEXT NOT NULL,
    ward_id         UUID REFERENCES locations(id),
    bed_number      TEXT,
    valid_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until     TIMESTAMPTZ NOT NULL,
    status          visitor_pass_status NOT NULL DEFAULT 'active',
    qr_code         TEXT,
    issued_by       UUID REFERENCES users(id),
    revoked_at      TIMESTAMPTZ,
    revoked_reason  TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE visitor_passes ENABLE ROW LEVEL SECURITY;
CREATE POLICY visitor_passes_tenant ON visitor_passes
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_visitor_passes_tenant ON visitor_passes(tenant_id);
CREATE INDEX idx_visitor_passes_registration ON visitor_passes(registration_id);
CREATE INDEX idx_visitor_passes_status ON visitor_passes(status);
CREATE TRIGGER trg_visitor_passes_updated_at BEFORE UPDATE ON visitor_passes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. Visitor logs (actual entry/exit tracking)
CREATE TABLE visitor_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID NOT NULL REFERENCES tenants(id),
    pass_id      UUID NOT NULL REFERENCES visitor_passes(id),
    check_in_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    check_out_at TIMESTAMPTZ,
    logged_by    UUID REFERENCES users(id),
    gate         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE visitor_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY visitor_logs_tenant ON visitor_logs
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_visitor_logs_tenant ON visitor_logs(tenant_id);
CREATE INDEX idx_visitor_logs_pass ON visitor_logs(pass_id);
CREATE TRIGGER trg_visitor_logs_updated_at BEFORE UPDATE ON visitor_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 5. Queue priority rules
CREATE TABLE queue_priority_rules (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES tenants(id),
    department_id         UUID REFERENCES departments(id),
    priority              queue_priority NOT NULL,
    weight                INT NOT NULL DEFAULT 1,
    auto_detect_criteria  JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active             BOOLEAN NOT NULL DEFAULT true,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE queue_priority_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY queue_priority_rules_tenant ON queue_priority_rules
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_queue_priority_rules_tenant ON queue_priority_rules(tenant_id);
CREATE TRIGGER trg_queue_priority_rules_updated_at BEFORE UPDATE ON queue_priority_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 6. Queue display config
CREATE TABLE queue_display_config (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES tenants(id),
    department_id         UUID REFERENCES departments(id),
    location_name         TEXT NOT NULL,
    display_type          TEXT NOT NULL DEFAULT 'waiting_area',
    doctors_per_screen    INT NOT NULL DEFAULT 4,
    show_patient_name     BOOLEAN NOT NULL DEFAULT false,
    show_wait_time        BOOLEAN NOT NULL DEFAULT true,
    language              JSONB NOT NULL DEFAULT '["en"]'::jsonb,
    announcement_enabled  BOOLEAN NOT NULL DEFAULT false,
    scroll_speed          INT NOT NULL DEFAULT 3,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE queue_display_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY queue_display_config_tenant ON queue_display_config
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_queue_display_config_tenant ON queue_display_config(tenant_id);
CREATE TRIGGER trg_queue_display_config_updated_at BEFORE UPDATE ON queue_display_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 7. Enquiry logs
CREATE TABLE enquiry_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id    UUID NOT NULL REFERENCES tenants(id),
    caller_name  TEXT,
    caller_phone TEXT,
    enquiry_type TEXT NOT NULL DEFAULT 'general',
    patient_id   UUID REFERENCES patients(id),
    response_text TEXT,
    handled_by   UUID REFERENCES users(id),
    resolved     BOOLEAN NOT NULL DEFAULT false,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE enquiry_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY enquiry_logs_tenant ON enquiry_logs
    USING (tenant_id::text = current_setting('app.tenant_id', true));
CREATE INDEX idx_enquiry_logs_tenant ON enquiry_logs(tenant_id);
CREATE TRIGGER trg_enquiry_logs_updated_at BEFORE UPDATE ON enquiry_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
