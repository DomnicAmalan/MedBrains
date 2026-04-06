#![allow(clippy::too_many_lines)]

use axum::{Extension, Json, extract::{Path, Query, State}};
use medbrains_core::blood_bank::{
    BloodComponent, BloodDonation, BloodDonor, CrossmatchRequest, TransfusionRecord,
};
use medbrains_core::permissions;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    error::AppError,
    middleware::auth::Claims,
    middleware::authorization::require_permission,
    state::AppState,
};

// ══════════════════════════════════════════════════════════
//  Request / Response types
// ══════════════════════════════════════════════════════════

#[derive(Debug, Deserialize)]
pub struct ListDonorsQuery {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub blood_group: Option<String>,
    pub is_deferred: Option<bool>,
}

#[derive(Debug, Serialize)]
pub struct DonorListResponse {
    pub donors: Vec<BloodDonor>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
}

#[derive(Debug, Deserialize)]
pub struct CreateDonorRequest {
    pub donor_number: String,
    pub first_name: String,
    pub last_name: String,
    pub blood_group: String,
    pub date_of_birth: Option<String>,
    pub gender: Option<String>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub address: Option<String>,
    pub id_type: Option<String>,
    pub id_number: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreateDonationRequest {
    pub bag_number: String,
    pub donation_type: Option<String>,
    pub volume_ml: i32,
    pub camp_name: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateDonationRequest {
    pub adverse_reaction: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreateComponentRequest {
    pub donation_id: Uuid,
    pub component_type: String,
    pub bag_number: String,
    pub blood_group: String,
    pub volume_ml: i32,
    pub expiry_at: String,
    pub storage_location: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateComponentStatusRequest {
    pub status: String,
    pub discard_reason: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ListComponentsQuery {
    pub status: Option<String>,
    pub blood_group: Option<String>,
    pub component_type: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CreateCrossmatchRequest {
    pub patient_id: Uuid,
    pub blood_group: String,
    pub component_type: Option<String>,
    pub units_requested: Option<i32>,
    pub clinical_indication: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateCrossmatchRequest {
    pub status: Option<String>,
    pub result: Option<String>,
    pub component_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct CreateTransfusionRequest {
    pub patient_id: Uuid,
    pub component_id: Uuid,
    pub crossmatch_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct RecordReactionRequest {
    pub reaction_type: String,
    pub reaction_severity: String,
    pub reaction_details: Option<String>,
}

// ══════════════════════════════════════════════════════════
//  Donors CRUD
// ══════════════════════════════════════════════════════════

pub async fn list_donors(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Query(params): Query<ListDonorsQuery>,
) -> Result<Json<DonorListResponse>, AppError> {
    require_permission(&claims, permissions::blood_bank::donors::LIST)?;

    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).clamp(1, 100);
    let offset = (page - 1) * per_page;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let mut conditions = vec!["tenant_id = $1".to_owned()];
    let mut bind_idx: usize = 2;

    #[allow(clippy::items_after_statements)]
    struct Bind {
        string_val: Option<String>,
        bool_val: Option<bool>,
    }
    let mut binds: Vec<Bind> = Vec::new();

    if let Some(ref bg) = params.blood_group {
        conditions.push(format!("blood_group::text = ${bind_idx}"));
        binds.push(Bind { string_val: Some(bg.clone()), bool_val: None });
        bind_idx += 1;
    }
    if let Some(def) = params.is_deferred {
        conditions.push(format!("is_deferred = ${bind_idx}"));
        binds.push(Bind { string_val: None, bool_val: Some(def) });
        bind_idx += 1;
    }

    let where_clause = conditions.join(" AND ");

    let count_sql = format!("SELECT COUNT(*) FROM blood_donors WHERE {where_clause}");
    let mut cq = sqlx::query_scalar::<_, i64>(&count_sql).bind(claims.tenant_id);
    for b in &binds {
        if let Some(ref s) = b.string_val { cq = cq.bind(s.clone()); }
        if let Some(bv) = b.bool_val { cq = cq.bind(bv); }
    }
    let total = cq.fetch_one(&mut *tx).await?;

    let data_sql = format!(
        "SELECT * FROM blood_donors WHERE {where_clause} \
         ORDER BY created_at DESC LIMIT ${bind_idx} OFFSET ${}",
        bind_idx + 1
    );
    let mut dq = sqlx::query_as::<_, BloodDonor>(&data_sql).bind(claims.tenant_id);
    for b in &binds {
        if let Some(ref s) = b.string_val { dq = dq.bind(s.clone()); }
        if let Some(bv) = b.bool_val { dq = dq.bind(bv); }
    }
    let donors = dq.bind(per_page).bind(offset).fetch_all(&mut *tx).await?;

    tx.commit().await?;
    Ok(Json(DonorListResponse { donors, total, page, per_page }))
}

pub async fn create_donor(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateDonorRequest>,
) -> Result<Json<BloodDonor>, AppError> {
    require_permission(&claims, permissions::blood_bank::donors::CREATE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let donor = sqlx::query_as::<_, BloodDonor>(
        "INSERT INTO blood_donors \
         (tenant_id, donor_number, first_name, last_name, blood_group, \
          date_of_birth, gender, phone, email, address, id_type, id_number) \
         VALUES ($1, $2, $3, $4, $5::blood_group, \
                 $6::date, $7, $8, $9, $10, $11, $12) \
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(&body.donor_number)
    .bind(&body.first_name)
    .bind(&body.last_name)
    .bind(&body.blood_group)
    .bind(&body.date_of_birth)
    .bind(&body.gender)
    .bind(&body.phone)
    .bind(&body.email)
    .bind(&body.address)
    .bind(&body.id_type)
    .bind(&body.id_number)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(donor))
}

pub async fn get_donor(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
) -> Result<Json<BloodDonor>, AppError> {
    require_permission(&claims, permissions::blood_bank::donors::LIST)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let donor = sqlx::query_as::<_, BloodDonor>(
        "SELECT * FROM blood_donors WHERE id = $1 AND tenant_id = $2",
    )
    .bind(id)
    .bind(claims.tenant_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    tx.commit().await?;
    Ok(Json(donor))
}

// ══════════════════════════════════════════════════════════
//  Donations
// ══════════════════════════════════════════════════════════

pub async fn create_donation(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(donor_id): Path<Uuid>,
    Json(body): Json<CreateDonationRequest>,
) -> Result<Json<BloodDonation>, AppError> {
    require_permission(&claims, permissions::blood_bank::donors::CREATE)?;

    let dtype = body.donation_type.as_deref().unwrap_or("whole_blood");

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let donation = sqlx::query_as::<_, BloodDonation>(
        "INSERT INTO blood_donations \
         (tenant_id, donor_id, bag_number, donation_type, volume_ml, \
          collected_by, camp_name, notes) \
         VALUES ($1, $2, $3, $4::donation_type, $5, $6, $7, $8) \
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(donor_id)
    .bind(&body.bag_number)
    .bind(dtype)
    .bind(body.volume_ml)
    .bind(claims.sub)
    .bind(&body.camp_name)
    .bind(&body.notes)
    .fetch_one(&mut *tx)
    .await?;

    // Update donor stats
    sqlx::query(
        "UPDATE blood_donors SET \
         total_donations = total_donations + 1, \
         last_donation = now(), \
         updated_at = now() \
         WHERE id = $1 AND tenant_id = $2",
    )
    .bind(donor_id)
    .bind(claims.tenant_id)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(donation))
}

pub async fn list_donations(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(donor_id): Path<Uuid>,
) -> Result<Json<Vec<BloodDonation>>, AppError> {
    require_permission(&claims, permissions::blood_bank::donors::LIST)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let donations = sqlx::query_as::<_, BloodDonation>(
        "SELECT * FROM blood_donations WHERE donor_id = $1 AND tenant_id = $2 \
         ORDER BY donated_at DESC",
    )
    .bind(donor_id)
    .bind(claims.tenant_id)
    .fetch_all(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(donations))
}

pub async fn update_donation(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(donation_id): Path<Uuid>,
    Json(body): Json<UpdateDonationRequest>,
) -> Result<Json<BloodDonation>, AppError> {
    require_permission(&claims, permissions::blood_bank::donors::CREATE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let donation = sqlx::query_as::<_, BloodDonation>(
        "UPDATE blood_donations SET \
         adverse_reaction = COALESCE($1, adverse_reaction), \
         notes = COALESCE($2, notes) \
         WHERE id = $3 AND tenant_id = $4 \
         RETURNING *",
    )
    .bind(&body.adverse_reaction)
    .bind(&body.notes)
    .bind(donation_id)
    .bind(claims.tenant_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    tx.commit().await?;
    Ok(Json(donation))
}

// ══════════════════════════════════════════════════════════
//  Blood Components / Inventory
// ══════════════════════════════════════════════════════════

pub async fn list_components(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Query(params): Query<ListComponentsQuery>,
) -> Result<Json<Vec<BloodComponent>>, AppError> {
    require_permission(&claims, permissions::blood_bank::inventory::LIST)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let mut conditions = vec!["tenant_id = $1".to_owned()];
    let mut bind_idx: usize = 2;
    let mut string_binds: Vec<String> = Vec::new();

    if let Some(ref s) = params.status {
        conditions.push(format!("status::text = ${bind_idx}"));
        string_binds.push(s.clone());
        bind_idx += 1;
    }
    if let Some(ref bg) = params.blood_group {
        conditions.push(format!("blood_group::text = ${bind_idx}"));
        string_binds.push(bg.clone());
        bind_idx += 1;
    }
    if let Some(ref ct) = params.component_type {
        conditions.push(format!("component_type::text = ${bind_idx}"));
        string_binds.push(ct.clone());
        bind_idx += 1;
    }
    let _ = bind_idx; // suppress unused warning

    let where_clause = conditions.join(" AND ");
    let sql = format!(
        "SELECT * FROM blood_components WHERE {where_clause} ORDER BY expiry_at ASC"
    );

    let mut q = sqlx::query_as::<_, BloodComponent>(&sql).bind(claims.tenant_id);
    for s in &string_binds {
        q = q.bind(s.clone());
    }
    let components = q.fetch_all(&mut *tx).await?;

    tx.commit().await?;
    Ok(Json(components))
}

pub async fn create_component(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateComponentRequest>,
) -> Result<Json<BloodComponent>, AppError> {
    require_permission(&claims, permissions::blood_bank::inventory::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let component = sqlx::query_as::<_, BloodComponent>(
        "INSERT INTO blood_components \
         (tenant_id, donation_id, component_type, bag_number, blood_group, \
          volume_ml, expiry_at, storage_location) \
         VALUES ($1, $2, $3::blood_component_type, $4, $5::blood_group, \
                 $6, $7::timestamptz, $8) \
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(body.donation_id)
    .bind(&body.component_type)
    .bind(&body.bag_number)
    .bind(&body.blood_group)
    .bind(body.volume_ml)
    .bind(&body.expiry_at)
    .bind(&body.storage_location)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(component))
}

pub async fn update_component_status(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
    Json(body): Json<UpdateComponentStatusRequest>,
) -> Result<Json<BloodComponent>, AppError> {
    require_permission(&claims, permissions::blood_bank::inventory::MANAGE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let discard_clause = if body.status == "discarded" {
        ", discarded_at = now(), discard_reason = $4"
    } else {
        ""
    };

    let sql = format!(
        "UPDATE blood_components SET \
         status = $1::blood_bag_status{discard_clause}, updated_at = now() \
         WHERE id = $2 AND tenant_id = $3 \
         RETURNING *"
    );

    let mut q = sqlx::query_as::<_, BloodComponent>(&sql)
        .bind(&body.status)
        .bind(id)
        .bind(claims.tenant_id);

    if body.status == "discarded" {
        q = q.bind(&body.discard_reason);
    }

    let component = q.fetch_optional(&mut *tx).await?.ok_or(AppError::NotFound)?;

    tx.commit().await?;
    Ok(Json(component))
}

// ══════════════════════════════════════════════════════════
//  Cross-match
// ══════════════════════════════════════════════════════════

pub async fn list_crossmatch_requests(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<Vec<CrossmatchRequest>>, AppError> {
    require_permission(&claims, permissions::blood_bank::crossmatch::LIST)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let requests = sqlx::query_as::<_, CrossmatchRequest>(
        "SELECT * FROM crossmatch_requests WHERE tenant_id = $1 \
         ORDER BY created_at DESC",
    )
    .bind(claims.tenant_id)
    .fetch_all(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(requests))
}

pub async fn create_crossmatch_request(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateCrossmatchRequest>,
) -> Result<Json<CrossmatchRequest>, AppError> {
    require_permission(&claims, permissions::blood_bank::crossmatch::CREATE)?;

    let ct = body.component_type.as_deref().unwrap_or("prbc");
    let units = body.units_requested.unwrap_or(1);

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let request = sqlx::query_as::<_, CrossmatchRequest>(
        "INSERT INTO crossmatch_requests \
         (tenant_id, patient_id, requested_by, blood_group, component_type, \
          units_requested, clinical_indication) \
         VALUES ($1, $2, $3, $4::blood_group, $5::blood_component_type, $6, $7) \
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(body.patient_id)
    .bind(claims.sub)
    .bind(&body.blood_group)
    .bind(ct)
    .bind(units)
    .bind(&body.clinical_indication)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(request))
}

pub async fn update_crossmatch(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
    Json(body): Json<UpdateCrossmatchRequest>,
) -> Result<Json<CrossmatchRequest>, AppError> {
    require_permission(&claims, permissions::blood_bank::crossmatch::CREATE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let request = sqlx::query_as::<_, CrossmatchRequest>(
        "UPDATE crossmatch_requests SET \
         status = COALESCE($1::crossmatch_status, status), \
         result = COALESCE($2, result), \
         component_id = COALESCE($3, component_id), \
         tested_by = $4, tested_at = now(), updated_at = now() \
         WHERE id = $5 AND tenant_id = $6 \
         RETURNING *",
    )
    .bind(&body.status)
    .bind(&body.result)
    .bind(body.component_id)
    .bind(claims.sub)
    .bind(id)
    .bind(claims.tenant_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    tx.commit().await?;
    Ok(Json(request))
}

// ══════════════════════════════════════════════════════════
//  Transfusion Records
// ══════════════════════════════════════════════════════════

pub async fn create_transfusion(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateTransfusionRequest>,
) -> Result<Json<TransfusionRecord>, AppError> {
    require_permission(&claims, permissions::blood_bank::transfusion::CREATE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    // ABO/Rh compatibility check
    let patient_blood_group = sqlx::query_scalar::<_, Option<String>>(
        "SELECT attributes->>'blood_group' FROM patients WHERE id = $1",
    )
    .bind(body.patient_id)
    .fetch_one(&mut *tx)
    .await?;

    let component_blood_group = sqlx::query_scalar::<_, Option<String>>(
        "SELECT blood_group::text FROM blood_components WHERE id = $1",
    )
    .bind(body.component_id)
    .fetch_one(&mut *tx)
    .await?;

    if let (Some(patient_bg), Some(component_bg)) =
        (&patient_blood_group, &component_blood_group)
    {
        let compatible = match (patient_bg.as_str(), component_bg.as_str()) {
            (p, c) if p == c => true,
            ("AB+", _) | ("ab_positive", _) => true,
            ("AB-", c) | ("ab_negative", c) if !c.ends_with('+') && !c.contains("positive") => {
                true
            }
            (_, "O-") | (_, "o_negative") => true,
            (p, "O+") | (p, "o_positive")
                if p.ends_with('+') || p.contains("positive") =>
            {
                true
            }
            ("A+", "A-") | ("A+", "O-") | ("A+", "O+") => true,
            ("a_positive", "a_negative")
            | ("a_positive", "o_negative")
            | ("a_positive", "o_positive") => true,
            ("A-", "A-") | ("A-", "O-") => true,
            ("a_negative", "a_negative") | ("a_negative", "o_negative") => true,
            ("B+", "B-") | ("B+", "O-") | ("B+", "O+") => true,
            ("b_positive", "b_negative")
            | ("b_positive", "o_negative")
            | ("b_positive", "o_positive") => true,
            ("B-", "B-") | ("B-", "O-") => true,
            ("b_negative", "b_negative") | ("b_negative", "o_negative") => true,
            _ => false,
        };
        if !compatible {
            return Err(AppError::BadRequest(format!(
                "ABO/Rh incompatibility: patient {} cannot receive component {}",
                patient_bg, component_bg
            )));
        }
    }

    let record = sqlx::query_as::<_, TransfusionRecord>(
        "INSERT INTO transfusion_records \
         (tenant_id, patient_id, component_id, crossmatch_id, administered_by) \
         VALUES ($1, $2, $3, $4, $5) \
         RETURNING *",
    )
    .bind(claims.tenant_id)
    .bind(body.patient_id)
    .bind(body.component_id)
    .bind(body.crossmatch_id)
    .bind(claims.sub)
    .fetch_one(&mut *tx)
    .await?;

    // Mark component as transfused
    sqlx::query(
        "UPDATE blood_components SET \
         status = 'transfused'::blood_bag_status, \
         issued_to_patient = $1, issued_at = now(), issued_by = $2, \
         updated_at = now() \
         WHERE id = $3 AND tenant_id = $4",
    )
    .bind(body.patient_id)
    .bind(claims.sub)
    .bind(body.component_id)
    .bind(claims.tenant_id)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(record))
}

pub async fn record_reaction(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
    Json(body): Json<RecordReactionRequest>,
) -> Result<Json<TransfusionRecord>, AppError> {
    require_permission(&claims, permissions::blood_bank::transfusion::CREATE)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let record = sqlx::query_as::<_, TransfusionRecord>(
        "UPDATE transfusion_records SET \
         has_reaction = true, \
         reaction_type = $1, \
         reaction_severity = $2::transfusion_reaction_severity, \
         reaction_details = $3, \
         reaction_reported_at = now(), \
         updated_at = now() \
         WHERE id = $4 AND tenant_id = $5 \
         RETURNING *",
    )
    .bind(&body.reaction_type)
    .bind(&body.reaction_severity)
    .bind(&body.reaction_details)
    .bind(id)
    .bind(claims.tenant_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(AppError::NotFound)?;

    tx.commit().await?;
    Ok(Json(record))
}

pub async fn list_transfusions(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<Vec<TransfusionRecord>>, AppError> {
    require_permission(&claims, permissions::blood_bank::transfusion::LIST)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let records = sqlx::query_as::<_, TransfusionRecord>(
        "SELECT * FROM transfusion_records WHERE tenant_id = $1 \
         ORDER BY created_at DESC",
    )
    .bind(claims.tenant_id)
    .fetch_all(&mut *tx)
    .await?;

    tx.commit().await?;
    Ok(Json(records))
}

// ══════════════════════════════════════════════════════════
//  GET /api/blood-bank/tti-report — TTI screening report
// ══════════════════════════════════════════════════════════

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct TtiReportRow {
    pub tti_status: String,
    pub count: i64,
}

pub async fn get_tti_report(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<serde_json::Value>, AppError> {
    require_permission(&claims, permissions::blood_bank::inventory::LIST)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let rows = sqlx::query_as::<_, TtiReportRow>(
        "SELECT COALESCE(tti_status::text, 'pending') AS tti_status, \
         COUNT(*)::bigint AS count \
         FROM blood_components WHERE tenant_id = $1 \
         GROUP BY tti_status ORDER BY count DESC",
    )
    .bind(claims.tenant_id)
    .fetch_all(&mut *tx)
    .await?;

    let total: i64 = rows.iter().map(|r| r.count).sum();

    tx.commit().await?;
    Ok(Json(serde_json::json!({
        "total_components": total,
        "by_status": rows
    })))
}

// ══════════════════════════════════════════════════════════
//  GET /api/blood-bank/hemovigilance — Hemovigilance NACO report
// ══════════════════════════════════════════════════════════

pub async fn get_hemovigilance_report(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<serde_json::Value>, AppError> {
    require_permission(&claims, permissions::blood_bank::transfusion::LIST)?;

    let mut tx = state.db.begin().await?;
    medbrains_db::pool::set_tenant_context(&mut tx, &claims.tenant_id).await?;

    let total_transfusions = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM transfusion_records \
         WHERE tenant_id = $1 AND created_at >= CURRENT_DATE - INTERVAL '365 days'",
    )
    .bind(claims.tenant_id)
    .fetch_one(&mut *tx)
    .await?;

    let total_reactions = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM transfusion_records \
         WHERE tenant_id = $1 AND has_reaction = true \
         AND created_at >= CURRENT_DATE - INTERVAL '365 days'",
    )
    .bind(claims.tenant_id)
    .fetch_one(&mut *tx)
    .await?;

    let reaction_rate = if total_transfusions > 0 {
        total_reactions as f64 / total_transfusions as f64 * 100.0
    } else {
        0.0
    };

    tx.commit().await?;
    Ok(Json(serde_json::json!({
        "reporting_period": "last_365_days",
        "total_transfusions": total_transfusions,
        "total_reactions": total_reactions,
        "reaction_rate_percent": reaction_rate
    })))
}
