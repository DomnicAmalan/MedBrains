use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "cath_procedure_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum CathProcedureType {
    DiagnosticCath,
    Pci,
    Pacemaker,
    Icd,
    Eps,
    Ablation,
    ValveIntervention,
    Structural,
    Peripheral,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "stemi_pathway_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum StemiPathwayStatus {
    Door,
    Ecg,
    CathLabActivation,
    ArterialAccess,
    BalloonInflation,
    Completed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "hemodynamic_site", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum HemodynamicSite {
    Aorta,
    Lv,
    Rv,
    Ra,
    La,
    Pa,
    Pcwp,
    Svg,
    Lm,
    Lad,
    Lcx,
    Rca,
    Other,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "cath_device_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum CathDeviceType {
    Stent,
    Balloon,
    Guidewire,
    Catheter,
    ClosureDevice,
    Pacemaker,
    Icd,
    Lead,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CathProcedure {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub procedure_type: CathProcedureType,
    pub operator_id: Uuid,
    pub assistant_ids: Vec<Uuid>,
    pub is_stemi: bool,
    pub door_time: Option<DateTime<Utc>>,
    pub balloon_time: Option<DateTime<Utc>>,
    pub door_to_balloon_minutes: Option<i32>,
    pub fluoroscopy_time_seconds: Option<i32>,
    pub total_dap: Option<rust_decimal::Decimal>,
    pub total_air_kerma: Option<rust_decimal::Decimal>,
    pub contrast_type: Option<String>,
    pub contrast_volume_ml: Option<rust_decimal::Decimal>,
    pub access_site: Option<String>,
    pub findings: serde_json::Value,
    pub complications: Option<String>,
    pub status: String,
    pub scheduled_at: Option<DateTime<Utc>>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CathHemodynamic {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub procedure_id: Uuid,
    pub site: HemodynamicSite,
    pub systolic_mmhg: Option<rust_decimal::Decimal>,
    pub diastolic_mmhg: Option<rust_decimal::Decimal>,
    pub mean_mmhg: Option<rust_decimal::Decimal>,
    pub saturation_pct: Option<rust_decimal::Decimal>,
    pub gradient_mmhg: Option<rust_decimal::Decimal>,
    pub recorded_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CathDevice {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub procedure_id: Uuid,
    pub device_type: CathDeviceType,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub lot_number: Option<String>,
    pub barcode: Option<String>,
    pub size: Option<String>,
    pub is_consignment: bool,
    pub vendor_id: Option<Uuid>,
    pub unit_cost: Option<rust_decimal::Decimal>,
    pub billed: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CathStemiTimeline {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub procedure_id: Uuid,
    pub event: StemiPathwayStatus,
    pub event_time: DateTime<Utc>,
    pub recorded_by: Uuid,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CathPostMonitoring {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub procedure_id: Uuid,
    pub monitored_at: DateTime<Utc>,
    pub sheath_status: Option<String>,
    pub access_site_status: Option<String>,
    pub vitals: serde_json::Value,
    pub ambulation_started: bool,
    pub monitored_by: Uuid,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
