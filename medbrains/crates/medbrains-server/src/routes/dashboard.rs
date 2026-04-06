#![allow(clippy::too_many_lines)]

use axum::{Extension, Json, extract::{Path, State}};
use chrono::Utc;
use medbrains_core::dashboard::{
    Dashboard, DashboardSummary, DashboardWidget, DashboardWithWidgets, WidgetTemplate, WidgetType,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    error::AppError,
    middleware::{auth::Claims, authorization::{is_bypass_role, require_permission}},
    state::AppState,
};

// ══════════════════════════════════════════════════════════
//  Department data filter resolution
// ══════════════════════════════════════════════════════════

/// Resolved department filter for a widget query.
struct DataFilters {
    /// Effective department IDs to filter by. Empty = no filtering.
    department_ids: Vec<Uuid>,
}

/// Resolve the effective data filters for a widget, merging the widget's
/// `data_filters` config with the viewer's JWT claims.
fn resolve_data_filters(widget: &DashboardWidget, claims: &Claims) -> DataFilters {
    let scope = widget
        .data_filters
        .get("scope")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("auto");

    match scope {
        "all" => {
            // No department filtering — hospital-wide view
            DataFilters {
                department_ids: Vec::new(),
            }
        }
        "custom" => {
            // Use widget-configured department IDs, intersected with user's departments
            // for non-bypass roles (security: users cannot widen their own access).
            let widget_dept_ids: Vec<Uuid> = widget
                .data_filters
                .get("department_ids")
                .and_then(serde_json::Value::as_array)
                .map(|arr| {
                    arr.iter()
                        .filter_map(|v| v.as_str().and_then(|s| s.parse::<Uuid>().ok()))
                        .collect()
                })
                .unwrap_or_default();

            if is_bypass_role(claims) || claims.department_ids.is_empty() {
                DataFilters {
                    department_ids: widget_dept_ids,
                }
            } else {
                // Intersect: only keep widget departments that the user actually has access to
                let intersected: Vec<Uuid> = widget_dept_ids
                    .into_iter()
                    .filter(|d| claims.department_ids.contains(d))
                    .collect();
                DataFilters {
                    department_ids: intersected,
                }
            }
        }
        // "auto" and any other value — use the viewer's own departments
        _ => {
            if is_bypass_role(claims) {
                // Bypass roles see everything
                DataFilters {
                    department_ids: Vec::new(),
                }
            } else {
                DataFilters {
                    department_ids: claims.department_ids.clone(),
                }
            }
        }
    }
}

// ══════════════════════════════════════════════════════════
//  Request / Response types
// ══════════════════════════════════════════════════════════

#[derive(Debug, Deserialize)]
pub struct CreateDashboardRequest {
    pub name: String,
    pub code: String,
    pub description: Option<String>,
    pub role_codes: Option<Vec<String>>,
    pub department_ids: Option<Vec<Uuid>>,
    pub layout_config: Option<serde_json::Value>,
    pub is_default: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateDashboardRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub role_codes: Option<Vec<String>>,
    pub department_ids: Option<Vec<Uuid>>,
    pub layout_config: Option<serde_json::Value>,
    pub is_default: Option<bool>,
    pub is_active: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct CreateWidgetRequest {
    pub widget_type: WidgetType,
    pub title: String,
    pub subtitle: Option<String>,
    pub icon: Option<String>,
    pub color: Option<String>,
    pub config: Option<serde_json::Value>,
    pub data_source: Option<serde_json::Value>,
    pub data_filters: Option<serde_json::Value>,
    pub position_x: Option<i32>,
    pub position_y: Option<i32>,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub refresh_interval: Option<i32>,
    pub permission_code: Option<String>,
    pub template_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateWidgetRequest {
    pub title: Option<String>,
    pub subtitle: Option<String>,
    pub icon: Option<String>,
    pub color: Option<String>,
    pub config: Option<serde_json::Value>,
    pub data_source: Option<serde_json::Value>,
    pub data_filters: Option<serde_json::Value>,
    pub position_x: Option<i32>,
    pub position_y: Option<i32>,
    pub width: Option<i32>,
    pub height: Option<i32>,
    pub refresh_interval: Option<i32>,
    pub is_visible: Option<bool>,
    pub permission_code: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateLayoutRequest {
    pub widgets: Vec<WidgetLayoutItem>,
}

#[derive(Debug, Deserialize)]
pub struct WidgetLayoutItem {
    pub id: Uuid,
    pub position_x: i32,
    pub position_y: i32,
    pub width: i32,
    pub height: i32,
}

#[derive(Debug, Deserialize)]
pub struct BatchWidgetDataRequest {
    pub widget_ids: Vec<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct WidgetDataResponse {
    pub widget_id: Uuid,
    pub data: serde_json::Value,
    pub fetched_at: String,
}

#[derive(Debug, Deserialize)]
pub struct PersonalizeDashboardRequest {
    pub source_dashboard_id: Uuid,
    pub name: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreateWidgetTemplateRequest {
    pub name: String,
    pub description: Option<String>,
    pub widget_type: WidgetType,
    pub icon: Option<String>,
    pub color: Option<String>,
    pub default_config: Option<serde_json::Value>,
    pub default_source: Option<serde_json::Value>,
    pub default_width: Option<i32>,
    pub default_height: Option<i32>,
    pub category: Option<String>,
}

// ══════════════════════════════════════════════════════════
//  User-Facing Endpoints
// ══════════════════════════════════════════════════════════

/// GET /api/dashboards — list dashboards visible to the current user.
///
/// Gating rules (all applied):
/// - Role: `role_codes` is empty (all roles) or contains user's role
/// - Department: `department_ids` is empty (all depts) or overlaps with user's departments
/// - User: `user_id` is NULL (shared) or matches the current user
pub async fn list_dashboards(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
) -> Result<Json<Vec<DashboardSummary>>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let role = &claims.role;
    let dept_ids = serde_json::to_value(&claims.department_ids)
        .unwrap_or(serde_json::json!([]));

    let rows = sqlx::query_as::<_, DashboardSummary>(
        "SELECT d.id, d.name, d.code, d.description, d.is_default, d.role_codes,
                d.department_ids, d.user_id, d.is_active,
                (SELECT COUNT(*) FROM dashboard_widgets dw WHERE dw.dashboard_id = d.id) AS widget_count,
                d.created_at
         FROM dashboards d
         WHERE d.is_active = true
           AND (d.user_id IS NULL OR d.user_id = $1)
           AND (d.role_codes = '[]'::jsonb OR d.role_codes @> $2::jsonb)
           AND (d.department_ids = '[]'::jsonb OR d.department_ids ?| ARRAY(SELECT jsonb_array_elements_text($3)))
         ORDER BY d.user_id IS NOT NULL DESC, d.is_default DESC, d.name",
    )
    .bind(claims.sub)
    .bind(serde_json::json!([role]))
    .bind(&dept_ids)
    .fetch_all(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(rows))
}

/// GET /api/dashboards/my — get the user's active dashboard.
///
/// Resolution chain (first match wins):
/// 1. User-specific personal dashboard (`user_id` = current user)
/// 2. Department-matched dashboard (`department_ids` overlaps user's departments + role match)
/// 3. Role-matched dashboard (`role_codes` contains user's role)
/// 4. Default dashboard (`is_default = true` or `role_codes = []`)
pub async fn get_my_dashboard(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
) -> Result<Json<DashboardWithWidgets>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let role = &claims.role;
    let dept_ids = serde_json::to_value(&claims.department_ids)
        .unwrap_or(serde_json::json!([]));

    // 1. User-specific personal dashboard
    let dashboard = sqlx::query_as::<_, Dashboard>(
        "SELECT * FROM dashboards
         WHERE is_active = true AND user_id = $1
         ORDER BY updated_at DESC LIMIT 1",
    )
    .bind(claims.sub)
    .fetch_optional(&mut *tx)
    .await?;

    // 2. Department + role matched dashboard
    let dashboard = match dashboard {
        Some(d) => Some(d),
        None => sqlx::query_as::<_, Dashboard>(
            "SELECT * FROM dashboards
             WHERE is_active = true AND user_id IS NULL
               AND department_ids != '[]'::jsonb
               AND department_ids ?| ARRAY(SELECT jsonb_array_elements_text($1))
               AND (role_codes = '[]'::jsonb OR role_codes @> $2::jsonb)
             ORDER BY is_default DESC LIMIT 1",
        )
        .bind(&dept_ids)
        .bind(serde_json::json!([role]))
        .fetch_optional(&mut *tx)
        .await?,
    };

    // 3. Role-matched dashboard
    let dashboard = match dashboard {
        Some(d) => Some(d),
        None => sqlx::query_as::<_, Dashboard>(
            "SELECT * FROM dashboards
             WHERE is_active = true AND user_id IS NULL
               AND department_ids = '[]'::jsonb
               AND role_codes @> $1::jsonb
             ORDER BY is_default DESC LIMIT 1",
        )
        .bind(serde_json::json!([role]))
        .fetch_optional(&mut *tx)
        .await?,
    };

    // 4. Default dashboard
    let dashboard = match dashboard {
        Some(d) => d,
        None => sqlx::query_as::<_, Dashboard>(
            "SELECT * FROM dashboards
             WHERE is_active = true AND user_id IS NULL
               AND (role_codes = '[]'::jsonb OR is_default = true)
             ORDER BY is_default DESC LIMIT 1",
        )
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(AppError::NotFound)?,
    };

    let widgets = fetch_visible_widgets(&mut tx, dashboard.id, &claims).await?;

    tx.commit().await?;
    Ok(Json(DashboardWithWidgets { dashboard, widgets }))
}

/// POST /api/dashboards/my/personalize — clone a shared dashboard as a personal copy.
pub async fn personalize_dashboard(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Json(req): Json<PersonalizeDashboardRequest>,
) -> Result<Json<DashboardWithWidgets>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let source = sqlx::query_as::<_, Dashboard>(
        "SELECT * FROM dashboards WHERE id = $1",
    )
    .bind(req.source_dashboard_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    let new_code = format!("personal_{}_{}", claims.sub, Utc::now().timestamp());

    let personal = sqlx::query_as::<_, Dashboard>(
        "INSERT INTO dashboards (tenant_id, user_id, name, code, description,
                is_default, role_codes, department_ids, layout_config, created_by, cloned_from)
         VALUES ($1, $2, $3, $4, $5, false, '[]'::jsonb, '[]'::jsonb, $6, $2, $7)
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(claims.sub)
    .bind(req.name.as_deref().unwrap_or(&source.name))
    .bind(&new_code)
    .bind(&source.description)
    .bind(&source.layout_config)
    .bind(source.id)
    .fetch_one(&mut *tx)
    .await?;

    // Copy all widgets
    sqlx::query(
        "INSERT INTO dashboard_widgets (dashboard_id, widget_type, title, subtitle, icon, color,
                config, data_source, data_filters, position_x, position_y, width, height,
                min_width, min_height, refresh_interval, is_visible, permission_code, sort_order)
         SELECT $1, widget_type, title, subtitle, icon, color,
                config, data_source, data_filters, position_x, position_y, width, height,
                min_width, min_height, refresh_interval, is_visible, permission_code, sort_order
         FROM dashboard_widgets WHERE dashboard_id = $2",
    )
    .bind(personal.id)
    .bind(source.id)
    .execute(&mut *tx)
    .await?;

    let widgets = fetch_visible_widgets(&mut tx, personal.id, &claims).await?;

    tx.commit().await?;
    Ok(Json(DashboardWithWidgets { dashboard: personal, widgets }))
}

/// GET /api/dashboards/{id} — get dashboard with all widgets.
pub async fn get_dashboard(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<DashboardWithWidgets>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let dashboard = sqlx::query_as::<_, Dashboard>(
        "SELECT * FROM dashboards WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    let widgets = fetch_visible_widgets(&mut tx, dashboard.id, &claims).await?;

    tx.commit().await?;
    Ok(Json(DashboardWithWidgets { dashboard, widgets }))
}

// ══════════════════════════════════════════════════════════
//  Admin Endpoints — Dashboard CRUD
// ══════════════════════════════════════════════════════════

/// POST /api/admin/dashboards — create a dashboard.
pub async fn admin_create_dashboard(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Json(req): Json<CreateDashboardRequest>,
) -> Result<Json<Dashboard>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let role_codes = serde_json::to_value(req.role_codes.unwrap_or_default())
        .unwrap_or(serde_json::json!([]));
    let department_ids = serde_json::to_value(req.department_ids.unwrap_or_default())
        .unwrap_or(serde_json::json!([]));
    let layout_config = req.layout_config.unwrap_or_else(||
        serde_json::json!({"columns": 12, "row_height": 80, "gap": 16})
    );

    let dashboard = sqlx::query_as::<_, Dashboard>(
        "INSERT INTO dashboards (tenant_id, name, code, description, is_default,
                role_codes, department_ids, layout_config, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(&req.name)
    .bind(&req.code)
    .bind(&req.description)
    .bind(req.is_default.unwrap_or(false))
    .bind(&role_codes)
    .bind(&department_ids)
    .bind(&layout_config)
    .bind(claims.sub)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(dashboard))
}

/// PUT /api/admin/dashboards/{id} — update dashboard metadata.
pub async fn admin_update_dashboard(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    Json(req): Json<UpdateDashboardRequest>,
) -> Result<Json<Dashboard>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let existing = sqlx::query_as::<_, Dashboard>(
        "SELECT * FROM dashboards WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    let name = req.name.unwrap_or(existing.name);
    let description = req.description.or(existing.description);
    let role_codes = req
        .role_codes
        .map(|rc| serde_json::to_value(rc).unwrap_or(serde_json::json!([])))
        .unwrap_or(existing.role_codes);
    let department_ids = req
        .department_ids
        .map(|d| serde_json::to_value(d).unwrap_or(serde_json::json!([])))
        .unwrap_or(existing.department_ids);
    let layout_config = req.layout_config.unwrap_or(existing.layout_config);
    let is_default = req.is_default.unwrap_or(existing.is_default);
    let is_active = req.is_active.unwrap_or(existing.is_active);

    let updated = sqlx::query_as::<_, Dashboard>(
        "UPDATE dashboards SET name = $1, description = $2, role_codes = $3,
                department_ids = $4, layout_config = $5, is_default = $6, is_active = $7,
                updated_at = now()
         WHERE id = $8 RETURNING *",
    )
    .bind(&name)
    .bind(&description)
    .bind(&role_codes)
    .bind(&department_ids)
    .bind(&layout_config)
    .bind(is_default)
    .bind(is_active)
    .bind(id)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(updated))
}

/// DELETE /api/admin/dashboards/{id} — delete dashboard and all widgets.
pub async fn admin_delete_dashboard(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let result = sqlx::query("DELETE FROM dashboards WHERE id = $1")
        .bind(id)
        .execute(&mut *tx)
        .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound);
    }

    tx.commit().await?;
    Ok(Json(serde_json::json!({"status": "deleted"})))
}

/// POST /api/admin/dashboards/{id}/duplicate — clone dashboard with all widgets.
pub async fn admin_duplicate_dashboard(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Dashboard>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let source = sqlx::query_as::<_, Dashboard>(
        "SELECT * FROM dashboards WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    let new_code = format!("{}_copy_{}", source.code, Utc::now().timestamp());

    let new_dash = sqlx::query_as::<_, Dashboard>(
        "INSERT INTO dashboards (tenant_id, name, code, description, is_default,
                role_codes, department_ids, layout_config, created_by, cloned_from)
         VALUES ($1, $2, $3, $4, false, $5, $6, $7, $8, $9)
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(format!("{} (Copy)", source.name))
    .bind(&new_code)
    .bind(&source.description)
    .bind(&source.role_codes)
    .bind(&source.department_ids)
    .bind(&source.layout_config)
    .bind(claims.sub)
    .bind(source.id)
    .fetch_one(&mut *tx)
    .await?;

    // Copy all widgets
    sqlx::query(
        "INSERT INTO dashboard_widgets (dashboard_id, widget_type, title, subtitle, icon, color,
                config, data_source, data_filters, position_x, position_y, width, height,
                min_width, min_height, refresh_interval, is_visible, permission_code, sort_order)
         SELECT $1, widget_type, title, subtitle, icon, color,
                config, data_source, data_filters, position_x, position_y, width, height,
                min_width, min_height, refresh_interval, is_visible, permission_code, sort_order
         FROM dashboard_widgets WHERE dashboard_id = $2",
    )
    .bind(new_dash.id)
    .bind(id)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(new_dash))
}

// ══════════════════════════════════════════════════════════
//  Admin Endpoints — Widget CRUD
// ══════════════════════════════════════════════════════════

/// POST /api/admin/dashboards/{id}/widgets — add widget to dashboard.
pub async fn admin_add_widget(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path(dashboard_id): Path<Uuid>,
    Json(req): Json<CreateWidgetRequest>,
) -> Result<Json<DashboardWidget>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    // Verify dashboard exists
    let exists = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM dashboards WHERE id = $1)",
    )
    .bind(dashboard_id)
    .fetch_one(&mut *tx)
    .await?;

    if !exists {
        return Err(AppError::NotFound);
    }

    // If a template_id was provided, merge defaults
    let (config, data_source, width, height, icon, color) = if let Some(tid) = req.template_id {
        let tmpl = sqlx::query_as::<_, WidgetTemplate>(
            "SELECT * FROM widget_templates WHERE id = $1",
        )
        .bind(tid)
        .fetch_optional(&mut *tx)
        .await?
        .ok_or(AppError::BadRequest("invalid template_id".to_owned()))?;

        (
            req.config.unwrap_or(tmpl.default_config),
            req.data_source.unwrap_or(tmpl.default_source),
            req.width.unwrap_or(tmpl.default_width),
            req.height.unwrap_or(tmpl.default_height),
            req.icon.or(tmpl.icon),
            req.color.or(tmpl.color),
        )
    } else {
        (
            req.config.unwrap_or_else(|| serde_json::json!({})),
            req.data_source.unwrap_or_else(|| serde_json::json!({})),
            req.width.unwrap_or(4),
            req.height.unwrap_or(2),
            req.icon,
            req.color,
        )
    };

    let data_filters = req
        .data_filters
        .unwrap_or_else(|| serde_json::json!({}));

    let widget = sqlx::query_as::<_, DashboardWidget>(
        "INSERT INTO dashboard_widgets
            (dashboard_id, widget_type, title, subtitle, icon, color,
             config, data_source, data_filters, position_x, position_y, width, height,
             refresh_interval, permission_code)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
         RETURNING *",
    )
    .bind(dashboard_id)
    .bind(req.widget_type)
    .bind(&req.title)
    .bind(&req.subtitle)
    .bind(&icon)
    .bind(&color)
    .bind(&config)
    .bind(&data_source)
    .bind(&data_filters)
    .bind(req.position_x.unwrap_or(0))
    .bind(req.position_y.unwrap_or(0))
    .bind(width)
    .bind(height)
    .bind(req.refresh_interval)
    .bind(&req.permission_code)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(widget))
}

/// PUT `/api/admin/dashboards/{dashboard_id}/widgets/{wid}` — update widget.
pub async fn admin_update_widget(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path((dashboard_id, wid)): Path<(Uuid, Uuid)>,
    Json(req): Json<UpdateWidgetRequest>,
) -> Result<Json<DashboardWidget>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let existing = sqlx::query_as::<_, DashboardWidget>(
        "SELECT * FROM dashboard_widgets WHERE id = $1 AND dashboard_id = $2",
    )
    .bind(wid)
    .bind(dashboard_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    let updated = sqlx::query_as::<_, DashboardWidget>(
        "UPDATE dashboard_widgets SET
            title = $1, subtitle = $2, icon = $3, color = $4,
            config = $5, data_source = $6, data_filters = $7,
            position_x = $8, position_y = $9, width = $10, height = $11,
            refresh_interval = $12, is_visible = $13, permission_code = $14,
            updated_at = now()
         WHERE id = $15 RETURNING *",
    )
    .bind(req.title.as_deref().unwrap_or(&existing.title))
    .bind(req.subtitle.as_ref().or(existing.subtitle.as_ref()))
    .bind(req.icon.as_ref().or(existing.icon.as_ref()))
    .bind(req.color.as_ref().or(existing.color.as_ref()))
    .bind(req.config.as_ref().unwrap_or(&existing.config))
    .bind(req.data_source.as_ref().unwrap_or(&existing.data_source))
    .bind(req.data_filters.as_ref().unwrap_or(&existing.data_filters))
    .bind(req.position_x.unwrap_or(existing.position_x))
    .bind(req.position_y.unwrap_or(existing.position_y))
    .bind(req.width.unwrap_or(existing.width))
    .bind(req.height.unwrap_or(existing.height))
    .bind(req.refresh_interval.or(existing.refresh_interval))
    .bind(req.is_visible.unwrap_or(existing.is_visible))
    .bind(req.permission_code.as_ref().or(existing.permission_code.as_ref()))
    .bind(wid)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(updated))
}

/// DELETE `/api/admin/dashboards/{dashboard_id}/widgets/{wid}` — remove widget.
pub async fn admin_delete_widget(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path((dashboard_id, wid)): Path<(Uuid, Uuid)>,
) -> Result<Json<serde_json::Value>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let result = sqlx::query(
        "DELETE FROM dashboard_widgets WHERE id = $1 AND dashboard_id = $2",
    )
    .bind(wid)
    .bind(dashboard_id)
    .execute(&mut *tx)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound);
    }

    tx.commit().await?;
    Ok(Json(serde_json::json!({"status": "deleted"})))
}

/// PUT /api/admin/dashboards/{id}/layout — batch update widget positions.
pub async fn admin_update_layout(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path(dashboard_id): Path<Uuid>,
    Json(req): Json<UpdateLayoutRequest>,
) -> Result<Json<serde_json::Value>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    for item in &req.widgets {
        sqlx::query(
            "UPDATE dashboard_widgets
             SET position_x = $1, position_y = $2, width = $3, height = $4, updated_at = now()
             WHERE id = $5 AND dashboard_id = $6",
        )
        .bind(item.position_x)
        .bind(item.position_y)
        .bind(item.width)
        .bind(item.height)
        .bind(item.id)
        .bind(dashboard_id)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;
    Ok(Json(serde_json::json!({"status": "updated", "count": req.widgets.len()})))
}

// ══════════════════════════════════════════════════════════
//  Admin Endpoints — Widget Templates
// ══════════════════════════════════════════════════════════

/// GET /api/admin/widget-templates — list templates (system + tenant).
pub async fn admin_list_widget_templates(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
) -> Result<Json<Vec<WidgetTemplate>>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let rows = sqlx::query_as::<_, WidgetTemplate>(
        "SELECT * FROM widget_templates
         ORDER BY is_system DESC, category, name",
    )
    .fetch_all(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(rows))
}

/// GET /api/widget-templates — list templates visible to the current user.
///
/// Gating rules (all applied, in order of precedence):
/// 1. Widget access: user override → role default → template-level check
/// 2. Permission: `required_permissions` is empty or user has ALL listed permissions
/// 3. Department: `required_departments` is empty or overlaps user's departments
pub async fn list_widget_templates(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
) -> Result<Json<Vec<WidgetTemplate>>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let all = sqlx::query_as::<_, WidgetTemplate>(
        "SELECT * FROM widget_templates
         ORDER BY is_system DESC, category, name",
    )
    .fetch_all(&mut *tx)
    .await?;

    // Fetch role's widget_access_defaults
    let role_widget_access = sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT COALESCE(widget_access_defaults, '{}'::jsonb) \
         FROM roles WHERE tenant_id = $1 AND code = $2",
    )
    .bind(claims.tenant_id)
    .bind(&claims.role)
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or_else(|| serde_json::json!({}));

    // Fetch user's widget_access from access_matrix
    let user_widget_access = sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT COALESCE(access_matrix->'widget_access', '{}'::jsonb) \
         FROM users WHERE id = $1 AND tenant_id = $2",
    )
    .bind(claims.sub)
    .bind(claims.tenant_id)
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or_else(|| serde_json::json!({}));

    tx.commit().await?;

    let is_bypass = is_bypass_role(&claims);
    let filtered: Vec<WidgetTemplate> = all
        .into_iter()
        .filter(|t| {
            if is_bypass {
                return true;
            }

            let tid = t.id.to_string();

            // 1. Widget access resolution: user override → role default → template permissions
            //    "visible" = allowed, "hidden" = denied
            if let Some(user_level) = user_widget_access.get(&tid).and_then(|v| v.as_str()) {
                if user_level == "hidden" {
                    return false;
                }
                if user_level == "visible" {
                    return true;
                }
            }

            if let Some(role_level) = role_widget_access.get(&tid).and_then(|v| v.as_str()) {
                if role_level == "hidden" {
                    return false;
                }
                if role_level == "visible" {
                    return true;
                }
            }

            // 2. Permission gate: user must have ALL required permissions
            let perms_ok = match t.required_permissions.as_array() {
                Some(arr) if !arr.is_empty() => arr.iter().all(|p| {
                    p.as_str()
                        .is_some_and(|code| claims.permissions.iter().any(|cp| cp == code))
                }),
                _ => true,
            };

            // 3. Department gate: user must belong to at least one required department
            let dept_ok = match t.required_departments.as_array() {
                Some(arr) if !arr.is_empty() => arr.iter().any(|d| {
                    d.as_str().is_some_and(|did| {
                        claims
                            .department_ids
                            .iter()
                            .any(|ud| ud.to_string() == did)
                    })
                }),
                _ => true,
            };

            perms_ok && dept_ok
        })
        .collect();

    Ok(Json(filtered))
}

/// POST /api/admin/widget-templates — create custom template.
pub async fn admin_create_widget_template(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Json(req): Json<CreateWidgetTemplateRequest>,
) -> Result<Json<WidgetTemplate>, AppError> {
    require_permission(&claims, medbrains_core::permissions::admin::settings::general::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let empty_json = serde_json::json!({});
    let config = req.default_config.as_ref().unwrap_or(&empty_json);
    let source = req.default_source.as_ref().unwrap_or(&empty_json);

    let tmpl = sqlx::query_as::<_, WidgetTemplate>(
        "INSERT INTO widget_templates (tenant_id, name, description, widget_type, icon, color,
                default_config, default_source, default_width, default_height, category, is_system)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, false)
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(&req.name)
    .bind(&req.description)
    .bind(req.widget_type)
    .bind(&req.icon)
    .bind(&req.color)
    .bind(config)
    .bind(source)
    .bind(req.default_width.unwrap_or(4))
    .bind(req.default_height.unwrap_or(2))
    .bind(req.category.as_deref().unwrap_or("general"))
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(tmpl))
}

// ══════════════════════════════════════════════════════════
//  Widget Data Resolver
// ══════════════════════════════════════════════════════════

/// GET /api/dashboard/widget-data/{widget_id} — fetch data for a single widget.
pub async fn get_widget_data(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Path(widget_id): Path<Uuid>,
) -> Result<Json<WidgetDataResponse>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let widget = sqlx::query_as::<_, DashboardWidget>(
        "SELECT dw.* FROM dashboard_widgets dw
         JOIN dashboards d ON d.id = dw.dashboard_id
         WHERE dw.id = $1",
    )
    .bind(widget_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    // Set full department context based on widget's data_filters + viewer claims
    let filters = resolve_data_filters(&widget, &claims);
    medbrains_db::pool::set_full_context(&mut tx, &claims.tenant_id, &filters.department_ids)
        .await?;

    let data = resolve_widget_data(&mut tx, &widget, &filters).await?;

    tx.commit().await?;
    Ok(Json(WidgetDataResponse {
        widget_id,
        data,
        fetched_at: Utc::now().to_rfc3339(),
    }))
}

/// POST /api/dashboard/widget-data/batch — batch-fetch data for multiple widgets.
pub async fn batch_widget_data(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
    Json(req): Json<BatchWidgetDataRequest>,
) -> Result<Json<Vec<WidgetDataResponse>>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let widgets = sqlx::query_as::<_, DashboardWidget>(
        "SELECT dw.* FROM dashboard_widgets dw
         JOIN dashboards d ON d.id = dw.dashboard_id
         WHERE dw.id = ANY($1)",
    )
    .bind(&req.widget_ids)
    .fetch_all(&mut *tx)
    .await?;

    let fetched_at = Utc::now().to_rfc3339();
    let mut results = Vec::with_capacity(widgets.len());

    for widget in &widgets {
        // Re-set department context per widget (each widget may have different scope)
        let filters = resolve_data_filters(widget, &claims);
        medbrains_db::pool::set_full_context(
            &mut tx,
            &claims.tenant_id,
            &filters.department_ids,
        )
        .await?;

        let data = resolve_widget_data(&mut tx, widget, &filters).await?;
        results.push(WidgetDataResponse {
            widget_id: widget.id,
            data,
            fetched_at: fetched_at.clone(),
        });
    }

    tx.commit().await?;
    Ok(Json(results))
}

// ══════════════════════════════════════════════════════════
//  Internal Helpers
// ══════════════════════════════════════════════════════════

/// Fetch widgets for a dashboard, filtering by user permissions.
async fn fetch_visible_widgets(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    dashboard_id: Uuid,
    claims: &Claims,
) -> Result<Vec<DashboardWidget>, AppError> {
    let all_widgets = sqlx::query_as::<_, DashboardWidget>(
        "SELECT * FROM dashboard_widgets
         WHERE dashboard_id = $1 AND is_visible = true
         ORDER BY sort_order, position_y, position_x",
    )
    .bind(dashboard_id)
    .fetch_all(&mut **tx)
    .await?;

    // Filter by permission_code if set
    let is_bypass = is_bypass_role(claims);
    let visible: Vec<DashboardWidget> = all_widgets
        .into_iter()
        .filter(|w| {
            w.permission_code.as_ref().is_none_or(|perm| {
                is_bypass || claims.permissions.iter().any(|p| p == perm)
            })
        })
        .collect();

    Ok(visible)
}

/// Resolve widget data based on its `data_source` configuration.
async fn resolve_widget_data(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    widget: &DashboardWidget,
    filters: &DataFilters,
) -> Result<serde_json::Value, AppError> {
    let source = &widget.data_source;

    let source_type = source
        .get("type")
        .and_then(serde_json::Value::as_str)
        .unwrap_or("static");

    match source_type {
        "module_query" => {
            let module = source.get("module").and_then(serde_json::Value::as_str).unwrap_or("");
            let query = source.get("query").and_then(serde_json::Value::as_str).unwrap_or("");
            let params = source.get("params").cloned().unwrap_or_else(|| serde_json::json!({}));

            resolve_module_query(tx, module, query, &params, filters).await
        }
        "static" => {
            Ok(source.get("static_data").cloned().unwrap_or(serde_json::json!(null)))
        }
        _ => Ok(serde_json::json!({"error": "unsupported data source type"})),
    }
}

/// Module-specific data resolvers.
///
/// Tables with `department_id` (`opd_queues`, `encounters`) are auto-filtered by
/// RLS via `set_full_context()`. Tables without it (`lab_orders`, `invoices`,
/// `admissions`) use JOIN-based filtering through `encounters.department_id`.
/// `patients` are hospital-wide — intentionally unscoped.
#[allow(clippy::match_same_arms)]
async fn resolve_module_query(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    module: &str,
    query: &str,
    params: &serde_json::Value,
    filters: &DataFilters,
) -> Result<serde_json::Value, AppError> {
    let has_dept_filter = !filters.department_ids.is_empty();

    match (module, query) {
        // ── Patients (hospital-wide — no department scoping) ──
        ("patients", "count") => {
            let count = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM patients WHERE is_active = true",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(serde_json::json!({"value": count, "label": "Total Patients"}))
        }
        ("patients", "today_count") => {
            let count = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM patients WHERE created_at >= CURRENT_DATE",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(serde_json::json!({"value": count, "label": "Today's Registrations"}))
        }
        ("patients", "recent_registrations") => {
            let limit = params.get("limit").and_then(serde_json::Value::as_i64).unwrap_or(5);
            let rows = sqlx::query_as::<_, PatientRow>(
                "SELECT id, uhid, first_name, last_name, created_at
                 FROM patients WHERE is_active = true
                 ORDER BY created_at DESC LIMIT $1",
            )
            .bind(limit)
            .fetch_all(&mut **tx)
            .await?;
            Ok(serde_json::json!({"items": rows}))
        }

        // ── OPD (opd_queues has department_id — RLS auto-filters) ──
        ("opd", "queue_count") => {
            // opd_queues has department_id → RLS auto-filters
            let count = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM opd_queues
                 WHERE status = 'waiting' AND queue_date = CURRENT_DATE",
            )
            .fetch_optional(&mut **tx)
            .await?
            .unwrap_or(0);
            Ok(serde_json::json!({"value": count, "label": "OPD Queue"}))
        }
        ("opd", "today_visits") => {
            // encounters has department_id → RLS auto-filters
            let count = sqlx::query_scalar::<_, i64>(
                "SELECT COUNT(*) FROM encounters
                 WHERE encounter_type = 'opd' AND encounter_date = CURRENT_DATE",
            )
            .fetch_optional(&mut **tx)
            .await?
            .unwrap_or(0);
            Ok(serde_json::json!({"value": count, "label": "Today's Visits"}))
        }
        ("opd", "active_tokens") => {
            let limit = params.get("limit").and_then(serde_json::Value::as_i64).unwrap_or(10);
            // opd_queues has department_id → RLS auto-filters
            let rows = sqlx::query_as::<_, OpdTokenRow>(
                "SELECT q.id, q.token_number AS token_no,
                        p.first_name || ' ' || p.last_name AS patient_name,
                        u.full_name AS doctor_name,
                        q.status::text
                 FROM opd_queues q
                 JOIN encounters e ON e.id = q.encounter_id
                 JOIN patients p ON p.id = e.patient_id
                 LEFT JOIN users u ON u.id = q.doctor_id
                 WHERE q.queue_date = CURRENT_DATE
                 ORDER BY q.token_number LIMIT $1",
            )
            .bind(limit)
            .fetch_all(&mut **tx)
            .await?;
            Ok(serde_json::json!({"items": rows}))
        }

        // ── Lab (lab_orders has no department_id — JOIN through encounters) ──
        ("lab", "pending_count") => {
            let count = if has_dept_filter {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM lab_orders lo
                     JOIN encounters e ON e.id = lo.encounter_id
                     WHERE lo.status = 'pending'
                       AND e.department_id = ANY($1)",
                )
                .bind(&filters.department_ids)
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM lab_orders WHERE status = 'pending'",
                )
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            };
            Ok(serde_json::json!({"value": count, "label": "Lab Pending"}))
        }
        ("lab", "today_completed") => {
            let count = if has_dept_filter {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM lab_orders lo
                     JOIN encounters e ON e.id = lo.encounter_id
                     WHERE lo.status = 'completed' AND lo.updated_at >= CURRENT_DATE
                       AND e.department_id = ANY($1)",
                )
                .bind(&filters.department_ids)
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM lab_orders
                     WHERE status = 'completed' AND updated_at >= CURRENT_DATE",
                )
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            };
            Ok(serde_json::json!({"value": count, "label": "Completed Today"}))
        }
        ("lab", "recent_results") => {
            let limit = params.get("limit").and_then(serde_json::Value::as_i64).unwrap_or(5);
            let rows = if has_dept_filter {
                sqlx::query_as::<_, LabResultRow>(
                    "SELECT lo.id, p.first_name || ' ' || p.last_name AS patient_name,
                            lo.status::text, lo.updated_at
                     FROM lab_orders lo
                     JOIN encounters e ON e.id = lo.encounter_id
                     JOIN patients p ON p.id = lo.patient_id
                     WHERE e.department_id = ANY($1)
                     ORDER BY lo.updated_at DESC LIMIT $2",
                )
                .bind(&filters.department_ids)
                .bind(limit)
                .fetch_all(&mut **tx)
                .await?
            } else {
                sqlx::query_as::<_, LabResultRow>(
                    "SELECT lo.id, p.first_name || ' ' || p.last_name AS patient_name,
                            lo.status::text, lo.updated_at
                     FROM lab_orders lo
                     JOIN patients p ON p.id = lo.patient_id
                     ORDER BY lo.updated_at DESC LIMIT $1",
                )
                .bind(limit)
                .fetch_all(&mut **tx)
                .await?
            };
            Ok(serde_json::json!({"items": rows}))
        }

        // ── Billing (invoices has no department_id — JOIN through encounters) ──
        ("billing", "today_revenue") => {
            let total = if has_dept_filter {
                sqlx::query_scalar::<_, Option<rust_decimal::Decimal>>(
                    "SELECT SUM(i.total_amount) FROM invoices i
                     JOIN encounters e ON e.id = i.encounter_id
                     WHERE i.created_at >= CURRENT_DATE AND i.status != 'cancelled'
                       AND e.department_id = ANY($1)",
                )
                .bind(&filters.department_ids)
                .fetch_optional(&mut **tx)
                .await?
                .flatten()
                .unwrap_or_default()
            } else {
                sqlx::query_scalar::<_, Option<rust_decimal::Decimal>>(
                    "SELECT SUM(total_amount) FROM invoices
                     WHERE created_at >= CURRENT_DATE AND status != 'cancelled'",
                )
                .fetch_optional(&mut **tx)
                .await?
                .flatten()
                .unwrap_or_default()
            };
            Ok(serde_json::json!({"value": total.to_string(), "label": "Revenue Today"}))
        }
        ("billing", "pending_invoices") => {
            let count = if has_dept_filter {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM invoices i
                     JOIN encounters e ON e.id = i.encounter_id
                     WHERE i.status = 'pending'
                       AND e.department_id = ANY($1)",
                )
                .bind(&filters.department_ids)
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM invoices WHERE status = 'pending'",
                )
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            };
            Ok(serde_json::json!({"value": count, "label": "Pending Invoices"}))
        }
        ("billing", "revenue_summary") => {
            let rows = if has_dept_filter {
                sqlx::query_as::<_, RevenueDayRow>(
                    "SELECT DATE(i.created_at) AS day,
                            COALESCE(SUM(i.total_amount), 0) AS total
                     FROM invoices i
                     JOIN encounters e ON e.id = i.encounter_id
                     WHERE i.created_at >= CURRENT_DATE - INTERVAL '7 days'
                       AND i.status != 'cancelled'
                       AND e.department_id = ANY($1)
                     GROUP BY DATE(i.created_at)
                     ORDER BY day",
                )
                .bind(&filters.department_ids)
                .fetch_all(&mut **tx)
                .await?
            } else {
                sqlx::query_as::<_, RevenueDayRow>(
                    "SELECT DATE(created_at) AS day,
                            COALESCE(SUM(total_amount), 0) AS total
                     FROM invoices
                     WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
                       AND status != 'cancelled'
                     GROUP BY DATE(created_at)
                     ORDER BY day",
                )
                .fetch_all(&mut **tx)
                .await?
            };
            Ok(serde_json::json!({"items": rows}))
        }

        // ── IPD (admissions has no department_id — JOIN through encounters) ──
        ("ipd", "occupied_beds") => {
            let count = if has_dept_filter {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM admissions a
                     JOIN encounters e ON e.id = a.encounter_id
                     WHERE a.status = 'admitted'
                       AND e.department_id = ANY($1)",
                )
                .bind(&filters.department_ids)
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM admissions WHERE status = 'admitted'",
                )
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            };
            Ok(serde_json::json!({"value": count, "label": "Occupied Beds"}))
        }
        ("ipd", "today_admissions") => {
            let count = if has_dept_filter {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM admissions a
                     JOIN encounters e ON e.id = a.encounter_id
                     WHERE a.admitted_at >= CURRENT_DATE
                       AND e.department_id = ANY($1)",
                )
                .bind(&filters.department_ids)
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM admissions
                     WHERE admitted_at >= CURRENT_DATE",
                )
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            };
            Ok(serde_json::json!({"value": count, "label": "Today's Admissions"}))
        }
        ("ipd", "today_discharges") => {
            let count = if has_dept_filter {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM admissions a
                     JOIN encounters e ON e.id = a.encounter_id
                     WHERE a.status = 'discharged' AND a.discharged_at >= CURRENT_DATE
                       AND e.department_id = ANY($1)",
                )
                .bind(&filters.department_ids)
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar::<_, i64>(
                    "SELECT COUNT(*) FROM admissions
                     WHERE status = 'discharged' AND discharged_at >= CURRENT_DATE",
                )
                .fetch_optional(&mut **tx)
                .await?
                .unwrap_or(0)
            };
            Ok(serde_json::json!({"value": count, "label": "Today's Discharges"}))
        }

        // ── System ──
        ("system", "health_check") => {
            Ok(serde_json::json!({
                "services": [
                    {"name": "API Server", "status": "healthy"},
                    {"name": "PostgreSQL", "status": "connected"},
                    {"name": "YottaDB", "status": "deferred"}
                ]
            }))
        }

        // ── Billing analytics ──
        ("billing", "revenue_by_department") => {
            let rows = sqlx::query_scalar::<_, serde_json::Value>(
                "SELECT COALESCE(json_agg(r), '[]'::json) FROM ( \
                 SELECT d.name as department, \
                 COALESCE(SUM(ii.amount), 0)::float8 as revenue \
                 FROM departments d \
                 LEFT JOIN invoices i ON i.tenant_id = d.tenant_id \
                 LEFT JOIN invoice_items ii ON ii.invoice_id = i.id \
                   AND ii.department_id = d.id \
                   AND i.created_at >= CURRENT_DATE - INTERVAL '30 days' \
                 GROUP BY d.name ORDER BY revenue DESC LIMIT 20 \
                 ) r",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(serde_json::json!({"departments": rows}))
        }
        ("billing", "revenue_trend") => {
            let rows = sqlx::query_scalar::<_, serde_json::Value>(
                "SELECT COALESCE(json_agg(r ORDER BY r.date), '[]'::json) FROM ( \
                 SELECT DATE(created_at)::text as date, \
                 SUM(total_amount)::float8 as revenue, COUNT(*)::bigint as invoice_count \
                 FROM invoices \
                 WHERE created_at >= CURRENT_DATE - INTERVAL '30 days' \
                 GROUP BY DATE(created_at) \
                 ) r",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(serde_json::json!({"trend": rows}))
        }

        // ── OPD analytics ──
        ("opd", "footfall_trend") => {
            let rows = sqlx::query_scalar::<_, serde_json::Value>(
                "SELECT COALESCE(json_agg(r ORDER BY r.date), '[]'::json) FROM ( \
                 SELECT DATE(visit_date)::text as date, COUNT(*)::bigint as visits \
                 FROM opd_visits \
                 WHERE visit_date >= CURRENT_DATE - INTERVAL '30 days' \
                 GROUP BY DATE(visit_date) \
                 ) r",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(serde_json::json!({"trend": rows}))
        }
        ("opd", "by_department") => {
            let rows = sqlx::query_scalar::<_, serde_json::Value>(
                "SELECT COALESCE(json_agg(r), '[]'::json) FROM ( \
                 SELECT d.name as department, COUNT(*)::bigint as visits \
                 FROM opd_visits v \
                 JOIN departments d ON d.id = v.department_id \
                 WHERE v.visit_date >= CURRENT_DATE - INTERVAL '30 days' \
                 GROUP BY d.name ORDER BY visits DESC \
                 ) r",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(serde_json::json!({"departments": rows}))
        }

        // ── IPD analytics ──
        ("ipd", "bed_occupancy_rate") => {
            let row = sqlx::query_scalar::<_, serde_json::Value>(
                "SELECT json_build_object( \
                 'total_beds', (SELECT COUNT(*) FROM beds), \
                 'occupied_beds', (SELECT COUNT(*) FROM beds \
                  WHERE status = 'occupied'))",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(row)
        }
        ("ipd", "ward_wise_occupancy") => {
            let rows = sqlx::query_scalar::<_, serde_json::Value>(
                "SELECT COALESCE(json_agg(r), '[]'::json) FROM ( \
                 SELECT w.name as ward, \
                 COUNT(b.id)::bigint as total_beds, \
                 COUNT(CASE WHEN b.status = 'occupied' THEN 1 END)::bigint as occupied \
                 FROM wards w \
                 LEFT JOIN beds b ON b.ward_id = w.id \
                 GROUP BY w.name ORDER BY w.name \
                 ) r",
            )
            .fetch_one(&mut **tx)
            .await?;
            Ok(serde_json::json!({"wards": rows}))
        }

        // ── Fallback ──
        _ => Ok(serde_json::json!({
            "error": "unknown_query",
            "module": module,
            "query": query
        })),
    }
}

// ══════════════════════════════════════════════════════════
//  Quick summary endpoint (no widget config needed)
// ══════════════════════════════════════════════════════════

/// GET /api/dashboard/summary — returns key stats for the default dashboard.
pub async fn dashboard_summary(
    Extension(claims): Extension<Claims>,
    State(state): State<AppState>,
) -> Result<Json<DashboardSummaryResponse>, AppError> {
    require_permission(&claims, medbrains_core::permissions::dashboard::VIEW)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    // Total patients
    let total_patients = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM patients WHERE is_active = true",
    )
    .fetch_one(&mut *tx)
    .await?;

    // Today's registrations
    let today_registrations = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM patients WHERE created_at >= CURRENT_DATE",
    )
    .fetch_one(&mut *tx)
    .await?;

    // OPD queue waiting
    let opd_queue_count = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM opd_queues WHERE status = 'waiting' AND queue_date = CURRENT_DATE",
    )
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or(0);

    // Today's OPD visits
    let today_visits = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM encounters WHERE encounter_type = 'opd' AND encounter_date = CURRENT_DATE",
    )
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or(0);

    // Lab pending
    let lab_pending = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM lab_orders WHERE status IN ('ordered', 'sample_collected', 'processing')",
    )
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or(0);

    // Today's revenue
    let today_revenue = sqlx::query_scalar::<_, Option<rust_decimal::Decimal>>(
        "SELECT SUM(total_amount) FROM invoices WHERE created_at >= CURRENT_DATE AND status != 'cancelled'",
    )
    .fetch_optional(&mut *tx)
    .await?
    .flatten()
    .unwrap_or_default();

    // Today's appointments
    let today_appointments = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM appointments WHERE appointment_date = CURRENT_DATE",
    )
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or(0);

    // IPD active admissions
    let ipd_active = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM admissions WHERE status = 'admitted'",
    )
    .fetch_optional(&mut *tx)
    .await?
    .unwrap_or(0);

    // Recent activity — last 10 events across modules
    let recent = sqlx::query_as::<_, RecentActivityRow>(
        "SELECT * FROM (
            SELECT 'patient' AS activity_type,
                   'New patient registered: ' || first_name || ' ' || last_name AS description,
                   created_at AS occurred_at
            FROM patients WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
            UNION ALL
            SELECT 'opd',
                   'OPD visit created',
                   created_at
            FROM encounters WHERE encounter_type = 'opd' AND created_at >= CURRENT_DATE - INTERVAL '7 days'
            UNION ALL
            SELECT 'lab',
                   'Lab order ' || status::text,
                   updated_at
            FROM lab_orders WHERE updated_at >= CURRENT_DATE - INTERVAL '7 days'
            UNION ALL
            SELECT 'billing',
                   'Invoice ' || status::text || ' - ' || COALESCE(total_amount::text, '0'),
                   created_at
            FROM invoices WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
            UNION ALL
            SELECT 'appointment',
                   'Appointment ' || status::text,
                   created_at
            FROM appointments WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
        ) AS activity
        ORDER BY occurred_at DESC
        LIMIT 10",
    )
    .fetch_all(&mut *tx)
    .await?;

    tx.commit().await?;

    Ok(Json(DashboardSummaryResponse {
        total_patients,
        today_registrations,
        opd_queue_count,
        today_visits,
        lab_pending,
        today_revenue: today_revenue.to_string(),
        today_appointments,
        ipd_active,
        recent_activity: recent,
    }))
}

#[derive(Debug, Serialize)]
pub struct DashboardSummaryResponse {
    pub total_patients: i64,
    pub today_registrations: i64,
    pub opd_queue_count: i64,
    pub today_visits: i64,
    pub lab_pending: i64,
    pub today_revenue: String,
    pub today_appointments: i64,
    pub ipd_active: i64,
    pub recent_activity: Vec<RecentActivityRow>,
}

#[derive(Debug, sqlx::FromRow, Serialize)]
pub struct RecentActivityRow {
    pub activity_type: String,
    pub description: String,
    pub occurred_at: chrono::DateTime<Utc>,
}

// ── Internal query row types ────────────────────────────

#[derive(Debug, sqlx::FromRow, Serialize)]
struct PatientRow {
    id: Uuid,
    uhid: Option<String>,
    first_name: String,
    last_name: String,
    created_at: chrono::DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow, Serialize)]
struct OpdTokenRow {
    id: Uuid,
    token_no: Option<i32>,
    patient_name: Option<String>,
    doctor_name: Option<String>,
    status: Option<String>,
}

#[derive(Debug, sqlx::FromRow, Serialize)]
struct LabResultRow {
    id: Uuid,
    patient_name: Option<String>,
    status: Option<String>,
    updated_at: chrono::DateTime<Utc>,
}

#[derive(Debug, sqlx::FromRow, Serialize)]
struct RevenueDayRow {
    day: Option<chrono::NaiveDate>,
    total: rust_decimal::Decimal,
}
