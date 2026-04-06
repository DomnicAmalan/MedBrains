-- 067_security.sql — Security Department module
-- Physical access control, CCTV, incidents, patient safety tags, code debriefs

-- ══════════════════════════════════════════════════════════
--  ENUMS
-- ══════════════════════════════════════════════════════════

CREATE TYPE sec_access_method AS ENUM ('card', 'biometric', 'pin', 'manual');
CREATE TYPE sec_zone_level AS ENUM ('public', 'general', 'restricted', 'high_security', 'critical');
CREATE TYPE sec_incident_severity AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE sec_incident_status AS ENUM ('reported', 'investigating', 'resolved', 'closed');
CREATE TYPE sec_patient_tag_type AS ENUM ('infant_rfid', 'wander_guard', 'elopement_risk');
CREATE TYPE sec_tag_alert_status AS ENUM ('active', 'alert_triggered', 'resolved', 'deactivated');

-- ══════════════════════════════════════════════════════════
--  TABLES
-- ══════════════════════════════════════════════════════════

-- 1. Security Zones
CREATE TABLE security_zones (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id),
    name        TEXT NOT NULL,
    zone_code   TEXT NOT NULL,
    level       sec_zone_level NOT NULL DEFAULT 'general',
    department_id UUID REFERENCES departments(id),
    description TEXT,
    allowed_methods JSONB DEFAULT '["card","biometric","pin","manual"]'::jsonb,
    after_hours_restricted BOOLEAN NOT NULL DEFAULT false,
    after_hours_start TEXT,
    after_hours_end   TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, zone_code)
);

ALTER TABLE security_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_zones_tenant ON security_zones
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_zones_tenant ON security_zones(tenant_id);
CREATE TRIGGER trg_security_zones_updated_at
    BEFORE UPDATE ON security_zones FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. Security Access Logs
CREATE TABLE security_access_logs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    zone_id       UUID NOT NULL REFERENCES security_zones(id),
    employee_id   UUID REFERENCES employees(id),
    person_name   TEXT,
    access_method sec_access_method NOT NULL DEFAULT 'manual',
    card_number   TEXT,
    direction     TEXT NOT NULL DEFAULT 'entry',
    granted       BOOLEAN NOT NULL DEFAULT true,
    denied_reason TEXT,
    is_after_hours BOOLEAN NOT NULL DEFAULT false,
    accessed_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    device_id     TEXT,
    recorded_by   UUID REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE security_access_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_access_logs_tenant ON security_access_logs
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_access_logs_tenant ON security_access_logs(tenant_id);
CREATE INDEX idx_security_access_logs_zone ON security_access_logs(zone_id);
CREATE INDEX idx_security_access_logs_employee ON security_access_logs(employee_id);
CREATE INDEX idx_security_access_logs_accessed ON security_access_logs(accessed_at DESC);
CREATE TRIGGER trg_security_access_logs_updated_at
    BEFORE UPDATE ON security_access_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. Security Access Cards
CREATE TABLE security_access_cards (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    employee_id         UUID NOT NULL REFERENCES employees(id),
    card_number         TEXT NOT NULL,
    card_type           TEXT DEFAULT 'standard',
    issued_date         DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date         DATE,
    allowed_zones       JSONB DEFAULT '[]'::jsonb,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    deactivated_at      TIMESTAMPTZ,
    deactivation_reason TEXT,
    issued_by           UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, card_number)
);

ALTER TABLE security_access_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_access_cards_tenant ON security_access_cards
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_access_cards_tenant ON security_access_cards(tenant_id);
CREATE INDEX idx_security_access_cards_employee ON security_access_cards(employee_id);
CREATE TRIGGER trg_security_access_cards_updated_at
    BEFORE UPDATE ON security_access_cards FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. Security Cameras
CREATE TABLE security_cameras (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id            UUID NOT NULL REFERENCES tenants(id),
    name                 TEXT NOT NULL,
    camera_id            TEXT,
    zone_id              UUID REFERENCES security_zones(id),
    location_description TEXT,
    camera_type          TEXT DEFAULT 'dome',
    resolution           TEXT,
    is_recording         BOOLEAN NOT NULL DEFAULT true,
    retention_days       INT NOT NULL DEFAULT 30,
    ip_address           TEXT,
    is_active            BOOLEAN NOT NULL DEFAULT true,
    last_checked_at      TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE security_cameras ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_cameras_tenant ON security_cameras
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_cameras_tenant ON security_cameras(tenant_id);
CREATE INDEX idx_security_cameras_zone ON security_cameras(zone_id);
CREATE TRIGGER trg_security_cameras_updated_at
    BEFORE UPDATE ON security_cameras FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 5. Security Incidents
CREATE TABLE security_incidents (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID NOT NULL REFERENCES tenants(id),
    incident_number        TEXT NOT NULL,
    severity               sec_incident_severity NOT NULL DEFAULT 'medium',
    status                 sec_incident_status NOT NULL DEFAULT 'reported',
    category               TEXT NOT NULL DEFAULT 'other',
    zone_id                UUID REFERENCES security_zones(id),
    location_description   TEXT,
    occurred_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    description            TEXT NOT NULL,
    persons_involved       JSONB DEFAULT '[]'::jsonb,
    witnesses              JSONB DEFAULT '[]'::jsonb,
    camera_ids             JSONB DEFAULT '[]'::jsonb,
    video_timestamp_start  TEXT,
    video_timestamp_end    TEXT,
    police_notified        BOOLEAN NOT NULL DEFAULT false,
    police_report_number   TEXT,
    investigation_notes    TEXT,
    resolution             TEXT,
    resolved_at            TIMESTAMPTZ,
    resolved_by            UUID REFERENCES users(id),
    reported_by            UUID REFERENCES users(id),
    assigned_to            UUID REFERENCES users(id),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, incident_number)
);

ALTER TABLE security_incidents ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_incidents_tenant ON security_incidents
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_incidents_tenant ON security_incidents(tenant_id);
CREATE INDEX idx_security_incidents_status ON security_incidents(status);
CREATE INDEX idx_security_incidents_severity ON security_incidents(severity);
CREATE INDEX idx_security_incidents_occurred ON security_incidents(occurred_at DESC);
CREATE TRIGGER trg_security_incidents_updated_at
    BEFORE UPDATE ON security_incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 6. Security Patient Tags
CREATE TABLE security_patient_tags (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    tag_type        sec_patient_tag_type NOT NULL,
    tag_identifier  TEXT,
    allowed_zone_id UUID REFERENCES security_zones(id),
    alert_status    sec_tag_alert_status NOT NULL DEFAULT 'active',
    mother_id       UUID REFERENCES patients(id),
    admission_id    UUID,
    activated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    deactivated_at  TIMESTAMPTZ,
    activated_by    UUID REFERENCES users(id),
    deactivated_by  UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE security_patient_tags ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_patient_tags_tenant ON security_patient_tags
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_patient_tags_tenant ON security_patient_tags(tenant_id);
CREATE INDEX idx_security_patient_tags_patient ON security_patient_tags(patient_id);
CREATE INDEX idx_security_patient_tags_status ON security_patient_tags(alert_status);
CREATE TRIGGER trg_security_patient_tags_updated_at
    BEFORE UPDATE ON security_patient_tags FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 7. Security Tag Alerts
CREATE TABLE security_tag_alerts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    tag_id              UUID NOT NULL REFERENCES security_patient_tags(id),
    alert_type          TEXT NOT NULL DEFAULT 'zone_breach',
    triggered_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    zone_id             UUID REFERENCES security_zones(id),
    location_description TEXT,
    is_resolved         BOOLEAN NOT NULL DEFAULT false,
    resolved_at         TIMESTAMPTZ,
    resolved_by         UUID REFERENCES users(id),
    was_false_alarm     BOOLEAN NOT NULL DEFAULT false,
    resolution_notes    TEXT,
    code_activation_id  UUID REFERENCES er_code_activations(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE security_tag_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_tag_alerts_tenant ON security_tag_alerts
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_tag_alerts_tenant ON security_tag_alerts(tenant_id);
CREATE INDEX idx_security_tag_alerts_tag ON security_tag_alerts(tag_id);
CREATE INDEX idx_security_tag_alerts_resolved ON security_tag_alerts(is_resolved);
CREATE TRIGGER trg_security_tag_alerts_updated_at
    BEFORE UPDATE ON security_tag_alerts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 8. Security Code Debriefs
CREATE TABLE security_code_debriefs (
    id                           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                    UUID NOT NULL REFERENCES tenants(id),
    code_activation_id           UUID NOT NULL REFERENCES er_code_activations(id),
    debrief_date                 DATE NOT NULL DEFAULT CURRENT_DATE,
    facilitator_id               UUID REFERENCES users(id),
    attendees                    JSONB DEFAULT '[]'::jsonb,
    response_time_seconds        INT,
    total_duration_minutes       INT,
    what_went_well               TEXT,
    what_went_wrong              TEXT,
    root_cause                   TEXT,
    lessons_learned              TEXT,
    action_items                 JSONB DEFAULT '[]'::jsonb,
    equipment_issues             TEXT,
    training_gaps                TEXT,
    protocol_changes_recommended TEXT,
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE security_code_debriefs ENABLE ROW LEVEL SECURITY;
CREATE POLICY security_code_debriefs_tenant ON security_code_debriefs
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);
CREATE INDEX idx_security_code_debriefs_tenant ON security_code_debriefs(tenant_id);
CREATE INDEX idx_security_code_debriefs_code ON security_code_debriefs(code_activation_id);
CREATE TRIGGER trg_security_code_debriefs_updated_at
    BEFORE UPDATE ON security_code_debriefs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
