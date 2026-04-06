use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_equipment_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeEquipmentStatus {
    Active,
    UnderMaintenance,
    OutOfService,
    Condemned,
    Disposed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_risk_category", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeRiskCategory {
    Critical,
    High,
    Medium,
    Low,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_work_order_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeWorkOrderStatus {
    Open,
    Assigned,
    InProgress,
    Completed,
    Cancelled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_work_order_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeWorkOrderType {
    Preventive,
    Corrective,
    Calibration,
    Installation,
    Inspection,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_pm_frequency", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmePmFrequency {
    Monthly,
    Quarterly,
    SemiAnnual,
    Annual,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_calibration_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeCalibrationStatus {
    Calibrated,
    Due,
    Overdue,
    OutOfTolerance,
    Exempted,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_contract_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeContractType {
    Amc,
    Cmc,
    Warranty,
    Camc,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_breakdown_priority", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeBreakdownPriority {
    Critical,
    High,
    Medium,
    Low,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bme_breakdown_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BmeBreakdownStatus {
    Reported,
    Acknowledged,
    InProgress,
    PartsAwaited,
    Resolved,
    Closed,
}

// ── Structs ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BmeEquipment {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub make: Option<String>,
    pub model: Option<String>,
    pub serial_number: Option<String>,
    pub asset_tag: Option<String>,
    pub barcode_value: Option<String>,
    pub category: Option<String>,
    pub sub_category: Option<String>,
    pub risk_category: BmeRiskCategory,
    pub is_critical: bool,
    pub department_id: Option<Uuid>,
    pub location_description: Option<String>,
    pub facility_id: Option<Uuid>,
    pub status: BmeEquipmentStatus,
    pub purchase_date: Option<NaiveDate>,
    pub purchase_cost: Option<Decimal>,
    pub installation_date: Option<NaiveDate>,
    pub commissioned_date: Option<NaiveDate>,
    pub installed_by: Option<String>,
    pub commissioning_notes: Option<String>,
    pub expected_life_years: Option<i32>,
    pub condemned_date: Option<NaiveDate>,
    pub disposal_date: Option<NaiveDate>,
    pub disposal_method: Option<String>,
    pub warranty_start_date: Option<NaiveDate>,
    pub warranty_end_date: Option<NaiveDate>,
    pub warranty_terms: Option<String>,
    pub vendor_id: Option<Uuid>,
    pub manufacturer_contact: Option<String>,
    pub specifications: serde_json::Value,
    pub notes: Option<String>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BmePmSchedule {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub equipment_id: Uuid,
    pub frequency: BmePmFrequency,
    pub checklist: serde_json::Value,
    pub next_due_date: Option<NaiveDate>,
    pub last_completed_date: Option<NaiveDate>,
    pub assigned_to: Option<Uuid>,
    pub is_active: bool,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BmeWorkOrder {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub work_order_number: String,
    pub equipment_id: Uuid,
    pub order_type: BmeWorkOrderType,
    pub status: BmeWorkOrderStatus,
    pub priority: BmeBreakdownPriority,
    pub assigned_to: Option<Uuid>,
    pub assigned_at: Option<DateTime<Utc>>,
    pub scheduled_date: Option<NaiveDate>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub description: Option<String>,
    pub findings: Option<String>,
    pub actions_taken: Option<String>,
    pub checklist_results: serde_json::Value,
    pub labor_cost: Option<Decimal>,
    pub parts_cost: Option<Decimal>,
    pub vendor_cost: Option<Decimal>,
    pub total_cost: Option<Decimal>,
    pub technician_sign_off_by: Option<Uuid>,
    pub technician_sign_off_at: Option<DateTime<Utc>>,
    pub supervisor_sign_off_by: Option<Uuid>,
    pub supervisor_sign_off_at: Option<DateTime<Utc>>,
    pub pm_schedule_id: Option<Uuid>,
    pub breakdown_id: Option<Uuid>,
    pub notes: Option<String>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BmeCalibration {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub equipment_id: Uuid,
    pub calibration_status: BmeCalibrationStatus,
    pub frequency: BmePmFrequency,
    pub last_calibrated_date: Option<NaiveDate>,
    pub next_due_date: Option<NaiveDate>,
    pub calibrated_by: Option<String>,
    pub calibration_vendor_id: Option<Uuid>,
    pub certificate_number: Option<String>,
    pub certificate_url: Option<String>,
    pub is_in_tolerance: Option<bool>,
    pub deviation_notes: Option<String>,
    pub reference_standard: Option<String>,
    pub is_locked: bool,
    pub locked_at: Option<DateTime<Utc>>,
    pub locked_reason: Option<String>,
    pub notes: Option<String>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BmeContract {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub contract_number: String,
    pub equipment_id: Uuid,
    pub contract_type: BmeContractType,
    pub vendor_id: Uuid,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub contract_value: Option<Decimal>,
    pub payment_terms: Option<String>,
    pub coverage_details: Option<String>,
    pub exclusions: Option<String>,
    pub sla_response_hours: Option<i32>,
    pub sla_resolution_hours: Option<i32>,
    pub renewal_alert_days: i32,
    pub is_renewed: bool,
    pub renewed_contract_id: Option<Uuid>,
    pub is_active: bool,
    pub notes: Option<String>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BmeBreakdown {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub equipment_id: Uuid,
    pub reported_by: Option<Uuid>,
    pub reported_at: DateTime<Utc>,
    pub department_id: Option<Uuid>,
    pub priority: BmeBreakdownPriority,
    pub status: BmeBreakdownStatus,
    pub description: String,
    pub acknowledged_at: Option<DateTime<Utc>>,
    pub acknowledged_by: Option<Uuid>,
    pub resolution_started_at: Option<DateTime<Utc>>,
    pub resolved_at: Option<DateTime<Utc>>,
    pub resolved_by: Option<Uuid>,
    pub resolution_notes: Option<String>,
    pub downtime_start: Option<DateTime<Utc>>,
    pub downtime_end: Option<DateTime<Utc>>,
    pub downtime_minutes: Option<i32>,
    pub spare_parts_used: Option<String>,
    pub spare_parts_cost: Option<Decimal>,
    pub vendor_visit_required: bool,
    pub vendor_visit_date: Option<NaiveDate>,
    pub vendor_cost: Option<Decimal>,
    pub total_repair_cost: Option<Decimal>,
    pub vendor_id: Option<Uuid>,
    pub vendor_response_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BmeVendorEvaluation {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub vendor_id: Uuid,
    pub contract_id: Option<Uuid>,
    pub evaluation_date: NaiveDate,
    pub period_from: Option<NaiveDate>,
    pub period_to: Option<NaiveDate>,
    pub response_time_score: Option<i32>,
    pub resolution_quality_score: Option<i32>,
    pub spare_parts_availability_score: Option<i32>,
    pub professionalism_score: Option<i32>,
    pub overall_score: Option<Decimal>,
    pub total_calls: Option<i32>,
    pub calls_within_sla: Option<i32>,
    pub comments: Option<String>,
    pub evaluated_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
