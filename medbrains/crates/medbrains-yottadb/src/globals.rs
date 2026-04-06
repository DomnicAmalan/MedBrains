//! Typed accessors for well-known `YottaDB` globals.
//!
//! These correspond to the hierarchical data stored in `YottaDB`
//! for real-time state and configuration that doesn't fit relational models.

use crate::client::{YottaDbClient, YottaDbError};

/// `^CONFIG(tenantId, layer, module, key)` — per-tenant configuration tree.
pub async fn get_config(
    client: &YottaDbClient,
    tenant_id: &str,
    layer: &str,
    module: &str,
    key: &str,
) -> Result<Option<String>, YottaDbError> {
    client
        .get_global("CONFIG", &[tenant_id, layer, module, key])
        .await
}

/// `^CONFIG(tenantId, layer, module, key)` — set config value.
pub async fn set_config(
    client: &YottaDbClient,
    tenant_id: &str,
    layer: &str,
    module: &str,
    key: &str,
    value: &str,
) -> Result<(), YottaDbError> {
    client
        .set_global("CONFIG", &[tenant_id, layer, module, key], value)
        .await
}

/// `^SEQUENCE(tenantId, type)` — atomic counter for UHID generation, etc.
pub async fn next_sequence(
    client: &YottaDbClient,
    tenant_id: &str,
    sequence_type: &str,
) -> Result<i64, YottaDbError> {
    client
        .increment("SEQUENCE", &[tenant_id, sequence_type])
        .await
}

/// `^BEDSTATE(tenantId, locationId)` — real-time bed status cache.
pub async fn get_bed_state(
    client: &YottaDbClient,
    tenant_id: &str,
    location_id: &str,
) -> Result<Option<String>, YottaDbError> {
    client
        .get_global("BEDSTATE", &[tenant_id, location_id])
        .await
}

/// `^BEDSTATE(tenantId, locationId)` — update bed status.
pub async fn set_bed_state(
    client: &YottaDbClient,
    tenant_id: &str,
    location_id: &str,
    status: &str,
) -> Result<(), YottaDbError> {
    client
        .set_global("BEDSTATE", &[tenant_id, location_id], status)
        .await
}

/// `^SESSION(token)` — session data.
pub async fn get_session(
    client: &YottaDbClient,
    token: &str,
) -> Result<Option<String>, YottaDbError> {
    client.get_global("SESSION", &[token]).await
}

/// `^SESSION(token)` — store session data.
pub async fn set_session(
    client: &YottaDbClient,
    token: &str,
    data: &str,
) -> Result<(), YottaDbError> {
    client.set_global("SESSION", &[token], data).await
}
