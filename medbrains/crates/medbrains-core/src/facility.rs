use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Institutional facility — self-referencing tree for multi-campus setups.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
#[allow(clippy::struct_excessive_bools)]
pub struct Facility {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub facility_type: FacilityType,
    pub status: FacilityStatus,
    pub address_line1: Option<String>,
    pub address_line2: Option<String>,
    pub city: Option<String>,
    pub pincode: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub country_id: Option<Uuid>,
    pub state_id: Option<Uuid>,
    pub district_id: Option<Uuid>,
    pub latitude: Option<rust_decimal::Decimal>,
    pub longitude: Option<rust_decimal::Decimal>,
    pub bed_count: i32,
    pub shared_billing: bool,
    pub shared_pharmacy: bool,
    pub shared_lab: bool,
    pub shared_hr: bool,
    pub config: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// 30-variant facility classification.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "facility_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FacilityType {
    MainHospital,
    MedicalCollege,
    DentalCollege,
    NursingCollege,
    PharmacyCollege,
    AyushHospital,
    ResearchCenter,
    BloodBank,
    DialysisCenter,
    TraumaCenter,
    BurnCenter,
    RehabilitationCenter,
    PalliativeCare,
    PsychiatricHospital,
    EyeHospital,
    MaternityHospital,
    PediatricHospital,
    CancerCenter,
    CardiacCenter,
    NeuroCenter,
    OrthoCenter,
    DayCareCenter,
    DiagnosticCenter,
    TelemedicineHub,
    CommunityHealthCenter,
    PrimaryHealthCenter,
    SubCenter,
    UrbanHealthCenter,
    MobileHealthUnit,
    Other,
}

/// Facility operational status.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "facility_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum FacilityStatus {
    Active,
    Inactive,
    UnderConstruction,
    Closed,
}
