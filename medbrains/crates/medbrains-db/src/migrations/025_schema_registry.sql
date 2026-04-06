-- 025 — Schema Registry: output_schema on node templates + module entity & event schemas
-- These tables store the canonical field schemas for modules, events, and node templates,
-- enabling the Integration Hub to dynamically discover available fields instead of using
-- hardcoded maps in the frontend.

-- ═══════════════════════════════════════════════════════════
--  1. Add output_schema to integration_node_templates
-- ═══════════════════════════════════════════════════════════

ALTER TABLE integration_node_templates
  ADD COLUMN IF NOT EXISTS output_schema JSONB NOT NULL DEFAULT '{}';

-- Populate output_schema for each existing template

-- Triggers
UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "prescription_id", "type": "uuid", "label": "Prescription ID"},
    {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
    {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
    {"path": "doctor_id", "type": "uuid", "label": "Doctor ID"},
    {"path": "items", "type": "array", "label": "Items"},
    {"path": "items[].drug_name", "type": "string", "label": "Drug Name"},
    {"path": "items[].dosage", "type": "string", "label": "Dosage"},
    {"path": "items[].frequency", "type": "string", "label": "Frequency"},
    {"path": "items[].duration", "type": "string", "label": "Duration"},
    {"path": "items[].route", "type": "string", "label": "Route"},
    {"path": "notes", "type": "string", "label": "Notes"},
    {"path": "created_at", "type": "timestamp", "label": "Created At"}
  ]
}' WHERE code = 'trigger.internal_event';
-- Note: trigger.internal_event output depends on event_type; this is a generic fallback.
-- The frontend resolves per-event schemas from event_schemas table at runtime.

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "body", "type": "object", "label": "Request Body"},
    {"path": "headers", "type": "object", "label": "Headers"},
    {"path": "query_params", "type": "object", "label": "Query Parameters"},
    {"path": "method", "type": "string", "label": "HTTP Method"}
  ]
}' WHERE code = 'trigger.webhook';

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "triggered_at", "type": "timestamp", "label": "Triggered At"},
    {"path": "schedule_name", "type": "string", "label": "Schedule Name"}
  ]
}' WHERE code = 'trigger.schedule';

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "triggered_by", "type": "uuid", "label": "Triggered By"},
    {"path": "triggered_at", "type": "timestamp", "label": "Triggered At"},
    {"path": "input_data", "type": "object", "label": "Input Data"}
  ]
}' WHERE code = 'trigger.manual';

-- Conditions
UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "matched", "type": "boolean", "label": "Matched"},
    {"path": "branch", "type": "string", "label": "Branch"},
    {"path": "data", "type": "object", "label": "Pass-through Data"}
  ]
}' WHERE code = 'condition.if_else';

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "matched", "type": "boolean", "label": "Matched"},
    {"path": "branch", "type": "string", "label": "Branch"},
    {"path": "value", "type": "string", "label": "Matched Value"}
  ]
}' WHERE code = 'condition.switch';

-- Transform
UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "result", "type": "object", "label": "Transformed Data"}
  ]
}' WHERE code = 'transform.map_data';

-- Actions
UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "indent_id", "type": "uuid", "label": "Indent ID"},
    {"path": "indent_number", "type": "string", "label": "Indent Number"},
    {"path": "status", "type": "string", "label": "Status"}
  ]
}' WHERE code = 'action.create_indent';

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "order_id", "type": "uuid", "label": "Order ID"},
    {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
    {"path": "status", "type": "string", "label": "Status"}
  ]
}' WHERE code = 'action.create_order';

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "notification_id", "type": "uuid", "label": "Notification ID"},
    {"path": "status", "type": "string", "label": "Status"},
    {"path": "channel", "type": "string", "label": "Channel"}
  ]
}' WHERE code = 'action.send_notification';

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "status", "type": "string", "label": "Status"},
    {"path": "entity", "type": "string", "label": "Entity"}
  ]
}' WHERE code = 'action.update_record';

UPDATE integration_node_templates SET output_schema = '{
  "fields": [
    {"path": "response_status", "type": "integer", "label": "Response Status"},
    {"path": "response_body", "type": "object", "label": "Response Body"},
    {"path": "response_headers", "type": "object", "label": "Response Headers"}
  ]
}' WHERE code = 'action.webhook_call';

-- Also add invoice.created and payment.recorded to the trigger.internal_event config_schema enum
UPDATE integration_node_templates SET config_schema = jsonb_set(
  config_schema,
  '{properties,event_type,enum}',
  '["prescription.created","order.dispensed","stock.low","indent.submitted","indent.approved","patient.registered","encounter.created","lab.completed","admission.created","discharge.completed","invoice.created","payment.recorded"]'
) WHERE code = 'trigger.internal_event';


-- ═══════════════════════════════════════════════════════════
--  2. Module Entity Schemas
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS module_entity_schemas (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_code   TEXT NOT NULL,
    entity_code   TEXT NOT NULL,
    entity_label  TEXT NOT NULL,
    fields        JSONB NOT NULL DEFAULT '[]',
    UNIQUE(module_code, entity_code)
);

INSERT INTO module_entity_schemas (module_code, entity_code, entity_label, fields) VALUES
('patients', 'patient', 'Patient', '[
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "uhid", "type": "string", "label": "UHID"},
  {"path": "first_name", "type": "string", "label": "First Name"},
  {"path": "last_name", "type": "string", "label": "Last Name"},
  {"path": "full_name", "type": "string", "label": "Full Name"},
  {"path": "date_of_birth", "type": "date", "label": "Date of Birth"},
  {"path": "gender", "type": "string", "label": "Gender"},
  {"path": "phone", "type": "string", "label": "Phone"},
  {"path": "email", "type": "string", "label": "Email"},
  {"path": "category", "type": "string", "label": "Category"},
  {"path": "registration_type", "type": "string", "label": "Registration Type"},
  {"path": "created_at", "type": "timestamp", "label": "Created At"}
]'),
('opd', 'encounter', 'OPD Encounter', '[
  {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "patient_name", "type": "string", "label": "Patient Name"},
  {"path": "uhid", "type": "string", "label": "UHID"},
  {"path": "department_id", "type": "uuid", "label": "Department ID"},
  {"path": "doctor_id", "type": "uuid", "label": "Doctor ID"},
  {"path": "encounter_type", "type": "string", "label": "Encounter Type"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "encounter_date", "type": "date", "label": "Encounter Date"}
]'),
('lab', 'lab_order', 'Lab Order', '[
  {"path": "order_id", "type": "uuid", "label": "Order ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "test_id", "type": "uuid", "label": "Test ID"},
  {"path": "test_name", "type": "string", "label": "Test Name"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "priority", "type": "string", "label": "Priority"},
  {"path": "results", "type": "array", "label": "Results"},
  {"path": "results[].parameter_name", "type": "string", "label": "Parameter Name"},
  {"path": "results[].value", "type": "string", "label": "Value"},
  {"path": "results[].unit", "type": "string", "label": "Unit"},
  {"path": "results[].flag", "type": "string", "label": "Flag"}
]'),
('pharmacy', 'pharmacy_order', 'Pharmacy Order', '[
  {"path": "order_id", "type": "uuid", "label": "Order ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "prescription_id", "type": "uuid", "label": "Prescription ID"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "items", "type": "array", "label": "Items"},
  {"path": "items[].drug_name", "type": "string", "label": "Drug Name"},
  {"path": "items[].quantity", "type": "number", "label": "Quantity"},
  {"path": "items[].unit_price", "type": "decimal", "label": "Unit Price"},
  {"path": "dispensed_at", "type": "timestamp", "label": "Dispensed At"}
]'),
('billing', 'invoice', 'Invoice', '[
  {"path": "invoice_id", "type": "uuid", "label": "Invoice ID"},
  {"path": "invoice_number", "type": "string", "label": "Invoice Number"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "subtotal", "type": "decimal", "label": "Subtotal"},
  {"path": "tax_amount", "type": "decimal", "label": "Tax Amount"},
  {"path": "total_amount", "type": "decimal", "label": "Total Amount"},
  {"path": "paid_amount", "type": "decimal", "label": "Paid Amount"}
]'),
('ipd', 'admission', 'IPD Admission', '[
  {"path": "admission_id", "type": "uuid", "label": "Admission ID"},
  {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "patient_name", "type": "string", "label": "Patient Name"},
  {"path": "uhid", "type": "string", "label": "UHID"},
  {"path": "bed_id", "type": "uuid", "label": "Bed ID"},
  {"path": "admitting_doctor", "type": "uuid", "label": "Admitting Doctor"},
  {"path": "department_id", "type": "uuid", "label": "Department ID"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "admitted_at", "type": "timestamp", "label": "Admitted At"}
]'),
('indent', 'indent_requisition', 'Indent Requisition', '[
  {"path": "requisition_id", "type": "uuid", "label": "Requisition ID"},
  {"path": "indent_number", "type": "string", "label": "Indent Number"},
  {"path": "department_id", "type": "uuid", "label": "Department ID"},
  {"path": "requested_by", "type": "uuid", "label": "Requested By"},
  {"path": "indent_type", "type": "string", "label": "Indent Type"},
  {"path": "priority", "type": "string", "label": "Priority"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "total_amount", "type": "decimal", "label": "Total Amount"},
  {"path": "items", "type": "array", "label": "Items"},
  {"path": "items[].item_name", "type": "string", "label": "Item Name"},
  {"path": "items[].quantity_requested", "type": "number", "label": "Quantity Requested"},
  {"path": "items[].unit_price", "type": "decimal", "label": "Unit Price"}
]'),
('opd', 'prescription', 'Prescription', '[
  {"path": "prescription_id", "type": "uuid", "label": "Prescription ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
  {"path": "doctor_id", "type": "uuid", "label": "Doctor ID"},
  {"path": "items", "type": "array", "label": "Items"},
  {"path": "items[].drug_name", "type": "string", "label": "Drug Name"},
  {"path": "items[].dosage", "type": "string", "label": "Dosage"},
  {"path": "items[].frequency", "type": "string", "label": "Frequency"},
  {"path": "items[].duration", "type": "string", "label": "Duration"},
  {"path": "items[].route", "type": "string", "label": "Route"},
  {"path": "notes", "type": "string", "label": "Notes"},
  {"path": "created_at", "type": "timestamp", "label": "Created At"}
]')
ON CONFLICT (module_code, entity_code) DO NOTHING;


-- ═══════════════════════════════════════════════════════════
--  3. Event Schemas
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS event_schemas (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type      TEXT NOT NULL UNIQUE,
    module_code     TEXT NOT NULL,
    label           TEXT NOT NULL,
    description     TEXT,
    payload_schema  JSONB NOT NULL DEFAULT '[]',
    entity_code     TEXT
);

INSERT INTO event_schemas (event_type, module_code, label, description, payload_schema, entity_code) VALUES
('patient.registered', 'patients', 'Patient Registered', 'Fired when a new patient is registered', '[
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "uhid", "type": "string", "label": "UHID"},
  {"path": "first_name", "type": "string", "label": "First Name"},
  {"path": "last_name", "type": "string", "label": "Last Name"},
  {"path": "full_name", "type": "string", "label": "Full Name"},
  {"path": "date_of_birth", "type": "date", "label": "Date of Birth"},
  {"path": "gender", "type": "string", "label": "Gender"},
  {"path": "phone", "type": "string", "label": "Phone"},
  {"path": "email", "type": "string", "label": "Email"},
  {"path": "category", "type": "string", "label": "Category"},
  {"path": "registration_type", "type": "string", "label": "Registration Type"},
  {"path": "created_at", "type": "timestamp", "label": "Created At"}
]', 'patient'),
('encounter.created', 'opd', 'Encounter Created', 'Fired when an OPD encounter is created', '[
  {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "patient_name", "type": "string", "label": "Patient Name"},
  {"path": "uhid", "type": "string", "label": "UHID"},
  {"path": "department_id", "type": "uuid", "label": "Department ID"},
  {"path": "doctor_id", "type": "uuid", "label": "Doctor ID"},
  {"path": "encounter_type", "type": "string", "label": "Encounter Type"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "encounter_date", "type": "date", "label": "Encounter Date"}
]', 'encounter'),
('prescription.created', 'opd', 'Prescription Created', 'Fired when a prescription is created', '[
  {"path": "prescription_id", "type": "uuid", "label": "Prescription ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
  {"path": "doctor_id", "type": "uuid", "label": "Doctor ID"},
  {"path": "items", "type": "array", "label": "Items"},
  {"path": "items[].drug_name", "type": "string", "label": "Drug Name"},
  {"path": "items[].dosage", "type": "string", "label": "Dosage"},
  {"path": "items[].frequency", "type": "string", "label": "Frequency"},
  {"path": "items[].duration", "type": "string", "label": "Duration"},
  {"path": "items[].route", "type": "string", "label": "Route"},
  {"path": "notes", "type": "string", "label": "Notes"},
  {"path": "created_at", "type": "timestamp", "label": "Created At"}
]', 'prescription'),
('order.dispensed', 'pharmacy', 'Order Dispensed', 'Fired when a pharmacy order is dispensed', '[
  {"path": "order_id", "type": "uuid", "label": "Order ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "prescription_id", "type": "uuid", "label": "Prescription ID"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "items", "type": "array", "label": "Items"},
  {"path": "items[].drug_name", "type": "string", "label": "Drug Name"},
  {"path": "items[].quantity", "type": "number", "label": "Quantity"},
  {"path": "items[].unit_price", "type": "decimal", "label": "Unit Price"},
  {"path": "dispensed_at", "type": "timestamp", "label": "Dispensed At"}
]', 'pharmacy_order'),
('stock.low', 'pharmacy', 'Stock Low', 'Fired when stock falls below reorder level', '[
  {"path": "catalog_item_id", "type": "uuid", "label": "Catalog Item ID"},
  {"path": "item_code", "type": "string", "label": "Item Code"},
  {"path": "item_name", "type": "string", "label": "Item Name"},
  {"path": "current_stock", "type": "number", "label": "Current Stock"},
  {"path": "reorder_level", "type": "number", "label": "Reorder Level"},
  {"path": "category", "type": "string", "label": "Category"}
]', NULL),
('indent.submitted', 'indent', 'Indent Submitted', 'Fired when an indent requisition is submitted', '[
  {"path": "requisition_id", "type": "uuid", "label": "Requisition ID"},
  {"path": "indent_number", "type": "string", "label": "Indent Number"},
  {"path": "department_id", "type": "uuid", "label": "Department ID"},
  {"path": "requested_by", "type": "uuid", "label": "Requested By"},
  {"path": "indent_type", "type": "string", "label": "Indent Type"},
  {"path": "priority", "type": "string", "label": "Priority"},
  {"path": "items", "type": "array", "label": "Items"},
  {"path": "items[].item_name", "type": "string", "label": "Item Name"},
  {"path": "items[].quantity_requested", "type": "number", "label": "Quantity Requested"},
  {"path": "items[].unit_price", "type": "decimal", "label": "Unit Price"},
  {"path": "total_amount", "type": "decimal", "label": "Total Amount"}
]', 'indent_requisition'),
('indent.approved', 'indent', 'Indent Approved', 'Fired when an indent requisition is approved', '[
  {"path": "requisition_id", "type": "uuid", "label": "Requisition ID"},
  {"path": "indent_number", "type": "string", "label": "Indent Number"},
  {"path": "department_id", "type": "uuid", "label": "Department ID"},
  {"path": "approved_by", "type": "uuid", "label": "Approved By"},
  {"path": "items", "type": "array", "label": "Items"},
  {"path": "items[].item_name", "type": "string", "label": "Item Name"},
  {"path": "items[].quantity_approved", "type": "number", "label": "Quantity Approved"},
  {"path": "approved_at", "type": "timestamp", "label": "Approved At"}
]', 'indent_requisition'),
('lab.completed', 'lab', 'Lab Test Completed', 'Fired when lab results are verified and complete', '[
  {"path": "order_id", "type": "uuid", "label": "Order ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "test_id", "type": "uuid", "label": "Test ID"},
  {"path": "test_name", "type": "string", "label": "Test Name"},
  {"path": "status", "type": "string", "label": "Status"},
  {"path": "results", "type": "array", "label": "Results"},
  {"path": "results[].parameter_name", "type": "string", "label": "Parameter Name"},
  {"path": "results[].value", "type": "string", "label": "Value"},
  {"path": "results[].unit", "type": "string", "label": "Unit"},
  {"path": "results[].flag", "type": "string", "label": "Flag"},
  {"path": "verified_by", "type": "uuid", "label": "Verified By"},
  {"path": "completed_at", "type": "timestamp", "label": "Completed At"}
]', 'lab_order'),
('admission.created', 'ipd', 'Patient Admitted', 'Fired when a patient is admitted to IPD', '[
  {"path": "admission_id", "type": "uuid", "label": "Admission ID"},
  {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "patient_name", "type": "string", "label": "Patient Name"},
  {"path": "uhid", "type": "string", "label": "UHID"},
  {"path": "bed_id", "type": "uuid", "label": "Bed ID"},
  {"path": "admitting_doctor", "type": "uuid", "label": "Admitting Doctor"},
  {"path": "department_id", "type": "uuid", "label": "Department ID"},
  {"path": "admitted_at", "type": "timestamp", "label": "Admitted At"}
]', 'admission'),
('discharge.completed', 'ipd', 'Patient Discharged', 'Fired when a patient is discharged', '[
  {"path": "admission_id", "type": "uuid", "label": "Admission ID"},
  {"path": "encounter_id", "type": "uuid", "label": "Encounter ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "discharge_type", "type": "string", "label": "Discharge Type"},
  {"path": "discharge_summary", "type": "string", "label": "Discharge Summary"},
  {"path": "discharged_at", "type": "timestamp", "label": "Discharged At"}
]', 'admission'),
('invoice.created', 'billing', 'Invoice Created', 'Fired when a new invoice is created', '[
  {"path": "invoice_id", "type": "uuid", "label": "Invoice ID"},
  {"path": "patient_id", "type": "uuid", "label": "Patient ID"},
  {"path": "invoice_number", "type": "string", "label": "Invoice Number"},
  {"path": "total_amount", "type": "decimal", "label": "Total Amount"}
]', 'invoice'),
('payment.recorded', 'billing', 'Payment Recorded', 'Fired when a payment is recorded against an invoice', '[
  {"path": "payment_id", "type": "uuid", "label": "Payment ID"},
  {"path": "invoice_id", "type": "uuid", "label": "Invoice ID"},
  {"path": "amount", "type": "decimal", "label": "Amount"},
  {"path": "method", "type": "string", "label": "Payment Method"}
]', 'invoice')
ON CONFLICT (event_type) DO NOTHING;
