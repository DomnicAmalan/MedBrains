//! Insurance & TPA — domain types.
//!
//! Eligibility verification, prior authorization, appeals, and PA rules.

use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::FromRow;
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[sqlx(type_name = "verification_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum VerificationStatus {
    Pending,
    Active,
    Inactive,
    Unknown,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[sqlx(type_name = "prior_auth_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum PriorAuthStatus {
    Draft,
    PendingInfo,
    Submitted,
    InReview,
    Approved,
    PartiallyApproved,
    Denied,
    Expired,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[sqlx(type_name = "pa_urgency", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum PaUrgency {
    Standard,
    Urgent,
    Retrospective,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[sqlx(type_name = "appeal_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum AppealStatus {
    Draft,
    Submitted,
    InReview,
    Upheld,
    Overturned,
    Withdrawn,
}

// ── Row structs ────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct InsuranceVerification {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub patient_insurance_id: Uuid,
    pub trigger_point: String,
    pub trigger_entity_id: Option<Uuid>,
    pub status: VerificationStatus,
    pub verified_at: Option<DateTime<Utc>>,
    pub payer_name: Option<String>,
    pub payer_id: Option<String>,
    pub member_id: Option<String>,
    pub group_number: Option<String>,
    pub subscriber_name: Option<String>,
    pub relationship_to_subscriber: Option<String>,
    pub coverage_start: Option<NaiveDate>,
    pub coverage_end: Option<NaiveDate>,
    pub benefits: Option<Value>,
    pub individual_deductible: Option<rust_decimal::Decimal>,
    pub individual_deductible_met: Option<rust_decimal::Decimal>,
    pub family_deductible: Option<rust_decimal::Decimal>,
    pub family_deductible_met: Option<rust_decimal::Decimal>,
    pub co_pay_percent: Option<rust_decimal::Decimal>,
    pub co_insurance_percent: Option<rust_decimal::Decimal>,
    pub out_of_pocket_max: Option<rust_decimal::Decimal>,
    pub out_of_pocket_met: Option<rust_decimal::Decimal>,
    pub scheme_type: Option<String>,
    pub scheme_balance: Option<rust_decimal::Decimal>,
    pub error_code: Option<String>,
    pub error_message: Option<String>,
    pub raw_response: Option<Value>,
    pub notes: Option<String>,
    pub verified_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PriorAuthRequest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub pa_number: String,
    pub patient_id: Uuid,
    pub patient_insurance_id: Uuid,
    pub service_type: String,
    pub service_code: Option<String>,
    pub service_description: Option<String>,
    pub diagnosis_codes: Option<Vec<String>>,
    pub ordering_doctor_id: Option<Uuid>,
    pub department_id: Option<Uuid>,
    pub encounter_id: Option<Uuid>,
    pub invoice_id: Option<Uuid>,
    pub insurance_claim_id: Option<Uuid>,
    pub status: PriorAuthStatus,
    pub urgency: PaUrgency,
    pub requested_start: Option<NaiveDate>,
    pub requested_end: Option<NaiveDate>,
    pub requested_units: Option<i32>,
    pub estimated_cost: Option<rust_decimal::Decimal>,
    pub auth_number: Option<String>,
    pub approved_start: Option<NaiveDate>,
    pub approved_end: Option<NaiveDate>,
    pub approved_units: Option<i32>,
    pub approved_amount: Option<rust_decimal::Decimal>,
    pub denial_reason: Option<String>,
    pub denial_code: Option<String>,
    pub submitted_at: Option<DateTime<Utc>>,
    pub responded_at: Option<DateTime<Utc>>,
    pub expires_at: Option<DateTime<Utc>>,
    pub expected_tat_hours: Option<i32>,
    pub escalated: bool,
    pub escalated_at: Option<DateTime<Utc>>,
    pub created_by: Option<Uuid>,
    pub submitted_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PriorAuthDocument {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub prior_auth_id: Uuid,
    pub document_type: String,
    pub file_name: Option<String>,
    pub file_path: Option<String>,
    pub file_size_bytes: Option<i64>,
    pub mime_type: Option<String>,
    pub content_text: Option<String>,
    pub content_json: Option<Value>,
    pub source_entity: Option<String>,
    pub source_id: Option<Uuid>,
    pub uploaded_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PriorAuthStatusLog {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub prior_auth_id: Uuid,
    pub from_status: Option<PriorAuthStatus>,
    pub to_status: PriorAuthStatus,
    pub notes: Option<String>,
    pub changed_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PriorAuthAppeal {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub prior_auth_id: Uuid,
    pub appeal_number: String,
    pub level: i32,
    pub status: AppealStatus,
    pub reason: Option<String>,
    pub clinical_rationale: Option<String>,
    pub supporting_evidence: Option<String>,
    pub letter_content: Option<String>,
    pub payer_decision: Option<String>,
    pub payer_response_date: Option<NaiveDate>,
    pub payer_notes: Option<String>,
    pub submitted_at: Option<DateTime<Utc>>,
    pub resolved_at: Option<DateTime<Utc>>,
    pub deadline: Option<NaiveDate>,
    pub created_by: Option<Uuid>,
    pub submitted_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PaRequirementRule {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub rule_name: String,
    pub description: Option<String>,
    pub insurance_provider: Option<String>,
    pub scheme_type: Option<String>,
    pub tpa_name: Option<String>,
    pub service_type: Option<String>,
    pub charge_code: Option<String>,
    pub charge_code_pattern: Option<String>,
    pub cost_threshold: Option<rust_decimal::Decimal>,
    pub los_threshold: Option<i32>,
    pub priority: i32,
    pub is_active: bool,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── Dashboard aggregate types ─────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InsuranceDashboard {
    pub total_verifications: i64,
    pub active_verifications: i64,
    pub total_prior_auths: i64,
    pub pending_prior_auths: i64,
    pub approved_prior_auths: i64,
    pub denied_prior_auths: i64,
    pub denial_rate_percent: f64,
    pub pending_appeals: i64,
    pub avg_tat_hours: Option<f64>,
    pub expiring_soon: Vec<PriorAuthRequest>,
    pub top_denial_reasons: Vec<DenialReasonCount>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DenialReasonCount {
    pub reason: String,
    pub count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaCheckResult {
    pub required: bool,
    pub matching_rule_id: Option<Uuid>,
    pub rule_name: Option<String>,
}
