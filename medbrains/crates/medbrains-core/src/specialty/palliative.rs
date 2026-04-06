use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "dnr_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DnrStatus {
    Active,
    Expired,
    Revoked,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "body_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BodyStatus {
    Received,
    ColdStorage,
    InquestPending,
    PmScheduled,
    PmCompleted,
    Released,
    Unclaimed,
    Disposed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "radiopharmaceutical_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum RadiopharmaceuticalType {
    Diagnostic,
    Therapeutic,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DnrOrder {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub admission_id: Option<Uuid>,
    pub status: DnrStatus,
    pub scope: String,
    pub authorized_by: Uuid,
    pub witness_name: Option<String>,
    pub review_due_at: DateTime<Utc>,
    pub revoked_at: Option<DateTime<Utc>>,
    pub revoked_by: Option<Uuid>,
    pub revocation_reason: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PainAssessment {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub pain_score: i32,
    pub pain_location: Option<String>,
    pub pain_character: Option<String>,
    pub who_ladder_step: Option<i32>,
    pub opioid_dose_morphine_eq: Option<rust_decimal::Decimal>,
    pub breakthrough_doses: i32,
    pub current_medications: serde_json::Value,
    pub assessed_by: Uuid,
    pub assessed_at: DateTime<Utc>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct MortuaryRecord {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub body_receipt_number: String,
    pub deceased_name: String,
    pub deceased_age: Option<i32>,
    pub deceased_gender: Option<String>,
    pub date_of_death: Option<DateTime<Utc>>,
    pub cause_of_death: Option<String>,
    pub is_mlc: bool,
    pub mlc_case_id: Option<Uuid>,
    pub cold_storage_slot: Option<String>,
    pub temperature_log: serde_json::Value,
    pub status: BodyStatus,
    pub pm_requested: bool,
    pub pm_performed_by: Option<String>,
    pub pm_date: Option<DateTime<Utc>>,
    pub pm_findings: Option<String>,
    pub viscera_preserved: bool,
    pub viscera_chain_of_custody: serde_json::Value,
    pub organ_donation_status: Option<String>,
    pub released_to: Option<String>,
    pub released_at: Option<DateTime<Utc>>,
    pub released_by: Option<Uuid>,
    pub identification_marks: Option<String>,
    pub unclaimed_notice_date: Option<chrono::NaiveDate>,
    pub unclaimed_disposal_date: Option<chrono::NaiveDate>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct NuclearMedSource {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub isotope: String,
    pub activity_mci: rust_decimal::Decimal,
    pub half_life_hours: rust_decimal::Decimal,
    pub source_type: RadiopharmaceuticalType,
    pub aerb_license_number: Option<String>,
    pub batch_number: Option<String>,
    pub calibration_date: Option<DateTime<Utc>>,
    pub expiry_date: Option<DateTime<Utc>>,
    pub is_active: bool,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct NuclearMedAdministration {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub source_id: Uuid,
    pub patient_id: Uuid,
    pub dose_mci: rust_decimal::Decimal,
    pub route: String,
    pub indication: String,
    pub administered_by: Uuid,
    pub administered_at: DateTime<Utc>,
    pub waste_disposed: bool,
    pub waste_disposal_date: Option<DateTime<Utc>>,
    pub isolation_required: bool,
    pub isolation_end: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
