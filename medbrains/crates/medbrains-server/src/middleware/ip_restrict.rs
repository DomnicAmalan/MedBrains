//! IP-based access restriction middleware.
//!
//! Checks the request IP against the tenant's allowed IP ranges.
//! Runs after auth middleware (needs Claims for tenant lookup).
//! Empty `allowed_ips` means no restriction.

use std::net::IpAddr;

use axum::{
    extract::{ConnectInfo, Request, State},
    middleware::Next,
    response::Response,
};
use sqlx::PgPool;

use crate::{error::AppError, middleware::auth::Claims, state::AppState};

/// Check whether an IP address matches a CIDR range string.
///
/// Supports both IPv4 (`10.0.0.0/8`) and IPv6 (`::1/128`).
fn ip_in_cidr(ip: IpAddr, cidr: &str) -> bool {
    let Some((network_str, prefix_str)) = cidr.split_once('/') else {
        // No prefix — exact match
        return cidr.parse::<IpAddr>().is_ok_and(|a| a == ip);
    };

    let Ok(network) = network_str.parse::<IpAddr>() else {
        return false;
    };

    let Ok(prefix_len) = prefix_str.parse::<u32>() else {
        return false;
    };

    match (ip, network) {
        (IpAddr::V4(ip4), IpAddr::V4(net4)) => {
            if prefix_len > 32 {
                return false;
            }
            if prefix_len == 0 {
                return true;
            }
            let mask = u32::MAX << (32 - prefix_len);
            (u32::from(ip4) & mask) == (u32::from(net4) & mask)
        }
        (IpAddr::V6(ip6), IpAddr::V6(net6)) => {
            if prefix_len > 128 {
                return false;
            }
            if prefix_len == 0 {
                return true;
            }
            let mask = u128::MAX << (128 - prefix_len);
            (u128::from(ip6) & mask) == (u128::from(net6) & mask)
        }
        _ => false, // mismatched IP versions
    }
}

/// Load allowed IP ranges for a tenant from the database.
async fn load_allowed_ips(db: &PgPool, tenant_id: uuid::Uuid) -> Result<Vec<String>, AppError> {
    let json: Option<serde_json::Value> =
        sqlx::query_scalar("SELECT allowed_ips FROM tenants WHERE id = $1")
            .bind(tenant_id)
            .fetch_optional(db)
            .await?;

    let Some(val) = json else {
        return Ok(Vec::new());
    };

    Ok(val
        .as_array()
        .map(|a| {
            a.iter()
                .filter_map(serde_json::Value::as_str)
                .map(String::from)
                .collect()
        })
        .unwrap_or_default())
}

/// Middleware that enforces tenant IP restrictions.
///
/// Must run after auth middleware (requires Claims in extensions).
/// Bypass roles (`super_admin`) are not restricted.
pub async fn ip_restrict_middleware(
    State(state): State<AppState>,
    request: Request,
    next: Next,
) -> Result<Response, AppError> {
    // Only check if we have authenticated claims
    let Some(claims) = request.extensions().get::<Claims>().cloned() else {
        return Ok(next.run(request).await);
    };

    // Bypass roles skip IP checks
    if super::authorization::is_bypass_role(&claims) {
        return Ok(next.run(request).await);
    }

    let client_ip = extract_ip(&request);

    let Some(ip) = client_ip else {
        return Ok(next.run(request).await);
    };

    let allowed = load_allowed_ips(&state.db, claims.tenant_id).await?;

    // Empty list = no restriction
    if allowed.is_empty() {
        return Ok(next.run(request).await);
    }

    if allowed.iter().any(|cidr| ip_in_cidr(ip, cidr)) {
        Ok(next.run(request).await)
    } else {
        Err(AppError::Forbidden)
    }
}

/// Extract client IP from request headers/extensions.
fn extract_ip(request: &Request) -> Option<IpAddr> {
    if let Some(ci) = request
        .extensions()
        .get::<ConnectInfo<std::net::SocketAddr>>()
    {
        return Some(ci.0.ip());
    }

    if let Some(fwd) = request
        .headers()
        .get("x-forwarded-for")
        .and_then(|v| v.to_str().ok())
    {
        if let Some(first) = fwd.split(',').next() {
            if let Ok(ip) = first.trim().parse::<IpAddr>() {
                return Some(ip);
            }
        }
    }

    if let Some(real) = request
        .headers()
        .get("x-real-ip")
        .and_then(|v| v.to_str().ok())
    {
        if let Ok(ip) = real.trim().parse::<IpAddr>() {
            return Some(ip);
        }
    }

    None
}
