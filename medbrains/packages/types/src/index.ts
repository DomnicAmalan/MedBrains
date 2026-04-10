// Permissions
export {
  PERMISSIONS,
  P,
  ROLE_TEMPLATES,
  buildPermissionTree,
  isValidPermissionCode,
} from "./permissions.js";
export type { PermissionDef, PermissionGroup } from "./permissions.js";

// Health
export interface HealthResponse {
  status: string;
  postgres: string;
  yottadb: string;
}

// Tenant
export type HospitalType =
  | "medical_college"
  | "multi_specialty"
  | "district_hospital"
  | "community_health"
  | "primary_health"
  | "standalone_clinic"
  | "eye_hospital"
  | "dental_college";

export interface Tenant {
  id: string;
  code: string;
  name: string;
  hospital_type: HospitalType;
  config: Record<string, unknown>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface TenantSummary {
  id: string;
  code: string;
  name: string;
  address_line1: string | null;
  address_line2: string | null;
  city: string | null;
  pincode: string | null;
  phone: string | null;
  email: string | null;
  website: string | null;
  registration_no: string | null;
  accreditation: string | null;
  timezone: string;
  locale: string;
  currency: string;
  fy_start_month: number;
}

// User
export type UserRole =
  | "super_admin"
  | "hospital_admin"
  | "doctor"
  | "nurse"
  | "receptionist"
  | "lab_technician"
  | "pharmacist"
  | "billing_clerk"
  | "housekeeping_staff"
  | "facilities_manager"
  | "audit_officer";

export interface User {
  id: string;
  tenant_id: string;
  username: string;
  email: string;
  full_name: string;
  role: UserRole;
  access_matrix: Record<string, unknown>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface SetupUser {
  id: string;
  tenant_id: string;
  username: string;
  email: string;
  full_name: string;
  role: string;
  is_active: boolean;
  specialization: string | null;
  medical_registration_number: string | null;
  qualification: string | null;
  consultation_fee: number | null;
  department_ids: string[];
  access_matrix: Record<string, unknown>;
}

export interface UserFacilityAssignment {
  id: string;
  tenant_id: string;
  user_id: string;
  facility_id: string;
  is_primary: boolean;
  assigned_at: string;
}

export interface AssignUserFacilitiesRequest {
  facility_ids: string[];
  primary_facility_id?: string;
}

export interface ComplianceRow {
  id: string;
  tenant_id: string;
  facility_id: string;
  regulatory_body_id: string;
  license_number: string | null;
  status: string;
}

// Onboarding
export interface OnboardingStatusResponse {
  needs_setup: boolean;
  tenant_count: number;
}

export interface OnboardingInitRequest {
  hospital_name: string;
  hospital_code: string;
  hospital_type: string;
  admin_username: string;
  admin_email: string;
  admin_password: string;
  admin_full_name: string;
}

export interface OnboardingInitResponse {
  tenant_id: string;
  user_id: string;
  csrf_token: string;
}

export interface OnboardingProgress {
  id: string;
  tenant_id: string;
  current_step: number;
  completed_steps: number[];
  is_complete: boolean;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
}

// Geo
export interface GeoCountry {
  id: string;
  code: string;
  name: string;
  phone_code: string | null;
  currency: string | null;
  is_active: boolean;
  default_locale: string;
  default_timezone: string;
  date_format: string;
  measurement_system: string;
}

// Locale / Units
export type MeasurementSystem = "metric" | "imperial";
export type TemperatureUnit = "celsius" | "fahrenheit";
export type WeightUnit = "kg" | "lbs";
export type HeightUnit = "cm" | "in";

export interface LocaleConfig {
  measurement_system: MeasurementSystem;
  temperature_unit: TemperatureUnit;
  weight_unit: WeightUnit;
  height_unit: HeightUnit;
  date_format: string;
  currency: string;
  timezone: string;
  locale: string;
}

export interface GeoState {
  id: string;
  country_id: string;
  code: string;
  name: string;
  is_active: boolean;
}

export interface GeoDistrict {
  id: string;
  state_id: string;
  code: string;
  name: string;
  is_active: boolean;
}

export interface GeoSubdistrict {
  id: string;
  district_id: string;
  code: string;
  name: string;
  is_active: boolean;
}

export interface GeoTown {
  id: string;
  subdistrict_id: string;
  code: string;
  name: string;
  pincode: string | null;
  is_active: boolean;
}

export interface PincodeResult {
  town_id: string;
  town_name: string;
  pincode: string;
  subdistrict_id: string;
  subdistrict_name: string;
  district_id: string;
  district_name: string;
  state_id: string;
  state_name: string;
  country_id: string;
  country_name: string;
}

export interface RegulatoryBody {
  id: string;
  code: string;
  name: string;
  level: "international" | "national" | "state" | "education";
  country_id: string | null;
  state_id: string | null;
  description: string | null;
  is_active: boolean;
}

// Facilities
export type FacilityType =
  | "main_hospital"
  | "medical_college"
  | "dental_college"
  | "nursing_college"
  | "pharmacy_college"
  | "ayush_hospital"
  | "research_center"
  | "blood_bank"
  | "dialysis_center"
  | "trauma_center"
  | "burn_center"
  | "rehabilitation_center"
  | "palliative_care"
  | "psychiatric_hospital"
  | "eye_hospital"
  | "maternity_hospital"
  | "pediatric_hospital"
  | "cancer_center"
  | "cardiac_center"
  | "neuro_center"
  | "ortho_center"
  | "day_care_center"
  | "diagnostic_center"
  | "telemedicine_hub"
  | "community_health_center"
  | "primary_health_center"
  | "sub_center"
  | "urban_health_center"
  | "mobile_health_unit"
  | "other";

export interface Facility {
  id: string;
  tenant_id: string;
  parent_id: string | null;
  code: string;
  name: string;
  facility_type: FacilityType;
  status: string;
  address_line1: string | null;
  city: string | null;
  phone: string | null;
  email: string | null;
  bed_count: number;
  shared_billing: boolean;
  shared_pharmacy: boolean;
  shared_lab: boolean;
  shared_hr: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Locations
export interface LocationRow {
  id: string;
  tenant_id: string;
  parent_id: string | null;
  level: string;
  code: string;
  name: string;
  is_active: boolean;
}

// Departments
export interface DepartmentRow {
  id: string;
  tenant_id: string;
  parent_id: string | null;
  code: string;
  name: string;
  department_type: string;
  working_hours: WorkingHours;
  is_active: boolean;
}

// Working Hours
export interface TimeSlot {
  start: string; // "HH:MM"
  end: string;   // "HH:MM"
}

export interface DaySchedule {
  morning?: TimeSlot;
  evening?: TimeSlot;
}

export type WorkingHours = Record<string, DaySchedule | null>;

// Roles
export type WidgetAccessLevel = "visible" | "hidden";

export interface CustomRole {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  description: string | null;
  permissions: Record<string, unknown>;
  field_access_defaults: Record<string, FieldAccessLevel>;
  widget_access_defaults: Record<string, WidgetAccessLevel>;
  is_system: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Modules
export type ModuleStatus = "available" | "enabled" | "disabled" | "coming_soon";

export interface ModuleConfig {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  description: string | null;
  status: ModuleStatus;
  config: Record<string, unknown>;
  depends_on: string[];
  created_at: string;
  updated_at: string;
}

// Sequences
export interface SequenceRow {
  id: string;
  tenant_id: string;
  seq_type: string;
  prefix: string;
  current_val: number;
  pad_width: number;
}

// Tenant Settings (branding etc.)
export interface TenantSettingsRow {
  id: string;
  tenant_id: string;
  category: string;
  key: string;
  value: unknown;
  created_at: string;
  updated_at: string;
}

// ── CSV Import ──────────────────────────────────────────────

export interface CsvImportRow {
  values: string[];
}

export interface CsvImportRequest {
  headers: string[];
  rows: CsvImportRow[];
}

export interface CsvImportResult {
  imported: number;
  skipped: number;
  errors: string[];
}

// ── Module Masters Seeding ──────────────────────────────────

export interface SeedModuleMastersRequest {
  module_code: string;
}

export interface SeedModuleMastersResponse {
  status: string;
  module?: string;
  message?: string;
  seeded: string[];
}

// ── Print Templates ─────────────────────────────────────────

export interface PrintTemplateRequest {
  template_type: string;
  header_text?: string;
  footer_text?: string;
  logo_position?: string;
  font_family?: string;
  font_size?: number;
  margin_top?: number;
  margin_bottom?: number;
  margin_left?: number;
  margin_right?: number;
  show_logo?: boolean;
  show_hospital_name?: boolean;
  show_hospital_address?: boolean;
  show_hospital_phone?: boolean;
  show_registration_no?: boolean;
  custom_css?: string;
}

export type PrintTemplateType =
  | "letterhead"
  | "prescription_pad"
  | "invoice"
  | "lab_report"
  | "discharge_summary";

// ── Form Master / Field Master / Module Linker ──────────

export type FieldDataType =
  | "text"
  | "email"
  | "phone"
  | "date"
  | "datetime"
  | "time"
  | "select"
  | "multiselect"
  | "checkbox"
  | "radio"
  | "textarea"
  | "number"
  | "decimal"
  | "file"
  | "hidden"
  | "computed"
  | "boolean"
  | "uuid_fk"
  | "json";

export type RequirementLevel =
  | "mandatory"
  | "conditional"
  | "recommended"
  | "optional";

export type FieldAccessLevel = "edit" | "view" | "hidden";

export type FormStatus = "draft" | "active" | "deprecated";

export interface FieldValidation {
  min_length?: number;
  max_length?: number;
  min?: number;
  max?: number;
  regex?: string;
  options?: string[];
  fk_table?: string;
  fk_column?: string;
  fk_display?: string;
  custom?: string;
}

export interface FieldCondition {
  field: string;
  operator: "eq" | "neq" | "in" | "not_in" | "contains" | "is_empty" | "is_not_empty" | "gt" | "lt" | "gte" | "lte";
  value?: unknown;
  values?: unknown[];
  all?: FieldCondition[];
  any?: FieldCondition[];
}

export interface RegulatoryClauseRef {
  body_code: string;
  body_name: string;
  clause_code: string | null;
  clause_reference: string | null;
  requirement_level: RequirementLevel;
}

export interface ResolvedField {
  field_code: string;
  label: string;
  description: string | null;
  data_type: FieldDataType;
  requirement_level: RequirementLevel;
  default_value: string | null;
  placeholder: string | null;
  validation: FieldValidation | null;
  ui_component: string | null;
  ui_width: string | null;
  ui_hint: string | null;
  icon: string | null;
  icon_position: "left" | "right" | null;
  condition: FieldCondition | null;
  is_quick_mode: boolean;
  is_hidden: boolean;
  access_level: FieldAccessLevel;
  regulatory_clauses: RegulatoryClauseRef[];
  data_source: FieldDataSource | null;
  actions: FieldAction[];
}

export interface ResolvedSection {
  code: string;
  name: string;
  sort_order: number;
  is_collapsible: boolean;
  is_default_open: boolean;
  icon: string | null;
  color: string | null;
  fields: ResolvedField[];
}

export interface ResolvedFormDefinition {
  form_code: string;
  form_name: string;
  version: number;
  config: Record<string, unknown> | null;
  sections: ResolvedSection[];
}

export interface TenantFieldOverride {
  id: string;
  tenant_id: string;
  field_id: string;
  form_id: string | null;
  label_override: string | null;
  requirement_override: RequirementLevel | null;
  is_hidden: boolean;
  validation_override: FieldValidation | null;
  created_at: string;
  updated_at: string;
}

export interface FormMaster {
  id: string;
  code: string;
  name: string;
  version: number;
  status: FormStatus;
  config: Record<string, unknown> | null;
  published_at: string | null;
  published_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface FieldMaster {
  id: string;
  code: string;
  name: string;
  description: string | null;
  data_type: FieldDataType;
  is_system: boolean;
  is_active: boolean;
}

export interface ModuleFormLink {
  module_code: string;
  form_id: string;
  context: string;
}

// ── Admin Form Management ────────────────────────────────

export interface FieldMasterFull {
  id: string;
  code: string;
  name: string;
  description: string | null;
  data_type: FieldDataType;
  default_value: string | null;
  placeholder: string | null;
  validation: FieldValidation | null;
  ui_component: string | null;
  ui_width: string | null;
  fhir_path: string | null;
  db_table: string | null;
  db_column: string | null;
  condition: FieldCondition | null;
  is_system: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface FieldRegulatoryLinkRow {
  id: string;
  regulatory_body_id: string;
  body_code: string;
  body_name: string;
  requirement_level: RequirementLevel;
  clause_reference: string | null;
  clause_code: string | null;
  description: string | null;
}

export interface FieldDetailResponse {
  field: FieldMasterFull;
  regulatory_links: FieldRegulatoryLinkRow[];
}

export interface FormFieldWithMaster {
  ff_id: string;
  field_id: string;
  field_code: string;
  field_name: string;
  data_type: FieldDataType;
  sort_order: number;
  label_override: string | null;
  is_quick_mode: boolean;
  icon: string | null;
  icon_position: string | null;
}

export interface SectionWithFields {
  id: string;
  code: string;
  name: string;
  sort_order: number;
  is_collapsible: boolean;
  is_default_open: boolean;
  icon: string | null;
  color: string | null;
  fields: FormFieldWithMaster[];
}

export interface ModuleFormLinkRow {
  module_code: string;
  form_id: string;
  context: string;
  form_code: string;
  form_name: string;
}

export interface FormDetailResponse {
  id: string;
  code: string;
  name: string;
  version: number;
  status: FormStatus;
  config: Record<string, unknown> | null;
  published_at: string | null;
  published_by: string | null;
  created_at: string;
  updated_at: string;
  sections: SectionWithFields[];
  module_links: ModuleFormLinkRow[];
}

// ── Form Versioning Types ──────────────────────────────────

export interface FormVersionSummary {
  id: string;
  form_id: string;
  version: number;
  name: string;
  status: FormStatus;
  config: Record<string, unknown> | null;
  change_summary: string | null;
  created_by: string | null;
  created_by_name: string | null;
  created_at: string;
}

export interface FormVersionSnapshot {
  id: string;
  form_id: string;
  version: number;
  name: string;
  status: FormStatus;
  config: Record<string, unknown> | null;
  snapshot: FormSnapshotData;
  change_summary: string | null;
  created_by: string | null;
  created_at: string;
}

export interface FormSnapshotData {
  sections: FormSnapshotSection[];
}

export interface FormSnapshotSection {
  id: string;
  code: string;
  name: string;
  sort_order: number;
  is_collapsible: boolean;
  is_default_open: boolean;
  icon: string | null;
  color: string | null;
  fields: FormSnapshotField[];
}

export interface FormSnapshotField {
  ff_id: string;
  field_id: string;
  field_code: string;
  field_name: string;
  data_type: FieldDataType;
  sort_order: number;
  label_override: string | null;
  is_quick_mode: boolean;
  icon: string | null;
  icon_position: string | null;
  field_master_snapshot: {
    placeholder: string | null;
    validation: FieldValidation | null;
    ui_width: string | null;
    data_source: Record<string, unknown> | null;
    actions: Record<string, unknown> | null;
  };
}

export interface PublishFormRequest {
  change_summary?: string;
}

export interface FormDiffResponse {
  v1: number;
  v2: number;
  config_changes: PropertyChange[];
  section_changes: SectionChange[];
  summary: DiffSummary;
}

export interface PropertyChange {
  property: string;
  old_value: unknown;
  new_value: unknown;
}

export interface SectionChange {
  code: string;
  name: string;
  change_type: "added" | "removed" | "modified";
  field_changes: FieldChange[];
}

export interface FieldChange {
  field_code: string;
  field_name: string;
  change_type: "added" | "removed" | "modified" | "moved";
  property_changes: PropertyChange[];
}

export interface DiffSummary {
  sections_added: number;
  sections_removed: number;
  sections_modified: number;
  fields_added: number;
  fields_removed: number;
  fields_modified: number;
}

export interface FieldAuditEntry {
  id: string;
  field_id: string;
  action: "created" | "updated";
  previous_state: Record<string, unknown> | null;
  new_state: Record<string, unknown>;
  changed_fields: string[] | null;
  changed_by: string | null;
  changed_by_name: string | null;
  changed_at: string;
}

export interface TenantFieldOverrideRow {
  id: string;
  field_id: string;
  field_code: string;
  field_name: string;
  form_id: string | null;
  label_override: string | null;
  requirement_override: RequirementLevel | null;
  is_hidden: boolean;
  validation_override: FieldValidation | null;
}

export interface RegulatoryClauseWithContext {
  id: string;
  field_id: string;
  field_code: string;
  field_name: string;
  regulatory_body_id: string;
  body_code: string;
  body_name: string;
  body_level: string;
  requirement_level: RequirementLevel;
  clause_reference: string | null;
  clause_code: string | null;
  description: string | null;
}

export interface CreateFormRequest {
  code: string;
  name: string;
  status?: FormStatus;
  config?: Record<string, unknown>;
}

export interface UpdateFormRequest {
  name?: string;
  status?: FormStatus;
  config?: Record<string, unknown>;
}

export interface CreateFieldRequest {
  code: string;
  name: string;
  description?: string;
  data_type: FieldDataType;
  default_value?: string;
  placeholder?: string;
  validation?: FieldValidation;
  ui_component?: string;
  ui_width?: string;
  fhir_path?: string;
  db_table?: string;
  db_column?: string;
}

export interface UpdateFieldRequest {
  name?: string;
  description?: string;
  data_type?: FieldDataType;
  validation?: FieldValidation;
  default_value?: string;
  placeholder?: string;
  ui_component?: string;
  ui_width?: string;
  is_active?: boolean;
}

export interface CreateSectionRequest {
  code: string;
  name: string;
  sort_order?: number;
  is_collapsible?: boolean;
  is_default_open?: boolean;
  icon?: string;
  color?: string;
}

export interface UpdateSectionRequest {
  name?: string;
  is_collapsible?: boolean;
  is_default_open?: boolean;
  icon?: string;
  color?: string;
}

export interface AddFieldToFormRequest {
  field_id: string;
  section_id: string;
  sort_order?: number;
  label_override?: string;
  is_quick_mode?: boolean;
  icon?: string | null;
  icon_position?: string | null;
}

export interface UpdateFormFieldRequest {
  label_override?: string | null;
  is_quick_mode?: boolean;
  section_id?: string;
  icon?: string | null;
  icon_position?: string | null;
}

export interface ReorderItem {
  id: string;
  sort_order: number;
}

export interface CreateModuleLinkRequest {
  module_code: string;
  form_id: string;
  context?: string;
}

// ── Regulatory Body Management ────────────────────────────

export interface RegulatoryBodyFull {
  id: string;
  code: string;
  name: string;
  level: "international" | "national" | "state" | "education";
  country_id: string | null;
  state_id: string | null;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateRegulatoryBodyRequest {
  code: string;
  name: string;
  level: "international" | "national" | "state" | "education";
  country_id?: string;
  state_id?: string;
  description?: string;
}

export interface UpdateRegulatoryBodyRequest {
  name?: string;
  description?: string;
  is_active?: boolean;
}

export interface CreateRegulatoryLinkRequest {
  field_id: string;
  regulatory_body_id: string;
  requirement_level: RequirementLevel;
  clause_reference?: string;
  clause_code?: string;
  description?: string;
}

export interface UpdateRegulatoryLinkRequest {
  requirement_level?: RequirementLevel;
  clause_reference?: string;
  clause_code?: string;
  description?: string;
}

// ── Onboarding Store Types ──────────────────────────────

export interface OnboardingFacility {
  local_id: string;
  code: string;
  name: string;
  facility_type: FacilityType;
  parent_local_id?: string;
  bed_count?: number;
  shared_billing: boolean;
  shared_pharmacy: boolean;
  shared_lab: boolean;
  shared_hr: boolean;
}

export interface OnboardingLocation {
  local_id: string;
  code: string;
  name: string;
  level: string;
  parent_local_id?: string;
}

export interface OnboardingDepartment {
  local_id: string;
  code: string;
  name: string;
  department_type: string;
  parent_local_id?: string;
  working_hours?: WorkingHours;
}

export interface OnboardingUser {
  local_id: string;
  full_name: string;
  username: string;
  email: string;
  password: string;
  role: string;
  specialization?: string;
  medical_registration_number?: string;
  qualification?: string;
  consultation_fee?: number;
  department_local_ids?: string[];
}

export interface OnboardingRole {
  local_id: string;
  code: string;
  name: string;
  description?: string;
}

export interface OnboardingService {
  local_id: string;
  code: string;
  name: string;
  service_type: ServiceType;
  description?: string;
}

export interface OnboardingBedType {
  local_id: string;
  code: string;
  name: string;
  daily_rate: number;
  description?: string;
}

export interface OnboardingTaxCategory {
  local_id: string;
  code: string;
  name: string;
  rate_percent: number;
  applicability: TaxApplicability;
  description?: string;
}

export interface OnboardingPaymentMethod {
  local_id: string;
  code: string;
  name: string;
  is_default: boolean;
}

export interface AdditionalSequence {
  seq_type: string;
  prefix: string;
  pad_width: number;
}

// ── Services ─────────────────────────────────────────────

export type ServiceType =
  | "consultation"
  | "procedure"
  | "investigation"
  | "nursing"
  | "diet"
  | "other";

export interface ServiceRow {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  service_type: ServiceType;
  base_price: number;
  department_id: string | null;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ── Bed Types ────────────────────────────────────────────

export interface BedTypeRow {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  daily_rate: number;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ── Tax Categories ───────────────────────────────────────

export type TaxApplicability = "taxable" | "exempt" | "zero_rated";

export interface TaxCategoryRow {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  rate_percent: number;
  applicability: TaxApplicability;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ── Payment Methods ──────────────────────────────────────

export interface PaymentMethodRow {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  is_default: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ── Patient Registration ─────────────────────────────────

export type Gender = "male" | "female" | "other" | "unknown";
export type PatientCategory =
  | "general" | "private" | "insurance" | "pmjay" | "cghs"
  | "staff" | "vip" | "mlc" | "esi" | "corporate" | "free"
  | "charity" | "research_subject" | "staff_dependent";

export type MaritalStatus = "single" | "married" | "divorced" | "widowed" | "separated" | "domestic_partner" | "unknown";
export type RegistrationType = "new" | "revisit" | "transfer_in" | "referral" | "emergency" | "camp" | "telemedicine" | "pre_registration";
export type RegistrationSource = "walk_in" | "phone" | "online_portal" | "mobile_app" | "kiosk" | "referral" | "ambulance" | "camp" | "telemedicine";
export type AddressType = "current" | "permanent" | "correspondence" | "workplace" | "temporary";
export type IdentifierType = "aadhaar" | "pan" | "voter_id" | "driving_license" | "passport" | "ration_card" | "ssn" | "nhs_number" | "medicare_number" | "national_id" | "birth_certificate" | "employee_id" | "disability_certificate" | "abha" | "abha_address" | "emirates_id" | "iqama" | "uhid_external";
export type BloodGroup = "a_positive" | "a_negative" | "b_positive" | "b_negative" | "ab_positive" | "ab_negative" | "o_positive" | "o_negative" | "unknown";
export type AllergyType = "drug" | "food" | "environmental" | "latex" | "contrast_dye" | "biological" | "other";
export type AllergySeverity = "mild" | "moderate" | "severe" | "life_threatening";
export type ConsentType = "general_treatment" | "data_sharing" | "abdm_linking" | "research_participation" | "sms_communication" | "email_communication" | "photography" | "advance_directive" | "organ_donation" | "hie_participation";
export type ConsentStatus = "granted" | "denied" | "withdrawn" | "pending";
export type ConsentCaptureMode = "paper_signed" | "digital_signature" | "biometric" | "otp_verified" | "verbal_recorded";
export type FinancialClass = "self_pay" | "insurance" | "government_scheme" | "corporate" | "charity" | "research";

// Expanded Patient interface matching the ~55-field Rust struct
export interface Patient {
  id: string;
  tenant_id: string;
  uhid: string;
  abha_id: string | null;
  prefix: string | null;
  first_name: string;
  middle_name: string | null;
  last_name: string;
  suffix: string | null;
  full_name_local: string | null;
  father_name: string | null;
  mother_name: string | null;
  spouse_name: string | null;
  guardian_name: string | null;
  guardian_relation: string | null;
  date_of_birth: string | null;
  is_dob_estimated: boolean;
  gender: Gender;
  gender_identity: string | null;
  marital_status: MaritalStatus | null;
  religion: string | null;
  nationality_id: string | null;
  preferred_language: string | null;
  birth_place: string | null;
  blood_group: BloodGroup | null;
  blood_group_verified: boolean;
  no_known_allergies: boolean | null;
  occupation: string | null;
  education_level: string | null;
  phone: string;
  phone_secondary: string | null;
  email: string | null;
  preferred_contact_method: string | null;
  address: Record<string, unknown> | null;
  category: PatientCategory;
  registration_type: RegistrationType;
  registration_source: RegistrationSource | null;
  registered_by: string | null;
  registered_at_facility: string | null;
  financial_class: FinancialClass;
  is_medico_legal: boolean;
  mlc_number: string | null;
  is_unknown_patient: boolean;
  temporary_name: string | null;
  is_vip: boolean;
  is_deceased: boolean;
  deceased_date: string | null;
  photo_url: string | null;
  photo_captured_at: string | null;
  data_quality_score: number | null;
  last_visit_date: string | null;
  total_visits: number;
  is_merged: boolean;
  merged_into_patient_id: string | null;
  source_system: string | null;
  legacy_id: string | null;
  attributes: Record<string, unknown>;
  is_active: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

// Sub-resource interfaces
export interface PatientIdentifier {
  id: string;
  tenant_id: string;
  patient_id: string;
  id_type: IdentifierType;
  id_number: string;
  id_number_hash: string | null;
  issuing_authority: string | null;
  issuing_country_id: string | null;
  valid_from: string | null;
  valid_until: string | null;
  is_verified: boolean;
  verified_at: string | null;
  verification_mode: string | null;
  document_url: string | null;
  is_primary: boolean;
  created_at: string;
  updated_at: string;
}

export interface PatientAddress {
  id: string;
  tenant_id: string;
  patient_id: string;
  address_type: AddressType;
  address_line1: string;
  address_line2: string | null;
  village_town: string | null;
  city: string;
  district_id: string | null;
  state_id: string | null;
  country_id: string;
  postal_code: string;
  latitude: number | null;
  longitude: number | null;
  is_primary: boolean;
  valid_from: string | null;
  valid_until: string | null;
  created_at: string;
  updated_at: string;
}

export interface PatientContact {
  id: string;
  tenant_id: string;
  patient_id: string;
  contact_name: string;
  relation: string;
  phone: string;
  phone_alt: string | null;
  email: string | null;
  address: Record<string, unknown> | null;
  is_emergency_contact: boolean;
  is_next_of_kin: boolean;
  is_legal_guardian: boolean;
  priority: number;
  created_at: string;
  updated_at: string;
}

export interface PatientInsurance {
  id: string;
  tenant_id: string;
  patient_id: string;
  insurance_provider: string;
  policy_number: string;
  group_number: string | null;
  member_id: string | null;
  plan_name: string | null;
  policy_holder_name: string | null;
  policy_holder_relation: string | null;
  valid_from: string;
  valid_until: string;
  sum_insured: number | null;
  tpa_name: string | null;
  tpa_id: string | null;
  coverage_type: string | null;
  priority: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PatientAllergy {
  id: string;
  tenant_id: string;
  patient_id: string;
  allergy_type: AllergyType;
  allergen_name: string;
  allergen_code: string | null;
  reaction: string | null;
  severity: AllergySeverity | null;
  onset_date: string | null;
  reported_by: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PatientConsent {
  id: string;
  tenant_id: string;
  patient_id: string;
  consent_type: ConsentType;
  consent_status: ConsentStatus;
  consent_date: string;
  consent_version: string | null;
  consented_by: string;
  consented_by_relation: string | null;
  witness_name: string | null;
  capture_mode: ConsentCaptureMode;
  document_url: string | null;
  valid_until: string | null;
  notes: string | null;
  revoked_at: string | null;
  revoked_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface PatientDocument {
  id: string;
  tenant_id: string;
  patient_id: string;
  document_type: string;
  document_name: string;
  file_url: string;
  file_size: number | null;
  mime_type: string | null;
  uploaded_by: string | null;
  notes: string | null;
  created_at: string;
}

export interface PatientFamilyLink {
  id: string;
  tenant_id: string;
  patient_id: string;
  related_patient_id: string;
  relationship: string;
  is_primary_contact: boolean;
  notes: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface FamilyLinkRow {
  id: string;
  patient_id: string;
  related_patient_id: string;
  relationship: string;
  is_primary_contact: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
  related_uhid: string | null;
  related_name: string | null;
  related_phone: string | null;
  related_gender: string | null;
}

export interface CreateFamilyLinkRequest {
  related_patient_id: string;
  relationship: string;
  is_primary_contact?: boolean;
  notes?: string;
}

export interface PatientMergeHistory {
  id: string;
  tenant_id: string;
  surviving_patient_id: string;
  merged_patient_id: string;
  merged_by: string;
  merge_reason: string;
  merge_data: Record<string, unknown>;
  unmerged_at: string | null;
  unmerged_by: string | null;
  created_at: string;
}

export interface MergePatientRequest {
  surviving_patient_id: string;
  merged_patient_id: string;
  merge_reason: string;
}

export interface CreateDocumentRequest {
  document_type: string;
  document_name: string;
  file_url: string;
  file_size?: number;
  mime_type?: string;
  notes?: string;
}

export interface MasterItem {
  id: string;
  tenant_id: string | null;
  code: string;
  name: string;
  sort_order: number;
  is_active: boolean;
}

export interface CreateMasterItemRequest {
  code: string;
  name: string;
  sort_order?: number;
}

export interface UpdateMasterItemRequest {
  code?: string;
  name?: string;
  sort_order?: number;
  is_active?: boolean;
}

export interface InsuranceProvider {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  provider_type: string;
  contact_phone: string | null;
  contact_email: string | null;
  website: string | null;
  is_active: boolean;
  created_at: string;
}

export interface CreateInsuranceProviderRequest {
  code: string;
  name: string;
  provider_type: string;
  contact_phone?: string;
  contact_email?: string;
  website?: string;
}

export interface UpdateInsuranceProviderRequest {
  code?: string;
  name?: string;
  provider_type?: string;
  contact_phone?: string | null;
  contact_email?: string | null;
  website?: string | null;
  is_active?: boolean;
}

// Keep existing PatientListResponse, update requests:
export interface PatientListResponse {
  patients: Patient[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreatePatientRequest {
  first_name: string;
  last_name: string;
  date_of_birth?: string | null;
  gender: Gender;
  phone: string;
  prefix?: string;
  middle_name?: string;
  suffix?: string;
  father_name?: string;
  guardian_name?: string;
  guardian_relation?: string;
  is_dob_estimated?: boolean;
  marital_status?: MaritalStatus;
  religion?: string;
  nationality_id?: string;
  preferred_language?: string;
  blood_group?: BloodGroup;
  occupation?: string;
  phone_secondary?: string;
  email?: string | null;
  address?: Record<string, unknown> | null;
  category?: PatientCategory;
  registration_type?: RegistrationType;
  registration_source?: RegistrationSource;
  financial_class?: FinancialClass;
  is_medico_legal?: boolean;
  mlc_number?: string;
  is_vip?: boolean;
  is_unknown_patient?: boolean;
  attributes?: Record<string, unknown>;
}

export interface UpdatePatientRequest {
  first_name?: string;
  last_name?: string;
  date_of_birth?: string | null;
  gender?: Gender;
  phone?: string;
  prefix?: string | null;
  middle_name?: string | null;
  suffix?: string | null;
  father_name?: string | null;
  guardian_name?: string | null;
  guardian_relation?: string | null;
  is_dob_estimated?: boolean;
  marital_status?: MaritalStatus | null;
  religion?: string | null;
  nationality_id?: string | null;
  preferred_language?: string | null;
  blood_group?: BloodGroup | null;
  occupation?: string | null;
  phone_secondary?: string | null;
  email?: string | null;
  address?: Record<string, unknown> | null;
  category?: PatientCategory;
  registration_type?: RegistrationType;
  registration_source?: RegistrationSource | null;
  financial_class?: FinancialClass;
  is_medico_legal?: boolean;
  mlc_number?: string | null;
  is_vip?: boolean;
  is_unknown_patient?: boolean;
  is_active?: boolean;
  attributes?: Record<string, unknown>;
}

// Create/update requests for sub-resources
export interface CreatePatientIdentifierRequest {
  id_type: IdentifierType;
  id_number: string;
  issuing_authority?: string;
  issuing_country_id?: string;
  valid_from?: string;
  valid_until?: string;
  is_verified?: boolean;
  document_url?: string;
  is_primary?: boolean;
}

export interface CreatePatientAddressRequest {
  address_type: AddressType;
  address_line1: string;
  address_line2?: string;
  village_town?: string;
  city: string;
  district_id?: string;
  state_id?: string;
  country_id: string;
  postal_code: string;
  is_primary?: boolean;
}

export interface CreatePatientContactRequest {
  contact_name: string;
  relation: string;
  phone: string;
  phone_alt?: string;
  email?: string;
  is_emergency_contact?: boolean;
  is_next_of_kin?: boolean;
  is_legal_guardian?: boolean;
  priority?: number;
}

export interface CreatePatientAllergyRequest {
  allergy_type: AllergyType;
  allergen_name: string;
  allergen_code?: string;
  reaction?: string;
  severity?: AllergySeverity;
  onset_date?: string;
  reported_by?: string;
}

export interface CreatePatientConsentRequest {
  consent_type: ConsentType;
  consent_status: ConsentStatus;
  consented_by: string;
  consented_by_relation?: string;
  witness_name?: string;
  capture_mode: ConsentCaptureMode;
  consent_version?: string;
  document_url?: string;
  valid_until?: string;
  notes?: string;
}

export interface MpiMatchRequest {
  first_name: string;
  last_name: string;
  date_of_birth?: string;
  phone?: string;
  identifier_hash?: string;
}

export interface MpiMatchResult {
  patient: Patient;
  score: number;
  match_fields: string[];
}

// ── Data Source Binding ─────────────────────────────────

/** How a select/multiselect/radio/checkbox field gets its options */
export type DataSourceType = "static" | "api" | "dependent";

export interface FieldDataSource {
  type: DataSourceType;

  // For type="api" — direct API fetch
  endpoint?: string;
  method?: "GET" | "POST";
  valueKey?: string;
  labelKey?: string;
  params?: Record<string, string>;

  // For type="dependent" — cascading (extends api)
  dependsOn?: string;
  parentParamKey?: string;
}

// ── Field Actions ───────────────────────────────────────

export type FieldActionTrigger = "on_click" | "on_blur" | "on_change";
export type FieldActionType = "api_call" | "validate" | "lookup" | "copy_value";

export interface FieldAction {
  id: string;
  label: string;
  trigger: FieldActionTrigger;
  actionType: FieldActionType;
  icon?: string;

  // For api_call
  endpoint?: string;
  method?: "GET" | "POST";
  bodyMapping?: Record<string, string>;
  responseMapping?: Record<string, string>;

  // For validate
  validationExpr?: string;

  // For lookup
  lookupEntity?: string;
  lookupDisplayFields?: string[];

  // For copy_value
  sourceField?: string;
  targetField?: string;
}

// ── Form Builder Types ──────────────────────────────────

/** Unique ID for any form builder node */
export type FormBuilderNodeId = string;

/** JSON Logic rule — pure data, no code execution */
export type JsonLogicRule = Record<string, unknown> | boolean | null;

/** The complete form builder state — single source of truth */
export interface FormBuilderState {
  /** Form metadata */
  form: {
    id: string;
    code: string;
    name: string;
    version: number;
    status: FormStatus;
    config: FormBuilderConfig;
  };

  /** Flat map of all sections (O(1) lookup) */
  sections: Record<FormBuilderNodeId, FormBuilderSectionNode>;

  /** Ordered list of section IDs (defines visual order) */
  sectionOrder: FormBuilderNodeId[];

  /** Flat map of all fields (O(1) lookup) */
  fields: Record<FormBuilderNodeId, FormBuilderFieldNode>;

  /** Section -> ordered field IDs mapping */
  fieldOrder: Record<FormBuilderNodeId, FormBuilderNodeId[]>;

  /** Currently selected node for property editing */
  selectedNodeId: FormBuilderNodeId | null;

  /** Drag state */
  dragState: FormBuilderDragState | null;

  /** Undo/redo history */
  history: FormBuilderHistoryStack;
}

/** Section node in the form builder */
export interface FormBuilderSectionNode {
  id: FormBuilderNodeId;
  code: string;
  name: string;
  icon: string | null;
  color: string | null;
  isCollapsible: boolean;
  isDefaultOpen: boolean;
  condition: JsonLogicRule | null;
  layout: "single" | "two-column" | "three-column";
}

/** Field node in the form builder */
export interface FormBuilderFieldNode {
  id: FormBuilderNodeId;
  fieldMasterId: string;
  fieldCode: string;
  label: string;
  dataType: FieldDataType;
  requirementLevel: RequirementLevel;
  /** Column span in a 12-column grid (1–12) */
  colSpan: number;
  isQuickMode: boolean;
  placeholder: string | null;
  helpText: string | null;
  defaultValue: string | null;

  /** Choices for select / multiselect / radio / checkbox fields */
  options: string[] | null;

  // Expression-powered properties (MBX)
  condition: JsonLogicRule | null;
  computedExpr: string | null;
  validationRules: FormBuilderValidationRule[];

  // Regulatory (read-only, from field_master)
  regulatoryClauses: RegulatoryClauseRef[];

  // Field icon (shown in leftSection or rightSection of the input)
  icon: string | null;
  iconPosition: "left" | "right";

  // Data source binding (for option-type fields)
  dataSource: FieldDataSource | null;

  // Field actions (API calls, validation, lookup, copy)
  actions: FieldAction[];
}

/** Enhanced validation rule for the form builder */
export interface FormBuilderValidationRule {
  type:
    | "required"
    | "min_length"
    | "max_length"
    | "regex"
    | "min"
    | "max"
    | "custom_expr";
  value: string | number | boolean;
  message: string;
  condition?: JsonLogicRule;
}

/** Form-level configuration */
export interface FormBuilderConfig {
  submitLabel: string;
  cancelButton: boolean;
  supportsQuickMode: boolean;
  printTemplate: PrintTemplateConfig | null;
}

/** Drag-and-drop state */
export interface FormBuilderDragState {
  type: "field" | "section" | "palette-field";
  sourceId: FormBuilderNodeId;
  sourceSectionId?: FormBuilderNodeId;
  targetSectionId?: FormBuilderNodeId;
  targetIndex?: number;
}

/** Snapshot of form builder state for undo/redo */
export interface FormBuilderHistoryEntry {
  sections: Record<FormBuilderNodeId, FormBuilderSectionNode>;
  sectionOrder: FormBuilderNodeId[];
  fields: Record<FormBuilderNodeId, FormBuilderFieldNode>;
  fieldOrder: Record<FormBuilderNodeId, FormBuilderNodeId[]>;
}

/** Undo/redo stack */
export interface FormBuilderHistoryStack {
  past: FormBuilderHistoryEntry[];
  future: FormBuilderHistoryEntry[];
}

// ── Print Template Types ────────────────────────────────

/** Print template configuration for a form */
export interface PrintTemplateConfig {
  pageSize: "A4" | "A5" | "letter" | "prescription";
  orientation: "portrait" | "landscape";
  margins: { top: number; right: number; bottom: number; left: number };

  header: {
    template: string;
    height: number;
    showOnAllPages: boolean;
    showLogo: boolean;
    logoPosition: "left" | "center" | "right";
  };

  body: {
    mode: "form-fields" | "custom-template";
    template?: string;
    fieldLayout: "table" | "flow" | "grid";
    showLabels: boolean;
    showEmptyFields: boolean;
  };

  footer: {
    template: string;
    height: number;
    showOnAllPages: boolean;
    showPageNumbers: boolean;
    signatures: PrintSignatureSlot[];
  };
}

/** Signature slot in print footer */
export interface PrintSignatureSlot {
  label: string;
  position: "left" | "center" | "right";
  lineWidth: number;
}

// ── Onboarding Store Types ──────────────────────────────

export interface OnboardingSetupRequest {
  hospital_details?: {
    address_line1?: string | null;
    address_line2?: string | null;
    city?: string | null;
    pincode?: string | null;
    phone?: string | null;
    email?: string | null;
    website?: string | null;
    registration_no?: string | null;
    accreditation?: string | null;
    timezone: string;
    currency: string;
    fy_start_month: number;
  };
  geo?: {
    country_id?: string;
    state_id?: string;
    district_id?: string;
  };
  regulator_ids?: string[];
  facilities: OnboardingFacility[];
  locations: OnboardingLocation[];
  departments: OnboardingDepartment[];
  users: OnboardingUser[];
  roles: OnboardingRole[];
  module_statuses: Record<string, string>;
  sequences?: {
    uhid_prefix: string;
    uhid_pad_width: number;
    invoice_prefix: string;
    invoice_pad_width: number;
  };
  additional_sequences?: AdditionalSequence[];
  services?: OnboardingService[];
  bed_types?: OnboardingBedType[];
  tax_categories?: OnboardingTaxCategory[];
  payment_methods?: OnboardingPaymentMethod[];
  branding?: {
    primary_color: string;
    secondary_color: string;
    logo_url?: string;
  };
}

// ── Dashboard Widget Builder Types ──────────────────────

export type WidgetType =
  | "stat_card"
  | "data_table"
  | "list"
  | "chart"
  | "quick_actions"
  | "module_embed"
  | "form_embed"
  | "system_health"
  | "custom_html";

export type WidgetCategory =
  | "metrics"
  | "data"
  | "actions"
  | "module"
  | "system"
  | "general";

export interface LayoutConfig {
  columns: number;
  row_height: number;
  gap: number;
}

export interface Dashboard {
  id: string;
  tenant_id: string;
  user_id: string | null;
  name: string;
  code: string;
  description: string | null;
  is_default: boolean;
  role_codes: string[];
  department_ids: string[];
  layout_config: LayoutConfig;
  is_active: boolean;
  created_by: string | null;
  cloned_from: string | null;
  created_at: string;
  updated_at: string;
}

export interface DashboardSummary {
  id: string;
  name: string;
  code: string;
  description: string | null;
  is_default: boolean;
  role_codes: string[];
  department_ids: string[];
  user_id: string | null;
  is_active: boolean;
  widget_count: number;
  created_at: string;
}

export interface DashboardWidget {
  id: string;
  dashboard_id: string;
  widget_type: WidgetType;
  title: string;
  subtitle: string | null;
  icon: string | null;
  color: string | null;
  config: Record<string, unknown>;
  data_source: WidgetDataSource;
  data_filters: WidgetDataFilters;
  position_x: number;
  position_y: number;
  width: number;
  height: number;
  min_width: number;
  min_height: number;
  refresh_interval: number | null;
  is_visible: boolean;
  permission_code: string | null;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface DashboardWithWidgets {
  dashboard: Dashboard;
  widgets: DashboardWidget[];
}

export interface WidgetTemplate {
  id: string;
  tenant_id: string | null;
  name: string;
  description: string | null;
  widget_type: WidgetType;
  icon: string | null;
  color: string | null;
  default_config: Record<string, unknown>;
  default_source: Record<string, unknown>;
  default_width: number;
  default_height: number;
  category: string;
  is_system: boolean;
  required_permissions: string[];
  required_departments: string[];
  created_at: string;
}

export interface WidgetDataSource {
  type: "module_query" | "api" | "static";
  module?: string;
  query?: string;
  params?: Record<string, unknown>;
  static_data?: unknown;
}

export type DataFilterScope = "auto" | "all" | "custom";

export interface WidgetDataFilters {
  scope?: DataFilterScope;
  department_ids?: string[];
  doctor_id?: string;
  date_range?: "today" | "week" | "month" | "custom";
  custom_start?: string;
  custom_end?: string;
}

export interface StatCardConfig {
  format?: "number" | "currency" | "percent";
  trend_period?: "day" | "week" | "month";
  suffix?: string;
}

export interface DataTableConfig {
  columns: { key: string; label: string; sortable?: boolean }[];
  page_size?: number;
  show_search?: boolean;
  row_click_path?: string;
}

export interface ListConfig {
  max_items?: number;
  show_timestamp?: boolean;
  show_icon?: boolean;
  empty_message?: string;
}

export interface QuickActionsConfig {
  actions: {
    label: string;
    path: string;
    icon?: string;
    color?: string;
    permission?: string;
    description?: string;
  }[];
}

export interface ModuleEmbedConfig {
  module_code: string;
  view_mode: "card" | "table" | "compact_list" | "stats";
  filters?: Record<string, unknown>;
}

export interface ChartConfig {
  chart_type: "bar" | "line" | "pie" | "donut";
  x_key?: string;
  y_key?: string;
  colors?: string[];
}

export interface CreateDashboardRequest {
  name: string;
  code: string;
  description?: string;
  role_codes?: string[];
  department_ids?: string[];
  layout_config?: LayoutConfig;
  is_default?: boolean;
}

export interface UpdateDashboardRequest {
  name?: string;
  description?: string;
  role_codes?: string[];
  department_ids?: string[];
  layout_config?: LayoutConfig;
  is_default?: boolean;
  is_active?: boolean;
}

export interface PersonalizeDashboardRequest {
  source_dashboard_id: string;
  name?: string;
}

export interface CreateWidgetRequest {
  widget_type: WidgetType;
  title: string;
  subtitle?: string;
  icon?: string;
  color?: string;
  config?: Record<string, unknown>;
  data_source?: WidgetDataSource;
  data_filters?: WidgetDataFilters;
  position_x?: number;
  position_y?: number;
  width?: number;
  height?: number;
  refresh_interval?: number;
  permission_code?: string;
  template_id?: string;
}

export interface UpdateWidgetRequest {
  title?: string;
  subtitle?: string;
  icon?: string;
  color?: string;
  config?: Record<string, unknown>;
  data_source?: WidgetDataSource;
  data_filters?: WidgetDataFilters;
  position_x?: number;
  position_y?: number;
  width?: number;
  height?: number;
  refresh_interval?: number;
  is_visible?: boolean;
  permission_code?: string;
}

export interface UpdateLayoutRequest {
  widgets: {
    id: string;
    position_x: number;
    position_y: number;
    width: number;
    height: number;
  }[];
}

export interface WidgetDataResponse {
  widget_id: string;
  data: unknown;
  fetched_at: string;
}

export interface DashboardStatsResponse {
  total_patients: number;
  today_registrations: number;
  opd_queue_count: number;
  today_visits: number;
  lab_pending: number;
  today_revenue: string;
  today_appointments: number;
  ipd_active: number;
  recent_activity: RecentActivity[];
}

export interface RecentActivity {
  activity_type: string;
  description: string;
  occurred_at: string;
}

// ══════════════════════════════════════════════════════════
//  Indent / Store Module
// ══════════════════════════════════════════════════════════

export type IndentType = "general" | "pharmacy" | "lab" | "surgical" | "housekeeping" | "emergency";
export type IndentPriority = "normal" | "urgent" | "emergency";
export type IndentStatus =
  | "draft"
  | "submitted"
  | "approved"
  | "partially_approved"
  | "rejected"
  | "issued"
  | "partially_issued"
  | "closed"
  | "cancelled";
export type StockMovementType = "receipt" | "issue" | "return" | "adjustment" | "transfer";

export type VedClass = "vital" | "essential" | "desirable";
export type CondemnationStatus = "initiated" | "committee_review" | "approved" | "condemned" | "rejected";
export type SupplierPaymentStatus = "pending" | "partially_paid" | "paid" | "overdue" | "disputed";
export type ConsumableIssueStatus = "issued" | "returned" | "billed";

export interface StoreCatalog {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  category: string | null;
  sub_category: string | null;
  unit: string;
  base_price: string;
  current_stock: number;
  reorder_level: number;
  is_active: boolean;
  is_implant: boolean;
  is_high_value: boolean;
  ved_class: VedClass | null;
  hsn_code: string | null;
  bin_location: string | null;
  last_issue_date: string | null;
  last_receipt_date: string | null;
  min_stock: number;
  max_stock: number;
  created_at: string;
  updated_at: string;
}

export interface IndentRequisition {
  id: string;
  tenant_id: string;
  indent_number: string;
  department_id: string;
  requested_by: string;
  indent_type: IndentType;
  priority: IndentPriority;
  status: IndentStatus;
  total_amount: string;
  approved_by: string | null;
  approved_at: string | null;
  context: Record<string, unknown>;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface IndentItem {
  id: string;
  tenant_id: string;
  requisition_id: string;
  catalog_item_id: string | null;
  item_name: string;
  quantity_requested: number;
  quantity_approved: number;
  quantity_issued: number;
  unit_price: string;
  total_price: string;
  item_context: Record<string, unknown>;
  notes: string | null;
  created_at: string;
}

export interface StoreStockMovement {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  movement_type: StockMovementType;
  quantity: number;
  reference_type: string | null;
  reference_id: string | null;
  department_id: string | null;
  store_location_id: string | null;
  batch_stock_id: string | null;
  patient_id: string | null;
  notes: string | null;
  created_by: string;
  created_at: string;
}

export interface IndentRequisitionListResponse {
  requisitions: IndentRequisition[];
  total: number;
  page: number;
  per_page: number;
}

export interface IndentRequisitionDetailResponse {
  requisition: IndentRequisition;
  items: IndentItem[];
}

export interface CreateIndentItemInput {
  catalog_item_id?: string;
  item_name: string;
  quantity_requested: number;
  unit_price?: number;
  item_context?: Record<string, unknown>;
  notes?: string;
}

export interface CreateIndentRequisitionRequest {
  department_id: string;
  indent_type: IndentType;
  priority?: IndentPriority;
  context?: Record<string, unknown>;
  notes?: string;
  items: CreateIndentItemInput[];
}

export interface ApproveIndentItemInput {
  item_id: string;
  quantity_approved: number;
}

export interface ApproveIndentRequest {
  items: ApproveIndentItemInput[];
  notes?: string;
}

export interface IssueIndentItemInput {
  item_id: string;
  quantity_issued: number;
}

export interface IssueIndentRequest {
  items: IssueIndentItemInput[];
  notes?: string;
}

export interface CreateStoreCatalogRequest {
  code: string;
  name: string;
  category?: string;
  sub_category?: string;
  unit?: string;
  base_price?: number;
  reorder_level?: number;
}

export interface UpdateStoreCatalogRequest {
  name?: string;
  category?: string;
  sub_category?: string;
  unit?: string;
  base_price?: number;
  reorder_level?: number;
  is_active?: boolean;
  ved_class?: VedClass;
  is_implant?: boolean;
  is_high_value?: boolean;
  hsn_code?: string;
  bin_location?: string;
  min_stock?: number;
  max_stock?: number;
}

export interface StockMovementListResponse {
  movements: StoreStockMovement[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateStoreStockMovementRequest {
  catalog_item_id: string;
  movement_type: StockMovementType;
  quantity: number;
  reference_type?: string;
  reference_id?: string;
  notes?: string;
}

// ══════════════════════════════════════════════════════════
//  Inventory Phase 2
// ══════════════════════════════════════════════════════════

export interface PatientConsumableIssue {
  id: string;
  tenant_id: string;
  patient_id: string;
  catalog_item_id: string;
  batch_stock_id: string | null;
  department_id: string | null;
  encounter_id: string | null;
  admission_id: string | null;
  quantity: number;
  returned_qty: number;
  unit_price: string;
  status: ConsumableIssueStatus;
  is_chargeable: boolean;
  invoice_item_id: string | null;
  issued_by: string;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface ImplantRegistryEntry {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  batch_stock_id: string | null;
  patient_id: string;
  serial_number: string | null;
  implant_date: string;
  implant_site: string | null;
  surgeon_id: string | null;
  manufacturer: string | null;
  model_number: string | null;
  warranty_expiry: string | null;
  removal_date: string | null;
  removal_reason: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface EquipmentCondemnation {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  condemnation_number: string;
  status: CondemnationStatus;
  reason: string;
  current_value: string;
  purchase_value: string;
  committee_remarks: string | null;
  approved_by: string | null;
  approved_at: string | null;
  disposal_method: string | null;
  disposed_at: string | null;
  initiated_by: string;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface SupplierPayment {
  id: string;
  tenant_id: string;
  vendor_id: string;
  po_id: string | null;
  grn_id: string | null;
  payment_number: string;
  invoice_amount: string;
  paid_amount: string;
  balance_amount: string;
  status: SupplierPaymentStatus;
  payment_date: string | null;
  due_date: string | null;
  payment_method: string | null;
  reference_number: string | null;
  notes: string | null;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface ReorderAlert {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  alert_type: string;
  current_stock: number;
  threshold_level: number;
  is_acknowledged: boolean;
  acknowledged_by: string | null;
  acknowledged_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// Analytics row types
export interface ConsumptionAnalysisRow {
  item_name: string;
  department_name: string | null;
  total_issued: number;
  total_value: string;
}

export interface AbcAnalysisRow {
  item_name: string;
  annual_value: string;
  cumulative_pct: number;
  abc_class: string;
}

export interface VedAnalysisRow {
  item_name: string;
  ved_class: string | null;
  current_stock: number;
  reorder_level: number;
}

export interface FsnAnalysisRow {
  item_name: string;
  last_issue_date: string | null;
  days_since_last_issue: number | null;
  fsn_class: string;
}

export interface DeadStockRow {
  item_name: string;
  current_stock: number;
  stock_value: string;
  last_movement_date: string | null;
  days_idle: number | null;
}

export interface InventoryValuationRow {
  item_name: string;
  category: string | null;
  current_stock: number;
  avg_unit_cost: string;
  total_value: string;
}

export interface PurchaseConsumptionTrendRow {
  period: string;
  total_purchased: number;
  total_consumed: number;
  net_change: number;
}

export interface VendorPerformanceRow {
  vendor_name: string;
  total_orders: number;
  on_time_pct: number;
  rejection_rate: number;
  avg_delivery_days: number;
}

export interface VendorComparisonRow {
  vendor_name: string;
  item_name: string;
  unit_price: string;
  delivery_days: number | null;
  rejection_rate: number | null;
}

export interface ComplianceCheckRow {
  check_name: string;
  status: string;
  detail: string;
}

// Request types
export interface IssueToPatientRequest {
  patient_id: string;
  catalog_item_id: string;
  batch_stock_id?: string;
  department_id?: string;
  encounter_id?: string;
  admission_id?: string;
  quantity: number;
  unit_price?: number;
  is_chargeable?: boolean;
  notes?: string;
}

export interface DepartmentIssueRequest {
  catalog_item_id: string;
  department_id: string;
  quantity: number;
  notes?: string;
}

export interface ReturnToStoreRequest {
  catalog_item_id: string;
  quantity: number;
  department_id?: string;
  patient_consumable_id?: string;
  notes?: string;
}

export interface CreateImplantRequest {
  catalog_item_id: string;
  batch_stock_id?: string;
  patient_id: string;
  serial_number?: string;
  implant_date: string;
  implant_site?: string;
  surgeon_id?: string;
  manufacturer?: string;
  model_number?: string;
  warranty_expiry?: string;
  notes?: string;
}

export interface UpdateImplantRequest {
  implant_site?: string;
  manufacturer?: string;
  model_number?: string;
  warranty_expiry?: string;
  removal_date?: string;
  removal_reason?: string;
  notes?: string;
}

export interface CreateCondemnationRequest {
  catalog_item_id: string;
  reason: string;
  current_value?: number;
  purchase_value?: number;
  notes?: string;
}

export interface UpdateCondemnationStatusRequest {
  status: CondemnationStatus;
  committee_remarks?: string;
  disposal_method?: string;
}

export interface CreateSupplierPaymentRequest {
  vendor_id: string;
  po_id?: string;
  grn_id?: string;
  invoice_amount: number;
  paid_amount?: number;
  due_date?: string;
  payment_method?: string;
  reference_number?: string;
  notes?: string;
}

export interface UpdateSupplierPaymentRequest {
  paid_amount: number;
  payment_method?: string;
  reference_number?: string;
  notes?: string;
}

export interface CreateEmergencyPoRequest {
  vendor_id: string;
  store_location_id?: string;
  emergency_reason: string;
  expected_delivery?: string;
  notes?: string;
  items: CreatePoItemInput[];
}

export interface ConsignmentUsageRequest {
  batch_stock_id: string;
  quantity: number;
  patient_id?: string;
  notes?: string;
}

// ══════════════════════════════════════════════════════════
//  OPD Module
// ══════════════════════════════════════════════════════════

export type EncounterType = "opd" | "ipd" | "emergency";
export type EncounterStatus = "open" | "in_progress" | "completed" | "cancelled";
export type QueueStatus =
  | "waiting"
  | "called"
  | "in_consultation"
  | "completed"
  | "no_show";

export interface Encounter {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_type: EncounterType;
  status: EncounterStatus;
  department_id: string | null;
  doctor_id: string | null;
  encounter_date: string;
  notes: string | null;
  attributes: Record<string, unknown>;
  visit_type: string | null;
  created_at: string;
  updated_at: string;
}

export interface OpdQueue {
  id: string;
  tenant_id: string;
  encounter_id: string;
  department_id: string;
  doctor_id: string | null;
  token_number: number;
  status: QueueStatus;
  queue_date: string;
  called_at: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface QueueEntry {
  id: string;
  encounter_id: string;
  department_id: string;
  doctor_id: string | null;
  token_number: number;
  status: string;
  queue_date: string;
  called_at: string | null;
  completed_at: string | null;
  patient_id: string;
  patient_name: string;
  uhid: string;
}

export interface EncounterListResponse {
  encounters: Encounter[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateEncounterRequest {
  patient_id: string;
  department_id: string;
  doctor_id?: string;
  notes?: string;
  visit_type?: string;
}

export interface CreateEncounterResponse {
  encounter: Encounter;
  queue: OpdQueue;
}

export interface UpdateEncounterRequest {
  department_id?: string;
  doctor_id?: string;
  notes?: string;
  status?: string;
}

export interface Vital {
  id: string;
  tenant_id: string;
  encounter_id: string;
  temperature: string | null;
  pulse: number | null;
  systolic_bp: number | null;
  diastolic_bp: number | null;
  respiratory_rate: number | null;
  spo2: number | null;
  weight_kg: string | null;
  height_cm: string | null;
  bmi: string | null;
  notes: string | null;
  recorded_by: string;
  created_at: string;
}

export interface CreateVitalRequest {
  temperature?: number;
  pulse?: number;
  systolic_bp?: number;
  diastolic_bp?: number;
  respiratory_rate?: number;
  spo2?: number;
  weight_kg?: number;
  height_cm?: number;
  notes?: string;
}

// -- Structured History Types --

export interface PastMedicalEntry {
  condition: string;
  diagnosed_year?: number;
  status: "active" | "resolved" | "controlled";
  notes?: string;
}

export interface PastSurgicalEntry {
  procedure: string;
  year?: number;
  hospital?: string;
  notes?: string;
}

export interface FamilyHistoryEntry {
  relation: string;
  condition: string;
  age_of_onset?: number;
  is_alive?: boolean;
  notes?: string;
}

export interface SocialHistory {
  smoking?: { status: "never" | "former" | "current"; packs_per_day?: number; years?: number };
  alcohol?: { status: "never" | "occasional" | "moderate" | "heavy"; frequency?: string };
  tobacco_chewing?: { status: "never" | "former" | "current"; details?: string };
  occupation?: string;
  diet?: string;
  exercise?: string;
  notes?: string;
}

export interface ROSSystem {
  abnormal: boolean;
  details?: string;
}

export interface ReviewOfSystems {
  constitutional?: ROSSystem;
  eyes?: ROSSystem;
  ent?: ROSSystem;
  cardiovascular?: ROSSystem;
  respiratory?: ROSSystem;
  gi?: ROSSystem;
  genitourinary?: ROSSystem;
  musculoskeletal?: ROSSystem;
  skin?: ROSSystem;
  neurological?: ROSSystem;
  psychiatric?: ROSSystem;
  endocrine?: ROSSystem;
  hematologic?: ROSSystem;
  allergic_immunologic?: ROSSystem;
}

export interface PhysicalExamination {
  general?: string;
  heent?: string;
  neck?: string;
  cardiovascular?: string;
  respiratory?: string;
  abdomen?: string;
  musculoskeletal?: string;
  neurological?: string;
  skin?: string;
  extremities?: string;
  genitourinary?: string;
  psychiatric?: string;
}

export interface Consultation {
  id: string;
  tenant_id: string;
  encounter_id: string;
  doctor_id: string;
  chief_complaint: string | null;
  history: string | null;
  examination: string | null;
  plan: string | null;
  notes: string | null;
  hpi: string | null;
  past_medical_history: PastMedicalEntry[] | null;
  past_surgical_history: PastSurgicalEntry[] | null;
  family_history: FamilyHistoryEntry[] | null;
  social_history: SocialHistory | null;
  review_of_systems: ReviewOfSystems | null;
  physical_examination: PhysicalExamination | null;
  general_appearance: string | null;
  snomed_codes: Array<{ code: string; display: string }> | null;
  created_at: string;
  updated_at: string;
}

export interface CreateConsultationRequest {
  chief_complaint?: string;
  history?: string;
  examination?: string;
  plan?: string;
  notes?: string;
  hpi?: string;
  past_medical_history?: PastMedicalEntry[];
  past_surgical_history?: PastSurgicalEntry[];
  family_history?: FamilyHistoryEntry[];
  social_history?: SocialHistory;
  review_of_systems?: ReviewOfSystems;
  physical_examination?: PhysicalExamination;
  general_appearance?: string;
}

export interface UpdateConsultationRequest {
  chief_complaint?: string;
  history?: string;
  examination?: string;
  plan?: string;
  notes?: string;
  hpi?: string;
  past_medical_history?: PastMedicalEntry[];
  past_surgical_history?: PastSurgicalEntry[];
  family_history?: FamilyHistoryEntry[];
  social_history?: SocialHistory;
  review_of_systems?: ReviewOfSystems;
  physical_examination?: PhysicalExamination;
  general_appearance?: string;
  snomed_codes?: Array<{ code: string; display: string }>;
}

export type DiagnosisSeverity = "mild" | "moderate" | "severe" | "critical";
export type DiagnosisCertainty = "suspected" | "probable" | "confirmed" | "ruled_out";

export interface Diagnosis {
  id: string;
  tenant_id: string;
  encounter_id: string;
  icd_code: string | null;
  description: string;
  is_primary: boolean;
  notes: string | null;
  severity: string | null;
  certainty: string | null;
  onset_date: string | null;
  resolved_date: string | null;
  snomed_code: string | null;
  snomed_display: string | null;
  created_at: string;
}

export interface CreateDiagnosisRequest {
  icd_code?: string;
  description: string;
  is_primary?: boolean;
  notes?: string;
  severity?: DiagnosisSeverity;
  certainty?: DiagnosisCertainty;
  onset_date?: string;
  resolved_date?: string;
  snomed_code?: string;
  snomed_display?: string;
}

// -- ICD-10 Reference --

export interface Icd10Code {
  id: string;
  code: string;
  short_desc: string;
  long_desc: string | null;
  category: string | null;
  chapter: string | null;
  is_billable: boolean;
  is_active: boolean;
  created_at: string;
}

// -- SNOMED CT Reference --

export interface SnomedCode {
  id: string;
  code: string;
  display_name: string;
  semantic_tag: string | null;
  is_active: boolean;
  created_at: string;
}

// -- Wait Time Estimation --

export interface WaitEstimate {
  estimated_minutes: number;
  queue_position: number;
  avg_consultation_minutes: number;
}

// -- Multi-Doctor Appointment Group --

export interface SlotRequest {
  doctor_id: string;
  department_id: string;
  appointment_date: string;
  slot_start: string;
  slot_end: string;
  appointment_type?: AppointmentType;
  notes?: string;
}

export interface BookAppointmentGroupRequest {
  patient_id: string;
  slot_requests: SlotRequest[];
}

// -- OPD → IPD Admission --

export interface AdmitFromOpdRequest {
  department_id: string;
  ward_id?: string;
  bed_id?: string;
  doctor_id?: string;
  notes?: string;
}

export interface AdmitFromOpdResponse {
  ipd_encounter: Encounter;
  admission: Admission;
  vitals_copied: number;
  diagnoses_copied: number;
  prescriptions_copied: number;
}

// -- Available Beds --

export interface AvailableBed {
  bed_id: string;
  bed_number: string;
  ward_id: string | null;
  ward_name: string | null;
  room_number: string | null;
  bed_type: string | null;
  is_isolation: boolean;
}

// -- Chief Complaint Masters --

export interface ChiefComplaintMaster {
  id: string;
  tenant_id: string;
  name: string;
  category: string | null;
  synonyms: string[];
  suggested_icd: string[];
  is_active: boolean;
  created_at: string;
}

export interface Prescription {
  id: string;
  tenant_id: string;
  encounter_id: string;
  doctor_id: string;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// ── Medication Timing (structured instructions) ──────────────
export type FoodTiming = "before_food" | "with_food" | "after_food" | "empty_stomach" | "any";
export type TimeOfDay = "morning" | "afternoon" | "evening" | "bedtime";

export interface MedicationTiming {
  _v: 1;
  food_timing?: FoodTiming;
  time_slots?: TimeOfDay[];
  specific_times?: string[];
  custom_instruction?: string;
}

export interface PrescriptionItem {
  id: string;
  tenant_id: string;
  prescription_id: string;
  drug_name: string;
  dosage: string;
  frequency: string;
  duration: string;
  route: string | null;
  instructions: string | null;
  created_at: string;
}

export interface PrescriptionItemInput {
  drug_name: string;
  dosage: string;
  frequency: string;
  duration: string;
  route?: string;
  instructions?: string;
}

export interface CreatePrescriptionRequest {
  notes?: string;
  items: PrescriptionItemInput[];
}

export interface PrescriptionWithItems {
  prescription: Prescription;
  items: PrescriptionItem[];
}

export interface PrescriptionTemplate {
  id: string;
  tenant_id: string;
  created_by: string;
  name: string;
  description: string | null;
  department_id: string | null;
  is_shared: boolean;
  items: PrescriptionItemInput[];
  created_at: string;
  updated_at: string;
}

export interface CreatePrescriptionTemplateRequest {
  name: string;
  description?: string;
  department_id?: string;
  is_shared?: boolean;
  items: PrescriptionItemInput[];
}

export interface PrescriptionHistoryItem {
  prescription: Prescription;
  items: PrescriptionItem[];
  encounter_date: string;
  doctor_name: string | null;
}

export type CertificateType = "medical" | "fitness" | "sick_leave" | "disability" | "death" | "birth" | "custom";

export interface MedicalCertificate {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string | null;
  doctor_id: string;
  certificate_type: CertificateType;
  certificate_number: string | null;
  issued_date: string;
  valid_from: string | null;
  valid_to: string | null;
  diagnosis: string | null;
  remarks: string | null;
  body: Record<string, unknown>;
  is_void: boolean;
  voided_by: string | null;
  voided_at: string | null;
  void_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateMedicalCertificateRequest {
  patient_id: string;
  encounter_id?: string;
  certificate_type: CertificateType;
  issued_date?: string;
  valid_from?: string;
  valid_to?: string;
  diagnosis?: string;
  remarks?: string;
  body: Record<string, unknown>;
}

// ══════════════════════════════════════════════════════════
//  Vitals History (Trend Charts)
// ══════════════════════════════════════════════════════════

export interface VitalHistoryPoint {
  id: string;
  encounter_id: string;
  encounter_date: string;
  temperature: number | null;
  pulse: number | null;
  systolic_bp: number | null;
  diastolic_bp: number | null;
  respiratory_rate: number | null;
  spo2: number | null;
  weight_kg: number | null;
  height_cm: number | null;
  bmi: number | null;
  recorded_at: string;
}

// ══════════════════════════════════════════════════════════
//  Referrals
// ══════════════════════════════════════════════════════════

export type ReferralUrgency = "routine" | "urgent" | "emergency";
export type ReferralStatus = "pending" | "accepted" | "declined" | "completed" | "cancelled";

export interface ReferralWithNames {
  id: string;
  patient_id: string;
  encounter_id: string | null;
  from_department_id: string;
  from_department_name: string | null;
  to_department_id: string;
  to_department_name: string | null;
  from_doctor_id: string | null;
  from_doctor_name: string | null;
  to_doctor_id: string | null;
  to_doctor_name: string | null;
  urgency: ReferralUrgency;
  status: ReferralStatus;
  reason: string;
  clinical_notes: string | null;
  response_notes: string | null;
  responded_at: string | null;
  created_at: string;
}

export interface CreateReferralRequest {
  patient_id: string;
  encounter_id?: string;
  to_department_id: string;
  to_doctor_id?: string;
  urgency?: ReferralUrgency;
  reason: string;
  clinical_notes?: string;
}

// ══════════════════════════════════════════════════════════
//  Procedure Catalog & Orders
// ══════════════════════════════════════════════════════════

export interface ProcedureCatalog {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  description: string | null;
  department_id: string | null;
  category: string | null;
  base_price: number | null;
  duration_minutes: number | null;
  requires_consent: boolean;
  requires_anesthesia: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type ProcedureOrderStatus = "ordered" | "scheduled" | "in_progress" | "completed" | "cancelled";

export interface ProcedureOrderWithName {
  id: string;
  patient_id: string;
  encounter_id: string;
  procedure_id: string;
  procedure_name: string | null;
  procedure_code: string | null;
  ordered_by: string;
  priority: string;
  status: ProcedureOrderStatus;
  scheduled_date: string | null;
  notes: string | null;
  findings: string | null;
  created_at: string;
}

export interface CreateProcedureOrderRequest {
  patient_id: string;
  encounter_id: string;
  procedure_id: string;
  priority?: string;
  scheduled_date?: string;
  notes?: string;
}

// ══════════════════════════════════════════════════════════
//  Duplicate Order Detection
// ══════════════════════════════════════════════════════════

export interface DuplicateOrderInfo {
  id: string;
  order_type: string;
  name: string | null;
  status: string;
  created_at: string;
}

// ══════════════════════════════════════════════════════════
//  Doctor Dockets
// ══════════════════════════════════════════════════════════

export interface DoctorDocket {
  id: string;
  tenant_id: string;
  doctor_id: string;
  docket_date: string;
  total_patients: number;
  new_patients: number;
  follow_ups: number;
  referrals_made: number;
  procedures_done: number;
  notes: string | null;
  generated_at: string;
  created_at: string;
}

// ══════════════════════════════════════════════════════════
//  Patient Reminders
// ══════════════════════════════════════════════════════════

export type ReminderType =
  | "follow_up"
  | "lab_review"
  | "medication_review"
  | "vaccination"
  | "screening"
  | "custom";

export type ReminderStatus =
  | "pending"
  | "sent"
  | "acknowledged"
  | "completed"
  | "cancelled"
  | "overdue";

export type ReminderPriority = "low" | "normal" | "high" | "urgent";

export interface PatientReminder {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string | null;
  doctor_id: string;
  reminder_type: ReminderType;
  reminder_date: string;
  title: string;
  description: string | null;
  priority: ReminderPriority;
  status: ReminderStatus;
  notification_channels: string[];
  completed_at: string | null;
  cancelled_at: string | null;
  cancel_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateReminderRequest {
  patient_id: string;
  encounter_id?: string;
  reminder_type: ReminderType;
  reminder_date: string;
  title: string;
  description?: string;
  priority?: ReminderPriority;
}

// ══════════════════════════════════════════════════════════
//  Patient Feedback
// ══════════════════════════════════════════════════════════

export interface PatientFeedback {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string | null;
  doctor_id: string | null;
  department_id: string | null;
  rating: number | null;
  wait_time_rating: number | null;
  staff_rating: number | null;
  cleanliness_rating: number | null;
  overall_experience: string | null;
  suggestions: string | null;
  would_recommend: boolean | null;
  is_anonymous: boolean;
  submitted_at: string;
  created_at: string;
}

export interface CreateFeedbackRequest {
  patient_id: string;
  encounter_id?: string;
  doctor_id?: string;
  department_id?: string;
  rating?: number;
  wait_time_rating?: number;
  staff_rating?: number;
  cleanliness_rating?: number;
  overall_experience?: string;
  suggestions?: string;
  would_recommend?: boolean;
  is_anonymous?: boolean;
}

// ══════════════════════════════════════════════════════════
//  Procedure Consents
// ══════════════════════════════════════════════════════════

export type ProcedureConsentStatus = "pending" | "signed" | "refused" | "withdrawn" | "expired";

export type ProcedureConsentType =
  | "procedure"
  | "anesthesia"
  | "blood_transfusion"
  | "surgery"
  | "investigation"
  | "general";

export interface ProcedureConsent {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string | null;
  procedure_order_id: string | null;
  procedure_name: string;
  consent_type: ProcedureConsentType;
  risks_explained: string | null;
  alternatives_explained: string | null;
  benefits_explained: string | null;
  patient_questions: string | null;
  consented_by_name: string | null;
  consented_by_relation: string | null;
  witness_name: string | null;
  witness_designation: string | null;
  doctor_id: string;
  status: ProcedureConsentStatus;
  signed_at: string | null;
  refused_at: string | null;
  refusal_reason: string | null;
  withdrawn_at: string | null;
  withdrawal_reason: string | null;
  expires_at: string | null;
  body: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface CreateConsentRequest {
  patient_id: string;
  encounter_id?: string;
  procedure_order_id?: string;
  procedure_name: string;
  consent_type?: ProcedureConsentType;
  risks_explained?: string;
  alternatives_explained?: string;
  benefits_explained?: string;
  patient_questions?: string;
  consented_by_name?: string;
  consented_by_relation?: string;
  witness_name?: string;
  witness_designation?: string;
}

// ══════════════════════════════════════════════════════════
//  Patient Diagnoses (cross-encounter)
// ══════════════════════════════════════════════════════════

export interface PatientDiagnosisRow {
  id: string;
  encounter_id: string;
  icd_code: string | null;
  description: string;
  is_primary: boolean;
  severity: string | null;
  certainty: string | null;
  onset_date: string | null;
  resolved_date: string | null;
  encounter_date: string;
  doctor_name: string | null;
  created_at: string;
}

// ══════════════════════════════════════════════════════════
//  Consultation Templates
// ══════════════════════════════════════════════════════════

export interface ConsultationTemplate {
  id: string;
  tenant_id: string;
  created_by: string;
  name: string;
  description: string | null;
  specialty: string | null;
  department_id: string | null;
  is_shared: boolean;
  chief_complaints: string[];
  default_history: Record<string, unknown>;
  default_examination: Record<string, unknown>;
  default_ros: Record<string, unknown>;
  default_plan: string | null;
  common_diagnoses: string[];
  common_medications: Record<string, unknown>[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateConsultationTemplateRequest {
  name: string;
  description?: string;
  specialty?: string;
  department_id?: string;
  is_shared: boolean;
  chief_complaints?: string[];
  default_history?: Record<string, unknown>;
  default_examination?: Record<string, unknown>;
  default_ros?: Record<string, unknown>;
  default_plan?: string;
  common_diagnoses?: string[];
  common_medications?: Record<string, unknown>[];
}

// ══════════════════════════════════════════════════════════
//  OPD Appointments
// ══════════════════════════════════════════════════════════

export type AppointmentStatus =
  | "scheduled"
  | "confirmed"
  | "checked_in"
  | "in_consultation"
  | "completed"
  | "cancelled"
  | "no_show";

export type AppointmentType =
  | "new_visit"
  | "follow_up"
  | "consultation"
  | "procedure"
  | "walk_in";

export interface DoctorSchedule {
  id: string;
  tenant_id: string;
  doctor_id: string;
  department_id: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  slot_duration_mins: number;
  max_patients: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface DoctorScheduleException {
  id: string;
  tenant_id: string;
  doctor_id: string;
  exception_date: string;
  is_available: boolean;
  start_time: string | null;
  end_time: string | null;
  reason: string | null;
  created_at: string;
}

export interface Appointment {
  id: string;
  tenant_id: string;
  patient_id: string;
  doctor_id: string;
  department_id: string;
  appointment_date: string;
  slot_start: string;
  slot_end: string;
  appointment_type: AppointmentType;
  status: AppointmentStatus;
  token_number: number | null;
  reason: string | null;
  cancel_reason: string | null;
  notes: string | null;
  encounter_id: string | null;
  checked_in_at: string | null;
  completed_at: string | null;
  cancelled_at: string | null;
  recurrence_pattern: string | null;
  recurrence_group_id: string | null;
  recurrence_index: number | null;
  appointment_group_id: string | null;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface AppointmentWithPatient extends Appointment {
  patient_name: string;
  doctor_name: string;
}

export interface AvailableSlot {
  start_time: string;
  end_time: string;
  booked_count: number;
  max_patients: number;
  is_available: boolean;
}

export interface CreateScheduleRequest {
  doctor_id: string;
  department_id: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  slot_duration_mins?: number;
  max_patients?: number;
}

export interface UpdateScheduleRequest {
  start_time?: string;
  end_time?: string;
  slot_duration_mins?: number;
  max_patients?: number;
  is_active?: boolean;
}

export interface CreateScheduleExceptionRequest {
  doctor_id: string;
  exception_date: string;
  is_available?: boolean;
  start_time?: string;
  end_time?: string;
  reason?: string;
}

export interface BookAppointmentRequest {
  patient_id: string;
  doctor_id: string;
  department_id: string;
  appointment_date: string;
  slot_start: string;
  slot_end: string;
  appointment_type?: AppointmentType;
  reason?: string;
  notes?: string;
  recurrence_pattern?: "weekly" | "biweekly" | "monthly";
  recurrence_count?: number;
}

export interface RescheduleAppointmentRequest {
  appointment_date: string;
  slot_start: string;
  slot_end: string;
}

export interface CancelAppointmentRequest {
  cancel_reason?: string;
}

// ══════════════════════════════════════════════════════════
//  Patient Visit History / Timeline
// ══════════════════════════════════════════════════════════

export interface PatientVisitRow {
  id: string;
  encounter_type: "opd" | "ipd" | "emergency";
  status: "open" | "in_progress" | "completed" | "cancelled";
  encounter_date: string;
  doctor_name: string | null;
  department_name: string | null;
  chief_complaint: string | null;
  diagnosis_count: number | null;
  prescription_count: number | null;
  lab_order_count: number | null;
  created_at: string;
}

export interface PatientLabOrderRow {
  id: string;
  test_name: string | null;
  status: string;
  priority: string;
  ordered_by_name: string | null;
  result_count: number | null;
  created_at: string;
  updated_at: string;
}

export interface PatientInvoiceRow {
  id: string;
  invoice_number: string;
  status: InvoiceStatus;
  total_amount: string;
  paid_amount: string;
  balance: string;
  item_count: number | null;
  issued_at: string | null;
  created_at: string;
}

export interface PatientAppointmentRow {
  id: string;
  appointment_date: string;
  slot_start: string;
  slot_end: string;
  appointment_type: string;
  status: string;
  doctor_name: string | null;
  department_name: string | null;
  reason: string | null;
  created_at: string;
}

// ══════════════════════════════════════════════════════════
//  Billing Module
// ══════════════════════════════════════════════════════════

export type InvoiceStatus =
  | "draft"
  | "issued"
  | "partially_paid"
  | "paid"
  | "cancelled"
  | "refunded";
export type ChargeSource = "opd" | "ipd" | "lab" | "pharmacy" | "procedure" | "radiology" | "manual" | "ot" | "emergency" | "diet" | "cssd";
export type PaymentMode = "cash" | "card" | "upi" | "bank_transfer" | "cheque" | "insurance" | "credit";

export interface Invoice {
  id: string;
  tenant_id: string;
  invoice_number: string;
  patient_id: string;
  encounter_id: string | null;
  status: InvoiceStatus;
  subtotal: string;
  tax_amount: string;
  discount_amount: string;
  total_amount: string;
  paid_amount: string;
  notes: string | null;
  issued_at: string | null;
  cgst_amount: string;
  sgst_amount: string;
  igst_amount: string;
  cess_amount: string;
  is_interim: boolean;
  billing_period_start: string | null;
  billing_period_end: string | null;
  sequence_number: number | null;
  corporate_id: string | null;
  place_of_supply: string | null;
  is_er_deferred: boolean;
  cloned_from_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface InvoiceItem {
  id: string;
  tenant_id: string;
  invoice_id: string;
  charge_code: string;
  description: string;
  source: ChargeSource;
  source_id: string | null;
  quantity: number;
  unit_price: string;
  tax_percent: string;
  total_price: string;
  gst_rate: string;
  gst_type: GstType;
  cgst_amount: string;
  sgst_amount: string;
  igst_amount: string;
  hsn_sac_code: string | null;
  ordering_doctor_id: string | null;
  department_id: string | null;
  created_at: string;
}

export interface Payment {
  id: string;
  tenant_id: string;
  invoice_id: string;
  amount: string;
  mode: PaymentMode;
  reference_number: string | null;
  received_by: string | null;
  notes: string | null;
  paid_at: string;
  created_at: string;
}

export interface ChargeMaster {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  category: string;
  base_price: string;
  tax_percent: string;
  is_active: boolean;
  hsn_sac_code: string | null;
  gst_category: string | null;
  created_at: string;
  updated_at: string;
}

export interface InvoiceListResponse {
  invoices: Invoice[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateInvoiceRequest {
  patient_id: string;
  encounter_id?: string;
  notes?: string;
  is_er_deferred?: boolean;
}

export interface AddInvoiceItemRequest {
  charge_code: string;
  description: string;
  source: string;
  source_id?: string;
  quantity: number;
  unit_price: number;
  tax_percent?: number;
  ordering_doctor_id?: string;
  department_id?: string;
}

export interface RecordPaymentRequest {
  amount: number;
  mode: string;
  reference_number?: string;
  notes?: string;
}

export interface InvoiceDetailResponse {
  invoice: Invoice;
  items: InvoiceItem[];
  payments: Payment[];
}

export interface CreateChargeMasterRequest {
  code: string;
  name: string;
  category: string;
  base_price: number;
  tax_percent?: number;
  hsn_sac_code?: string;
  gst_category?: string;
}

export interface UpdateChargeMasterRequest {
  name?: string;
  category?: string;
  base_price?: number;
  tax_percent?: number;
  is_active?: boolean;
  hsn_sac_code?: string;
  gst_category?: string;
}

// -- Billing Packages --

export interface BillingPackage {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  description: string | null;
  total_price: string;
  discount_percent: string;
  is_active: boolean;
  valid_from: string | null;
  valid_to: string | null;
  created_at: string;
  updated_at: string;
}

export interface BillingPackageItem {
  id: string;
  tenant_id: string;
  package_id: string;
  charge_code: string;
  description: string;
  quantity: number;
  unit_price: string;
  created_at: string;
}

export interface CreatePackageRequest {
  code: string;
  name: string;
  description?: string;
  total_price: number;
  discount_percent?: number;
  valid_from?: string;
  valid_to?: string;
  items: CreatePackageItemRequest[];
}

export interface CreatePackageItemRequest {
  charge_code: string;
  description: string;
  quantity: number;
  unit_price: number;
}

export interface UpdatePackageRequest {
  name?: string;
  description?: string;
  total_price?: number;
  discount_percent?: number;
  is_active?: boolean;
  valid_from?: string;
  valid_to?: string;
}

export interface PackageDetailResponse {
  package: BillingPackage;
  items: BillingPackageItem[];
}

// -- Rate Plans --

export interface RatePlan {
  id: string;
  tenant_id: string;
  name: string;
  description: string | null;
  patient_category: string | null;
  is_default: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface RatePlanItem {
  id: string;
  tenant_id: string;
  rate_plan_id: string;
  charge_code: string;
  override_price: string;
  override_tax_percent: string | null;
  created_at: string;
}

export interface CreateRatePlanRequest {
  name: string;
  description?: string;
  patient_category?: string;
  is_default?: boolean;
  items: CreateRatePlanItemRequest[];
}

export interface CreateRatePlanItemRequest {
  charge_code: string;
  override_price: number;
  override_tax_percent?: number;
}

export interface UpdateRatePlanRequest {
  name?: string;
  description?: string;
  patient_category?: string;
  is_default?: boolean;
  is_active?: boolean;
}

export interface RatePlanDetailResponse {
  plan: RatePlan;
  items: RatePlanItem[];
}

// -- Discounts --

export interface InvoiceDiscount {
  id: string;
  tenant_id: string;
  invoice_id: string;
  discount_type: string;
  discount_value: string;
  reason: string | null;
  approved_by: string | null;
  created_at: string;
}

export interface AddDiscountRequest {
  discount_type: string;
  discount_value: number;
  reason?: string;
}

// -- Refunds --

export interface Refund {
  id: string;
  tenant_id: string;
  invoice_id: string;
  payment_id: string | null;
  refund_number: string;
  amount: string;
  reason: string;
  mode: PaymentMode;
  reference_number: string | null;
  refunded_by: string | null;
  refunded_at: string;
  created_at: string;
}

export interface CreateRefundRequest {
  invoice_id: string;
  payment_id?: string;
  amount: number;
  reason: string;
  mode: string;
  reference_number?: string;
}

// -- Credit Notes --

export type CreditNoteStatus = "active" | "used" | "cancelled";

export interface CreditNote {
  id: string;
  tenant_id: string;
  credit_note_number: string;
  invoice_id: string;
  amount: string;
  reason: string;
  status: CreditNoteStatus;
  used_against_invoice_id: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateCreditNoteRequest {
  invoice_id: string;
  amount: number;
  reason: string;
}

// -- Receipts --

export interface Receipt {
  id: string;
  tenant_id: string;
  receipt_number: string;
  invoice_id: string;
  payment_id: string;
  amount: string;
  receipt_date: string;
  printed_at: string | null;
  created_at: string;
}

// -- Insurance Claims --

export type InsuranceClaimType = "cashless" | "reimbursement";
export type InsuranceClaimStatus =
  | "initiated"
  | "pre_auth_requested"
  | "pre_auth_approved"
  | "pre_auth_rejected"
  | "claim_submitted"
  | "claim_approved"
  | "claim_rejected"
  | "settled"
  | "partially_settled";

export type InsuranceSchemeType = "private" | "cghs" | "echs" | "pmjay" | "esis" | "state_scheme";

export interface InsuranceClaim {
  id: string;
  tenant_id: string;
  invoice_id: string;
  patient_id: string;
  insurance_provider: string;
  policy_number: string | null;
  claim_number: string | null;
  claim_type: InsuranceClaimType;
  status: InsuranceClaimStatus;
  pre_auth_amount: string | null;
  approved_amount: string | null;
  settled_amount: string | null;
  tpa_name: string | null;
  notes: string | null;
  submitted_at: string | null;
  settled_at: string | null;
  created_by: string | null;
  scheme_type: InsuranceSchemeType;
  co_pay_percent: string | null;
  deductible_amount: string | null;
  member_id: string | null;
  scheme_card_number: string | null;
  is_secondary: boolean;
  primary_claim_id: string | null;
  tpa_rate_plan_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateInsuranceClaimRequest {
  invoice_id: string;
  patient_id: string;
  insurance_provider: string;
  policy_number?: string;
  claim_type: string;
  pre_auth_amount?: number;
  tpa_name?: string;
  notes?: string;
  scheme_type?: string;
  co_pay_percent?: number;
  deductible_amount?: number;
  member_id?: string;
  scheme_card_number?: string;
}

export interface UpdateInsuranceClaimRequest {
  status?: string;
  claim_number?: string;
  approved_amount?: number;
  settled_amount?: number;
  notes?: string;
}

// -- Auto-Billing --

export interface ManualAutoChargeRequest {
  encounter_id: string;
  modules: string[];
}

export interface ManualAutoChargeResponse {
  invoice_id: string | null;
  items_added: number;
  items_skipped: number;
  errors: string[];
}

// -- Billing Phase 2: GST, Advances, Corporate, Reports --

export type GstType = "cgst_sgst" | "igst" | "exempt";
export type AdvancePurpose = "admission" | "prepaid" | "general" | "procedure";
export type AdvanceStatus = "active" | "partially_used" | "fully_used" | "refunded";

export interface PatientAdvance {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string | null;
  advance_number: string;
  amount: string;
  balance: string;
  payment_mode: PaymentMode;
  reference_number: string | null;
  purpose: AdvancePurpose;
  status: AdvanceStatus;
  received_by: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdvanceAdjustment {
  id: string;
  tenant_id: string;
  advance_id: string;
  invoice_id: string;
  amount_adjusted: string;
  adjusted_by: string | null;
  notes: string | null;
  created_at: string;
}

export interface CorporateClient {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  gst_number: string | null;
  billing_address: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  credit_limit: string;
  credit_days: number;
  agreed_discount_percent: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface CorporateEnrollment {
  id: string;
  tenant_id: string;
  corporate_id: string;
  patient_id: string;
  employee_id: string | null;
  department: string | null;
  is_active: boolean;
  enrolled_at: string;
  created_at: string;
}

export interface CreateAdvanceRequest {
  patient_id: string;
  encounter_id?: string;
  amount: number;
  payment_mode: string;
  reference_number?: string;
  purpose?: string;
  notes?: string;
}

export interface AdjustAdvanceRequest {
  invoice_id: string;
  amount: number;
  notes?: string;
}

export interface RefundAdvanceRequest {
  amount: number;
  reason: string;
  mode?: string;
  reference_number?: string;
}

export interface CreateInterimInvoiceRequest {
  encounter_id: string;
  patient_id: string;
  notes?: string;
}

export interface CreateCorporateRequest {
  code: string;
  name: string;
  gst_number?: string;
  billing_address?: string;
  contact_email?: string;
  contact_phone?: string;
  credit_limit?: number;
  credit_days?: number;
  agreed_discount_percent?: number;
}

export interface UpdateCorporateRequest {
  name?: string;
  gst_number?: string;
  billing_address?: string;
  contact_email?: string;
  contact_phone?: string;
  credit_limit?: number;
  credit_days?: number;
  agreed_discount_percent?: number;
  is_active?: boolean;
}

export interface CreateEnrollmentRequest {
  patient_id: string;
  employee_id?: string;
  department?: string;
}

export interface BillingSummaryReport {
  total_invoiced: string;
  total_collected: string;
  total_outstanding: string;
  total_refunded: string;
  total_discounts: string;
  invoice_count: number;
  payment_modes: PaymentModeSummary[];
}

export interface PaymentModeSummary {
  mode: string;
  total: string;
  count: number;
}

export interface DepartmentRevenueRow {
  department: string;
  total_revenue: string;
  invoice_count: number;
}

export interface CollectionEfficiencyReport {
  overall_rate: string;
  months: MonthlyEfficiency[];
}

export interface MonthlyEfficiency {
  month: string;
  invoiced: string;
  collected: string;
  rate: string;
}

export interface AgingBucket {
  bucket: string;
  count: number;
  total_amount: string;
}

export interface DailySummary {
  date: string;
  invoices_created: number;
  invoices_issued: number;
  total_billed: string;
  total_collected: string;
  payments: PaymentModeSummary[];
}

// -- Day Close, Write-Offs, TPA Rate Cards, Audit --

export type DayCloseStatus = "open" | "verified" | "discrepancy";
export type WriteOffStatus = "pending" | "approved" | "rejected";
export type AuditAction =
  | "invoice_created"
  | "invoice_issued"
  | "invoice_cancelled"
  | "payment_recorded"
  | "payment_voided"
  | "refund_created"
  | "discount_applied"
  | "discount_removed"
  | "advance_collected"
  | "advance_adjusted"
  | "advance_refunded"
  | "credit_note_created"
  | "credit_note_applied"
  | "claim_created"
  | "claim_updated"
  | "day_closed"
  | "write_off_created"
  | "write_off_approved"
  | "invoice_cloned";

export interface DayEndClose {
  id: string;
  tenant_id: string;
  close_date: string;
  cashier_id: string;
  expected_cash: string;
  actual_cash: string;
  cash_difference: string;
  total_card: string;
  total_upi: string;
  total_cheque: string;
  total_bank_transfer: string;
  total_insurance: string;
  total_collected: string;
  invoices_count: number;
  payments_count: number;
  refunds_total: string;
  advances_total: string;
  status: DayCloseStatus;
  verified_by: string | null;
  verified_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface BadDebtWriteOff {
  id: string;
  tenant_id: string;
  invoice_id: string;
  write_off_number: string;
  amount: string;
  reason: string;
  status: WriteOffStatus;
  requested_by: string | null;
  approved_by: string | null;
  approved_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface BillingAuditEntry {
  id: string;
  tenant_id: string;
  action: AuditAction;
  entity_type: string;
  entity_id: string;
  invoice_id: string | null;
  patient_id: string | null;
  amount: string | null;
  previous_state: unknown;
  new_state: unknown;
  performed_by: string | null;
  ip_address: string | null;
  created_at: string;
}

export interface TpaRateCard {
  id: string;
  tenant_id: string;
  tpa_name: string;
  insurance_provider: string;
  rate_plan_id: string | null;
  scheme_type: string | null;
  valid_from: string | null;
  valid_to: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateDayCloseRequest {
  close_date: string;
  actual_cash: number;
  notes?: string;
}

export interface CreateWriteOffRequest {
  invoice_id: string;
  amount: number;
  reason: string;
  notes?: string;
}

export interface ApproveWriteOffRequest {
  approved: boolean;
  notes?: string;
}

export interface CreateTpaRateCardRequest {
  tpa_name: string;
  insurance_provider: string;
  rate_plan_id?: string;
  scheme_type?: string;
  valid_from?: string;
  valid_to?: string;
  is_active?: boolean;
}

export interface UpdateTpaRateCardRequest {
  tpa_name?: string;
  insurance_provider?: string;
  rate_plan_id?: string;
  scheme_type?: string;
  valid_from?: string;
  valid_to?: string;
  is_active?: boolean;
}

export interface DoctorRevenueRow {
  doctor_id: string | null;
  doctor_name: string;
  total_revenue: string;
  item_count: number;
}

export interface InsurancePanelRow {
  insurance_provider: string;
  total_claims: number;
  total_claimed: string;
  total_approved: string;
  total_settled: string;
  pending_count: number;
}

export interface ReconciliationReport {
  close_date: string;
  expected_cash: string;
  actual_cash: string;
  cash_difference: string;
  system_total: string;
  total_payments: string;
  total_refunds: string;
  variance: string;
  status: DayCloseStatus;
}

export interface AuditLogResponse {
  entries: BillingAuditEntry[];
  total: number;
  page: number;
  per_page: number;
}

// ══════════════════════════════════════════════════════════
//  Billing Phase 3 — Multi-Currency, Credit, Accounting, TDS, GST, ERP
// ══════════════════════════════════════════════════════════

export type CurrencyCode = "INR" | "USD" | "EUR" | "GBP" | "AED" | "SAR" | "SGD" | "BDT" | "NPR" | "LKR";
export type CreditPatientStatus = "active" | "overdue" | "suspended" | "closed";
export type JournalEntryType = "manual" | "auto_invoice" | "auto_payment" | "auto_refund" | "auto_write_off" | "auto_advance";
export type JournalEntryStatus = "draft" | "posted" | "reversed";
export type ReconStatus = "unmatched" | "matched" | "discrepancy" | "excluded";
export type GstrFilingStatus = "draft" | "validated" | "filed" | "accepted" | "error";
export type TdsStatus = "deducted" | "deposited" | "certificate_issued";
export type ErpExportStatus = "pending" | "exported" | "failed" | "acknowledged";

export interface ExchangeRate {
  id: string;
  tenant_id: string;
  from_currency: CurrencyCode;
  to_currency: CurrencyCode;
  rate: number;
  effective_date: string;
  source: string | null;
  created_at: string;
}

export interface CreditPatient {
  id: string;
  tenant_id: string;
  patient_id: string;
  credit_limit: number;
  current_balance: number;
  status: CreditPatientStatus;
  approved_by: string | null;
  overdue_since: string | null;
  reason: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface GlAccount {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  account_type: "asset" | "liability" | "equity" | "revenue" | "expense";
  parent_id: string | null;
  is_active: boolean;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface JournalEntry {
  id: string;
  tenant_id: string;
  entry_number: string;
  entry_date: string;
  entry_type: JournalEntryType;
  status: JournalEntryStatus;
  total_debit: number;
  total_credit: number;
  description: string | null;
  reference_type: string | null;
  reference_id: string | null;
  posted_by: string | null;
  posted_at: string | null;
  reversal_of_id: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface JournalEntryLine {
  id: string;
  tenant_id: string;
  journal_entry_id: string;
  account_id: string;
  department_id: string | null;
  debit_amount: number;
  credit_amount: number;
  narration: string | null;
  created_at: string;
}

export interface JournalEntryDetail {
  entry: JournalEntry;
  lines: JournalEntryLine[];
}

export interface BankTransaction {
  id: string;
  tenant_id: string;
  bank_name: string;
  account_number: string;
  transaction_date: string;
  value_date: string | null;
  description: string | null;
  debit_amount: number;
  credit_amount: number;
  running_balance: number | null;
  reference_number: string | null;
  recon_status: ReconStatus;
  matched_payment_id: string | null;
  matched_refund_id: string | null;
  import_batch: string | null;
  matched_by: string | null;
  matched_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface TdsDeduction {
  id: string;
  tenant_id: string;
  invoice_id: string | null;
  deductee_name: string;
  deductee_pan: string;
  tds_section: string;
  tds_rate: number;
  base_amount: number;
  tds_amount: number;
  status: TdsStatus;
  deducted_date: string;
  challan_number: string | null;
  challan_date: string | null;
  certificate_number: string | null;
  certificate_date: string | null;
  financial_year: string;
  quarter: string;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface GstReturnSummary {
  id: string;
  tenant_id: string;
  return_type: string;
  period: string;
  filing_status: GstrFilingStatus;
  total_taxable: number;
  total_cgst: number;
  total_sgst: number;
  total_igst: number;
  total_cess: number;
  total_tax: number;
  hsn_summary: unknown[] | null;
  invoice_count: number;
  arn: string | null;
  filed_by: string | null;
  filed_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface ErpExportLog {
  id: string;
  tenant_id: string;
  target_system: string;
  export_type: string;
  record_ids: string[];
  date_from: string | null;
  date_to: string | null;
  status: ErpExportStatus;
  payload: unknown | null;
  response: unknown | null;
  error_message: string | null;
  exported_by: string | null;
  created_at: string;
}

export interface InvoicePrintData {
  invoice: Invoice;
  items: InvoiceItem[];
  payments: Payment[];
  hospital_gstin: string | null;
  hospital_name: string | null;
  hospital_address: string | null;
  patient_name: string | null;
  patient_address: string | null;
  hsn_summary: HsnSummaryRow[];
}

export interface HsnSummaryRow {
  hsn_code: string;
  taxable_amount: number;
  cgst_amount: number;
  sgst_amount: number;
  igst_amount: number;
  total_tax: number;
  item_count: number;
}

export interface BillingThresholdStatus {
  encounter_id: string;
  current_total: number;
  threshold: number | null;
  exceeded: boolean;
  percentage_used: number | null;
}

export interface DualInsuranceResult {
  primary_claim: InsuranceClaim | null;
  secondary_claim: InsuranceClaim | null;
  patient_responsibility: number;
  coordination_notes: string;
}

export interface CreditAgingRow {
  patient_id: string;
  patient_name: string | null;
  credit_limit: number;
  current_balance: number;
  status: CreditPatientStatus;
  overdue_since: string | null;
  days_overdue: number | null;
}

export interface SchemeRateResult {
  charge_code: string;
  scheme_type: string;
  override_price: number | null;
  tpa_name: string | null;
  rate_plan_name: string | null;
}

export interface FinancialMisReport {
  total_revenue: number;
  total_collections: number;
  total_outstanding: number;
  total_refunds: number;
  total_write_offs: number;
  total_advances: number;
  collection_rate: number;
  period_from: string;
  period_to: string;
}

export interface ProfitLossDeptRow {
  department_id: string | null;
  department_name: string | null;
  revenue: number;
  expenses: number;
  profit: number;
}

export interface AutoReconcileResponse {
  matched_count: number;
  unmatched_count: number;
}

export interface ImportBankTransactionsResponse {
  imported: number;
  import_batch: string;
}

export interface CreateExchangeRateRequest {
  from_currency: CurrencyCode;
  to_currency?: CurrencyCode;
  rate: number;
  effective_date: string;
  source?: string;
}

export interface CreateCreditPatientRequest {
  patient_id: string;
  credit_limit: number;
  reason?: string;
  notes?: string;
}

export interface UpdateCreditPatientRequest {
  credit_limit?: number;
  status?: CreditPatientStatus;
  notes?: string;
}

export interface JournalLineInput {
  account_id: string;
  department_id?: string;
  debit_amount: number;
  credit_amount: number;
  narration?: string;
}

export interface CreateJournalEntryRequest {
  entry_date: string;
  description?: string;
  reference_type?: string;
  reference_id?: string;
  lines: JournalLineInput[];
}

export interface ImportBankTransactionRow {
  bank_name: string;
  account_number: string;
  transaction_date: string;
  value_date?: string;
  description?: string;
  debit_amount: number;
  credit_amount: number;
  running_balance?: number;
  reference_number?: string;
}

export interface ImportBankTransactionsRequest {
  transactions: ImportBankTransactionRow[];
  import_batch?: string;
}

export interface MatchBankTransactionRequest {
  payment_id?: string;
  refund_id?: string;
  notes?: string;
}

export interface CreateTdsRequest {
  invoice_id?: string;
  deductee_name: string;
  deductee_pan: string;
  tds_section: string;
  tds_rate: number;
  base_amount: number;
  deducted_date: string;
  financial_year: string;
  quarter: string;
}

export interface GenerateGstrRequest {
  return_type: string;
  period: string;
}

export interface ErpExportRequest {
  target_system: string;
  export_type: string;
  date_from?: string;
  date_to?: string;
}

export interface CreateGlAccountRequest {
  code: string;
  name: string;
  account_type: string;
  parent_id?: string;
  description?: string;
}

export interface UpdateGlAccountRequest {
  name?: string;
  description?: string;
  is_active?: boolean;
}

// ══════════════════════════════════════════════════════════
//  Lab Module
// ══════════════════════════════════════════════════════════

export type LabOrderStatus =
  | "ordered"
  | "sample_collected"
  | "processing"
  | "completed"
  | "verified"
  | "cancelled";
export type LabPriority = "routine" | "urgent" | "stat";
export type LabResultFlag =
  | "normal"
  | "low"
  | "high"
  | "critical_low"
  | "critical_high"
  | "abnormal";
export type LabReportStatus = "preliminary" | "final" | "amended";
export type LabQcStatus = "accepted" | "rejected" | "warning";
export type LabOutsourceStatus = "pending_send" | "sent" | "result_received" | "cancelled";
export type LabPhlebotomyStatus = "waiting" | "in_progress" | "completed" | "skipped";
export type LabWestgardRule = "1_2s" | "1_3s" | "2_2s" | "r_4s" | "4_1s" | "10x";

export interface LabOrder {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string | null;
  test_id: string;
  ordered_by: string;
  status: LabOrderStatus;
  priority: LabPriority;
  notes: string | null;
  rejection_reason: string | null;
  collected_at: string | null;
  collected_by: string | null;
  verified_by: string | null;
  verified_at: string | null;
  // Phase 2 fields
  sample_barcode: string | null;
  is_outsourced: boolean;
  report_status: LabReportStatus | null;
  is_report_locked: boolean;
  expected_tat_minutes: number | null;
  completed_at: string | null;
  parent_order_id: string | null;
  // Phase 3 fields
  is_stat: boolean;
  collection_center_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabResult {
  id: string;
  tenant_id: string;
  order_id: string;
  parameter_name: string;
  value: string;
  unit: string | null;
  normal_range: string | null;
  flag: LabResultFlag | null;
  notes: string | null;
  // Phase 2 fields
  previous_value: string | null;
  delta_percent: string | null;
  is_delta_flagged: boolean;
  is_auto_validated: boolean;
  entered_by: string | null;
  updated_at: string;
  created_at: string;
}

export interface LabTestCatalog {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  department_id: string | null;
  sample_type: string | null;
  normal_range: string | null;
  unit: string | null;
  price: string;
  tat_hours: number | null;
  is_active: boolean;
  // Phase 2 fields
  loinc_code: string | null;
  method: string | null;
  specimen_volume: string | null;
  critical_low: string | null;
  critical_high: string | null;
  delta_check_percent: string | null;
  auto_validation_rules: Record<string, unknown> | null;
  allows_add_on: boolean;
  created_at: string;
  updated_at: string;
}

export interface LabOrderListResponse {
  orders: LabOrder[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateLabOrderRequest {
  patient_id: string;
  encounter_id?: string;
  test_id: string;
  priority?: LabPriority;
  notes?: string;
}

export interface AddResultsRequest {
  results: ResultInput[];
}

export interface ResultInput {
  parameter_name: string;
  value: string;
  unit?: string;
  normal_range?: string;
  flag?: LabResultFlag;
}

export interface LabOrderDetailResponse {
  order: LabOrder;
  results: LabResult[];
}

export interface CreateLabCatalogRequest {
  code: string;
  name: string;
  department_id?: string;
  sample_type?: string;
  normal_range?: string;
  unit?: string;
  price: number;
  tat_hours?: number;
  // Phase 2 fields
  loinc_code?: string;
  method?: string;
  specimen_volume?: string;
  critical_low?: number;
  critical_high?: number;
  delta_check_percent?: number;
  auto_validation_rules?: Record<string, unknown>;
  allows_add_on?: boolean;
}

export interface UpdateLabCatalogRequest {
  name?: string;
  department_id?: string;
  sample_type?: string;
  normal_range?: string;
  unit?: string;
  price?: number;
  tat_hours?: number;
  is_active?: boolean;
  // Phase 2 fields
  loinc_code?: string;
  method?: string;
  specimen_volume?: string;
  critical_low?: number;
  critical_high?: number;
  delta_check_percent?: number;
  auto_validation_rules?: Record<string, unknown>;
  allows_add_on?: boolean;
}

// Lab Panels / Profiles

export interface LabTestPanel {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  description: string | null;
  price: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface LabPanelTest {
  id: string;
  tenant_id: string;
  panel_id: string;
  test_id: string;
  sort_order: number;
}

export interface CreateLabPanelRequest {
  code: string;
  name: string;
  description?: string;
  price: number;
  test_ids: string[];
}

export interface UpdateLabPanelRequest {
  name?: string;
  description?: string;
  price?: number;
  is_active?: boolean;
  test_ids?: string[];
}

export interface LabPanelDetailResponse {
  panel: LabTestPanel;
  tests: LabPanelTest[];
}

export interface RejectSampleRequest {
  rejection_reason: string;
}

// Lab Phase 2 — Enhanced Results, QC/NABL, Operations

export interface LabResultAmendment {
  id: string;
  tenant_id: string;
  result_id: string;
  order_id: string;
  original_value: string | null;
  amended_value: string | null;
  original_flag: LabResultFlag | null;
  amended_flag: LabResultFlag | null;
  reason: string;
  amended_by: string;
  amended_at: string;
}

export interface LabCriticalAlert {
  id: string;
  tenant_id: string;
  order_id: string;
  result_id: string;
  patient_id: string;
  parameter_name: string;
  value: string;
  flag: LabResultFlag;
  notified_to: string | null;
  notified_at: string | null;
  acknowledged_by: string | null;
  acknowledged_at: string | null;
  created_at: string;
}

export interface LabReagentLot {
  id: string;
  tenant_id: string;
  reagent_name: string;
  lot_number: string;
  manufacturer: string | null;
  test_id: string | null;
  received_date: string | null;
  expiry_date: string | null;
  quantity: string | null;
  quantity_unit: string | null;
  is_active: boolean;
  // Phase 3 fields
  reorder_level: number | null;
  consumption_per_test: number | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabQcResult {
  id: string;
  tenant_id: string;
  test_id: string;
  lot_id: string;
  level: string;
  target_mean: string | null;
  target_sd: string | null;
  observed_value: string | null;
  sd_index: string | null;
  status: LabQcStatus;
  westgard_violations: LabWestgardRule[] | null;
  run_date: string | null;
  run_time: string;
  performed_by: string | null;
  reviewer_notes: string | null;
  reviewed_by: string | null;
  created_at: string;
}

export interface LabCalibration {
  id: string;
  tenant_id: string;
  test_id: string;
  instrument_name: string | null;
  calibrator_lot: string | null;
  calibration_date: string | null;
  next_calibration_date: string | null;
  result_summary: Record<string, unknown> | null;
  is_passed: boolean;
  performed_by: string | null;
  notes: string | null;
  created_at: string;
}

export interface LabOutsourcedOrder {
  id: string;
  tenant_id: string;
  order_id: string;
  external_lab_name: string;
  external_lab_code: string | null;
  sent_date: string | null;
  expected_return_date: string | null;
  actual_return_date: string | null;
  external_ref_number: string | null;
  status: LabOutsourceStatus;
  cost: string | null;
  notes: string | null;
  sent_by: string | null;
  received_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabPhlebotomyQueueItem {
  id: string;
  tenant_id: string;
  order_id: string;
  patient_id: string;
  priority: LabPriority;
  queue_number: number | null;
  status: LabPhlebotomyStatus;
  assigned_to: string | null;
  location_id: string | null;
  queued_at: string;
  started_at: string | null;
  completed_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// Lab Phase 2 Request Types

export interface AmendResultRequest {
  result_id: string;
  amended_value: string;
  amended_flag?: LabResultFlag;
  reason: string;
}

export interface UpdateReportStatusRequest {
  report_status: LabReportStatus;
}

export interface AddOnTestRequest {
  test_id: string;
  priority?: LabPriority;
  notes?: string;
}

export interface CreateReagentLotRequest {
  reagent_name: string;
  lot_number: string;
  manufacturer?: string;
  test_id?: string;
  received_date?: string;
  expiry_date?: string;
  quantity?: number;
  quantity_unit?: string;
  notes?: string;
}

export interface UpdateReagentLotRequest {
  reagent_name?: string;
  manufacturer?: string;
  test_id?: string;
  expiry_date?: string;
  quantity?: number;
  quantity_unit?: string;
  is_active?: boolean;
  notes?: string;
}

export interface CreateQcResultRequest {
  test_id: string;
  lot_id: string;
  level: string;
  target_mean?: number;
  target_sd?: number;
  observed_value?: number;
  run_date?: string;
  reviewer_notes?: string;
}

export interface CreateCalibrationRequest {
  test_id: string;
  instrument_name?: string;
  calibrator_lot?: string;
  calibration_date?: string;
  next_calibration_date?: string;
  result_summary?: Record<string, unknown>;
  is_passed?: boolean;
  notes?: string;
}

export interface CreatePhlebotomyEntryRequest {
  order_id: string;
  patient_id: string;
  priority?: LabPriority;
  location_id?: string;
  notes?: string;
}

export interface UpdatePhlebotomyStatusRequest {
  status: LabPhlebotomyStatus;
}

export interface CreateOutsourcedOrderRequest {
  order_id: string;
  external_lab_name: string;
  external_lab_code?: string;
  sent_date?: string;
  expected_return_date?: string;
  cost?: number;
  notes?: string;
}

export interface UpdateOutsourcedOrderRequest {
  status?: LabOutsourceStatus;
  actual_return_date?: string;
  external_ref_number?: string;
  cost?: number;
  notes?: string;
}

// Lab Phase 2 Response Types

export interface CumulativeReportResponse {
  patient_id: string;
  test_id: string;
  results: CumulativeResultRow[];
}

export interface CumulativeResultRow {
  order_id: string;
  parameter_name: string;
  value: string;
  flag: LabResultFlag | null;
  created_at: string;
}

export interface TatMonitoringRow {
  order_id: string;
  test_id: string;
  patient_id: string;
  expected_tat_minutes: number | null;
  actual_minutes: number | null;
  is_breached: boolean;
  ordered_at: string;
  completed_at: string | null;
}

// Lab Phase 3 Enums

export type LabHomeCollectionStatus =
  | "scheduled"
  | "assigned"
  | "in_transit"
  | "arrived"
  | "collected"
  | "returned_to_lab"
  | "cancelled";

export type LabCollectionCenterType = "hospital" | "satellite" | "partner" | "camp";

export type LabSampleArchiveStatus = "stored" | "retrieved" | "discarded" | "expired";

export type LabDispatchMethod = "counter" | "email" | "sms" | "whatsapp" | "portal" | "courier";

export type LabEqasEvaluation = "acceptable" | "marginal" | "unacceptable" | "pending";

// Lab Phase 3 Interfaces

export interface LabHomeCollection {
  id: string;
  tenant_id: string;
  order_id: string | null;
  patient_id: string;
  scheduled_date: string;
  scheduled_time_slot: string | null;
  address_line: string | null;
  city: string | null;
  pincode: string | null;
  contact_phone: string | null;
  assigned_phlebotomist: string | null;
  status: LabHomeCollectionStatus;
  special_instructions: string | null;
  collected_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabCollectionCenter {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  center_type: LabCollectionCenterType;
  address: string | null;
  city: string | null;
  phone: string | null;
  contact_person: string | null;
  is_active: boolean;
  operating_hours: Record<string, unknown> | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabSampleArchive {
  id: string;
  tenant_id: string;
  order_id: string | null;
  patient_id: string | null;
  sample_barcode: string | null;
  storage_location: string | null;
  stored_at: string | null;
  archived_by: string | null;
  status: LabSampleArchiveStatus;
  retrieved_at: string | null;
  retrieved_by: string | null;
  disposal_date: string | null;
  notes: string | null;
  created_at: string;
}

export interface LabReportDispatch {
  id: string;
  tenant_id: string;
  order_id: string;
  patient_id: string;
  dispatch_method: LabDispatchMethod;
  dispatched_to: string | null;
  dispatched_by: string | null;
  dispatched_at: string;
  received_confirmation: boolean;
  confirmed_at: string | null;
  notes: string | null;
  created_at: string;
}

export interface LabReportTemplate {
  id: string;
  tenant_id: string;
  department_id: string | null;
  template_name: string;
  header_html: string | null;
  footer_html: string | null;
  logo_url: string | null;
  report_format: Record<string, unknown> | null;
  is_default: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface LabEqasResult {
  id: string;
  tenant_id: string;
  program_name: string;
  provider: string | null;
  test_id: string | null;
  cycle: string | null;
  sample_number: string | null;
  expected_value: number | null;
  reported_value: number | null;
  evaluation: LabEqasEvaluation;
  bias_percent: number | null;
  z_score: number | null;
  report_date: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabProficiencyTest {
  id: string;
  tenant_id: string;
  program: string;
  test_id: string | null;
  survey_round: string | null;
  sample_id: string | null;
  assigned_value: number | null;
  reported_value: number | null;
  acceptable_range_low: number | null;
  acceptable_range_high: number | null;
  is_acceptable: boolean | null;
  evaluation_date: string | null;
  notes: string | null;
  created_at: string;
}

export interface LabNablDocument {
  id: string;
  tenant_id: string;
  document_type: string | null;
  document_number: string;
  title: string;
  version: string | null;
  effective_date: string | null;
  review_date: string | null;
  approved_by: string | null;
  file_path: string | null;
  is_current: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabHistopathReport {
  id: string;
  tenant_id: string;
  order_id: string;
  patient_id: string;
  specimen_type: string | null;
  clinical_history: string | null;
  gross_description: string | null;
  microscopy_findings: string | null;
  special_stains: Record<string, unknown> | null;
  immunohistochemistry: Record<string, unknown> | null;
  synoptic_data: Record<string, unknown> | null;
  diagnosis: string | null;
  icd_code: string | null;
  pathologist_id: string | null;
  reported_at: string | null;
  notes: string | null;
  turnaround_days: number | null;
  created_at: string;
  updated_at: string;
}

export interface LabCytologyReport {
  id: string;
  tenant_id: string;
  order_id: string;
  patient_id: string;
  specimen_type: string | null;
  clinical_indication: string | null;
  adequacy: string | null;
  screening_findings: string | null;
  diagnosis: string | null;
  bethesda_category: string | null;
  cytopathologist_id: string | null;
  reported_at: string | null;
  icd_code: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabMolecularReport {
  id: string;
  tenant_id: string;
  order_id: string;
  patient_id: string;
  test_method: string | null;
  target_gene: string | null;
  primer_details: string | null;
  amplification_data: Record<string, unknown> | null;
  ct_value: number | null;
  result_interpretation: string | null;
  quantitative_value: number | null;
  quantitative_unit: string | null;
  kit_name: string | null;
  kit_lot: string | null;
  performed_by: string | null;
  reported_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LabB2bClient {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  client_type: string | null;
  address: string | null;
  city: string | null;
  phone: string | null;
  email: string | null;
  contact_person: string | null;
  credit_limit: number | null;
  payment_terms_days: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface LabB2bRate {
  id: string;
  tenant_id: string;
  client_id: string;
  test_id: string;
  agreed_price: number | null;
  discount_percent: number | null;
  effective_from: string | null;
  effective_to: string | null;
  created_at: string;
  updated_at: string;
}

// Lab Phase 3 Request Types

export interface CreateHomeCollectionRequest {
  order_id?: string;
  patient_id: string;
  scheduled_date: string;
  scheduled_time_slot?: string;
  address_line?: string;
  city?: string;
  pincode?: string;
  contact_phone?: string;
  special_instructions?: string;
}

export interface UpdateHomeCollectionRequest {
  assigned_phlebotomist?: string;
  scheduled_date?: string;
  scheduled_time_slot?: string;
  address_line?: string;
  city?: string;
  pincode?: string;
  contact_phone?: string;
  special_instructions?: string;
  notes?: string;
}

export interface HomeCollectionStatusRequest {
  status: LabHomeCollectionStatus;
  notes?: string;
}

export interface CreateCollectionCenterRequest {
  code: string;
  name: string;
  center_type: LabCollectionCenterType;
  address?: string;
  city?: string;
  phone?: string;
  contact_person?: string;
  operating_hours?: Record<string, unknown>;
  notes?: string;
}

export interface UpdateCollectionCenterRequest {
  name?: string;
  center_type?: LabCollectionCenterType;
  address?: string;
  city?: string;
  phone?: string;
  contact_person?: string;
  operating_hours?: Record<string, unknown>;
  is_active?: boolean;
  notes?: string;
}

export interface CreateSampleArchiveRequest {
  order_id?: string;
  patient_id?: string;
  sample_barcode?: string;
  storage_location?: string;
  notes?: string;
}

export interface CreateReportDispatchRequest {
  order_id: string;
  patient_id: string;
  dispatch_method: LabDispatchMethod;
  dispatched_to?: string;
  notes?: string;
}

export interface CreateReportTemplateRequest {
  department_id?: string;
  template_name: string;
  header_html?: string;
  footer_html?: string;
  logo_url?: string;
  report_format?: Record<string, unknown>;
  is_default?: boolean;
}

export interface UpdateReportTemplateRequest {
  template_name?: string;
  header_html?: string;
  footer_html?: string;
  logo_url?: string;
  report_format?: Record<string, unknown>;
  is_default?: boolean;
  is_active?: boolean;
}

export interface CreateEqasResultRequest {
  program_name: string;
  provider?: string;
  test_id?: string;
  cycle?: string;
  sample_number?: string;
  expected_value?: number;
  reported_value?: number;
  evaluation?: LabEqasEvaluation;
  bias_percent?: number;
  z_score?: number;
  report_date?: string;
  notes?: string;
}

export interface UpdateEqasResultRequest {
  evaluation?: LabEqasEvaluation;
  reported_value?: number;
  bias_percent?: number;
  z_score?: number;
  notes?: string;
}

export interface CreateProficiencyTestRequest {
  program: string;
  test_id?: string;
  survey_round?: string;
  sample_id?: string;
  assigned_value?: number;
  reported_value?: number;
  acceptable_range_low?: number;
  acceptable_range_high?: number;
  is_acceptable?: boolean;
  evaluation_date?: string;
  notes?: string;
}

export interface CreateNablDocumentRequest {
  document_type?: string;
  document_number: string;
  title: string;
  version?: string;
  effective_date?: string;
  review_date?: string;
  file_path?: string;
  is_current?: boolean;
  notes?: string;
}

export interface UpdateNablDocumentRequest {
  title?: string;
  version?: string;
  effective_date?: string;
  review_date?: string;
  file_path?: string;
  is_current?: boolean;
  notes?: string;
}

export interface CreateHistopathReportRequest {
  order_id: string;
  patient_id: string;
  specimen_type?: string;
  clinical_history?: string;
  gross_description?: string;
  microscopy_findings?: string;
  special_stains?: Record<string, unknown>;
  immunohistochemistry?: Record<string, unknown>;
  synoptic_data?: Record<string, unknown>;
  diagnosis?: string;
  icd_code?: string;
  notes?: string;
  turnaround_days?: number;
}

export interface CreateCytologyReportRequest {
  order_id: string;
  patient_id: string;
  specimen_type?: string;
  clinical_indication?: string;
  adequacy?: string;
  screening_findings?: string;
  diagnosis?: string;
  bethesda_category?: string;
  icd_code?: string;
  notes?: string;
}

export interface CreateMolecularReportRequest {
  order_id: string;
  patient_id: string;
  test_method?: string;
  target_gene?: string;
  primer_details?: string;
  amplification_data?: Record<string, unknown>;
  ct_value?: number;
  result_interpretation?: string;
  quantitative_value?: number;
  quantitative_unit?: string;
  kit_name?: string;
  kit_lot?: string;
  notes?: string;
}

export interface CreateB2bClientRequest {
  code: string;
  name: string;
  client_type?: string;
  address?: string;
  city?: string;
  phone?: string;
  email?: string;
  contact_person?: string;
  credit_limit?: number;
  payment_terms_days?: number;
}

export interface UpdateB2bClientRequest {
  name?: string;
  client_type?: string;
  address?: string;
  city?: string;
  phone?: string;
  email?: string;
  contact_person?: string;
  credit_limit?: number;
  payment_terms_days?: number;
  is_active?: boolean;
}

export interface CreateB2bRateRequest {
  test_id: string;
  agreed_price?: number;
  discount_percent?: number;
  effective_from?: string;
  effective_to?: string;
}

export interface HomeCollectionStatsRow {
  status: LabHomeCollectionStatus;
  count: number;
}

export interface ReagentConsumptionRow {
  id: string;
  reagent_name: string;
  lot_number: string;
  quantity: number | null;
  quantity_unit: string | null;
  reorder_level: number | null;
  consumption_per_test: number | null;
  is_active: boolean;
  expiry_date: string | null;
}

// ══════════════════════════════════════════════════════════
//  Radiology Module
// ══════════════════════════════════════════════════════════

export type RadiologyOrderStatus =
  | "ordered"
  | "scheduled"
  | "in_progress"
  | "completed"
  | "reported"
  | "verified"
  | "cancelled";

export type RadiologyPriority = "routine" | "urgent" | "stat";

export type RadiologyReportStatus = "draft" | "preliminary" | "final" | "amended";

export interface RadiologyModality {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface RadiologyOrder {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string | null;
  modality_id: string;
  ordered_by: string;
  body_part: string | null;
  clinical_indication: string | null;
  priority: RadiologyPriority;
  status: RadiologyOrderStatus;
  scheduled_at: string | null;
  completed_at: string | null;
  notes: string | null;
  contrast_required: boolean;
  pregnancy_checked: boolean;
  allergy_flagged: boolean;
  cancellation_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface RadiologyReport {
  id: string;
  tenant_id: string;
  order_id: string;
  reported_by: string;
  verified_by: string | null;
  status: RadiologyReportStatus;
  findings: string;
  impression: string | null;
  recommendations: string | null;
  is_critical: boolean;
  template_name: string | null;
  verified_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface RadiationDoseRecord {
  id: string;
  tenant_id: string;
  order_id: string;
  patient_id: string;
  modality_code: string;
  body_part: string | null;
  dose_value: string | null;
  dose_unit: string;
  dlp: string | null;
  ctdi_vol: string | null;
  dap: string | null;
  fluoroscopy_time_seconds: number | null;
  recorded_by: string | null;
  recorded_at: string;
  created_at: string;
}

export interface RadiologyOrderListResponse {
  orders: RadiologyOrder[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateRadiologyOrderRequest {
  patient_id: string;
  encounter_id?: string;
  modality_id: string;
  body_part?: string;
  clinical_indication?: string;
  priority?: string;
  scheduled_at?: string;
  notes?: string;
  contrast_required?: boolean;
  pregnancy_checked?: boolean;
  allergy_flagged?: boolean;
}

export interface RadiologyOrderDetailResponse {
  order: RadiologyOrder;
  report: RadiologyReport | null;
  dose_records: RadiationDoseRecord[];
}

export interface CancelRadiologyOrderRequest {
  cancellation_reason: string;
}

export interface CreateRadiologyReportRequest {
  findings: string;
  impression?: string;
  recommendations?: string;
  is_critical?: boolean;
  template_name?: string;
  status?: string;
}

export interface CreateModalityRequest {
  code: string;
  name: string;
  description?: string;
}

export interface UpdateModalityRequest {
  name?: string;
  description?: string;
  is_active?: boolean;
}

export interface RecordDoseRequest {
  modality_code: string;
  body_part?: string;
  dose_value?: number;
  dose_unit?: string;
  dlp?: number;
  ctdi_vol?: number;
  dap?: number;
  fluoroscopy_time_seconds?: number;
}

// ══════════════════════════════════════════════════════════
//  Pharmacy Module
// ══════════════════════════════════════════════════════════

export type PharmacyOrderStatus = "ordered" | "dispensed" | "cancelled" | "returned";
export type StockTransactionType = "receipt" | "issue" | "return" | "adjustment";
export type DrugSchedule = "H" | "H1" | "X" | "G" | "OTC" | "NDPS";
export type FormularyStatus = "approved" | "restricted" | "non_formulary";
export type AwareCategory = "access" | "watch" | "reserve";

export interface PharmacyCatalog {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  generic_name: string | null;
  category: string | null;
  manufacturer: string | null;
  unit: string | null;
  base_price: string;
  tax_percent: string;
  current_stock: number;
  reorder_level: number;
  is_active: boolean;
  // Regulatory fields
  drug_schedule: DrugSchedule | null;
  is_controlled: boolean;
  inn_name: string | null;
  atc_code: string | null;
  rxnorm_code: string | null;
  snomed_code: string | null;
  formulary_status: FormularyStatus;
  aware_category: AwareCategory | null;
  is_lasa: boolean;
  lasa_group: string | null;
  max_dose_per_day: string | null;
  batch_tracking_required: boolean;
  storage_conditions: string | null;
  black_box_warning: string | null;
  created_at: string;
  updated_at: string;
}

export interface ComplianceSettings {
  enforce_drug_scheduling: boolean;
  enforce_ndps_tracking: boolean;
  enforce_formulary: boolean;
  enforce_drug_interactions: boolean;
  enforce_antibiotic_stewardship: boolean;
  enforce_lasa_warnings: boolean;
  enforce_max_dose_check: boolean;
  enforce_batch_tracking: boolean;
  show_schedule_badges: boolean;
  show_controlled_warnings: boolean;
  show_formulary_status: boolean;
  show_aware_category: boolean;
}

export type PharmacyDispensingType = "prescription" | "otc" | "discharge" | "package" | "emergency";
export type NdpsRegisterAction = "receipt" | "dispensed" | "destroyed" | "transferred" | "adjustment";
export type PharmacyReturnStatusType = "requested" | "approved" | "returned_to_stock" | "destroyed" | "rejected";

export interface PharmacyOrder {
  id: string;
  tenant_id: string;
  prescription_id: string | null;
  patient_id: string;
  encounter_id: string | null;
  ordered_by: string;
  status: PharmacyOrderStatus;
  notes: string | null;
  // Phase 2 fields
  dispensing_type: PharmacyDispensingType;
  discharge_summary_id: string | null;
  billing_package_id: string | null;
  store_location_id: string | null;
  interaction_check_result: unknown | null;
  dispensed_by: string | null;
  dispensed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface PharmacyOrderItem {
  id: string;
  tenant_id: string;
  order_id: string;
  catalog_item_id: string | null;
  drug_name: string;
  quantity: number;
  unit_price: string;
  total_price: string;
  // Phase 2 fields
  batch_number: string | null;
  expiry_date: string | null;
  batch_stock_id: string | null;
  quantity_prescribed: number | null;
  quantity_returned: number;
  created_at: string;
}

export interface PharmacyStockTransaction {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  transaction_type: StockTransactionType;
  quantity: number;
  reference_id: string | null;
  notes: string | null;
  created_by: string;
  created_at: string;
}

export interface PharmacyOrderListResponse {
  orders: PharmacyOrder[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreatePharmacyOrderRequest {
  patient_id: string;
  prescription_id?: string;
  encounter_id?: string;
  notes?: string;
  items: PharmacyOrderItemInput[];
  dispensing_type?: PharmacyDispensingType;
  discharge_summary_id?: string;
  billing_package_id?: string;
  store_location_id?: string;
}

export interface PharmacyOrderItemInput {
  catalog_item_id?: string;
  drug_name: string;
  quantity: number;
  unit_price: number;
}

export interface PharmacyOrderDetailResponse {
  order: PharmacyOrder;
  items: PharmacyOrderItem[];
}

export interface CreatePharmacyCatalogRequest {
  code: string;
  name: string;
  generic_name?: string;
  category?: string;
  manufacturer?: string;
  unit?: string;
  base_price: number;
  tax_percent?: number;
  reorder_level?: number;
  // Regulatory
  drug_schedule?: DrugSchedule;
  is_controlled?: boolean;
  inn_name?: string;
  atc_code?: string;
  rxnorm_code?: string;
  snomed_code?: string;
  formulary_status?: FormularyStatus;
  aware_category?: AwareCategory;
  is_lasa?: boolean;
  lasa_group?: string;
  max_dose_per_day?: string;
  batch_tracking_required?: boolean;
  storage_conditions?: string;
  black_box_warning?: string;
}

export interface UpdatePharmacyCatalogRequest {
  name?: string;
  generic_name?: string;
  category?: string;
  manufacturer?: string;
  unit?: string;
  base_price?: number;
  tax_percent?: number;
  reorder_level?: number;
  is_active?: boolean;
  // Regulatory
  drug_schedule?: DrugSchedule;
  is_controlled?: boolean;
  inn_name?: string;
  atc_code?: string;
  rxnorm_code?: string;
  snomed_code?: string;
  formulary_status?: FormularyStatus;
  aware_category?: AwareCategory;
  is_lasa?: boolean;
  lasa_group?: string;
  max_dose_per_day?: string;
  batch_tracking_required?: boolean;
  storage_conditions?: string;
  black_box_warning?: string;
}

export interface CreateStockTransactionRequest {
  catalog_item_id: string;
  transaction_type: StockTransactionType;
  quantity: number;
  reference_id?: string;
  notes?: string;
}

// ── Pharmacy Phase 2 ──────────────────────────────────────

export interface PharmacyBatch {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  batch_number: string;
  expiry_date: string;
  manufacture_date: string | null;
  quantity_received: number;
  quantity_dispensed: number;
  quantity_on_hand: number;
  store_location_id: string | null;
  supplier_info: string | null;
  grn_item_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface NdpsRegisterEntry {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  action: NdpsRegisterAction;
  quantity: number;
  balance_after: number;
  patient_id: string | null;
  prescription_id: string | null;
  dispensed_by: string | null;
  witnessed_by: string | null;
  register_number: string | null;
  page_number: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface PharmacyReturn {
  id: string;
  tenant_id: string;
  order_item_id: string;
  patient_id: string;
  quantity_returned: number;
  reason: string | null;
  status: PharmacyReturnStatusType;
  approved_by: string | null;
  return_batch_id: string | null;
  restocked: boolean;
  created_at: string;
  updated_at: string;
}

export interface PharmacyStoreAssignment {
  id: string;
  tenant_id: string;
  store_location_id: string;
  is_central: boolean;
  serves_departments: string[] | null;
  operating_hours: unknown | null;
  created_at: string;
  updated_at: string;
}

export interface PharmacyTransferRequest {
  id: string;
  tenant_id: string;
  from_location_id: string;
  to_location_id: string;
  status: string;
  items: unknown;
  requested_by: string;
  approved_by: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface PharmacyValidationResult {
  valid: boolean;
  warnings: string[];
  blocks: string[];
  interactions: unknown[];
}

export interface NdpsBalanceRow {
  catalog_item_id: string;
  drug_name: string;
  balance: number;
}

export interface NdpsReportResponse {
  entries: NdpsBalanceRow[];
}

export interface NdpsListResponse {
  entries: NdpsRegisterEntry[];
  total: number;
  page: number;
  per_page: number;
}

export interface PharmacyConsumptionRow {
  drug_name: string;
  category: string | null;
  total_dispensed: number;
  total_value: string;
}

export interface PharmacyAbcVedRow {
  drug_name: string;
  annual_value: string;
  abc_class: string;
  ved_class: string | null;
}

export interface NearExpiryRow {
  drug_name: string;
  batch_number: string;
  expiry_date: string;
  quantity_on_hand: number;
  days_until_expiry: number;
}

export interface PharmacyDeadStockRow {
  drug_name: string;
  current_stock: number;
  stock_value: string;
  last_dispensed_date: string | null;
  days_idle: number | null;
}

export interface DrugUtilizationRow {
  drug_name: string;
  generic_name: string | null;
  aware_category: string | null;
  total_dispensed: number;
  unique_patients: number;
}

export interface CreateOtcSaleRequest {
  items: PharmacyOrderItemInput[];
  notes?: string;
  store_location_id?: string;
}

export interface CreateDischargeMedsRequest {
  patient_id: string;
  discharge_summary_id: string;
  encounter_id?: string;
  items: PharmacyOrderItemInput[];
  notes?: string;
}

export interface CreateNdpsEntryRequest {
  catalog_item_id: string;
  action: NdpsRegisterAction;
  quantity: number;
  notes?: string;
  witnessed_by?: string;
}

export interface CreatePharmacyBatchRequest {
  catalog_item_id: string;
  batch_number: string;
  expiry_date: string;
  manufacture_date?: string;
  quantity_received: number;
  store_location_id?: string;
  supplier_info?: string;
}

export interface CreateStoreAssignmentRequest {
  store_location_id: string;
  is_central?: boolean;
  serves_departments?: string[];
  operating_hours?: unknown;
}

export interface CreatePharmacyTransferRequest {
  from_location_id: string;
  to_location_id: string;
  items: unknown;
  notes?: string;
}

export interface CreatePharmacyReturnRequest {
  order_item_id: string;
  patient_id: string;
  quantity_returned: number;
  reason?: string;
}

export interface ProcessPharmacyReturnRequest {
  status: PharmacyReturnStatusType;
}

// ══════════════════════════════════════════════════════════
//  IPD Module
// ══════════════════════════════════════════════════════════

export type AdmissionStatus =
  | "admitted"
  | "transferred"
  | "discharged"
  | "absconded"
  | "deceased";
export type DischargeType =
  | "normal"
  | "lama"
  | "dama"
  | "absconded"
  | "referred"
  | "deceased";
export type DischargeSummaryStatus = "draft" | "finalized";
export type AdmissionSource = "er" | "opd" | "direct" | "referral" | "transfer_in";

export interface Admission {
  id: string;
  tenant_id: string;
  encounter_id: string;
  patient_id: string;
  bed_id: string | null;
  admitting_doctor: string;
  status: AdmissionStatus;
  admitted_at: string;
  discharged_at: string | null;
  discharge_type: DischargeType | null;
  discharge_summary: string | null;
  provisional_diagnosis: string | null;
  comorbidities: unknown[];
  estimated_los_days: number | null;
  deposit_amount: number | null;
  deposit_paid: boolean;
  priority: string;
  admission_source: AdmissionSource | null;
  referral_from: string | null;
  referral_doctor: string | null;
  referral_notes: string | null;
  admission_weight_kg: number | null;
  admission_height_cm: number | null;
  expected_discharge_date: string | null;
  ward_id: string | null;
  mlc_case_id: string | null;
  ip_type: IpType | null;
  estimated_cost: number | null;
  is_critical: boolean;
  isolation_required: boolean;
  isolation_reason: string | null;
  primary_nurse_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdmissionRow {
  id: string;
  encounter_id: string;
  patient_id: string;
  bed_id: string | null;
  admitting_doctor: string;
  status: AdmissionStatus;
  admitted_at: string;
  discharged_at: string | null;
  patient_name: string;
  uhid: string;
  ward_name: string | null;
}

export type NursingTaskPriority = "routine" | "urgent" | "stat";
export type NursingTaskCategory =
  | "vital_check" | "wound_care" | "catheter_care" | "repositioning"
  | "mouth_care" | "hygiene" | "mobilization" | "teaching"
  | "drain_care" | "tracheostomy_care" | "medication" | "other";

export interface NursingTask {
  id: string;
  tenant_id: string;
  admission_id: string;
  assigned_to: string | null;
  task_type: string;
  description: string;
  is_completed: boolean;
  due_at: string | null;
  completed_at: string | null;
  completed_by: string | null;
  priority: NursingTaskPriority;
  category: NursingTaskCategory | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdmissionListResponse {
  admissions: AdmissionRow[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateAdmissionRequest {
  patient_id: string;
  department_id: string;
  doctor_id?: string;
  bed_id?: string;
  notes?: string;
  admission_source?: AdmissionSource;
  referral_from?: string;
  referral_doctor?: string;
  referral_notes?: string;
  admission_weight_kg?: number;
  admission_height_cm?: number;
  expected_discharge_date?: string;
  ward_id?: string;
}

export interface CreateAdmissionResponse {
  encounter: Encounter;
  admission: Admission;
}

export interface AdmissionDetailResponse {
  admission: Admission;
  encounter: Encounter;
  tasks: NursingTask[];
  attenders?: AdmissionAttender[];
}

export interface UpdateAdmissionRequest {
  bed_id?: string;
  notes?: string;
}

export interface TransferBedRequest {
  bed_id: string;
  notes?: string;
}

export interface DischargeRequest {
  discharge_type: DischargeType;
  discharge_summary?: string;
}

export interface CreateNursingTaskRequest {
  task_type: string;
  description: string;
  assigned_to?: string;
  due_at?: string;
  notes?: string;
}

export interface UpdateNursingTaskRequest {
  task_type?: string;
  description?: string;
  assigned_to?: string;
  is_completed?: boolean;
  due_at?: string;
  notes?: string;
}

// ── IPD Phase 2 — Wards, Bed Dashboard, Discharge Summaries ─

export interface Ward {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  department_id: string | null;
  ward_type: string;
  total_beds: number;
  gender_restriction: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface WardBedMapping {
  id: string;
  tenant_id: string;
  ward_id: string;
  bed_location_id: string;
  bed_type_id: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

export interface AdmissionAttender {
  id: string;
  tenant_id: string;
  admission_id: string;
  relationship: string;
  name: string;
  phone: string | null;
  alt_phone: string | null;
  address: string | null;
  id_proof_type: string | null;
  id_proof_number: string | null;
  is_primary: boolean;
  created_at: string;
}

export interface DischargeSummaryTemplate {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  sections: unknown[];
  is_default: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface IpdDischargeSummary {
  id: string;
  tenant_id: string;
  admission_id: string;
  template_id: string | null;
  status: DischargeSummaryStatus;
  final_diagnosis: string | null;
  condition_at_discharge: string | null;
  course_in_hospital: string | null;
  treatment_given: string | null;
  procedures_performed: unknown[];
  investigation_summary: string | null;
  medications_on_discharge: unknown[];
  follow_up_instructions: string | null;
  follow_up_date: string | null;
  dietary_advice: string | null;
  activity_restrictions: string | null;
  warning_signs: string | null;
  emergency_contact_info: string | null;
  prepared_by: string | null;
  verified_by: string | null;
  finalized_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateWardRequest {
  code: string;
  name: string;
  department_id?: string;
  ward_type?: string;
  gender_restriction?: string;
  is_active?: boolean;
}

export interface UpdateWardRequest {
  name?: string;
  department_id?: string;
  ward_type?: string;
  gender_restriction?: string;
  is_active?: boolean;
}

export interface WardListRow {
  id: string;
  code: string;
  name: string;
  department_name: string | null;
  ward_type: string;
  total_beds: number;
  vacant_beds: number;
  gender_restriction: string;
  is_active: boolean;
}

export interface AssignBedToWardRequest {
  bed_location_id: string;
  bed_type_id?: string;
  sort_order?: number;
}

export interface WardBedRow {
  mapping_id: string;
  bed_location_id: string;
  bed_name: string;
  bed_type_name: string | null;
  status: string;
  patient_name: string | null;
  patient_uhid: string | null;
  sort_order: number;
}

export interface BedDashboardSummary {
  ward_id: string | null;
  ward_name: string | null;
  total: number;
  vacant_clean: number;
  vacant_dirty: number;
  occupied: number;
  reserved: number;
  maintenance: number;
  blocked: number;
}

export interface BedDashboardRow {
  bed_id: string;
  bed_name: string;
  ward_id: string | null;
  ward_name: string | null;
  bed_type: string | null;
  status: string;
  patient_name: string | null;
  patient_uhid: string | null;
  admission_id: string | null;
}

export interface UpdateBedStatusRequest {
  status: string;
}

export interface CreateAttenderRequest {
  relationship: string;
  name: string;
  phone?: string;
  alt_phone?: string;
  address?: string;
  id_proof_type?: string;
  id_proof_number?: string;
  is_primary?: boolean;
}

export interface CreateDischargeTemplateRequest {
  code: string;
  name: string;
  sections: unknown[];
  is_default?: boolean;
  is_active?: boolean;
}

export interface CreateDischargeSummaryRequest {
  template_id?: string;
  final_diagnosis?: string;
  condition_at_discharge?: string;
  course_in_hospital?: string;
  treatment_given?: string;
  procedures_performed?: unknown[];
  investigation_summary?: string;
  medications_on_discharge?: unknown[];
  follow_up_instructions?: string;
  follow_up_date?: string;
  dietary_advice?: string;
  activity_restrictions?: string;
  warning_signs?: string;
  emergency_contact_info?: string;
}

export interface UpdateDischargeSummaryRequest {
  final_diagnosis?: string;
  condition_at_discharge?: string;
  course_in_hospital?: string;
  treatment_given?: string;
  procedures_performed?: unknown[];
  investigation_summary?: string;
  medications_on_discharge?: unknown[];
  follow_up_instructions?: string;
  follow_up_date?: string;
  dietary_advice?: string;
  activity_restrictions?: string;
  warning_signs?: string;
  emergency_contact_info?: string;
}

export interface CensusWardRow {
  ward_id: string | null;
  ward_name: string | null;
  total_beds: number;
  occupied: number;
  vacant: number;
}

export interface OccupancyRow {
  ward_id: string | null;
  ward_name: string | null;
  total_beds: number;
  occupied_bed_days: number;
  total_bed_days: number;
  occupancy_pct: number;
}

export interface AlosRow {
  department_name: string | null;
  discharge_type: string;
  avg_los_days: number;
  count: number;
}

export interface DischargeStatRow {
  discharge_type: string;
  count: number;
}

// ── IPD Clinical Expansion ──────────────────────────────────

export type ProgressNoteType = "doctor_round" | "nursing_note" | "specialist_opinion" | "dietitian_note" | "physiotherapy_note" | "social_worker_note" | "discharge_note";
export type ClinicalAssessmentType = "morse_fall_scale" | "braden_scale" | "gcs" | "pain_vas" | "pain_nrs" | "pain_flacc" | "barthel_adl" | "norton_scale" | "waterlow_score" | "rass" | "cam" | "news2" | "mews" | "custom";
export type MarStatus = "scheduled" | "given" | "held" | "refused" | "missed" | "self_administered";
export type CarePlanStatus = "active" | "resolved" | "discontinued";
export type NursingShift = "morning" | "afternoon" | "night";

export interface IpdProgressNote {
  id: string; tenant_id: string; admission_id: string; encounter_id: string | null;
  note_type: ProgressNoteType; author_id: string; note_date: string;
  subjective: string | null; objective: string | null; assessment: string | null; plan: string | null;
  is_addendum: boolean; parent_note_id: string | null;
  created_at: string; updated_at: string;
}

export interface IpdClinicalAssessment {
  id: string; tenant_id: string; admission_id: string;
  assessment_type: ClinicalAssessmentType; score_value: number | null;
  risk_level: string | null; score_details: unknown;
  assessed_by: string; assessed_at: string;
  created_at: string; updated_at: string;
}

export interface IpdMedicationAdministration {
  id: string; tenant_id: string; admission_id: string;
  prescription_item_id: string | null; drug_name: string; dose: string;
  route: string; frequency: string | null;
  scheduled_at: string; administered_at: string | null;
  status: MarStatus; administered_by: string | null; witnessed_by: string | null;
  barcode_verified: boolean; is_high_alert: boolean;
  hold_reason: string | null; refused_reason: string | null; notes: string | null;
  prn_reason: string | null; missed_reason: string | null; double_checked_by: string | null;
  created_at: string; updated_at: string;
}

export interface IpdIntakeOutput {
  id: string; tenant_id: string; admission_id: string;
  is_intake: boolean; category: string; volume_ml: number;
  description: string | null; recorded_at: string; recorded_by: string;
  shift: NursingShift; created_at: string;
}

export interface IoBalanceResponse {
  total_intake_ml: number;
  total_output_ml: number;
  balance_ml: number;
}

export interface IpdNursingAssessment {
  id: string; tenant_id: string; admission_id: string;
  assessed_by: string; assessed_at: string;
  general_appearance: unknown; skin_assessment: unknown; pain_assessment: unknown;
  nutritional_status: unknown; elimination_status: unknown; respiratory_status: unknown;
  psychosocial_status: unknown; fall_risk_assessment: unknown;
  allergies: string | null; medications_on_admission: string | null;
  personal_belongings: unknown; patient_education_needs: string | null;
  created_at: string; updated_at: string;
}

export interface IpdCarePlan {
  id: string; tenant_id: string; admission_id: string;
  nursing_diagnosis: string; goals: string | null; interventions: unknown;
  evaluation: string | null; status: CarePlanStatus;
  initiated_by: string; initiated_at: string;
  resolved_at: string | null; resolved_by: string | null;
  created_at: string; updated_at: string;
}

export interface IpdHandoverReport {
  id: string; tenant_id: string; admission_id: string;
  shift: NursingShift; handover_date: string;
  outgoing_nurse: string; incoming_nurse: string;
  identification: string | null; situation: string | null;
  background: string | null; assessment: string | null; recommendation: string | null;
  pending_tasks: unknown; acknowledged_at: string | null;
  created_at: string; updated_at: string;
}

export interface IpdDischargeChecklist {
  id: string; tenant_id: string; admission_id: string;
  item_code: string; item_label: string; status: string;
  completed_by: string | null; completed_at: string | null; sort_order: number;
  created_at: string; updated_at: string;
}

// IPD Clinical Request Types
export interface CreateProgressNoteRequest { note_type: ProgressNoteType; note_date?: string; subjective?: string; objective?: string; assessment?: string; plan?: string; is_addendum?: boolean; parent_note_id?: string; }
export interface UpdateProgressNoteRequest { subjective?: string; objective?: string; assessment?: string; plan?: string; }
export interface CreateAssessmentRequest { assessment_type: ClinicalAssessmentType; score_value?: number; risk_level?: string; score_details?: unknown; }
export interface CreateMarRequest { prescription_item_id?: string; drug_name: string; dose: string; route: string; frequency?: string; scheduled_at: string; is_high_alert?: boolean; notes?: string; }
export interface UpdateMarRequest { status: MarStatus; administered_at?: string; witnessed_by?: string; barcode_verified?: boolean; hold_reason?: string; refused_reason?: string; notes?: string; }
export interface CreateIntakeOutputRequest { is_intake: boolean; category: string; volume_ml: number; description?: string; recorded_at?: string; shift: NursingShift; }
export interface CreateNursingAssessmentRequest { general_appearance?: unknown; skin_assessment?: unknown; pain_assessment?: unknown; nutritional_status?: unknown; elimination_status?: unknown; respiratory_status?: unknown; psychosocial_status?: unknown; fall_risk_assessment?: unknown; allergies?: string; medications_on_admission?: string; personal_belongings?: unknown; patient_education_needs?: string; }
export interface CreateCarePlanRequest { nursing_diagnosis: string; goals?: string; interventions?: unknown; }
export interface UpdateCarePlanRequest { goals?: string; interventions?: unknown; evaluation?: string; status?: CarePlanStatus; }
export interface CreateHandoverRequest { shift: NursingShift; handover_date?: string; incoming_nurse: string; identification?: string; situation?: string; background?: string; assessment?: string; recommendation?: string; pending_tasks?: unknown; }
export interface UpdateDischargeChecklistRequest { status: string; }

// ══════════════════════════════════════════════════════════════
//  Operation Theatre (OT)
// ══════════════════════════════════════════════════════════════

export type OtBookingStatus = "requested" | "confirmed" | "in_progress" | "completed" | "cancelled" | "postponed";
export type OtCasePriority = "elective" | "urgent" | "emergency";
export type AnesthesiaType = "general" | "spinal" | "epidural" | "regional_block" | "local" | "sedation" | "combined";
export type AsaClassification = "asa_1" | "asa_2" | "asa_3" | "asa_4" | "asa_5" | "asa_6";
export type ChecklistPhase = "sign_in" | "time_out" | "sign_out";
export type OtRoomStatus = "available" | "in_use" | "cleaning" | "maintenance" | "reserved";
export type PreopClearanceStatus = "pending" | "cleared" | "not_cleared" | "conditional";
export type PostopRecoveryStatus = "in_recovery" | "stable" | "shifted_to_ward" | "shifted_to_icu" | "discharged";

export interface OtRoom {
  id: string; tenant_id: string; location_id: string | null;
  name: string; code: string; status: OtRoomStatus;
  specialties: unknown; equipment: unknown; is_active: boolean;
  created_at: string; updated_at: string;
}

export interface OtBooking {
  id: string; tenant_id: string; patient_id: string;
  admission_id: string | null; ot_room_id: string;
  primary_surgeon_id: string; anesthetist_id: string | null;
  scheduled_date: string; scheduled_start: string; scheduled_end: string;
  actual_start: string | null; actual_end: string | null;
  procedure_name: string; procedure_code: string | null; laterality: string | null;
  priority: OtCasePriority; status: OtBookingStatus;
  consent_obtained: boolean; site_marked: boolean; blood_arranged: boolean;
  assistant_surgeons: unknown; scrub_nurses: unknown; circulating_nurses: unknown;
  estimated_duration_min: number | null;
  actual_start_time: string | null; actual_end_time: string | null; turnaround_minutes: number | null;
  cancellation_reason: string | null; postpone_reason: string | null; notes: string | null;
  created_at: string; updated_at: string;
}

export interface OtBookingListResponse { bookings: OtBooking[]; total: number; page: number; per_page: number; }

export interface OtPreopAssessment {
  id: string; tenant_id: string; booking_id: string;
  clearance_status: PreopClearanceStatus; asa_class: AsaClassification | null;
  airway_assessment: unknown; cardiac_assessment: unknown; pulmonary_assessment: unknown;
  lab_results_reviewed: boolean; imaging_reviewed: boolean; blood_group_confirmed: boolean;
  fasting_status: boolean; npo_since: string | null;
  allergies_noted: string | null; current_medications: string | null; conditions: string | null;
  assessed_by: string; assessed_at: string;
  created_at: string; updated_at: string;
}

export interface OtSurgicalSafetyChecklist {
  id: string; tenant_id: string; booking_id: string;
  phase: ChecklistPhase; items: unknown; completed: boolean;
  completed_by: string | null; completed_at: string | null; verified_by: string | null;
  created_at: string; updated_at: string;
}

export interface OtCaseRecord {
  id: string; tenant_id: string; booking_id: string; surgeon_id: string;
  patient_in_time: string | null; patient_out_time: string | null;
  incision_time: string | null; closure_time: string | null;
  procedure_performed: string; findings: string | null; technique: string | null;
  complications: string | null; blood_loss_ml: number | null;
  specimens: unknown; implants: unknown; drains: unknown;
  instrument_count_correct_before: boolean | null;
  instrument_count_correct_after: boolean | null;
  sponge_count_correct: boolean | null; cssd_issuance_ids: unknown;
  surgical_site_infection: boolean; ssi_detected_at: string | null;
  notes: string | null; created_at: string; updated_at: string;
}

export interface OtAnesthesiaRecord {
  id: string; tenant_id: string; booking_id: string; anesthetist_id: string;
  anesthesia_type: AnesthesiaType; asa_class: AsaClassification | null;
  induction_time: string | null; intubation_time: string | null; extubation_time: string | null;
  airway_details: unknown; drugs_administered: unknown; monitoring_events: unknown;
  fluids_given: unknown; blood_products: unknown; adverse_events: unknown;
  complications: string | null; notes: string | null;
  created_at: string; updated_at: string;
}

export interface OtPostopRecord {
  id: string; tenant_id: string; booking_id: string;
  destination_bed_id: string | null; recovery_status: PostopRecoveryStatus;
  arrival_time: string | null; discharge_time: string | null;
  aldrete_score_arrival: number | null; aldrete_score_discharge: number | null;
  vitals_on_arrival: unknown; monitoring_entries: unknown;
  pain_assessment: string | null; fluid_orders: string | null;
  diet_orders: string | null; activity_orders: string | null;
  disposition: string | null; postop_orders: unknown; notes: string | null;
  created_at: string; updated_at: string;
}

export interface OtSurgeonPreference {
  id: string; tenant_id: string; surgeon_id: string;
  procedure_name: string; position: string | null; skin_prep: string | null; draping: string | null;
  instruments: unknown; sutures: unknown; implants: unknown;
  equipment: unknown; medications: unknown;
  special_instructions: string | null; is_active: boolean;
  created_at: string; updated_at: string;
}

// OT Request Types
export interface CreateOtRoomRequest { name: string; code: string; location_id?: string; specialties?: unknown; equipment?: unknown; }
export interface UpdateOtRoomRequest { name?: string; status?: OtRoomStatus; specialties?: unknown; equipment?: unknown; is_active?: boolean; }
export interface CreateOtBookingRequest { patient_id: string; admission_id?: string; ot_room_id: string; primary_surgeon_id: string; anesthetist_id?: string; scheduled_date: string; scheduled_start: string; scheduled_end: string; procedure_name: string; procedure_code?: string; laterality?: string; priority?: OtCasePriority; estimated_duration_min?: number; assistant_surgeons?: unknown; scrub_nurses?: unknown; circulating_nurses?: unknown; notes?: string; }
export interface UpdateOtBookingRequest { ot_room_id?: string; anesthetist_id?: string; scheduled_date?: string; scheduled_start?: string; scheduled_end?: string; procedure_name?: string; laterality?: string; priority?: OtCasePriority; consent_obtained?: boolean; site_marked?: boolean; blood_arranged?: boolean; assistant_surgeons?: unknown; scrub_nurses?: unknown; circulating_nurses?: unknown; estimated_duration_min?: number; notes?: string; }
export interface UpdateOtBookingStatusRequest { status: OtBookingStatus; actual_start?: string; actual_end?: string; cancellation_reason?: string; postpone_reason?: string; }
export interface CreatePreopAssessmentRequest { asa_class?: AsaClassification; airway_assessment?: unknown; cardiac_assessment?: unknown; pulmonary_assessment?: unknown; lab_results_reviewed?: boolean; imaging_reviewed?: boolean; blood_group_confirmed?: boolean; fasting_status?: boolean; npo_since?: string; allergies_noted?: string; current_medications?: string; conditions?: string; }
export interface UpdatePreopAssessmentRequest { clearance_status?: PreopClearanceStatus; asa_class?: AsaClassification; airway_assessment?: unknown; cardiac_assessment?: unknown; pulmonary_assessment?: unknown; lab_results_reviewed?: boolean; imaging_reviewed?: boolean; blood_group_confirmed?: boolean; fasting_status?: boolean; npo_since?: string; }
export interface CreateSafetyChecklistRequest { phase: ChecklistPhase; items: unknown; }
export interface UpdateSafetyChecklistRequest { items?: unknown; completed?: boolean; }
export interface CreateCaseRecordRequest { patient_in_time?: string; patient_out_time?: string; incision_time?: string; closure_time?: string; procedure_performed: string; findings?: string; technique?: string; complications?: string; blood_loss_ml?: number; specimens?: unknown; implants?: unknown; drains?: unknown; instrument_count_correct_before?: boolean; instrument_count_correct_after?: boolean; sponge_count_correct?: boolean; cssd_issuance_ids?: unknown; notes?: string; }
export interface UpdateCaseRecordRequest { patient_out_time?: string; closure_time?: string; findings?: string; technique?: string; complications?: string; blood_loss_ml?: number; specimens?: unknown; implants?: unknown; drains?: unknown; instrument_count_correct_after?: boolean; sponge_count_correct?: boolean; notes?: string; }
export interface CreateAnesthesiaRecordRequest { anesthesia_type: AnesthesiaType; asa_class?: AsaClassification; induction_time?: string; intubation_time?: string; airway_details?: unknown; drugs_administered?: unknown; notes?: string; }
export interface UpdateAnesthesiaRecordRequest { extubation_time?: string; monitoring_events?: unknown; fluids_given?: unknown; blood_products?: unknown; adverse_events?: unknown; complications?: string; notes?: string; }
export interface CreatePostopRecordRequest { destination_bed_id?: string; arrival_time?: string; aldrete_score_arrival?: number; vitals_on_arrival?: unknown; pain_assessment?: string; fluid_orders?: string; diet_orders?: string; activity_orders?: string; postop_orders?: unknown; notes?: string; }
export interface UpdatePostopRecordRequest { recovery_status?: PostopRecoveryStatus; discharge_time?: string; aldrete_score_discharge?: number; monitoring_entries?: unknown; disposition?: string; notes?: string; }
export interface CreateSurgeonPreferenceRequest { surgeon_id: string; procedure_name: string; position?: string; skin_prep?: string; draping?: string; instruments?: unknown; sutures?: unknown; implants?: unknown; equipment?: unknown; medications?: unknown; special_instructions?: string; }
export interface UpdateSurgeonPreferenceRequest { position?: string; skin_prep?: string; draping?: string; instruments?: unknown; sutures?: unknown; implants?: unknown; equipment?: unknown; medications?: unknown; special_instructions?: string; is_active?: boolean; }

// ══════════════════════════════════════════════════════════════
//  Blood Bank & Transfusion Medicine
// ══════════════════════════════════════════════════════════════

export type DonationType = "whole_blood" | "apheresis_platelets" | "apheresis_plasma";

export type BloodComponentType =
  | "whole_blood"
  | "prbc"
  | "ffp"
  | "platelets"
  | "cryoprecipitate"
  | "granulocytes";

export type BloodBagStatus =
  | "collected"
  | "processing"
  | "tested"
  | "available"
  | "reserved"
  | "crossmatched"
  | "issued"
  | "transfused"
  | "returned"
  | "expired"
  | "discarded";

export type CrossmatchStatus =
  | "requested"
  | "testing"
  | "compatible"
  | "incompatible"
  | "issued"
  | "cancelled";

export type TransfusionReactionSeverity = "mild" | "moderate" | "severe" | "fatal";

export interface BloodDonor {
  id: string;
  tenant_id: string;
  donor_number: string;
  first_name: string;
  last_name: string;
  date_of_birth: string | null;
  gender: string | null;
  blood_group: string;
  phone: string | null;
  email: string | null;
  address: string | null;
  id_type: string | null;
  id_number: string | null;
  is_active: boolean;
  is_deferred: boolean;
  deferral_reason: string | null;
  deferral_until: string | null;
  last_donation: string | null;
  total_donations: number;
  medical_history: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

export interface BloodDonation {
  id: string;
  tenant_id: string;
  donor_id: string;
  bag_number: string;
  donation_type: DonationType;
  volume_ml: number;
  donated_at: string;
  collected_by: string | null;
  camp_name: string | null;
  adverse_reaction: string | null;
  notes: string | null;
  created_at: string;
}

export interface BloodComponent {
  id: string;
  tenant_id: string;
  donation_id: string;
  component_type: BloodComponentType;
  bag_number: string;
  blood_group: string;
  volume_ml: number;
  status: BloodBagStatus;
  collected_at: string;
  expiry_at: string;
  storage_location: string | null;
  storage_temperature: string | null;
  tti_status: string | null;
  tti_tested_at: string | null;
  issued_to_patient: string | null;
  issued_at: string | null;
  issued_by: string | null;
  discarded_at: string | null;
  discard_reason: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface CrossmatchRequest {
  id: string;
  tenant_id: string;
  patient_id: string;
  component_id: string | null;
  requested_by: string;
  blood_group: string;
  component_type: BloodComponentType;
  units_requested: number;
  clinical_indication: string | null;
  status: CrossmatchStatus;
  result: string | null;
  tested_by: string | null;
  tested_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface TransfusionRecord {
  id: string;
  tenant_id: string;
  patient_id: string;
  component_id: string;
  crossmatch_id: string | null;
  administered_by: string;
  verified_by: string | null;
  started_at: string;
  completed_at: string | null;
  volume_transfused_ml: number | null;
  has_reaction: boolean;
  reaction_type: string | null;
  reaction_severity: TransfusionReactionSeverity | null;
  reaction_details: string | null;
  reaction_reported_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface DonorListResponse {
  donors: BloodDonor[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateDonorRequest {
  donor_number: string;
  first_name: string;
  last_name: string;
  blood_group: string;
  date_of_birth?: string;
  gender?: string;
  phone?: string;
  email?: string;
  address?: string;
  id_type?: string;
  id_number?: string;
}

export interface CreateDonationRequest {
  bag_number: string;
  donation_type?: DonationType;
  volume_ml: number;
  camp_name?: string;
  notes?: string;
}

export interface AdverseReaction {
  reaction_type: "vasovagal" | "hematoma" | "nerve_injury" | "citrate_reaction" | "allergic" | "other";
  severity: "mild" | "moderate" | "severe";
  description: string;
  treatment_given: string;
  outcome: "resolved" | "referred" | "hospitalized";
}

export interface UpdateDonationRequest {
  adverse_reaction?: string;
  notes?: string;
}

export interface CreateComponentRequest {
  donation_id: string;
  component_type: BloodComponentType;
  bag_number: string;
  blood_group: string;
  volume_ml: number;
  expiry_at: string;
  storage_location?: string;
}

export interface UpdateComponentStatusRequest {
  status: BloodBagStatus;
  discard_reason?: string;
}

export interface CreateCrossmatchRequestBody {
  patient_id: string;
  blood_group: string;
  component_type?: BloodComponentType;
  units_requested?: number;
  clinical_indication?: string;
}

export interface UpdateCrossmatchRequestBody {
  status?: CrossmatchStatus;
  result?: string;
  component_id?: string;
}

export interface CreateTransfusionRequest {
  patient_id: string;
  component_id: string;
  crossmatch_id?: string;
}

export interface RecordReactionRequest {
  reaction_type: string;
  reaction_severity: TransfusionReactionSeverity;
  reaction_details?: string;
}

// ══════════════════════════════════════════════════════════════
//  ICU / Critical Care
// ══════════════════════════════════════════════════════════════

export type IcuScoreType =
  | "apache_ii"
  | "apache_iv"
  | "sofa"
  | "gcs"
  | "prism"
  | "snappe"
  | "rass"
  | "cam_icu";

export type VentilatorMode =
  | "cmv"
  | "acv"
  | "simv"
  | "psv"
  | "cpap"
  | "bipap"
  | "hfov"
  | "aprv"
  | "niv"
  | "other";

export type IcuDeviceType =
  | "central_line"
  | "urinary_catheter"
  | "ventilator"
  | "arterial_line"
  | "peripheral_iv"
  | "nasogastric_tube"
  | "chest_tube"
  | "tracheostomy";

export type NutritionRoute = "enteral" | "parenteral" | "oral" | "npo";

export interface IcuFlowsheet {
  id: string;
  tenant_id: string;
  admission_id: string;
  recorded_at: string;
  recorded_by: string;
  heart_rate: number | null;
  systolic_bp: number | null;
  diastolic_bp: number | null;
  mean_arterial_bp: number | null;
  respiratory_rate: number | null;
  spo2: number | null;
  temperature: number | null;
  cvp: number | null;
  intake_ml: number | null;
  output_ml: number | null;
  urine_ml: number | null;
  drain_ml: number | null;
  infusions: Record<string, unknown>[] | null;
  notes: string | null;
  created_at: string;
}

export interface IcuVentilatorRecord {
  id: string;
  tenant_id: string;
  admission_id: string;
  recorded_at: string;
  recorded_by: string;
  mode: VentilatorMode;
  fio2: number | null;
  peep: number | null;
  tidal_volume: number | null;
  respiratory_rate: number | null;
  pip: number | null;
  plateau_pressure: number | null;
  ph: number | null;
  pao2: number | null;
  paco2: number | null;
  hco3: number | null;
  sao2: number | null;
  lactate: number | null;
  notes: string | null;
  created_at: string;
}

export interface IcuScore {
  id: string;
  tenant_id: string;
  admission_id: string;
  score_type: IcuScoreType;
  score_value: number;
  score_details: Record<string, unknown> | null;
  predicted_mortality: number | null;
  scored_at: string;
  scored_by: string;
  notes: string | null;
  created_at: string;
}

export interface IcuDevice {
  id: string;
  tenant_id: string;
  admission_id: string;
  device_type: IcuDeviceType;
  inserted_at: string;
  inserted_by: string | null;
  removed_at: string | null;
  removed_by: string | null;
  site: string | null;
  is_active: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface IcuBundleCheck {
  id: string;
  tenant_id: string;
  device_id: string;
  checked_at: string;
  checked_by: string;
  is_compliant: boolean;
  still_needed: boolean;
  checklist: Record<string, unknown> | null;
  notes: string | null;
  created_at: string;
}

export interface IcuNutrition {
  id: string;
  tenant_id: string;
  admission_id: string;
  recorded_at: string;
  recorded_by: string;
  route: NutritionRoute;
  formula_name: string | null;
  rate_ml_hr: number | null;
  calories_kcal: number | null;
  protein_gm: number | null;
  volume_ml: number | null;
  notes: string | null;
  created_at: string;
}

export interface IcuNeonatalRecord {
  id: string;
  tenant_id: string;
  admission_id: string;
  recorded_at: string;
  recorded_by: string;
  gestational_age_weeks: number | null;
  birth_weight_gm: number | null;
  current_weight_gm: number | null;
  bilirubin_total: number | null;
  bilirubin_direct: number | null;
  phototherapy_active: boolean;
  phototherapy_hours: number | null;
  breast_milk_type: string | null;
  breast_milk_volume_ml: number | null;
  hearing_screen_result: string | null;
  sepsis_screen_result: string | null;
  mother_patient_id: string | null;
  notes: string | null;
  created_at: string;
}

export interface CreateIcuFlowsheetRequest {
  heart_rate?: number;
  systolic_bp?: number;
  diastolic_bp?: number;
  mean_arterial_bp?: number;
  respiratory_rate?: number;
  spo2?: number;
  temperature?: number;
  cvp?: number;
  intake_ml?: number;
  output_ml?: number;
  urine_ml?: number;
  drain_ml?: number;
  infusions?: Record<string, unknown>[];
  notes?: string;
}

export interface CreateIcuVentilatorRequest {
  mode: VentilatorMode;
  fio2?: number;
  peep?: number;
  tidal_volume?: number;
  respiratory_rate?: number;
  pip?: number;
  plateau_pressure?: number;
  ph?: number;
  pao2?: number;
  paco2?: number;
  hco3?: number;
  sao2?: number;
  lactate?: number;
  notes?: string;
}

export interface CreateIcuScoreRequest {
  score_type: IcuScoreType;
  score_value: number;
  score_details?: Record<string, unknown>;
  predicted_mortality?: number;
  notes?: string;
}

export interface CreateIcuDeviceRequest {
  device_type: IcuDeviceType;
  site?: string;
  notes?: string;
}

export interface CreateIcuBundleCheckRequest {
  is_compliant: boolean;
  still_needed: boolean;
  checklist?: Record<string, unknown>;
  notes?: string;
}

export interface CreateIcuNutritionRequest {
  route: NutritionRoute;
  formula_name?: string;
  rate_ml_hr?: number;
  calories_kcal?: number;
  protein_gm?: number;
  volume_ml?: number;
  notes?: string;
}

export interface CreateIcuNeonatalRequest {
  gestational_age_weeks?: number;
  birth_weight_gm?: number;
  current_weight_gm?: number;
  bilirubin_total?: number;
  bilirubin_direct?: number;
  phototherapy_active?: boolean;
  phototherapy_hours?: number;
  breast_milk_type?: string;
  breast_milk_volume_ml?: number;
  hearing_screen_result?: string;
  sepsis_screen_result?: string;
  mother_patient_id?: string;
  notes?: string;
}

// ══════════════════════════════════════════════════════════════
//  Camp Management
// ══════════════════════════════════════════════════════════════

export type CampType =
  | "general_health"
  | "blood_donation"
  | "vaccination"
  | "eye_screening"
  | "dental"
  | "awareness"
  | "specialized";

export type CampStatus =
  | "planned"
  | "approved"
  | "setup"
  | "active"
  | "completed"
  | "cancelled";

export type CampRegistrationStatus =
  | "registered"
  | "screened"
  | "referred"
  | "converted"
  | "no_show";

export type CampFollowupStatus =
  | "scheduled"
  | "completed"
  | "missed"
  | "cancelled";

export interface Camp {
  id: string;
  tenant_id: string;
  camp_code: string;
  name: string;
  camp_type: CampType;
  status: CampStatus;
  organizing_department_id: string | null;
  coordinator_id: string | null;
  scheduled_date: string;
  start_time: string | null;
  end_time: string | null;
  venue_name: string | null;
  venue_address: string | null;
  venue_city: string | null;
  venue_state: string | null;
  venue_pincode: string | null;
  venue_latitude: number | null;
  venue_longitude: number | null;
  expected_participants: number | null;
  actual_participants: number | null;
  budget_allocated: number | null;
  budget_spent: number | null;
  logistics_notes: string | null;
  equipment_list: unknown | null;
  is_free: boolean;
  discount_percentage: number | null;
  approved_by: string | null;
  approved_at: string | null;
  completed_at: string | null;
  cancellation_reason: string | null;
  summary_notes: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CampTeamMember {
  id: string;
  tenant_id: string;
  camp_id: string;
  employee_id: string;
  role_in_camp: string;
  is_confirmed: boolean;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface CampRegistration {
  id: string;
  tenant_id: string;
  camp_id: string;
  registration_number: string;
  person_name: string;
  age: number | null;
  gender: string | null;
  phone: string | null;
  address: string | null;
  id_proof_type: string | null;
  id_proof_number: string | null;
  patient_id: string | null;
  status: CampRegistrationStatus;
  chief_complaint: string | null;
  is_walk_in: boolean;
  registered_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CampScreening {
  id: string;
  tenant_id: string;
  registration_id: string;
  bp_systolic: number | null;
  bp_diastolic: number | null;
  pulse_rate: number | null;
  spo2: number | null;
  temperature: number | null;
  blood_sugar_random: number | null;
  bmi: number | null;
  height_cm: number | null;
  weight_kg: number | null;
  visual_acuity_left: string | null;
  visual_acuity_right: string | null;
  findings: string | null;
  diagnosis: string | null;
  advice: string | null;
  referred_to_hospital: boolean;
  referral_department: string | null;
  referral_urgency: string | null;
  screened_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CampLabSample {
  id: string;
  tenant_id: string;
  registration_id: string;
  sample_type: string;
  test_requested: string | null;
  barcode: string | null;
  collected_at: string | null;
  collected_by: string | null;
  sent_to_lab: boolean;
  lab_order_id: string | null;
  result_summary: string | null;
  created_at: string;
  updated_at: string;
}

export interface CampBillingRecord {
  id: string;
  tenant_id: string;
  registration_id: string;
  service_description: string;
  standard_amount: number;
  discount_percentage: number | null;
  charged_amount: number;
  is_free: boolean;
  payment_mode: string | null;
  payment_reference: string | null;
  billed_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CampFollowup {
  id: string;
  tenant_id: string;
  registration_id: string;
  followup_date: string;
  followup_type: string;
  status: CampFollowupStatus;
  notes: string | null;
  outcome: string | null;
  converted_to_patient: boolean;
  converted_patient_id: string | null;
  converted_department_id: string | null;
  followed_up_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateCampRequest {
  name: string;
  camp_type: string;
  organizing_department_id?: string;
  coordinator_id?: string;
  scheduled_date: string;
  start_time?: string;
  end_time?: string;
  venue_name?: string;
  venue_address?: string;
  venue_city?: string;
  venue_state?: string;
  venue_pincode?: string;
  venue_latitude?: number;
  venue_longitude?: number;
  expected_participants?: number;
  budget_allocated?: number;
  logistics_notes?: string;
  equipment_list?: unknown;
  is_free?: boolean;
  discount_percentage?: number;
}

export interface UpdateCampRequest {
  name?: string;
  organizing_department_id?: string;
  coordinator_id?: string;
  scheduled_date?: string;
  start_time?: string;
  end_time?: string;
  venue_name?: string;
  venue_address?: string;
  venue_city?: string;
  venue_state?: string;
  venue_pincode?: string;
  venue_latitude?: number;
  venue_longitude?: number;
  expected_participants?: number;
  budget_allocated?: number;
  budget_spent?: number;
  logistics_notes?: string;
  equipment_list?: unknown;
  is_free?: boolean;
  discount_percentage?: number;
  summary_notes?: string;
}

export interface CancelCampRequest {
  cancellation_reason?: string;
}

export interface AddCampTeamMemberRequest {
  employee_id: string;
  role_in_camp: string;
  is_confirmed?: boolean;
  notes?: string;
}

export interface CreateCampRegistrationRequest {
  camp_id: string;
  person_name: string;
  age?: number;
  gender?: string;
  phone?: string;
  address?: string;
  id_proof_type?: string;
  id_proof_number?: string;
  patient_id?: string;
  chief_complaint?: string;
  is_walk_in?: boolean;
}

export interface UpdateCampRegistrationRequest {
  status?: string;
  patient_id?: string;
  chief_complaint?: string;
}

export interface CreateCampScreeningRequest {
  registration_id: string;
  bp_systolic?: number;
  bp_diastolic?: number;
  pulse_rate?: number;
  spo2?: number;
  temperature?: number;
  blood_sugar_random?: number;
  bmi?: number;
  height_cm?: number;
  weight_kg?: number;
  visual_acuity_left?: string;
  visual_acuity_right?: string;
  findings?: string;
  diagnosis?: string;
  advice?: string;
  referred_to_hospital?: boolean;
  referral_department?: string;
  referral_urgency?: string;
}

export interface CreateCampLabSampleRequest {
  registration_id: string;
  sample_type: string;
  test_requested?: string;
  barcode?: string;
}

export interface LinkCampLabSampleRequest {
  lab_order_id: string;
  result_summary?: string;
}

export interface CreateCampBillingRequest {
  registration_id: string;
  service_description: string;
  standard_amount: number;
  discount_percentage?: number;
  charged_amount: number;
  is_free?: boolean;
  payment_mode?: string;
  payment_reference?: string;
}

export interface CreateCampFollowupRequest {
  registration_id: string;
  followup_date: string;
  followup_type: string;
  notes?: string;
}

export interface UpdateCampFollowupRequest {
  status?: string;
  notes?: string;
  outcome?: string;
  converted_to_patient?: boolean;
  converted_patient_id?: string;
  converted_department_id?: string;
}

export interface CampStatsResponse {
  total_registrations: number;
  screened: number;
  referred: number;
  converted: number;
  lab_samples: number;
  followups_scheduled: number;
  followups_completed: number;
  billing_total: number;
}

// ══════════════════════════════════════════════════════════════
//  Consent Management
// ══════════════════════════════════════════════════════════════

export type ConsentTemplateCategory =
  | "general"
  | "surgical"
  | "anesthesia"
  | "blood_transfusion"
  | "investigation"
  | "data_sharing"
  | "research"
  | "photography"
  | "teaching"
  | "refusal"
  | "advance_directive"
  | "organ_donation"
  | "communication"
  | "custom";

export type ConsentAuditAction =
  | "created"
  | "granted"
  | "denied"
  | "signed"
  | "refused"
  | "withdrawn"
  | "revoked"
  | "expired"
  | "renewed"
  | "amended";

export type ConsentSignatureType =
  | "pen_on_paper"
  | "digital_pen"
  | "aadhaar_esign"
  | "biometric_thumb"
  | "otp"
  | "video_consent"
  | "verbal_witness";

export interface ConsentTemplate {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  category: ConsentTemplateCategory;
  version: number;
  body_text: Record<string, string>;
  risks_section: Record<string, string> | null;
  alternatives_section: Record<string, string> | null;
  benefits_section: Record<string, string> | null;
  required_fields: string[];
  requires_witness: boolean;
  requires_doctor: boolean;
  validity_days: number | null;
  applicable_departments: string[] | null;
  is_read_aloud_required: boolean;
  is_active: boolean;
  sort_order: number;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ConsentAuditEntry {
  id: string;
  tenant_id: string;
  patient_id: string;
  consent_source: string;
  consent_id: string;
  action: ConsentAuditAction;
  old_status: string | null;
  new_status: string | null;
  changed_by: string | null;
  change_reason: string | null;
  ip_address: string | null;
  user_agent: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface ConsentSignatureMetadata {
  id: string;
  tenant_id: string;
  consent_source: string;
  consent_id: string;
  signature_type: ConsentSignatureType;
  signature_image_url: string | null;
  video_consent_url: string | null;
  aadhaar_esign_ref: string | null;
  aadhaar_esign_timestamp: string | null;
  biometric_hash: string | null;
  biometric_device_id: string | null;
  witness_name: string | null;
  witness_designation: string | null;
  witness_signature_url: string | null;
  doctor_signature_url: string | null;
  captured_at: string;
  captured_by: string | null;
  created_at: string;
}

export interface CreateConsentTemplateRequest {
  code: string;
  name: string;
  category?: ConsentTemplateCategory;
  version?: number;
  body_text?: Record<string, string>;
  risks_section?: Record<string, string>;
  alternatives_section?: Record<string, string>;
  benefits_section?: Record<string, string>;
  required_fields?: string[];
  requires_witness?: boolean;
  requires_doctor?: boolean;
  validity_days?: number;
  applicable_departments?: string[];
  is_read_aloud_required?: boolean;
  is_active?: boolean;
  sort_order?: number;
}

export interface UpdateConsentTemplateRequest {
  name?: string;
  category?: ConsentTemplateCategory;
  version?: number;
  body_text?: Record<string, string>;
  risks_section?: Record<string, string>;
  alternatives_section?: Record<string, string>;
  benefits_section?: Record<string, string>;
  required_fields?: string[];
  requires_witness?: boolean;
  requires_doctor?: boolean;
  validity_days?: number;
  applicable_departments?: string[];
  is_read_aloud_required?: boolean;
  is_active?: boolean;
  sort_order?: number;
}

export interface VerifyConsentRequest {
  patient_id: string;
  consent_type?: string;
  procedure_type?: string;
}

export interface VerifyConsentResponse {
  is_valid: boolean;
  consent_id: string | null;
  consent_source: string | null;
  expires_at: string | null;
}

export interface ConsentSummaryItem {
  consent_type: string;
  source: string;
  status: string;
  consent_id: string;
  valid_until: string | null;
}

export interface RevokeConsentRequest {
  consent_source: string;
  consent_id: string;
  patient_id: string;
  reason?: string;
}

export interface CreateConsentSignatureRequest {
  consent_source: string;
  consent_id: string;
  signature_type: ConsentSignatureType;
  signature_image_url?: string;
  video_consent_url?: string;
  aadhaar_esign_ref?: string;
  aadhaar_esign_timestamp?: string;
  biometric_hash?: string;
  biometric_device_id?: string;
  witness_name?: string;
  witness_designation?: string;
  witness_signature_url?: string;
  doctor_signature_url?: string;
}

// ══════════════════════════════════════════════════════════════
//  CSSD (Central Sterile Supply Department)
// ══════════════════════════════════════════════════════════════

export type InstrumentStatus =
  | "available"
  | "in_use"
  | "decontaminating"
  | "sterilizing"
  | "sterile"
  | "damaged"
  | "condemned";

export type SterilizationMethod = "steam" | "eto" | "plasma" | "dry_heat" | "flash";

export type IndicatorType = "chemical" | "biological";

export type LoadStatus = "loading" | "running" | "completed" | "failed";

export interface CssdSterilizer {
  id: string;
  tenant_id: string;
  name: string;
  model: string | null;
  serial_number: string | null;
  method: SterilizationMethod;
  chamber_size_liters: number | null;
  location: string | null;
  is_active: boolean;
  last_maintenance_at: string | null;
  next_maintenance_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface CssdInstrument {
  id: string;
  tenant_id: string;
  barcode: string;
  name: string;
  category: string | null;
  manufacturer: string | null;
  status: InstrumentStatus;
  purchase_date: string | null;
  lifecycle_uses: number;
  max_uses: number | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface CssdInstrumentSet {
  id: string;
  tenant_id: string;
  set_code: string;
  set_name: string;
  department: string | null;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface CssdSetItem {
  id: string;
  tenant_id: string;
  set_id: string;
  instrument_id: string;
  quantity: number;
}

export interface CssdSterilizationLoad {
  id: string;
  tenant_id: string;
  load_number: string;
  sterilizer_id: string;
  method: SterilizationMethod;
  status: LoadStatus;
  operator_id: string | null;
  started_at: string | null;
  completed_at: string | null;
  cycle_time_minutes: number | null;
  temperature_c: number | null;
  pressure_psi: number | null;
  is_flash: boolean;
  flash_reason: string | null;
  notes: string | null;
  created_at: string;
}

export interface CssdLoadItem {
  id: string;
  tenant_id: string;
  load_id: string;
  set_id: string | null;
  instrument_id: string | null;
  quantity: number;
  pack_expiry_date: string | null;
}

export interface CssdIndicatorResult {
  id: string;
  tenant_id: string;
  load_id: string;
  indicator_type: IndicatorType;
  indicator_brand: string | null;
  indicator_lot: string | null;
  result_pass: boolean;
  read_at: string;
  read_by: string | null;
  notes: string | null;
  created_at: string;
}

export interface CssdIssuance {
  id: string;
  tenant_id: string;
  load_item_id: string | null;
  set_id: string | null;
  issued_to_department: string;
  issued_to_patient_id: string | null;
  issued_by: string | null;
  issued_at: string;
  returned_at: string | null;
  returned_by: string | null;
  is_recalled: boolean;
  recall_reason: string | null;
  notes: string | null;
  created_at: string;
}

export interface CssdMaintenanceLog {
  id: string;
  tenant_id: string;
  sterilizer_id: string;
  maintenance_type: string;
  performed_by: string | null;
  performed_at: string;
  next_due_at: string | null;
  findings: string | null;
  actions_taken: string | null;
  cost: number | null;
  notes: string | null;
  created_at: string;
}

export interface CreateCssdInstrumentRequest {
  barcode: string;
  name: string;
  category?: string;
  manufacturer?: string;
  purchase_date?: string;
  max_uses?: number;
  notes?: string;
}

export interface UpdateCssdInstrumentRequest {
  name?: string;
  category?: string;
  manufacturer?: string;
  status?: InstrumentStatus;
  max_uses?: number;
  notes?: string;
}

export interface CreateCssdSetRequest {
  set_code: string;
  set_name: string;
  department?: string;
  description?: string;
  items?: Array<{ instrument_id: string; quantity?: number }>;
}

export interface CreateCssdSterilizerRequest {
  name: string;
  model?: string;
  serial_number?: string;
  method?: SterilizationMethod;
  chamber_size_liters?: number;
  location?: string;
}

export interface UpdateCssdSterilizerRequest {
  name?: string;
  model?: string;
  serial_number?: string;
  method?: SterilizationMethod;
  chamber_size_liters?: number;
  location?: string;
  is_active?: boolean;
}

export interface CreateCssdLoadRequest {
  sterilizer_id: string;
  method: SterilizationMethod;
  is_flash?: boolean;
  flash_reason?: string;
  notes?: string;
}

export interface UpdateCssdLoadStatusRequest {
  status: LoadStatus;
  cycle_time_minutes?: number;
  temperature_c?: number;
  pressure_psi?: number;
}

export interface AddCssdLoadItemRequest {
  set_id?: string;
  instrument_id?: string;
  quantity?: number;
  pack_expiry_date?: string;
}

export interface RecordCssdIndicatorRequest {
  indicator_type: IndicatorType;
  indicator_brand?: string;
  indicator_lot?: string;
  result_pass: boolean;
  notes?: string;
}

export interface CreateCssdIssuanceRequest {
  load_item_id?: string;
  set_id?: string;
  issued_to_department: string;
  issued_to_patient_id?: string;
  notes?: string;
}

export interface CreateCssdMaintenanceRequest {
  maintenance_type: string;
  performed_by?: string;
  next_due_at?: string;
  findings?: string;
  actions_taken?: string;
  cost?: number;
  notes?: string;
}

// ══════════════════════════════════════════════════════════════
//  Diet & Kitchen
// ══════════════════════════════════════════════════════════════

export type DietType = "regular" | "diabetic" | "renal" | "cardiac" | "liquid" | "soft" | "high_protein" | "low_sodium" | "npo" | "custom";
export type MealType = "breakfast" | "morning_snack" | "lunch" | "afternoon_snack" | "dinner" | "bedtime_snack";
export type DietOrderStatus = "active" | "modified" | "completed" | "cancelled";
export type MealPrepStatus = "pending" | "preparing" | "ready" | "dispatched" | "delivered";

export interface DietTemplate {
  id: string;
  tenant_id: string;
  name: string;
  diet_type: DietType;
  description: string | null;
  calories_target: number | null;
  protein_g: number | null;
  carbs_g: number | null;
  fat_g: number | null;
  fiber_g: number | null;
  sodium_mg: number | null;
  restrictions: string[];
  suitable_for: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface DietOrder {
  id: string;
  tenant_id: string;
  patient_id: string;
  admission_id: string | null;
  template_id: string | null;
  diet_type: DietType;
  status: DietOrderStatus;
  ordered_by: string | null;
  special_instructions: string | null;
  allergies_flagged: string[];
  is_npo: boolean;
  npo_reason: string | null;
  start_date: string;
  end_date: string | null;
  calories_target: number | null;
  protein_g: number | null;
  carbs_g: number | null;
  fat_g: number | null;
  preferences: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface KitchenMenu {
  id: string;
  tenant_id: string;
  name: string;
  week_number: number | null;
  season: string | null;
  is_active: boolean;
  valid_from: string | null;
  valid_until: string | null;
  created_at: string;
  updated_at: string;
}

export interface KitchenMenuItem {
  id: string;
  tenant_id: string;
  menu_id: string;
  day_of_week: number;
  meal_type: MealType;
  diet_type: DietType;
  item_name: string;
  description: string | null;
  calories: number | null;
  protein_g: number | null;
  carbs_g: number | null;
  fat_g: number | null;
  is_vegetarian: boolean;
  allergens: string[];
}

export interface MealPreparation {
  id: string;
  tenant_id: string;
  diet_order_id: string;
  meal_type: MealType;
  meal_date: string;
  status: MealPrepStatus;
  prepared_by: string | null;
  prepared_at: string | null;
  dispatched_at: string | null;
  delivered_at: string | null;
  delivered_to_ward: string | null;
  delivered_to_bed: string | null;
  patient_feedback: string | null;
  feedback_rating: number | null;
  notes: string | null;
  created_at: string;
}

export interface MealCount {
  id: string;
  tenant_id: string;
  count_date: string;
  meal_type: MealType;
  ward: string;
  total_beds: number;
  occupied: number;
  npo_count: number;
  regular_count: number;
  special_count: number;
  notes: string | null;
  created_at: string;
}

export interface KitchenInventory {
  id: string;
  tenant_id: string;
  item_name: string;
  category: string | null;
  unit: string;
  current_stock: number;
  reorder_level: number | null;
  supplier: string | null;
  last_procured_at: string | null;
  expiry_date: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface KitchenAudit {
  id: string;
  tenant_id: string;
  audit_date: string;
  auditor_name: string;
  audit_type: string;
  temperature_log: Record<string, unknown>;
  hygiene_score: number | null;
  findings: string | null;
  corrective_actions: string | null;
  is_compliant: boolean;
  next_audit_date: string | null;
  attachments: string[];
  created_at: string;
}

export interface CreateDietTemplateRequest {
  name: string;
  diet_type?: DietType;
  description?: string;
  calories_target?: number;
  protein_g?: number;
  carbs_g?: number;
  fat_g?: number;
  fiber_g?: number;
  sodium_mg?: number;
  restrictions?: string[];
  suitable_for?: string[];
}

export interface UpdateDietTemplateRequest {
  name?: string;
  diet_type?: DietType;
  description?: string;
  calories_target?: number;
  protein_g?: number;
  carbs_g?: number;
  fat_g?: number;
  fiber_g?: number;
  sodium_mg?: number;
  restrictions?: string[];
  suitable_for?: string[];
  is_active?: boolean;
}

export interface CreateDietOrderRequest {
  patient_id: string;
  admission_id?: string;
  template_id?: string;
  diet_type?: DietType;
  special_instructions?: string;
  allergies_flagged?: string[];
  is_npo?: boolean;
  npo_reason?: string;
  start_date?: string;
  end_date?: string;
  calories_target?: number;
  protein_g?: number;
  carbs_g?: number;
  fat_g?: number;
  preferences?: Record<string, unknown>;
}

export interface UpdateDietOrderRequest {
  diet_type?: DietType;
  status?: DietOrderStatus;
  special_instructions?: string;
  is_npo?: boolean;
  npo_reason?: string;
  end_date?: string;
  calories_target?: number;
  preferences?: Record<string, unknown>;
}

export interface CreateKitchenMenuRequest {
  name: string;
  week_number?: number;
  season?: string;
  valid_from?: string;
  valid_until?: string;
}

export interface CreateMenuItemRequest {
  day_of_week: number;
  meal_type: MealType;
  diet_type?: DietType;
  item_name: string;
  description?: string;
  calories?: number;
  protein_g?: number;
  carbs_g?: number;
  fat_g?: number;
  is_vegetarian?: boolean;
  allergens?: string[];
}

export interface CreateMealPrepRequest {
  diet_order_id: string;
  meal_type: MealType;
  meal_date?: string;
}

export interface UpdateMealPrepStatusRequest {
  status: MealPrepStatus;
  delivered_to_ward?: string;
  delivered_to_bed?: string;
  patient_feedback?: string;
  feedback_rating?: number;
  notes?: string;
}

export interface CreateMealCountRequest {
  count_date?: string;
  meal_type: MealType;
  ward: string;
  total_beds: number;
  occupied: number;
  npo_count?: number;
  regular_count?: number;
  special_count?: number;
  notes?: string;
}

export interface CreateKitchenInventoryRequest {
  item_name: string;
  category?: string;
  unit?: string;
  current_stock?: number;
  reorder_level?: number;
  supplier?: string;
  expiry_date?: string;
}

export interface UpdateKitchenInventoryRequest {
  item_name?: string;
  category?: string;
  unit?: string;
  current_stock?: number;
  reorder_level?: number;
  supplier?: string;
  expiry_date?: string;
  is_active?: boolean;
}

export interface CreateKitchenAuditRequest {
  audit_date?: string;
  auditor_name: string;
  audit_type?: string;
  temperature_log?: Record<string, unknown>;
  hygiene_score?: number;
  findings?: string;
  corrective_actions?: string;
  is_compliant?: boolean;
  next_audit_date?: string;
}

// ══════════════════════════════════════════════════════════════
//  Integration Hub
// ══════════════════════════════════════════════════════════════

export type PipelineStatus = "draft" | "active" | "paused" | "archived";
export type ExecutionStatus = "pending" | "running" | "completed" | "failed" | "skipped";
export type PipelineTriggerType = "internal_event" | "schedule" | "webhook" | "manual";
export type PipelineNodeType = "trigger" | "condition" | "action" | "transform" | "delay";

export interface ReactFlowNode {
  id: string;
  type: string;
  position: { x: number; y: number };
  data: Record<string, unknown>;
}

export interface ReactFlowEdge {
  id: string;
  source: string;
  target: string;
  sourceHandle?: string | null;
  targetHandle?: string | null;
  label?: string;
}

export interface IntegrationPipeline {
  id: string;
  tenant_id: string;
  name: string;
  code: string;
  description: string | null;
  status: PipelineStatus;
  trigger_type: PipelineTriggerType;
  trigger_config: Record<string, unknown>;
  nodes: ReactFlowNode[];
  edges: ReactFlowEdge[];
  metadata: Record<string, unknown>;
  version: number;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface PipelineSummary {
  id: string;
  name: string;
  code: string;
  description: string | null;
  status: PipelineStatus;
  trigger_type: PipelineTriggerType;
  version: number;
  execution_count: number;
  last_run_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface IntegrationExecution {
  id: string;
  tenant_id: string;
  pipeline_id: string;
  pipeline_version: number;
  trigger_event: string | null;
  status: ExecutionStatus;
  input_data: Record<string, unknown>;
  output_data: Record<string, unknown>;
  node_results: Record<string, unknown>;
  error: string | null;
  triggered_by: string | null;
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
}

export interface IntegrationNodeTemplate {
  id: string;
  tenant_id: string | null;
  node_type: PipelineNodeType;
  code: string;
  name: string;
  description: string | null;
  icon: string | null;
  color: string | null;
  category: string | null;
  config_schema: Record<string, unknown>;
  default_config: Record<string, unknown>;
  output_schema: { fields?: SchemaField[] } & Record<string, unknown>;
  input_schema?: { fields?: SchemaField[] } & Record<string, unknown>;
  is_system: boolean;
  created_at: string;
}

export interface PipelineListResponse {
  pipelines: PipelineSummary[];
  total: number;
  page: number;
  per_page: number;
}

export interface ExecutionListResponse {
  executions: IntegrationExecution[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreatePipelineRequest {
  name: string;
  code: string;
  description?: string;
  trigger_type: PipelineTriggerType;
  trigger_config?: Record<string, unknown>;
  nodes?: ReactFlowNode[];
  edges?: ReactFlowEdge[];
  metadata?: Record<string, unknown>;
}

export interface UpdatePipelineRequest {
  name?: string;
  description?: string;
  trigger_type?: PipelineTriggerType;
  trigger_config?: Record<string, unknown>;
  nodes?: ReactFlowNode[];
  edges?: ReactFlowEdge[];
  metadata?: Record<string, unknown>;
}

export interface UpdatePipelineStatusRequest {
  status: PipelineStatus;
}

export interface TriggerPipelineRequest {
  input_data?: Record<string, unknown>;
}

// ── Field Mapping (Map Data Transform Node) ─────────────

export type StringOperationType =
  | "uppercase" | "lowercase" | "trim" | "capitalize"
  | "camel_case" | "snake_case" | "kebab_case" | "slug"
  | "pad_start" | "pad_end"
  | "substring" | "replace" | "regex_replace" | "regex_extract"
  | "split" | "template" | "truncate"
  | "encode_base64" | "decode_base64";

export type ArrayOperationType =
  | "join" | "flatten" | "unique" | "sort_array" | "reverse"
  | "first" | "last" | "nth"
  | "count" | "filter" | "map_each" | "pluck"
  | "sum" | "avg" | "array_min" | "array_max"
  | "push" | "concat_arrays" | "slice" | "chunk";

export type NumberOperationType =
  | "to_number" | "round" | "ceil" | "floor" | "abs" | "mod"
  | "add" | "subtract" | "multiply" | "divide"
  | "clamp" | "format_number";

export type DateOperationType =
  | "to_date" | "format_date" | "parse_date"
  | "add_days" | "add_hours" | "subtract_days"
  | "date_diff" | "now"
  | "extract_year" | "extract_month" | "extract_day";

export type ConversionOperationType =
  | "to_string" | "to_boolean" | "to_array"
  | "parse_json" | "to_json"
  | "coalesce" | "default_value"
  | "is_null" | "is_empty" | "typeof";

export type MergeOperationType = "merge_field";

export type MappingOperationType =
  | "none"
  | StringOperationType
  | ArrayOperationType
  | NumberOperationType
  | DateOperationType
  | ConversionOperationType
  | MergeOperationType;

export type OperationCategory = "string" | "array" | "number" | "date" | "conversion" | "merge";

export interface OperationDescriptor {
  type: MappingOperationType;
  label: string;
  category: OperationCategory;
  description: string;
  hasConfig: boolean;
}

export interface MappingOperationConfig {
  dateFormat?: string;
  separator?: string;
  start?: number;
  end?: number;
  find?: string;
  replaceWith?: string;
  defaultValue?: string;
  templateString?: string;
  padChar?: string;
  padLength?: number;
  regex?: string;
  regexFlags?: string;
  maxLength?: number;
  suffix?: string;
  index?: number;
  field?: string;
  condition?: string;
  chunkSize?: number;
  operand?: number;
  minValue?: number;
  maxValue?: number;
  decimalPlaces?: number;
  locale?: string;
  inputFormat?: string;
  outputFormat?: string;
  days?: number;
  hours?: number;
  /** merge_field: path of the additional source field to merge */
  mergeFieldPath?: string;
  /** merge_field: how to combine — concat, template, fallback, arithmetic */
  mergeCombineMode?: string;
}

export interface TransformStep {
  id: string;
  operation: MappingOperationType;
  config: MappingOperationConfig;
}

// Combine modes for multi-source mapping
export type CombineMode = "single" | "concat" | "fallback" | "template" | "arithmetic";

export interface MappingSource {
  id: string;
  path: string;
  nodeId?: string;
  /** Nested group: when children exist, this is a group node */
  children?: MappingSource[];
  /** Combine mode for this group's children */
  groupCombineMode?: CombineMode;
  /** Combine config for this group */
  groupCombineConfig?: CombineConfig;
}

export interface CombineConfig {
  separator?: string;
  templateStr?: string;
  expression?: string;
}

export type MappingFieldType =
  | "string"
  | "number"
  | "boolean"
  | "array"
  | "object"
  | "date"
  | "null"
  | "unknown";

export interface TargetFieldSuggestion {
  path: string;
  label: string;
  group: string;
  type?: MappingFieldType;
}

export interface FieldMapping {
  id: string;
  from: string;
  to: string;
  operation: MappingOperationType;
  operationConfig: MappingOperationConfig;
  chain?: TransformStep[];
  sources?: MappingSource[];
  combineMode?: CombineMode;
  combineConfig?: CombineConfig;
}

export interface AvailableField {
  nodeId: string;
  nodeLabel: string;
  path: string;
  source?: string;
  type?: MappingFieldType;
}

// ── Schema Registry ─────────────────────────────────────

export interface SchemaField {
  path: string;
  type: string;
  label: string;
  description?: string;
}

export interface ModuleEntitySchema {
  id: string;
  module_code: string;
  entity_code: string;
  entity_label: string;
  fields: SchemaField[];
}

export interface EventSchema {
  id: string;
  event_type: string;
  module_code: string;
  label: string;
  description?: string;
  payload_schema: SchemaField[];
  entity_code?: string;
}

export interface ModuleSummary {
  module_code: string;
  label: string;
}

// ── Screen System ──────────────────────────────────────────

export type ScreenType =
  | "form"
  | "list"
  | "detail"
  | "composite"
  | "wizard"
  | "dashboard"
  | "calendar"
  | "kanban";

export type SidecarTrigger =
  | "screen_load"
  | "screen_exit"
  | "form_submit"
  | "form_validate"
  | "form_save_draft"
  | "field_change"
  | "row_select"
  | "row_action"
  | "interval"
  | "step_enter"
  | "step_leave";

export type ScreenStatus = "draft" | "active" | "deprecated";

export interface ScreenMaster {
  id: string;
  tenant_id: string | null;
  code: string;
  name: string;
  description: string | null;
  screen_type: ScreenType;
  module_code: string | null;
  status: ScreenStatus;
  version: number;
  layout: Record<string, unknown>;
  config: Record<string, unknown>;
  route_path: string | null;
  icon: string | null;
  permission_code: string | null;
  is_system: boolean;
  is_active: boolean;
  sort_order: number;
  published_at: string | null;
  published_by: string | null;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ScreenSummary {
  id: string;
  code: string;
  name: string;
  description: string | null;
  screen_type: ScreenType;
  module_code: string | null;
  status: ScreenStatus;
  version: number;
  route_path: string | null;
  icon: string | null;
  permission_code: string | null;
  is_system: boolean;
  is_active: boolean;
  sort_order: number;
  published_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface ScreenSidecar {
  id: string;
  screen_id: string;
  name: string;
  description: string | null;
  trigger_event: SidecarTrigger;
  trigger_config: Record<string, unknown>;
  pipeline_id: string | null;
  inline_action: Record<string, unknown> | null;
  condition: Record<string, unknown> | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface ResolvedSidecar {
  id: string;
  name: string;
  trigger_event: SidecarTrigger;
  trigger_config: Record<string, unknown>;
  pipeline_id: string | null;
  inline_action: Record<string, unknown> | null;
  condition: Record<string, unknown> | null;
}

export interface ResolvedScreen {
  id: string;
  code: string;
  name: string;
  description: string | null;
  screen_type: ScreenType;
  module_code: string | null;
  version: number;
  layout: Record<string, unknown>;
  config: Record<string, unknown>;
  route_path: string | null;
  icon: string | null;
  permission_code: string | null;
  sidecars: ResolvedSidecar[];
}

export interface ScreenVersionSnapshot {
  id: string;
  screen_id: string;
  version: number;
  name: string;
  screen_type: ScreenType;
  status: ScreenStatus;
  layout: Record<string, unknown>;
  config: Record<string, unknown>;
  form_refs: unknown[];
  sidecars: unknown[];
  change_summary: string | null;
  created_by: string | null;
  created_at: string;
}

export interface ScreenVersionSummary {
  id: string;
  screen_id: string;
  version: number;
  name: string;
  screen_type: ScreenType;
  status: ScreenStatus;
  change_summary: string | null;
  created_by: string | null;
  created_by_name: string | null;
  created_at: string;
}

export interface TenantScreenOverride {
  id: string;
  screen_id: string;
  screen_code: string;
  screen_name: string;
  layout_patch: Record<string, unknown>;
  config_patch: Record<string, unknown>;
  hidden_zones: string[];
  extra_actions: unknown[];
  is_active: boolean;
  created_at: string;
}

export interface CreateScreenRequest {
  code: string;
  name: string;
  description?: string;
  screen_type: ScreenType;
  module_code?: string;
  route_path?: string;
  icon?: string;
  permission_code?: string;
  layout?: Record<string, unknown>;
  config?: Record<string, unknown>;
  sort_order?: number;
}

export interface UpdateScreenRequest {
  name?: string;
  description?: string;
  module_code?: string;
  route_path?: string;
  icon?: string;
  permission_code?: string;
  layout?: Record<string, unknown>;
  config?: Record<string, unknown>;
  sort_order?: number;
}

export interface CreateSidecarRequest {
  name: string;
  description?: string;
  trigger_event: SidecarTrigger;
  trigger_config?: Record<string, unknown>;
  pipeline_id?: string;
  inline_action?: Record<string, unknown>;
  condition?: Record<string, unknown>;
  sort_order?: number;
}

export interface ScreenOverrideRequest {
  layout_patch?: Record<string, unknown>;
  config_patch?: Record<string, unknown>;
  hidden_zones?: string[];
  extra_actions?: unknown[];
}

// ── Screen Layout Zone Types ────────────────────────────────

export type ScreenZoneType =
  | "form"
  | "data_table"
  | "filter_bar"
  | "detail_header"
  | "tabs"
  | "stepper"
  | "calendar"
  | "kanban"
  | "widget_grid"
  | "info_panel";

export interface ScreenZone {
  type: ScreenZoneType;
  key: string;
  label?: string;
  config: Record<string, unknown>;
}

export interface ScreenAction {
  key: string;
  label: string;
  icon?: string;
  variant?: string;
  action_type: string;
  permission?: string;
  route?: string;
  confirm?: boolean;
}

export interface ScreenLayout {
  header?: {
    title: string;
    subtitle?: string;
    icon?: string;
  };
  breadcrumbs?: Array<{ label: string; path: string }>;
  actions?: ScreenAction[];
  zones: ScreenZone[];
}

// ══════════════════════════════════════════════════════════
//  Clinical Decision Support
// ══════════════════════════════════════════════════════════

export interface DrugInteraction {
  id: string;
  tenant_id: string;
  drug_a_name: string;
  drug_b_name: string;
  severity: "minor" | "moderate" | "major" | "contraindicated";
  description: string;
  mechanism: string | null;
  management: string | null;
  source: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface DrugInteractionAlert {
  drug_a: string;
  drug_b: string;
  severity: string;
  description: string;
  management: string | null;
}

export interface AllergyConflict {
  drug_name: string;
  allergen_name: string;
  allergy_type: string;
  severity: string | null;
  reaction: string | null;
}

export interface DrugSafetyCheckResult {
  interactions: DrugInteractionAlert[];
  allergy_conflicts: AllergyConflict[];
}

export interface CheckDrugInteractionsRequest {
  drug_names: string[];
  patient_id?: string;
}

export interface CreateDrugInteractionRequest {
  drug_a_name: string;
  drug_b_name: string;
  severity: "minor" | "moderate" | "major" | "contraindicated";
  description: string;
  mechanism?: string;
  management?: string;
}

export interface CriticalValueRule {
  id: string;
  tenant_id: string;
  test_code: string;
  test_name: string;
  low_critical: number | null;
  high_critical: number | null;
  unit: string | null;
  age_min: number | null;
  age_max: number | null;
  gender: string | null;
  alert_message: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateCriticalValueRuleRequest {
  test_code: string;
  test_name: string;
  low_critical?: number;
  high_critical?: number;
  unit?: string;
  age_min?: number;
  age_max?: number;
  gender?: string;
  alert_message: string;
}

export interface ClinicalProtocol {
  id: string;
  tenant_id: string;
  name: string;
  code: string | null;
  category: string;
  description: string | null;
  trigger_conditions: unknown[];
  steps: unknown[];
  department_id: string | null;
  is_active: boolean;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface CreateClinicalProtocolRequest {
  name: string;
  code?: string;
  category: string;
  description?: string;
  trigger_conditions?: unknown[];
  steps?: unknown[];
  department_id?: string;
}

export interface RestrictedDrugApproval {
  id: string;
  tenant_id: string;
  prescription_id: string | null;
  encounter_id: string;
  patient_id: string;
  drug_name: string;
  catalog_item_id: string | null;
  reason: string;
  requested_by: string;
  approved_by: string | null;
  status: "pending" | "approved" | "denied" | "expired";
  approved_at: string | null;
  denied_reason: string | null;
  expires_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateRestrictedDrugApprovalRequest {
  encounter_id: string;
  patient_id: string;
  drug_name: string;
  catalog_item_id?: string;
  reason: string;
}

export interface PreAuthorizationRequest {
  id: string;
  tenant_id: string;
  patient_id: string;
  encounter_id: string;
  insurance_provider: string;
  policy_number: string | null;
  procedure_codes: string[];
  diagnosis_codes: string[];
  estimated_cost: number | null;
  status: "pending" | "submitted" | "approved" | "denied" | "expired";
  auth_number: string | null;
  approved_amount: number | null;
  valid_from: string | null;
  valid_until: string | null;
  notes: string | null;
  submitted_by: string;
  reviewed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreatePreAuthRequest {
  patient_id: string;
  encounter_id: string;
  insurance_provider: string;
  policy_number?: string;
  procedure_codes?: string[];
  diagnosis_codes?: string[];
  estimated_cost?: number;
  notes?: string;
}

export interface UpdatePreAuthRequest {
  status?: string;
  auth_number?: string;
  approved_amount?: number;
  valid_from?: string;
  valid_until?: string;
  notes?: string;
}

export interface PgLogbookEntry {
  id: string;
  tenant_id: string;
  user_id: string;
  encounter_id: string | null;
  entry_type: "case" | "procedure" | "ward_round" | "emergency" | "seminar" | "other";
  title: string;
  description: string | null;
  diagnosis_codes: string[];
  procedure_codes: string[];
  department_id: string | null;
  supervisor_id: string | null;
  supervisor_verified: boolean;
  verified_at: string | null;
  entry_date: string;
  created_at: string;
  updated_at: string;
}

export interface CreatePgLogbookRequest {
  encounter_id?: string;
  entry_type: string;
  title: string;
  description?: string;
  diagnosis_codes?: string[];
  procedure_codes?: string[];
  department_id?: string;
  supervisor_id?: string;
  entry_date?: string;
}

export interface CoSignatureRequest {
  id: string;
  tenant_id: string;
  encounter_id: string;
  order_type: "prescription" | "procedure" | "lab_order" | "referral" | "other";
  order_id: string;
  requested_by: string;
  approver_id: string;
  status: "pending" | "approved" | "denied";
  approved_at: string | null;
  denied_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateCoSignatureRequest {
  encounter_id: string;
  order_type: string;
  order_id: string;
  approver_id: string;
}

// ── Emergency ──────────────────────────────────────────

export type TriageLevel = "immediate" | "emergent" | "urgent" | "less_urgent" | "non_urgent" | "expectant" | "unassigned";
export type ErVisitStatus = "registered" | "triaged" | "in_treatment" | "observation" | "admitted" | "discharged" | "transferred" | "lama" | "deceased";
export type MlcStatus = "registered" | "under_investigation" | "opinion_given" | "court_pending" | "closed";
export type MassCasualtyStatus = "activated" | "ongoing" | "scaling_down" | "deactivated";

export interface ErVisit {
  id: string;
  tenant_id: string;
  patient_id: string;
  visit_number: string;
  status: ErVisitStatus;
  arrival_mode: string | null;
  arrival_time: string;
  chief_complaint: string | null;
  is_mlc: boolean;
  is_brought_dead: boolean;
  triage_level: TriageLevel | null;
  attending_doctor_id: string | null;
  bay_number: string | null;
  disposition: string | null;
  disposition_time: string | null;
  disposition_notes: string | null;
  admitted_to: string | null;
  admission_id: string | null;
  door_to_doctor_mins: number | null;
  door_to_disposition_mins: number | null;
  vitals: Record<string, unknown> | null;
  notes: string | null;
  mass_casualty_event_id: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ErTriageAssessment {
  id: string;
  tenant_id: string;
  er_visit_id: string;
  triage_level: TriageLevel;
  triage_system: string;
  score: number | null;
  respiratory_rate: number | null;
  pulse_rate: number | null;
  blood_pressure_systolic: number | null;
  blood_pressure_diastolic: number | null;
  spo2: number | null;
  gcs_score: number | null;
  gcs_eye: number | null;
  gcs_verbal: number | null;
  gcs_motor: number | null;
  pain_score: number | null;
  chief_complaint: string | null;
  presenting_symptoms: Record<string, unknown> | null;
  allergies: Record<string, unknown> | null;
  is_pregnant: boolean | null;
  disability_assessment: string | null;
  notes: string | null;
  assessed_by: string | null;
  assessed_at: string;
  created_at: string;
  updated_at: string;
}

export interface ErResuscitationLog {
  id: string;
  tenant_id: string;
  er_visit_id: string;
  log_type: string;
  timestamp: string;
  medication_name: string | null;
  dose: string | null;
  route: string | null;
  fluid_name: string | null;
  fluid_volume_ml: number | null;
  procedure_name: string | null;
  procedure_notes: string | null;
  vitals_snapshot: Record<string, unknown> | null;
  notes: string | null;
  recorded_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface ErCodeActivation {
  id: string;
  tenant_id: string;
  er_visit_id: string | null;
  code_type: string;
  activated_at: string;
  deactivated_at: string | null;
  location: string | null;
  response_team: Record<string, unknown> | null;
  crash_cart_checklist: Record<string, unknown> | null;
  outcome: string | null;
  notes: string | null;
  activated_by: string | null;
  deactivated_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface MlcCase {
  id: string;
  tenant_id: string;
  er_visit_id: string | null;
  patient_id: string;
  mlc_number: string;
  status: MlcStatus;
  case_type: string | null;
  fir_number: string | null;
  police_station: string | null;
  brought_by: string | null;
  informant_name: string | null;
  informant_relation: string | null;
  informant_contact: string | null;
  history_of_incident: string | null;
  examination_findings: string | null;
  medical_opinion: string | null;
  is_pocso: boolean;
  is_death_case: boolean;
  cause_of_death: string | null;
  registered_by: string | null;
  registered_at: string;
  created_at: string;
  updated_at: string;
}

export interface MlcDocument {
  id: string;
  tenant_id: string;
  mlc_case_id: string;
  document_type: string;
  title: string;
  body_diagram: Record<string, unknown> | null;
  content: Record<string, unknown>;
  generated_by: string | null;
  verified_by: string | null;
  verified_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface MlcPoliceIntimation {
  id: string;
  tenant_id: string;
  mlc_case_id: string;
  intimation_number: string;
  police_station: string;
  officer_name: string | null;
  officer_designation: string | null;
  officer_contact: string | null;
  sent_at: string;
  sent_via: string | null;
  receipt_confirmed: boolean;
  receipt_confirmed_at: string | null;
  receipt_number: string | null;
  notes: string | null;
  sent_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface MassCasualtyEvent {
  id: string;
  tenant_id: string;
  event_name: string;
  event_type: string | null;
  status: MassCasualtyStatus;
  activated_at: string;
  deactivated_at: string | null;
  location: string | null;
  estimated_casualties: number | null;
  actual_casualties: number | null;
  triage_summary: Record<string, unknown> | null;
  resources_deployed: Record<string, unknown> | null;
  notifications_sent: Record<string, unknown> | null;
  notes: string | null;
  activated_by: string | null;
  deactivated_by: string | null;
  created_at: string;
  updated_at: string;
}

// ── Emergency Request Types ────────────────────────────

export interface CreateErVisitRequest {
  patient_id: string;
  arrival_mode?: string;
  chief_complaint?: string;
  is_mlc?: boolean;
  is_brought_dead?: boolean;
  bay_number?: string;
  vitals?: Record<string, unknown>;
  notes?: string;
  mass_casualty_event_id?: string;
}

export interface UpdateErVisitRequest {
  status?: string;
  triage_level?: string;
  attending_doctor_id?: string;
  bay_number?: string;
  disposition?: string;
  disposition_notes?: string;
  admitted_to?: string;
  admission_id?: string;
  door_to_doctor_mins?: number;
  door_to_disposition_mins?: number;
  vitals?: Record<string, unknown>;
  notes?: string;
}

export interface CreateTriageRequest {
  triage_level: string;
  triage_system?: string;
  score?: number;
  respiratory_rate?: number;
  pulse_rate?: number;
  blood_pressure_systolic?: number;
  blood_pressure_diastolic?: number;
  spo2?: number;
  gcs_score?: number;
  gcs_eye?: number;
  gcs_verbal?: number;
  gcs_motor?: number;
  pain_score?: number;
  chief_complaint?: string;
  presenting_symptoms?: Record<string, unknown>;
  allergies?: Record<string, unknown>;
  is_pregnant?: boolean;
  disability_assessment?: string;
  notes?: string;
}

export interface CreateResuscitationLogRequest {
  log_type: string;
  medication_name?: string;
  dose?: string;
  route?: string;
  fluid_name?: string;
  fluid_volume_ml?: number;
  procedure_name?: string;
  procedure_notes?: string;
  vitals_snapshot?: Record<string, unknown>;
  notes?: string;
}

export interface CreateCodeActivationRequest {
  er_visit_id?: string;
  code_type: string;
  location?: string;
  response_team?: Record<string, unknown>;
  crash_cart_checklist?: Record<string, unknown>;
  notes?: string;
}

export interface DeactivateCodeRequest {
  outcome?: string;
  notes?: string;
}

export interface CreateMlcCaseRequest {
  er_visit_id?: string;
  patient_id: string;
  case_type?: string;
  fir_number?: string;
  police_station?: string;
  brought_by?: string;
  informant_name?: string;
  informant_relation?: string;
  informant_contact?: string;
  history_of_incident?: string;
  examination_findings?: string;
  is_pocso?: boolean;
  is_death_case?: boolean;
}

export interface UpdateMlcCaseRequest {
  status?: string;
  case_type?: string;
  fir_number?: string;
  police_station?: string;
  examination_findings?: string;
  medical_opinion?: string;
  cause_of_death?: string;
}

export interface CreateMlcDocumentRequest {
  document_type: string;
  title: string;
  body_diagram?: Record<string, unknown>;
  content: Record<string, unknown>;
  notes?: string;
}

export interface CreatePoliceIntimationRequest {
  police_station: string;
  officer_name?: string;
  officer_designation?: string;
  officer_contact?: string;
  sent_via?: string;
  notes?: string;
}

export interface CreateMassCasualtyEventRequest {
  event_name: string;
  event_type?: string;
  location?: string;
  estimated_casualties?: number;
  notes?: string;
}

export interface UpdateMassCasualtyEventRequest {
  status?: string;
  actual_casualties?: number;
  triage_summary?: Record<string, unknown>;
  resources_deployed?: Record<string, unknown>;
  notifications_sent?: Record<string, unknown>;
  notes?: string;
}

// ── Procurement Types ─────────────────────────────────────

export type PoStatus = "draft" | "submitted" | "approved" | "sent_to_vendor" | "partially_received" | "fully_received" | "closed" | "cancelled";
export type GrnStatus = "draft" | "inspecting" | "accepted" | "partially_accepted" | "rejected" | "completed";
export type VendorStatus = "active" | "inactive" | "blacklisted" | "pending_approval";
export type RateContractStatus = "draft" | "active" | "expired" | "terminated";

export interface Vendor {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  display_name: string | null;
  vendor_type: string;
  status: VendorStatus;
  contact_person: string | null;
  phone: string | null;
  email: string | null;
  website: string | null;
  address_line1: string | null;
  address_line2: string | null;
  city: string | null;
  state: string | null;
  pincode: string | null;
  country: string | null;
  gst_number: string | null;
  pan_number: string | null;
  drug_license_number: string | null;
  fssai_license: string | null;
  bank_name: string | null;
  bank_account: string | null;
  bank_ifsc: string | null;
  payment_terms: string | null;
  credit_limit: number;
  credit_days: number;
  rating: number;
  categories: unknown[];
  notes: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface StoreLocation {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  location_type: string;
  department_id: string | null;
  facility_id: string | null;
  address: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface PurchaseOrder {
  id: string;
  tenant_id: string;
  po_number: string;
  vendor_id: string;
  store_location_id: string | null;
  status: PoStatus;
  indent_requisition_id: string | null;
  rate_contract_id: string | null;
  subtotal: number;
  tax_amount: number;
  discount_amount: number;
  total_amount: number;
  order_date: string;
  expected_delivery: string | null;
  payment_terms: string | null;
  delivery_terms: string | null;
  created_by: string;
  approved_by: string | null;
  approved_at: string | null;
  sent_at: string | null;
  is_emergency: boolean;
  emergency_reason: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface PurchaseOrderItem {
  id: string;
  tenant_id: string;
  po_id: string;
  catalog_item_id: string | null;
  item_name: string;
  item_code: string | null;
  unit: string;
  quantity_ordered: number;
  quantity_received: number;
  unit_price: number;
  tax_percent: number;
  tax_amount: number;
  discount_percent: number;
  discount_amount: number;
  total_amount: number;
  indent_item_id: string | null;
  notes: string | null;
  created_at: string;
}

export interface GoodsReceiptNote {
  id: string;
  tenant_id: string;
  grn_number: string;
  po_id: string;
  vendor_id: string;
  store_location_id: string | null;
  status: GrnStatus;
  total_amount: number;
  receipt_date: string;
  invoice_number: string | null;
  invoice_date: string | null;
  invoice_amount: number | null;
  received_by: string;
  inspected_by: string | null;
  inspected_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface GrnItem {
  id: string;
  tenant_id: string;
  grn_id: string;
  po_item_id: string | null;
  catalog_item_id: string | null;
  item_name: string;
  quantity_received: number;
  quantity_accepted: number;
  quantity_rejected: number;
  batch_number: string | null;
  expiry_date: string | null;
  manufacture_date: string | null;
  unit_price: number;
  total_amount: number;
  rejection_reason: string | null;
  notes: string | null;
  created_at: string;
}

export interface BatchStock {
  id: string;
  tenant_id: string;
  catalog_item_id: string;
  store_location_id: string | null;
  batch_number: string;
  expiry_date: string | null;
  manufacture_date: string | null;
  quantity: number;
  unit_cost: number;
  grn_id: string | null;
  vendor_id: string | null;
  is_consignment: boolean;
  serial_number: string | null;
  barcode: string | null;
  created_at: string;
  updated_at: string;
}

export interface RateContract {
  id: string;
  tenant_id: string;
  contract_number: string;
  vendor_id: string;
  status: RateContractStatus;
  start_date: string;
  end_date: string;
  payment_terms: string | null;
  notes: string | null;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface RateContractItem {
  id: string;
  tenant_id: string;
  contract_id: string;
  catalog_item_id: string;
  contracted_price: number;
  max_quantity: number | null;
  notes: string | null;
  created_at: string;
}

// ── Procurement Request Types ─────────────────────────────

export interface CreateVendorRequest {
  code: string;
  name: string;
  display_name?: string;
  vendor_type?: string;
  contact_person?: string;
  phone?: string;
  email?: string;
  website?: string;
  address_line1?: string;
  address_line2?: string;
  city?: string;
  state?: string;
  pincode?: string;
  country?: string;
  gst_number?: string;
  pan_number?: string;
  drug_license_number?: string;
  fssai_license?: string;
  bank_name?: string;
  bank_account?: string;
  bank_ifsc?: string;
  payment_terms?: string;
  credit_limit?: number;
  credit_days?: number;
  categories?: unknown[];
  notes?: string;
}

export interface UpdateVendorRequest {
  name?: string;
  display_name?: string;
  vendor_type?: string;
  status?: VendorStatus;
  contact_person?: string;
  phone?: string;
  email?: string;
  website?: string;
  address_line1?: string;
  address_line2?: string;
  city?: string;
  state?: string;
  pincode?: string;
  country?: string;
  gst_number?: string;
  pan_number?: string;
  drug_license_number?: string;
  fssai_license?: string;
  bank_name?: string;
  bank_account?: string;
  bank_ifsc?: string;
  payment_terms?: string;
  credit_limit?: number;
  credit_days?: number;
  categories?: unknown[];
  notes?: string;
  is_active?: boolean;
}

export interface CreateStoreLocationRequest {
  code: string;
  name: string;
  location_type?: string;
  department_id?: string;
  facility_id?: string;
  address?: string;
}

export interface UpdateStoreLocationRequest {
  name?: string;
  location_type?: string;
  department_id?: string;
  facility_id?: string;
  address?: string;
  is_active?: boolean;
}

export interface CreatePoItemInput {
  catalog_item_id?: string;
  item_name: string;
  item_code?: string;
  unit?: string;
  quantity_ordered: number;
  unit_price: number;
  tax_percent?: number;
  discount_percent?: number;
  indent_item_id?: string;
  notes?: string;
}

export interface CreatePurchaseOrderRequest {
  vendor_id: string;
  store_location_id?: string;
  indent_requisition_id?: string;
  rate_contract_id?: string;
  expected_delivery?: string;
  payment_terms?: string;
  delivery_terms?: string;
  notes?: string;
  items: CreatePoItemInput[];
}

export interface PoDetailResponse {
  purchase_order: PurchaseOrder;
  items: PurchaseOrderItem[];
}

export interface PoListResponse {
  purchase_orders: PurchaseOrder[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateGrnItemInput {
  po_item_id?: string;
  catalog_item_id?: string;
  item_name: string;
  quantity_received: number;
  quantity_accepted: number;
  quantity_rejected?: number;
  batch_number?: string;
  expiry_date?: string;
  manufacture_date?: string;
  unit_price: number;
  rejection_reason?: string;
  notes?: string;
}

export interface CreateGrnRequest {
  po_id: string;
  store_location_id?: string;
  invoice_number?: string;
  invoice_date?: string;
  invoice_amount?: number;
  notes?: string;
  items: CreateGrnItemInput[];
}

export interface GrnDetailResponse {
  grn: GoodsReceiptNote;
  items: GrnItem[];
}

export interface GrnListResponse {
  grns: GoodsReceiptNote[];
  total: number;
  page: number;
  per_page: number;
}

export interface CreateRcItemInput {
  catalog_item_id: string;
  contracted_price: number;
  max_quantity?: number;
  notes?: string;
}

export interface CreateRateContractRequest {
  vendor_id: string;
  start_date: string;
  end_date: string;
  payment_terms?: string;
  notes?: string;
  items: CreateRcItemInput[];
}

export interface RcDetailResponse {
  contract: RateContract;
  items: RateContractItem[];
}

// ── Quality Management ──────────────────────────────────────

export type DocumentStatus = "draft" | "under_review" | "approved" | "released" | "revised" | "obsolete";
export type IncidentSeverityType = "near_miss" | "minor" | "moderate" | "major" | "sentinel";
export type IncidentStatusType = "reported" | "acknowledged" | "investigating" | "rca_complete" | "capa_assigned" | "capa_in_progress" | "closed" | "reopened";
export type CapaStatusType = "open" | "in_progress" | "completed" | "verified" | "overdue";
export type IndicatorFrequencyType = "daily" | "weekly" | "monthly" | "quarterly" | "annually";
export type AccreditationBodyType = "nabh" | "nmc" | "nabl" | "jci" | "abdm" | "naac" | "other";
export type ComplianceStatusType = "compliant" | "partially_compliant" | "non_compliant" | "not_applicable";
export type CommitteeFrequencyType = "weekly" | "biweekly" | "monthly" | "quarterly" | "biannual" | "annual" | "as_needed";

export interface QualityIndicator {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  description?: string;
  category: string;
  sub_category?: string;
  numerator_description?: string;
  denominator_description?: string;
  unit?: string;
  frequency: IndicatorFrequencyType;
  target_value?: number;
  threshold_warning?: number;
  threshold_critical?: number;
  benchmark_national?: number;
  benchmark_international?: number;
  auto_calculated: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface QualityIndicatorValue {
  id: string;
  tenant_id: string;
  indicator_id: string;
  period_start: string;
  period_end: string;
  numerator_value?: number;
  denominator_value?: number;
  calculated_value?: number;
  department_id?: string;
  notes?: string;
  recorded_by: string;
  created_at: string;
  updated_at: string;
}

export interface QualityDocument {
  id: string;
  tenant_id: string;
  document_number: string;
  title: string;
  category: string;
  department_id?: string;
  current_version: number;
  status: DocumentStatus;
  content?: string;
  summary?: string;
  author_id: string;
  reviewer_id?: string;
  approver_id?: string;
  released_at?: string;
  next_review_date?: string;
  review_cycle_months: number;
  is_training_required: boolean;
  attachments: unknown[];
  created_at: string;
  updated_at: string;
}

export interface QualityIncident {
  id: string;
  tenant_id: string;
  incident_number: string;
  title: string;
  description?: string;
  incident_type: string;
  severity: IncidentSeverityType;
  status: IncidentStatusType;
  department_id?: string;
  location?: string;
  incident_date: string;
  reported_by: string;
  is_anonymous: boolean;
  patient_id?: string;
  affected_persons: unknown[];
  immediate_action?: string;
  root_cause?: string;
  contributing_factors: unknown[];
  assigned_to?: string;
  closed_at?: string;
  is_reportable: boolean;
  regulatory_body?: string;
  attachments: unknown[];
  created_at: string;
  updated_at: string;
}

export interface QualityCapa {
  id: string;
  tenant_id: string;
  incident_id: string;
  capa_number: string;
  capa_type: string;
  description?: string;
  action_plan?: string;
  status: CapaStatusType;
  assigned_to: string;
  due_date: string;
  completed_at?: string;
  verified_by?: string;
  verified_at?: string;
  effectiveness_check?: string;
  created_at: string;
  updated_at: string;
}

export interface QualityCommittee {
  id: string;
  tenant_id: string;
  name: string;
  code: string;
  description?: string;
  committee_type: string;
  chairperson_id?: string;
  secretary_id?: string;
  members: unknown[];
  meeting_frequency: CommitteeFrequencyType;
  charter?: string;
  is_mandatory: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface QualityCommitteeMeeting {
  id: string;
  tenant_id: string;
  committee_id: string;
  meeting_number?: string;
  scheduled_date: string;
  actual_date?: string;
  venue?: string;
  agenda: unknown[];
  minutes?: string;
  attendees: unknown[];
  absentees: unknown[];
  decisions: unknown[];
  status: string;
  created_at: string;
  updated_at: string;
}

export interface QualityActionItem {
  id: string;
  tenant_id: string;
  source_type: string;
  source_id: string;
  description?: string;
  assigned_to: string;
  due_date: string;
  status: string;
  completed_at?: string;
  remarks?: string;
  created_at: string;
  updated_at: string;
}

export interface QualityAccreditationStandard {
  id: string;
  tenant_id: string;
  body: AccreditationBodyType;
  standard_code: string;
  standard_name: string;
  chapter?: string;
  description?: string;
  measurable_elements: unknown[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface QualityAccreditationCompliance {
  id: string;
  tenant_id: string;
  standard_id: string;
  compliance: ComplianceStatusType;
  evidence_summary?: string;
  evidence_documents: unknown[];
  gap_description?: string;
  action_plan?: string;
  responsible_person_id?: string;
  target_date?: string;
  assessed_at?: string;
  assessed_by?: string;
  created_at: string;
  updated_at: string;
}

export interface QualityAudit {
  id: string;
  tenant_id: string;
  audit_number: string;
  audit_type: string;
  title: string;
  scope?: string;
  department_id?: string;
  auditor_id: string;
  audit_date: string;
  report_date?: string;
  findings: unknown[];
  non_conformities: number;
  observations: number;
  opportunities: number;
  overall_score?: number;
  status: string;
  created_at: string;
  updated_at: string;
}

// Request types
export interface CreateQualityIndicatorRequest {
  code: string;
  name: string;
  description?: string;
  category: string;
  sub_category?: string;
  numerator_description?: string;
  denominator_description?: string;
  unit?: string;
  frequency: IndicatorFrequencyType;
  target_value?: number;
  threshold_warning?: number;
  threshold_critical?: number;
  auto_calculated?: boolean;
}

export interface RecordIndicatorValueRequest {
  indicator_id: string;
  period_start: string;
  period_end: string;
  numerator_value?: number;
  denominator_value?: number;
  calculated_value?: number;
  department_id?: string;
  notes?: string;
}

export interface CreateQualityDocumentRequest {
  document_number: string;
  title: string;
  category: string;
  department_id?: string;
  content?: string;
  summary?: string;
  reviewer_id?: string;
  is_training_required?: boolean;
}

export interface CreateQualityIncidentRequest {
  title: string;
  description?: string;
  incident_type: string;
  severity: IncidentSeverityType;
  department_id?: string;
  location?: string;
  incident_date: string;
  is_anonymous?: boolean;
  patient_id?: string;
  immediate_action?: string;
}

export interface UpdateQualityIncidentRequest {
  status?: IncidentStatusType;
  assigned_to?: string;
  root_cause?: string;
  contributing_factors?: unknown[];
  is_reportable?: boolean;
  regulatory_body?: string;
}

export interface CreateCapaRequest {
  incident_id: string;
  capa_type: string;
  description?: string;
  action_plan?: string;
  assigned_to: string;
  due_date: string;
}

export interface CreateQualityCommitteeRequest {
  name: string;
  code: string;
  description?: string;
  committee_type: string;
  chairperson_id?: string;
  secretary_id?: string;
  members?: unknown[];
  meeting_frequency: CommitteeFrequencyType;
  charter?: string;
  is_mandatory?: boolean;
}

export interface CreateMeetingRequest {
  committee_id: string;
  scheduled_date: string;
  venue?: string;
  agenda?: unknown[];
}

export interface CreateAccreditationStandardRequest {
  body: AccreditationBodyType;
  standard_code: string;
  standard_name: string;
  chapter?: string;
  description?: string;
  measurable_elements?: unknown[];
}

export interface UpdateComplianceRequest {
  standard_id: string;
  compliance: ComplianceStatusType;
  evidence_summary?: string;
  evidence_documents?: unknown[];
  gap_description?: string;
  action_plan?: string;
  responsible_person_id?: string;
  target_date?: string;
}

export interface CreateQualityAuditRequest {
  audit_type: string;
  title: string;
  scope?: string;
  department_id?: string;
  audit_date: string;
}


// ── Infection Control ─────────────────────────────────────
export type HaiType = "clabsi" | "cauti" | "vap" | "ssi" | "cdiff" | "mrsa" | "other";
export type InfectionStatusType = "suspected" | "confirmed" | "ruled_out";
export type AntibioticRequestStatusType = "pending" | "approved" | "denied" | "expired";
export type WasteCategoryType = "yellow" | "red" | "white_translucent" | "blue" | "cytotoxic" | "chemical" | "radioactive";
export type OutbreakStatusType = "suspected" | "confirmed" | "contained" | "closed";

export interface InfectionSurveillanceEvent {
  id: string; tenant_id: string; patient_id: string; admission_id?: string;
  hai_type: HaiType; infection_status: InfectionStatusType;
  organism?: string; susceptibility_pattern?: unknown; device_type?: string;
  insertion_date?: string; infection_date: string;
  location_id?: string; department_id?: string;
  nhsn_criteria?: string; contributing_factors?: unknown; notes?: string;
  reported_by: string; confirmed_by?: string; confirmed_at?: string;
  created_at: string; updated_at: string;
}

export interface InfectionDeviceDay {
  id: string; tenant_id: string; location_id: string; department_id?: string;
  record_date: string; patient_days: number;
  central_line_days: number; urinary_catheter_days: number; ventilator_days: number;
  recorded_by: string; created_at: string; updated_at: string;
}

export interface AntibioticStewardshipRequest {
  id: string; tenant_id: string; patient_id: string;
  antibiotic_name: string; dose?: string; route?: string; frequency?: string; duration_days?: number;
  indication: string; culture_sent: boolean; culture_result?: string;
  request_status: AntibioticRequestStatusType;
  requested_by: string; requested_at: string;
  reviewed_by?: string; reviewed_at?: string; review_notes?: string;
  escalation_reason?: string; auto_stop_date?: string;
  created_at: string; updated_at: string;
}

export interface AntibioticConsumptionRecord {
  id: string; tenant_id: string; department_id?: string;
  antibiotic_name: string; atc_code?: string; record_month: string;
  quantity_used: number; ddd?: number; patient_days: number;
  ddd_per_1000_patient_days?: number;
  created_at: string; updated_at: string;
}

export interface BiowasteRecord {
  id: string; tenant_id: string; department_id: string;
  waste_category: WasteCategoryType; weight_kg: number;
  record_date: string; container_count: number;
  disposal_vendor?: string; manifest_number?: string; notes?: string;
  recorded_by: string; created_at: string; updated_at: string;
}

export interface NeedleStickIncident {
  id: string; tenant_id: string; incident_number: string;
  staff_id: string; incident_date: string;
  location_id?: string; department_id?: string;
  device_type: string; procedure_during?: string; body_part?: string; depth?: string;
  source_patient_id?: string;
  hiv_status?: string; hbv_status?: string; hcv_status?: string;
  pep_initiated: boolean; pep_details?: string;
  follow_up_schedule?: unknown; outcome?: string;
  reported_by: string; created_at: string; updated_at: string;
}

export interface HandHygieneAudit {
  id: string; tenant_id: string;
  audit_date: string; location_id?: string; department_id: string;
  auditor_id: string; observations: number; compliant: number; non_compliant: number;
  compliance_rate?: number; moment_breakdown?: unknown;
  staff_category?: string; findings?: string;
  created_at: string; updated_at: string;
}

export interface CultureSurveillance {
  id: string; tenant_id: string;
  culture_type: string; sample_site: string;
  location_id?: string; department_id?: string;
  collection_date: string; result?: string; organism?: string;
  colony_count?: number; acceptable?: boolean; action_taken?: string;
  collected_by: string; created_at: string; updated_at: string;
}

export interface OutbreakEvent {
  id: string; tenant_id: string; outbreak_number: string;
  organism: string; outbreak_status: OutbreakStatusType;
  detected_date: string; location_id?: string; department_id?: string;
  initial_cases: number; total_cases: number;
  description?: string; control_measures?: unknown;
  hicc_notified: boolean; hicc_notified_at?: string;
  containment_date?: string; closure_date?: string;
  root_cause?: string; lessons_learned?: string;
  reported_by: string; created_at: string; updated_at: string;
}

export interface OutbreakContact {
  id: string; tenant_id: string; outbreak_id: string;
  patient_id?: string; staff_id?: string;
  contact_type: string; exposure_date?: string;
  screening_date?: string; screening_result?: string;
  quarantine_required: boolean; quarantine_start?: string; quarantine_end?: string;
  notes?: string; created_at: string; updated_at: string;
}

// Request types
export interface CreateSurveillanceEventRequest { patient_id: string; hai_type: HaiType; organism?: string; device_type?: string; insertion_date?: string; infection_date: string; location_id?: string; department_id?: string; nhsn_criteria?: string; notes?: string; }
export interface RecordDeviceDaysRequest { location_id: string; department_id?: string; record_date: string; patient_days: number; central_line_days: number; urinary_catheter_days: number; ventilator_days: number; }
export interface CreateStewardshipRequest { patient_id: string; antibiotic_name: string; dose?: string; route?: string; frequency?: string; duration_days?: number; indication: string; culture_sent: boolean; escalation_reason?: string; }
export interface ReviewStewardshipRequest { request_status: AntibioticRequestStatusType; review_notes?: string; }
export interface CreateBiowasteRecordRequest { department_id: string; waste_category: WasteCategoryType; weight_kg: number; record_date: string; container_count: number; disposal_vendor?: string; manifest_number?: string; notes?: string; }
export interface CreateNeedleStickIncidentRequest { staff_id: string; incident_date: string; location_id?: string; department_id?: string; device_type: string; procedure_during?: string; body_part?: string; depth?: string; source_patient_id?: string; pep_initiated: boolean; pep_details?: string; }
export interface CreateHygieneAuditRequest { audit_date: string; department_id: string; observations: number; compliant: number; non_compliant: number; moment_breakdown?: unknown; staff_category?: string; findings?: string; }
export interface CreateCultureSurveillanceRequest { culture_type: string; sample_site: string; location_id?: string; department_id?: string; collection_date: string; result?: string; organism?: string; colony_count?: number; acceptable?: boolean; action_taken?: string; }
export interface CreateOutbreakRequest { organism: string; detected_date: string; location_id?: string; department_id?: string; initial_cases: number; description?: string; }
export interface UpdateOutbreakRequest { outbreak_status?: OutbreakStatusType; total_cases?: number; control_measures?: unknown; hicc_notified?: boolean; root_cause?: string; lessons_learned?: string; }
export interface CreateOutbreakContactRequest { patient_id?: string; staff_id?: string; contact_type: string; exposure_date?: string; quarantine_required: boolean; notes?: string; }

// ── Housekeeping ──────────────────────────────────────────

export type CleaningAreaType = "icu" | "ward" | "ot" | "er" | "lab" | "pharmacy" | "corridor" | "lobby" | "washroom" | "kitchen" | "general";
export type CleaningTaskStatusType = "pending" | "assigned" | "in_progress" | "completed" | "verified" | "rejected";
export type LinenStatusType = "clean" | "in_use" | "soiled" | "washing" | "condemned";
export type LinenContaminationTypeValue = "regular" | "contaminated" | "isolation";

export interface CleaningSchedule {
  id: string; tenant_id: string; area_type: CleaningAreaType;
  location_id?: string; department_id?: string; frequency_hours: number;
  checklist_items: unknown; is_active: boolean; notes?: string;
  created_at: string; updated_at: string;
}

export interface CleaningTask {
  id: string; tenant_id: string; schedule_id?: string;
  location_id?: string; department_id?: string; area_type: CleaningAreaType;
  task_date: string; assigned_to?: string; status: CleaningTaskStatusType;
  started_at?: string; completed_at?: string; verified_by?: string;
  verified_at?: string; checklist_results: unknown; notes?: string;
  created_at: string; updated_at: string;
}

export interface RoomTurnaround {
  id: string; tenant_id: string; location_id?: string; patient_id?: string;
  discharge_at?: string; dirty_at?: string; cleaning_started_at?: string;
  cleaning_completed_at?: string; ready_at?: string; turnaround_minutes?: number;
  cleaned_by?: string; verified_by?: string;
  created_at: string; updated_at: string;
}

export interface PestControlSchedule {
  id: string; tenant_id: string; location_id?: string; department_id?: string;
  pest_type: string; frequency_months: number; last_done?: string;
  next_due?: string; vendor_name?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface PestControlLog {
  id: string; tenant_id: string; schedule_id?: string;
  treatment_date: string; treatment_type: string; chemicals_used?: string;
  areas_treated: unknown; vendor_name?: string; certificate_no?: string;
  next_due?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface LinenItem {
  id: string; tenant_id: string; barcode?: string; item_type: string;
  current_status: LinenStatusType; ward_id?: string; wash_count: number;
  max_washes: number; commissioned_date?: string; condemned_date?: string;
  notes?: string; created_at: string; updated_at: string;
}

export interface LinenMovement {
  id: string; tenant_id: string; linen_item_id?: string; movement_type: string;
  from_ward?: string; to_ward?: string; quantity: number; weight_kg?: number;
  contamination_type: LinenContaminationTypeValue; batch_id?: string;
  recorded_by?: string; movement_date: string;
  created_at: string; updated_at: string;
}

export interface LaundryBatch {
  id: string; tenant_id: string; batch_number: string; items_count: number;
  total_weight?: number; contamination_type: LinenContaminationTypeValue;
  wash_formula?: string; wash_temperature?: number; cycle_minutes?: number;
  started_at?: string; completed_at?: string; status: string;
  operator_name?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface LinenParLevel {
  id: string; tenant_id: string; ward_id?: string; item_type: string;
  par_level: number; current_stock: number; reorder_level: number;
  created_at: string; updated_at: string;
}

export interface LinenCondemnation {
  id: string; tenant_id: string; linen_item_id?: string; reason: string;
  wash_count_at_condemn?: number; condemned_by?: string; condemned_date: string;
  replacement_requested: boolean; created_at: string; updated_at: string;
}

// Request types
export interface CreateCleaningScheduleRequest { area_type: string; location_id?: string; department_id?: string; frequency_hours?: number; checklist_items?: unknown; is_active?: boolean; notes?: string; }
export interface UpdateCleaningScheduleRequest { area_type?: string; location_id?: string; department_id?: string; frequency_hours?: number; checklist_items?: unknown; is_active?: boolean; notes?: string; }
export interface CreateCleaningTaskRequest { schedule_id?: string; location_id?: string; department_id?: string; area_type: string; task_date?: string; assigned_to?: string; notes?: string; }
export interface UpdateTaskStatusRequest { status: string; }
export interface CreateTurnaroundRequest { location_id?: string; patient_id?: string; discharge_at?: string; dirty_at?: string; cleaned_by?: string; }
export interface CreatePestControlScheduleRequest { location_id?: string; department_id?: string; pest_type: string; frequency_months?: number; last_done?: string; next_due?: string; vendor_name?: string; notes?: string; }
export interface UpdatePestControlScheduleRequest { pest_type?: string; frequency_months?: number; last_done?: string; next_due?: string; vendor_name?: string; notes?: string; }
export interface CreatePestControlLogRequest { schedule_id?: string; treatment_date: string; treatment_type: string; chemicals_used?: string; areas_treated?: unknown; vendor_name?: string; certificate_no?: string; next_due?: string; notes?: string; }
export interface CreateLinenItemRequest { barcode?: string; item_type: string; current_status?: string; ward_id?: string; max_washes?: number; commissioned_date?: string; notes?: string; }
export interface UpdateLinenItemRequest { current_status?: string; ward_id?: string; notes?: string; }
export interface CreateLinenMovementRequest { linen_item_id?: string; movement_type: string; from_ward?: string; to_ward?: string; quantity?: number; weight_kg?: number; contamination_type?: string; batch_id?: string; recorded_by?: string; }
export interface CreateLaundryBatchRequest { batch_number: string; items_count?: number; total_weight?: number; contamination_type?: string; wash_formula?: string; wash_temperature?: number; cycle_minutes?: number; operator_name?: string; notes?: string; }
export interface UpsertParLevelRequest { ward_id?: string; item_type: string; par_level: number; current_stock?: number; reorder_level?: number; }
export interface CreateLinenCondemnationRequest { linen_item_id?: string; reason: string; wash_count_at_condemn?: number; replacement_requested?: boolean; }

// ── HR & Staff Management ─────────────────────────────────

// Enum types
export type EmploymentType = "permanent" | "contract" | "visiting" | "intern" | "resident" | "fellow" | "volunteer" | "outsourced";
export type EmployeeStatusType = "active" | "on_leave" | "suspended" | "resigned" | "terminated" | "retired" | "absconding";
export type CredentialType = "medical_council" | "nursing_council" | "pharmacy_council" | "dental_council" | "other_council" | "bls" | "acls" | "pals" | "nals" | "fire_safety" | "radiation_safety" | "nabh_orientation";
export type CredentialStatusType = "active" | "expired" | "suspended" | "revoked" | "pending_renewal";
export type LeaveType = "casual" | "earned" | "medical" | "maternity" | "paternity" | "compensatory" | "study" | "special" | "loss_of_pay";
export type LeaveStatusType = "draft" | "pending_hod" | "pending_admin" | "approved" | "rejected" | "cancelled";
export type ShiftType = "morning" | "afternoon" | "evening" | "night" | "general" | "split" | "on_call" | "custom";
export type TrainingStatusType = "scheduled" | "in_progress" | "completed" | "cancelled" | "failed";

// Entity interfaces
export interface Designation {
  id: string; tenant_id: string; code: string; name: string;
  level: number; category: string; is_active: boolean;
  created_at: string; updated_at: string;
}

export interface Employee {
  id: string; tenant_id: string; user_id?: string;
  employee_code: string; first_name: string; last_name?: string;
  date_of_birth?: string; gender?: string; phone?: string; email?: string;
  employment_type: EmploymentType; status: EmployeeStatusType;
  department_id?: string; designation_id?: string; reporting_to?: string;
  date_of_joining: string; date_of_leaving?: string;
  qualifications: unknown; blood_group?: string;
  address: unknown; emergency_contact: unknown;
  bank_name?: string; bank_account?: string; bank_ifsc?: string;
  pf_number?: string; esi_number?: string; uan_number?: string;
  pan_number?: string; aadhaar_number?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface EmployeeCredential {
  id: string; tenant_id: string; employee_id: string;
  credential_type: CredentialType; issuing_body: string;
  registration_no: string; state_code?: string;
  issued_date?: string; expiry_date?: string;
  status: CredentialStatusType;
  verified_by?: string; verified_at?: string;
  document_url?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface ShiftDefinition {
  id: string; tenant_id: string; code: string; name: string;
  shift_type: ShiftType; start_time: string; end_time: string;
  break_minutes: number; is_night: boolean; is_active: boolean;
  created_at: string; updated_at: string;
}

export interface DutyRoster {
  id: string; tenant_id: string; employee_id: string;
  department_id?: string; shift_id: string;
  roster_date: string; is_on_call: boolean;
  swap_with?: string; swap_approved: boolean;
  notes?: string; created_by: string;
  created_at: string; updated_at: string;
}

export interface AttendanceRecord {
  id: string; tenant_id: string; employee_id: string;
  attendance_date: string; shift_id?: string;
  check_in?: string; check_out?: string;
  is_late: boolean; late_minutes: number;
  is_early_out: boolean; early_minutes: number;
  overtime_minutes: number; status: string; source: string;
  notes?: string; recorded_by: string;
  created_at: string; updated_at: string;
}

export interface LeaveBalance {
  id: string; tenant_id: string; employee_id: string;
  leave_type: LeaveType; year: number;
  opening: number; earned: number; used: number;
  balance: number; carry_forward: number;
  created_at: string; updated_at: string;
}

export interface LeaveRequest {
  id: string; tenant_id: string; employee_id: string;
  leave_type: LeaveType; start_date: string; end_date: string;
  days: number; is_half_day: boolean; reason?: string;
  status: LeaveStatusType;
  hod_id?: string; hod_action_at?: string; hod_remarks?: string;
  admin_id?: string; admin_action_at?: string; admin_remarks?: string;
  cancelled_by?: string; cancelled_at?: string; cancel_reason?: string;
  created_at: string; updated_at: string;
}

export interface OnCallSchedule {
  id: string; tenant_id: string; employee_id: string;
  department_id?: string; schedule_date: string;
  start_time: string; end_time: string;
  is_primary: boolean; contact_number?: string;
  notes?: string; created_by: string;
  created_at: string; updated_at: string;
}

export interface TrainingProgram {
  id: string; tenant_id: string; code: string; name: string;
  description?: string; is_mandatory: boolean;
  frequency_months?: number; duration_hours?: number;
  target_roles: unknown; is_active: boolean;
  created_at: string; updated_at: string;
}

export interface TrainingRecord {
  id: string; tenant_id: string; employee_id: string;
  program_id: string; training_date: string;
  status: TrainingStatusType; score?: number;
  certificate_no?: string; expiry_date?: string;
  trainer_name?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface Appraisal {
  id: string; tenant_id: string; employee_id: string;
  appraisal_year: number; appraiser_id?: string;
  rating?: number; strengths?: string; improvements?: string;
  goals: unknown; notes?: string;
  created_at: string; updated_at: string;
}

export interface StatutoryRecord {
  id: string; tenant_id: string; employee_id: string;
  record_type: string; title: string;
  compliance_date?: string; expiry_date?: string;
  details: unknown; notes?: string;
  created_at: string; updated_at: string;
}

// Request types
export interface CreateDesignationRequest { code: string; name: string; level?: number; category?: string; }
export interface UpdateDesignationRequest { name?: string; level?: number; category?: string; is_active?: boolean; }
export interface CreateEmployeeRequest { employee_code: string; first_name: string; last_name?: string; date_of_birth?: string; gender?: string; phone?: string; email?: string; employment_type?: string; department_id?: string; designation_id?: string; reporting_to?: string; date_of_joining?: string; qualifications?: unknown; blood_group?: string; address?: unknown; emergency_contact?: unknown; bank_name?: string; bank_account?: string; bank_ifsc?: string; pf_number?: string; esi_number?: string; uan_number?: string; pan_number?: string; aadhaar_number?: string; user_id?: string; notes?: string; }
export interface UpdateEmployeeRequest { first_name?: string; last_name?: string; date_of_birth?: string; gender?: string; phone?: string; email?: string; employment_type?: string; status?: string; department_id?: string; designation_id?: string; reporting_to?: string; date_of_leaving?: string; qualifications?: unknown; blood_group?: string; address?: unknown; emergency_contact?: unknown; bank_name?: string; bank_account?: string; bank_ifsc?: string; pf_number?: string; esi_number?: string; uan_number?: string; pan_number?: string; aadhaar_number?: string; user_id?: string; notes?: string; }
export interface CreateCredentialRequest { credential_type: string; issuing_body: string; registration_no: string; state_code?: string; issued_date?: string; expiry_date?: string; document_url?: string; notes?: string; }
export interface UpdateCredentialRequest { status?: string; expiry_date?: string; verified_by?: string; document_url?: string; notes?: string; }
export interface CreateShiftRequest { code: string; name: string; shift_type?: string; start_time: string; end_time: string; break_minutes?: number; is_night?: boolean; }
export interface UpdateShiftRequest { name?: string; shift_type?: string; start_time?: string; end_time?: string; break_minutes?: number; is_night?: boolean; is_active?: boolean; }
export interface CreateRosterRequest { employee_id: string; department_id?: string; shift_id: string; roster_date: string; is_on_call?: boolean; notes?: string; }
export interface CreateAttendanceRequest { employee_id: string; attendance_date: string; shift_id?: string; check_in?: string; check_out?: string; status?: string; source?: string; notes?: string; }
export interface CreateLeaveRequestInput { employee_id: string; leave_type: string; start_date: string; end_date: string; days?: number; is_half_day?: boolean; reason?: string; }
export interface LeaveActionRequest { action: string; remarks?: string; }
export interface CreateOnCallRequest { employee_id: string; department_id?: string; schedule_date: string; start_time: string; end_time: string; is_primary?: boolean; contact_number?: string; notes?: string; }
export interface CreateTrainingProgramRequest { code: string; name: string; description?: string; is_mandatory?: boolean; frequency_months?: number; duration_hours?: number; target_roles?: unknown; }
export interface CreateTrainingRecordRequest { employee_id: string; program_id: string; training_date: string; status?: string; score?: number; certificate_no?: string; expiry_date?: string; trainer_name?: string; notes?: string; }
export interface CreateAppraisalRequest { employee_id: string; appraisal_year: number; rating?: number; strengths?: string; improvements?: string; goals?: unknown; notes?: string; }
export interface CreateStatutoryRecordRequest { employee_id: string; record_type: string; title: string; compliance_date?: string; expiry_date?: string; details?: unknown; notes?: string; }

// ══════════════════════════════════════════════════════════
//  Front Office & Reception
// ══════════════════════════════════════════════════════════

export type VisitorPassStatus = "active" | "expired" | "revoked";
export type FrontOfficeVisitorCategory = "general" | "legal_counsel" | "religious" | "vip" | "media" | "vendor" | "emergency";
export type FrontOfficeQueuePriority = "normal" | "elderly" | "disabled" | "pregnant" | "emergency_referral" | "vip";

export interface VisitingHours {
  id: string; tenant_id: string;
  ward_id?: string; day_of_week: number;
  start_time: string; end_time: string;
  max_visitors_per_patient: number; is_active: boolean;
  created_at: string; updated_at: string;
}

export interface VisitorRegistration {
  id: string; tenant_id: string;
  visitor_name: string; phone?: string;
  id_type?: string; id_number?: string;
  photo_url?: string; relationship?: string;
  category: FrontOfficeVisitorCategory;
  patient_id?: string; ward_id?: string;
  purpose?: string; created_by?: string;
  created_at: string; updated_at: string;
}

export interface VisitorPass {
  id: string; tenant_id: string;
  registration_id: string; pass_number: string;
  ward_id?: string; bed_number?: string;
  valid_from: string; valid_until: string;
  status: VisitorPassStatus; qr_code?: string;
  issued_by?: string; revoked_at?: string;
  revoked_reason?: string;
  created_at: string; updated_at: string;
}

export interface VisitorLog {
  id: string; tenant_id: string;
  pass_id: string; check_in_at: string;
  check_out_at?: string; logged_by?: string;
  gate?: string;
  created_at: string; updated_at: string;
}

export interface QueuePriorityRule {
  id: string; tenant_id: string;
  department_id?: string; priority: FrontOfficeQueuePriority;
  weight: number; auto_detect_criteria: unknown;
  is_active: boolean;
  created_at: string; updated_at: string;
}

export interface QueueDisplayConfig {
  id: string; tenant_id: string;
  department_id?: string; location_name: string;
  display_type: string; doctors_per_screen: number;
  show_patient_name: boolean; show_wait_time: boolean;
  language: unknown; announcement_enabled: boolean;
  scroll_speed: number;
  created_at: string; updated_at: string;
}

export interface FrontOfficeEnquiryLog {
  id: string; tenant_id: string;
  caller_name?: string; caller_phone?: string;
  enquiry_type: string; patient_id?: string;
  response_text?: string; handled_by?: string;
  resolved: boolean;
  created_at: string; updated_at: string;
}

export interface QueueStatsResponse {
  department_id?: string;
  waiting_count: number;
  avg_wait_minutes?: number;
}

// Request types
export interface UpsertVisitingHoursRequest { ward_id?: string; day_of_week: number; start_time: string; end_time: string; max_visitors_per_patient?: number; is_active?: boolean; }
export interface CreateVisitorRequest { visitor_name: string; phone?: string; id_type?: string; id_number?: string; photo_url?: string; relationship?: string; category?: string; patient_id?: string; ward_id?: string; purpose?: string; }
export interface CreateVisitorPassRequest { registration_id: string; ward_id?: string; bed_number?: string; valid_hours?: number; }
export interface RevokePassRequest { reason?: string; }
export interface UpsertQueuePriorityRequest { department_id?: string; priority: string; weight?: number; auto_detect_criteria?: unknown; is_active?: boolean; }
export interface UpsertDisplayConfigRequest { department_id?: string; location_name: string; display_type?: string; doctors_per_screen?: number; show_patient_name?: boolean; show_wait_time?: boolean; language?: unknown; announcement_enabled?: boolean; scroll_speed?: number; }
export interface CreateEnquiryRequest { caller_name?: string; caller_phone?: string; enquiry_type?: string; patient_id?: string; response_text?: string; }

// ═══════════════════════════════════════════════════════════
//  BME / CMMS — Biomedical Equipment Management
// ═══════════════════════════════════════════════════════════

export type BmeEquipmentStatus = "active" | "under_maintenance" | "out_of_service" | "condemned" | "disposed";
export type BmeRiskCategory = "critical" | "high" | "medium" | "low";
export type BmeWorkOrderStatus = "open" | "assigned" | "in_progress" | "completed" | "cancelled";
export type BmeWorkOrderType = "preventive" | "corrective" | "calibration" | "installation" | "inspection";
export type BmePmFrequency = "monthly" | "quarterly" | "semi_annual" | "annual";
export type BmeCalibrationStatus = "calibrated" | "due" | "overdue" | "out_of_tolerance" | "exempted";
export type BmeContractType = "amc" | "cmc" | "warranty" | "camc";
export type BmeBreakdownPriority = "critical" | "high" | "medium" | "low";
export type BmeBreakdownStatus = "reported" | "acknowledged" | "in_progress" | "parts_awaited" | "resolved" | "closed";

export interface BmeEquipment {
  id: string; tenant_id: string;
  name: string; make?: string; model?: string;
  serial_number?: string; asset_tag?: string; barcode_value?: string;
  category?: string; sub_category?: string;
  risk_category: BmeRiskCategory; is_critical: boolean;
  department_id?: string; location_description?: string; facility_id?: string;
  status: BmeEquipmentStatus;
  purchase_date?: string; purchase_cost?: number;
  installation_date?: string; commissioned_date?: string;
  installed_by?: string; commissioning_notes?: string;
  expected_life_years?: number;
  condemned_date?: string; disposal_date?: string; disposal_method?: string;
  warranty_start_date?: string; warranty_end_date?: string; warranty_terms?: string;
  vendor_id?: string; manufacturer_contact?: string;
  specifications: Record<string, unknown>;
  notes?: string; created_by?: string;
  created_at: string; updated_at: string;
}

export interface BmePmSchedule {
  id: string; tenant_id: string;
  equipment_id: string; frequency: BmePmFrequency;
  checklist: unknown[];
  next_due_date?: string; last_completed_date?: string;
  assigned_to?: string; is_active: boolean;
  notes?: string;
  created_at: string; updated_at: string;
}

export interface BmeWorkOrder {
  id: string; tenant_id: string;
  work_order_number: string; equipment_id: string;
  order_type: BmeWorkOrderType; status: BmeWorkOrderStatus;
  priority: BmeBreakdownPriority;
  assigned_to?: string; assigned_at?: string;
  scheduled_date?: string; started_at?: string; completed_at?: string;
  description?: string; findings?: string; actions_taken?: string;
  checklist_results: unknown[];
  labor_cost?: number; parts_cost?: number; vendor_cost?: number; total_cost?: number;
  technician_sign_off_by?: string; technician_sign_off_at?: string;
  supervisor_sign_off_by?: string; supervisor_sign_off_at?: string;
  pm_schedule_id?: string; breakdown_id?: string;
  notes?: string; created_by?: string;
  created_at: string; updated_at: string;
}

export interface BmeCalibration {
  id: string; tenant_id: string;
  equipment_id: string; calibration_status: BmeCalibrationStatus;
  frequency: BmePmFrequency;
  last_calibrated_date?: string; next_due_date?: string;
  calibrated_by?: string; calibration_vendor_id?: string;
  certificate_number?: string; certificate_url?: string;
  is_in_tolerance?: boolean; deviation_notes?: string;
  reference_standard?: string;
  is_locked: boolean; locked_at?: string; locked_reason?: string;
  notes?: string; created_by?: string;
  created_at: string; updated_at: string;
}

export interface BmeContract {
  id: string; tenant_id: string;
  contract_number: string; equipment_id: string;
  contract_type: BmeContractType; vendor_id: string;
  start_date: string; end_date: string;
  contract_value?: number; payment_terms?: string;
  coverage_details?: string; exclusions?: string;
  sla_response_hours?: number; sla_resolution_hours?: number;
  renewal_alert_days: number;
  is_renewed: boolean; renewed_contract_id?: string;
  is_active: boolean; notes?: string; created_by?: string;
  created_at: string; updated_at: string;
}

export interface BmeBreakdown {
  id: string; tenant_id: string;
  equipment_id: string; reported_by?: string;
  reported_at: string; department_id?: string;
  priority: BmeBreakdownPriority; status: BmeBreakdownStatus;
  description: string;
  acknowledged_at?: string; acknowledged_by?: string;
  resolution_started_at?: string;
  resolved_at?: string; resolved_by?: string;
  resolution_notes?: string;
  downtime_start?: string; downtime_end?: string; downtime_minutes?: number;
  spare_parts_used?: string; spare_parts_cost?: number;
  vendor_visit_required: boolean; vendor_visit_date?: string;
  vendor_cost?: number; total_repair_cost?: number;
  vendor_id?: string; vendor_response_at?: string;
  notes?: string;
  created_at: string; updated_at: string;
}

export interface BmeVendorEvaluation {
  id: string; tenant_id: string;
  vendor_id: string; contract_id?: string;
  evaluation_date: string; period_from?: string; period_to?: string;
  response_time_score?: number; resolution_quality_score?: number;
  spare_parts_availability_score?: number; professionalism_score?: number;
  overall_score?: number;
  total_calls?: number; calls_within_sla?: number;
  comments?: string; evaluated_by?: string;
  created_at: string; updated_at: string;
}

export interface BmeStatsResponse {
  total_equipment: number; active_equipment: number;
  pm_overdue: number; calibration_overdue: number;
  open_breakdowns: number; expiring_contracts: number;
}

// Request types
export interface CreateBmeEquipmentRequest {
  name: string; make?: string; model?: string; serial_number?: string;
  asset_tag?: string; barcode_value?: string; category?: string; sub_category?: string;
  risk_category?: BmeRiskCategory; is_critical?: boolean;
  department_id?: string; location_description?: string; facility_id?: string;
  status?: BmeEquipmentStatus;
  purchase_date?: string; purchase_cost?: number;
  installation_date?: string; commissioned_date?: string;
  installed_by?: string; commissioning_notes?: string; expected_life_years?: number;
  warranty_start_date?: string; warranty_end_date?: string; warranty_terms?: string;
  vendor_id?: string; manufacturer_contact?: string;
  specifications?: Record<string, unknown>; notes?: string;
}

export interface UpdateBmeEquipmentRequest extends Partial<CreateBmeEquipmentRequest> {
  condemned_date?: string; disposal_date?: string; disposal_method?: string;
}

export interface CreateBmePmScheduleRequest {
  equipment_id: string; frequency: BmePmFrequency;
  checklist?: unknown[]; next_due_date?: string;
  assigned_to?: string; notes?: string;
}
export interface UpdateBmePmScheduleRequest {
  frequency?: BmePmFrequency; checklist?: unknown[];
  next_due_date?: string; assigned_to?: string;
  is_active?: boolean; notes?: string;
}

export interface CreateBmeWorkOrderRequest {
  equipment_id: string; order_type: BmeWorkOrderType;
  priority?: BmeBreakdownPriority; assigned_to?: string;
  scheduled_date?: string; description?: string;
  pm_schedule_id?: string; breakdown_id?: string; notes?: string;
}
export interface UpdateBmeWorkOrderStatusRequest {
  status: BmeWorkOrderStatus; findings?: string; actions_taken?: string;
  checklist_results?: unknown[];
  labor_cost?: number; parts_cost?: number; vendor_cost?: number; total_cost?: number;
}

export interface CreateBmeCalibrationRequest {
  equipment_id: string; calibration_status?: BmeCalibrationStatus;
  frequency?: BmePmFrequency;
  last_calibrated_date?: string; next_due_date?: string;
  calibrated_by?: string; calibration_vendor_id?: string;
  certificate_number?: string; certificate_url?: string;
  is_in_tolerance?: boolean; deviation_notes?: string;
  reference_standard?: string; notes?: string;
}
export interface UpdateBmeCalibrationRequest extends Partial<CreateBmeCalibrationRequest> {
  is_locked?: boolean; locked_reason?: string;
}

export interface CreateBmeContractRequest {
  contract_number: string; equipment_id: string;
  contract_type: BmeContractType; vendor_id: string;
  start_date: string; end_date: string;
  contract_value?: number; payment_terms?: string;
  coverage_details?: string; exclusions?: string;
  sla_response_hours?: number; sla_resolution_hours?: number;
  renewal_alert_days?: number; notes?: string;
}
export interface UpdateBmeContractRequest {
  contract_type?: BmeContractType; vendor_id?: string;
  start_date?: string; end_date?: string;
  contract_value?: number; payment_terms?: string;
  coverage_details?: string; exclusions?: string;
  sla_response_hours?: number; sla_resolution_hours?: number;
  renewal_alert_days?: number;
  is_renewed?: boolean; renewed_contract_id?: string;
  is_active?: boolean; notes?: string;
}

export interface CreateBmeBreakdownRequest {
  equipment_id: string; department_id?: string;
  priority?: BmeBreakdownPriority; description: string;
  downtime_start?: string; vendor_visit_required?: boolean; notes?: string;
}
export interface UpdateBmeBreakdownStatusRequest {
  status: BmeBreakdownStatus; resolution_notes?: string;
  downtime_end?: string; spare_parts_used?: string;
  spare_parts_cost?: number; vendor_id?: string;
  vendor_cost?: number; total_repair_cost?: number;
}

export interface CreateBmeVendorEvaluationRequest {
  vendor_id: string; contract_id?: string;
  evaluation_date: string; period_from?: string; period_to?: string;
  response_time_score?: number; resolution_quality_score?: number;
  spare_parts_availability_score?: number; professionalism_score?: number;
  overall_score?: number;
  total_calls?: number; calls_within_sla?: number; comments?: string;
}

// ═══════════════════════════════════════════════════════════
//  Facilities Management (FMS)
// ═══════════════════════════════════════════════════════════

export type FmsGasType = "oxygen" | "nitrous_oxide" | "nitrogen" | "medical_air" | "vacuum" | "co2" | "heliox";
export type FmsGasSourceType = "psa_plant" | "lmo_tank" | "cylinder_manifold" | "pipeline";
export type FmsFireEquipmentType = "extinguisher_abc" | "extinguisher_co2" | "extinguisher_water" | "hydrant" | "hose_reel" | "smoke_detector" | "heat_detector" | "sprinkler" | "fire_alarm_panel" | "emergency_light";
export type FmsDrillType = "fire" | "code_red" | "evacuation" | "chemical_spill" | "bomb_threat";
export type FmsWaterSourceType = "municipal" | "borewell" | "tanker" | "ro_plant" | "stp_recycled";
export type FmsWaterTestType = "bacteriological" | "chemical" | "endotoxin" | "conductivity";
export type FmsEnergySourceType = "grid" | "dg_set" | "ups" | "solar" | "inverter";
export type FmsWorkOrderStatus = "open" | "assigned" | "in_progress" | "on_hold" | "completed" | "cancelled";

export interface FmsGasReading {
  id: string; tenant_id: string;
  gas_type: FmsGasType; source_type: FmsGasSourceType;
  location_id?: string; department_id?: string;
  purity_percent?: number; pressure_bar?: number; flow_lpm?: number;
  temperature_c?: number; tank_level_percent?: number;
  cylinder_count?: number; manifold_side?: string;
  is_alarm: boolean; alarm_reason?: string;
  reading_at: string; recorded_by?: string;
  notes?: string; created_at: string; updated_at: string;
}

export interface FmsGasCompliance {
  id: string; tenant_id: string;
  facility_id?: string; gas_type: FmsGasType;
  peso_license_number?: string;
  peso_valid_from?: string; peso_valid_to?: string;
  drug_license_number?: string; drug_license_valid_to?: string;
  last_inspection_date?: string; next_inspection_date?: string;
  inspector_name?: string; compliance_status?: string;
  notes?: string; created_at: string; updated_at: string;
}

export interface FmsFireEquipment {
  id: string; tenant_id: string;
  name: string; equipment_type: FmsFireEquipmentType;
  location_id?: string; department_id?: string;
  serial_number?: string; make?: string; capacity?: string;
  installation_date?: string; expiry_date?: string;
  last_refill_date?: string; next_refill_date?: string;
  barcode_value?: string; qr_code_value?: string;
  is_active: boolean; notes?: string;
  created_at: string; updated_at: string;
}

export interface FmsFireInspection {
  id: string; tenant_id: string;
  equipment_id: string; inspection_date: string;
  is_functional: boolean; findings?: string;
  corrective_action?: string; inspected_by?: string;
  next_inspection_date?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface FmsFireDrill {
  id: string; tenant_id: string;
  drill_type: FmsDrillType; facility_id?: string;
  drill_date: string; start_time?: string; end_time?: string;
  duration_minutes?: number; zones_covered?: string[];
  participants_count?: number; scenario_description?: string;
  evacuation_time_seconds?: number; response_time_seconds?: number;
  findings?: string; improvement_actions?: string;
  drill_report_url?: string;
  conducted_by?: string; approved_by?: string;
  next_drill_due?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface FmsFireNoc {
  id: string; tenant_id: string;
  facility_id?: string; noc_number: string;
  issuing_authority?: string; issue_date?: string;
  valid_from?: string; valid_to?: string;
  renewal_alert_days: number; is_active: boolean;
  document_url?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface FmsWaterTest {
  id: string; tenant_id: string;
  source_type: FmsWaterSourceType; test_type: FmsWaterTestType;
  location_id?: string; sample_date: string; result_date?: string;
  parameter_name: string; result_value?: number; unit?: string;
  acceptable_min?: number; acceptable_max?: number;
  is_within_limits?: boolean; corrective_action?: string;
  tested_by?: string; lab_name?: string; certificate_number?: string;
  notes?: string; created_at: string; updated_at: string;
}

export interface FmsWaterSchedule {
  id: string; tenant_id: string;
  location_id?: string; schedule_type: string; frequency: string;
  last_completed_date?: string; next_due_date?: string;
  assigned_to?: string; is_active: boolean; notes?: string;
  created_at: string; updated_at: string;
}

export interface FmsEnergyReading {
  id: string; tenant_id: string;
  source_type: FmsEnergySourceType; location_id?: string;
  equipment_name?: string; reading_at: string;
  voltage?: number; current_amps?: number; power_kw?: number;
  power_factor?: number; frequency_hz?: number;
  fuel_level_percent?: number; runtime_hours?: number; load_percent?: number;
  battery_voltage?: number; battery_health_percent?: number;
  backup_minutes?: number; switchover_time_seconds?: number;
  is_alarm: boolean; alarm_reason?: string;
  recorded_by?: string; notes?: string;
  created_at: string; updated_at: string;
}

export interface FmsWorkOrder {
  id: string; tenant_id: string;
  work_order_number: string; category?: string;
  location_id?: string; department_id?: string;
  requested_by?: string; requested_at: string;
  priority: string; status: FmsWorkOrderStatus;
  description: string; assigned_to?: string;
  assigned_at?: string; started_at?: string; completed_at?: string;
  findings?: string; actions_taken?: string;
  vendor_id?: string; vendor_report?: string;
  vendor_cost?: number; material_cost?: number;
  labor_cost?: number; total_cost?: number;
  completed_by?: string; sign_off_by?: string; sign_off_at?: string;
  notes?: string; created_at: string; updated_at: string;
}

export interface FmsStatsResponse {
  overdue_fire_inspections: number;
  gas_compliance_expiring: number;
  water_tests_due: number;
  open_work_orders: number;
  energy_alarms: number;
}

// Request types
export interface CreateFmsGasReadingRequest {
  gas_type: FmsGasType; source_type: FmsGasSourceType;
  location_id?: string; department_id?: string;
  purity_percent?: number; pressure_bar?: number; flow_lpm?: number;
  temperature_c?: number; tank_level_percent?: number;
  cylinder_count?: number; manifold_side?: string;
  is_alarm?: boolean; alarm_reason?: string;
  reading_at?: string; notes?: string;
}

export interface CreateFmsGasComplianceRequest {
  facility_id?: string; gas_type: FmsGasType;
  peso_license_number?: string;
  peso_valid_from?: string; peso_valid_to?: string;
  drug_license_number?: string; drug_license_valid_to?: string;
  last_inspection_date?: string; next_inspection_date?: string;
  inspector_name?: string; compliance_status?: string; notes?: string;
}

export interface UpdateFmsGasComplianceRequest {
  peso_license_number?: string;
  peso_valid_from?: string; peso_valid_to?: string;
  drug_license_number?: string; drug_license_valid_to?: string;
  last_inspection_date?: string; next_inspection_date?: string;
  inspector_name?: string; compliance_status?: string; notes?: string;
}

export interface CreateFmsFireEquipmentRequest {
  name: string; equipment_type: FmsFireEquipmentType;
  location_id?: string; department_id?: string;
  serial_number?: string; make?: string; capacity?: string;
  installation_date?: string; expiry_date?: string;
  last_refill_date?: string; next_refill_date?: string;
  barcode_value?: string; qr_code_value?: string; notes?: string;
}

export interface UpdateFmsFireEquipmentRequest {
  name?: string; location_id?: string; department_id?: string;
  serial_number?: string; make?: string; capacity?: string;
  expiry_date?: string; last_refill_date?: string; next_refill_date?: string;
  barcode_value?: string; qr_code_value?: string;
  is_active?: boolean; notes?: string;
}

export interface CreateFmsFireInspectionRequest {
  equipment_id: string; inspection_date: string;
  is_functional: boolean; findings?: string;
  corrective_action?: string; next_inspection_date?: string; notes?: string;
}

export interface CreateFmsFireDrillRequest {
  drill_type: FmsDrillType; facility_id?: string;
  drill_date: string; start_time?: string; end_time?: string;
  duration_minutes?: number; zones_covered?: string[];
  participants_count?: number; scenario_description?: string;
  evacuation_time_seconds?: number; response_time_seconds?: number;
  findings?: string; improvement_actions?: string;
  drill_report_url?: string; approved_by?: string;
  next_drill_due?: string; notes?: string;
}

export interface CreateFmsFireNocRequest {
  facility_id?: string; noc_number: string;
  issuing_authority?: string; issue_date?: string;
  valid_from?: string; valid_to?: string;
  renewal_alert_days?: number; document_url?: string; notes?: string;
}

export interface UpdateFmsFireNocRequest {
  issuing_authority?: string; issue_date?: string;
  valid_from?: string; valid_to?: string;
  renewal_alert_days?: number; is_active?: boolean;
  document_url?: string; notes?: string;
}

export interface CreateFmsWaterTestRequest {
  source_type: FmsWaterSourceType; test_type: FmsWaterTestType;
  location_id?: string; sample_date: string; result_date?: string;
  parameter_name: string; result_value?: number; unit?: string;
  acceptable_min?: number; acceptable_max?: number;
  is_within_limits?: boolean; corrective_action?: string;
  tested_by?: string; lab_name?: string; certificate_number?: string; notes?: string;
}

export interface CreateFmsWaterScheduleRequest {
  location_id?: string; schedule_type: string; frequency: string;
  last_completed_date?: string; next_due_date?: string;
  assigned_to?: string; notes?: string;
}

export interface UpdateFmsWaterScheduleRequest {
  last_completed_date?: string; next_due_date?: string;
  assigned_to?: string; is_active?: boolean; notes?: string;
}

export interface CreateFmsEnergyReadingRequest {
  source_type: FmsEnergySourceType; location_id?: string;
  equipment_name?: string; reading_at?: string;
  voltage?: number; current_amps?: number; power_kw?: number;
  power_factor?: number; frequency_hz?: number;
  fuel_level_percent?: number; runtime_hours?: number; load_percent?: number;
  battery_voltage?: number; battery_health_percent?: number;
  backup_minutes?: number; switchover_time_seconds?: number;
  is_alarm?: boolean; alarm_reason?: string; notes?: string;
}

export interface CreateFmsWorkOrderRequest {
  category?: string; location_id?: string; department_id?: string;
  priority?: string; description: string;
  assigned_to?: string; vendor_id?: string; notes?: string;
}

export interface UpdateFmsWorkOrderStatusRequest {
  status: FmsWorkOrderStatus;
  assigned_to?: string; findings?: string; actions_taken?: string;
  vendor_id?: string; vendor_report?: string;
  vendor_cost?: number; material_cost?: number; labor_cost?: number;
  notes?: string;
}

// ═══════════════════════════════════════════════════════════
//  Security Department
// ═══════════════════════════════════════════════════════════

export type SecAccessMethod = "card" | "biometric" | "pin" | "manual";
export type SecZoneLevel = "public" | "general" | "restricted" | "high_security" | "critical";
export type SecIncidentSeverity = "low" | "medium" | "high" | "critical";
export type SecIncidentStatus = "reported" | "investigating" | "resolved" | "closed";
export type SecPatientTagType = "infant_rfid" | "wander_guard" | "elopement_risk";
export type SecTagAlertStatus = "active" | "alert_triggered" | "resolved" | "deactivated";

export interface SecurityZone {
  id: string; tenant_id: string;
  name: string; zone_code: string; level: SecZoneLevel;
  department_id?: string; description?: string;
  allowed_methods?: unknown;
  after_hours_restricted: boolean;
  after_hours_start?: string; after_hours_end?: string;
  is_active: boolean;
  created_at: string; updated_at: string;
}

export interface SecurityAccessLog {
  id: string; tenant_id: string;
  zone_id: string; employee_id?: string; person_name?: string;
  access_method: SecAccessMethod; card_number?: string;
  direction: string; granted: boolean; denied_reason?: string;
  is_after_hours: boolean; accessed_at: string;
  device_id?: string; recorded_by?: string;
  created_at: string; updated_at: string;
}

export interface SecurityAccessCard {
  id: string; tenant_id: string;
  employee_id: string; card_number: string; card_type?: string;
  issued_date: string; expiry_date?: string;
  allowed_zones?: unknown;
  is_active: boolean; deactivated_at?: string; deactivation_reason?: string;
  issued_by?: string;
  created_at: string; updated_at: string;
}

export interface SecurityCamera {
  id: string; tenant_id: string;
  name: string; camera_id?: string; zone_id?: string;
  location_description?: string; camera_type?: string; resolution?: string;
  is_recording: boolean; retention_days: number;
  ip_address?: string; is_active: boolean; last_checked_at?: string;
  created_at: string; updated_at: string;
}

export interface SecurityIncident {
  id: string; tenant_id: string;
  incident_number: string; severity: SecIncidentSeverity;
  status: SecIncidentStatus; category: string;
  zone_id?: string; location_description?: string;
  occurred_at: string; description: string;
  persons_involved?: unknown; witnesses?: unknown;
  camera_ids?: unknown;
  video_timestamp_start?: string; video_timestamp_end?: string;
  police_notified: boolean; police_report_number?: string;
  investigation_notes?: string; resolution?: string;
  resolved_at?: string; resolved_by?: string;
  reported_by?: string; assigned_to?: string;
  created_at: string; updated_at: string;
}

export interface SecurityPatientTag {
  id: string; tenant_id: string;
  patient_id: string; tag_type: SecPatientTagType;
  tag_identifier?: string; allowed_zone_id?: string;
  alert_status: SecTagAlertStatus;
  mother_id?: string; admission_id?: string;
  activated_at: string; deactivated_at?: string;
  activated_by?: string; deactivated_by?: string;
  created_at: string; updated_at: string;
}

export interface SecurityTagAlert {
  id: string; tenant_id: string;
  tag_id: string; alert_type: string;
  triggered_at: string; zone_id?: string; location_description?: string;
  is_resolved: boolean; resolved_at?: string; resolved_by?: string;
  was_false_alarm: boolean; resolution_notes?: string;
  code_activation_id?: string;
  created_at: string; updated_at: string;
}

export interface SecurityCodeDebrief {
  id: string; tenant_id: string;
  code_activation_id: string; debrief_date: string;
  facilitator_id?: string; attendees?: unknown;
  response_time_seconds?: number; total_duration_minutes?: number;
  what_went_well?: string; what_went_wrong?: string;
  root_cause?: string; lessons_learned?: string;
  action_items?: unknown; equipment_issues?: string;
  training_gaps?: string; protocol_changes_recommended?: string;
  created_at: string; updated_at: string;
}

// Request types
export interface CreateSecurityZoneRequest {
  name: string; zone_code: string; level?: SecZoneLevel;
  department_id?: string; description?: string;
  allowed_methods?: unknown;
  after_hours_restricted?: boolean;
  after_hours_start?: string; after_hours_end?: string;
}

export interface UpdateSecurityZoneRequest {
  name?: string; level?: SecZoneLevel;
  department_id?: string; description?: string;
  allowed_methods?: unknown;
  after_hours_restricted?: boolean;
  after_hours_start?: string; after_hours_end?: string;
  is_active?: boolean;
}

export interface CreateSecurityAccessLogRequest {
  zone_id: string; employee_id?: string; person_name?: string;
  access_method?: SecAccessMethod; card_number?: string;
  direction?: string; granted?: boolean; denied_reason?: string;
  is_after_hours?: boolean; accessed_at?: string; device_id?: string;
}

export interface CreateSecurityAccessCardRequest {
  employee_id: string; card_number: string; card_type?: string;
  issued_date?: string; expiry_date?: string;
  allowed_zones?: unknown;
}

export interface UpdateSecurityAccessCardRequest {
  card_type?: string; expiry_date?: string; allowed_zones?: unknown;
}

export interface CreateSecurityCameraRequest {
  name: string; camera_id?: string; zone_id?: string;
  location_description?: string; camera_type?: string; resolution?: string;
  is_recording?: boolean; retention_days?: number; ip_address?: string;
}

export interface UpdateSecurityCameraRequest {
  name?: string; camera_id?: string; zone_id?: string;
  location_description?: string; camera_type?: string; resolution?: string;
  is_recording?: boolean; retention_days?: number; ip_address?: string;
  is_active?: boolean;
}

export interface CreateSecurityIncidentRequest {
  severity?: SecIncidentSeverity; category: string;
  zone_id?: string; location_description?: string;
  occurred_at?: string; description: string;
  persons_involved?: unknown; witnesses?: unknown;
  camera_ids?: unknown;
  video_timestamp_start?: string; video_timestamp_end?: string;
  police_notified?: boolean; police_report_number?: string;
  assigned_to?: string;
}

export interface UpdateSecurityIncidentRequest {
  severity?: SecIncidentSeverity; status?: SecIncidentStatus;
  category?: string; zone_id?: string; location_description?: string;
  description?: string; persons_involved?: unknown; witnesses?: unknown;
  camera_ids?: unknown;
  video_timestamp_start?: string; video_timestamp_end?: string;
  police_notified?: boolean; police_report_number?: string;
  investigation_notes?: string; resolution?: string; assigned_to?: string;
}

export interface CreateSecurityPatientTagRequest {
  patient_id: string; tag_type: SecPatientTagType;
  tag_identifier?: string; allowed_zone_id?: string;
  mother_id?: string; admission_id?: string;
}

export interface ResolveSecurityTagAlertRequest {
  was_false_alarm?: boolean; resolution_notes?: string;
}

export interface CreateSecurityCodeDebriefRequest {
  code_activation_id: string; debrief_date?: string;
  facilitator_id?: string; attendees?: unknown;
  response_time_seconds?: number; total_duration_minutes?: number;
  what_went_well?: string; what_went_wrong?: string;
  root_cause?: string; lessons_learned?: string;
  action_items?: unknown; equipment_issues?: string;
  training_gaps?: string; protocol_changes_recommended?: string;
}

// ── MRD (Medical Records Department) ────────────────────────

export type MrdRecordStatus = "active" | "archived" | "destroyed" | "missing";
export type MrdMovementStatus = "issued" | "returned" | "overdue";
export type MrdRegisterType = "birth" | "death";

export interface MrdMedicalRecord {
  id: string; tenant_id: string; patient_id: string;
  record_number: string; record_type: string;
  volume_number: number; total_pages: number | null;
  shelf_location: string | null;
  status: MrdRecordStatus;
  last_accessed_at: string | null;
  retention_years: number;
  destruction_due_date: string | null;
  notes: string | null;
  created_by: string | null;
  created_at: string; updated_at: string;
}

export interface MrdRecordMovement {
  id: string; tenant_id: string;
  medical_record_id: string;
  issued_to_user_id: string | null;
  issued_to_department_id: string | null;
  issued_at: string;
  due_date: string | null;
  returned_at: string | null;
  status: MrdMovementStatus;
  purpose: string | null;
  notes: string | null;
  created_by: string | null;
  created_at: string; updated_at: string;
}

export interface MrdBirthRegister {
  id: string; tenant_id: string; patient_id: string;
  admission_id: string | null;
  register_number: string;
  birth_date: string; birth_time: string | null;
  baby_gender: string; baby_weight_grams: number | null;
  birth_type: string;
  apgar_1min: number | null; apgar_5min: number | null;
  complications: string | null;
  attending_doctor_id: string | null;
  certificate_number: string | null;
  certificate_issued: boolean;
  father_name: string | null; mother_age: number | null;
  created_by: string | null;
  created_at: string; updated_at: string;
}

export interface MrdDeathRegister {
  id: string; tenant_id: string; patient_id: string;
  admission_id: string | null;
  er_visit_id: string | null;
  mlc_case_id: string | null;
  register_number: string;
  death_date: string; death_time: string | null;
  cause_of_death: string | null;
  immediate_cause: string | null;
  antecedent_cause: string | null;
  underlying_cause: string | null;
  manner_of_death: string;
  is_medico_legal: boolean;
  is_brought_dead: boolean;
  certifying_doctor_id: string | null;
  certificate_number: string | null;
  certificate_issued: boolean;
  reported_to_municipality: boolean;
  municipality_report_date: string | null;
  created_by: string | null;
  created_at: string; updated_at: string;
}

export interface MrdRetentionPolicy {
  id: string; tenant_id: string;
  record_type: string; category: string;
  retention_years: number;
  legal_reference: string | null;
  destruction_method: string | null;
  is_active: boolean;
  created_by: string | null;
  created_at: string; updated_at: string;
}

export interface CreateMrdRecordRequest {
  patient_id: string; record_number?: string; record_type?: string;
  volume_number?: number; total_pages?: number;
  shelf_location?: string; retention_years?: number;
  destruction_due_date?: string; notes?: string;
}

export interface UpdateMrdRecordRequest {
  volume_number?: number; total_pages?: number;
  shelf_location?: string; status?: MrdRecordStatus;
  retention_years?: number; destruction_due_date?: string; notes?: string;
}

export interface IssueMrdRecordRequest {
  issued_to_user_id?: string; issued_to_department_id?: string;
  purpose?: string; due_days?: number; notes?: string;
}

export interface CreateMrdBirthRequest {
  patient_id: string; admission_id?: string;
  register_number?: string; birth_date: string; birth_time?: string;
  baby_gender: string; baby_weight_grams?: number;
  birth_type?: string;
  apgar_1min?: number; apgar_5min?: number;
  complications?: string; attending_doctor_id?: string;
  certificate_number?: string; certificate_issued?: boolean;
  father_name?: string; mother_age?: number;
}

export interface CreateMrdDeathRequest {
  patient_id: string; admission_id?: string;
  er_visit_id?: string; mlc_case_id?: string;
  register_number?: string; death_date: string; death_time?: string;
  cause_of_death?: string; immediate_cause?: string;
  antecedent_cause?: string; underlying_cause?: string;
  manner_of_death?: string;
  is_medico_legal?: boolean; is_brought_dead?: boolean;
  certifying_doctor_id?: string;
  certificate_number?: string; certificate_issued?: boolean;
  reported_to_municipality?: boolean; municipality_report_date?: string;
}

export interface CreateMrdRetentionPolicyRequest {
  record_type: string; category: string; retention_years: number;
  legal_reference?: string; destruction_method?: string; is_active?: boolean;
}

export interface UpdateMrdRetentionPolicyRequest {
  retention_years?: number; legal_reference?: string;
  destruction_method?: string; is_active?: boolean;
}

export interface MrdMorbidityRow {
  icd_code: string | null; diagnosis_name: string; count: number;
}

export interface MrdMortalityRow {
  cause_of_death: string | null; manner_of_death: string; count: number;
}

export interface MrdMorbidityMortalityResponse {
  morbidity: MrdMorbidityRow[]; mortality: MrdMortalityRow[];
}

export interface MrdAdmissionDischargeRow {
  department_name: string | null;
  total_admitted: number; total_discharged: number;
  total_deaths: number; avg_los_days: number | null;
}

export interface MrdAdmissionDischargeSummary {
  rows: MrdAdmissionDischargeRow[];
  total_admitted: number; total_discharged: number;
  total_deaths: number; overall_avg_los_days: number | null;
}

// ══════════════════════════════════════════════════════════════
//  Specialty Clinical
// ══════════════════════════════════════════════════════════════

// ── Cath Lab ──

export type CathProcedureType =
  | "diagnostic_cath" | "pci" | "pacemaker" | "icd" | "eps"
  | "ablation" | "valve_intervention" | "structural" | "peripheral";

export type StemiPathwayStatus =
  | "door" | "ecg" | "cath_lab_activation" | "arterial_access"
  | "balloon_inflation" | "completed";

export type HemodynamicSite =
  | "aorta" | "lv" | "rv" | "ra" | "la" | "pa" | "pcwp"
  | "svg" | "lm" | "lad" | "lcx" | "rca" | "other";

export type CathDeviceType =
  | "stent" | "balloon" | "guidewire" | "catheter" | "closure_device"
  | "pacemaker" | "icd" | "lead" | "other";

export interface CathProcedure {
  id: string;
  tenant_id: string;
  patient_id: string;
  procedure_type: CathProcedureType;
  operator_id: string;
  is_stemi: boolean;
  door_time: string | null;
  balloon_time: string | null;
  door_to_balloon_minutes: number | null;
  fluoroscopy_time_seconds: number | null;
  total_dap: number | null;
  total_air_kerma: number | null;
  contrast_type: string | null;
  contrast_volume_ml: number | null;
  findings: Record<string, unknown> | null;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface CreateCathProcedureRequest {
  patient_id: string;
  procedure_type: CathProcedureType;
  operator_id: string;
  is_stemi?: boolean;
  door_time?: string;
  contrast_type?: string;
  contrast_volume_ml?: number;
  findings?: Record<string, unknown>;
}

export interface CathHemodynamic {
  id: string;
  tenant_id: string;
  procedure_id: string;
  site: HemodynamicSite;
  systolic_mmhg: number | null;
  diastolic_mmhg: number | null;
  mean_mmhg: number | null;
  saturation_pct: number | null;
  gradient_mmhg: number | null;
  created_at: string;
}

export interface CreateCathHemodynamicRequest {
  site: HemodynamicSite;
  systolic_mmhg?: number;
  diastolic_mmhg?: number;
  mean_mmhg?: number;
  saturation_pct?: number;
  gradient_mmhg?: number;
}

export interface CathDevice {
  id: string;
  tenant_id: string;
  procedure_id: string;
  device_type: CathDeviceType;
  manufacturer: string | null;
  lot_number: string | null;
  barcode: string | null;
  is_consignment: boolean;
  vendor_id: string | null;
  unit_cost: number | null;
  billed: boolean;
  created_at: string;
}

export interface CreateCathDeviceRequest {
  device_type: CathDeviceType;
  manufacturer?: string;
  lot_number?: string;
  barcode?: string;
  is_consignment?: boolean;
  vendor_id?: string;
  unit_cost?: number;
}

export interface CathStemiTimeline {
  id: string;
  tenant_id: string;
  procedure_id: string;
  event: StemiPathwayStatus;
  event_time: string;
  recorded_by: string;
  created_at: string;
}

export interface CreateCathStemiEventRequest {
  event: StemiPathwayStatus;
  event_time: string;
}

export interface CathPostMonitoring {
  id: string;
  tenant_id: string;
  procedure_id: string;
  monitored_at: string;
  sheath_status: string | null;
  access_site_status: string | null;
  vitals: Record<string, unknown> | null;
  ambulation_started: boolean;
  created_at: string;
}

export interface CreateCathPostMonitoringRequest {
  monitored_at: string;
  sheath_status?: string;
  access_site_status?: string;
  vitals?: Record<string, unknown>;
  ambulation_started?: boolean;
}

// ── Endoscopy ──

export type ScopeStatus =
  | "available" | "in_use" | "reprocessing" | "quarantine" | "decommissioned";

export type HldResult = "pass" | "fail" | "pending";

export interface EndoscopyProcedure {
  id: string;
  tenant_id: string;
  patient_id: string;
  scope_id: string | null;
  procedure_type: string;
  sedation_type: string | null;
  findings: Record<string, unknown> | null;
  biopsy_taken: boolean;
  sedation_drugs: Record<string, unknown> | null;
  aldrete_score_pre: number | null;
  aldrete_score_post: number | null;
  created_at: string;
  updated_at: string;
}

export interface CreateEndoscopyProcedureRequest {
  patient_id: string;
  scope_id?: string;
  procedure_type: string;
  sedation_type?: string;
  findings?: Record<string, unknown>;
  sedation_drugs?: Record<string, unknown>;
  aldrete_score_pre?: number;
  aldrete_score_post?: number;
}

export interface EndoscopyScope {
  id: string;
  tenant_id: string;
  serial_number: string;
  model: string | null;
  scope_type: string | null;
  status: ScopeStatus;
  last_hld_at: string | null;
  total_uses: number;
  last_culture_date: string | null;
  last_culture_result: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateEndoscopyScopeRequest {
  serial_number: string;
  model?: string;
  scope_type?: string;
}

export interface EndoscopyReprocessing {
  id: string;
  tenant_id: string;
  scope_id: string;
  procedure_id: string | null;
  leak_test_passed: boolean;
  hld_chemical: string | null;
  hld_concentration: string | null;
  hld_soak_minutes: number | null;
  hld_temperature: number | null;
  hld_result: HldResult;
  reprocessed_by: string;
  created_at: string;
}

export interface CreateEndoscopyReprocessingRequest {
  scope_id: string;
  procedure_id?: string;
  leak_test_passed: boolean;
  hld_chemical?: string;
  hld_concentration?: string;
  hld_soak_minutes?: number;
  hld_temperature?: number;
  hld_result: HldResult;
}

export interface EndoscopyBiopsySpecimen {
  id: string;
  tenant_id: string;
  procedure_id: string;
  site: string;
  container_label: string | null;
  fixative: string | null;
  chain_of_custody: Record<string, unknown> | null;
  pathology_result: string | null;
  created_at: string;
}

export interface CreateEndoscopyBiopsyRequest {
  site: string;
  container_label?: string;
  fixative?: string;
  chain_of_custody?: Record<string, unknown>;
}

// ── Psychiatry ──

export type PsychAdmissionCategory =
  | "independent" | "supported" | "minor_supported" | "emergency";

export type EctLaterality =
  | "bilateral" | "right_unilateral" | "left_unilateral";

export type RestraintType = "physical" | "chemical" | "seclusion";

export interface PsychPatient {
  id: string;
  tenant_id: string;
  patient_id: string;
  admission_category: PsychAdmissionCategory;
  advance_directive_text: string | null;
  nominated_rep_name: string | null;
  nominated_rep_contact: string | null;
  nominated_rep_relation: string | null;
  substance_abuse_flag: boolean;
  is_restricted: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreatePsychPatientRequest {
  patient_id: string;
  admission_category: PsychAdmissionCategory;
  advance_directive_text?: string;
  nominated_rep_name?: string;
  nominated_rep_contact?: string;
  nominated_rep_relation?: string;
  substance_abuse_flag?: boolean;
}

export interface PsychAssessment {
  id: string;
  tenant_id: string;
  psych_patient_id: string;
  assessment_type: string;
  mental_status_exam: Record<string, unknown> | null;
  ham_d_score: number | null;
  bprs_score: number | null;
  risk_assessment: Record<string, unknown> | null;
  created_at: string;
}

export interface CreatePsychAssessmentRequest {
  assessment_type: string;
  mental_status_exam?: Record<string, unknown>;
  ham_d_score?: number;
  bprs_score?: number;
  risk_assessment?: Record<string, unknown>;
}

export interface PsychEctSession {
  id: string;
  tenant_id: string;
  psych_patient_id: string;
  session_number: number;
  consent_obtained: boolean;
  laterality: EctLaterality;
  stimulus_dose: string | null;
  seizure_duration: string | null;
  anesthetic: string | null;
  performed_by: string;
  created_at: string;
}

export interface CreatePsychEctRequest {
  session_number: number;
  consent_obtained: boolean;
  laterality: EctLaterality;
  stimulus_dose?: string;
  seizure_duration?: string;
  anesthetic?: string;
  performed_by: string;
}

export interface PsychRestraint {
  id: string;
  tenant_id: string;
  psych_patient_id: string;
  restraint_type: RestraintType;
  start_time: string;
  review_due_at: string;
  reviewed_at: string | null;
  released_at: string | null;
  released_by: string | null;
  created_at: string;
}

export interface CreatePsychRestraintRequest {
  restraint_type: RestraintType;
  start_time: string;
}

export interface PsychMhrbNotification {
  id: string;
  tenant_id: string;
  psych_patient_id: string;
  notification_type: string;
  reference_number: string | null;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface CreatePsychMhrbRequest {
  notification_type: string;
  reference_number?: string;
}

export interface PsychCounselingSession {
  id: string;
  tenant_id: string;
  psych_patient_id: string;
  session_type: string;
  therapist_id: string;
  modality: string | null;
  outcome_rating: number | null;
  created_at: string;
}

export interface CreatePsychCounselingRequest {
  session_type: string;
  therapist_id: string;
  modality?: string;
  outcome_rating?: number;
}

// ── PMR / Audiology ──

export type RehabDiscipline =
  | "physiotherapy" | "occupational_therapy" | "speech_therapy"
  | "psychology" | "prosthetics_orthotics";

export type HearingTestType =
  | "pta" | "bera" | "oae" | "tympanometry" | "speech_audiometry";

export interface RehabPlan {
  id: string;
  tenant_id: string;
  patient_id: string;
  discipline: RehabDiscipline;
  goals: string | null;
  plan_details: Record<string, unknown> | null;
  fim_score_initial: number | null;
  barthel_score_initial: number | null;
  created_at: string;
  updated_at: string;
}

export interface CreateRehabPlanRequest {
  patient_id: string;
  discipline: RehabDiscipline;
  goals?: string;
  plan_details?: Record<string, unknown>;
  fim_score_initial?: number;
  barthel_score_initial?: number;
}

export interface RehabSession {
  id: string;
  tenant_id: string;
  plan_id: string;
  session_number: number;
  therapist_id: string;
  intervention: string | null;
  pain_score: number | null;
  rom: Record<string, unknown> | null;
  strength: Record<string, unknown> | null;
  fim_score: number | null;
  barthel_score: number | null;
  created_at: string;
}

export interface CreateRehabSessionRequest {
  session_number: number;
  therapist_id: string;
  intervention?: string;
  pain_score?: number;
  rom?: Record<string, unknown>;
  strength?: Record<string, unknown>;
  fim_score?: number;
  barthel_score?: number;
}

export interface AudiologyTest {
  id: string;
  tenant_id: string;
  patient_id: string;
  test_type: HearingTestType;
  right_ear_results: Record<string, unknown> | null;
  left_ear_results: Record<string, unknown> | null;
  is_nhsp: boolean;
  nhsp_referral_needed: boolean;
  audiogram_data: Record<string, unknown> | null;
  created_at: string;
}

export interface CreateAudiologyTestRequest {
  patient_id: string;
  test_type: HearingTestType;
  right_ear_results?: Record<string, unknown>;
  left_ear_results?: Record<string, unknown>;
  is_nhsp?: boolean;
  nhsp_referral_needed?: boolean;
  audiogram_data?: Record<string, unknown>;
}

export interface PsychometricTest {
  id: string;
  tenant_id: string;
  patient_id: string;
  test_name: string;
  raw_data_encrypted: Record<string, unknown> | null;
  summary_for_clinician: string | null;
  is_restricted: boolean;
  created_at: string;
}

export interface CreatePsychometricTestRequest {
  patient_id: string;
  test_name: string;
  raw_data_encrypted?: Record<string, unknown>;
  summary_for_clinician?: string;
}

// ── Palliative / Mortuary / Nuclear Medicine ──

export type DnrStatus = "active" | "expired" | "revoked";

export type BodyStatus =
  | "received" | "cold_storage" | "inquest_pending" | "pm_scheduled"
  | "pm_completed" | "released" | "unclaimed" | "disposed";

export type RadiopharmaceuticalType = "diagnostic" | "therapeutic";

export interface DnrOrder {
  id: string;
  tenant_id: string;
  patient_id: string;
  admission_id: string | null;
  status: DnrStatus;
  review_due_at: string;
  scope: string | null;
  authorized_by: string;
  revoked_at: string | null;
  revoked_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateDnrOrderRequest {
  patient_id: string;
  admission_id?: string;
  scope?: string;
}

export interface PainAssessment {
  id: string;
  tenant_id: string;
  patient_id: string;
  pain_score: number;
  who_ladder_step: number | null;
  opioid_dose_morphine_eq: number | null;
  breakthrough_doses: number | null;
  created_at: string;
}

export interface CreatePainAssessmentRequest {
  patient_id: string;
  pain_score: number;
  who_ladder_step?: number;
  opioid_dose_morphine_eq?: number;
  breakthrough_doses?: number;
}

export interface MortuaryRecord {
  id: string;
  tenant_id: string;
  body_receipt_number: string;
  deceased_name: string;
  is_mlc: boolean;
  mlc_case_id: string | null;
  cold_storage_slot: string | null;
  temperature_log: Record<string, unknown> | null;
  status: BodyStatus;
  pm_requested: boolean;
  pm_conducted_by: string | null;
  pm_date: string | null;
  pm_findings: string | null;
  viscera_chain_of_custody: Record<string, unknown> | null;
  unclaimed_fir_filed: boolean;
  unclaimed_photo_taken: boolean;
  organ_donation_status: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateMortuaryRecordRequest {
  body_receipt_number: string;
  deceased_name: string;
  is_mlc?: boolean;
  mlc_case_id?: string;
  cold_storage_slot?: string;
}

export interface NuclearMedSource {
  id: string;
  tenant_id: string;
  isotope: string;
  activity_mci: number;
  half_life_hours: number;
  aerb_license_number: string | null;
  batch_number: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateNuclearMedSourceRequest {
  isotope: string;
  activity_mci: number;
  half_life_hours: number;
  aerb_license_number?: string;
  batch_number?: string;
}

export interface NuclearMedAdministration {
  id: string;
  tenant_id: string;
  source_id: string;
  patient_id: string;
  dose_mci: number;
  route: string | null;
  indication: string | null;
  waste_disposed: boolean;
  created_at: string;
}

export interface CreateNuclearMedAdminRequest {
  source_id: string;
  patient_id: string;
  dose_mci: number;
  route?: string;
  indication?: string;
  waste_disposed?: boolean;
}

// ── Maternity / OB-GYN ──

export type AncRiskCategory = "low" | "moderate" | "high" | "very_high";

export type DeliveryType =
  | "normal_vaginal" | "assisted_vaginal" | "lscs_elective"
  | "lscs_emergency" | "breech";

export type LaborStage =
  | "first_latent" | "first_active" | "second" | "third" | "completed";

export interface MaternityRegistration {
  id: string;
  tenant_id: string;
  patient_id: string;
  registration_number: string;
  lmp_date: string | null;
  edd_date: string | null;
  gravida: number;
  para: number;
  abortion: number;
  living: number;
  risk_category: AncRiskCategory;
  blood_group: string | null;
  is_high_risk: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateMaternityRegistrationRequest {
  patient_id: string;
  registration_number: string;
  lmp_date?: string;
  edd_date?: string;
  gravida?: number;
  para?: number;
  abortion?: number;
  living?: number;
  risk_category?: AncRiskCategory;
  blood_group?: string;
}

export interface AncVisit {
  id: string;
  tenant_id: string;
  registration_id: string;
  visit_number: number;
  gestational_weeks: number | null;
  weight_kg: number | null;
  bp_systolic: number | null;
  bp_diastolic: number | null;
  fundal_height_cm: number | null;
  fetal_heart_rate: number | null;
  hemoglobin: number | null;
  pcpndt_form_f_filed: boolean;
  pcpndt_form_f_number: string | null;
  examined_by: string;
  created_at: string;
}

export interface CreateAncVisitRequest {
  visit_number: number;
  gestational_weeks?: number;
  weight_kg?: number;
  bp_systolic?: number;
  bp_diastolic?: number;
  fundal_height_cm?: number;
  fetal_heart_rate?: number;
  hemoglobin?: number;
  pcpndt_form_f_filed?: boolean;
  pcpndt_form_f_number?: string;
  examined_by: string;
}

export interface LaborRecord {
  id: string;
  tenant_id: string;
  registration_id: string;
  admission_id: string | null;
  labor_onset_time: string | null;
  current_stage: LaborStage;
  partograph_data: Record<string, unknown> | null;
  cervical_dilation_log: Record<string, unknown> | null;
  delivery_type: DeliveryType | null;
  apgar_1min: number | null;
  apgar_5min: number | null;
  baby_weight_gm: number | null;
  created_at: string;
  updated_at: string;
}

export interface CreateLaborRecordRequest {
  admission_id?: string;
  labor_onset_time?: string;
  current_stage?: LaborStage;
  partograph_data?: Record<string, unknown>;
}

export interface NewbornRecord {
  id: string;
  tenant_id: string;
  labor_id: string;
  birth_date: string;
  gender: string;
  weight_gm: number;
  apgar_1min: number | null;
  apgar_5min: number | null;
  vaccinations_given: Record<string, unknown> | null;
  nicu_admission_needed: boolean;
  birth_certificate_number: string | null;
  created_at: string;
}

export interface CreateNewbornRecordRequest {
  birth_date: string;
  gender: string;
  weight_gm: number;
  apgar_1min?: number;
  apgar_5min?: number;
  vaccinations_given?: Record<string, unknown>;
  nicu_admission_needed?: boolean;
  birth_certificate_number?: string;
}

export interface PostnatalRecord {
  id: string;
  tenant_id: string;
  registration_id: string;
  day_postpartum: number;
  mother_vitals: Record<string, unknown> | null;
  baby_vitals: Record<string, unknown> | null;
  baby_weight_gm: number | null;
  created_at: string;
}

export interface CreatePostnatalRecordRequest {
  day_postpartum: number;
  mother_vitals?: Record<string, unknown>;
  baby_vitals?: Record<string, unknown>;
  baby_weight_gm?: number;
}

// ── Other Specialties ──

export interface SpecialtyTemplate {
  id: string;
  tenant_id: string;
  specialty: string;
  template_name: string;
  template_code: string;
  form_schema: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface CreateSpecialtyTemplateRequest {
  specialty: string;
  template_name: string;
  template_code: string;
  form_schema: Record<string, unknown>;
}

export interface SpecialtyRecord {
  id: string;
  tenant_id: string;
  patient_id: string;
  specialty: string;
  template_id: string | null;
  form_data: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface CreateSpecialtyRecordRequest {
  patient_id: string;
  specialty: string;
  template_id?: string;
  form_data: Record<string, unknown>;
}

export interface DialysisSession {
  id: string;
  tenant_id: string;
  patient_id: string;
  machine_number: string | null;
  access_type: string | null;
  pre_weight_kg: number | null;
  post_weight_kg: number | null;
  uf_goal_ml: number | null;
  uf_achieved_ml: number | null;
  pre_vitals: Record<string, unknown> | null;
  post_vitals: Record<string, unknown> | null;
  kt_v: number | null;
  urr_pct: number | null;
  created_at: string;
  updated_at: string;
}

export interface CreateDialysisSessionRequest {
  patient_id: string;
  machine_number?: string;
  access_type?: string;
  pre_weight_kg?: number;
  uf_goal_ml?: number;
  pre_vitals?: Record<string, unknown>;
}

export interface ChemoProtocol {
  id: string;
  tenant_id: string;
  patient_id: string;
  protocol_name: string;
  cancer_type: string | null;
  staging: string | null;
  regimen: Record<string, unknown> | null;
  cycle_number: number;
  toxicity_grade: number | null;
  recist_response: string | null;
  tumor_board_reviewed: boolean;
  tumor_board_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateChemoProtocolRequest {
  patient_id: string;
  protocol_name: string;
  cancer_type?: string;
  staging?: string;
  regimen?: Record<string, unknown>;
  cycle_number?: number;
  toxicity_grade?: number;
  recist_response?: string;
  tumor_board_reviewed?: boolean;
  tumor_board_date?: string;
}

// ── Documents Module ─────────────────────────────────────

export type DocumentTemplateCategory =
  | "prescription" | "consultation_summary" | "discharge_summary" | "death_certificate"
  | "consent_form" | "lab_report" | "radiology_report" | "opd_bill" | "ipd_bill"
  | "receipt" | "case_sheet_cover" | "progress_note" | "nursing_assessment"
  | "mar_chart" | "vitals_chart" | "surgical_checklist" | "anesthesia_record"
  | "operation_note" | "employee_id_card" | "purchase_order" | "patient_card"
  | "wristband" | "queue_token" | "bmw_manifest" | "pcpndt_form_f"
  | "mlc_certificate" | "referral_letter" | "medical_certificate" | "fitness_certificate"
  | "blood_requisition" | "diet_chart" | "investigation_report" | "transfer_summary"
  | "admission_form" | "against_medical_advice" | "medico_legal_report"
  | "birth_certificate" | "duty_roster" | "indent_form" | "grn_form" | "custom";

export type DocumentOutputStatus = "draft" | "generated" | "printed" | "downloaded" | "voided" | "superseded";

export type DocumentPrintFormat =
  | "a4_portrait" | "a4_landscape" | "a5_portrait" | "a5_landscape"
  | "thermal_80mm" | "thermal_58mm" | "label_50x25mm" | "wristband" | "custom";

export type DocumentWatermark = "none" | "draft" | "confidential" | "copy" | "duplicate" | "uncontrolled" | "sample" | "cancelled";

export type PrintJobStatus = "queued" | "printing" | "completed" | "failed" | "cancelled";

export interface DocumentTemplate {
  id: string;
  tenant_id: string;
  code: string;
  name: string;
  category: DocumentTemplateCategory;
  module_code: string | null;
  description: string | null;
  version: number;
  is_active: boolean;
  is_default: boolean;
  print_format: DocumentPrintFormat;
  header_layout: Record<string, unknown> | null;
  body_layout: Record<string, unknown> | null;
  footer_layout: Record<string, unknown> | null;
  show_logo: boolean;
  logo_position: string | null;
  show_hospital_name: boolean;
  show_hospital_address: boolean;
  show_hospital_phone: boolean;
  show_registration_no: boolean;
  show_accreditation: boolean;
  font_family: string | null;
  font_size_pt: number | null;
  margin_top_mm: number | null;
  margin_bottom_mm: number | null;
  margin_left_mm: number | null;
  margin_right_mm: number | null;
  show_page_numbers: boolean;
  show_print_metadata: boolean;
  show_qr_code: boolean;
  default_watermark: DocumentWatermark;
  signature_blocks: Record<string, unknown> | null;
  required_context: string[] | null;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface DocumentTemplateVersion {
  id: string;
  tenant_id: string;
  template_id: string;
  version_number: number;
  snapshot: Record<string, unknown>;
  change_summary: string | null;
  created_by: string | null;
  created_at: string;
}

export interface DocumentOutput {
  id: string;
  tenant_id: string;
  template_id: string | null;
  template_version: number | null;
  module_code: string | null;
  source_table: string | null;
  source_id: string | null;
  patient_id: string | null;
  visit_id: string | null;
  admission_id: string | null;
  document_number: string;
  title: string;
  category: DocumentTemplateCategory;
  status: DocumentOutputStatus;
  file_url: string | null;
  file_size_bytes: number | null;
  mime_type: string | null;
  page_count: number | null;
  print_count: number;
  first_printed_at: string | null;
  last_printed_at: string | null;
  watermark: DocumentWatermark;
  language_code: string | null;
  context_snapshot: Record<string, unknown> | null;
  qr_code_data: string | null;
  document_hash: string | null;
  generated_by: string | null;
  voided_by: string | null;
  voided_at: string | null;
  voided_reason: string | null;
  created_at: string;
  updated_at: string;
}

export interface DocumentOutputSignature {
  id: string;
  tenant_id: string;
  document_output_id: string;
  signer_role: string;
  signer_name: string | null;
  designation: string | null;
  registration_number: string | null;
  signature_type: string;
  signature_image_url: string | null;
  biometric_hash: string | null;
  aadhaar_ref: string | null;
  thumb_impression: boolean;
  signed_at: string;
  captured_by: string | null;
  created_at: string;
}

export interface DocumentFormReviewSchedule {
  id: string;
  tenant_id: string;
  template_id: string;
  review_cycle_months: number;
  last_reviewed_at: string | null;
  last_reviewed_by: string | null;
  next_review_due: string | null;
  review_status: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface DocumentOutputStats {
  total_documents: number;
  total_prints: number;
  by_category: Record<string, number>;
  by_status: Record<string, number>;
}

// Request types
export interface CreateDocumentTemplateRequest {
  code: string;
  name: string;
  category: DocumentTemplateCategory;
  module_code?: string;
  description?: string;
  print_format?: DocumentPrintFormat;
  header_layout?: Record<string, unknown>;
  body_layout?: Record<string, unknown>;
  footer_layout?: Record<string, unknown>;
  show_logo?: boolean;
  logo_position?: string;
  show_hospital_name?: boolean;
  show_hospital_address?: boolean;
  show_hospital_phone?: boolean;
  show_registration_no?: boolean;
  show_accreditation?: boolean;
  font_family?: string;
  font_size_pt?: number;
  margin_top_mm?: number;
  margin_bottom_mm?: number;
  margin_left_mm?: number;
  margin_right_mm?: number;
  show_page_numbers?: boolean;
  show_print_metadata?: boolean;
  show_qr_code?: boolean;
  default_watermark?: DocumentWatermark;
  signature_blocks?: Record<string, unknown>;
  required_context?: string[];
}

export interface UpdateDocumentTemplateRequest {
  name?: string;
  category?: DocumentTemplateCategory;
  module_code?: string;
  description?: string;
  is_active?: boolean;
  print_format?: DocumentPrintFormat;
  header_layout?: Record<string, unknown>;
  body_layout?: Record<string, unknown>;
  footer_layout?: Record<string, unknown>;
  show_logo?: boolean;
  logo_position?: string;
  show_hospital_name?: boolean;
  show_hospital_address?: boolean;
  show_hospital_phone?: boolean;
  show_registration_no?: boolean;
  show_accreditation?: boolean;
  font_family?: string;
  font_size_pt?: number;
  margin_top_mm?: number;
  margin_bottom_mm?: number;
  margin_left_mm?: number;
  margin_right_mm?: number;
  show_page_numbers?: boolean;
  show_print_metadata?: boolean;
  show_qr_code?: boolean;
  default_watermark?: DocumentWatermark;
  signature_blocks?: Record<string, unknown>;
  required_context?: string[];
}

export interface GenerateDocumentRequest {
  template_code: string;
  title: string;
  module_code?: string;
  source_table?: string;
  source_id?: string;
  patient_id?: string;
  visit_id?: string;
  admission_id?: string;
  context: Record<string, unknown>;
  language_code?: string;
}

export interface BatchGenerateRequest {
  template_code: string;
  source_ids: string[];
  module_code?: string;
  source_table?: string;
}

export interface VoidDocumentRequest {
  reason: string;
}

export interface AddDocumentSignatureRequest {
  signer_role: string;
  signer_name?: string;
  designation?: string;
  registration_number?: string;
  signature_type: string;
  signature_image_url?: string;
  biometric_hash?: string;
  aadhaar_ref?: string;
  thumb_impression?: boolean;
}

export interface CreateReviewScheduleRequest {
  template_id: string;
  review_cycle_months: number;
  next_review_due?: string;
  notes?: string;
}

// ── Regulatory & Compliance ─────────────────────────────────

export type ComplianceChecklistStatus = "not_started" | "in_progress" | "compliant" | "non_compliant" | "not_applicable";
export type AdverseEventSeverity = "mild" | "moderate" | "severe" | "fatal";
export type AdverseEventStatus = "draft" | "submitted" | "under_review" | "closed" | "withdrawn";
export type PcpndtFormStatus = "draft" | "submitted" | "registered" | "expired";

export interface ComplianceChecklist {
  id: string;
  tenant_id: string;
  department_id?: string;
  accreditation_body: string;
  standard_code: string;
  name: string;
  description?: string;
  assessment_period_start: string;
  assessment_period_end: string;
  overall_status: ComplianceChecklistStatus;
  compliance_score?: number;
  total_items: number;
  compliant_items: number;
  non_compliant_items: number;
  assessed_by?: string;
  assessed_at?: string;
  next_review_date?: string;
  notes?: string;
  created_by: string;
  updated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface ComplianceChecklistItem {
  id: string;
  tenant_id: string;
  checklist_id: string;
  item_number: number;
  criterion: string;
  status: ComplianceChecklistStatus;
  evidence_summary?: string;
  evidence_documents: unknown[];
  gap_description?: string;
  corrective_action?: string;
  target_date?: string;
  responsible_user_id?: string;
  verified_by?: string;
  verified_at?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface ComplianceChecklistWithItems extends ComplianceChecklist {
  items: ComplianceChecklistItem[];
}

export interface AdrReport {
  id: string;
  tenant_id: string;
  report_number: string;
  patient_id?: string;
  reporter_id: string;
  reporter_type: string;
  drug_name: string;
  drug_generic_name?: string;
  drug_batch_number?: string;
  manufacturer?: string;
  reaction_description: string;
  onset_date?: string;
  reaction_date: string;
  severity: AdverseEventSeverity;
  outcome?: string;
  causality_assessment?: string;
  status: AdverseEventStatus;
  seriousness_criteria: unknown[];
  dechallenge?: string;
  rechallenge?: string;
  concomitant_drugs: unknown[];
  relevant_history?: string;
  submitted_to_pvpi: boolean;
  pvpi_reference?: string;
  submitted_at?: string;
  created_by: string;
  updated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface MateriovigilanceReport {
  id: string;
  tenant_id: string;
  report_number: string;
  patient_id?: string;
  reporter_id: string;
  device_name: string;
  device_manufacturer?: string;
  device_model?: string;
  device_batch?: string;
  event_description: string;
  event_date: string;
  severity: AdverseEventSeverity;
  patient_outcome?: string;
  device_action?: string;
  status: AdverseEventStatus;
  submitted_to_cdsco: boolean;
  cdsco_reference?: string;
  submitted_at?: string;
  investigation_findings?: string;
  corrective_action?: string;
  created_by: string;
  updated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface PcpndtForm {
  id: string;
  tenant_id: string;
  form_number: string;
  patient_id: string;
  referral_doctor_id?: string;
  performing_doctor_id: string;
  procedure_type: string;
  indication: string;
  gestational_age_weeks?: number;
  lmp_date?: string;
  declaration_text?: string;
  status: PcpndtFormStatus;
  form_signed_at?: string;
  patient_consent_id?: string;
  registered_with?: string;
  registration_date?: string;
  quarterly_report_included: boolean;
  gender_disclosure_blocked: boolean;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface ComplianceCalendarEvent {
  id: string;
  tenant_id: string;
  title: string;
  description?: string;
  regulatory_body_id?: string;
  event_type: string;
  due_date: string;
  reminder_days: number[];
  department_id?: string;
  assigned_to?: string;
  status: string;
  completed_at?: string;
  completed_by?: string;
  recurrence: string;
  source_table?: string;
  source_id?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface ComplianceDashboard {
  accreditation_scores: AccreditationScore[];
  department_scores: DepartmentComplianceScore[];
  upcoming_deadlines: ComplianceCalendarEvent[];
  overdue_items: number;
  total_checklists: number;
  compliant_checklists: number;
  license_expiring_soon: number;
}

export interface AccreditationScore {
  body: string;
  total_standards: number;
  compliant: number;
  non_compliant: number;
  score_percent: number;
}

export interface DepartmentComplianceScore {
  department_id: string;
  department_name: string;
  avg_score: number;
  checklist_count: number;
}

export interface ComplianceGap {
  checklist_id: string;
  checklist_name: string;
  department_id?: string;
  department_name?: string;
  accreditation_body: string;
  non_compliant_items: number;
  gap_descriptions: string[];
}

export interface CreateChecklistRequest {
  department_id?: string;
  accreditation_body: string;
  standard_code: string;
  name: string;
  description?: string;
  assessment_period_start: string;
  assessment_period_end: string;
  next_review_date?: string;
  notes?: string;
}

export interface UpdateChecklistRequest {
  overall_status?: ComplianceChecklistStatus;
  compliance_score?: number;
  next_review_date?: string;
  notes?: string;
}

export interface ChecklistItemInput {
  id?: string;
  item_number: number;
  criterion: string;
  status: ComplianceChecklistStatus;
  evidence_summary?: string;
  evidence_documents?: unknown[];
  gap_description?: string;
  corrective_action?: string;
  target_date?: string;
  responsible_user_id?: string;
}

export interface CreateAdrRequest {
  patient_id?: string;
  reporter_type?: string;
  drug_name: string;
  drug_generic_name?: string;
  drug_batch_number?: string;
  manufacturer?: string;
  reaction_description: string;
  onset_date?: string;
  reaction_date: string;
  severity: AdverseEventSeverity;
  outcome?: string;
  causality_assessment?: string;
  seriousness_criteria?: unknown[];
  dechallenge?: string;
  rechallenge?: string;
  concomitant_drugs?: unknown[];
  relevant_history?: string;
}

export interface UpdateAdrRequest {
  reaction_description?: string;
  severity?: AdverseEventSeverity;
  outcome?: string;
  causality_assessment?: string;
  status?: AdverseEventStatus;
  seriousness_criteria?: unknown[];
  dechallenge?: string;
  rechallenge?: string;
  concomitant_drugs?: unknown[];
  relevant_history?: string;
}

export interface CreateMvRequest {
  patient_id?: string;
  device_name: string;
  device_manufacturer?: string;
  device_model?: string;
  device_batch?: string;
  event_description: string;
  event_date: string;
  severity: AdverseEventSeverity;
  patient_outcome?: string;
  device_action?: string;
  investigation_findings?: string;
  corrective_action?: string;
}

export interface UpdateMvRequest {
  event_description?: string;
  severity?: AdverseEventSeverity;
  patient_outcome?: string;
  device_action?: string;
  status?: AdverseEventStatus;
  investigation_findings?: string;
  corrective_action?: string;
}

export interface CreatePcpndtRequest {
  patient_id: string;
  referral_doctor_id?: string;
  performing_doctor_id: string;
  procedure_type: string;
  indication: string;
  gestational_age_weeks?: number;
  lmp_date?: string;
  declaration_text?: string;
  patient_consent_id?: string;
}

export interface UpdatePcpndtRequest {
  status?: PcpndtFormStatus;
  registered_with?: string;
  registration_date?: string;
  quarterly_report_included?: boolean;
}

export interface CreateCalendarEventRequest {
  title: string;
  description?: string;
  regulatory_body_id?: string;
  event_type: string;
  due_date: string;
  reminder_days?: number[];
  department_id?: string;
  assigned_to?: string;
  recurrence?: string;
}

export interface UpdateCalendarEventRequest {
  title?: string;
  description?: string;
  due_date?: string;
  status?: string;
  assigned_to?: string;
  recurrence?: string;
}

export interface PcpndtQuarterlySummary {
  quarter_start: string;
  total_forms: number;
  by_procedure_type: { procedure_type: string; count: number }[];
}

// ── Order Sets ─────────────────────────────────────────────

export type OrderSetContext = "general" | "admission" | "pre_operative" | "diagnosis_specific" | "department_specific";
export type OrderSetItemType = "lab" | "medication" | "nursing" | "diet";

export interface OrderSetTemplate {
  id: string;
  tenant_id: string;
  name: string;
  code: string | null;
  description: string | null;
  context: OrderSetContext;
  department_id: string | null;
  trigger_diagnoses: string[] | null;
  surgery_type: string | null;
  version: number;
  is_current: boolean;
  parent_template_id: string | null;
  is_active: boolean;
  created_by: string | null;
  approved_by: string | null;
  approved_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface OrderSetTemplateItem {
  id: string;
  tenant_id: string;
  template_id: string;
  item_type: OrderSetItemType;
  sort_order: number;
  is_mandatory: boolean;
  default_selected: boolean;
  lab_test_id: string | null;
  lab_priority: string | null;
  lab_notes: string | null;
  drug_catalog_id: string | null;
  drug_name: string | null;
  dosage: string | null;
  frequency: string | null;
  duration: string | null;
  route: string | null;
  med_instructions: string | null;
  task_type: string | null;
  task_description: string | null;
  task_frequency: string | null;
  diet_template_id: string | null;
  diet_type: string | null;
  diet_instructions: string | null;
  created_at: string;
}

export interface OrderSetActivation {
  id: string;
  tenant_id: string;
  template_id: string;
  template_version: number;
  encounter_id: string | null;
  patient_id: string;
  admission_id: string | null;
  activated_by: string | null;
  diagnosis_icd: string | null;
  total_items: number;
  selected_items: number;
  notes: string | null;
  created_at: string;
}

export interface OrderSetActivationItem {
  id: string;
  tenant_id: string;
  activation_id: string;
  template_item_id: string | null;
  item_type: OrderSetItemType;
  was_selected: boolean;
  skip_reason: string | null;
  lab_order_id: string | null;
  prescription_id: string | null;
  nursing_task_id: string | null;
  diet_order_id: string | null;
  created_at: string;
}

export interface OrderSetUsageStats {
  id: string;
  tenant_id: string;
  template_id: string;
  period_start: string;
  period_end: string;
  activation_count: number;
  unique_doctors: number;
  items_ordered: number;
  items_skipped: number;
  completion_rate: number;
}

export interface TemplateWithItems {
  template: OrderSetTemplate;
  items: OrderSetTemplateItem[];
}

export interface ActivationWithItems {
  activation: OrderSetActivation;
  items: OrderSetActivationItem[];
}

export interface ActivationCounts {
  lab_orders: number;
  prescriptions: number;
  nursing_tasks: number;
  diet_orders: number;
}

export interface ActivationResult {
  activation: OrderSetActivation;
  items_created: ActivationCounts;
}

export interface OrderSetAnalyticsSummary {
  total_templates: number;
  total_activations: number;
  unique_doctors: number;
  avg_completion_rate: number;
}

export interface CreateOrderSetTemplateRequest {
  name: string;
  code?: string;
  description?: string;
  context: OrderSetContext;
  department_id?: string;
  trigger_diagnoses?: string[];
  surgery_type?: string;
}

export interface UpdateOrderSetTemplateRequest {
  name?: string;
  code?: string;
  description?: string;
  context?: OrderSetContext;
  department_id?: string;
  trigger_diagnoses?: string[];
  surgery_type?: string;
}

export interface AddOrderSetItemRequest {
  item_type: OrderSetItemType;
  sort_order?: number;
  is_mandatory?: boolean;
  default_selected?: boolean;
  lab_test_id?: string;
  lab_priority?: string;
  lab_notes?: string;
  drug_catalog_id?: string;
  drug_name?: string;
  dosage?: string;
  frequency?: string;
  duration?: string;
  route?: string;
  med_instructions?: string;
  task_type?: string;
  task_description?: string;
  task_frequency?: string;
  diet_template_id?: string;
  diet_type?: string;
  diet_instructions?: string;
}

export interface UpdateOrderSetItemRequest {
  sort_order?: number;
  is_mandatory?: boolean;
  default_selected?: boolean;
  lab_test_id?: string;
  lab_priority?: string;
  lab_notes?: string;
  drug_catalog_id?: string;
  drug_name?: string;
  dosage?: string;
  frequency?: string;
  duration?: string;
  route?: string;
  med_instructions?: string;
  task_type?: string;
  task_description?: string;
  task_frequency?: string;
  diet_template_id?: string;
  diet_type?: string;
  diet_instructions?: string;
}

export interface ActivateOrderSetRequest {
  template_id: string;
  encounter_id?: string;
  patient_id: string;
  admission_id?: string;
  diagnosis_icd?: string;
  notes?: string;
  items: { template_item_id: string; selected: boolean; skip_reason?: string }[];
}

// ── Insurance & TPA ─────────────────────────────────────

export type VerificationStatus = "pending" | "active" | "inactive" | "unknown" | "error";
export type PriorAuthStatus =
  | "draft"
  | "pending_info"
  | "submitted"
  | "in_review"
  | "approved"
  | "partially_approved"
  | "denied"
  | "expired"
  | "cancelled";
export type PaUrgency = "standard" | "urgent" | "retrospective";
export type AppealStatus = "draft" | "submitted" | "in_review" | "upheld" | "overturned" | "withdrawn";

export interface InsuranceVerification {
  id: string;
  tenant_id: string;
  patient_id: string;
  patient_insurance_id: string;
  trigger_point: string;
  trigger_entity_id: string | null;
  status: VerificationStatus;
  verified_at: string | null;
  payer_name: string | null;
  payer_id: string | null;
  member_id: string | null;
  group_number: string | null;
  subscriber_name: string | null;
  relationship_to_subscriber: string | null;
  coverage_start: string | null;
  coverage_end: string | null;
  benefits: Record<string, unknown> | null;
  individual_deductible: number | null;
  individual_deductible_met: number | null;
  family_deductible: number | null;
  family_deductible_met: number | null;
  co_pay_percent: number | null;
  co_insurance_percent: number | null;
  out_of_pocket_max: number | null;
  out_of_pocket_met: number | null;
  scheme_type: string | null;
  scheme_balance: number | null;
  error_code: string | null;
  error_message: string | null;
  raw_response: unknown | null;
  notes: string | null;
  verified_by: string | null;
  created_at: string;
}

export interface PriorAuthRequestRow {
  id: string;
  tenant_id: string;
  pa_number: string;
  patient_id: string;
  patient_insurance_id: string;
  service_type: string;
  service_code: string | null;
  service_description: string | null;
  diagnosis_codes: string[] | null;
  ordering_doctor_id: string | null;
  department_id: string | null;
  encounter_id: string | null;
  invoice_id: string | null;
  insurance_claim_id: string | null;
  status: PriorAuthStatus;
  urgency: PaUrgency;
  requested_start: string | null;
  requested_end: string | null;
  requested_units: number | null;
  estimated_cost: number | null;
  auth_number: string | null;
  approved_start: string | null;
  approved_end: string | null;
  approved_units: number | null;
  approved_amount: number | null;
  denial_reason: string | null;
  denial_code: string | null;
  submitted_at: string | null;
  responded_at: string | null;
  expires_at: string | null;
  expected_tat_hours: number | null;
  escalated: boolean;
  escalated_at: string | null;
  created_by: string | null;
  submitted_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface PriorAuthDocument {
  id: string;
  tenant_id: string;
  prior_auth_id: string;
  document_type: string;
  file_name: string | null;
  file_path: string | null;
  file_size_bytes: number | null;
  mime_type: string | null;
  content_text: string | null;
  content_json: unknown | null;
  source_entity: string | null;
  source_id: string | null;
  uploaded_by: string | null;
  created_at: string;
}

export interface PriorAuthStatusLog {
  id: string;
  tenant_id: string;
  prior_auth_id: string;
  from_status: PriorAuthStatus | null;
  to_status: PriorAuthStatus;
  notes: string | null;
  changed_by: string | null;
  created_at: string;
}

export interface PriorAuthAppeal {
  id: string;
  tenant_id: string;
  prior_auth_id: string;
  appeal_number: string;
  level: number;
  status: AppealStatus;
  reason: string | null;
  clinical_rationale: string | null;
  supporting_evidence: string | null;
  letter_content: string | null;
  payer_decision: string | null;
  payer_response_date: string | null;
  payer_notes: string | null;
  submitted_at: string | null;
  resolved_at: string | null;
  deadline: string | null;
  created_by: string | null;
  submitted_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface PaRequirementRule {
  id: string;
  tenant_id: string;
  rule_name: string;
  description: string | null;
  insurance_provider: string | null;
  scheme_type: string | null;
  tpa_name: string | null;
  service_type: string | null;
  charge_code: string | null;
  charge_code_pattern: string | null;
  cost_threshold: number | null;
  los_threshold: number | null;
  priority: number;
  is_active: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface InsuranceDashboard {
  total_verifications: number;
  active_verifications: number;
  total_prior_auths: number;
  pending_prior_auths: number;
  approved_prior_auths: number;
  denied_prior_auths: number;
  denial_rate_percent: number;
  pending_appeals: number;
  avg_tat_hours: number | null;
  expiring_soon: PriorAuthRequestRow[];
  top_denial_reasons: { reason: string; count: number }[];
}

export interface PaCheckResult {
  required: boolean;
  matching_rule_id: string | null;
  rule_name: string | null;
}

export interface PriorAuthDetail {
  prior_auth: PriorAuthRequestRow;
  documents: PriorAuthDocument[];
  status_log: PriorAuthStatusLog[];
  appeals: PriorAuthAppeal[];
}

// Request types

export interface RunVerificationRequest {
  patient_id: string;
  patient_insurance_id: string;
  trigger_point: string;
  trigger_entity_id?: string;
}

export interface CreatePriorAuthRequestBody {
  patient_id: string;
  patient_insurance_id: string;
  service_type: string;
  service_code?: string;
  service_description?: string;
  diagnosis_codes?: string[];
  ordering_doctor_id?: string;
  department_id?: string;
  encounter_id?: string;
  invoice_id?: string;
  insurance_claim_id?: string;
  urgency?: PaUrgency;
  requested_start?: string;
  requested_end?: string;
  requested_units?: number;
  estimated_cost?: number;
}

export interface UpdatePriorAuthRequestBody {
  service_type?: string;
  service_code?: string;
  service_description?: string;
  diagnosis_codes?: string[];
  urgency?: PaUrgency;
  requested_start?: string;
  requested_end?: string;
  requested_units?: number;
  estimated_cost?: number;
}

export interface RespondPriorAuthRequest {
  status: PriorAuthStatus;
  auth_number?: string;
  approved_start?: string;
  approved_end?: string;
  approved_units?: number;
  approved_amount?: number;
  denial_reason?: string;
  denial_code?: string;
  notes?: string;
}

export interface CheckPaRequiredRequest {
  patient_id: string;
  service_type: string;
  charge_code?: string;
  estimated_cost?: number;
  expected_los?: number;
}

export interface AttachDocumentRequest {
  document_type: string;
  file_name?: string;
  file_path?: string;
  file_size_bytes?: number;
  mime_type?: string;
  content_text?: string;
  content_json?: unknown;
  source_entity?: string;
  source_id?: string;
}

export interface CreateAppealRequest {
  prior_auth_id: string;
  reason?: string;
  clinical_rationale?: string;
  supporting_evidence?: string;
  letter_content?: string;
}

export interface UpdateAppealRequest {
  status?: AppealStatus;
  reason?: string;
  clinical_rationale?: string;
  supporting_evidence?: string;
  letter_content?: string;
  payer_decision?: string;
  payer_response_date?: string;
  payer_notes?: string;
}

export interface CreatePaRuleRequest {
  rule_name: string;
  description?: string;
  insurance_provider?: string;
  scheme_type?: string;
  tpa_name?: string;
  service_type?: string;
  charge_code?: string;
  charge_code_pattern?: string;
  cost_threshold?: number;
  los_threshold?: number;
  priority?: number;
  is_active?: boolean;
}

export interface UpdatePaRuleRequest {
  rule_name?: string;
  description?: string;
  insurance_provider?: string;
  scheme_type?: string;
  tpa_name?: string;
  service_type?: string;
  charge_code?: string;
  charge_code_pattern?: string;
  cost_threshold?: number;
  los_threshold?: number;
  priority?: number;
  is_active?: boolean;
}

// ──────────────────────────────────────────────────────────
//  IPD Phase 2b — Types & Enums
// ──────────────────────────────────────────────────────────

export type IpType = "general" | "semi_private" | "private" | "deluxe" | "suite" | "icu" | "nicu" | "picu" | "hdu" | "isolation" | "nursery";
export type BedReservationStatus = "active" | "confirmed" | "cancelled" | "expired" | "fulfilled";
export type IpdClinicalDocType = "wound_care" | "central_line" | "catheter" | "drain" | "restraint" | "transfusion" | "clinical_pathway" | "other" | "elopement_risk" | "dialysis" | "endoscopy" | "chemotherapy" | "blood_transfusion_checklist";
export type RestraintCheckStatus = "circulation_ok" | "skin_intact" | "repositioned" | "released" | "escalated";
export type TransferType = "inter_ward" | "inter_department" | "inter_hospital";
export type DeathCertFormType = "form_4" | "form_4a";
export type OtConsumableCategory = "surgical_instrument" | "implant" | "disposable" | "suture" | "drug" | "blood_product" | "other";

export interface IpTypeConfiguration {
  id: string; tenant_id: string; ip_type: IpType; label: string;
  daily_rate: number | null; nursing_charge: number | null; deposit_required: number | null;
  description: string | null; is_active: boolean;
  billing_alert_threshold: number | null; auto_billing_enabled: boolean;
  created_at: string; updated_at: string;
}

export interface AdmissionChecklist {
  id: string; tenant_id: string; admission_id: string;
  item_label: string; category: string | null; is_completed: boolean;
  completed_by: string | null; completed_at: string | null;
  sort_order: number; notes: string | null;
  created_at: string; updated_at: string;
}

export interface BedReservation {
  id: string; tenant_id: string; bed_id: string; patient_id: string | null;
  reserved_by: string; status: BedReservationStatus;
  reserved_from: string; reserved_until: string;
  purpose: string | null; notes: string | null;
  cancelled_by: string | null; cancelled_at: string | null;
  created_at: string; updated_at: string;
}

export interface BedTurnaroundLog {
  id: string; tenant_id: string; bed_id: string; admission_id: string | null;
  vacated_at: string | null; cleaning_started_at: string | null;
  cleaning_completed_at: string | null; ready_at: string | null;
  turnaround_minutes: number | null; cleaned_by: string | null;
  notes: string | null; created_at: string;
}

export interface IpdClinicalDocumentation {
  id: string; tenant_id: string; admission_id: string; patient_id: string;
  doc_type: IpdClinicalDocType; title: string; body: unknown;
  recorded_by: string; recorded_at: string;
  next_review_at: string | null; is_resolved: boolean;
  resolved_at: string | null; resolved_by: string | null;
  notes: string | null; created_at: string; updated_at: string;
}

export interface RestraintMonitoringLog {
  id: string; tenant_id: string; admission_id: string;
  clinical_doc_id: string; check_time: string;
  status: RestraintCheckStatus;
  circulation_status: string | null; skin_status: string | null;
  patient_response: string | null; checked_by: string;
  notes: string | null; created_at: string;
}

export interface IpdTransferLog {
  id: string; tenant_id: string; admission_id: string;
  transfer_type: TransferType;
  from_ward_id: string | null; to_ward_id: string | null;
  from_bed_id: string | null; to_bed_id: string | null;
  reason: string | null; clinical_summary: string | null;
  transferred_by: string; transferred_at: string;
  notes: string | null; created_at: string;
}

export interface IpdDeathSummary {
  id: string; tenant_id: string; admission_id: string; patient_id: string;
  date_of_death: string; time_of_death: string;
  cause_of_death_primary: string | null; cause_of_death_secondary: string | null;
  cause_of_death_tertiary: string | null; cause_of_death_underlying: string | null;
  manner_of_death: string | null; duration_of_illness: string | null;
  autopsy_requested: boolean; is_medico_legal: boolean;
  form_type: DeathCertFormType;
  certifying_doctor_id: string | null; witness_name: string | null;
  notes: string | null; created_at: string; updated_at: string;
}

export interface IpdBirthRecord {
  id: string; tenant_id: string; admission_id: string;
  mother_patient_id: string; baby_patient_id: string | null;
  date_of_birth: string; time_of_birth: string;
  gender: string | null; weight_grams: number | null;
  length_cm: number | null; head_circumference_cm: number | null;
  apgar_1min: number | null; apgar_5min: number | null;
  delivery_type: string | null; is_live_birth: boolean;
  birth_certificate_number: string | null;
  complications: string | null; notes: string | null;
  created_at: string; updated_at: string;
}

export interface IpdDischargeTatLog {
  id: string; tenant_id: string; admission_id: string;
  discharge_initiated_at: string | null; billing_cleared_at: string | null;
  pharmacy_cleared_at: string | null; nursing_cleared_at: string | null;
  doctor_cleared_at: string | null; discharge_completed_at: string | null;
  total_tat_minutes: number | null; notes: string | null;
  created_at: string; updated_at: string;
}

export interface OtConsumableUsage {
  id: string; tenant_id: string; booking_id: string;
  item_name: string; category: OtConsumableCategory;
  quantity: number; unit: string | null;
  unit_price: number | null; batch_number: string | null;
  recorded_by: string; notes: string | null;
  created_at: string;
}

export interface RoomUtilization {
  room_id: string; room_name: string;
  total_bookings: number;
  total_surgery_minutes: number | null;
  avg_turnaround_minutes: number | null;
}

// Request types — IPD Phase 2b

export interface CreateIpTypeRequest {
  ip_type: IpType; label: string;
  daily_rate?: number; nursing_charge?: number; deposit_required?: number;
  description?: string;
  billing_alert_threshold?: number; auto_billing_enabled?: boolean;
}

export interface UpdateIpTypeRequest {
  label?: string;
  daily_rate?: number; nursing_charge?: number; deposit_required?: number;
  description?: string; is_active?: boolean;
  billing_alert_threshold?: number; auto_billing_enabled?: boolean;
}

export interface CreateChecklistItemsRequest {
  items: { item_label: string; category?: string; sort_order?: number; notes?: string }[];
}

export interface ToggleChecklistItemRequest {
  is_completed: boolean;
  notes?: string;
}

export interface CreateBedReservationRequest {
  bed_id: string; patient_id?: string;
  reserved_from: string; reserved_until: string;
  purpose?: string; notes?: string;
}

export interface UpdateBedReservationStatusRequest {
  status: BedReservationStatus;
}

export interface CreateBedTurnaroundRequest {
  bed_id: string; admission_id?: string;
  vacated_at?: string; notes?: string;
}

export interface CreateClinicalDocRequest {
  doc_type: IpdClinicalDocType; title: string;
  body?: unknown; next_review_at?: string; notes?: string;
}

export interface UpdateClinicalDocRequest {
  title?: string; body?: unknown;
  next_review_at?: string; notes?: string;
}

export interface CreateRestraintCheckRequest {
  clinical_doc_id: string;
  status: RestraintCheckStatus;
  circulation_status?: string; skin_status?: string;
  patient_response?: string; notes?: string;
}

export interface CreateTransferRequest {
  transfer_type: TransferType;
  from_ward_id?: string; to_ward_id?: string;
  from_bed_id?: string; to_bed_id?: string;
  reason?: string; clinical_summary?: string; notes?: string;
}

export interface CreateDeathSummaryRequest {
  patient_id: string;
  date_of_death: string; time_of_death: string;
  cause_of_death_primary?: string; cause_of_death_secondary?: string;
  cause_of_death_tertiary?: string; cause_of_death_underlying?: string;
  manner_of_death?: string; duration_of_illness?: string;
  autopsy_requested?: boolean; is_medico_legal?: boolean;
  form_type?: DeathCertFormType;
  certifying_doctor_id?: string; witness_name?: string; notes?: string;
}

export interface UpdateDeathSummaryRequest {
  date_of_death?: string; time_of_death?: string;
  cause_of_death_primary?: string; cause_of_death_secondary?: string;
  cause_of_death_tertiary?: string; cause_of_death_underlying?: string;
  manner_of_death?: string; duration_of_illness?: string;
  autopsy_requested?: boolean; is_medico_legal?: boolean;
  form_type?: DeathCertFormType;
  certifying_doctor_id?: string; witness_name?: string; notes?: string;
}

export interface CreateBirthRecordRequest {
  mother_patient_id: string; baby_patient_id?: string;
  date_of_birth: string; time_of_birth: string;
  gender?: string; weight_grams?: number;
  length_cm?: number; head_circumference_cm?: number;
  apgar_1min?: number; apgar_5min?: number;
  delivery_type?: string; is_live_birth?: boolean;
  birth_certificate_number?: string;
  complications?: string; notes?: string;
}

export interface UpdateBirthRecordRequest {
  baby_patient_id?: string;
  date_of_birth?: string; time_of_birth?: string;
  gender?: string; weight_grams?: number;
  length_cm?: number; head_circumference_cm?: number;
  apgar_1min?: number; apgar_5min?: number;
  delivery_type?: string; is_live_birth?: boolean;
  birth_certificate_number?: string;
  complications?: string; notes?: string;
}

export interface InitDischargeTatRequest {
  notes?: string;
}

export interface UpdateDischargeTatRequest {
  billing_cleared_at?: string;
  pharmacy_cleared_at?: string;
  nursing_cleared_at?: string;
  doctor_cleared_at?: string;
  discharge_completed_at?: string;
  notes?: string;
}

export interface CreateOtConsumableRequest {
  item_name: string; category: OtConsumableCategory;
  quantity: number; unit?: string;
  unit_price?: number; batch_number?: string; notes?: string;
}

// ── IPD Phase 3a Response Types ────────────────────────────

export interface LabOrderSummary {
  id: string; test_name: string; ordered_at: string; status: string;
}

export interface LabResultSummary {
  id: string; order_id: string; parameter_name: string;
  value: string | null; unit: string | null;
  reference_range: string | null; is_abnormal: boolean;
}

export interface RadiologyOrderSummary {
  id: string; modality: string; body_part: string | null;
  ordered_at: string; status: string; findings: string | null;
}

export interface InvestigationsResponse {
  lab_orders: LabOrderSummary[];
  lab_results: LabResultSummary[];
  radiology_orders: RadiologyOrderSummary[];
}

export interface EstimatedCostResponse {
  daily_rate: number; nursing_charge: number; estimated_days: number;
  room_total: number; nursing_total: number;
  deposit_required: number; total_estimated: number;
}

export interface DeptChargeGroup {
  department_name: string; total: number;
}

export interface BillingSummaryResponse {
  charges_by_dept: DeptChargeGroup[];
  total_charges: number; total_payments: number; outstanding_balance: number;
}

export interface AdmissionPrintData {
  patient_name: string; uhid: string;
  age: number | null; gender: string | null;
  admission_date: string; bed_number: string | null;
  ward_name: string | null; department_name: string | null;
  doctor_name: string | null; ip_type: string | null;
  provisional_diagnosis: string | null;
}

export interface SurgeonCaseloadEntry {
  surgeon_id: string; surgeon_name: string;
  total_cases: number; avg_duration_minutes: number | null;
  complication_count: number; cancellation_count: number;
}

export interface AnesthesiaComplicationEntry {
  case_id: string; patient_name: string;
  procedure_name: string; anesthesia_type: string;
  complications: string | null;
  adverse_events: unknown;
  case_date: string;
}

export interface LinkMlcRequest {
  mlc_case_id: string;
}

// ── Care View / Ward Dashboard ──────────────────────────

export interface PatientCardRow {
  admission_id: string;
  patient_id: string;
  encounter_id: string;
  patient_name: string;
  uhid: string;
  bed_id: string | null;
  bed_name: string | null;
  ward_id: string | null;
  ward_name: string | null;
  is_critical: boolean;
  isolation_required: boolean;
  ip_type: string | null;
  admitting_doctor_name: string | null;
  primary_nurse_name: string | null;
  pending_tasks: number;
  overdue_tasks: number;
  pending_meds: number;
  overdue_meds: number;
  vitals_due: boolean;
  fall_risk_level: string | null;
  latest_news2_score: number | null;
  active_clinical_docs: number;
  expected_discharge_date: string | null;
}

export interface WardSummary {
  total_beds: number;
  occupied: number;
  critical_count: number;
  isolation_count: number;
  pending_discharges: number;
  overdue_tasks_total: number;
}

export interface WardGridResponse {
  patients: PatientCardRow[];
  summary: WardSummary;
}

export interface NurseTaskItem {
  task_id: string;
  admission_id: string;
  patient_name: string;
  bed_name: string | null;
  description: string;
  category: string | null;
  priority: string;
  due_at: string | null;
  is_overdue: boolean;
}

export interface MedAdminItem {
  mar_id: string;
  admission_id: string;
  patient_name: string;
  bed_name: string | null;
  drug_name: string;
  dose: string;
  route: string;
  scheduled_at: string;
  is_overdue: boolean;
  is_high_alert: boolean;
}

export interface MyTasksResponse {
  nursing_tasks: NurseTaskItem[];
  medication_tasks: MedAdminItem[];
}

export interface VitalsChecklistRow {
  admission_id: string;
  patient_name: string;
  bed_name: string | null;
  last_vitals_at: string | null;
  hours_since_last: number | null;
  vitals_due: boolean;
}

export interface HandoverSummaryPatient {
  admission_id: string;
  patient_name: string;
  bed_name: string | null;
  is_critical: boolean;
  isolation_required: boolean;
  provisional_diagnosis: string | null;
  pending_tasks: string[];
  pending_meds: string[];
  active_clinical_docs: string[];
}

export interface HandoverSummaryResponse {
  ward_name: string;
  shift: string;
  patients: HandoverSummaryPatient[];
  total_patients: number;
  critical_count: number;
}

export interface DischargeReadinessRow {
  admission_id: string;
  patient_name: string;
  uhid: string;
  bed_name: string | null;
  ward_name: string | null;
  expected_discharge_date: string | null;
  billing_cleared: boolean;
  pharmacy_cleared: boolean;
  nursing_cleared: boolean;
  doctor_cleared: boolean;
  pending_lab_count: number;
  readiness_pct: number;
}

export interface UpdatePrimaryNurseRequest {
  primary_nurse_id: string | null;
}

// ══════════════════════════════════════════════════════════
//  Chronic Care / Drug-o-gram
// ══════════════════════════════════════════════════════════

export type ChronicProgramType =
  | "tb_dots" | "hiv_art" | "diabetes" | "hypertension" | "ckd" | "copd"
  | "asthma" | "cancer_chemo" | "mental_health" | "epilepsy" | "thyroid" | "rheumatic" | "other";

export type EnrollmentStatus =
  | "active" | "completed" | "discontinued" | "transferred" | "lost_to_followup" | "deceased";

export type MedicationEventType =
  | "started" | "dose_changed" | "switched" | "discontinued" | "resumed" | "held";

export type AdherenceEventType =
  | "dose_taken" | "dose_missed" | "dose_late"
  | "refill_on_time" | "refill_late" | "refill_missed"
  | "appointment_attended" | "appointment_missed" | "appointment_rescheduled";

export interface ChronicProgram {
  id: string;
  tenant_id: string;
  name: string;
  code: string;
  program_type: ChronicProgramType;
  description: string | null;
  protocol_id: string | null;
  default_duration_months: number | null;
  target_outcomes: unknown[];
  monitoring_schedule: unknown[];
  is_active: boolean;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface ChronicEnrollmentRow {
  id: string;
  patient_id: string;
  program_id: string;
  patient_name: string;
  uhid: string;
  program_name: string;
  program_type: string;
  enrollment_date: string;
  expected_end_date: string | null;
  actual_end_date: string | null;
  status: EnrollmentStatus;
  status_reason: string | null;
  primary_doctor_name: string | null;
  icd_code: string | null;
  notes: string | null;
  target_overrides: unknown | null;
  created_at: string;
}

export interface MedicationTimelineEvent {
  id: string;
  event_type: MedicationEventType;
  drug_name: string;
  generic_name: string | null;
  atc_code: string | null;
  dosage: string | null;
  frequency: string | null;
  route: string | null;
  previous_dosage: string | null;
  previous_frequency: string | null;
  change_reason: string | null;
  switched_from_drug: string | null;
  effective_date: string;
  end_date: string | null;
  ordered_by_name: string;
  is_auto_generated: boolean;
  enrollment_id: string | null;
  created_at: string;
}

export interface LabTimelinePoint {
  result_id: string;
  parameter_name: string;
  value: string;
  numeric_value: number | null;
  unit: string | null;
  flag: string | null;
  result_date: string;
  loinc_code: string | null;
}

export interface LabSeriesGroup {
  parameter_name: string;
  loinc_code: string | null;
  unit: string | null;
  target_value: number | null;
  data_points: LabTimelinePoint[];
}

export interface VitalTimelinePoint {
  id: string;
  parameter: string;
  value: string;
  numeric_value: number | null;
  recorded_at: string;
}

export interface ActiveDrugRow {
  drug_name: string;
  generic_name: string | null;
  dosage: string | null;
  frequency: string | null;
  route: string | null;
  started_date: string;
}

export interface DrugTimelineWithLabsResponse {
  medication_events: MedicationTimelineEvent[];
  lab_series: LabSeriesGroup[];
  vitals_series: VitalTimelinePoint[];
  active_drugs: ActiveDrugRow[];
}

export interface AdherenceRow {
  id: string;
  event_type: AdherenceEventType;
  event_date: string;
  drug_name: string | null;
  recorded_by_name: string;
  notes: string | null;
  created_at: string;
}

export interface MonthlyAdherence {
  month: string;
  taken: number;
  missed: number;
  late: number;
}

export interface AdherenceSummaryResponse {
  doses_taken: number;
  doses_missed: number;
  doses_late: number;
  dose_adherence_pct: number;
  refills_on_time: number;
  refills_late: number;
  refills_missed: number;
  appointments_attended: number;
  appointments_missed: number;
  appointments_rescheduled: number;
  by_month: MonthlyAdherence[];
}

export interface PatientOutcomeTarget {
  id: string;
  parameter_name: string;
  loinc_code: string | null;
  target_value: number;
  unit: string;
  comparison: string;
  effective_from: string;
  notes: string | null;
  enrollment_id: string | null;
}

export interface OutcomeTargetWithActual {
  target: PatientOutcomeTarget;
  latest_value: number | null;
  latest_date: string | null;
  at_target: boolean | null;
}

export interface OutcomeDashboardResponse {
  targets: OutcomeTargetWithActual[];
  adherence_rate: number | null;
  enrollment_duration_days: number | null;
  active_enrollments: number;
}

export interface PolypharmacyInteractionAlert {
  id: string;
  drug_a_name: string;
  drug_b_name: string;
  severity: string;
  description: string | null;
  management: string | null;
  status: string;
  acknowledged_by: string | null;
  acknowledged_at: string | null;
  override_reason: string | null;
  detected_at: string;
}

export interface DiagnosisSummaryItem {
  diagnosis_name: string;
  icd_code: string | null;
  diagnosed_date: string | null;
}

export interface ChronicEnrollmentSummary {
  program_name: string;
  enrollment_date: string;
  status: string;
}

export interface TreatmentSummaryResponse {
  patient_name: string;
  uhid: string;
  date_of_birth: string | null;
  gender: string | null;
  active_diagnoses: DiagnosisSummaryItem[];
  current_medications: ActiveDrugRow[];
  lab_trends: LabSeriesGroup[];
  targets: OutcomeTargetWithActual[];
  adherence_rate: number | null;
  enrollments: ChronicEnrollmentSummary[];
}

// ── Chronic Care Requests ────────────────────────────────

export interface CreateChronicProgramRequest {
  name: string;
  code: string;
  program_type: ChronicProgramType;
  description?: string;
  protocol_id?: string;
  default_duration_months?: number;
  target_outcomes?: unknown[];
  monitoring_schedule?: unknown[];
}

export interface CreateChronicEnrollmentRequest {
  patient_id: string;
  program_id: string;
  primary_doctor_id?: string;
  enrollment_date?: string;
  expected_end_date?: string;
  diagnosis_id?: string;
  icd_code?: string;
  target_overrides?: unknown;
  notes?: string;
}

export interface UpdateEnrollmentStatusRequest {
  status: EnrollmentStatus;
  status_reason?: string;
}

export interface CreateTimelineEventRequest {
  patient_id: string;
  enrollment_id?: string;
  prescription_item_id?: string;
  encounter_id?: string;
  event_type: MedicationEventType;
  drug_name: string;
  generic_name?: string;
  atc_code?: string;
  catalog_item_id?: string;
  dosage?: string;
  frequency?: string;
  route?: string;
  previous_dosage?: string;
  previous_frequency?: string;
  change_reason?: string;
  switched_from_drug?: string;
  effective_date?: string;
  end_date?: string;
}

export interface RecordAdherenceRequest {
  patient_id: string;
  enrollment_id: string;
  event_type: AdherenceEventType;
  event_date?: string;
  drug_name?: string;
  appointment_id?: string;
  pharmacy_order_id?: string;
  notes?: string;
}

export interface CreateOutcomeTargetRequest {
  patient_id: string;
  enrollment_id?: string;
  parameter_name: string;
  loinc_code?: string;
  target_value: number;
  unit: string;
  comparison: string;
  effective_from?: string;
  notes?: string;
}

export interface UpdateOutcomeTargetRequest {
  target_value?: number;
  comparison?: string;
  notes?: string;
}

// ══════════════════════════════════════════════════════════
//  Retrospective Data Entry
// ══════════════════════════════════════════════════════════

export type RetrospectiveEntryStatus = 'pending' | 'approved' | 'rejected';

export interface RetrospectiveEntry {
  id: string;
  source_table: string;
  source_record_id: string;
  clinical_event_date: string;
  entry_date: string;
  entered_by: string;
  reason: string;
  status: RetrospectiveEntryStatus;
  reviewed_by?: string;
  reviewed_at?: string;
  review_notes?: string;
  created_at: string;
  entered_by_name?: string;
  reviewed_by_name?: string;
}

export interface RetrospectiveSettings {
  max_backdate_hours: number;
  requires_approval: boolean;
}

export interface CreateRetroEncounterRequest {
  patient_id: string;
  department_id: string;
  doctor_id: string;
  clinical_event_date: string;
  reason: string;
  visit_type?: string;
  chief_complaint?: string;
  notes?: string;
}

export interface ApproveRejectRequest {
  review_notes?: string;
}

// ══════════════════════════════════════════════════════════
//  Occupational Health
// ══════════════════════════════════════════════════════════

export type DrugScreenStatus = 'ordered' | 'collected' | 'sent_to_lab' | 'mro_review' | 'positive' | 'negative' | 'inconclusive' | 'cancelled';
export type RtwClearanceStatus = 'pending_evaluation' | 'cleared_full' | 'cleared_with_restrictions' | 'not_cleared' | 'follow_up_required';

export interface OccHealthScreening {
  id: string;
  tenant_id: string;
  employee_id: string;
  examiner_id?: string;
  screening_type: string;
  screening_date: string;
  fitness_status: string;
  findings: Record<string, unknown>;
  restrictions: unknown[];
  next_due_date?: string;
  notes?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

export interface OccHealthDrugScreen {
  id: string;
  tenant_id: string;
  employee_id: string;
  screening_id?: string;
  specimen_id?: string;
  status: DrugScreenStatus;
  chain_of_custody: Record<string, unknown>;
  panel: string;
  results: Record<string, unknown>;
  mro_reviewer_id?: string;
  mro_decision?: string;
  mro_reviewed_at?: string;
  collected_at?: string;
  created_at: string;
  updated_at: string;
}

export interface OccHealthVaccination {
  id: string;
  tenant_id: string;
  employee_id: string;
  vaccine_name: string;
  dose_number: number;
  administered_date: string;
  batch_number?: string;
  administered_by?: string;
  next_due_date?: string;
  is_compliant: boolean;
  exemption_type?: string;
  exemption_reason?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface OccHealthInjuryReport {
  id: string;
  tenant_id: string;
  employee_id: string;
  report_number: string;
  injury_date: string;
  injury_type: string;
  injury_description?: string;
  body_part_affected?: string;
  location_of_incident?: string;
  is_osha_recordable: boolean;
  lost_work_days: number;
  restricted_days: number;
  workers_comp_claim_number?: string;
  workers_comp_status?: string;
  rtw_status: RtwClearanceStatus;
  rtw_restrictions: unknown[];
  rtw_cleared_date?: string;
  rtw_cleared_by?: string;
  employer_access_notes?: string;
  reported_by?: string;
  created_at: string;
  updated_at: string;
}

export interface VaccinationComplianceRow {
  vaccine_name: string;
  total_employees: number;
  compliant_count: number;
  compliance_pct: number;
}

export interface EmployerViewResponse {
  id: string;
  employee_id: string;
  report_number: string;
  injury_date: string;
  injury_type: string;
  is_osha_recordable: boolean;
  lost_work_days: number;
  restricted_days: number;
  rtw_status: RtwClearanceStatus;
  rtw_restrictions: unknown[];
  employer_access_notes?: string;
}

export interface CreateOccScreeningRequest {
  employee_id: string;
  screening_type: string;
  screening_date: string;
  fitness_status?: string;
  findings?: Record<string, unknown>;
  restrictions?: unknown[];
  next_due_date?: string;
  examiner_id?: string;
  notes?: string;
}

export interface UpdateOccScreeningRequest {
  fitness_status?: string;
  findings?: Record<string, unknown>;
  restrictions?: unknown[];
  next_due_date?: string;
  notes?: string;
}

export interface CreateDrugScreenRequest {
  employee_id: string;
  screening_id?: string;
  panel?: string;
}

export interface UpdateDrugScreenRequest {
  status?: DrugScreenStatus;
  results?: Record<string, unknown>;
  mro_decision?: string;
}

export interface CreateVaccinationRequest {
  employee_id: string;
  vaccine_name: string;
  dose_number?: number;
  administered_date: string;
  batch_number?: string;
  next_due_date?: string;
  is_compliant?: boolean;
  exemption_type?: string;
  exemption_reason?: string;
  notes?: string;
}

export interface CreateInjuryRequest {
  employee_id: string;
  injury_date: string;
  injury_type: string;
  injury_description?: string;
  body_part_affected?: string;
  location_of_incident?: string;
  is_osha_recordable?: boolean;
}

export interface UpdateInjuryRequest {
  injury_description?: string;
  is_osha_recordable?: boolean;
  lost_work_days?: number;
  restricted_days?: number;
  workers_comp_claim_number?: string;
  workers_comp_status?: string;
  rtw_status?: RtwClearanceStatus;
  rtw_restrictions?: unknown[];
  employer_access_notes?: string;
}

// ══════════════════════════════════════════════════════════
//  Utilization Review
// ══════════════════════════════════════════════════════════

export type UrReviewType = 'pre_admission' | 'admission' | 'continued_stay' | 'retrospective';
export type UrDecision = 'approved' | 'denied' | 'pending_info' | 'modified' | 'escalated';

export interface UtilizationReview {
  id: string;
  tenant_id: string;
  admission_id: string;
  patient_id: string;
  reviewer_id?: string;
  review_type: UrReviewType;
  review_date: string;
  patient_status: string;
  decision: UrDecision;
  criteria_source?: string;
  criteria_met: unknown[];
  clinical_summary?: string;
  expected_los_days?: number;
  actual_los_days?: number;
  is_outlier: boolean;
  approved_days?: number;
  next_review_date?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface UrPayerCommunication {
  id: string;
  tenant_id: string;
  review_id: string;
  communication_type: string;
  payer_name: string;
  reference_number?: string;
  communicated_at: string;
  summary?: string;
  response?: string;
  attachments: unknown[];
  communicated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface UrStatusConversion {
  id: string;
  tenant_id: string;
  admission_id: string;
  from_status: string;
  to_status: string;
  conversion_date: string;
  reason?: string;
  effective_from: string;
  converted_by?: string;
  created_at: string;
  updated_at: string;
}

export interface UrAnalyticsSummary {
  total_reviews: number;
  avg_expected_los?: number;
  avg_actual_los?: number;
  outlier_count: number;
  denial_count: number;
  approval_rate: number;
}

export interface LosComparisonRow {
  department_name?: string;
  review_count: number;
  avg_expected_los?: number;
  avg_actual_los?: number;
}

export interface CreateUrReviewRequest {
  admission_id: string;
  patient_id: string;
  review_type: UrReviewType;
  patient_status?: string;
  criteria_source?: string;
  criteria_met?: unknown[];
  clinical_summary?: string;
  expected_los_days?: number;
  actual_los_days?: number;
  approved_days?: number;
  next_review_date?: string;
  notes?: string;
}

export interface UpdateUrReviewRequest {
  decision?: UrDecision;
  criteria_met?: unknown[];
  clinical_summary?: string;
  expected_los_days?: number;
  actual_los_days?: number;
  approved_days?: number;
  next_review_date?: string;
  notes?: string;
}

export interface CreateUrCommunicationRequest {
  review_id: string;
  communication_type: string;
  payer_name: string;
  reference_number?: string;
  summary?: string;
}

export interface CreateUrConversionRequest {
  admission_id: string;
  from_status: string;
  to_status: string;
  reason?: string;
}

// ══════════════════════════════════════════════════════════
//  Case Management
// ══════════════════════════════════════════════════════════

export type CaseMgmtStatus = 'assigned' | 'active' | 'pending_discharge' | 'discharged' | 'closed';
export type DischargeBarrierType = 'insurance_auth' | 'placement' | 'equipment' | 'family' | 'transport' | 'financial' | 'clinical' | 'documentation' | 'other';

export interface CaseAssignment {
  id: string;
  tenant_id: string;
  admission_id: string;
  patient_id: string;
  case_manager_id: string;
  status: CaseMgmtStatus;
  priority: string;
  target_discharge_date?: string;
  actual_discharge_date?: string;
  discharge_disposition?: string;
  disposition_details: Record<string, unknown>;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface DischargeBarrier {
  id: string;
  tenant_id: string;
  case_assignment_id: string;
  barrier_type: DischargeBarrierType;
  description: string;
  identified_date: string;
  is_resolved: boolean;
  resolved_date?: string;
  resolved_by?: string;
  escalated_to?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface CaseReferral {
  id: string;
  tenant_id: string;
  case_assignment_id: string;
  referral_type: string;
  referred_to: string;
  status: string;
  facility_details: Record<string, unknown>;
  outcome?: string;
  referred_by?: string;
  created_at: string;
  updated_at: string;
}

export interface CaseloadRow {
  case_manager_id: string;
  active_cases: number;
  pending_discharge: number;
  total_cases: number;
}

export interface DispositionRow {
  disposition?: string;
  count: number;
}

export interface BarrierAnalyticsRow {
  barrier_type: string;
  count: number;
  avg_days_open?: number;
}

export interface OutcomeAnalytics {
  avg_days_to_discharge?: number;
  total_discharged: number;
  total_with_barriers: number;
}

export interface CreateCaseAssignmentRequest {
  admission_id: string;
  patient_id: string;
  case_manager_id: string;
  priority?: string;
  target_discharge_date?: string;
  notes?: string;
}

export interface UpdateCaseAssignmentRequest {
  status?: CaseMgmtStatus;
  priority?: string;
  target_discharge_date?: string;
  actual_discharge_date?: string;
  discharge_disposition?: string;
  disposition_details?: Record<string, unknown>;
  notes?: string;
}

export interface AutoAssignRequest {
  admission_id: string;
  patient_id: string;
  priority?: string;
}

export interface CreateDischargeBarrierRequest {
  case_assignment_id: string;
  barrier_type: DischargeBarrierType;
  description: string;
}

export interface UpdateDischargeBarrierRequest {
  description?: string;
  is_resolved?: boolean;
  escalated_to?: string;
  notes?: string;
}

export interface CreateCaseReferralRequest {
  case_assignment_id: string;
  referral_type: string;
  referred_to: string;
  facility_details?: Record<string, unknown>;
}

export interface UpdateCaseReferralRequest {
  status?: string;
  outcome?: string;
  facility_details?: Record<string, unknown>;
}

// ══════════════════════════════════════════════════════════
//  Scheduling / No-Show AI
// ══════════════════════════════════════════════════════════

export interface NoshowPredictionScore {
  id: string;
  tenant_id: string;
  appointment_id: string;
  patient_id: string;
  predicted_noshow_probability: number;
  risk_level: string;
  features_used: Record<string, unknown>;
  model_version: string;
  scored_at: string;
  created_at: string;
}

export interface SchedulingWaitlistEntry {
  id: string;
  tenant_id: string;
  patient_id: string;
  doctor_id?: string;
  department_id?: string;
  preferred_date_from?: string;
  preferred_date_to?: string;
  preferred_time_from?: string;
  preferred_time_to?: string;
  priority: string;
  status: string;
  offered_appointment_id?: string;
  reason?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
}

export interface SchedulingOverbookingRule {
  id: string;
  tenant_id: string;
  doctor_id: string;
  department_id: string;
  day_of_week: number;
  max_overbook_slots: number;
  overbook_threshold_probability: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface OverbookingRecommendation {
  doctor_id: string;
  department_id: string;
  date: string;
  day_of_week: number;
  max_overbook_slots: number;
  threshold_probability: number;
  recommendation: string;
}

export interface AutoFillResult {
  waiting_count: number;
  message: string;
}

export interface NoshowRateRow {
  doctor_id?: string;
  department_id?: string;
  total_appointments: number;
  noshow_count: number;
  noshow_rate?: number;
}

export interface PredictionAccuracyReport {
  model_version: string;
  total_predictions: number;
  message: string;
}

export interface WaitlistStatsResponse {
  total_waiting: number;
  total_offered: number;
  total_booked: number;
  avg_wait_days?: number;
}

export interface ScoreAppointmentRequest {
  appointment_id: string;
}

export interface ScoreBatchRequest {
  appointment_ids: string[];
}

export interface CreateWaitlistRequest {
  patient_id: string;
  doctor_id?: string;
  department_id?: string;
  preferred_date_from?: string;
  preferred_date_to?: string;
  preferred_time_from?: string;
  preferred_time_to?: string;
  priority?: string;
  reason?: string;
}

export interface UpdateWaitlistRequest {
  preferred_date_from?: string;
  preferred_date_to?: string;
  preferred_time_from?: string;
  preferred_time_to?: string;
  priority?: string;
  status?: string;
}

export interface OfferSlotRequest {
  offered_appointment_id: string;
}

export interface RespondToOfferRequest {
  accept: boolean;
}

export interface CreateOverbookingRuleRequest {
  doctor_id: string;
  department_id: string;
  day_of_week: number;
  max_overbook_slots?: number;
  overbook_threshold_probability?: number;
}

export interface UpdateOverbookingRuleRequest {
  max_overbook_slots?: number;
  overbook_threshold_probability?: number;
  is_active?: boolean;
}

// ══════════════════════════════════════════════════════════
//  Batch 2 Analytics & New Endpoint Types
// ══════════════════════════════════════════════════════════

// Quality — auto-calculate, pending acks, evidence
export interface PendingAckUser {
  user_id: string;
  full_name: string;
}

export interface AutoScheduleRequest {
  months_ahead?: number;
}

export interface EvidenceCompilation {
  accreditation_body: string;
  total_standards: number;
  compliant_count: number;
  compliance_rate: number;
  non_compliant_items: unknown[];
}

// Lab — TAT analytics, auto-validate, crossmatch
export interface LabTatAnalyticsRow {
  test_name: string;
  total_orders: number;
  avg_tat_minutes: number | null;
  p95_tat_minutes: number | null;
  within_sla: number;
}

export interface AutoValidateResult {
  result_id: string;
  auto_validated: boolean;
  message: string;
}

export interface LabCrossmatchLink {
  order_id: string;
  patient_id: string;
  crossmatch_requests: unknown[];
}

// ICU — LOS analytics, device infections
export interface IcuLosAnalytics {
  total_admissions: number;
  avg_los_days: number | null;
  median_los_days: number | null;
  readmission_count: number;
  readmission_rate: number | null;
}

export interface DeviceInfectionRate {
  device_type: string;
  total_device_days: number;
  infection_count: number;
  rate_per_1000: number | null;
}

// BME — MTBF, uptime
export interface BmeMtbfRow {
  equipment_id: string;
  equipment_name: string;
  total_operating_hours: number | null;
  breakdown_count: number;
  mtbf_hours: number | null;
}

export interface BmeUptimeRow {
  equipment_id: string;
  equipment_name: string;
  total_days: number | null;
  downtime_days: number | null;
  uptime_percent: number | null;
}

// Blood Bank — TTI report, hemovigilance
export interface TtiReportRow {
  tti_status: string;
  count: number;
}

export interface TtiReport {
  total_components: number;
  by_status: TtiReportRow[];
}

export interface HemovigilanceRow {
  reaction_type: string | null;
  severity: string | null;
  count: number;
}

export interface HemovigilanceReport {
  reporting_period: string;
  total_transfusions: number;
  total_reactions: number;
  reaction_rate_percent: number;
  reactions_by_type: HemovigilanceRow[];
}

// Radiology — TAT, appointments
export interface RadiologyTatRow {
  modality_name: string;
  total_orders: number;
  avg_tat_hours: number | null;
  completed_count: number;
}

export interface CreateRadiologyAppointmentRequest {
  patient_id: string;
  modality_id: string;
  encounter_id: string;
  test_id?: string;
  priority?: string;
  notes?: string;
}

// Housekeeping — BMW schedule, sharp replacement
export interface BmwScheduleEntry {
  ward: string;
  category: string;
  total_weight_kg: number;
  record_count: number;
  latest_collection: string | null;
}

export interface SharpReplacementRequest {
  location_id: string;
  container_type?: string;
  notes?: string;
}

// Emergency — ER-to-IPD admission
export interface AdmitFromErRequest {
  bed_id: string;
  admitting_doctor_id: string;
  admission_notes?: string;
}

// ══════════════════════════════════════════════════════════
//  Batch 2 — Analytics & Reporting Types
// ══════════════════════════════════════════════════════════

// Infection Control Analytics
export interface HaiRateRow {
  infection_type: string;
  count: number;
  patient_days: number;
  rate_per_1000: number;
}

export interface DeviceUtilizationRow {
  unit_name: string;
  device_type: string;
  device_days: number;
  patient_days: number;
  utilization_ratio: number;
}

export interface AntimicrobialConsumptionRow {
  drug_name: string;
  atc_code: string | null;
  total_ddd: number;
  patient_days: number;
  ddd_per_1000: number;
}

export interface SurgicalProphylaxisRow {
  procedure_type: string;
  total_cases: number;
  timely_count: number;
  compliance_pct: number;
}

export interface CultureSensitivityRow {
  organism: string;
  antibiotic: string;
  sensitive_count: number;
  resistant_count: number;
  intermediate_count: number;
  total_tests: number;
  sensitivity_pct: number;
}

export interface MdroRow {
  organism: string;
  month: string;
  case_count: number;
  rate_per_1000: number;
}

export interface CreateExposureRequest {
  event_type: string;
  source_patient_id?: string;
  exposed_staff_id?: string;
  exposure_date: string;
  exposure_type: string;
  pep_initiated: boolean;
  details?: Record<string, unknown>;
  notes?: string;
}

export interface IcMeeting {
  id: string;
  tenant_id: string;
  meeting_date: string;
  meeting_type: string;
  attendees: unknown[];
  agenda: string | null;
  minutes: string | null;
  action_items: unknown[];
  created_at: string;
}

export interface CreateIcMeetingRequest {
  meeting_date: string;
  meeting_type?: string;
  attendees?: string[];
  agenda?: string;
  minutes?: string;
}

export interface MonthlySurveillanceReport {
  month: string;
  hai_count: number;
  hai_rate: number;
  hand_hygiene_compliance: number;
  bmw_total_kg: number;
  culture_count: number;
  mdro_count: number;
  outbreak_count: number;
}

export interface CreateOutbreakRcaRequest {
  methodology: string;
  root_causes: string[];
  contributing_factors: string[];
  corrective_actions: string[];
  notes?: string;
}

// Quality Analytics
export interface ScheduleAuditsRequest {
  template_audit_id?: string;
  department_ids: string[];
  frequency: string;
  start_date: string;
  end_date: string;
}

export interface AuditFinding {
  id: string;
  audit_id: string;
  finding_type: string;
  description: string;
  severity: string;
  recommendation: string | null;
  status: string;
  created_at: string;
}

export interface CreateAuditFindingRequest {
  finding_type: string;
  description: string;
  severity: string;
  recommendation?: string;
}

export interface CommitteeDashboard {
  total_meetings_scheduled: number;
  meetings_held: number;
  action_items_open: number;
  action_items_closed: number;
  action_items_overdue: number;
}

export interface CreateMortalityReviewRequest {
  patient_id: string;
  death_date: string;
  primary_diagnosis: string;
  contributing_factors?: string[];
  review_findings?: string;
  preventability?: string;
  recommendations?: string[];
}

export interface PatientSafetyIndicator {
  indicator_name: string;
  event_count: number;
  patient_days: number;
  rate_per_1000: number;
  benchmark: number | null;
}

export interface DepartmentScorecard {
  department_id: string;
  department_name: string;
  overall_score: number;
  indicator_scores: Record<string, number>;
}

// Regulatory
export interface AutoPopulateRequest {
  standard_ids?: string[];
}

export interface RegulatorySubmission {
  id: string;
  tenant_id: string;
  submission_type: string;
  submitted_to: string;
  reference_number: string | null;
  submitted_at: string;
  status: string;
  notes: string | null;
  created_at: string;
}

export interface CreateRegulatorySubmissionRequest {
  submission_type: string;
  submitted_to: string;
  reference_number?: string;
  submitted_at: string;
  status?: string;
  notes?: string;
}

export interface StaffCredentialSummary {
  employee_id: string;
  employee_name: string;
  credential_type: string;
  expiry_date: string | null;
  days_until_expiry: number | null;
  status: string;
}

export interface LicenseDashboardItem {
  id: string;
  license_type: string;
  license_number: string | null;
  issued_date: string | null;
  expiry_date: string | null;
  days_until_expiry: number | null;
  renewal_status: string;
  responsible_person: string | null;
}

export interface NablDocumentSummary {
  document_type: string;
  total_required: number;
  total_uploaded: number;
  completeness_pct: number;
}

// Setup
export interface BulkCreateUsersRequest {
  users: Array<{
    username: string;
    email: string;
    password: string;
    full_name: string;
    role_id: string;
  }>;
}

export interface CompletenessCheck {
  departments: number;
  users: number;
  roles: number;
  services: number;
  locations: number;
  drugs: number;
  lab_tests: number;
}

export interface SystemHealth {
  user_count: number;
  department_count: number;
  module_count: number;
  migration_count: number;
  table_sizes: Record<string, number>;
}

// Scheduling
export interface SchedulingConflict {
  resource_id: string;
  resource_name: string;
  slot_a_id: string;
  slot_b_id: string;
  overlap_start: string;
  overlap_end: string;
}

export interface ScheduleAnalytics {
  total_slots: number;
  utilized_slots: number;
  utilization_rate: number;
  no_show_count: number;
  no_show_rate: number;
  avg_wait_minutes: number;
}

export interface CreateRecurringRequest {
  resource_id: string;
  resource_type: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  repeat_count: number;
  start_date: string;
}

export interface CreateBlockRequest {
  resource_id: string;
  resource_type: string;
  start_time: string;
  end_time: string;
  block_reason: string;
}

// Occupational Health
export interface OccHealthHazard {
  id: string;
  tenant_id: string;
  hazard_type: string;
  location: string;
  risk_level: string;
  description: string | null;
  mitigation: string | null;
  assessed_date: string;
  created_at: string;
}

export interface CreateOccHealthHazardRequest {
  hazard_type: string;
  location: string;
  risk_level: string;
  description?: string;
  mitigation?: string;
  assessed_date: string;
}

export interface OccHealthAnalytics {
  total_screenings: number;
  by_type: Record<string, number>;
  by_department: Record<string, number>;
  fitness_rates: Record<string, number>;
}

export interface ReturnToWorkClearanceRequest {
  employee_id: string;
  clearance_date: string;
  restrictions?: string;
  follow_up_date?: string;
  notes?: string;
}

// OPD
export interface PharmacyDispatchStatus {
  prescription_id: string;
  drug_name: string;
  quantity_ordered: number;
  quantity_dispensed: number;
  status: string;
}

export interface ReferralTrackingRow {
  referral_id: string;
  patient_name: string;
  from_department: string;
  to_department: string;
  referral_date: string;
  status: string;
  acknowledged_at: string | null;
  completed_at: string | null;
}

export interface FollowupComplianceRow {
  patient_id: string;
  patient_name: string;
  last_visit_date: string;
  follow_up_date: string;
  days_overdue: number;
  department: string;
}

// IPD
export interface DischargeSummary {
  admission_id: string;
  patient_name: string;
  admission_date: string;
  discharge_date: string | null;
  diagnoses: string[];
  procedures: string[];
  medications: string[];
  instructions: string | null;
  follow_up: string | null;
}

export interface BedTransferRequest {
  to_bed_id: string;
  reason: string;
  notes?: string;
}

export interface ExpectedDischargeRow {
  admission_id: string;
  patient_id: string;
  patient_name: string;
  ward: string;
  bed_number: string;
  expected_discharge_date: string;
  attending_doctor: string;
  days_admitted: number;
}

// Pharmacy
export interface DrugInteractionCheckRequest {
  patient_id: string;
  drug_id: string;
}

export interface DrugInteractionResult {
  interacting_drug: string;
  interaction_type: string;
  severity: string;
  description: string;
}

export interface PrescriptionAuditEntry {
  action: string;
  changed_by: string;
  changed_at: string;
  old_value: string | null;
  new_value: string | null;
  field_name: string;
}

export interface FormularyCheckResult {
  drug_id: string;
  drug_name: string;
  is_formulary: boolean;
  requires_approval: boolean;
  alternative_drugs: string[];
}

// Billing — Service Packages (distinct from existing BillingPackage)
export interface BillingServicePackage {
  id: string;
  tenant_id: string;
  package_name: string;
  package_code: string;
  description: string | null;
  total_amount: number;
  components: unknown[];
  is_active: boolean;
  created_at: string;
}

export interface CreateBillingServicePackageRequest {
  package_name: string;
  package_code: string;
  description?: string;
  total_amount: number;
  components?: unknown[];
}

export interface CopayCalculation {
  invoice_amount: number;
  insurance_coverage: number;
  copay_amount: number;
  deductible: number;
  patient_responsibility: number;
}

export interface ErFastInvoiceRequest {
  emergency_visit_id: string;
  additional_charges?: Array<{ description: string; amount: number }>;
}

// Camp
export interface CampAnalytics {
  total_camps: number;
  total_registrations: number;
  total_screenings: number;
  conversion_rate: number;
  avg_cost_per_patient: number;
  followup_compliance: number;
  by_type: Record<string, number>;
}

export interface CampReport {
  camp: Record<string, unknown>;
  stats: Record<string, number>;
  registrations: number;
  screenings: number;
  lab_samples: number;
  followups: number;
  billing_total: number;
}

// Facilities
export interface SchedulePmRequest {
  equipment_ids?: string[];
  frequency: string;
  start_date: string;
}

export interface EnergyAnalytics {
  by_source: Array<{ source_type: string; total_kwh: number; total_cost: number }>;
  monthly_trend: Array<{ month: string; total_kwh: number; total_cost: number }>;
  peak_hours: Array<{ hour: number; avg_kwh: number }>;
}

// Front Office
export interface VisitorAnalytics {
  total_visitors: number;
  by_department: Record<string, number>;
  by_hour: Record<string, number>;
  avg_visit_duration_minutes: number;
}

export interface QueueMetrics {
  department: string;
  avg_wait_minutes: number;
  throughput_per_hour: number;
  current_waiting: number;
  longest_wait_minutes: number;
}

// HR
export interface TrainingComplianceRow {
  program_id: string;
  program_name: string;
  total_staff: number;
  completed: number;
  compliance_pct: number;
  is_mandatory: boolean;
}

// ── Command Center ─────────────────────────────────────────

export interface PatientFlowSnapshot {
  registered_today: number;
  opd_waiting: number;
  opd_in_consult: number;
  er_active: number;
  ipd_admitted: number;
  pending_discharge: number;
  discharged_today: number;
}

export interface HourlyFlowRow {
  hour: number;
  admissions: number;
  discharges: number;
  er_arrivals: number;
  opd_visits: number;
}

export interface BottleneckRow {
  area: string;
  metric: string;
  current_value: number;
  threshold: number;
  severity: string;
}

export interface DepartmentLoadRow {
  department_id: string;
  department_name: string;
  bed_total: number;
  bed_occupied: number;
  occupancy_pct: number;
  queue_depth: number;
  avg_wait_mins: number;
}

export interface DepartmentAlertRow {
  id: string;
  department_id: string;
  department_name: string;
  alert_level: string;
  metric_code: string;
  current_value: number;
  threshold_value: number;
  message: string;
  acknowledged_by: string | null;
  acknowledged_at: string | null;
  created_at: string;
}

export interface AlertThresholdRow {
  id: string;
  department_id: string;
  department_name: string;
  metric_code: string;
  warning_threshold: number | null;
  critical_threshold: number | null;
  is_active: boolean;
}

export interface CreateAlertThresholdRequest {
  department_id: string;
  metric_code: string;
  warning_threshold?: number;
  critical_threshold?: number;
}

export interface UpdateAlertThresholdRequest {
  warning_threshold?: number;
  critical_threshold?: number;
  is_active?: boolean;
}

export interface PendingDischargeRow {
  admission_id: string;
  patient_id: string;
  patient_name: string;
  uhid: string;
  ward_name: string;
  bed_code: string;
  doctor_name: string;
  admitted_at: string;
  expected_discharge_date: string | null;
  days_admitted: number;
  pending_labs: number;
  pending_billing: boolean;
  summary_draft: boolean;
  checklist_pending: number;
}

export interface BedTurnaroundRow {
  location_id: string;
  location_code: string;
  ward_name: string;
  status: string;
  discharge_at: string | null;
  cleaning_started_at: string | null;
  cleaning_completed_at: string | null;
  turnaround_minutes: number | null;
}

export interface TurnaroundStatsRow {
  ward_name: string;
  avg_turnaround_mins: number;
  max_turnaround_mins: number;
  beds_awaiting_cleaning: number;
  beds_being_cleaned: number;
}

export interface TransportRequestRow {
  id: string;
  patient_name: string | null;
  from_location: string | null;
  to_location: string | null;
  transport_mode: string;
  status: string;
  priority: string;
  requested_by_name: string;
  assigned_to_name: string | null;
  requested_at: string;
  assigned_at: string | null;
  picked_up_at: string | null;
  completed_at: string | null;
  notes: string | null;
}

export interface CreateTransportRequest {
  patient_id?: string;
  admission_id?: string;
  from_location_id?: string;
  to_location_id?: string;
  transport_mode: string;
  priority?: string;
  notes?: string;
}

export interface UpdateTransportRequest {
  transport_mode?: string;
  priority?: string;
  notes?: string;
}

export interface AssignTransportRequest {
  assigned_to: string;
}

export interface KpiTile {
  code: string;
  label: string;
  value: number;
  unit: string;
  trend: number | null;
  period: string;
}

// ══════════════════════════════════════════════════════════
//  Audit Trail
// ══════════════════════════════════════════════════════════

export interface AuditLogEntry {
  id: string;
  user_id: string | null;
  user_name: string | null;
  action: string;
  entity_type: string;
  entity_id: string | null;
  old_values: unknown | null;
  new_values: unknown | null;
  ip_address: string | null;
  module: string | null;
  description: string | null;
  created_at: string;
}

export interface AuditLogSummary {
  id: string;
  user_name: string | null;
  action: string;
  entity_type: string;
  entity_id: string | null;
  module: string | null;
  description: string | null;
  created_at: string;
}

export interface AccessLogEntry {
  id: string;
  user_id: string;
  user_name: string | null;
  entity_type: string;
  entity_id: string | null;
  patient_id: string | null;
  patient_name: string | null;
  action: string;
  ip_address: string | null;
  module: string | null;
  created_at: string;
}

export interface AuditLogQuery {
  module?: string;
  entity_type?: string;
  entity_id?: string;
  user_id?: string;
  action?: string;
  from?: string;
  to?: string;
  page?: number;
  per_page?: number;
}

export interface AccessLogQuery {
  patient_id?: string;
  user_id?: string;
  entity_type?: string;
  module?: string;
  from?: string;
  to?: string;
  page?: number;
  per_page?: number;
}

export interface AuditStats {
  total_entries: number;
  today_entries: number;
  top_modules: ModuleCount[];
  top_users: UserActionCount[];
  action_breakdown: ActionCount[];
}

export interface ModuleCount {
  module: string | null;
  count: number;
}

export interface UserActionCount {
  user_name: string | null;
  count: number;
}

export interface ActionCount {
  action: string;
  count: number;
}

export interface LogAccessRequest {
  entity_type: string;
  entity_id?: string;
  patient_id?: string;
  module?: string;
}

// ── Analytics & Dashboards ─────────────────────────────────

export interface DeptRevenueRow {
  department_name: string;
  revenue: number;
  invoice_count: number;
}

export interface AnalyticsDoctorRevenueRow {
  doctor_name: string;
  department_name: string;
  revenue: number;
  patient_count: number;
}

export interface IpdCensusRow {
  date: string;
  admissions: number;
  discharges: number;
  deaths: number;
  active: number;
}

export interface LabTatRow {
  test_name: string;
  order_count: number;
  avg_tat_mins: number;
  p90_tat_mins: number;
  min_tat_mins: number;
  max_tat_mins: number;
}

export interface PharmacySalesRow {
  drug_name: string;
  category: string | null;
  quantity_sold: number;
  total_revenue: number;
}

export interface OtUtilizationRow {
  room_name: string;
  total_bookings: number;
  completed: number;
  cancelled: number;
  avg_duration_mins: number;
  utilization_pct: number;
}

export interface ErVolumeRow {
  date: string;
  total_visits: number;
  immediate: number;
  emergent: number;
  urgent: number;
  less_urgent: number;
  non_urgent: number;
  avg_door_to_doctor_mins: number;
}

export interface ClinicalIndicatorRow {
  period: string;
  mortality_rate: number;
  infection_rate: number;
  readmission_rate: number;
  avg_los_days: number;
}

export interface OpdFootfallRow {
  date: string;
  department_name: string;
  visit_count: number;
  new_patients: number;
  follow_ups: number;
}

export interface BedOccupancyRow {
  ward_name: string;
  total_beds: number;
  occupied: number;
  vacant: number;
  occupancy_pct: number;
}

// ── Print Data ─────────────────────────────────────────

export interface MedicationLine {
  drug_name: string;
  dosage: string;
  route: string | null;
  frequency: string;
  duration: string;
  instructions: string | null;
}

export interface PrescriptionPrintData {
  patient_name: string;
  uhid: string;
  age: string | null;
  gender: string;
  phone: string;
  doctor_name: string;
  department: string | null;
  diagnosis: string | null;
  date: string;
  medications: MedicationLine[];
  advice: string | null;
  follow_up: string | null;
}

export interface LabResultLine {
  parameter_name: string;
  value: string;
  unit: string | null;
  normal_range: string | null;
  flag: string | null;
}

export interface LabReportPrintData {
  patient_name: string;
  uhid: string;
  age: string | null;
  gender: string;
  order_number: string | null;
  test_name: string;
  sample_type: string | null;
  collected_at: string | null;
  reported_at: string | null;
  referring_doctor: string | null;
  results: LabResultLine[];
  pathologist_name: string | null;
}

export interface RadiologyReportPrintData {
  patient_name: string;
  uhid: string;
  age: string | null;
  gender: string;
  modality: string;
  body_part: string | null;
  clinical_indication: string | null;
  findings: string;
  impression: string | null;
  recommendations: string | null;
  reported_by: string | null;
  verified_by: string | null;
  date: string;
}

export interface PatientCardPrintData {
  patient_name: string;
  uhid: string;
  date_of_birth: string | null;
  age: string | null;
  gender: string;
  phone: string;
  email: string | null;
  address: Record<string, unknown> | null;
  category: string;
  registered_at: string;
}

export interface WristbandPrintData {
  patient_name: string;
  uhid: string;
  age: string | null;
  gender: string;
  date_of_birth: string | null;
  blood_group: string | null;
  admission_date: string;
  bed_number: string | null;
  ward_name: string | null;
  doctor_name: string | null;
  allergies: string[];
}

export interface AppointmentSlipPrintData {
  patient_name: string;
  uhid: string;
  phone: string;
  doctor_name: string;
  department: string;
  appointment_date: string;
  slot_start: string;
  slot_end: string;
  token_number: number | null;
  reason: string | null;
}

export interface DeathCertificatePrintData {
  patient_name: string;
  uhid: string;
  age: string | null;
  gender: string;
  date_of_birth: string | null;
  admission_date: string;
  death_date: string | null;
  doctor_name: string | null;
  department: string | null;
  diagnosis: string | null;
  cause_of_death: string | null;
}

export interface DischargeSummaryPrintData {
  patient_name: string;
  uhid: string;
  age: string | null;
  gender: string;
  admission_date: string;
  discharge_date: string | null;
  department: string | null;
  doctor_name: string | null;
  bed_number: string | null;
  ward_name: string | null;
  discharge_type: string | null;
  discharge_summary: string | null;
  diagnosis: string | null;
}

export interface ReceiptPrintData {
  receipt_number: string | null;
  patient_name: string;
  uhid: string;
  invoice_number: string;
  amount: string;
  payment_mode: string;
  reference_number: string | null;
  received_by: string | null;
  paid_at: string;
  hospital_name: string | null;
}

export interface EstimateItemLine {
  description: string;
  quantity: number;
  unit_price: string;
  total_price: string;
}

export interface EstimatePrintData {
  invoice_number: string;
  patient_name: string;
  uhid: string;
  subtotal: string;
  tax_amount: string;
  discount_amount: string;
  total_amount: string;
  items: EstimateItemLine[];
  hospital_name: string | null;
  date: string;
}

export interface CreditNotePrintData {
  credit_note_number: string;
  invoice_number: string;
  patient_name: string;
  uhid: string;
  amount: string;
  reason: string;
  status: string;
  created_at: string;
  hospital_name: string | null;
}

export interface TdsCertificatePrintData {
  deductee_name: string;
  deductee_pan: string;
  tds_section: string;
  tds_rate: string;
  base_amount: string;
  tds_amount: string;
  deducted_date: string;
  certificate_number: string | null;
  certificate_date: string | null;
  financial_year: string;
  quarter: string;
  hospital_name: string | null;
}

export interface GstInvoiceItemLine {
  description: string;
  hsn_code: string | null;
  quantity: number;
  unit_price: string;
  tax_percent: string;
  total_price: string;
}

export interface GstInvoicePrintData {
  invoice_number: string;
  patient_name: string;
  uhid: string;
  subtotal: string;
  tax_amount: string;
  total_amount: string;
  hospital_gstin: string | null;
  hospital_name: string | null;
  hospital_address: string | null;
  items: GstInvoiceItemLine[];
  date: string;
}

// ── Ambulance Fleet Management ──────────────────────────

export type AmbulanceType = "bls" | "als" | "patient_transport" | "mortuary" | "neonatal";
export type AmbulanceStatusType = "available" | "on_trip" | "maintenance" | "off_duty" | "decommissioned";
export type AmbulanceTripType = "emergency" | "scheduled" | "inter_facility" | "discharge";
export type AmbulanceTripStatus = "requested" | "dispatched" | "en_route_pickup" | "at_pickup" | "en_route_drop" | "at_drop" | "completed" | "cancelled";
export type AmbulanceTripPriority = "critical" | "urgent" | "routine";
export type AmbulanceMaintenanceStatus = "scheduled" | "in_progress" | "completed" | "overdue" | "cancelled";

export interface AmbulanceRow {
  id: string;
  tenant_id: string;
  vehicle_number: string;
  ambulance_code: string;
  ambulance_type: AmbulanceType;
  status: AmbulanceStatusType;
  make: string | null;
  model: string | null;
  year_of_manufacture: number | null;
  chassis_number: string | null;
  engine_number: string | null;
  fitness_certificate_expiry: string | null;
  insurance_expiry: string | null;
  pollution_certificate_expiry: string | null;
  permit_expiry: string | null;
  equipment_checklist: unknown | null;
  has_ventilator: boolean;
  has_defibrillator: boolean;
  has_oxygen: boolean;
  seating_capacity: number | null;
  gps_device_id: string | null;
  last_latitude: number | null;
  last_longitude: number | null;
  last_location_at: string | null;
  default_driver_id: string | null;
  current_driver_id: string | null;
  odometer_km: number | null;
  fuel_type: string | null;
  notes: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface AmbulanceDriverRow {
  id: string;
  tenant_id: string;
  employee_id: string;
  license_number: string;
  license_type: string;
  license_expiry: string;
  is_active: boolean;
  bls_certified: boolean;
  bls_expiry: string | null;
  defensive_driving: boolean;
  shift_pattern: string | null;
  phone: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface AmbulanceTripRow {
  id: string;
  tenant_id: string;
  trip_code: string;
  ambulance_id: string | null;
  driver_id: string | null;
  trip_type: AmbulanceTripType;
  status: AmbulanceTripStatus;
  priority: AmbulanceTripPriority;
  patient_id: string | null;
  patient_name: string | null;
  patient_phone: string | null;
  pickup_address: string;
  pickup_latitude: number | null;
  pickup_longitude: number | null;
  pickup_landmark: string | null;
  drop_address: string | null;
  drop_latitude: number | null;
  drop_longitude: number | null;
  drop_landmark: string | null;
  requested_at: string;
  dispatched_at: string | null;
  pickup_arrived_at: string | null;
  patient_loaded_at: string | null;
  drop_arrived_at: string | null;
  completed_at: string | null;
  cancelled_at: string | null;
  vitals_at_pickup: unknown | null;
  vitals_at_drop: unknown | null;
  clinical_notes: string | null;
  oxygen_administered: boolean | null;
  iv_started: boolean | null;
  odometer_start: number | null;
  odometer_end: number | null;
  distance_km: number | null;
  cancellation_reason: string | null;
  is_billable: boolean;
  base_charge: number | null;
  per_km_charge: number | null;
  total_amount: number | null;
  billing_invoice_id: string | null;
  er_visit_id: string | null;
  transport_request_id: string | null;
  requested_by: string | null;
  dispatched_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface AmbulanceTripLogRow {
  id: string;
  tenant_id: string;
  trip_id: string;
  event_type: string;
  latitude: number | null;
  longitude: number | null;
  speed_kmh: number | null;
  heading: number | null;
  event_data: unknown | null;
  recorded_by: string | null;
  recorded_at: string;
}

export interface AmbulanceMaintenanceRow {
  id: string;
  tenant_id: string;
  ambulance_id: string;
  maintenance_type: string;
  status: AmbulanceMaintenanceStatus;
  scheduled_date: string;
  started_at: string | null;
  completed_at: string | null;
  description: string | null;
  vendor_name: string | null;
  cost: number | null;
  odometer_at_service: number | null;
  next_service_km: number | null;
  next_service_date: string | null;
  findings: string | null;
  parts_replaced: unknown | null;
  performed_by: string | null;
  approved_by: string | null;
  notes: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateAmbulanceRequest {
  vehicle_number: string;
  ambulance_type: AmbulanceType;
  make?: string;
  model?: string;
  year_of_manufacture?: number;
  chassis_number?: string;
  engine_number?: string;
  fitness_certificate_expiry?: string;
  insurance_expiry?: string;
  pollution_certificate_expiry?: string;
  permit_expiry?: string;
  equipment_checklist?: unknown;
  has_ventilator?: boolean;
  has_defibrillator?: boolean;
  has_oxygen?: boolean;
  seating_capacity?: number;
  gps_device_id?: string;
  default_driver_id?: string;
  fuel_type?: string;
  notes?: string;
}

export interface UpdateAmbulanceRequest {
  vehicle_number?: string;
  ambulance_type?: AmbulanceType;
  status?: AmbulanceStatusType;
  make?: string;
  model?: string;
  year_of_manufacture?: number;
  chassis_number?: string;
  engine_number?: string;
  fitness_certificate_expiry?: string;
  insurance_expiry?: string;
  pollution_certificate_expiry?: string;
  permit_expiry?: string;
  equipment_checklist?: unknown;
  has_ventilator?: boolean;
  has_defibrillator?: boolean;
  has_oxygen?: boolean;
  seating_capacity?: number;
  gps_device_id?: string;
  default_driver_id?: string;
  odometer_km?: number;
  fuel_type?: string;
  notes?: string;
}

export interface UpdateAmbulanceLocationRequest {
  latitude: number;
  longitude: number;
}

export interface CreateAmbulanceDriverRequest {
  employee_id: string;
  license_number: string;
  license_type: string;
  license_expiry: string;
  bls_certified?: boolean;
  bls_expiry?: string;
  defensive_driving?: boolean;
  shift_pattern?: string;
  phone?: string;
  notes?: string;
}

export interface UpdateAmbulanceDriverRequest {
  license_number?: string;
  license_type?: string;
  license_expiry?: string;
  is_active?: boolean;
  bls_certified?: boolean;
  bls_expiry?: string;
  defensive_driving?: boolean;
  shift_pattern?: string;
  phone?: string;
  notes?: string;
}

export interface CreateAmbulanceTripRequest {
  trip_type: AmbulanceTripType;
  priority?: AmbulanceTripPriority;
  ambulance_id?: string;
  driver_id?: string;
  patient_id?: string;
  patient_name?: string;
  patient_phone?: string;
  pickup_address: string;
  pickup_latitude?: number;
  pickup_longitude?: number;
  pickup_landmark?: string;
  drop_address?: string;
  drop_latitude?: number;
  drop_longitude?: number;
  drop_landmark?: string;
  er_visit_id?: string;
  transport_request_id?: string;
  is_billable?: boolean;
}

export interface UpdateAmbulanceTripRequest {
  ambulance_id?: string;
  driver_id?: string;
  patient_id?: string;
  patient_name?: string;
  patient_phone?: string;
  pickup_address?: string;
  drop_address?: string;
  vitals_at_pickup?: unknown;
  vitals_at_drop?: unknown;
  clinical_notes?: string;
  oxygen_administered?: boolean;
  iv_started?: boolean;
  odometer_start?: number;
  odometer_end?: number;
  base_charge?: number;
  per_km_charge?: number;
  total_amount?: number;
}

export interface UpdateAmbulanceTripStatusRequest {
  status: AmbulanceTripStatus;
  cancellation_reason?: string;
}

export interface AddAmbulanceTripLogRequest {
  event_type: string;
  latitude?: number;
  longitude?: number;
  speed_kmh?: number;
  event_data?: unknown;
}

export interface CreateAmbulanceMaintenanceRequest {
  ambulance_id: string;
  maintenance_type: string;
  scheduled_date: string;
  description?: string;
  vendor_name?: string;
  cost?: number;
  odometer_at_service?: number;
  next_service_km?: number;
  next_service_date?: string;
  notes?: string;
}

export interface UpdateAmbulanceMaintenanceRequest {
  maintenance_type?: string;
  status?: AmbulanceMaintenanceStatus;
  scheduled_date?: string;
  description?: string;
  vendor_name?: string;
  cost?: number;
  odometer_at_service?: number;
  next_service_km?: number;
  next_service_date?: string;
  findings?: string;
  parts_replaced?: unknown;
  performed_by?: string;
  notes?: string;
}

// ── Communication Hub ───────────────────────────────────

export type CommChannel = "sms" | "whatsapp" | "email" | "push" | "ivr" | "portal";
export type CommMessageStatus = "queued" | "sent" | "delivered" | "failed" | "read";
export type CommTemplateType = "appointment_reminder" | "lab_result" | "discharge_summary" | "billing" | "medication_reminder" | "follow_up" | "generic" | "marketing";
export type CommClinicalPriority = "routine" | "urgent" | "critical" | "stat";
export type CommAlertStatus = "triggered" | "acknowledged" | "escalated" | "resolved" | "expired";
export type CommComplaintStatus = "open" | "assigned" | "in_progress" | "pending_review" | "resolved" | "closed" | "reopened";
export type CommComplaintSource = "walk_in" | "phone" | "email" | "portal" | "kiosk" | "social_media" | "google_review";
export type CommFeedbackType = "bedside" | "post_discharge" | "nps" | "department" | "kiosk";

export interface CommTemplateRow {
  id: string; tenant_id: string; template_name: string; template_code: string;
  channel: CommChannel; template_type: CommTemplateType; subject: string | null;
  body_template: string; placeholders: unknown | null; language: string | null;
  is_active: boolean; requires_approval: boolean; approved_by: string | null;
  approved_at: string | null; external_template_id: string | null; notes: string | null;
  created_by: string | null; created_at: string; updated_at: string;
}

export interface CommMessageRow {
  id: string; tenant_id: string; message_code: string; template_id: string | null;
  channel: CommChannel; status: CommMessageStatus; recipient_type: string | null;
  recipient_id: string | null; recipient_name: string | null; recipient_contact: string;
  subject: string | null; body: string; scheduled_at: string | null;
  sent_at: string | null; delivered_at: string | null; read_at: string | null;
  failed_at: string | null; failure_reason: string | null; external_message_id: string | null;
  context_type: string | null; context_id: string | null; retry_count: number | null;
  sent_by: string | null; cost: number | null; created_at: string; updated_at: string;
}

export interface CommClinicalMessageRow {
  id: string; tenant_id: string; message_code: string; sender_id: string;
  recipient_id: string; recipient_department_id: string | null; patient_id: string | null;
  priority: CommClinicalPriority; message_type: string; subject: string | null;
  body: string; sbar_data: unknown | null; is_read: boolean; read_at: string | null;
  is_urgent: boolean; acknowledged_at: string | null; acknowledged_by: string | null;
  parent_message_id: string | null; attachments: unknown | null;
  created_at: string; updated_at: string;
}

export interface CommCriticalAlertRow {
  id: string; tenant_id: string; alert_code: string; alert_source: string;
  source_id: string | null; patient_id: string; department_id: string | null;
  priority: CommClinicalPriority; status: CommAlertStatus; title: string;
  description: string; alert_value: string | null; normal_range: string | null;
  triggered_at: string; acknowledged_at: string | null; acknowledged_by: string | null;
  resolved_at: string | null; resolved_by: string | null; resolution_notes: string | null;
  escalation_level: number | null; escalated_at: string | null; escalated_to: string | null;
  notification_log: unknown | null; created_at: string; updated_at: string;
}

export interface CommComplaintRow {
  id: string; tenant_id: string; complaint_code: string; source: CommComplaintSource;
  status: CommComplaintStatus; patient_id: string | null; complainant_name: string;
  complainant_phone: string | null; complainant_email: string | null;
  department_id: string | null; category: string | null; subcategory: string | null;
  subject: string; description: string; severity: string | null;
  assigned_to: string | null; assigned_at: string | null;
  sla_hours: number | null; sla_deadline: string | null;
  sla_breached: boolean; sla_breached_at: string | null;
  resolution_notes: string | null; resolved_at: string | null; resolved_by: string | null;
  closed_at: string | null; closed_by: string | null;
  satisfaction_score: number | null; service_recovery_action: string | null;
  service_recovery_cost: number | null; escalation_level: number | null;
  escalation_history: unknown | null; google_review_id: string | null;
  external_reference: string | null; attachments: unknown | null;
  created_by: string | null; created_at: string; updated_at: string;
}

export interface CommFeedbackSurveyRow {
  id: string; tenant_id: string; feedback_code: string; feedback_type: CommFeedbackType;
  patient_id: string | null; department_id: string | null; doctor_id: string | null;
  overall_rating: number | null; nps_score: number | null; wait_time_rating: number | null;
  staff_rating: number | null; cleanliness_rating: number | null; food_rating: number | null;
  communication_rating: number | null; discharge_rating: number | null;
  would_recommend: boolean | null; comments: string | null; suggestions: string | null;
  is_anonymous: boolean; channel: string | null; survey_data: unknown | null;
  submitted_at: string; waiting_time_minutes: number | null; collection_point: string | null;
  created_at: string;
}

export interface FeedbackStatsResponse {
  total_responses: number; avg_overall: number; avg_nps: number; nps_score: number;
  avg_wait_time: number; avg_staff: number; avg_cleanliness: number; would_recommend_pct: number;
}

export interface CreateCommTemplateRequest {
  template_name: string; template_code: string; channel: CommChannel; template_type: CommTemplateType;
  subject?: string; body_template: string; placeholders?: unknown; language?: string;
  is_active?: boolean; requires_approval?: boolean; external_template_id?: string; notes?: string;
}
export interface UpdateCommTemplateRequest {
  template_name?: string; channel?: CommChannel; template_type?: CommTemplateType;
  subject?: string; body_template?: string; placeholders?: unknown; language?: string;
  is_active?: boolean; requires_approval?: boolean; external_template_id?: string; notes?: string;
}
export interface CreateCommMessageRequest {
  template_id?: string; channel: CommChannel; recipient_type?: string; recipient_id?: string;
  recipient_name?: string; recipient_contact: string; subject?: string; body: string;
  context_type?: string; context_id?: string;
}
export interface UpdateCommMessageStatusRequest {
  status: CommMessageStatus; failure_reason?: string; external_message_id?: string;
}
export interface CreateCommClinicalRequest {
  recipient_id: string; recipient_department_id?: string; patient_id?: string;
  priority?: CommClinicalPriority; message_type: string; subject?: string; body: string;
  sbar_data?: unknown; is_urgent?: boolean; parent_message_id?: string; attachments?: unknown;
}
export interface CreateCommAlertRequest {
  alert_source: string; source_id?: string; patient_id: string; department_id?: string;
  priority?: CommClinicalPriority; title: string; description: string;
  alert_value?: string; normal_range?: string;
}
export interface ResolveCommAlertRequest { resolution_notes?: string; }
export interface CreateCommComplaintRequest {
  source: CommComplaintSource; patient_id?: string; complainant_name: string;
  complainant_phone?: string; complainant_email?: string; department_id?: string;
  category?: string; subcategory?: string; subject: string; description: string;
  severity?: string; sla_hours?: number;
}
export interface UpdateCommComplaintRequest {
  status?: CommComplaintStatus; assigned_to?: string; category?: string; severity?: string;
}
export interface ResolveCommComplaintRequest {
  resolution_notes?: string; satisfaction_score?: number;
  service_recovery_action?: string; service_recovery_cost?: number;
}
export interface CreateCommFeedbackRequest {
  feedback_type: CommFeedbackType; patient_id?: string; department_id?: string; doctor_id?: string;
  overall_rating?: number; nps_score?: number; wait_time_rating?: number; staff_rating?: number;
  cleanliness_rating?: number; food_rating?: number; communication_rating?: number;
  discharge_rating?: number; would_recommend?: boolean; comments?: string; suggestions?: string;
  is_anonymous?: boolean; channel?: string; survey_data?: unknown;
  waiting_time_minutes?: number; collection_point?: string;
}

// ── Blood Bank Phase 2 ─────────────────────────────────

export type BbReturnStatus = "requested" | "inspecting" | "accepted" | "rejected";
export type BbLookbackStatus = "detected" | "investigating" | "notified" | "closed";
export type BbBillingStatus = "pending" | "invoiced" | "paid" | "waived";
export type BbColdChainAlertLevel = "normal" | "warning" | "critical";

export interface BbRecruitmentCampaignRow {
  id: string; tenant_id: string; campaign_name: string; campaign_type: string;
  target_blood_groups: unknown | null; target_count: number | null; actual_count: number | null;
  start_date: string; end_date: string | null; status: string; notes: string | null;
  created_by: string | null; created_at: string; updated_at: string;
}

export interface BbColdChainDeviceRow {
  id: string; tenant_id: string; device_name: string; device_serial: string | null;
  location: string | null; equipment_type: string; min_temp: string | null; max_temp: string | null;
  alert_threshold_minutes: number | null; is_active: boolean; last_reading_at: string | null;
  last_temp: string | null; alert_level: BbColdChainAlertLevel | null; notes: string | null;
  created_at: string; updated_at: string;
}

export interface BbColdChainReadingRow {
  id: string; tenant_id: string; device_id: string; temperature: string;
  humidity: string | null; alert_level: BbColdChainAlertLevel | null; recorded_at: string;
}

export interface BbBloodReturnRow {
  id: string; tenant_id: string; component_id: string; return_code: string;
  returned_by: string | null; return_reason: string | null; temperature_at_return: string | null;
  temperature_acceptable: boolean | null; time_out_minutes: number | null; status: BbReturnStatus;
  inspection_notes: string | null; inspected_by: string | null; inspected_at: string | null;
  created_at: string; updated_at: string;
}

export interface BbMsbosGuidelineRow {
  id: string; tenant_id: string; procedure_name: string; procedure_code: string;
  blood_group: string | null; component_type: string; max_units: number;
  crossmatch_to_transfusion_ratio: string | null; is_active: boolean; notes: string | null;
  created_at: string; updated_at: string;
}

export interface BbLookbackEventRow {
  id: string; tenant_id: string; event_code: string; donation_id: string | null;
  donor_id: string | null; infection_type: string; detection_date: string;
  status: BbLookbackStatus; affected_components: unknown | null;
  recipients_notified: number | null; investigation_notes: string | null;
  reported_to: string | null; reported_at: string | null;
  closed_at: string | null; closed_by: string | null;
  created_by: string | null; created_at: string; updated_at: string;
}

export interface BbBillingItemRow {
  id: string; tenant_id: string; component_id: string | null; patient_id: string | null;
  billing_code: string; component_type: string | null; blood_group: string | null;
  processing_fee: string | null; component_cost: string | null; cross_match_fee: string | null;
  total_amount: string | null; status: BbBillingStatus; invoice_id: string | null;
  waiver_reason: string | null; billed_by: string | null; billed_at: string | null;
  created_at: string; updated_at: string;
}

export interface CreateBbCampaignRequest {
  campaign_name: string; campaign_type: string; target_blood_groups?: unknown;
  target_count?: number; start_date: string; end_date?: string; notes?: string;
}
export interface UpdateBbCampaignRequest {
  status?: string; actual_count?: number; notes?: string;
}
export interface CreateBbDeviceRequest {
  device_name: string; device_serial?: string; location?: string; equipment_type: string;
  min_temp?: number; max_temp?: number; alert_threshold_minutes?: number; notes?: string;
}
export interface AddBbReadingRequest {
  device_id: string; temperature: number; humidity?: number;
}
export interface CreateBbReturnRequest {
  component_id: string; return_reason?: string; temperature_at_return?: number; time_out_minutes?: number;
}
export interface InspectBbReturnRequest {
  status: BbReturnStatus; inspection_notes?: string; temperature_acceptable?: boolean;
}
export interface CreateBbMsbosRequest {
  procedure_name: string; procedure_code: string; blood_group?: string; component_type: string;
  max_units: number; crossmatch_to_transfusion_ratio?: number; notes?: string;
}
export interface CreateBbLookbackRequest {
  donation_id?: string; donor_id?: string; infection_type: string; detection_date: string;
  affected_components?: unknown; investigation_notes?: string;
}
export interface UpdateBbLookbackRequest {
  status?: BbLookbackStatus; recipients_notified?: number; investigation_notes?: string; reported_to?: string;
}
export interface CreateBbBillingRequest {
  component_id?: string; patient_id?: string; component_type?: string; blood_group?: string;
  processing_fee?: number; component_cost?: number; cross_match_fee?: number; total_amount?: number;
}
export interface BbSbtcReport {
  donation_count: number; component_count: number; discard_count: number;
  reaction_count: number; lookback_count: number;
}

// ══════════════════════════════════════════════════════════
//  Bedside Portal
// ══════════════════════════════════════════════════════════

export type BedsideRequestType =
  | "nurse_call" | "pain_management" | "bathroom_assist"
  | "water_food" | "blanket_pillow" | "position_change" | "other";

export type BedsideRequestStatus =
  | "pending" | "acknowledged" | "in_progress" | "completed" | "cancelled";

export interface BedsideSessionRow {
  id: string; tenant_id: string; admission_id: string; patient_id: string;
  bed_location: string | null; device_id: string | null;
  started_at: string; ended_at: string | null; is_active: boolean;
  created_at: string;
}

export interface BedsideNurseRequestRow {
  id: string; tenant_id: string; admission_id: string; patient_id: string;
  request_type: BedsideRequestType; status: BedsideRequestStatus;
  notes: string | null;
  acknowledged_by: string | null; acknowledged_at: string | null;
  completed_by: string | null; completed_at: string | null;
  created_at: string; updated_at: string;
}

export interface BedsideEducationVideoRow {
  id: string; tenant_id: string; title: string; description: string | null;
  video_url: string; thumbnail_url: string | null; category: string;
  condition_codes: unknown | null; language: string | null;
  duration_seconds: number | null; is_active: boolean; sort_order: number | null;
  created_by: string | null; created_at: string; updated_at: string;
}

export interface BedsideEducationViewRow {
  id: string; tenant_id: string; video_id: string; patient_id: string;
  admission_id: string; watched_seconds: number | null; completed: boolean;
  viewed_at: string;
}

export interface BedsideRealtimeFeedbackRow {
  id: string; tenant_id: string; admission_id: string; patient_id: string;
  pain_level: number | null; comfort_level: number | null;
  cleanliness_level: number | null; noise_level: number | null;
  staff_response: number | null; comments: string | null;
  submitted_at: string;
}

export interface BedsideDailyScheduleItem {
  event_type: string; scheduled_at: string | null;
  description: string; status: string | null;
}

export interface BedsideMedicationItem {
  id: string; drug_name: string | null; dose: string | null;
  route: string | null; frequency: string | null;
  scheduled_at: string | null; status: string | null;
}

export interface BedsideVitalReading {
  id: string; vital_type: string | null; value_numeric: number | null;
  value_text: string | null; unit: string | null; recorded_at: string | null;
}

export interface BedsideLabResultItem {
  id: string; test_name: string | null; result_value: string | null;
  unit: string | null; reference_range: string | null;
  is_abnormal: boolean | null; completed_at: string | null;
}

export interface BedsideDietOrderItem {
  id: string; diet_type: string | null; meal_type: string | null;
  instructions: string | null; status: string | null;
}

export interface CreateBedsideSessionRequest {
  admission_id: string; patient_id: string;
  bed_location?: string; device_id?: string;
}

export interface CreateBedsideNurseRequestPayload {
  patient_id: string; request_type: BedsideRequestType; notes?: string;
}

export interface UpdateBedsideRequestStatusPayload {
  status: BedsideRequestStatus;
}

export interface CreateBedsideVideoRequest {
  title: string; description?: string; video_url: string;
  thumbnail_url?: string; category: string;
  condition_codes?: unknown; language?: string;
  duration_seconds?: number; sort_order?: number;
}

export interface UpdateBedsideVideoRequest {
  title?: string; description?: string; video_url?: string;
  thumbnail_url?: string; category?: string;
  condition_codes?: unknown; language?: string;
  duration_seconds?: number; is_active?: boolean; sort_order?: number;
}

export interface RecordBedsideVideoViewRequest {
  video_id: string; patient_id: string;
  watched_seconds?: number; completed?: boolean;
}

export interface SubmitBedsideFeedbackRequest {
  patient_id: string; pain_level?: number; comfort_level?: number;
  cleanliness_level?: number; noise_level?: number;
  staff_response?: number; comments?: string;
}
