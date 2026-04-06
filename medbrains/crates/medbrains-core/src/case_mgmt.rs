use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "case_mgmt_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum CaseMgmtStatus {
    Assigned,
    Active,
    PendingDischarge,
    Discharged,
    Closed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "discharge_barrier_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DischargeBarrierType {
    InsuranceAuth,
    Placement,
    Equipment,
    Family,
    Transport,
    Financial,
    Clinical,
    Documentation,
    Other,
}

// ── Structs ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct CaseAssignment {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub admission_id: Uuid,
    pub patient_id: Uuid,
    pub case_manager_id: Uuid,
    pub status: CaseMgmtStatus,
    pub priority: String,
    pub target_discharge_date: Option<NaiveDate>,
    pub actual_discharge_date: Option<NaiveDate>,
    pub discharge_disposition: Option<String>,
    pub disposition_details: serde_json::Value,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct DischargeBarrier {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub case_assignment_id: Uuid,
    pub barrier_type: DischargeBarrierType,
    pub description: String,
    pub identified_date: NaiveDate,
    pub is_resolved: bool,
    pub resolved_date: Option<NaiveDate>,
    pub resolved_by: Option<Uuid>,
    pub escalated_to: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct CaseReferral {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub case_assignment_id: Uuid,
    pub referral_type: String,
    pub referred_to: String,
    pub status: String,
    pub facility_details: serde_json::Value,
    pub outcome: Option<String>,
    pub referred_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
