use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "drug_screen_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DrugScreenStatus {
    Ordered,
    Collected,
    SentToLab,
    MroReview,
    Positive,
    Negative,
    Inconclusive,
    Cancelled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "rtw_clearance_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum RtwClearanceStatus {
    PendingEvaluation,
    ClearedFull,
    ClearedWithRestrictions,
    NotCleared,
    FollowUpRequired,
}

// ── Structs ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OccHealthScreening {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub employee_id: Uuid,
    pub examiner_id: Option<Uuid>,
    pub screening_type: String,
    pub screening_date: NaiveDate,
    pub fitness_status: String,
    pub findings: serde_json::Value,
    pub restrictions: serde_json::Value,
    pub next_due_date: Option<NaiveDate>,
    pub notes: Option<String>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OccHealthDrugScreen {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub employee_id: Uuid,
    pub screening_id: Option<Uuid>,
    pub specimen_id: Option<String>,
    pub status: DrugScreenStatus,
    pub chain_of_custody: serde_json::Value,
    pub panel: String,
    pub results: serde_json::Value,
    pub mro_reviewer_id: Option<Uuid>,
    pub mro_decision: Option<String>,
    pub mro_reviewed_at: Option<DateTime<Utc>>,
    pub collected_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OccHealthVaccination {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub employee_id: Uuid,
    pub vaccine_name: String,
    pub dose_number: i32,
    pub administered_date: NaiveDate,
    pub batch_number: Option<String>,
    pub administered_by: Option<Uuid>,
    pub next_due_date: Option<NaiveDate>,
    pub is_compliant: bool,
    pub exemption_type: Option<String>,
    pub exemption_reason: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OccHealthInjuryReport {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub employee_id: Uuid,
    pub report_number: String,
    pub injury_date: NaiveDate,
    pub injury_type: String,
    pub injury_description: Option<String>,
    pub body_part_affected: Option<String>,
    pub location_of_incident: Option<String>,
    pub is_osha_recordable: bool,
    pub lost_work_days: i32,
    pub restricted_days: i32,
    pub workers_comp_claim_number: Option<String>,
    pub workers_comp_status: Option<String>,
    pub rtw_status: RtwClearanceStatus,
    pub rtw_restrictions: serde_json::Value,
    pub rtw_cleared_date: Option<NaiveDate>,
    pub rtw_cleared_by: Option<Uuid>,
    pub employer_access_notes: Option<String>,
    pub reported_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
