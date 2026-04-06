use chrono::{DateTime, NaiveDate, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ── Enums ──────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "order_set_context", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum OrderSetContext {
    General,
    Admission,
    PreOperative,
    DiagnosisSpecific,
    DepartmentSpecific,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "order_set_item_type", rename_all = "snake_case")]
#[serde(rename_all = "snake_case")]
pub enum OrderSetItemType {
    Lab,
    Medication,
    Nursing,
    Diet,
}

// ── Structs ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OrderSetTemplate {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub code: Option<String>,
    pub description: Option<String>,
    pub context: OrderSetContext,
    pub department_id: Option<Uuid>,
    pub trigger_diagnoses: Option<Vec<String>>,
    pub surgery_type: Option<String>,
    pub version: i32,
    pub is_current: bool,
    pub parent_template_id: Option<Uuid>,
    pub is_active: bool,
    pub created_by: Option<Uuid>,
    pub approved_by: Option<Uuid>,
    pub approved_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OrderSetTemplateItem {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub template_id: Uuid,
    pub item_type: OrderSetItemType,
    pub sort_order: i32,
    pub is_mandatory: bool,
    pub default_selected: bool,
    // Lab fields
    pub lab_test_id: Option<Uuid>,
    pub lab_priority: Option<String>,
    pub lab_notes: Option<String>,
    // Medication fields
    pub drug_catalog_id: Option<Uuid>,
    pub drug_name: Option<String>,
    pub dosage: Option<String>,
    pub frequency: Option<String>,
    pub duration: Option<String>,
    pub route: Option<String>,
    pub med_instructions: Option<String>,
    // Nursing fields
    pub task_type: Option<String>,
    pub task_description: Option<String>,
    pub task_frequency: Option<String>,
    // Diet fields
    pub diet_template_id: Option<Uuid>,
    pub diet_type: Option<String>,
    pub diet_instructions: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OrderSetActivation {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub template_id: Uuid,
    pub template_version: i32,
    pub encounter_id: Option<Uuid>,
    pub patient_id: Uuid,
    pub admission_id: Option<Uuid>,
    pub activated_by: Option<Uuid>,
    pub diagnosis_icd: Option<String>,
    pub total_items: i32,
    pub selected_items: i32,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OrderSetActivationItem {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub activation_id: Uuid,
    pub template_item_id: Option<Uuid>,
    pub item_type: OrderSetItemType,
    pub was_selected: bool,
    pub skip_reason: Option<String>,
    pub lab_order_id: Option<Uuid>,
    pub prescription_id: Option<Uuid>,
    pub nursing_task_id: Option<Uuid>,
    pub diet_order_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct OrderSetUsageStats {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub template_id: Uuid,
    pub period_start: NaiveDate,
    pub period_end: NaiveDate,
    pub activation_count: i32,
    pub unique_doctors: i32,
    pub items_ordered: i32,
    pub items_skipped: i32,
    pub completion_rate: Decimal,
}
