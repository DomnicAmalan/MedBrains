/**
 * Minimal valid request bodies for API smoke tests.
 *
 * These payloads are intentionally minimal — they provide just enough
 * data for a POST/PUT to not crash the server (i.e., no 500). The
 * server may still return 400/422 for validation errors, which is
 * acceptable for smoke tests (we only flag 500s).
 */

export const SMOKE_BODIES: Record<string, Record<string, unknown>> = {
  // ── Patients ────────────────────────────────────────────────
  "POST /api/patients": {
    first_name: "SmokeFirst",
    last_name: "SmokeLast",
    gender: "male",
    phone_primary: "9999900001",
  },

  // ── OPD ─────────────────────────────────────────────────────
  "POST /api/opd/encounters": {
    patient_id: "00000000-0000-0000-0000-000000000000",
    department_id: "00000000-0000-0000-0000-000000000000",
    visit_type: "new",
  },

  // ── Lab ─────────────────────────────────────────────────────
  "POST /api/lab/orders": {
    patient_id: "00000000-0000-0000-0000-000000000000",
    encounter_id: "00000000-0000-0000-0000-000000000000",
    test_ids: [],
  },

  // ── Pharmacy ────────────────────────────────────────────────
  "POST /api/pharmacy/orders": {
    patient_id: "00000000-0000-0000-0000-000000000000",
    encounter_id: "00000000-0000-0000-0000-000000000000",
    items: [],
  },

  // ── Billing ─────────────────────────────────────────────────
  "POST /api/billing/invoices": {
    patient_id: "00000000-0000-0000-0000-000000000000",
    items: [],
  },

  // ── IPD ─────────────────────────────────────────────────────
  "POST /api/ipd/admissions": {
    patient_id: "00000000-0000-0000-0000-000000000000",
    admitting_doctor_id: "00000000-0000-0000-0000-000000000000",
    department_id: "00000000-0000-0000-0000-000000000000",
    admission_type: "emergency",
  },

  // ── Emergency ───────────────────────────────────────────────
  "POST /api/emergency/cases": {
    patient_id: "00000000-0000-0000-0000-000000000000",
    chief_complaint: "Smoke test",
    triage_level: "green",
  },

  // ── Admin / Setup ───────────────────────────────────────────
  "POST /api/setup/departments": {
    name: "Smoke Dept",
    code: "SMOKE",
  },
};

/**
 * Endpoints that should be skipped in smoke tests because they
 * require specific preconditions or have side effects.
 */
export const SKIP_ENDPOINTS: string[] = [
  "DELETE /api/",  // Don't delete anything in smoke tests
  "POST /api/auth/logout",
  "POST /api/onboarding/init",
  "POST /api/setup/seed",
];
