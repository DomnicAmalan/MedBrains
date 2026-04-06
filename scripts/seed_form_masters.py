#!/usr/bin/env python3
"""
Generate SQL seed data for form_masters from Patient_Registration_Fields.xlsx.
Reads the Excel and outputs SQL INSERT statements for:
  - Additional regulatory bodies (HIPAA, NHS, CBAHI, UAE/NABIDH, EU/EHDS)
  - field_masters (60 fields)
  - field_regulatory_links (~200+ rows)
  - form_masters (1 form)
  - form_sections (10 sections)
  - form_fields (60 links)
  - module_form_links (1 link)
"""

import json
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:
    print("ERROR: openpyxl not installed. Run: pip3 install openpyxl", file=sys.stderr)
    sys.exit(1)

EXCEL_PATH = Path(__file__).parent.parent / "data" / "Patient_Registration_Fields.xlsx"
OUTPUT_PATH = Path(__file__).parent.parent / "medbrains" / "crates" / "medbrains-db" / "src" / "migrations" / "006_form_masters_seed.sql"

# Regulatory body IDs (existing from migration 004 + new ones)
REG_BODIES = {
    "NABH":     "f0000000-0000-0000-0000-000000000003",
    "JCI":      "f0000000-0000-0000-0000-000000000001",
    "HIPAA":    "f0000000-0000-0000-0000-000000000025",
    "ABDM":     "f0000000-0000-0000-0000-000000000016",
    "NHS":      "f0000000-0000-0000-0000-000000000026",
    "CBAHI":    "f0000000-0000-0000-0000-000000000027",
    "UAE":      "f0000000-0000-0000-0000-000000000028",
    "EU":       "f0000000-0000-0000-0000-000000000029",
}

# Column index mapping (0-based) from "Registration Fields" sheet
COL_SNO = 0
COL_SECTION = 1
COL_NAME = 2
COL_DB_COLUMN = 3
COL_DATA_TYPE = 4
COL_REQUIRED = 5
COL_FHIR = 6
COL_NABH = 7
COL_JCI = 8
COL_HIPAA = 9
COL_ABDM = 10
COL_NHS = 11
COL_CBAHI = 12
COL_UAE = 13
COL_EU = 14
COL_VALIDATION = 15
COL_UI_HINT = 16

# Regulatory column index -> body key
REG_COLUMNS = {
    COL_NABH: "NABH",
    COL_JCI:  "JCI",
    COL_HIPAA: "HIPAA",
    COL_ABDM: "ABDM",
    COL_NHS:  "NHS",
    COL_CBAHI: "CBAHI",
    COL_UAE:  "UAE",
    COL_EU:   "EU",
}

# Data type mapping from Excel to our enum
DATA_TYPE_MAP = {
    "TEXT": "text",
    "DATE": "date",
    "BOOLEAN": "boolean",
    "ENUM": "select",
    "UUID FK": "uuid_fk",
    "TIMESTAMPTZ": "datetime",
    "RECORD": "json",
}

# Requirement level mapping
REQ_LEVEL_MAP = {
    "Mandatory": "mandatory",
    "Optional": "optional",
    "Conditional": "conditional",
    "Mandatory (per entry)": "mandatory",
    "Mandatory (for ABHA)": "conditional",
}

# Section metadata
SECTION_META = {
    "Core Identity":     {"code": "core_identity",     "icon": "IconUser",        "order": 1, "collapsible": False, "default_open": True},
    "Demographics":      {"code": "demographics",      "icon": "IconId",          "order": 2, "collapsible": True,  "default_open": True},
    "Contact":           {"code": "contact",            "icon": "IconPhone",       "order": 3, "collapsible": True,  "default_open": True},
    "Emergency Contact": {"code": "emergency_contact",  "icon": "IconHeartbeat",   "order": 4, "collapsible": True,  "default_open": True},
    "Address":           {"code": "address",            "icon": "IconMapPin",      "order": 5, "collapsible": True,  "default_open": True},
    "Insurance":         {"code": "insurance",          "icon": "IconShield",      "order": 6, "collapsible": True,  "default_open": False},
    "Government ID":     {"code": "government_id",      "icon": "IconCreditCard",  "order": 7, "collapsible": True,  "default_open": False},
    "Consent":           {"code": "consent",            "icon": "IconClipboard",   "order": 8, "collapsible": True,  "default_open": True},
    "Registration":      {"code": "registration",       "icon": "IconForms",       "order": 9, "collapsible": True,  "default_open": True},
    "Allergies":         {"code": "allergies",           "icon": "IconAlertTriangle","order": 10,"collapsible": True,  "default_open": True},
}

# UI width defaults based on data type
UI_WIDTH_DEFAULTS = {
    "text": "half",
    "email": "half",
    "phone": "half",
    "date": "half",
    "datetime": "half",
    "select": "half",
    "boolean": "quarter",
    "uuid_fk": "half",
    "json": "full",
    "textarea": "full",
}

# Quick mode fields (appear in quick registration)
QUICK_MODE_FIELDS = {
    "first_name", "last_name", "date_of_birth", "biological_sex",
    "phone_primary", "category", "registration_type",
}


def sql_str(val):
    """Escape a string for SQL."""
    if val is None:
        return "NULL"
    escaped = str(val).replace("'", "''")
    return f"'{escaped}'"


def sql_bool(val):
    return "true" if val else "false"


def parse_validation(validation_text, data_type_raw):
    """Parse the validation rule text into a JSONB object."""
    if not validation_text:
        return None
    v = {}
    text = str(validation_text)

    # Extract options from "Values: x, y, z" pattern
    if "Values:" in text or "values:" in text:
        parts = text.split(":", 1)
        if len(parts) > 1:
            options_str = parts[1].strip().rstrip(".")
            options = [o.strip() for o in options_str.split(",")]
            v["options"] = options

    # Extract min/max length
    if "Min" in text and "char" in text.lower():
        import re
        match = re.search(r"Min\s+(\d+)\s+char", text)
        if match:
            v["min_length"] = int(match.group(1))
    if "max" in text.lower() and "char" in text.lower():
        import re
        match = re.search(r"[Mm]ax\s+(\d+)\s+char", text)
        if match:
            v["max_length"] = int(match.group(1))

    # Extract regex patterns
    if "Regex:" in text or "Format:" in text or "^" in text:
        import re
        match = re.search(r'(\^[^\s.]+\$?)', text)
        if match:
            v["regex"] = match.group(1)

    # Extract FK references
    if "FK to" in text:
        import re
        match = re.search(r'FK to (\w+)', text)
        if match:
            v["fk_table"] = match.group(1)

    # Handle data type size hints
    if data_type_raw and "(" in str(data_type_raw):
        import re
        match = re.search(r'\((\d+)\)', str(data_type_raw))
        if match:
            v["max_length"] = int(match.group(1))

    return v if v else None


def parse_db_parts(db_column_raw):
    """Split 'patient_contacts.contact_name' into (table, column) or just ('patients', column)."""
    if not db_column_raw:
        return "patients", None
    s = str(db_column_raw)
    if "." in s:
        parts = s.split(".", 1)
        return parts[0], parts[1]
    if " " in s:
        # Handle "patient_identifiers (type=aadhaar)" pattern
        parts = s.split(" ", 1)
        return parts[0], s
    return "patients", s


def parse_condition(required_text, validation_text, db_column_raw):
    """Generate a condition JSONB for conditional fields."""
    if required_text != "Conditional":
        return None

    cond = None
    vtext = str(validation_text or "").lower()

    if "required when financial_class = insurance" in vtext or "required with insurance" in vtext.lower():
        cond = {"field": "patient.financial_class", "operator": "eq", "value": "insurance"}
    elif "required if is_deceased = true" in vtext:
        cond = {"field": "patient.is_deceased", "operator": "eq", "value": True}
    elif "required when marital_status = married" in vtext or "marital_status" in vtext:
        cond = {"field": "patient.marital_status", "operator": "in", "values": ["married", "separated", "widowed"]}
    elif "required when patient age < 18" in vtext or "minor" in vtext:
        cond = {"field": "_tenant.patient_is_minor", "operator": "eq", "value": True}
    elif "required with guardian" in vtext or "guardian name" in vtext.lower():
        cond = {"field": "patient.guardian_name", "operator": "is_not_empty"}
    elif "regional language" in vtext.lower() or "regional" in str(db_column_raw or "").lower():
        cond = {"field": "_tenant.requires_local_script", "operator": "eq", "value": True}

    return cond


def extract_clause_code(clause_text):
    """Extract a short clause code from clause reference text."""
    if not clause_text:
        return None
    import re
    # Match patterns like "AAC.2", "IPSG.1", "COP.5", "PRE.1", "45 CFR 164.514(b)", "ESR"
    match = re.search(r'([A-Z]{2,}[\.\s]?\d+(?:\.\d+)?(?:\s+ME\d+)?)', str(clause_text))
    if match:
        return match.group(1).strip()
    # Match simple codes like "ESR", "USCDI v2"
    match = re.search(r'^([A-Z]{2,}(?:\s+v\d+)?)', str(clause_text))
    if match:
        return match.group(1).strip()
    return None


def main():
    wb = openpyxl.load_workbook(str(EXCEL_PATH), read_only=True)
    ws = wb["Registration Fields"]

    # Parse all field rows
    fields = []
    current_section = None
    field_counter = 0

    for row in ws.iter_rows(min_row=2, values_only=True):  # Skip header
        vals = list(row)
        sno = vals[COL_SNO]
        section = vals[COL_SECTION]
        name = vals[COL_NAME]

        # Section header row (no S.No, just section name in first column)
        if sno is None and section is None and name is None:
            # This is a section header — the section name is in COL_SNO position
            if vals[0] and isinstance(vals[0], str) and vals[0] in SECTION_META:
                current_section = vals[0]
            continue

        if name is None:
            continue

        if section:
            current_section = section

        if current_section is None:
            continue

        field_counter += 1
        db_table, db_column = parse_db_parts(vals[COL_DB_COLUMN])

        # Build field code
        raw_col = str(vals[COL_DB_COLUMN] or name.lower().replace(" ", "_").replace("/", "_"))
        if "." in raw_col:
            field_code = raw_col
        elif "(" in raw_col:
            # patient_identifiers (type=aadhaar) -> patient_identifiers.aadhaar
            import re
            m = re.search(r'(\w+)\s*\(type=(\w+(?:/\w+)?)\)', raw_col)
            if m:
                field_code = f"{m.group(1)}.{m.group(2).replace('/', '_')}"
            else:
                field_code = f"patient.{raw_col.split()[0]}"
        else:
            field_code = f"patient.{raw_col}"

        # Map data type
        data_type_raw = str(vals[COL_DATA_TYPE] or "TEXT")
        # Strip size hints like TEXT(12)
        dt_key = data_type_raw.split("(")[0].strip().upper()
        data_type = DATA_TYPE_MAP.get(dt_key, "text")

        # Map requirement level
        required_raw = str(vals[COL_REQUIRED] or "Optional")
        requirement = REQ_LEVEL_MAP.get(required_raw, "optional")

        # Parse validation
        validation = parse_validation(vals[COL_VALIDATION], data_type_raw)

        # Parse condition
        condition = parse_condition(required_raw, vals[COL_VALIDATION], vals[COL_DB_COLUMN])

        # UI width
        ui_width = UI_WIDTH_DEFAULTS.get(data_type, "half")
        if db_column and "address" in str(db_column).lower() and "line" in str(db_column).lower():
            ui_width = "full"

        # Quick mode
        is_quick = (db_column or "").replace("patient.", "") in QUICK_MODE_FIELDS

        # Regulatory links
        reg_links = []
        for col_idx, body_key in REG_COLUMNS.items():
            clause = vals[col_idx] if col_idx < len(vals) else None
            if clause:
                clause_code = extract_clause_code(str(clause))
                # Determine per-body requirement level
                if requirement == "mandatory":
                    body_req = "mandatory"
                elif requirement == "conditional":
                    body_req = "conditional"
                else:
                    body_req = "recommended"
                reg_links.append({
                    "body_key": body_key,
                    "clause_reference": str(clause),
                    "clause_code": clause_code,
                    "requirement_level": body_req,
                })

        fields.append({
            "idx": field_counter,
            "section": current_section,
            "name": str(name),
            "field_code": field_code,
            "db_table": db_table,
            "db_column": db_column,
            "data_type": data_type,
            "requirement": requirement,
            "fhir_path": vals[COL_FHIR],
            "validation": validation,
            "ui_hint": vals[COL_UI_HINT],
            "ui_width": ui_width,
            "condition": condition,
            "is_quick": is_quick,
            "reg_links": reg_links,
        })

    wb.close()

    # Generate SQL
    lines = []
    lines.append("-- Auto-generated seed data from Patient_Registration_Fields.xlsx")
    lines.append(f"-- {len(fields)} fields, {sum(len(f['reg_links']) for f in fields)} regulatory links")
    lines.append("")

    # Additional regulatory bodies (not in migration 004)
    lines.append("-- Additional regulatory bodies for international support")
    lines.append("INSERT INTO regulatory_bodies (id, code, name, level, country_id, description) VALUES")
    new_bodies = [
        ("f0000000-0000-0000-0000-000000000025", "HIPAA", "Health Insurance Portability and Accountability Act", "international", "NULL", "US health data privacy and security"),
        ("f0000000-0000-0000-0000-000000000026", "NHS", "National Health Service", "national", "(SELECT id FROM geo_countries WHERE code = 'IN')", "UK national health system"),
        ("f0000000-0000-0000-0000-000000000027", "CBAHI", "Saudi Central Board for Accreditation of Healthcare Institutions", "international", "NULL", "Saudi healthcare accreditation"),
        ("f0000000-0000-0000-0000-000000000028", "NABIDH", "National Backbone for Integrated Dubai Health", "international", "NULL", "UAE Dubai health information exchange"),
        ("f0000000-0000-0000-0000-000000000029", "EHDS", "European Health Data Space", "international", "NULL", "EU health data interoperability framework"),
    ]
    body_lines = []
    for bid, code, name, level, country, desc in new_bodies:
        body_lines.append(f"    ('{bid}', '{code}', '{name}', '{level}', {country}, '{desc}')")
    lines.append(",\n".join(body_lines) + "\nON CONFLICT (code) DO NOTHING;")
    lines.append("")

    # Form master
    form_id = "a2000000-0000-0000-0000-000000000001"
    lines.append("-- Form: Patient Registration")
    lines.append(f"INSERT INTO form_masters (id, code, name, version, status, config) VALUES")
    config = json.dumps({"submit_label": "Register Patient", "supports_quick_mode": True})
    lines.append(f"    ('{form_id}', 'patient_registration', 'Patient Registration', 1, 'active', '{config}');")
    lines.append("")

    # Form sections
    lines.append("-- Form sections")
    lines.append("INSERT INTO form_sections (id, form_id, code, name, sort_order, is_collapsible, is_default_open, icon) VALUES")
    section_ids = {}
    sec_lines = []
    for sec_name, meta in SECTION_META.items():
        sec_id = f"a3000000-0000-0000-0000-{meta['order']:012d}"
        section_ids[sec_name] = sec_id
        sec_lines.append(
            f"    ('{sec_id}', '{form_id}', '{meta['code']}', '{sec_name}', {meta['order']}, "
            f"{sql_bool(meta['collapsible'])}, {sql_bool(meta['default_open'])}, {sql_str(meta['icon'])})"
        )
    lines.append(",\n".join(sec_lines) + ";")
    lines.append("")

    # Field masters
    lines.append("-- Field masters")
    lines.append("INSERT INTO field_masters (id, code, name, description, data_type, default_value, placeholder, validation, ui_component, ui_width, fhir_path, db_table, db_column, condition, is_system, is_active) VALUES")
    field_ids = {}
    fm_lines = []
    for f in fields:
        fid = f"a1000000-0000-0000-0000-{f['idx']:012d}"
        field_ids[f['field_code']] = fid
        validation_json = f"'{json.dumps(f['validation'])}'" if f['validation'] else "NULL"
        condition_json = f"'{json.dumps(f['condition'])}'" if f['condition'] else "NULL"
        fm_lines.append(
            f"    ('{fid}', {sql_str(f['field_code'])}, {sql_str(f['name'])}, {sql_str(f['ui_hint'])}, "
            f"'{f['data_type']}', NULL, NULL, {validation_json}, NULL, '{f['ui_width']}', "
            f"{sql_str(f['fhir_path'])}, {sql_str(f['db_table'])}, {sql_str(f['db_column'])}, "
            f"{condition_json}, true, true)"
        )
    lines.append(",\n".join(fm_lines) + ";")
    lines.append("")

    # Form fields (link fields to form via sections)
    lines.append("-- Form fields (linking fields to form sections)")
    lines.append("INSERT INTO form_fields (id, form_id, section_id, field_id, sort_order, label_override, is_quick_mode) VALUES")
    ff_lines = []
    for f in fields:
        ffid = f"a4000000-0000-0000-0000-{f['idx']:012d}"
        sec_id = section_ids.get(f['section'], section_ids.get('Registration'))
        fid = field_ids[f['field_code']]
        ff_lines.append(
            f"    ('{ffid}', '{form_id}', '{sec_id}', '{fid}', {f['idx']}, NULL, {sql_bool(f['is_quick'])})"
        )
    lines.append(",\n".join(ff_lines) + ";")
    lines.append("")

    # Field regulatory links
    lines.append("-- Field regulatory links")
    link_counter = 0
    frl_lines = []
    for f in fields:
        fid = field_ids[f['field_code']]
        for rl in f['reg_links']:
            link_counter += 1
            link_id = f"a5000000-0000-0000-0000-{link_counter:012d}"
            body_id = REG_BODIES[rl['body_key']]
            frl_lines.append(
                f"    ('{link_id}', '{fid}', '{body_id}', '{rl['requirement_level']}', "
                f"{sql_str(rl['clause_reference'])}, {sql_str(rl['clause_code'])}, NULL, NULL)"
            )

    if frl_lines:
        lines.append("INSERT INTO field_regulatory_links (id, field_id, regulatory_body_id, requirement_level, clause_reference, clause_code, description, condition_override) VALUES")
        lines.append(",\n".join(frl_lines) + ";")
    lines.append("")

    # Module form link
    lines.append("-- Module form link")
    lines.append(f"INSERT INTO module_form_links (module_code, form_id, context) VALUES")
    lines.append(f"    ('registration', '{form_id}', 'primary');")

    # Write output
    output = "\n".join(lines) + "\n"
    OUTPUT_PATH.write_text(output, encoding="utf-8")
    print(f"Generated {len(fields)} fields, {link_counter} regulatory links")
    print(f"Output: {OUTPUT_PATH}")

    # Also print to stdout for embedding
    print("\n--- SQL OUTPUT ---\n")
    print(output)


if __name__ == "__main__":
    main()
