use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "donation_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DonationType {
    WholeBlood,
    ApheresisPlatelets,
    ApheresisPlasma,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "blood_component_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BloodComponentType {
    WholeBlood,
    Prbc,
    Ffp,
    Platelets,
    Cryoprecipitate,
    Granulocytes,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "blood_bag_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BloodBagStatus {
    Collected,
    Processing,
    Tested,
    Available,
    Reserved,
    Crossmatched,
    Issued,
    Transfused,
    Returned,
    Expired,
    Discarded,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "crossmatch_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum CrossmatchStatus {
    Requested,
    Testing,
    Compatible,
    Incompatible,
    Issued,
    Cancelled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "transfusion_reaction_severity", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum TransfusionReactionSeverity {
    Mild,
    Moderate,
    Severe,
    Fatal,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BloodDonor {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub donor_number: String,
    pub first_name: String,
    pub last_name: String,
    pub date_of_birth: Option<NaiveDate>,
    pub gender: Option<String>,
    pub blood_group: String,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub address: Option<String>,
    pub id_type: Option<String>,
    pub id_number: Option<String>,
    pub is_active: bool,
    pub is_deferred: bool,
    pub deferral_reason: Option<String>,
    pub deferral_until: Option<NaiveDate>,
    pub last_donation: Option<DateTime<Utc>>,
    pub total_donations: i32,
    pub medical_history: Option<serde_json::Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BloodDonation {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub donor_id: Uuid,
    pub bag_number: String,
    pub donation_type: DonationType,
    pub volume_ml: i32,
    pub donated_at: DateTime<Utc>,
    pub collected_by: Option<Uuid>,
    pub camp_name: Option<String>,
    pub adverse_reaction: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BloodComponent {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub donation_id: Uuid,
    pub component_type: BloodComponentType,
    pub bag_number: String,
    pub blood_group: String,
    pub volume_ml: i32,
    pub status: BloodBagStatus,
    pub collected_at: DateTime<Utc>,
    pub expiry_at: DateTime<Utc>,
    pub storage_location: Option<String>,
    pub storage_temperature: Option<String>,
    pub tti_status: Option<String>,
    pub tti_tested_at: Option<DateTime<Utc>>,
    pub issued_to_patient: Option<Uuid>,
    pub issued_at: Option<DateTime<Utc>>,
    pub issued_by: Option<Uuid>,
    pub discarded_at: Option<DateTime<Utc>>,
    pub discard_reason: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct CrossmatchRequest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub component_id: Option<Uuid>,
    pub requested_by: Uuid,
    pub blood_group: String,
    pub component_type: BloodComponentType,
    pub units_requested: i32,
    pub clinical_indication: Option<String>,
    pub status: CrossmatchStatus,
    pub result: Option<String>,
    pub tested_by: Option<Uuid>,
    pub tested_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct TransfusionRecord {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub component_id: Uuid,
    pub crossmatch_id: Option<Uuid>,
    pub administered_by: Uuid,
    pub verified_by: Option<Uuid>,
    pub started_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
    pub volume_transfused_ml: Option<i32>,
    pub has_reaction: bool,
    pub reaction_type: Option<String>,
    pub reaction_severity: Option<TransfusionReactionSeverity>,
    pub reaction_details: Option<String>,
    pub reaction_reported_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
