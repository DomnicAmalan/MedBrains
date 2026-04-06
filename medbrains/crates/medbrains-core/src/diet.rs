//! Diet & Kitchen domain types.

use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// ── Enums ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "diet_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DietType {
    Regular,
    Diabetic,
    Renal,
    Cardiac,
    Liquid,
    Soft,
    HighProtein,
    LowSodium,
    Npo,
    Custom,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "meal_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum MealType {
    Breakfast,
    MorningSnack,
    Lunch,
    AfternoonSnack,
    Dinner,
    BedtimeSnack,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "diet_order_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum DietOrderStatus {
    Active,
    Modified,
    Completed,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "meal_prep_status", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum MealPrepStatus {
    Pending,
    Preparing,
    Ready,
    Dispatched,
    Delivered,
}

// ── Structs ──────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DietTemplate {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub diet_type: DietType,
    pub description: Option<String>,
    pub calories_target: Option<i32>,
    pub protein_g: Option<Decimal>,
    pub carbs_g: Option<Decimal>,
    pub fat_g: Option<Decimal>,
    pub fiber_g: Option<Decimal>,
    pub sodium_mg: Option<Decimal>,
    pub restrictions: serde_json::Value,
    pub suitable_for: serde_json::Value,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct DietOrder {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub patient_id: Uuid,
    pub admission_id: Option<Uuid>,
    pub template_id: Option<Uuid>,
    pub diet_type: DietType,
    pub status: DietOrderStatus,
    pub ordered_by: Option<Uuid>,
    pub special_instructions: Option<String>,
    pub allergies_flagged: serde_json::Value,
    pub is_npo: bool,
    pub npo_reason: Option<String>,
    pub start_date: NaiveDate,
    pub end_date: Option<NaiveDate>,
    pub calories_target: Option<i32>,
    pub protein_g: Option<Decimal>,
    pub carbs_g: Option<Decimal>,
    pub fat_g: Option<Decimal>,
    pub preferences: serde_json::Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct KitchenMenu {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub week_number: Option<i32>,
    pub season: Option<String>,
    pub is_active: bool,
    pub valid_from: Option<NaiveDate>,
    pub valid_until: Option<NaiveDate>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct KitchenMenuItem {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub menu_id: Uuid,
    pub day_of_week: i32,
    pub meal_type: MealType,
    pub diet_type: DietType,
    pub item_name: String,
    pub description: Option<String>,
    pub calories: Option<i32>,
    pub protein_g: Option<Decimal>,
    pub carbs_g: Option<Decimal>,
    pub fat_g: Option<Decimal>,
    pub is_vegetarian: bool,
    pub allergens: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct MealPreparation {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub diet_order_id: Uuid,
    pub meal_type: MealType,
    pub meal_date: NaiveDate,
    pub status: MealPrepStatus,
    pub prepared_by: Option<Uuid>,
    pub prepared_at: Option<DateTime<Utc>>,
    pub dispatched_at: Option<DateTime<Utc>>,
    pub delivered_at: Option<DateTime<Utc>>,
    pub delivered_to_ward: Option<String>,
    pub delivered_to_bed: Option<String>,
    pub patient_feedback: Option<String>,
    pub feedback_rating: Option<i32>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct MealCount {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub count_date: NaiveDate,
    pub meal_type: MealType,
    pub ward: String,
    pub total_beds: i32,
    pub occupied: i32,
    pub npo_count: i32,
    pub regular_count: i32,
    pub special_count: i32,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct KitchenInventory {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub item_name: String,
    pub category: Option<String>,
    pub unit: String,
    pub current_stock: Decimal,
    pub reorder_level: Option<Decimal>,
    pub supplier: Option<String>,
    pub last_procured_at: Option<DateTime<Utc>>,
    pub expiry_date: Option<NaiveDate>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct KitchenAudit {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub audit_date: NaiveDate,
    pub auditor_name: String,
    pub audit_type: String,
    pub temperature_log: serde_json::Value,
    pub hygiene_score: Option<i32>,
    pub findings: Option<String>,
    pub corrective_actions: Option<String>,
    pub is_compliant: bool,
    pub next_audit_date: Option<NaiveDate>,
    pub attachments: serde_json::Value,
    pub created_at: DateTime<Utc>,
}
