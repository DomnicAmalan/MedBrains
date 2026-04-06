-- Migration 077: OPD Phase 2
-- Adds: SNOMED CT code reference table, diagnosis SNOMED fields, appointment grouping

-- ══════════════════════════════════════════════════════════
--  SNOMED CT Codes (global — NOT tenant-scoped, like icd10_codes)
-- ══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS snomed_codes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(20)  NOT NULL UNIQUE,
    display_name  TEXT         NOT NULL,
    semantic_tag  VARCHAR(100),
    is_active     BOOLEAN      NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_snomed_codes_code ON snomed_codes (code);

-- Trigram index for fuzzy search (requires pg_trgm extension — already enabled in 001)
CREATE INDEX IF NOT EXISTS idx_snomed_codes_display_trgm
    ON snomed_codes USING gin (display_name gin_trgm_ops);

-- ══════════════════════════════════════════════════════════
--  ALTER diagnoses — add SNOMED fields
-- ══════════════════════════════════════════════════════════

ALTER TABLE diagnoses
    ADD COLUMN IF NOT EXISTS snomed_code    VARCHAR(20),
    ADD COLUMN IF NOT EXISTS snomed_display TEXT;

-- ══════════════════════════════════════════════════════════
--  ALTER appointments — add group booking
-- ══════════════════════════════════════════════════════════

ALTER TABLE appointments
    ADD COLUMN IF NOT EXISTS appointment_group_id UUID;

CREATE INDEX IF NOT EXISTS idx_appointments_group_id
    ON appointments (appointment_group_id)
    WHERE appointment_group_id IS NOT NULL;

-- ══════════════════════════════════════════════════════════
--  Seed: 100 common SNOMED CT clinical finding codes
-- ══════════════════════════════════════════════════════════

INSERT INTO snomed_codes (code, display_name, semantic_tag) VALUES
-- Cardiovascular
('38341003',  'Hypertensive disorder',                   'disorder'),
('49436004',  'Atrial fibrillation',                     'disorder'),
('53741008',  'Coronary arteriosclerosis',                'disorder'),
('22298006',  'Myocardial infarction',                   'disorder'),
('84114007',  'Heart failure',                           'disorder'),
('29857009',  'Chest pain',                              'finding'),
('698247007', 'Cardiac arrhythmia',                      'disorder'),
('59621000',  'Essential hypertension',                  'disorder'),
('233604007', 'Pneumonia',                               'disorder'),
('195967001', 'Asthma',                                  'disorder'),

-- Respiratory
('13645005',  'Chronic obstructive lung disease',        'disorder'),
('36971009',  'Sinusitis',                               'disorder'),
('68566005',  'Urinary tract infection',                 'disorder'),
('54150009',  'Upper respiratory infection',             'disorder'),
('301011002', 'Cough',                                   'finding'),
('267036007', 'Dyspnea',                                 'finding'),
('11833005',  'Dry cough',                               'finding'),
('24199005',  'Feeling agitated',                        'finding'),

-- Endocrine & Metabolic
('73211009',  'Diabetes mellitus',                       'disorder'),
('44054006',  'Diabetes mellitus type 2',                'disorder'),
('46635009',  'Diabetes mellitus type 1',                'disorder'),
('40930008',  'Hypothyroidism',                          'disorder'),
('34486009',  'Hyperthyroidism',                         'disorder'),
('190828008', 'Hyperlipidemia',                          'disorder'),
('14304000',  'Thyroid disorder',                        'disorder'),
('267384006', 'Obesity',                                 'finding'),

-- Gastrointestinal
('235595009', 'Gastroesophageal reflux disease',         'disorder'),
('25374005',  'Gastroenteritis',                         'disorder'),
('396275006', 'Osteoarthritis',                          'disorder'),
('34840004',  'Tendinitis',                              'disorder'),
('21522001',  'Abdominal pain',                          'finding'),
('62315008',  'Diarrhea',                                'finding'),
('422587007', 'Nausea',                                  'finding'),
('249497008', 'Vomiting symptom',                        'finding'),
('235856003', 'Hepatitis',                               'disorder'),
('197321007', 'Steatosis of liver',                      'disorder'),

-- Musculoskeletal
('69896004',  'Rheumatoid arthritis',                    'disorder'),
('239873007', 'Osteoporosis',                            'disorder'),
('161891005', 'Back pain',                               'finding'),
('57676002',  'Joint pain',                              'finding'),
('125605004', 'Fracture of bone',                        'disorder'),
('263102004', 'Fracture of femur',                       'disorder'),
('65966004',  'Fracture of forearm',                     'disorder'),
('33737001',  'Fracture of rib',                         'disorder'),

-- Neurological
('230690007', 'Cerebrovascular accident',                'disorder'),
('37796009',  'Migraine',                                'disorder'),
('84757009',  'Epilepsy',                                'disorder'),
('25064002',  'Headache',                                'finding'),
('404640003', 'Dizziness',                               'finding'),
('62106007',  'Concussion',                              'disorder'),
('39848009',  'Whiplash injury',                         'disorder'),
('386661006', 'Fever',                                   'finding'),

-- Mental Health
('35489007',  'Depressive disorder',                     'disorder'),
('197480006', 'Anxiety disorder',                        'disorder'),
('91487003',  'Social anxiety disorder',                 'disorder'),
('13746004',  'Bipolar disorder',                        'disorder'),

-- Renal & Urological
('90708001',  'Kidney disease',                          'disorder'),
('431855005', 'Chronic kidney disease',                  'disorder'),
('95570007',  'Kidney stone',                            'disorder'),
('197927001', 'Benign prostatic hyperplasia',            'disorder'),

-- Infectious
('840539006', 'COVID-19',                                'disorder'),
('186747009', 'Malaria',                                 'disorder'),
('56717001',  'Tuberculosis',                            'disorder'),
('266096002', 'Human immunodeficiency virus infection',  'disorder'),
('6142004',   'Influenza',                               'disorder'),
('38907003',  'Varicella',                               'disorder'),
('302215000', 'Thrombocytopenic disorder',               'disorder'),
('409966000', 'Dengue hemorrhagic fever',                'disorder'),

-- Dermatological
('200936003', 'Dermatitis',                              'disorder'),
('238575004', 'Cellulitis',                              'disorder'),
('64572001',  'Disease',                                 'disorder'),
('126485001', 'Urticaria',                               'disorder'),

-- Hematological
('271737000', 'Anemia',                                  'disorder'),
('35434009',  'Sickle cell anemia',                      'disorder'),
('87522002',  'Iron deficiency anemia',                  'disorder'),
('109989006', 'Multiple myeloma',                        'disorder'),

-- Ophthalmological
('193570009', 'Cataract',                                'disorder'),
('23986001',  'Glaucoma',                                'disorder'),
('4855003',   'Retinal detachment',                      'disorder'),
('246636008', 'Blurred vision',                          'finding'),

-- ENT
('194828000', 'Allergic rhinitis',                       'disorder'),
('78275009',  'Obstructive sleep apnea syndrome',        'disorder'),
('15188001',  'Hearing loss',                            'finding'),
('60862001',  'Tinnitus',                                'finding'),

-- Obstetric & Gynecological
('72892002',  'Normal pregnancy',                        'finding'),
('17382005',  'Pre-eclampsia',                           'disorder'),
('129103003', 'Endometriosis',                           'disorder'),
('266599000', 'Dysmenorrhea',                            'finding'),

-- Pediatric
('367498001', 'Seasonal allergic rhinitis',              'disorder'),
('49727002',  'Croup',                                   'disorder'),
('50417007',  'Neonatal jaundice',                       'disorder'),
('95659009',  'Febrile convulsion',                      'disorder'),

-- Oncological
('363346000', 'Malignant neoplastic disease',            'disorder'),
('254637007', 'Non-small cell lung cancer',              'disorder'),
('93761005',  'Primary malignant neoplasm of colon',     'disorder'),
('254838004', 'Carcinoma of breast',                     'disorder'),

-- Procedures & Findings (common)
('18949003',  'Change in bowel habit',                   'finding'),
('248490000', 'Bloating symptom',                        'finding'),
('76948002',  'Severe pain',                             'finding'),
('22253000',  'Pain',                                    'finding'),
('271807003', 'Eruption of skin',                        'finding'),
('84229001',  'Fatigue',                                 'finding')

ON CONFLICT (code) DO NOTHING;
