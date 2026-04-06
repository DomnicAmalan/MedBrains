use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// System user — auth identity + ABAC access matrix.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub username: String,
    pub email: String,
    /// Argon2 hashed password.
    pub password_hash: String,
    pub full_name: String,
    pub role: Role,
    /// ABAC access matrix as JSONB — department scopes, action permissions, conditions.
    pub access_matrix: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// High-level role for coarse-grained access. Fine-grained control via `access_matrix`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "user_role", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum Role {
    SuperAdmin,
    HospitalAdmin,
    Doctor,
    Nurse,
    Receptionist,
    LabTechnician,
    Pharmacist,
    BillingClerk,
    HousekeepingStaff,
    FacilitiesManager,
    AuditOfficer,
}
