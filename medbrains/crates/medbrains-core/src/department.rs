use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Department in the hospital hierarchy. Supports unlimited nesting.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Department {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub department_type: DepartmentType,
    /// OPD/IPD config, fee structure, NMC requirements as JSONB.
    pub config: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Department classification determines which modules are relevant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "department_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DepartmentType {
    Clinical,
    PreClinical,
    ParaClinical,
    Administrative,
    Support,
    Academic,
}

/// Service catalog entry — every clinical/non-clinical service is configurable.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Service {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub department_id: Uuid,
    pub code: String,
    pub name: String,
    pub service_type: ServiceType,
    /// Prerequisites, resource requirements, billing config as JSONB.
    pub config: serde_json::Value,
    /// Links to `workflow_templates.id` — triggered when service is ordered.
    pub workflow_template_id: Option<Uuid>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Service classification per RFC Section 3.3.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "service_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum ServiceType {
    Consultation,
    Procedure,
    Investigation,
    Surgery,
    Therapy,
    Nursing,
    Support,
    Administrative,
}
