-- MedBrains HMS — Patient Family Links
-- Links patients who are family members, enabling household view,
-- shared demographics, and insurance propagation.

CREATE TABLE IF NOT EXISTS patient_family_links (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    related_patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    relationship    TEXT NOT NULL,       -- father, mother, spouse, child, sibling, guardian, other
    is_primary_contact BOOLEAN NOT NULL DEFAULT false,
    notes           TEXT,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, patient_id, related_patient_id),
    CHECK (patient_id <> related_patient_id)
);

ALTER TABLE patient_family_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_patient_family_links ON patient_family_links
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_patient_family_links_patient ON patient_family_links(tenant_id, patient_id);
CREATE INDEX idx_patient_family_links_related ON patient_family_links(tenant_id, related_patient_id);

CREATE TRIGGER trg_patient_family_links_updated_at BEFORE UPDATE ON patient_family_links
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
