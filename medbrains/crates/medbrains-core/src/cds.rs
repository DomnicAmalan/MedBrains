//! Clinical Decision Support — drug interactions, critical values, protocols, stewardship.

use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Drug Interactions ───────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct DrugInteraction {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub drug_a_name: String,
    pub drug_b_name: String,
    pub severity: String,
    pub description: String,
    pub mechanism: Option<String>,
    pub management: Option<String>,
    pub source: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── Critical Value Rules ────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct CriticalValueRule {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub test_code: String,
    pub test_name: String,
    pub low_critical: Option<rust_decimal::Decimal>,
    pub high_critical: Option<rust_decimal::Decimal>,
    pub unit: Option<String>,
    pub age_min: Option<i32>,
    pub age_max: Option<i32>,
    pub gender: Option<String>,
    pub alert_message: String,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── Clinical Protocols ──────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct ClinicalProtocol {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub code: Option<String>,
    pub category: String,
    pub description: Option<String>,
    pub trigger_conditions: serde_json::Value,
    pub steps: serde_json::Value,
    pub department_id: Option<Uuid>,
    pub is_active: bool,
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── Restricted Drug Approvals ───────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct RestrictedDrugApproval {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub prescription_id: Option<Uuid>,
    pub encounter_id: Uuid,
    pub patient_id: Uuid,
    pub drug_name: String,
    pub catalog_item_id: Option<Uuid>,
    pub reason: String,
    pub requested_by: Uuid,
    pub approved_by: Option<Uuid>,
    pub status: String,
    pub approved_at: Option<DateTime<Utc>>,
    pub denied_reason: Option<String>,
    pub expires_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── Pre-Authorization Requests ──────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct PreAuthorizationRequest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub encounter_id: Uuid,
    pub insurance_provider: String,
    pub policy_number: Option<String>,
    pub procedure_codes: Vec<String>,
    pub diagnosis_codes: Vec<String>,
    pub estimated_cost: Option<rust_decimal::Decimal>,
    pub status: String,
    pub auth_number: Option<String>,
    pub approved_amount: Option<rust_decimal::Decimal>,
    pub valid_from: Option<NaiveDate>,
    pub valid_until: Option<NaiveDate>,
    pub notes: Option<String>,
    pub submitted_by: Uuid,
    pub reviewed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── PG Logbook ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct PgLogbookEntry {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub encounter_id: Option<Uuid>,
    pub entry_type: String,
    pub title: String,
    pub description: Option<String>,
    pub diagnosis_codes: Vec<String>,
    pub procedure_codes: Vec<String>,
    pub department_id: Option<Uuid>,
    pub supervisor_id: Option<Uuid>,
    pub supervisor_verified: bool,
    pub verified_at: Option<DateTime<Utc>>,
    pub entry_date: NaiveDate,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ── Co-Signature Requests ───────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct CoSignatureRequest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub encounter_id: Uuid,
    pub order_type: String,
    pub order_id: Uuid,
    pub requested_by: Uuid,
    pub approver_id: Uuid,
    pub status: String,
    pub approved_at: Option<DateTime<Utc>>,
    pub denied_reason: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
