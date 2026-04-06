use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Workflow template — configurable blueprint (Layer 3).
/// Defines the step sequence, branching, approvals, SLAs, and auto-actions.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct WorkflowTemplate {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub code: String,
    pub name: String,
    pub version: i32,
    /// Step definitions as JSONB — ordered list of workflow building blocks.
    pub steps: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Running workflow instance — bound to a specific patient/case/transaction.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct WorkflowInstance {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub template_id: Uuid,
    pub patient_id: Option<Uuid>,
    pub status: WorkflowStatus,
    pub current_step: i32,
    /// Runtime state — captured data, actor assignments, timestamps.
    pub state: serde_json::Value,
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
}

/// Audit trail per workflow step — who, when, where, what, how long, SLA met?
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct WorkflowStepLog {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub instance_id: Uuid,
    pub step_index: i32,
    pub step_name: String,
    pub actor_id: Option<Uuid>,
    pub action: String,
    pub data: serde_json::Value,
    pub sla_met: Option<bool>,
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
}

/// Workflow lifecycle status.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "workflow_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum WorkflowStatus {
    Pending,
    InProgress,
    Paused,
    Completed,
    Cancelled,
    Error,
}
