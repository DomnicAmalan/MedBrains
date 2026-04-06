#!/usr/bin/env python3
"""
E2E Scenario Skeleton Generator — creates skeleton Playwright test files
for major user flows.

Generates:
  - apps/web/e2e/scenarios/<flow>.spec.ts — one per major flow

Usage:
    python3 scripts/generate_e2e_skeletons.py
    # or:
    make generate-e2e

The generated skeletons include test structure with TODO markers
for filling in assertions. They are NOT auto-run until completed.
"""

import sys
from pathlib import Path

# ── Paths ────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent
SCENARIOS_DIR = REPO_ROOT / "medbrains" / "apps" / "web" / "e2e" / "scenarios"

# ── Scenario definitions ─────────────────────────────────────────────

SCENARIOS = [
    {
        "file": "patient-registration.spec.ts",
        "title": "Patient Registration Flow",
        "description": "Register a new patient, verify in list, view details",
        "tests": [
            {
                "name": "should register a new patient via full form",
                "steps": [
                    'Navigate to /patients',
                    'Open registration drawer',
                    'Fill in required fields (first name, last name, phone)',
                    'Submit the form',
                    'Verify patient appears in the list',
                    'Open detail drawer and verify info',
                ],
                "page": "/patients",
            },
            {
                "name": "should register via quick registration",
                "steps": [
                    'Click "Quick Register" button',
                    'Fill minimal fields',
                    'Submit and verify success',
                ],
                "page": "/patients",
            },
            {
                "name": "should search for a patient by name",
                "steps": [
                    'Register a patient first',
                    'Use search bar to find by name',
                    'Verify correct patient shown',
                ],
                "page": "/patients",
            },
        ],
    },
    {
        "file": "opd-visit.spec.ts",
        "title": "OPD Visit Flow",
        "description": "Patient queue → encounter → consultation → prescription → complete",
        "tests": [
            {
                "name": "should create a new OPD encounter for a patient",
                "steps": [
                    'Navigate to /opd',
                    'Click "New Encounter" or select patient',
                    'Fill encounter details (department, visit type)',
                    'Submit and verify encounter created',
                ],
                "page": "/opd",
            },
            {
                "name": "should manage the OPD queue",
                "steps": [
                    'View queue list',
                    'Verify patient appears in queue',
                    'Call patient (change status)',
                    'Verify status update',
                ],
                "page": "/opd",
            },
            {
                "name": "should record consultation notes",
                "steps": [
                    'Open an active encounter',
                    'Switch to consultation tab',
                    'Enter chief complaint and notes',
                    'Save and verify',
                ],
                "page": "/opd",
            },
            {
                "name": "should create a prescription",
                "steps": [
                    'Open encounter prescriptions tab',
                    'Add a medication',
                    'Set dosage and frequency',
                    'Save prescription',
                ],
                "page": "/opd",
            },
        ],
    },
    {
        "file": "lab-order.spec.ts",
        "title": "Lab Order Flow",
        "description": "Create lab order → collect sample → enter results → complete",
        "tests": [
            {
                "name": "should create a lab order",
                "steps": [
                    'Navigate to /lab',
                    'Click "New Order"',
                    'Select patient and tests',
                    'Submit order',
                ],
                "page": "/lab",
            },
            {
                "name": "should collect a sample for a lab order",
                "steps": [
                    'Navigate to Phlebotomy tab',
                    'Find pending collection',
                    'Mark as collected',
                    'Verify status update',
                ],
                "page": "/lab",
            },
            {
                "name": "should enter results for a lab order",
                "steps": [
                    'Find a collected order',
                    'Open results entry',
                    'Enter values',
                    'Save and verify result recorded',
                ],
                "page": "/lab",
            },
            {
                "name": "should complete a lab order",
                "steps": [
                    'Find order with results entered',
                    'Mark as complete/verified',
                    'Verify final status',
                ],
                "page": "/lab",
            },
        ],
    },
    {
        "file": "pharmacy-dispense.spec.ts",
        "title": "Pharmacy Dispensing Flow",
        "description": "View prescription → dispense → verify stock update",
        "tests": [
            {
                "name": "should view pending pharmacy orders",
                "steps": [
                    'Navigate to /pharmacy',
                    'View orders list',
                    'Verify pending orders visible',
                ],
                "page": "/pharmacy",
            },
            {
                "name": "should dispense a pharmacy order",
                "steps": [
                    'Select a pending order',
                    'Click dispense',
                    'Confirm dispensing',
                    'Verify status changes to dispensed',
                ],
                "page": "/pharmacy",
            },
        ],
    },
    {
        "file": "billing-invoice.spec.ts",
        "title": "Billing Invoice Flow",
        "description": "Create invoice → add items → payment → receipt",
        "tests": [
            {
                "name": "should create a new invoice",
                "steps": [
                    'Navigate to /billing',
                    'Click "New Invoice"',
                    'Select patient',
                    'Add line items',
                    'Save invoice',
                ],
                "page": "/billing",
            },
            {
                "name": "should record a payment against an invoice",
                "steps": [
                    'Open a saved invoice',
                    'Click "Record Payment"',
                    'Enter amount and payment mode',
                    'Submit and verify payment recorded',
                ],
                "page": "/billing",
            },
        ],
    },
    {
        "file": "ipd-admission.spec.ts",
        "title": "IPD Admission Flow",
        "description": "Admit patient → bed assignment → orders → discharge",
        "tests": [
            {
                "name": "should admit a patient",
                "steps": [
                    'Navigate to /ipd',
                    'Click "New Admission"',
                    'Select patient and admitting doctor',
                    'Choose department',
                    'Submit admission',
                ],
                "page": "/ipd",
            },
            {
                "name": "should assign a bed to admitted patient",
                "steps": [
                    'Open an admitted patient',
                    'Navigate to bed assignment',
                    'Select available bed',
                    'Confirm assignment',
                ],
                "page": "/ipd",
            },
            {
                "name": "should initiate discharge",
                "steps": [
                    'Open an admitted patient',
                    'Click "Initiate Discharge"',
                    'Fill discharge summary',
                    'Complete discharge process',
                ],
                "page": "/ipd",
            },
        ],
    },
    {
        "file": "admin-setup.spec.ts",
        "title": "Admin Setup Flow",
        "description": "Create department → create user → assign role → verify access",
        "tests": [
            {
                "name": "should create a new department",
                "steps": [
                    'Navigate to admin settings → Departments',
                    'Click "Add Department"',
                    'Fill name and code',
                    'Submit and verify in list',
                ],
                "page": "/admin/settings",
            },
            {
                "name": "should create a new user",
                "steps": [
                    'Navigate to admin → Users',
                    'Click "Add User"',
                    'Fill username, email, role',
                    'Submit and verify in list',
                ],
                "page": "/admin/users",
            },
            {
                "name": "should manage roles and permissions",
                "steps": [
                    'Navigate to admin → Roles',
                    'Create or edit a role',
                    'Toggle permissions in the tree',
                    'Save and verify',
                ],
                "page": "/admin/roles",
            },
        ],
    },
]


# ── Generator ────────────────────────────────────────────────────────


def generate_skeleton(scenario: dict) -> str:
    """Generate a skeleton spec file for a scenario."""
    lines = [
        "/**",
        f" * E2E Scenario: {scenario['title']}",
        f" * {scenario['description']}",
        " *",
        " * Generated by: python3 scripts/generate_e2e_skeletons.py",
        " * Fill in the TODO markers to complete these tests.",
        " */",
        "",
        'import { test, expect } from "@playwright/test";',
        'import { routeApiDirect, navigateTo } from "../helpers";',
        "",
        f'test.describe("{scenario["title"]}", () => {{',
        "  test.beforeEach(async ({ page }) => {",
        "    await routeApiDirect(page);",
        "  });",
        "",
        "  test.afterEach(async ({ page }) => {",
        '    await page.unrouteAll({ behavior: "ignoreErrors" });',
        "  });",
        "",
    ]

    for t in scenario["tests"]:
        lines.append(f'  test("{t["name"]}", async ({{ page }}) => {{')
        lines.append(f'    await navigateTo(page, "{t["page"]}");')
        lines.append("")
        for step in t["steps"]:
            lines.append(f"    // TODO: {step}")
        lines.append("")
        lines.append(
            "    // TODO: Add assertions here"
        )
        lines.append("  });")
        lines.append("")

    lines.append("});")
    lines.append("")

    return "\n".join(lines)


# ── Main ─────────────────────────────────────────────────────────────


def main():
    SCENARIOS_DIR.mkdir(parents=True, exist_ok=True)

    generated = 0
    total_tests = 0

    for scenario in SCENARIOS:
        content = generate_skeleton(scenario)
        file_path = SCENARIOS_DIR / scenario["file"]
        file_path.write_text(content)
        test_count = len(scenario["tests"])
        generated += 1
        total_tests += test_count
        print(f"  Generated {scenario['file']}: {test_count} test skeletons")

    print()
    print(f"Generated {generated} scenario files with {total_tests} test skeletons")
    print(f"Output directory: {SCENARIOS_DIR}")
    print()
    print("Next steps:")
    print("  1. Fill in the TODO markers in each file with real selectors and assertions")
    print("  2. Run: make e2e-test (requires running backend + frontend)")


if __name__ == "__main__":
    main()
