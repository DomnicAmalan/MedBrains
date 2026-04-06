use axum::{Json, extract::State};
use serde::Serialize;

use crate::state::AppState;

#[derive(Debug, Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub postgres: &'static str,
    pub yottadb: &'static str,
}

/// `GET /api/health` — checks connectivity to databases.
/// `YottaDB` shows "deferred (phase 2)" if `YOTTADB_URL` is not configured.
pub async fn health_check(State(state): State<AppState>) -> Json<HealthResponse> {
    let pg_ok = medbrains_db::pool::health_check(&state.db).await.is_ok();

    let ydb_status = match &state.yottadb {
        Some(client) => {
            if client.health_check().await.unwrap_or(false) {
                "connected"
            } else {
                "disconnected"
            }
        }
        None => "deferred (phase 2)",
    };

    let overall = if pg_ok { "ok" } else { "degraded" };

    Json(HealthResponse {
        status: overall,
        postgres: if pg_ok { "connected" } else { "disconnected" },
        yottadb: ydb_status,
    })
}
