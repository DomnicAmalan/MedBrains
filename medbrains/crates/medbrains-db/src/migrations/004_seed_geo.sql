-- MedBrains HMS — Seed Geospatial Data & Regulatory Bodies
-- India: 1 country, 36 states/UTs, ~20 representative districts,
-- sample subdistricts + towns, 24 regulatory bodies.

-- ============================================================
-- Country: India
-- ============================================================

INSERT INTO geo_countries (id, code, name, phone_code, currency) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'IN', 'India', '+91', 'INR');

-- ============================================================
-- States & Union Territories (36)
-- ============================================================

INSERT INTO geo_states (id, country_id, code, name) VALUES
    -- States
    ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'AP', 'Andhra Pradesh'),
    ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'AR', 'Arunachal Pradesh'),
    ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'AS', 'Assam'),
    ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'BR', 'Bihar'),
    ('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'CG', 'Chhattisgarh'),
    ('b0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000001', 'GA', 'Goa'),
    ('b0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000001', 'GJ', 'Gujarat'),
    ('b0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000001', 'HR', 'Haryana'),
    ('b0000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000001', 'HP', 'Himachal Pradesh'),
    ('b0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000001', 'JH', 'Jharkhand'),
    ('b0000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000001', 'KA', 'Karnataka'),
    ('b0000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000001', 'KL', 'Kerala'),
    ('b0000000-0000-0000-0000-000000000013', 'a0000000-0000-0000-0000-000000000001', 'MP', 'Madhya Pradesh'),
    ('b0000000-0000-0000-0000-000000000014', 'a0000000-0000-0000-0000-000000000001', 'MH', 'Maharashtra'),
    ('b0000000-0000-0000-0000-000000000015', 'a0000000-0000-0000-0000-000000000001', 'MN', 'Manipur'),
    ('b0000000-0000-0000-0000-000000000016', 'a0000000-0000-0000-0000-000000000001', 'ML', 'Meghalaya'),
    ('b0000000-0000-0000-0000-000000000017', 'a0000000-0000-0000-0000-000000000001', 'MZ', 'Mizoram'),
    ('b0000000-0000-0000-0000-000000000018', 'a0000000-0000-0000-0000-000000000001', 'NL', 'Nagaland'),
    ('b0000000-0000-0000-0000-000000000019', 'a0000000-0000-0000-0000-000000000001', 'OD', 'Odisha'),
    ('b0000000-0000-0000-0000-000000000020', 'a0000000-0000-0000-0000-000000000001', 'PB', 'Punjab'),
    ('b0000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000001', 'RJ', 'Rajasthan'),
    ('b0000000-0000-0000-0000-000000000022', 'a0000000-0000-0000-0000-000000000001', 'SK', 'Sikkim'),
    ('b0000000-0000-0000-0000-000000000023', 'a0000000-0000-0000-0000-000000000001', 'TN', 'Tamil Nadu'),
    ('b0000000-0000-0000-0000-000000000024', 'a0000000-0000-0000-0000-000000000001', 'TS', 'Telangana'),
    ('b0000000-0000-0000-0000-000000000025', 'a0000000-0000-0000-0000-000000000001', 'TR', 'Tripura'),
    ('b0000000-0000-0000-0000-000000000026', 'a0000000-0000-0000-0000-000000000001', 'UP', 'Uttar Pradesh'),
    ('b0000000-0000-0000-0000-000000000027', 'a0000000-0000-0000-0000-000000000001', 'UK', 'Uttarakhand'),
    ('b0000000-0000-0000-0000-000000000028', 'a0000000-0000-0000-0000-000000000001', 'WB', 'West Bengal'),
    -- Union Territories
    ('b0000000-0000-0000-0000-000000000029', 'a0000000-0000-0000-0000-000000000001', 'AN', 'Andaman and Nicobar Islands'),
    ('b0000000-0000-0000-0000-000000000030', 'a0000000-0000-0000-0000-000000000001', 'CH', 'Chandigarh'),
    ('b0000000-0000-0000-0000-000000000031', 'a0000000-0000-0000-0000-000000000001', 'DN', 'Dadra and Nagar Haveli and Daman and Diu'),
    ('b0000000-0000-0000-0000-000000000032', 'a0000000-0000-0000-0000-000000000001', 'DL', 'Delhi'),
    ('b0000000-0000-0000-0000-000000000033', 'a0000000-0000-0000-0000-000000000001', 'JK', 'Jammu and Kashmir'),
    ('b0000000-0000-0000-0000-000000000034', 'a0000000-0000-0000-0000-000000000001', 'LA', 'Ladakh'),
    ('b0000000-0000-0000-0000-000000000035', 'a0000000-0000-0000-0000-000000000001', 'LD', 'Lakshadweep'),
    ('b0000000-0000-0000-0000-000000000036', 'a0000000-0000-0000-0000-000000000001', 'PY', 'Puducherry');

-- ============================================================
-- Representative Districts (~20)
-- ============================================================

-- Karnataka
INSERT INTO geo_districts (id, state_id, code, name) VALUES
    ('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000011', 'BLR-U', 'Bengaluru Urban'),
    ('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000011', 'BLR-R', 'Bengaluru Rural'),
    ('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000011', 'MYS', 'Mysuru'),
    ('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000011', 'HUB', 'Hubballi-Dharwad');

-- Tamil Nadu
INSERT INTO geo_districts (id, state_id, code, name) VALUES
    ('c0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000023', 'CHN', 'Chennai'),
    ('c0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000023', 'CBE', 'Coimbatore'),
    ('c0000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000023', 'MDU', 'Madurai'),
    ('c0000000-0000-0000-0000-000000000008', 'b0000000-0000-0000-0000-000000000023', 'SLM', 'Salem'),
    ('c0000000-0000-0000-0000-000000000009', 'b0000000-0000-0000-0000-000000000023', 'KPM', 'Karur');

-- Maharashtra
INSERT INTO geo_districts (id, state_id, code, name) VALUES
    ('c0000000-0000-0000-0000-000000000010', 'b0000000-0000-0000-0000-000000000014', 'MUM', 'Mumbai'),
    ('c0000000-0000-0000-0000-000000000011', 'b0000000-0000-0000-0000-000000000014', 'PUN', 'Pune'),
    ('c0000000-0000-0000-0000-000000000012', 'b0000000-0000-0000-0000-000000000014', 'NGP', 'Nagpur');

-- Delhi
INSERT INTO geo_districts (id, state_id, code, name) VALUES
    ('c0000000-0000-0000-0000-000000000013', 'b0000000-0000-0000-0000-000000000032', 'NDL', 'New Delhi'),
    ('c0000000-0000-0000-0000-000000000014', 'b0000000-0000-0000-0000-000000000032', 'CDL', 'Central Delhi'),
    ('c0000000-0000-0000-0000-000000000015', 'b0000000-0000-0000-0000-000000000032', 'SDL', 'South Delhi');

-- Kerala
INSERT INTO geo_districts (id, state_id, code, name) VALUES
    ('c0000000-0000-0000-0000-000000000016', 'b0000000-0000-0000-0000-000000000012', 'TVM', 'Thiruvananthapuram'),
    ('c0000000-0000-0000-0000-000000000017', 'b0000000-0000-0000-0000-000000000012', 'EKM', 'Ernakulam'),
    ('c0000000-0000-0000-0000-000000000018', 'b0000000-0000-0000-0000-000000000012', 'KZH', 'Kozhikode');

-- Telangana
INSERT INTO geo_districts (id, state_id, code, name) VALUES
    ('c0000000-0000-0000-0000-000000000019', 'b0000000-0000-0000-0000-000000000024', 'HYD', 'Hyderabad'),
    ('c0000000-0000-0000-0000-000000000020', 'b0000000-0000-0000-0000-000000000024', 'RNG', 'Rangareddy');

-- ============================================================
-- Sample Subdistricts
-- ============================================================

INSERT INTO geo_subdistricts (id, district_id, code, name) VALUES
    ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'BLR-N', 'Bengaluru North'),
    ('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'BLR-S', 'Bengaluru South'),
    ('d0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000005', 'CHN-C', 'Chennai Central'),
    ('d0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000005', 'CHN-S', 'Chennai South'),
    ('d0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000010', 'MUM-C', 'Mumbai City'),
    ('d0000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000010', 'MUM-S', 'Mumbai Suburban');

-- ============================================================
-- Sample Towns
-- ============================================================

INSERT INTO geo_towns (id, subdistrict_id, code, name, pincode) VALUES
    ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'YELAHANKA', 'Yelahanka', '560064'),
    ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000002', 'JAYANAGAR', 'Jayanagar', '560041'),
    ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000003', 'MYLAPORE', 'Mylapore', '600004'),
    ('e0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000005', 'DADAR', 'Dadar', '400014');

-- ============================================================
-- Regulatory Bodies (24)
-- ============================================================

INSERT INTO regulatory_bodies (id, code, name, level, country_id, description) VALUES
    -- International (2)
    ('f0000000-0000-0000-0000-000000000001', 'JCI', 'Joint Commission International', 'international', NULL, 'International hospital accreditation'),
    ('f0000000-0000-0000-0000-000000000002', 'WHO', 'World Health Organization', 'international', NULL, 'Global health standards'),
    -- National (14)
    ('f0000000-0000-0000-0000-000000000003', 'NABH', 'National Accreditation Board for Hospitals', 'national', 'a0000000-0000-0000-0000-000000000001', 'Hospital quality accreditation'),
    ('f0000000-0000-0000-0000-000000000004', 'NABL', 'National Accreditation Board for Laboratories', 'national', 'a0000000-0000-0000-0000-000000000001', 'Laboratory accreditation'),
    ('f0000000-0000-0000-0000-000000000005', 'NMC', 'National Medical Commission', 'national', 'a0000000-0000-0000-0000-000000000001', 'Medical education and practice regulation'),
    ('f0000000-0000-0000-0000-000000000006', 'INC', 'Indian Nursing Council', 'national', 'a0000000-0000-0000-0000-000000000001', 'Nursing education regulation'),
    ('f0000000-0000-0000-0000-000000000007', 'PCI', 'Pharmacy Council of India', 'national', 'a0000000-0000-0000-0000-000000000001', 'Pharmacy education and practice'),
    ('f0000000-0000-0000-0000-000000000008', 'DCI', 'Dental Council of India', 'national', 'a0000000-0000-0000-0000-000000000001', 'Dental education regulation'),
    ('f0000000-0000-0000-0000-000000000009', 'CDSCO', 'Central Drugs Standard Control Organisation', 'national', 'a0000000-0000-0000-0000-000000000001', 'Drug regulation and approval'),
    ('f0000000-0000-0000-0000-000000000010', 'AERB', 'Atomic Energy Regulatory Board', 'national', 'a0000000-0000-0000-0000-000000000001', 'Radiation safety in medical equipment'),
    ('f0000000-0000-0000-0000-000000000011', 'PNDT', 'Pre-Conception and Pre-Natal Diagnostic Techniques Act', 'national', 'a0000000-0000-0000-0000-000000000001', 'Pre-natal diagnostic regulation'),
    ('f0000000-0000-0000-0000-000000000012', 'PCPNDT', 'PC-PNDT Act Authority', 'national', 'a0000000-0000-0000-0000-000000000001', 'Prevention of sex determination'),
    ('f0000000-0000-0000-0000-000000000013', 'NACO', 'National AIDS Control Organisation', 'national', 'a0000000-0000-0000-0000-000000000001', 'HIV/AIDS program management'),
    ('f0000000-0000-0000-0000-000000000014', 'FSSAI', 'Food Safety and Standards Authority of India', 'national', 'a0000000-0000-0000-0000-000000000001', 'Food safety in hospital kitchens'),
    ('f0000000-0000-0000-0000-000000000015', 'CPCB', 'Central Pollution Control Board', 'national', 'a0000000-0000-0000-0000-000000000001', 'Biomedical waste management'),
    ('f0000000-0000-0000-0000-000000000016', 'ABDM', 'Ayushman Bharat Digital Mission', 'national', 'a0000000-0000-0000-0000-000000000001', 'Digital health ID and health records');

-- Education regulators (8)
INSERT INTO regulatory_bodies (id, code, name, level, country_id, description) VALUES
    ('f0000000-0000-0000-0000-000000000017', 'UGC', 'University Grants Commission', 'education', 'a0000000-0000-0000-0000-000000000001', 'Higher education standards'),
    ('f0000000-0000-0000-0000-000000000018', 'AICTE', 'All India Council for Technical Education', 'education', 'a0000000-0000-0000-0000-000000000001', 'Technical education regulation'),
    ('f0000000-0000-0000-0000-000000000019', 'NAAC', 'National Assessment and Accreditation Council', 'education', 'a0000000-0000-0000-0000-000000000001', 'Educational institution accreditation'),
    ('f0000000-0000-0000-0000-000000000020', 'NBA', 'National Board of Accreditation', 'education', 'a0000000-0000-0000-0000-000000000001', 'Program-level accreditation'),
    ('f0000000-0000-0000-0000-000000000021', 'NBE', 'National Board of Examinations', 'education', 'a0000000-0000-0000-0000-000000000001', 'Medical examination and DNB programs'),
    ('f0000000-0000-0000-0000-000000000022', 'RGUHS', 'Rajiv Gandhi University of Health Sciences', 'education', 'a0000000-0000-0000-0000-000000000001', 'Health sciences university (Karnataka)'),
    ('f0000000-0000-0000-0000-000000000023', 'TNMGRMU', 'Tamil Nadu Dr. M.G.R. Medical University', 'education', 'a0000000-0000-0000-0000-000000000001', 'Medical university (Tamil Nadu)'),
    ('f0000000-0000-0000-0000-000000000024', 'MUHS', 'Maharashtra University of Health Sciences', 'education', 'a0000000-0000-0000-0000-000000000001', 'Health sciences university (Maharashtra)');
