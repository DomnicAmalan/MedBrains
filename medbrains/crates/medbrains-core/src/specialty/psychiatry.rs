use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "psych_admission_category", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum PsychAdmissionCategory {
    Independent,
    Supported,
    MinorSupported,
    Emergency,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "ect_laterality", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum EctLaterality {
    Bilateral,
    RightUnilateral,
    LeftUnilateral,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "restraint_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum RestraintType {
    Physical,
    Chemical,
    Seclusion,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PsychPatient {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub admission_category: PsychAdmissionCategory,
    pub advance_directive_text: Option<String>,
    pub nominated_rep_name: Option<String>,
    pub nominated_rep_relation: Option<String>,
    pub nominated_rep_contact: Option<String>,
    pub substance_abuse_flag: bool,
    pub is_restricted: bool,
    pub treating_psychiatrist_id: Option<Uuid>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PsychAssessment {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub psych_patient_id: Uuid,
    pub assessment_type: String,
    pub mental_status_exam: serde_json::Value,
    pub ham_d_score: Option<i32>,
    pub bprs_score: Option<i32>,
    pub gaf_score: Option<i32>,
    pub risk_assessment: serde_json::Value,
    pub assessed_by: Uuid,
    pub assessed_at: DateTime<Utc>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PsychEctRegister {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub psych_patient_id: Uuid,
    pub session_number: i32,
    pub consent_obtained: bool,
    pub laterality: EctLaterality,
    pub stimulus_dose: Option<rust_decimal::Decimal>,
    pub seizure_duration_sec: Option<i32>,
    pub anesthetic: Option<String>,
    pub muscle_relaxant: Option<String>,
    pub performed_by: Uuid,
    pub anesthetist_id: Option<Uuid>,
    pub session_date: DateTime<Utc>,
    pub complications: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PsychSeclusionRestraint {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub psych_patient_id: Uuid,
    pub restraint_type: RestraintType,
    pub reason: String,
    pub start_time: DateTime<Utc>,
    pub review_due_at: DateTime<Utc>,
    pub reviewed_at: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub ordered_by: Uuid,
    pub released_by: Option<Uuid>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PsychMhrbNotification {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub psych_patient_id: Uuid,
    pub notification_type: String,
    pub reference_number: Option<String>,
    pub status: String,
    pub sent_at: Option<DateTime<Utc>>,
    pub acknowledged_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PsychCounselingSession {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub psych_patient_id: Uuid,
    pub session_type: String,
    pub therapist_id: Uuid,
    pub modality: Option<String>,
    pub duration_minutes: Option<i32>,
    pub outcome_rating: Option<i32>,
    pub session_date: DateTime<Utc>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
