use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "retrospective_entry_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum RetrospectiveEntryStatus {
    Pending,
    Approved,
    Rejected,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct RetrospectiveEntry {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub source_table: String,
    pub source_record_id: Uuid,
    pub clinical_event_date: DateTime<Utc>,
    pub entry_date: DateTime<Utc>,
    pub entered_by: Uuid,
    pub reason: String,
    pub status: RetrospectiveEntryStatus,
    pub reviewed_by: Option<Uuid>,
    pub reviewed_at: Option<DateTime<Utc>>,
    pub review_notes: Option<String>,
    pub created_at: DateTime<Utc>,
}
