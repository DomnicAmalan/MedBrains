use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text")]
#[serde(rename_all = "snake_case")]
pub enum PipelineStatus {
    #[sqlx(rename = "draft")]
    Draft,
    #[sqlx(rename = "active")]
    Active,
    #[sqlx(rename = "paused")]
    Paused,
    #[sqlx(rename = "archived")]
    Archived,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text")]
#[serde(rename_all = "snake_case")]
pub enum ExecutionStatus {
    #[sqlx(rename = "pending")]
    Pending,
    #[sqlx(rename = "running")]
    Running,
    #[sqlx(rename = "completed")]
    Completed,
    #[sqlx(rename = "failed")]
    Failed,
    #[sqlx(rename = "skipped")]
    Skipped,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text")]
#[serde(rename_all = "snake_case")]
pub enum PipelineTriggerType {
    #[sqlx(rename = "internal_event")]
    InternalEvent,
    #[sqlx(rename = "schedule")]
    Schedule,
    #[sqlx(rename = "webhook")]
    Webhook,
    #[sqlx(rename = "manual")]
    Manual,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text")]
#[serde(rename_all = "snake_case")]
pub enum PipelineNodeType {
    #[sqlx(rename = "trigger")]
    Trigger,
    #[sqlx(rename = "condition")]
    Condition,
    #[sqlx(rename = "action")]
    Action,
    #[sqlx(rename = "transform")]
    Transform,
    #[sqlx(rename = "delay")]
    Delay,
}

// ── Structs ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct IntegrationPipeline {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub code: String,
    pub description: Option<String>,
    pub status: PipelineStatus,
    pub trigger_type: PipelineTriggerType,
    pub trigger_config: serde_json::Value,
    pub nodes: serde_json::Value,
    pub edges: serde_json::Value,
    pub metadata: serde_json::Value,
    pub version: i32,
    pub created_by: Option<Uuid>,
    pub updated_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct PipelineSummary {
    pub id: Uuid,
    pub name: String,
    pub code: String,
    pub description: Option<String>,
    pub status: PipelineStatus,
    pub trigger_type: PipelineTriggerType,
    pub version: i32,
    pub execution_count: Option<i64>,
    pub last_run_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct IntegrationExecution {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub pipeline_id: Uuid,
    pub pipeline_version: i32,
    pub trigger_event: Option<String>,
    pub status: ExecutionStatus,
    pub input_data: serde_json::Value,
    pub output_data: serde_json::Value,
    pub node_results: serde_json::Value,
    pub error: Option<String>,
    pub triggered_by: Option<Uuid>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct IntegrationNodeTemplate {
    pub id: Uuid,
    pub tenant_id: Option<Uuid>,
    pub node_type: PipelineNodeType,
    pub code: String,
    pub name: String,
    pub description: Option<String>,
    pub icon: Option<String>,
    pub color: Option<String>,
    pub category: String,
    pub config_schema: serde_json::Value,
    pub default_config: serde_json::Value,
    pub output_schema: serde_json::Value,
    pub is_system: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── Schema Registry ─────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct ModuleEntitySchema {
    pub id: Uuid,
    pub module_code: String,
    pub entity_code: String,
    pub entity_label: String,
    pub fields: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct EventSchema {
    pub id: Uuid,
    pub event_type: String,
    pub module_code: String,
    pub label: String,
    pub description: Option<String>,
    pub payload_schema: serde_json::Value,
    pub entity_code: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SchemaField {
    pub path: String,
    #[serde(rename = "type")]
    pub field_type: String,
    pub label: String,
    pub description: Option<String>,
}
