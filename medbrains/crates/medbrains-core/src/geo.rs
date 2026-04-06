use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Country in the geospatial hierarchy.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct GeoCountry {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub phone_code: Option<String>,
    pub currency: Option<String>,
    pub is_active: bool,
    pub default_locale: String,
    pub default_timezone: String,
    pub date_format: String,
    pub measurement_system: String,
}

/// State or union territory.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct GeoState {
    pub id: Uuid,
    pub country_id: Uuid,
    pub code: String,
    pub name: String,
    pub is_active: bool,
}

/// District within a state.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct GeoDistrict {
    pub id: Uuid,
    pub state_id: Uuid,
    pub code: String,
    pub name: String,
    pub is_active: bool,
}

/// Sub-district / taluk.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct GeoSubdistrict {
    pub id: Uuid,
    pub district_id: Uuid,
    pub code: String,
    pub name: String,
    pub is_active: bool,
}

/// Town / city within a sub-district.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct GeoTown {
    pub id: Uuid,
    pub subdistrict_id: Uuid,
    pub code: String,
    pub name: String,
    pub pincode: Option<String>,
    pub is_active: bool,
}

/// Result from a PIN-code reverse-lookup — joins town up through the hierarchy.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct PincodeResult {
    pub town_id: Uuid,
    pub town_name: String,
    pub pincode: String,
    pub subdistrict_id: Uuid,
    pub subdistrict_name: String,
    pub district_id: Uuid,
    pub district_name: String,
    pub state_id: Uuid,
    pub state_name: String,
    pub country_id: Uuid,
    pub country_name: String,
}

/// Regulatory body master record.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct RegulatoryBody {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub level: RegulatoryLevel,
    pub country_id: Option<Uuid>,
    pub state_id: Option<Uuid>,
    pub description: Option<String>,
    pub is_active: bool,
}

/// Regulatory body classification level.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "regulatory_level", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum RegulatoryLevel {
    International,
    National,
    State,
    Education,
}

/// Facility compliance record.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FacilityRegulatoryCompliance {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub facility_id: Uuid,
    pub regulatory_body_id: Uuid,
    pub license_number: Option<String>,
    pub valid_from: Option<chrono::NaiveDate>,
    pub valid_until: Option<chrono::NaiveDate>,
    pub status: String,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
