use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "scope_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum ScopeStatus {
    Available,
    InUse,
    Reprocessing,
    Quarantine,
    Decommissioned,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "hld_result", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum HldResult {
    Pass,
    Fail,
    Pending,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct EndoscopyScope {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub serial_number: String,
    pub model: String,
    pub scope_type: String,
    pub manufacturer: Option<String>,
    pub status: ScopeStatus,
    pub last_hld_at: Option<DateTime<Utc>>,
    pub total_uses: i32,
    pub last_culture_date: Option<chrono::NaiveDate>,
    pub last_culture_result: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct EndoscopyProcedure {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub scope_id: Option<Uuid>,
    pub procedure_type: String,
    pub operator_id: Uuid,
    pub sedation_type: Option<String>,
    pub sedation_drugs: serde_json::Value,
    pub findings: serde_json::Value,
    pub biopsy_taken: bool,
    pub aldrete_score_pre: Option<i32>,
    pub aldrete_score_post: Option<i32>,
    pub status: String,
    pub scheduled_at: Option<DateTime<Utc>>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct EndoscopyReprocessing {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub scope_id: Uuid,
    pub procedure_id: Option<Uuid>,
    pub leak_test_passed: bool,
    pub hld_chemical: String,
    pub hld_concentration: Option<rust_decimal::Decimal>,
    pub hld_soak_minutes: i32,
    pub hld_temperature: Option<rust_decimal::Decimal>,
    pub hld_result: HldResult,
    pub reprocessed_by: Uuid,
    pub reprocessed_at: DateTime<Utc>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct EndoscopyBiopsySpecimen {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub procedure_id: Uuid,
    pub site: String,
    pub container_label: String,
    pub fixative: Option<String>,
    pub chain_of_custody: serde_json::Value,
    pub pathology_result: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
