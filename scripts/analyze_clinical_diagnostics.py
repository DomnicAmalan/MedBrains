#!/usr/bin/env python3
"""
Analyze Clinical and Diagnostics & Support sheets from MedBrains_Features.xlsx.
Groups features by Module, counts Total/Done/Partial/Pending per module,
and displays sorted by Pending count (highest first).
"""

import openpyxl
from collections import defaultdict

EXCEL_PATH = "/Users/apple/Projects/MedBrains/MedBrains_Features.xlsx"
SHEETS = ["Clinical", "Diagnostics & Support"]


def analyze_sheet(ws, sheet_name):
    """Parse a sheet and return per-module counts."""
    modules = defaultdict(lambda: {"total": 0, "Done": 0, "Partial": 0, "Pending": 0, "In Progress": 0, "Other": 0})

    for row in ws.iter_rows(min_row=2, values_only=False):  # skip header
        a_val = row[0].value  # S.No (column A)
        b_val = row[1].value  # Module (column B)
        g_val = row[6].value  # Status (column G)

        # Skip section headers (module/sub-module headers have no numeric S.No and no Module in B)
        if b_val is None or b_val == "Module":
            continue

        # Only count rows that have a numeric S.No (actual features)
        if not isinstance(a_val, (int, float)):
            continue

        module = str(b_val).strip()
        status = str(g_val).strip() if g_val else "Pending"

        modules[module]["total"] += 1

        if status == "Done":
            modules[module]["Done"] += 1
        elif status == "Partial":
            modules[module]["Partial"] += 1
        elif status == "In Progress":
            modules[module]["In Progress"] += 1
        elif status in ("Pending", "", "None"):
            modules[module]["Pending"] += 1
        else:
            modules[module]["Other"] += 1

    return modules


def print_summary(sheet_name, modules):
    """Print a formatted table of module stats."""
    # Sort by Pending count descending
    sorted_modules = sorted(modules.items(), key=lambda x: x[1]["Pending"], reverse=True)

    print(f"\n{'=' * 90}")
    print(f"  {sheet_name}")
    print(f"{'=' * 90}")
    print(f"{'Module':<28} {'Total':>6} {'Done':>6} {'Partial':>8} {'In Prog':>8} {'Pending':>8} {'Other':>6}")
    print(f"{'-' * 28} {'-' * 6} {'-' * 6} {'-' * 8} {'-' * 8} {'-' * 8} {'-' * 6}")

    sheet_total = {"total": 0, "Done": 0, "Partial": 0, "In Progress": 0, "Pending": 0, "Other": 0}

    for module, counts in sorted_modules:
        print(
            f"{module:<28} {counts['total']:>6} {counts['Done']:>6} {counts['Partial']:>8} "
            f"{counts['In Progress']:>8} {counts['Pending']:>8} {counts['Other']:>6}"
        )
        for key in sheet_total:
            sheet_total[key] += counts[key]

    print(f"{'-' * 28} {'-' * 6} {'-' * 6} {'-' * 8} {'-' * 8} {'-' * 8} {'-' * 6}")
    print(
        f"{'SHEET TOTAL':<28} {sheet_total['total']:>6} {sheet_total['Done']:>6} "
        f"{sheet_total['Partial']:>8} {sheet_total['In Progress']:>8} "
        f"{sheet_total['Pending']:>8} {sheet_total['Other']:>6}"
    )
    done_pct = (sheet_total["Done"] / sheet_total["total"] * 100) if sheet_total["total"] > 0 else 0
    print(f"  Completion: {done_pct:.1f}% Done")


def main():
    wb = openpyxl.load_workbook(EXCEL_PATH, read_only=True)

    grand_total = {"total": 0, "Done": 0, "Partial": 0, "In Progress": 0, "Pending": 0, "Other": 0}

    for sheet_name in SHEETS:
        ws = wb[sheet_name]
        modules = analyze_sheet(ws, sheet_name)
        print_summary(sheet_name, modules)

        for counts in modules.values():
            for key in grand_total:
                grand_total[key] += counts[key]

    # Combined summary
    print(f"\n{'=' * 90}")
    print(f"  COMBINED (Clinical + Diagnostics & Support)")
    print(f"{'=' * 90}")

    # Merge modules across sheets
    all_modules = defaultdict(lambda: {"total": 0, "Done": 0, "Partial": 0, "In Progress": 0, "Pending": 0, "Other": 0})
    for sheet_name in SHEETS:
        ws = wb[sheet_name]
        modules = analyze_sheet(ws, sheet_name)
        for module, counts in modules.items():
            for key in counts:
                all_modules[module][key] += counts[key]

    sorted_all = sorted(all_modules.items(), key=lambda x: x[1]["Pending"], reverse=True)

    print(f"{'Module':<28} {'Total':>6} {'Done':>6} {'Partial':>8} {'In Prog':>8} {'Pending':>8} {'Other':>6}")
    print(f"{'-' * 28} {'-' * 6} {'-' * 6} {'-' * 8} {'-' * 8} {'-' * 8} {'-' * 6}")

    for module, counts in sorted_all:
        print(
            f"{module:<28} {counts['total']:>6} {counts['Done']:>6} {counts['Partial']:>8} "
            f"{counts['In Progress']:>8} {counts['Pending']:>8} {counts['Other']:>6}"
        )

    print(f"{'-' * 28} {'-' * 6} {'-' * 6} {'-' * 8} {'-' * 8} {'-' * 8} {'-' * 6}")
    print(
        f"{'GRAND TOTAL':<28} {grand_total['total']:>6} {grand_total['Done']:>6} "
        f"{grand_total['Partial']:>8} {grand_total['In Progress']:>8} "
        f"{grand_total['Pending']:>8} {grand_total['Other']:>6}"
    )
    done_pct = (grand_total["Done"] / grand_total["total"] * 100) if grand_total["total"] > 0 else 0
    pending_pct = (grand_total["Pending"] / grand_total["total"] * 100) if grand_total["total"] > 0 else 0
    print(f"  Completion: {done_pct:.1f}% Done, {pending_pct:.1f}% Pending")

    wb.close()


if __name__ == "__main__":
    main()
