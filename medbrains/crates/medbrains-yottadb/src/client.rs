use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum YottaDbError {
    #[error("YottaDB HTTP error: {0}")]
    Http(#[from] reqwest::Error),

    #[error("YottaDB not reachable at {url}")]
    Unreachable { url: String },

    #[error("YottaDB returned error: {message}")]
    Api { message: String },
}

/// REST client for the `YottaDB` Docker container.
///
/// Communicates via the `%YDBWEB` REST API on the configured port.
#[derive(Debug, Clone)]
pub struct YottaDbClient {
    base_url: String,
    http: reqwest::Client,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GlobalValue {
    pub subscripts: Vec<String>,
    pub value: String,
}

impl YottaDbClient {
    /// Create a new client pointing at the `YottaDB` REST endpoint.
    pub fn new(base_url: &str) -> Self {
        let http = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(5))
            .build()
            .unwrap_or_default();

        Self {
            base_url: base_url.trim_end_matches('/').to_owned(),
            http,
        }
    }

    /// Ping the `YottaDB` server to check connectivity.
    pub async fn health_check(&self) -> Result<bool, YottaDbError> {
        let url = format!("{}/api/ping", self.base_url);
        Ok(self
            .http
            .get(&url)
            .send()
            .await
            .is_ok_and(|resp| resp.status().is_success()))
    }

    /// Get a global value by name and subscripts.
    ///
    /// e.g., `get_global("CONFIG", &["tenant1", "layer1", "module", "key"])`
    pub async fn get_global(
        &self,
        global: &str,
        subscripts: &[&str],
    ) -> Result<Option<String>, YottaDbError> {
        let subs = subscripts.join(",");
        let url = format!("{}/api/global/{global}?subscripts={subs}", self.base_url);

        let resp = self.http.get(&url).send().await?;
        if resp.status().is_success() {
            let body: serde_json::Value = resp.json().await?;
            Ok(body.get("value").and_then(|v| v.as_str()).map(String::from))
        } else if resp.status() == reqwest::StatusCode::NOT_FOUND {
            Ok(None)
        } else {
            Err(YottaDbError::Api {
                message: resp.text().await.unwrap_or_default(),
            })
        }
    }

    /// Set a global value.
    pub async fn set_global(
        &self,
        global: &str,
        subscripts: &[&str],
        value: &str,
    ) -> Result<(), YottaDbError> {
        let url = format!("{}/api/global/{global}", self.base_url);

        let body = serde_json::json!({
            "subscripts": subscripts,
            "value": value,
        });

        let resp = self.http.put(&url).json(&body).send().await?;
        if resp.status().is_success() {
            Ok(())
        } else {
            Err(YottaDbError::Api {
                message: resp.text().await.unwrap_or_default(),
            })
        }
    }

    /// Increment a global atomically — used for sequence generation (UHID, etc.).
    pub async fn increment(&self, global: &str, subscripts: &[&str]) -> Result<i64, YottaDbError> {
        let url = format!("{}/api/global/{global}/increment", self.base_url);

        let body = serde_json::json!({
            "subscripts": subscripts,
        });

        let resp = self.http.post(&url).json(&body).send().await?;
        if resp.status().is_success() {
            let result: serde_json::Value = resp.json().await?;
            result
                .get("value")
                .and_then(serde_json::Value::as_i64)
                .ok_or_else(|| YottaDbError::Api {
                    message: "invalid increment response".to_owned(),
                })
        } else {
            Err(YottaDbError::Api {
                message: resp.text().await.unwrap_or_default(),
            })
        }
    }

    /// Get the base URL (for diagnostics).
    pub fn base_url(&self) -> &str {
        &self.base_url
    }
}
