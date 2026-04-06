-- MedBrains HMS — Clinical Form Definitions (OPD)
-- Seeds 4 clinical forms: opd_vitals, opd_consultation, opd_diagnosis, opd_prescription_item

-- ============================================================
-- Field Masters — OPD Vitals
-- ============================================================

INSERT INTO field_masters (id, code, name, description, data_type, placeholder, validation, ui_width, is_system, is_active) VALUES
    ('b1000000-0000-0000-0000-000000000001', 'vitals.temperature', 'Temperature (°F)', 'Body temperature in Fahrenheit', 'decimal', '98.6', '{"min": 90, "max": 110}', 'quarter', true, true),
    ('b1000000-0000-0000-0000-000000000002', 'vitals.pulse', 'Pulse (bpm)', 'Heart rate in beats per minute', 'number', '72', '{"min": 30, "max": 250}', 'quarter', true, true),
    ('b1000000-0000-0000-0000-000000000003', 'vitals.spo2', 'SpO2 (%)', 'Oxygen saturation percentage', 'number', '98', '{"min": 50, "max": 100}', 'quarter', true, true),
    ('b1000000-0000-0000-0000-000000000004', 'vitals.systolic_bp', 'Systolic BP (mmHg)', 'Systolic blood pressure', 'number', '120', '{"min": 50, "max": 300}', 'quarter', true, true),
    ('b1000000-0000-0000-0000-000000000005', 'vitals.diastolic_bp', 'Diastolic BP (mmHg)', 'Diastolic blood pressure', 'number', '80', '{"min": 20, "max": 200}', 'quarter', true, true),
    ('b1000000-0000-0000-0000-000000000006', 'vitals.respiratory_rate', 'Resp. Rate (/min)', 'Respiratory rate per minute', 'number', '16', '{"min": 5, "max": 60}', 'quarter', true, true),
    ('b1000000-0000-0000-0000-000000000007', 'vitals.weight_kg', 'Weight (kg)', 'Body weight in kilograms', 'decimal', '70', '{"min": 0.5, "max": 500}', 'quarter', true, true),
    ('b1000000-0000-0000-0000-000000000008', 'vitals.height_cm', 'Height (cm)', 'Height in centimeters', 'decimal', '170', '{"min": 20, "max": 300}', 'quarter', true, true);

-- ============================================================
-- Field Masters — OPD Consultation (SOAP)
-- ============================================================

INSERT INTO field_masters (id, code, name, description, data_type, placeholder, validation, ui_width, is_system, is_active) VALUES
    ('b1000000-0000-0000-0000-000000000010', 'consultation.chief_complaint', 'Chief Complaint', 'Patient''s primary reason for visit (subjective)', 'textarea', 'Describe the chief complaint...', '{"min_length": 1}', 'full', true, true),
    ('b1000000-0000-0000-0000-000000000011', 'consultation.history', 'History of Present Illness', 'Detailed history and associated symptoms', 'textarea', 'Document history and HPI...', NULL, 'full', true, true),
    ('b1000000-0000-0000-0000-000000000012', 'consultation.examination', 'Examination Findings', 'Physical examination findings (objective)', 'textarea', 'Document examination findings...', NULL, 'full', true, true),
    ('b1000000-0000-0000-0000-000000000013', 'consultation.plan', 'Treatment Plan', 'Assessment, plan, and follow-up instructions', 'textarea', 'Document treatment plan...', NULL, 'full', true, true);

-- ============================================================
-- Field Masters — OPD Diagnosis
-- ============================================================

INSERT INTO field_masters (id, code, name, description, data_type, placeholder, validation, ui_width, is_system, is_active) VALUES
    ('b1000000-0000-0000-0000-000000000020', 'diagnosis.description', 'Diagnosis', 'Diagnosis description', 'text', 'Enter diagnosis', '{"min_length": 1}', 'full', true, true),
    ('b1000000-0000-0000-0000-000000000021', 'diagnosis.icd_code', 'ICD-10 Code', 'ICD-10 classification code', 'text', 'e.g. J06.9', NULL, 'half', true, true),
    ('b1000000-0000-0000-0000-000000000022', 'diagnosis.is_primary', 'Primary Diagnosis', 'Whether this is the primary diagnosis', 'boolean', NULL, NULL, 'half', true, true);

-- ============================================================
-- Field Masters — OPD Prescription Item
-- ============================================================

INSERT INTO field_masters (id, code, name, description, data_type, placeholder, validation, ui_width, is_system, is_active) VALUES
    ('b1000000-0000-0000-0000-000000000030', 'prescription.drug_name', 'Drug Name', 'Name of the medication', 'text', 'Enter drug name', '{"min_length": 1}', 'half', true, true),
    ('b1000000-0000-0000-0000-000000000031', 'prescription.dosage', 'Dosage', 'Dosage amount and unit', 'text', 'e.g. 500mg', '{"min_length": 1}', 'half', true, true),
    ('b1000000-0000-0000-0000-000000000032', 'prescription.frequency', 'Frequency', 'How often to take', 'select', NULL, '{"options": ["OD", "BD", "TDS", "QID", "SOS", "PRN"]}', 'third', true, true),
    ('b1000000-0000-0000-0000-000000000033', 'prescription.duration', 'Duration', 'Duration of course', 'text', 'e.g. 5 days', NULL, 'third', true, true),
    ('b1000000-0000-0000-0000-000000000034', 'prescription.route', 'Route', 'Route of administration', 'select', NULL, '{"options": ["Oral", "IV", "IM", "SC", "Topical", "Inhalation"]}', 'third', true, true),
    ('b1000000-0000-0000-0000-000000000035', 'prescription.instructions', 'Instructions', 'Special instructions for the patient', 'textarea', 'e.g. Take after food', NULL, 'full', true, true);

-- ============================================================
-- Form Masters
-- ============================================================

INSERT INTO form_masters (id, code, name, version, status, config) VALUES
    ('b2000000-0000-0000-0000-000000000001', 'opd_vitals', 'Vital Signs', 1, 'active', '{"submit_label": "Save Vitals", "compact": true}'),
    ('b2000000-0000-0000-0000-000000000002', 'opd_consultation', 'Consultation Notes', 1, 'active', '{"submit_label": "Save Notes"}'),
    ('b2000000-0000-0000-0000-000000000003', 'opd_diagnosis', 'Diagnosis Entry', 1, 'active', '{"submit_label": "Add Diagnosis", "compact": true}'),
    ('b2000000-0000-0000-0000-000000000004', 'opd_prescription_item', 'Prescription Item', 1, 'active', '{"submit_label": "Add Item", "compact": true}');

-- ============================================================
-- Form Sections
-- ============================================================

INSERT INTO form_sections (id, form_id, code, name, sort_order, is_collapsible, is_default_open, icon, color) VALUES
    -- opd_vitals: 1 section
    ('b3000000-0000-0000-0000-000000000001', 'b2000000-0000-0000-0000-000000000001', 'vital_signs', 'Vital Signs', 1, false, true, 'IconHeartbeat', 'red'),
    -- opd_consultation: 4 SOAP sections
    ('b3000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000002', 'subjective', 'Subjective', 1, false, true, 'IconMessage', 'blue'),
    ('b3000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000002', 'objective', 'Objective', 2, false, true, 'IconEye', 'teal'),
    ('b3000000-0000-0000-0000-000000000004', 'b2000000-0000-0000-0000-000000000002', 'assessment', 'Assessment', 3, false, true, 'IconBrain', 'violet'),
    ('b3000000-0000-0000-0000-000000000005', 'b2000000-0000-0000-0000-000000000002', 'plan', 'Plan', 4, false, true, 'IconClipboard', 'green'),
    -- opd_diagnosis: 1 section
    ('b3000000-0000-0000-0000-000000000006', 'b2000000-0000-0000-0000-000000000003', 'diagnosis', 'Diagnosis', 1, false, true, 'IconStethoscope', 'orange'),
    -- opd_prescription_item: 1 section
    ('b3000000-0000-0000-0000-000000000007', 'b2000000-0000-0000-0000-000000000004', 'medication', 'Medication', 1, false, true, 'IconPill', 'green');

-- ============================================================
-- Form Fields — linking fields to form sections
-- ============================================================

INSERT INTO form_fields (id, form_id, section_id, field_id, sort_order, label_override, is_quick_mode) VALUES
    -- opd_vitals (8 fields in vital_signs section)
    ('b4000000-0000-0000-0000-000000000001', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 1, NULL, true),
    ('b4000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000002', 2, NULL, true),
    ('b4000000-0000-0000-0000-000000000003', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000003', 3, NULL, true),
    ('b4000000-0000-0000-0000-000000000004', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000004', 4, NULL, true),
    ('b4000000-0000-0000-0000-000000000005', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000005', 5, NULL, true),
    ('b4000000-0000-0000-0000-000000000006', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000006', 6, NULL, true),
    ('b4000000-0000-0000-0000-000000000007', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000007', 7, NULL, true),
    ('b4000000-0000-0000-0000-000000000008', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000008', 8, NULL, true),
    -- opd_consultation (4 fields, 1 per SOAP section)
    ('b4000000-0000-0000-0000-000000000010', 'b2000000-0000-0000-0000-000000000002', 'b3000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000010', 1, NULL, true),
    ('b4000000-0000-0000-0000-000000000011', 'b2000000-0000-0000-0000-000000000002', 'b3000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000011', 1, NULL, false),
    ('b4000000-0000-0000-0000-000000000012', 'b2000000-0000-0000-0000-000000000002', 'b3000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000012', 1, NULL, false),
    ('b4000000-0000-0000-0000-000000000013', 'b2000000-0000-0000-0000-000000000002', 'b3000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000013', 1, NULL, false),
    -- opd_diagnosis (3 fields)
    ('b4000000-0000-0000-0000-000000000020', 'b2000000-0000-0000-0000-000000000003', 'b3000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000020', 1, NULL, true),
    ('b4000000-0000-0000-0000-000000000021', 'b2000000-0000-0000-0000-000000000003', 'b3000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000021', 2, NULL, false),
    ('b4000000-0000-0000-0000-000000000022', 'b2000000-0000-0000-0000-000000000003', 'b3000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000022', 3, NULL, false),
    -- opd_prescription_item (6 fields)
    ('b4000000-0000-0000-0000-000000000030', 'b2000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000030', 1, NULL, true),
    ('b4000000-0000-0000-0000-000000000031', 'b2000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000031', 2, NULL, true),
    ('b4000000-0000-0000-0000-000000000032', 'b2000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000032', 3, NULL, true),
    ('b4000000-0000-0000-0000-000000000033', 'b2000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000033', 4, NULL, false),
    ('b4000000-0000-0000-0000-000000000034', 'b2000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000034', 5, NULL, false),
    ('b4000000-0000-0000-0000-000000000035', 'b2000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000035', 6, NULL, false);

-- ============================================================
-- Module Form Links
-- ============================================================

INSERT INTO module_form_links (module_code, form_id, context) VALUES
    ('opd', 'b2000000-0000-0000-0000-000000000001', 'vitals'),
    ('opd', 'b2000000-0000-0000-0000-000000000002', 'consultation'),
    ('opd', 'b2000000-0000-0000-0000-000000000003', 'diagnosis'),
    ('opd', 'b2000000-0000-0000-0000-000000000004', 'prescription');
