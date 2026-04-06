use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 6-level physical location hierarchy: Campus → Building → Floor → Wing → Room → Bed.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Location {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub level: LocationLevel,
    pub code: String,
    pub name: String,
    /// Level-specific attributes (gas availability, room type, bed type, etc.)
    pub attributes: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Physical location levels in the hospital topology tree.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "location_level", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum LocationLevel {
    Campus,
    Building,
    Floor,
    Wing,
    Zone,
    Room,
    Bed,
}

/// Bed state machine — drives the entire hospital flow.
/// State transitions are configurable per tenant; hospitals can add custom states.
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BedState {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub location_id: Uuid,
    pub status: BedStatus,
    pub patient_id: Option<Uuid>,
    pub changed_by: Option<Uuid>,
    pub reason: Option<String>,
    pub changed_at: DateTime<Utc>,
}

/// Default bed statuses per RFC Section 2.3.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "bed_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum BedStatus {
    VacantClean,
    VacantDirty,
    Reserved,
    Occupied,
    OccupiedTransferPending,
    Maintenance,
    Blocked,
}
