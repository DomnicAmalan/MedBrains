use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Sequence {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub seq_type: String,
    pub prefix: String,
    pub current_val: i64,
    pub pad_width: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
