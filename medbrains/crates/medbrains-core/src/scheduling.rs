use chrono::{DateTime, NaiveDate, NaiveTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Structs ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct NoshowPredictionScore {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub appointment_id: Uuid,
    pub patient_id: Uuid,
    pub predicted_noshow_probability: Decimal,
    pub risk_level: String,
    pub features_used: serde_json::Value,
    pub model_version: String,
    pub scored_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct SchedulingWaitlistEntry {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub doctor_id: Option<Uuid>,
    pub department_id: Option<Uuid>,
    pub preferred_date_from: Option<NaiveDate>,
    pub preferred_date_to: Option<NaiveDate>,
    pub preferred_time_from: Option<NaiveTime>,
    pub preferred_time_to: Option<NaiveTime>,
    pub priority: String,
    pub status: String,
    pub offered_appointment_id: Option<Uuid>,
    pub reason: Option<String>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct SchedulingOverbookingRule {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub doctor_id: Uuid,
    pub department_id: Uuid,
    pub day_of_week: i32,
    pub max_overbook_slots: i32,
    pub overbook_threshold_probability: Decimal,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
