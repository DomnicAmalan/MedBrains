use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
};

use crate::validation::ValidationErrors;

/// Unified error type for the HTTP layer.
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("database error: {0}")]
    Database(#[from] medbrains_db::pool::DbError),

    #[error("YottaDB error: {0}")]
    YottaDb(#[from] medbrains_yottadb::client::YottaDbError),

    #[error("configuration error: {0}")]
    Config(#[from] crate::config::ConfigError),

    #[error("unauthorized")]
    Unauthorized,

    #[error("forbidden")]
    Forbidden,

    #[error("not found")]
    NotFound,

    #[error("bad request: {0}")]
    BadRequest(String),

    #[error("conflict: {0}")]
    Conflict(String),

    #[error("validation failed")]
    ValidationFailed(ValidationErrors),

    #[error("internal error: {0}")]
    Internal(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        // Handle validation errors specially — return 422 with field-level errors
        if let Self::ValidationFailed(errors) = self {
            tracing::warn!("validation failed");
            let body = serde_json::json!({
                "error": "validation_failed",
                "fields": errors.into_fields(),
            });
            return (StatusCode::UNPROCESSABLE_ENTITY, axum::Json(body)).into_response();
        }

        let (status, message) = match &self {
            Self::Database(_) => (StatusCode::INTERNAL_SERVER_ERROR, "database error"),
            Self::YottaDb(_) => (StatusCode::BAD_GATEWAY, "yottadb error"),
            Self::Config(_) => (StatusCode::INTERNAL_SERVER_ERROR, "configuration error"),
            Self::Unauthorized => (StatusCode::UNAUTHORIZED, "unauthorized"),
            Self::Forbidden => (StatusCode::FORBIDDEN, "forbidden"),
            Self::NotFound => (StatusCode::NOT_FOUND, "not found"),
            Self::BadRequest(_) => (StatusCode::BAD_REQUEST, "bad request"),
            Self::Conflict(_) => (StatusCode::CONFLICT, "conflict"),
            Self::Internal(_) => (StatusCode::INTERNAL_SERVER_ERROR, "internal error"),
            Self::ValidationFailed(_) => unreachable!(),
        };

        tracing::error!(error = %self, "request error");

        let detail = match &self {
            Self::BadRequest(msg) | Self::Conflict(msg) | Self::Internal(msg) => msg.clone(),
            _ => message.to_owned(),
        };

        let body = serde_json::json!({
            "error": message,
            "detail": detail,
        });

        (status, axum::Json(body)).into_response()
    }
}

impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        Self::Database(medbrains_db::pool::DbError::Sqlx(err))
    }
}

impl From<argon2::password_hash::Error> for AppError {
    fn from(_: argon2::password_hash::Error) -> Self {
        Self::Internal("password hashing error".to_owned())
    }
}
