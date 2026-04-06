/**
 * Mock patient data for E2E tests.
 *
 * Each entry provides form-filling values that match the DynamicForm
 * field labels (used with `getByLabel()`).
 */

export interface PatientFormData {
  firstName: string;
  lastName: string;
  phone: string;
  gender?: string;
  email?: string;
  dateOfBirth?: string; // YYYY-MM-DD
  category?: string;
}

/** Generate a unique patient with a timestamp suffix to avoid collisions. */
export function uniquePatient(
  base: Partial<PatientFormData> = {},
): PatientFormData {
  const ts = Date.now();
  return {
    firstName: base.firstName ?? `E2EFirst${ts}`,
    lastName: base.lastName ?? `E2ELast${ts}`,
    phone: base.phone ?? `98${String(ts).slice(-8)}`,
    gender: base.gender ?? "male",
    email: base.email,
    dateOfBirth: base.dateOfBirth,
    category: base.category,
  };
}

/** Pre-defined patients for specific test scenarios. */
export const PATIENTS = {
  basic: {
    firstName: "TestJohn",
    lastName: "TestDoe",
    phone: "9876543210",
    gender: "male",
  } satisfies PatientFormData,

  female: {
    firstName: "TestJane",
    lastName: "TestSmith",
    phone: "9876543211",
    gender: "female",
  } satisfies PatientFormData,

  withEmail: {
    firstName: "TestAlex",
    lastName: "TestBrown",
    phone: "9876543212",
    gender: "male",
    email: "alex.brown@test.local",
  } satisfies PatientFormData,

  withDob: {
    firstName: "TestSam",
    lastName: "TestWilson",
    phone: "9876543213",
    gender: "male",
    dateOfBirth: "1990-05-15",
  } satisfies PatientFormData,
} as const;
