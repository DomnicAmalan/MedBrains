-- 024_integration_hub.sql — Integration Hub: Pipelines, Executions & Node Templates

-- ── Integration Node Templates (catalog) ────────────────
CREATE TABLE IF NOT EXISTS integration_node_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID REFERENCES tenants(id),  -- NULL = global/system
    node_type       TEXT NOT NULL CHECK (node_type IN (
                        'trigger', 'condition', 'action', 'transform', 'delay'
                    )),
    code            TEXT NOT NULL,
    name            TEXT NOT NULL,
    description     TEXT,
    icon            TEXT,
    color           TEXT,
    category        TEXT NOT NULL,
    config_schema   JSONB NOT NULL DEFAULT '{}',
    default_config  JSONB NOT NULL DEFAULT '{}',
    is_system       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (code)
);

ALTER TABLE integration_node_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY integration_node_templates_tenant ON integration_node_templates
    USING (
        tenant_id IS NULL
        OR tenant_id::text = current_setting('app.tenant_id', true)
    );

CREATE INDEX idx_int_node_tpl_tenant ON integration_node_templates(tenant_id);
CREATE INDEX idx_int_node_tpl_type ON integration_node_templates(node_type);
CREATE INDEX idx_int_node_tpl_category ON integration_node_templates(category);

-- ── Integration Pipelines ───────────────────────────────
CREATE TABLE IF NOT EXISTS integration_pipelines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            TEXT NOT NULL,
    code            TEXT NOT NULL,
    description     TEXT,
    status          TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
                        'draft', 'active', 'paused', 'archived'
                    )),
    trigger_type    TEXT NOT NULL CHECK (trigger_type IN (
                        'internal_event', 'schedule', 'webhook', 'manual'
                    )),
    trigger_config  JSONB NOT NULL DEFAULT '{}',
    nodes           JSONB NOT NULL DEFAULT '[]',
    edges           JSONB NOT NULL DEFAULT '[]',
    metadata        JSONB NOT NULL DEFAULT '{}',
    version         INTEGER NOT NULL DEFAULT 1,
    created_by      UUID REFERENCES users(id),
    updated_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, code)
);

ALTER TABLE integration_pipelines ENABLE ROW LEVEL SECURITY;
CREATE POLICY integration_pipelines_tenant ON integration_pipelines
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_int_pipelines_tenant ON integration_pipelines(tenant_id);
CREATE INDEX idx_int_pipelines_status ON integration_pipelines(tenant_id, status);
CREATE INDEX idx_int_pipelines_trigger ON integration_pipelines(tenant_id, trigger_type);
CREATE INDEX idx_int_pipelines_trigger_config ON integration_pipelines
    USING GIN (trigger_config);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_integration_pipelines_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_integration_pipelines_updated_at
    BEFORE UPDATE ON integration_pipelines
    FOR EACH ROW
    EXECUTE FUNCTION update_integration_pipelines_updated_at();

-- ── Integration Executions ──────────────────────────────
CREATE TABLE IF NOT EXISTS integration_executions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    pipeline_id       UUID NOT NULL REFERENCES integration_pipelines(id) ON DELETE CASCADE,
    pipeline_version  INTEGER NOT NULL DEFAULT 1,
    trigger_event     TEXT,
    status            TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                          'pending', 'running', 'completed', 'failed', 'skipped'
                      )),
    input_data        JSONB NOT NULL DEFAULT '{}',
    output_data       JSONB NOT NULL DEFAULT '{}',
    node_results      JSONB NOT NULL DEFAULT '{}',
    error             TEXT,
    triggered_by      UUID REFERENCES users(id),
    started_at        TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE integration_executions ENABLE ROW LEVEL SECURITY;
CREATE POLICY integration_executions_tenant ON integration_executions
    USING (tenant_id::text = current_setting('app.tenant_id', true));

CREATE INDEX idx_int_exec_tenant ON integration_executions(tenant_id);
CREATE INDEX idx_int_exec_pipeline ON integration_executions(pipeline_id);
CREATE INDEX idx_int_exec_status ON integration_executions(tenant_id, status);
CREATE INDEX idx_int_exec_created ON integration_executions(created_at DESC);

-- ══════════════════════════════════════════════════════════
--  Seed System Node Templates
-- ══════════════════════════════════════════════════════════

INSERT INTO integration_node_templates (tenant_id, node_type, code, name, description, icon, color, category, config_schema, default_config, is_system)
VALUES
-- Triggers
(NULL, 'trigger', 'trigger.internal_event', 'Internal Event', 'Fires when an internal event occurs', 'IconBolt', 'blue', 'Triggers',
 '{"type":"object","properties":{"event_type":{"type":"string","enum":["prescription.created","order.dispensed","stock.low","indent.submitted","indent.approved","patient.registered","encounter.created","lab.completed","admission.created","discharge.completed"],"title":"Event Type"}}}',
 '{"event_type":"prescription.created"}', TRUE),

(NULL, 'trigger', 'trigger.schedule', 'Schedule', 'Runs on a cron schedule', 'IconClock', 'teal', 'Triggers',
 '{"type":"object","properties":{"cron":{"type":"string","title":"Cron Expression","description":"e.g. 0 9 * * MON-FRI"},"timezone":{"type":"string","title":"Timezone","default":"Asia/Kolkata"}}}',
 '{"cron":"0 9 * * MON-FRI","timezone":"Asia/Kolkata"}', TRUE),

(NULL, 'trigger', 'trigger.manual', 'Manual Trigger', 'Triggered manually by a user', 'IconHandClick', 'gray', 'Triggers',
 '{"type":"object","properties":{"description":{"type":"string","title":"Description"}}}',
 '{}', TRUE),

(NULL, 'trigger', 'trigger.webhook', 'Webhook', 'Receives data from an external source', 'IconWebhook', 'violet', 'Triggers',
 '{"type":"object","properties":{"secret":{"type":"string","title":"Webhook Secret"},"method":{"type":"string","enum":["POST","PUT"],"title":"HTTP Method","default":"POST"}}}',
 '{"method":"POST"}', TRUE),

-- Logic / Conditions
(NULL, 'condition', 'condition.if_else', 'If/Else', 'Routes flow based on a condition', 'IconGitBranch', 'orange', 'Logic',
 '{"type":"object","properties":{"field":{"type":"string","title":"Field Path"},"operator":{"type":"string","enum":["eq","neq","gt","lt","gte","lte","contains","is_empty","is_not_empty"],"title":"Operator"},"value":{"type":"string","title":"Compare Value"}}}',
 '{"operator":"eq"}', TRUE),

(NULL, 'condition', 'condition.switch', 'Switch', 'Multi-way branching based on a value', 'IconArrowsSplit', 'orange', 'Logic',
 '{"type":"object","properties":{"field":{"type":"string","title":"Field Path"},"cases":{"type":"array","title":"Cases","items":{"type":"object","properties":{"value":{"type":"string","title":"Case Value"},"label":{"type":"string","title":"Label"}}}}}}',
 '{"cases":[]}', TRUE),

(NULL, 'transform', 'transform.map_data', 'Map Data', 'Transform and reshape data between nodes', 'IconTransform', 'cyan', 'Logic',
 '{"type":"object","properties":{"mappings":{"type":"array","title":"Field Mappings","items":{"type":"object","properties":{"from":{"type":"string","title":"Source Field"},"to":{"type":"string","title":"Target Field"},"transform":{"type":"string","title":"Transform Expression"}}}}}}',
 '{"mappings":[]}', TRUE),

-- Actions
(NULL, 'action', 'action.create_indent', 'Create Indent', 'Creates a new indent requisition', 'IconPackage', 'green', 'Actions',
 '{"type":"object","properties":{"department_id":{"type":"string","title":"Department ID","format":"uuid"},"indent_type":{"type":"string","enum":["general","pharmacy","lab","surgical","housekeeping","emergency"],"title":"Indent Type"},"priority":{"type":"string","enum":["normal","urgent","emergency"],"title":"Priority","default":"normal"},"items_source":{"type":"string","title":"Items Source Field","description":"JSON path to array of items in input data"}}}',
 '{"indent_type":"pharmacy","priority":"normal"}', TRUE),

(NULL, 'action', 'action.create_order', 'Create Order', 'Creates a pharmacy order', 'IconPill', 'green', 'Actions',
 '{"type":"object","properties":{"patient_id_source":{"type":"string","title":"Patient ID Source Field"},"items_source":{"type":"string","title":"Items Source Field"}}}',
 '{}', TRUE),

(NULL, 'action', 'action.send_notification', 'Send Notification', 'Sends a notification to users or channels', 'IconBell', 'yellow', 'Actions',
 '{"type":"object","properties":{"channel":{"type":"string","enum":["in_app","email","sms","webhook"],"title":"Channel","default":"in_app"},"recipient_type":{"type":"string","enum":["user","role","department"],"title":"Recipient Type"},"recipient_id":{"type":"string","title":"Recipient ID"},"title":{"type":"string","title":"Notification Title"},"body":{"type":"string","title":"Notification Body"}}}',
 '{"channel":"in_app"}', TRUE),

(NULL, 'action', 'action.update_record', 'Update Record', 'Updates a record in the system', 'IconPencil', 'green', 'Actions',
 '{"type":"object","properties":{"entity":{"type":"string","enum":["patient","encounter","admission","lab_order","pharmacy_order","indent","invoice"],"title":"Entity Type"},"id_source":{"type":"string","title":"Record ID Source Field"},"updates":{"type":"object","title":"Fields to Update"}}}',
 '{}', TRUE),

(NULL, 'action', 'action.webhook_call', 'Webhook Call', 'Calls an external webhook URL', 'IconSend', 'red', 'Actions',
 '{"type":"object","properties":{"url":{"type":"string","title":"Webhook URL","format":"uri"},"method":{"type":"string","enum":["GET","POST","PUT","PATCH","DELETE"],"title":"HTTP Method","default":"POST"},"headers":{"type":"object","title":"Custom Headers"},"body_template":{"type":"string","title":"Body Template","description":"JSON template with {{field}} placeholders"}}}',
 '{"method":"POST"}', TRUE)

ON CONFLICT (code) DO NOTHING;
