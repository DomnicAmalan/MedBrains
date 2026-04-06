# MedBrains — Feature Build List

> Master feature inventory. Each feature is a discrete, buildable unit.
> Status: `[ ]` pending | `[~]` in progress | `[x]` done

---

## 1. PATIENT MANAGEMENT

### 1.1 Registration
- [ ] Quick patient registration form (name, age, gender, phone, address)
- [ ] UHID auto-generation (ACMS-YYYY-NNNNNN format)
- [ ] QR code generation per patient
- [ ] Aadhaar-based deduplication
- [ ] ABHA ID creation & linking (ABDM M1)
- [ ] Photo capture (webcam/upload)
- [ ] Emergency registration (minimal fields, complete later)
- [ ] Family linking (spouse, parent, child relationships)
- [ ] Patient merge (duplicate resolution)
- [ ] Patient search (name, phone, UHID, ABHA)
- [ ] Fuzzy/typo-tolerant search
- [ ] Patient history timeline (all visits, labs, prescriptions)
- [ ] Patient portal (self-service appointment, reports)
- [ ] Digital consent forms (registration consent, treatment consent)
- [ ] Multi-language support (form labels, consent text)

### 1.2 Patient Categories
- [ ] Walk-in patient
- [ ] Referred patient (with referring doctor capture)
- [ ] Corporate patient (company linked)
- [ ] Insurance patient (TPA linked)
- [ ] Emergency patient
- [ ] Medico-legal case (MLC) patient
- [ ] VIP/VVIP flagging (restricted access)
- [ ] Staff/employee patient
- [ ] Camp patient

---

## 2. OPD (OUT-PATIENT DEPARTMENT)

### 2.1 Appointments
- [ ] Appointment booking (date, time, doctor, department)
- [ ] Doctor availability calendar (slot-based)
- [ ] Recurring appointment scheduling
- [ ] Online appointment booking (patient portal/app)
- [ ] Walk-in token generation
- [ ] QR code check-in at kiosk
- [ ] Token display system (TV/monitor)
- [ ] Appointment rescheduling
- [ ] Appointment cancellation with reason
- [ ] No-show tracking
- [ ] SMS/WhatsApp appointment reminders
- [ ] Waiting time estimation
- [ ] Multi-doctor appointment (e.g., health checkup)

### 2.2 Consultation
- [ ] Doctor queue/worklist
- [ ] Patient history view (previous visits, labs, prescriptions)
- [ ] Chief complaints entry
- [ ] History of present illness (HPI)
- [ ] Past medical history
- [ ] Family history
- [ ] Vitals recording (BP, pulse, temp, SpO2, weight, height, BMI)
- [ ] Clinical examination notes
- [ ] Diagnosis entry with ICD-10 search
- [ ] SNOMED CT coded findings
- [ ] Clinical notes (free text + structured)
- [ ] Clinical templates per specialty (15+ specialties)
- [ ] Template builder (admin-configurable)
- [ ] Automatic EMR prompts (drug allergies, chronic conditions)
- [ ] Patient timeline view during consultation

### 2.3 Prescription
- [ ] E-prescription with drug search
- [ ] Drug formulary master
- [ ] Dosage, frequency, duration, route
- [ ] Drug-drug interaction alerts
- [ ] Drug-allergy alerts
- [ ] Favourite prescriptions (doctor-specific templates)
- [ ] Prescription print (standard format)
- [ ] Prescription forwarding to in-house pharmacy
- [ ] External pharmacy prescription print
- [ ] Prescription history view

### 2.4 Orders & Referrals
- [ ] Lab test ordering (from consultation)
- [ ] Radiology ordering
- [ ] Procedure ordering
- [ ] Inter-department referral
- [ ] External referral letter generation
- [ ] Follow-up scheduling from consultation
- [ ] Cost estimation for ordered services
- [ ] Pre-authorization request (insurance patients)

### 2.5 Post-Consultation
- [ ] Docket management (doctor daily summary)
- [ ] Review & reminder management
- [ ] Patient feedback collection
- [ ] Medical certificate generation
- [ ] Fitness certificate
- [ ] Sick leave certificate
- [ ] Disability certificate
- [ ] Charts & graphs (vitals trend, lab trends)
- [ ] Visit summary print
- [ ] Digital consent for procedures

---

## 3. IPD (IN-PATIENT DEPARTMENT)

### 3.1 Admission
- [ ] IP admission form
- [ ] Emergency admission (fast-track)
- [ ] Planned admission from OPD
- [ ] Bed selection (ward, room type, bed number)
- [ ] Bed availability display
- [ ] Admission checklist validation
- [ ] Attender/next-of-kin capture
- [ ] Admission slip/form print
- [ ] IP type configuration (general, semi-private, private, ICU, NICU, etc.)
- [ ] Estimated cost for admission
- [ ] Advance payment collection
- [ ] Pre-authorization for insurance
- [ ] MLC registration at admission

### 3.2 Ward & Bed Management
- [ ] Ward master (name, type, floor, building)
- [ ] Bed master (bed number, type, features)
- [ ] Real-time bed occupancy dashboard
- [ ] Bed transfer (ward to ward, bed to bed)
- [ ] Bed blocking/reservation
- [ ] Bed cleaning status tracking
- [ ] Bed turnaround time tracking
- [ ] Isolation bed flagging
- [ ] ICU bed management
- [ ] NICU/PICU bed management
- [ ] Nursery management
- [ ] TV display for bed status (ward-level)

### 3.3 Clinical — Inpatient
- [ ] Digital case sheet entry
- [ ] Doctor rounds notes (daily progress notes)
- [ ] Nursing notes
- [ ] Vitals monitoring (periodic charting)
- [ ] I/O (Intake/Output) charting
- [ ] Medication administration record (MAR)
- [ ] Diet chart management
- [ ] Wound care documentation
- [ ] Fall risk assessment
- [ ] Pain assessment scoring
- [ ] Glasgow Coma Scale
- [ ] APACHE scoring (ICU)
- [ ] ICU care bundle compliance
- [ ] Ventilator settings & monitoring
- [ ] Central line care checklist
- [ ] Catheter care checklist
- [ ] Restraint documentation
- [ ] Transfusion documentation
- [ ] Consent forms (procedure-specific)

### 3.4 OT (Operation Theatre)
- [ ] OT scheduling calendar
- [ ] OT slot management
- [ ] Pre-operative assessment form
- [ ] Pre-operative checklist (WHO surgical safety)
- [ ] Anesthesia pre-assessment
- [ ] Anesthesia record
- [ ] Intra-operative notes
- [ ] Surgeon notes
- [ ] Post-operative instructions
- [ ] OT consumable tracking
- [ ] OT utilization dashboard
- [ ] Emergency OT booking
- [ ] OT turnaround time tracking

### 3.5 Discharge
- [ ] Discharge summary generation
- [ ] Discharge checklist
- [ ] Final billing at discharge
- [ ] Discharge medication list
- [ ] Follow-up appointment scheduling
- [ ] Discharge against medical advice (DAMA)
- [ ] Absconding patient workflow
- [ ] Death summary
- [ ] Death certificate generation
- [ ] Birth certificate generation (maternity)
- [ ] Transfer summary (inter-hospital)
- [ ] Dept-wise billing configuration at discharge
- [ ] Billing threshold control
- [ ] TAT tracking for discharge process
- [ ] Patient feedback at discharge

---

## 4. LABORATORY / DIAGNOSTICS

### 4.1 Pre-Analytical
- [ ] Lab test master (test name, sample type, container, department)
- [ ] Lab panel/profile master (CBC = Hb+WBC+Plt+...)
- [ ] Lab order management (from OPD/IPD)
- [ ] Sample collection scheduling
- [ ] Barcode generation per sample
- [ ] Sample accessioning
- [ ] Sample tracking (collection → processing → result)
- [ ] Emergency/STAT sample handling
- [ ] Sample rejection with reason
- [ ] Phlebotomist assignment
- [ ] Home collection management
- [ ] Collection center management
- [ ] Camp-based sample collection
- [ ] Outsource lab management (send-out tests)

### 4.2 Analytical
- [ ] Worklist generation per department/analyzer
- [ ] Lab machine interfacing (uni-directional)
- [ ] Lab machine interfacing (bi-directional)
- [ ] Manual result entry
- [ ] Auto-approval for normal results (configurable rules)
- [ ] Abnormal result flagging
- [ ] Critical result alerts (to ordering doctor)
- [ ] Delta check (compare with previous result)
- [ ] Result verification workflow (tech → supervisor → pathologist)
- [ ] Cross-department result verification
- [ ] Reflex testing rules
- [ ] Add-on test to existing sample
- [ ] Sample archival & retrieval

### 4.3 Post-Analytical
- [ ] Report generation (customizable templates)
- [ ] Preliminary report generation
- [ ] Report locking (auto-lock after approval)
- [ ] Report amendment with audit trail
- [ ] Omni-channel report delivery (WhatsApp, SMS, Email)
- [ ] Patient portal report access
- [ ] Bulk report printing
- [ ] Report dispatch tracking
- [ ] Referring doctor portal (view reports)
- [ ] Trend charts (patient lab value history)
- [ ] QR code on lab reports (verification)
- [ ] TAT tracking & analytics
- [ ] STAT test monitoring

### 4.4 Quality Control
- [ ] QC sample management
- [ ] Levey-Jennings (LJ) charts
- [ ] Westgard rules implementation
- [ ] QC lot management
- [ ] Reagent tracking & auto-deduction
- [ ] Reagent consumption reports
- [ ] Reagent re-order alerts
- [ ] NABL accreditation compliance
- [ ] CAP accreditation compliance
- [ ] EQAS (External QA) management

### 4.5 B2B & Referral
- [ ] B2B client registration
- [ ] B2B rate management (contract pricing)
- [ ] B2B portal (order placement, report viewing)
- [ ] Referral doctor registration
- [ ] Referral doctor portal
- [ ] Referral doctor payout/commission management
- [ ] Bulk invoicing for postpaid accounts
- [ ] Credit management
- [ ] Online payment settlement on portal

---

## 5. RADIOLOGY / IMAGING

- [ ] Radiology order management
- [ ] Modality worklist (MWL) — DICOM
- [ ] PACS integration (Orthanc)
- [ ] Radiology reporting templates
- [ ] Image viewing (DICOM viewer)
- [ ] Report generation with images
- [ ] Critical finding alerts
- [ ] Radiology TAT tracking
- [ ] Contrast allergy alerts
- [ ] Radiation dose tracking
- [ ] Modality scheduling (CT, MRI, USG, X-ray)
- [ ] Report approval workflow

---

## 6. PHARMACY / INVENTORY

### 6.1 Pharmacy
- [ ] Drug master (name, generic, brand, strength, form)
- [ ] Drug category management
- [ ] E-prescription integration (auto-populate from OPD)
- [ ] OTC sales (walk-in billing)
- [ ] IP medicine indent & dispensing
- [ ] Drug-allergy checking at dispensing
- [ ] Drug-drug interaction checking at dispensing
- [ ] Substitute drug suggestions
- [ ] FIFO dispensing
- [ ] Batch & expiry tracking
- [ ] Near-expiry alerts
- [ ] Expired drug quarantine
- [ ] Narcotic/controlled drug register
- [ ] Return management
- [ ] Multi-store management
- [ ] Inter-store stock transfer
- [ ] Pharmacy billing
- [ ] Discount authorization
- [ ] Patient credit management
- [ ] GST/tax computation

### 6.2 Inventory / Procurement
- [ ] Product/item master
- [ ] Supplier/vendor master
- [ ] Purchase requisition
- [ ] Purchase order generation
- [ ] Quotation management (get quote & compare)
- [ ] GRN (Goods Received Note)
- [ ] Goods return to supplier
- [ ] Price disparity notification
- [ ] Stock consumption tracking
- [ ] Stock adjustment
- [ ] Stock audit
- [ ] Re-order level alerts
- [ ] Auto-reorder generation
- [ ] Barcode & QR generation for stock items
- [ ] Stock reports (current stock, movement, aging)
- [ ] FSN analysis (Fast/Slow/Non-moving)
- [ ] ABC analysis (value-based classification)
- [ ] VED analysis (Vital/Essential/Desirable)
- [ ] Consumption reports
- [ ] Supplier payment tracking

---

## 7. BILLING & FINANCE

### 7.1 Billing
- [ ] Service/procedure rate master
- [ ] Multi-level rate plans (general, staff, VIP, corporate, insurance)
- [ ] OPD billing (consultation, procedures, services)
- [ ] IPD billing (room charges, services, consumables, drugs)
- [ ] Lab billing
- [ ] Pharmacy billing
- [ ] Radiology billing
- [ ] OT billing
- [ ] Package billing (health checkup, surgery packages)
- [ ] Auto-charge on service (lab order → auto-bill)
- [ ] Interim billing (IP running bill)
- [ ] Final billing at discharge
- [ ] Bill cancellation & refund
- [ ] Bulk discount management
- [ ] Discount authorization workflow
- [ ] Multi-payment mode (cash, card, UPI, cheque, online)
- [ ] Receipt generation & print
- [ ] Bill print (customizable format)
- [ ] Duplicate bill generation
- [ ] Multi-currency support
- [ ] GST/tax management
- [ ] Billing threshold control

### 7.2 Insurance / TPA
- [ ] Insurance company master
- [ ] TPA master
- [ ] Insurance scheme/plan management
- [ ] Pre-authorization request
- [ ] Pre-authorization approval tracking
- [ ] Claim submission (digital)
- [ ] Dual insurance (primary + secondary)
- [ ] Co-payment calculation
- [ ] Patient vs insurance split
- [ ] Claim follow-up & tracking
- [ ] Claim rejection management
- [ ] Corporate billing & invoicing
- [ ] Corporate credit management
- [ ] Insurance panel (smart panel view)
- [ ] NHCX (National Health Claim Exchange) integration

### 7.3 Accounts & Finance
- [ ] Accounting journal entries
- [ ] Revenue reports (department-wise, doctor-wise, service-wise)
- [ ] Collection reports (daily, weekly, monthly)
- [ ] Outstanding & receivables tracking
- [ ] Refund management
- [ ] Advance & deposit management
- [ ] End-of-day cash closing
- [ ] Bank reconciliation
- [ ] ERP integration (Tally, SAP, Odoo, Zoho Books)
- [ ] Profit & loss by department
- [ ] MIS dashboards (revenue, collection, trends)

---

## 8. BLOOD BANK

- [ ] Donor registration
- [ ] Donor screening & questionnaire
- [ ] Blood group & cross-match
- [ ] Blood collection (bag, volume, date)
- [ ] Component separation (packed RBC, FFP, platelets)
- [ ] Blood storage & inventory
- [ ] Blood testing (HIV, HBV, HCV, VDRL, Malaria)
- [ ] Blood issue & transfusion request
- [ ] Cross-match compatibility check
- [ ] Blood utilization tracking
- [ ] Blood discard management
- [ ] Expiry tracking
- [ ] Blood bank billing
- [ ] Donor camp management
- [ ] Adverse reaction reporting

---

## 9. CSSD (Central Sterile Supply Department)

- [ ] Instrument master
- [ ] Instrument set/tray master
- [ ] Dirty instrument receipt
- [ ] Washing & decontamination tracking
- [ ] Packing & wrapping
- [ ] Sterilization cycle tracking (autoclave, ETO)
- [ ] Biological indicator (BI) result logging
- [ ] Chemical indicator tracking
- [ ] Sterile item issue to OT/ward
- [ ] Instrument recall management
- [ ] Instrument lifecycle tracking
- [ ] Sterilizer maintenance log
- [ ] CSSD dashboard (cycle count, TAT, compliance)

---

## 10. DIET & NUTRITION

- [ ] Diet plan master (regular, soft, liquid, diabetic, renal, etc.)
- [ ] Patient diet order (from doctor/nurse)
- [ ] Kitchen order generation
- [ ] Meal schedule management (breakfast, lunch, snacks, dinner)
- [ ] Special diet requests
- [ ] Allergy-aware diet planning
- [ ] Calorie/nutrient tracking
- [ ] Diet compliance monitoring
- [ ] Kitchen inventory management
- [ ] Meal delivery tracking

---

## 11. AMBULANCE MANAGEMENT

- [ ] Ambulance fleet master
- [ ] Ambulance booking/dispatch
- [ ] GPS tracking integration
- [ ] Driver assignment
- [ ] Patient pickup/drop tracking
- [ ] Emergency vs scheduled trips
- [ ] Ambulance billing
- [ ] Trip log & reports
- [ ] Maintenance schedule

---

## 12. BIO-WASTE MANAGEMENT

- [ ] Waste category master (yellow, red, blue, white, cytotoxic)
- [ ] Waste generation recording (per department)
- [ ] Waste segregation compliance tracking
- [ ] Waste storage monitoring
- [ ] Waste disposal vendor management
- [ ] Manifest/tracking slip generation
- [ ] SPCB (State Pollution Control Board) report generation
- [ ] Monthly waste reports
- [ ] Needle stick injury reporting

---

## 13. INFECTION CONTROL

- [ ] Hospital-acquired infection (HAI) surveillance
- [ ] Infection event reporting
- [ ] Antibiogram (department-wise, organism-wise)
- [ ] Hand hygiene compliance tracking
- [ ] Isolation precaution management
- [ ] Outbreak detection & alert
- [ ] Infection rate dashboards (VAP, CLABSI, CAUTI, SSI)
- [ ] Culture sensitivity pattern tracking
- [ ] Antimicrobial stewardship reports

---

## 14. LINEN MANAGEMENT

- [ ] Linen inventory master
- [ ] Linen issue to wards
- [ ] Dirty linen collection tracking
- [ ] Laundry management (in-house/outsourced)
- [ ] Linen lifecycle tracking
- [ ] Linen condemnation
- [ ] Linen usage reports per department

---

## 15. ASSET MANAGEMENT

- [ ] Asset master (equipment, furniture, vehicles)
- [ ] Asset tagging (barcode/QR)
- [ ] Asset allocation to department
- [ ] Preventive maintenance schedule
- [ ] Breakdown maintenance requests
- [ ] AMC/CMC tracking (vendor, dates, cost)
- [ ] Asset depreciation tracking
- [ ] Asset audit & verification
- [ ] Asset disposal/condemnation
- [ ] Calibration tracking (medical equipment)
- [ ] Asset utilization reports

---

## 16. CAMP MANAGEMENT

- [ ] Camp planning & scheduling
- [ ] Camp location & logistics
- [ ] Camp patient registration (simplified)
- [ ] Camp lab sample collection
- [ ] Camp billing (free/discounted)
- [ ] Camp reports & analytics
- [ ] Follow-up tracking for camp patients
- [ ] Camp-to-hospital patient conversion tracking

---

## 17. HR & STAFF MANAGEMENT

- [ ] Employee master
- [ ] Department & designation master
- [ ] Duty roster / shift management
- [ ] Attendance tracking (QR/biometric)
- [ ] Leave management
- [ ] Payroll integration
- [ ] Staff credentialing
- [ ] License/certification expiry tracking
- [ ] Doctor payout/incentive management
- [ ] Referral commission management
- [ ] Staff training records
- [ ] On-call schedule management

---

## 18. MRD (Medical Records Department)

- [ ] Medical record indexing
- [ ] Record retrieval tracking
- [ ] Record movement tracking
- [ ] Coding (ICD-10, procedure coding)
- [ ] Morbidity & mortality reports
- [ ] Statistical reports (admission, discharge, death rates)
- [ ] Birth & death register
- [ ] MLC register
- [ ] Record retention & destruction policy
- [ ] Scanned document management
- [ ] Medico-legal case documentation

---

## 19. QUALITY & COMPLIANCE

### 19.1 NABH
- [ ] NABH indicator tracking (clinical, patient safety, management)
- [ ] Incident reporting (adverse events, near misses)
- [ ] Root cause analysis (RCA) workflow
- [ ] CAPA (Corrective & Preventive Action) management
- [ ] Patient safety goals tracking
- [ ] Clinical audit management
- [ ] Policy & SOP document management
- [ ] Committee meeting management
- [ ] Quality dashboard

### 19.2 ABDM (Ayushman Bharat Digital Mission)
- [ ] ABHA ID creation (M1)
- [ ] ABHA verification
- [ ] Link care context (M2)
- [ ] Consent management (M2)
- [ ] Health record sharing to HIU (M2)
- [ ] Create consent request (M3)
- [ ] Receive data from HIP (M3)
- [ ] FHIR resource generation
- [ ] Digital health locker integration

### 19.3 Accreditation Support
- [ ] JCI standards tracking
- [ ] NABL standards tracking (laboratory)
- [ ] NABH pre-entry level checklist
- [ ] NABH entry level checklist
- [ ] NABH full accreditation checklist
- [ ] Document control system
- [ ] Internal audit scheduling & tracking

---

## 20. COMMUNICATION & NOTIFICATIONS

- [ ] In-app notifications (real-time WebSocket)
- [ ] SMS notifications (appointment, lab ready, discharge)
- [ ] WhatsApp notifications (reports, reminders)
- [ ] Email notifications
- [ ] Push notifications (mobile app)
- [ ] Omni-channel notification engine (template-based)
- [ ] Notification preference management (per patient)
- [ ] Masked communication (Uber model — staff-to-staff)
- [ ] Emergency code system (Code Blue, Code Red)
- [ ] Intercom code system
- [ ] Critical result escalation chain
- [ ] Auto-escalation (doctor not responding → HOD → MS)

---

## 21. TV / DISPLAY BOARDS

- [ ] OPD queue display (token number → room number)
- [ ] Lab queue display (token → counter)
- [ ] Pharmacy queue display
- [ ] Ward bed status display
- [ ] OT schedule display
- [ ] Emergency department status board
- [ ] Canteen/cafeteria menu display
- [ ] Visitor information display
- [ ] Numbers-only mode (privacy — no patient names)
- [ ] Auto-refresh via WebSocket
- [ ] Multi-screen/multi-location support

---

## 22. MOBILE APPS

### 22.1 Doctor App
- [ ] Login & authentication
- [ ] OPD patient queue
- [ ] Patient search
- [ ] View patient history
- [ ] Write consultation notes
- [ ] E-prescription
- [ ] Lab order placement
- [ ] Lab result viewing
- [ ] IPD patient list
- [ ] Progress note entry
- [ ] Push notifications (critical alerts)
- [ ] Offline mode (WatermelonDB cache)
- [ ] On-call schedule view

### 22.2 Patient App
- [ ] Registration & profile
- [ ] Appointment booking
- [ ] Appointment history
- [ ] Lab report viewing & download
- [ ] Prescription history
- [ ] Bill viewing & payment
- [ ] Health records timeline
- [ ] Family member linking
- [ ] Feedback submission
- [ ] Push notifications (appointment reminders, report ready)

### 22.3 Phlebo / Runner App
- [ ] Home collection order list
- [ ] Route/navigation to patient location
- [ ] Sample collection confirmation
- [ ] Barcode scanning
- [ ] Sample handover to lab
- [ ] Trip completion tracking

---

## 23. DASHBOARDS & ANALYTICS

- [ ] Admin dashboard (hospital overview)
- [ ] Revenue dashboard (daily/weekly/monthly)
- [ ] Department-wise revenue analytics
- [ ] Doctor-wise revenue analytics
- [ ] OPD footfall analytics
- [ ] IPD census (admission/discharge/death)
- [ ] Bed occupancy dashboard
- [ ] Lab TAT analytics
- [ ] Pharmacy sales analytics
- [ ] OT utilization analytics
- [ ] Emergency department analytics
- [ ] Patient satisfaction dashboard
- [ ] Clinical indicators dashboard (mortality, infection rates)
- [ ] MIS report builder (custom reports)
- [ ] Export to Excel/PDF
- [ ] Scheduled report delivery (email)
- [ ] Cross-timezone analytics
- [ ] Multi-location comparison analytics

---

## 24. SECURITY & ACCESS CONTROL

- [ ] RBAC (role-based access control)
- [ ] ABAC (attribute-based access control)
- [ ] Data access lifetime (context-aware sessions)
- [ ] Break-glass emergency access
- [ ] Field-level access control
- [ ] IP address whitelisting
- [ ] Single-session enforcement
- [ ] Multi-factor authentication (TOTP)
- [ ] Session timeout management
- [ ] Password policy enforcement
- [ ] Login audit trail
- [ ] Failed login lockout
- [ ] Audit log (all operations)
- [ ] Tamper-evident audit chain (SHA-256)
- [ ] Break-glass review workflow
- [ ] Address-based conflict detection (staff vs patient)
- [ ] Sensitive case escalation (HIV, psychiatry)
- [ ] Data export control (print/export permissions)
- [ ] Anonymized data access (students)

---

## 25. ENCRYPTION & PRIVACY

- [ ] TLS 1.3 (transit encryption)
- [ ] Database encryption at rest (YottaDB DAR, PostgreSQL TDE/LUKS)
- [ ] Field-level encryption (Aadhaar, phone, HIV status)
- [ ] Per-patient encryption keys (PDK)
- [ ] Key hierarchy (MK → KEK → PDK → field keys)
- [ ] Consent-based encryption (HIV, psychiatry — patient must consent)
- [ ] Password hashing (Argon2id)
- [ ] JWT signing (Ed25519)
- [ ] Certificate pinning (mobile app)
- [ ] mTLS for ABDM/TPA API calls
- [ ] Key rotation (MK annual, KEK quarterly)
- [ ] DPDPA compliance (right to erasure, consent management)

---

## 26. INTEGRATIONS

### 26.1 Government
- [ ] ABDM (ABHA, care context, consent)
- [ ] NHCX (National Health Claim Exchange)
- [ ] e-Hospital (NIC)
- [ ] CoWIN (vaccination records)

### 26.2 ERP
- [ ] Tally integration
- [ ] SAP integration
- [ ] Odoo integration
- [ ] Zoho Books integration
- [ ] Webhook-based generic integration

### 26.3 Clinical Standards
- [ ] ICD-10 coding
- [ ] SNOMED CT
- [ ] LOINC (lab codes)
- [ ] CPT (procedure codes)
- [ ] CDSS (Clinical Decision Support)
- [ ] HL7 FHIR (data exchange)

### 26.4 Lab Machine Interfacing
- [ ] ASTM protocol support
- [ ] HL7 protocol support
- [ ] Uni-directional interface (result import)
- [ ] Bi-directional interface (order send + result import)
- [ ] Machine-specific drivers (Beckman, Roche, Sysmex, Siemens, Erba)

### 26.5 Payment
- [ ] Payment gateway integration (Razorpay/Stripe)
- [ ] UPI integration
- [ ] POS terminal integration

### 26.6 Communication
- [ ] SMS gateway integration
- [ ] WhatsApp Business API integration
- [ ] Email (SMTP/SendGrid)
- [ ] Push notification (FCM/APNs)

---

## 27. MEDICAL COLLEGE INTEGRATION

- [ ] Student master (MBBS, PG, nursing, paramedical)
- [ ] Posting/rotation schedule management
- [ ] Auto-populated case logs (from patient encounters)
- [ ] Faculty verification of case logs
- [ ] Procedure log (PG residents, linked to OT records)
- [ ] Clinical attendance tracking
- [ ] Student assessment recording
- [ ] OSCE station management
- [ ] Anonymized patient data for students (ABAC-filtered)
- [ ] NMC inspection report generation (one-click)
- [ ] Faculty-student ratio reporting
- [ ] Research/thesis tracking
- [ ] Ethics committee approval workflow
- [ ] Patient consent for teaching

---

## 28. SPECIALTY MODULES

### 28.1 Emergency Medicine
- [ ] Triage (color-coded severity)
- [ ] Trauma assessment forms
- [ ] Code Blue / Code Red management
- [ ] Emergency resuscitation documentation
- [ ] MLC documentation
- [ ] Police intimation workflow
- [ ] Emergency OT escalation
- [ ] Mass casualty incident management

### 28.2 Maternity / Obstetrics
- [ ] Antenatal registration
- [ ] Antenatal visit tracking
- [ ] USG report integration
- [ ] Labor monitoring (partograph)
- [ ] Delivery documentation
- [ ] Newborn registration
- [ ] Birth certificate generation
- [ ] Postnatal care documentation
- [ ] NICU admission integration

### 28.3 Pediatrics / Neonatology
- [ ] Growth chart tracking
- [ ] Vaccination schedule
- [ ] NICU monitoring
- [ ] Kangaroo mother care documentation
- [ ] Pediatric dosage calculator

### 28.4 ART (IVF & IUI)
- [ ] Patient profile (fertility assessment)
- [ ] Investigation tracking (hormones, blood tests)
- [ ] Ovarian stimulation monitoring
- [ ] Egg retrieval documentation
- [ ] Semen preparation (IUI)
- [ ] IUI procedure documentation
- [ ] Embryology documentation
- [ ] Embryo freezing records
- [ ] Embryo transfer documentation
- [ ] Cycle outcome tracking
- [ ] Multi-clinic coordination
- [ ] ART-specific billing

### 28.5 Dental
- [ ] Dental chart (adult/pediatric)
- [ ] Tooth-wise treatment planning
- [ ] Dental procedure coding (CDT)
- [ ] Dental imaging integration
- [ ] Orthodontic treatment tracking
- [ ] Dental material inventory

### 28.6 Ophthalmology
- [ ] Visual acuity recording
- [ ] Refraction data
- [ ] Slit lamp findings
- [ ] Fundoscopy documentation
- [ ] IOP recording
- [ ] Surgical documentation (cataract, retina)

### 28.7 Psychiatry
- [ ] Psychiatric assessment forms
- [ ] Mental status examination
- [ ] Consent-gated records (enhanced privacy)
- [ ] Substance abuse documentation
- [ ] Counseling session tracking
- [ ] Mental Health Act compliance
- [ ] Restricted access (ABAC — psychiatry notes hidden from non-psychiatry)

### 28.8 Oncology
- [ ] Cancer staging
- [ ] Chemotherapy protocol management
- [ ] Radiation therapy tracking
- [ ] Tumor board documentation
- [ ] RECIST criteria tracking

### 28.9 Dialysis
- [ ] Dialysis schedule management
- [ ] Pre-dialysis assessment
- [ ] Intra-dialysis monitoring
- [ ] Dialysis machine assignment
- [ ] Consumable tracking per session
- [ ] Monthly adequacy reporting

### 28.10 Physiotherapy / Rehabilitation
- [ ] Therapy plan creation
- [ ] Session tracking
- [ ] Progress documentation
- [ ] Outcome measurement tools
- [ ] Home exercise program generation

---

## 29. INFRASTRUCTURE MANAGEMENT

- [ ] Building master (campus, buildings, floors, wings)
- [ ] Room master (type, capacity, equipment)
- [ ] Facility maintenance requests
- [ ] Preventive maintenance schedule
- [ ] Vendor management for facility services
- [ ] Energy/utility monitoring
- [ ] Fire safety equipment tracking
- [ ] Security incident reporting
- [ ] Visitor management system
- [ ] Parking management

---

## 30. PATIENT EXPERIENCE

- [ ] Patient feedback forms (post-visit, post-discharge)
- [ ] Net Promoter Score (NPS) tracking
- [ ] Complaint management workflow
- [ ] Grievance redressal tracking
- [ ] Patient satisfaction surveys
- [ ] Google review integration
- [ ] Patient education material delivery
- [ ] Waiting time analytics
- [ ] Service recovery alerts (unhappy patient → immediate action)

---

## 31. WORKFLOW ENGINE

- [ ] Workflow template builder (admin)
- [ ] Step sequence definition (JSONB)
- [ ] Conditional branching (if/else rules)
- [ ] Parallel steps
- [ ] Approval steps (single/multi-level)
- [ ] Auto-trigger workflows (on event)
- [ ] Manual trigger workflows
- [ ] SLA/deadline tracking per step
- [ ] Escalation on deadline breach
- [ ] Workflow instance tracking (status per patient/order)
- [ ] Workflow audit trail
- [ ] Form builder (dynamic forms per workflow step)
- [ ] Notification integration (per step)
- [ ] 120+ pre-built workflow templates (from RFC-002)

---

## 32. ADMIN & CONFIGURATION

- [ ] Tenant management (create, configure, activate)
- [ ] 7-layer config hierarchy (Global → Tenant → Campus → Building → Floor → Dept → User)
- [ ] Module enablement (activate/deactivate per tenant)
- [ ] Department master
- [ ] Designation/role master
- [ ] User management (create, assign role, assign department)
- [ ] Permission management (ABAC policy editor)
- [ ] Master file management (lab tests, drugs, services, rates)
- [ ] Form builder (dynamic form configuration)
- [ ] Template management (print templates, report templates)
- [ ] Numbering/sequence configuration (UHID, bill, lab report)
- [ ] System settings (date format, currency, timezone)
- [ ] Audit log viewer
- [ ] System health dashboard
- [ ] Backup management
- [ ] Data export tools
- [ ] Branding configuration (logo, colors, header/footer)
