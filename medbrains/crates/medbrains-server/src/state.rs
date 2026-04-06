use jsonwebtoken::{DecodingKey, EncodingKey};
use medbrains_yottadb::client::YottaDbClient;
use sqlx::PgPool;

/// Cookie configuration for `HttpOnly` cookie-based auth.
#[derive(Debug, Clone)]
pub struct CookieConfig {
    pub domain: Option<String>,
    pub secure: bool,
    pub cors_origin: String,
}

/// Shared application state — available to all route handlers via Axum's `State` extractor.
#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub yottadb: Option<YottaDbClient>,
    pub jwt_encoding_key: EncodingKey,
    pub jwt_decoding_key: DecodingKey,
    pub cookie_config: CookieConfig,
}

impl std::fmt::Debug for AppState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AppState")
            .field("db", &"PgPool")
            .field("yottadb", &self.yottadb.is_some())
            .field("jwt_encoding_key", &"[redacted]")
            .field("jwt_decoding_key", &"[redacted]")
            .field("cookie_config", &self.cookie_config)
            .finish()
    }
}
