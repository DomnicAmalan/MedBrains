-- Migration 036: Structured Consultation Fields
-- Adds ICD-10 catalog, chief complaint masters, structured consultation columns,
-- and enhanced diagnosis fields.

-- ============================================================
-- ICD-10 Reference Catalog (GLOBAL — not tenant-scoped)
-- ============================================================

CREATE TABLE IF NOT EXISTS icd10_codes (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            VARCHAR(10) NOT NULL UNIQUE,
    short_desc      TEXT NOT NULL,
    long_desc       TEXT,
    category        VARCHAR(20),
    chapter         VARCHAR(10),
    is_billable     BOOLEAN NOT NULL DEFAULT true,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_icd10_code ON icd10_codes(code);
CREATE INDEX idx_icd10_search ON icd10_codes USING gin(to_tsvector('english', short_desc));

-- ============================================================
-- Chief Complaint Masters (tenant-scoped)
-- ============================================================

CREATE TABLE IF NOT EXISTS chief_complaint_masters (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            VARCHAR(200) NOT NULL,
    category        VARCHAR(100),
    synonyms        TEXT[] DEFAULT '{}',
    suggested_icd   TEXT[] DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cc_tenant ON chief_complaint_masters(tenant_id);
CREATE INDEX idx_cc_search ON chief_complaint_masters USING gin(to_tsvector('english', name));

ALTER TABLE chief_complaint_masters ENABLE ROW LEVEL SECURITY;
CREATE POLICY chief_complaint_masters_tenant ON chief_complaint_masters
    USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ============================================================
-- Extend consultations with structured fields
-- ============================================================

ALTER TABLE consultations
    ADD COLUMN IF NOT EXISTS hpi TEXT,
    ADD COLUMN IF NOT EXISTS past_medical_history JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS past_surgical_history JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS family_history JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS social_history JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS review_of_systems JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS physical_examination JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS general_appearance TEXT;

-- ============================================================
-- Enhance diagnoses with clinical attributes
-- ============================================================

ALTER TABLE diagnoses
    ADD COLUMN IF NOT EXISTS severity VARCHAR(20) DEFAULT 'moderate',
    ADD COLUMN IF NOT EXISTS certainty VARCHAR(20) DEFAULT 'confirmed',
    ADD COLUMN IF NOT EXISTS onset_date DATE,
    ADD COLUMN IF NOT EXISTS resolved_date DATE;

-- ============================================================
-- Seed ICD-10 codes (100 most common outpatient codes)
-- ============================================================

INSERT INTO icd10_codes (code, short_desc, category, chapter, is_billable) VALUES
-- Infectious & Parasitic
('A09', 'Infectious gastroenteritis and colitis, unspecified', 'A00-B99', 'I', true),
('B34.9', 'Viral infection, unspecified', 'A00-B99', 'I', true),
('A15.0', 'Tuberculosis of lung', 'A00-B99', 'I', true),
('B50.9', 'Plasmodium falciparum malaria, unspecified', 'A00-B99', 'I', true),
('A01.0', 'Typhoid fever', 'A00-B99', 'I', true),
('B01.9', 'Varicella without complication', 'A00-B99', 'I', true),
-- Neoplasms
('C50.9', 'Malignant neoplasm of breast, unspecified', 'C00-D49', 'II', true),
('D25.9', 'Leiomyoma of uterus, unspecified', 'C00-D49', 'II', true),
-- Blood disorders
('D50.9', 'Iron deficiency anaemia, unspecified', 'D50-D89', 'III', true),
('D64.9', 'Anaemia, unspecified', 'D50-D89', 'III', true),
-- Endocrine/Metabolic
('E11.9', 'Type 2 diabetes mellitus without complications', 'E00-E89', 'IV', true),
('E10.9', 'Type 1 diabetes mellitus without complications', 'E00-E89', 'IV', true),
('E03.9', 'Hypothyroidism, unspecified', 'E00-E89', 'IV', true),
('E05.9', 'Thyrotoxicosis, unspecified', 'E00-E89', 'IV', true),
('E78.5', 'Hyperlipidaemia, unspecified', 'E00-E89', 'IV', true),
('E66.9', 'Obesity, unspecified', 'E00-E89', 'IV', true),
('E55.9', 'Vitamin D deficiency, unspecified', 'E00-E89', 'IV', true),
-- Mental/Behavioural
('F32.9', 'Depressive episode, unspecified', 'F01-F99', 'V', true),
('F41.1', 'Generalized anxiety disorder', 'F01-F99', 'V', true),
('F41.9', 'Anxiety disorder, unspecified', 'F01-F99', 'V', true),
('F10.2', 'Alcohol dependence syndrome', 'F01-F99', 'V', true),
-- Nervous system
('G43.9', 'Migraine, unspecified', 'G00-G99', 'VI', true),
('G40.9', 'Epilepsy, unspecified', 'G00-G99', 'VI', true),
('G47.0', 'Insomnia', 'G00-G99', 'VI', true),
-- Eye
('H10.9', 'Conjunctivitis, unspecified', 'H00-H59', 'VII', true),
('H52.1', 'Myopia', 'H00-H59', 'VII', true),
-- Ear
('H66.9', 'Otitis media, unspecified', 'H60-H95', 'VIII', true),
('H65.9', 'Nonsuppurative otitis media, unspecified', 'H60-H95', 'VIII', true),
-- Circulatory
('I10', 'Essential (primary) hypertension', 'I00-I99', 'IX', true),
('I25.1', 'Atherosclerotic heart disease', 'I00-I99', 'IX', true),
('I20.9', 'Angina pectoris, unspecified', 'I00-I99', 'IX', true),
('I50.9', 'Heart failure, unspecified', 'I00-I99', 'IX', true),
('I48.9', 'Atrial fibrillation, unspecified', 'I00-I99', 'IX', true),
('I63.9', 'Cerebral infarction, unspecified', 'I00-I99', 'IX', true),
('I84.9', 'Haemorrhoids, unspecified', 'I00-I99', 'IX', true),
-- Respiratory
('J06.9', 'Acute upper respiratory infection, unspecified', 'J00-J99', 'X', true),
('J18.9', 'Pneumonia, unspecified organism', 'J00-J99', 'X', true),
('J45.9', 'Asthma, unspecified', 'J00-J99', 'X', true),
('J44.1', 'COPD with acute exacerbation', 'J00-J99', 'X', true),
('J02.9', 'Acute pharyngitis, unspecified', 'J00-J99', 'X', true),
('J01.9', 'Acute sinusitis, unspecified', 'J00-J99', 'X', true),
('J20.9', 'Acute bronchitis, unspecified', 'J00-J99', 'X', true),
('J30.1', 'Allergic rhinitis due to pollen', 'J00-J99', 'X', true),
('J00', 'Acute nasopharyngitis (common cold)', 'J00-J99', 'X', true),
-- Digestive
('K21.0', 'GERD with oesophagitis', 'K00-K93', 'XI', true),
('K29.7', 'Gastritis, unspecified', 'K00-K93', 'XI', true),
('K30', 'Functional dyspepsia', 'K00-K93', 'XI', true),
('K59.0', 'Constipation', 'K00-K93', 'XI', true),
('K40.9', 'Inguinal hernia without obstruction or gangrene', 'K00-K93', 'XI', true),
('K80.2', 'Calculus of gallbladder without cholecystitis', 'K00-K93', 'XI', true),
('K35.8', 'Acute appendicitis, other and unspecified', 'K00-K93', 'XI', true),
('K58.9', 'Irritable bowel syndrome without diarrhoea', 'K00-K93', 'XI', true),
-- Skin
('L50.9', 'Urticaria, unspecified', 'L00-L99', 'XII', true),
('L30.9', 'Dermatitis, unspecified', 'L00-L99', 'XII', true),
('L20.9', 'Atopic dermatitis, unspecified', 'L00-L99', 'XII', true),
('L02.9', 'Cutaneous abscess, furuncle and carbuncle, unspecified', 'L00-L99', 'XII', true),
('B35.9', 'Dermatophytosis, unspecified', 'L00-L99', 'XII', true),
-- Musculoskeletal
('M54.5', 'Low back pain', 'M00-M99', 'XIII', true),
('M54.2', 'Cervicalgia', 'M00-M99', 'XIII', true),
('M79.3', 'Panniculitis, unspecified', 'M00-M99', 'XIII', true),
('M25.5', 'Pain in joint', 'M00-M99', 'XIII', true),
('M17.9', 'Gonarthrosis, unspecified', 'M00-M99', 'XIII', true),
('M06.9', 'Rheumatoid arthritis, unspecified', 'M00-M99', 'XIII', true),
('M81.9', 'Osteoporosis, unspecified', 'M00-M99', 'XIII', true),
('M75.1', 'Rotator cuff syndrome', 'M00-M99', 'XIII', true),
-- Genitourinary
('N39.0', 'Urinary tract infection, site not specified', 'N00-N99', 'XIV', true),
('N40', 'Benign prostatic hyperplasia', 'N00-N99', 'XIV', true),
('N20.0', 'Calculus of kidney', 'N00-N99', 'XIV', true),
('N76.0', 'Acute vaginitis', 'N00-N99', 'XIV', true),
('N92.1', 'Excessive and frequent menstruation with irregular cycle', 'N00-N99', 'XIV', true),
-- Pregnancy/Obstetric
('O80', 'Single spontaneous delivery', 'O00-O9A', 'XV', true),
('O21.0', 'Mild hyperemesis gravidarum', 'O00-O9A', 'XV', true),
('O13', 'Gestational hypertension', 'O00-O9A', 'XV', true),
('O24.4', 'Gestational diabetes mellitus', 'O00-O9A', 'XV', true),
-- Perinatal
('P59.9', 'Neonatal jaundice, unspecified', 'P00-P96', 'XVI', true),
-- Symptoms/Signs
('R50.9', 'Fever, unspecified', 'R00-R99', 'XVIII', true),
('R10.4', 'Other and unspecified abdominal pain', 'R00-R99', 'XVIII', true),
('R51', 'Headache', 'R00-R99', 'XVIII', true),
('R05', 'Cough', 'R00-R99', 'XVIII', true),
('R11.1', 'Nausea with vomiting, unspecified', 'R00-R99', 'XVIII', true),
('R42', 'Dizziness and giddiness', 'R00-R99', 'XVIII', true),
('R07.9', 'Chest pain, unspecified', 'R00-R99', 'XVIII', true),
('R53.1', 'Weakness', 'R00-R99', 'XVIII', true),
('R19.7', 'Diarrhoea, unspecified', 'R00-R99', 'XVIII', true),
('R73.0', 'Abnormal glucose', 'R00-R99', 'XVIII', true),
-- Injury/Poisoning
('S62.5', 'Fracture of thumb', 'S00-T88', 'XIX', true),
('S52.5', 'Fracture of lower end of radius', 'S00-T88', 'XIX', true),
('S82.0', 'Fracture of patella', 'S00-T88', 'XIX', true),
('T78.4', 'Allergy, unspecified', 'S00-T88', 'XIX', true),
-- External causes
('W19', 'Unspecified fall', 'V00-Y99', 'XX', true),
-- Factors influencing health
('Z00.0', 'Encounter for general adult medical examination', 'Z00-Z99', 'XXI', true),
('Z23', 'Encounter for immunization', 'Z00-Z99', 'XXI', true),
('Z30.0', 'Encounter for general counseling on contraception', 'Z00-Z99', 'XXI', true),
('Z34.0', 'Supervision of normal first pregnancy', 'Z00-Z99', 'XXI', true),
('Z76.0', 'Encounter for issue of repeat prescription', 'Z00-Z99', 'XXI', true),
('Z01.0', 'Encounter for examination of eyes and vision', 'Z00-Z99', 'XXI', true)
ON CONFLICT (code) DO NOTHING;

-- ============================================================
-- Seed Chief Complaint Masters for all tenants
-- ============================================================

INSERT INTO chief_complaint_masters (tenant_id, name, category, synonyms, suggested_icd)
SELECT t.id,
       cc.name,
       cc.category,
       cc.synonyms,
       cc.suggested_icd
FROM tenants t
CROSS JOIN (VALUES
    ('Fever', 'General', ARRAY['pyrexia','high temperature','febrile'], ARRAY['R50.9']),
    ('Headache', 'General', ARRAY['cephalalgia','head pain','migraine'], ARRAY['R51','G43.9']),
    ('Cough', 'Respiratory', ARRAY['dry cough','wet cough','productive cough'], ARRAY['R05','J06.9']),
    ('Cold', 'Respiratory', ARRAY['common cold','runny nose','nasal congestion','coryza'], ARRAY['J00','J30.1']),
    ('Sore Throat', 'Respiratory', ARRAY['pharyngitis','throat pain','tonsillitis'], ARRAY['J02.9']),
    ('Breathlessness', 'Respiratory', ARRAY['dyspnoea','shortness of breath','SOB'], ARRAY['J45.9','J44.1']),
    ('Chest Pain', 'Cardiovascular', ARRAY['angina','chest discomfort','precordial pain'], ARRAY['R07.9','I20.9']),
    ('Abdominal Pain', 'GI', ARRAY['stomach ache','belly pain','epigastric pain'], ARRAY['R10.4','K30']),
    ('Nausea/Vomiting', 'GI', ARRAY['emesis','morning sickness','retching'], ARRAY['R11.1']),
    ('Diarrhoea', 'GI', ARRAY['loose stools','watery stools','dysentery'], ARRAY['R19.7','A09']),
    ('Constipation', 'GI', ARRAY['hard stools','difficulty passing stool'], ARRAY['K59.0']),
    ('Back Pain', 'Musculoskeletal', ARRAY['lumbago','low back pain','lumbar pain'], ARRAY['M54.5']),
    ('Joint Pain', 'Musculoskeletal', ARRAY['arthralgia','knee pain','shoulder pain'], ARRAY['M25.5','M17.9']),
    ('Neck Pain', 'Musculoskeletal', ARRAY['cervicalgia','stiff neck'], ARRAY['M54.2']),
    ('Dizziness', 'Neurological', ARRAY['vertigo','giddiness','lightheadedness'], ARRAY['R42']),
    ('Weakness', 'General', ARRAY['fatigue','tiredness','malaise','lethargy'], ARRAY['R53.1']),
    ('Skin Rash', 'Dermatological', ARRAY['rash','eruption','hives','urticaria'], ARRAY['L50.9','L30.9']),
    ('Itching', 'Dermatological', ARRAY['pruritus','scratching'], ARRAY['L30.9']),
    ('Eye Problem', 'Ophthalmological', ARRAY['red eye','eye pain','blurred vision'], ARRAY['H10.9','H52.1']),
    ('Ear Pain', 'ENT', ARRAY['otalgia','earache'], ARRAY['H66.9']),
    ('Burning Micturition', 'Urological', ARRAY['dysuria','UTI symptoms','painful urination'], ARRAY['N39.0']),
    ('Menstrual Irregularity', 'Gynaecological', ARRAY['irregular periods','heavy periods','amenorrhoea'], ARRAY['N92.1']),
    ('Pregnancy Checkup', 'Obstetric', ARRAY['antenatal visit','ANC','prenatal'], ARRAY['Z34.0']),
    ('Diabetes Follow-up', 'Endocrine', ARRAY['DM review','sugar check','HbA1c review'], ARRAY['E11.9']),
    ('Hypertension Follow-up', 'Cardiovascular', ARRAY['BP check','HTN review','blood pressure'], ARRAY['I10']),
    ('Anxiety', 'Psychiatry', ARRAY['nervousness','panic','anxious'], ARRAY['F41.9','F41.1']),
    ('Insomnia', 'Psychiatry', ARRAY['sleeplessness','difficulty sleeping','sleep disorder'], ARRAY['G47.0']),
    ('Weight Loss', 'General', ARRAY['losing weight','unintentional weight loss'], ARRAY['R63.4']),
    ('Vaccination', 'Preventive', ARRAY['immunization','vaccine','booster'], ARRAY['Z23']),
    ('General Checkup', 'Preventive', ARRAY['health screening','annual exam','routine checkup'], ARRAY['Z00.0'])
) AS cc(name, category, synonyms, suggested_icd);
