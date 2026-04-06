use chrono::{DateTime, NaiveTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "visitor_pass_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum VisitorPassStatus {
    Active,
    Expired,
    Revoked,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "visitor_category", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum VisitorCategory {
    General,
    LegalCounsel,
    Religious,
    Vip,
    Media,
    Vendor,
    Emergency,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "queue_priority", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum QueuePriority {
    Normal,
    Elderly,
    Disabled,
    Pregnant,
    EmergencyReferral,
    Vip,
}

// ── Structs ────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct VisitingHours {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub ward_id: Option<Uuid>,
    pub day_of_week: i32,
    pub start_time: NaiveTime,
    pub end_time: NaiveTime,
    pub max_visitors_per_patient: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct VisitorRegistration {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub visitor_name: String,
    pub phone: Option<String>,
    pub id_type: Option<String>,
    pub id_number: Option<String>,
    pub photo_url: Option<String>,
    pub relationship: Option<String>,
    pub category: VisitorCategory,
    pub patient_id: Option<Uuid>,
    pub ward_id: Option<Uuid>,
    pub purpose: Option<String>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct VisitorPass {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub registration_id: Uuid,
    pub pass_number: String,
    pub ward_id: Option<Uuid>,
    pub bed_number: Option<String>,
    pub valid_from: DateTime<Utc>,
    pub valid_until: DateTime<Utc>,
    pub status: VisitorPassStatus,
    pub qr_code: Option<String>,
    pub issued_by: Option<Uuid>,
    pub revoked_at: Option<DateTime<Utc>>,
    pub revoked_reason: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct VisitorLog {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub pass_id: Uuid,
    pub check_in_at: DateTime<Utc>,
    pub check_out_at: Option<DateTime<Utc>>,
    pub logged_by: Option<Uuid>,
    pub gate: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct QueuePriorityRule {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub department_id: Option<Uuid>,
    pub priority: QueuePriority,
    pub weight: i32,
    pub auto_detect_criteria: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct QueueDisplayConfig {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub department_id: Option<Uuid>,
    pub location_name: String,
    pub display_type: String,
    pub doctors_per_screen: i32,
    pub show_patient_name: bool,
    pub show_wait_time: bool,
    pub language: serde_json::Value,
    pub announcement_enabled: bool,
    pub scroll_speed: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct EnquiryLog {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub caller_name: Option<String>,
    pub caller_phone: Option<String>,
    pub enquiry_type: String,
    pub patient_id: Option<Uuid>,
    pub response_text: Option<String>,
    pub handled_by: Option<Uuid>,
    pub resolved: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
