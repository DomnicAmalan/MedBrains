use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "rehab_discipline", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum RehabDiscipline {
    Physiotherapy,
    OccupationalTherapy,
    SpeechTherapy,
    Psychology,
    ProstheticsOrthotics,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "hearing_test_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum HearingTestType {
    Pta,
    Bera,
    Oae,
    Tympanometry,
    SpeechAudiometry,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct RehabPlan {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub discipline: RehabDiscipline,
    pub diagnosis: Option<String>,
    pub goals: String,
    pub plan_details: serde_json::Value,
    pub fim_score_initial: Option<i32>,
    pub barthel_score_initial: Option<i32>,
    pub status: String,
    pub therapist_id: Option<Uuid>,
    pub start_date: NaiveDate,
    pub target_end_date: Option<NaiveDate>,
    pub actual_end_date: Option<NaiveDate>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct RehabSession {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub plan_id: Uuid,
    pub session_number: i32,
    pub therapist_id: Uuid,
    pub intervention: String,
    pub pain_score: Option<i32>,
    pub rom_data: serde_json::Value,
    pub strength_data: serde_json::Value,
    pub fim_score: Option<i32>,
    pub barthel_score: Option<i32>,
    pub session_date: DateTime<Utc>,
    pub duration_minutes: Option<i32>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AudiologyTest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub test_type: HearingTestType,
    pub right_ear_results: serde_json::Value,
    pub left_ear_results: serde_json::Value,
    pub is_nhsp: bool,
    pub nhsp_referral_needed: bool,
    pub audiogram_data: serde_json::Value,
    pub performed_by: Uuid,
    pub test_date: DateTime<Utc>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PsychometricTest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub test_name: String,
    pub raw_data_encrypted: serde_json::Value,
    pub summary_for_clinician: Option<String>,
    pub is_restricted: bool,
    pub administered_by: Uuid,
    pub test_date: DateTime<Utc>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
