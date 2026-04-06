use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Master tenant record. Each hospital deployment is a tenant.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Tenant {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub hospital_type: HospitalType,
    /// Global config blob — Layer 1-7 defaults, feature flags, branding.
    pub config: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Hospital classification determines default configs and NMC requirements.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "hospital_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum HospitalType {
    MedicalCollege,
    MultiSpecialty,
    DistrictHospital,
    CommunityHealth,
    PrimaryHealth,
    StandaloneClinic,
    EyeHospital,
    DentalCollege,
}
