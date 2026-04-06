use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "ur_review_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum UrReviewType {
    PreAdmission,
    Admission,
    ContinuedStay,
    Retrospective,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "ur_decision", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum UrDecision {
    Approved,
    Denied,
    PendingInfo,
    Modified,
    Escalated,
}

// ── Structs ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct UtilizationReview {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub admission_id: Uuid,
    pub patient_id: Uuid,
    pub reviewer_id: Option<Uuid>,
    pub review_type: UrReviewType,
    pub review_date: NaiveDate,
    pub patient_status: String,
    pub decision: UrDecision,
    pub criteria_source: Option<String>,
    pub criteria_met: serde_json::Value,
    pub clinical_summary: Option<String>,
    pub expected_los_days: Option<i32>,
    pub actual_los_days: Option<i32>,
    pub is_outlier: bool,
    pub approved_days: Option<i32>,
    pub next_review_date: Option<NaiveDate>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct UrPayerCommunication {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub review_id: Uuid,
    pub communication_type: String,
    pub payer_name: String,
    pub reference_number: Option<String>,
    pub communicated_at: DateTime<Utc>,
    pub summary: Option<String>,
    pub response: Option<String>,
    pub attachments: serde_json::Value,
    pub communicated_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct UrStatusConversion {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub admission_id: Uuid,
    pub from_status: String,
    pub to_status: String,
    pub conversion_date: NaiveDate,
    pub reason: Option<String>,
    pub effective_from: DateTime<Utc>,
    pub converted_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
