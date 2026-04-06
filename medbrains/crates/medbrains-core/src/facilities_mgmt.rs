use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_gas_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsGasType {
    Oxygen,
    NitrousOxide,
    Nitrogen,
    MedicalAir,
    Vacuum,
    Co2,
    Heliox,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_gas_source_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsGasSourceType {
    PsaPlant,
    LmoTank,
    CylinderManifold,
    Pipeline,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_fire_equipment_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsFireEquipmentType {
    ExtinguisherAbc,
    ExtinguisherCo2,
    ExtinguisherWater,
    Hydrant,
    HoseReel,
    SmokeDetector,
    HeatDetector,
    Sprinkler,
    FireAlarmPanel,
    EmergencyLight,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_drill_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsDrillType {
    Fire,
    CodeRed,
    Evacuation,
    ChemicalSpill,
    BombThreat,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_water_source_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsWaterSourceType {
    Municipal,
    Borewell,
    Tanker,
    RoPlant,
    StpRecycled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_water_test_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsWaterTestType {
    Bacteriological,
    Chemical,
    Endotoxin,
    Conductivity,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_energy_source_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsEnergySourceType {
    Grid,
    DgSet,
    Ups,
    Solar,
    Inverter,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "fms_work_order_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FmsWorkOrderStatus {
    Open,
    Assigned,
    InProgress,
    OnHold,
    Completed,
    Cancelled,
}

// ── Structs ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsGasReading {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub gas_type: FmsGasType,
    pub source_type: FmsGasSourceType,
    pub location_id: Option<Uuid>,
    pub department_id: Option<Uuid>,
    pub purity_percent: Option<Decimal>,
    pub pressure_bar: Option<Decimal>,
    pub flow_lpm: Option<Decimal>,
    pub temperature_c: Option<Decimal>,
    pub tank_level_percent: Option<Decimal>,
    pub cylinder_count: Option<i32>,
    pub manifold_side: Option<String>,
    pub is_alarm: bool,
    pub alarm_reason: Option<String>,
    pub reading_at: DateTime<Utc>,
    pub recorded_by: Option<Uuid>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsGasCompliance {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub facility_id: Option<Uuid>,
    pub gas_type: FmsGasType,
    pub peso_license_number: Option<String>,
    pub peso_valid_from: Option<NaiveDate>,
    pub peso_valid_to: Option<NaiveDate>,
    pub drug_license_number: Option<String>,
    pub drug_license_valid_to: Option<NaiveDate>,
    pub last_inspection_date: Option<NaiveDate>,
    pub next_inspection_date: Option<NaiveDate>,
    pub inspector_name: Option<String>,
    pub compliance_status: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsFireEquipment {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub equipment_type: FmsFireEquipmentType,
    pub location_id: Option<Uuid>,
    pub department_id: Option<Uuid>,
    pub serial_number: Option<String>,
    pub make: Option<String>,
    pub capacity: Option<String>,
    pub installation_date: Option<NaiveDate>,
    pub expiry_date: Option<NaiveDate>,
    pub last_refill_date: Option<NaiveDate>,
    pub next_refill_date: Option<NaiveDate>,
    pub barcode_value: Option<String>,
    pub qr_code_value: Option<String>,
    pub is_active: bool,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsFireInspection {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub equipment_id: Uuid,
    pub inspection_date: NaiveDate,
    pub is_functional: bool,
    pub findings: Option<String>,
    pub corrective_action: Option<String>,
    pub inspected_by: Option<Uuid>,
    pub next_inspection_date: Option<NaiveDate>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsFireDrill {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub drill_type: FmsDrillType,
    pub facility_id: Option<Uuid>,
    pub drill_date: NaiveDate,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub duration_minutes: Option<i32>,
    pub zones_covered: Option<Vec<String>>,
    pub participants_count: Option<i32>,
    pub scenario_description: Option<String>,
    pub evacuation_time_seconds: Option<i32>,
    pub response_time_seconds: Option<i32>,
    pub findings: Option<String>,
    pub improvement_actions: Option<String>,
    pub drill_report_url: Option<String>,
    pub conducted_by: Option<Uuid>,
    pub approved_by: Option<Uuid>,
    pub next_drill_due: Option<NaiveDate>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsFireNoc {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub facility_id: Option<Uuid>,
    pub noc_number: String,
    pub issuing_authority: Option<String>,
    pub issue_date: Option<NaiveDate>,
    pub valid_from: Option<NaiveDate>,
    pub valid_to: Option<NaiveDate>,
    pub renewal_alert_days: i32,
    pub is_active: bool,
    pub document_url: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsWaterTest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub source_type: FmsWaterSourceType,
    pub test_type: FmsWaterTestType,
    pub location_id: Option<Uuid>,
    pub sample_date: NaiveDate,
    pub result_date: Option<NaiveDate>,
    pub parameter_name: String,
    pub result_value: Option<Decimal>,
    pub unit: Option<String>,
    pub acceptable_min: Option<Decimal>,
    pub acceptable_max: Option<Decimal>,
    pub is_within_limits: Option<bool>,
    pub corrective_action: Option<String>,
    pub tested_by: Option<String>,
    pub lab_name: Option<String>,
    pub certificate_number: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsWaterSchedule {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub location_id: Option<Uuid>,
    pub schedule_type: String,
    pub frequency: String,
    pub last_completed_date: Option<NaiveDate>,
    pub next_due_date: Option<NaiveDate>,
    pub assigned_to: Option<Uuid>,
    pub is_active: bool,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsEnergyReading {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub source_type: FmsEnergySourceType,
    pub location_id: Option<Uuid>,
    pub equipment_name: Option<String>,
    pub reading_at: DateTime<Utc>,
    pub voltage: Option<Decimal>,
    pub current_amps: Option<Decimal>,
    pub power_kw: Option<Decimal>,
    pub power_factor: Option<Decimal>,
    pub frequency_hz: Option<Decimal>,
    pub fuel_level_percent: Option<Decimal>,
    pub runtime_hours: Option<Decimal>,
    pub load_percent: Option<Decimal>,
    pub battery_voltage: Option<Decimal>,
    pub battery_health_percent: Option<Decimal>,
    pub backup_minutes: Option<i32>,
    pub switchover_time_seconds: Option<Decimal>,
    pub is_alarm: bool,
    pub alarm_reason: Option<String>,
    pub recorded_by: Option<Uuid>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FmsWorkOrder {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub work_order_number: String,
    pub category: Option<String>,
    pub location_id: Option<Uuid>,
    pub department_id: Option<Uuid>,
    pub requested_by: Option<Uuid>,
    pub requested_at: DateTime<Utc>,
    pub priority: String,
    pub status: FmsWorkOrderStatus,
    pub description: String,
    pub assigned_to: Option<Uuid>,
    pub assigned_at: Option<DateTime<Utc>>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub findings: Option<String>,
    pub actions_taken: Option<String>,
    pub vendor_id: Option<Uuid>,
    pub vendor_report: Option<String>,
    pub vendor_cost: Option<Decimal>,
    pub material_cost: Option<Decimal>,
    pub labor_cost: Option<Decimal>,
    pub total_cost: Option<Decimal>,
    pub completed_by: Option<Uuid>,
    pub sign_off_by: Option<Uuid>,
    pub sign_off_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
