#!/usr/bin/env python3
"""Seed world geographic and regulatory data into PostgreSQL.

Interactive CLI to populate geo_countries, geo_states, and regulatory_bodies
tables with deterministic UUIDs and UPSERT semantics.

Usage:
    pip install psycopg2-binary
    python3 scripts/seed_world_geo.py
"""

import json
import os
import sys
import uuid
from pathlib import Path
from urllib.parse import urlparse

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    print("Error: psycopg2 is required. Install it with:")
    print("  pip install psycopg2-binary")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data" / "geo"
ENV_FILE = PROJECT_ROOT / "medbrains" / ".env"

# ---------------------------------------------------------------------------
# Deterministic UUID namespace (DNS namespace from RFC 4122)
# ---------------------------------------------------------------------------

NAMESPACE = uuid.UUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8")


def country_uuid(code: str) -> str:
    return str(uuid.uuid5(NAMESPACE, f"geo-country-{code}"))


def state_uuid(country_code: str, state_code: str) -> str:
    return str(uuid.uuid5(NAMESPACE, f"geo-state-{country_code}-{state_code}"))


def regulatory_uuid(code: str) -> str:
    return str(uuid.uuid5(NAMESPACE, f"regulatory-{code}"))


# ---------------------------------------------------------------------------
# Region mapping
# ---------------------------------------------------------------------------

REGIONS = {
    "Asia": [
        "AF", "AM", "AZ", "BH", "BD", "BT", "BN", "KH", "CN", "CY", "GE",
        "IN", "ID", "IR", "IQ", "IL", "JP", "JO", "KZ", "KW", "KG", "LA",
        "LB", "MY", "MV", "MN", "MM", "NP", "KP", "KR", "OM", "PK", "PH",
        "QA", "SA", "SG", "LK", "SY", "TJ", "TH", "TL", "TM", "AE", "UZ",
        "VN", "YE",
    ],
    "Europe": [
        "AL", "AD", "AT", "BY", "BE", "BA", "BG", "HR", "CZ", "DK", "EE",
        "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT",
        "LU", "MT", "MD", "MC", "ME", "NL", "MK", "NO", "PL", "PT", "RO",
        "RU", "SM", "RS", "SK", "SI", "ES", "SE", "CH", "UA", "GB", "VA",
    ],
    "Americas": [
        "AG", "AR", "BS", "BB", "BZ", "BO", "BR", "CA", "CL", "CO", "CR",
        "CU", "DM", "DO", "EC", "SV", "GD", "GT", "GY", "HT", "HN", "JM",
        "MX", "NI", "PA", "PY", "PE", "KN", "LC", "VC", "SR", "TT", "US",
        "UY", "VE",
    ],
    "Africa": [
        "DZ", "AO", "BJ", "BW", "BF", "BI", "CV", "CM", "CF", "TD", "KM",
        "CG", "CD", "CI", "DJ", "EG", "GQ", "ER", "SZ", "ET", "GA", "GM",
        "GH", "GN", "GW", "KE", "LS", "LR", "LY", "MG", "MW", "ML", "MR",
        "MU", "MA", "MZ", "NA", "NE", "NG", "RW", "ST", "SN", "SC", "SL",
        "SO", "ZA", "SS", "SD", "TZ", "TG", "TN", "UG", "ZM", "ZW",
    ],
    "Oceania": [
        "AU", "FJ", "KI", "MH", "FM", "NR", "NZ", "PW", "PG", "WS", "SB",
        "TO", "TV", "VU",
    ],
}


# ---------------------------------------------------------------------------
# .env parser
# ---------------------------------------------------------------------------

def read_database_url() -> str:
    """Read DATABASE_URL from the project .env file."""
    if not ENV_FILE.exists():
        print(f"Error: .env file not found at {ENV_FILE}")
        sys.exit(1)

    with open(ENV_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            if key.strip() == "DATABASE_URL":
                return value.strip()

    print("Error: DATABASE_URL not found in .env file")
    sys.exit(1)


def parse_database_url(url: str) -> dict:
    """Parse a postgres:// URL into connection parameters."""
    parsed = urlparse(url)
    return {
        "host": parsed.hostname or "localhost",
        "port": parsed.port or 5432,
        "dbname": parsed.path.lstrip("/"),
        "user": parsed.username or "medbrains",
        "password": parsed.password or "",
    }


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def load_json(filename: str) -> list:
    """Load a JSON array from the data directory."""
    filepath = DATA_DIR / filename
    if not filepath.exists():
        print(f"  Warning: {filepath} not found. Skipping.")
        return []
    with open(filepath, "r") as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Database connection
# ---------------------------------------------------------------------------

def get_connection(db_params: dict):
    """Create and return a psycopg2 connection."""
    try:
        conn = psycopg2.connect(**db_params)
        conn.autocommit = False
        return conn
    except psycopg2.OperationalError as e:
        print(f"Error: Could not connect to database: {e}")
        sys.exit(1)


# ---------------------------------------------------------------------------
# Seed functions
# ---------------------------------------------------------------------------

def seed_countries(conn, countries: list) -> int:
    """Insert or update countries. Returns count of rows affected."""
    if not countries:
        print("  No country data to seed.")
        return 0

    values = [
        (
            country_uuid(c["code"]),
            c["code"],
            c["name"],
            c.get("phone_code"),
            c.get("currency"),
            True,
        )
        for c in countries
    ]

    sql = """
        INSERT INTO geo_countries (id, code, name, phone_code, currency, is_active)
        VALUES %s
        ON CONFLICT (code) DO UPDATE SET
            name = EXCLUDED.name,
            phone_code = EXCLUDED.phone_code,
            currency = EXCLUDED.currency
    """

    cur = conn.cursor()
    execute_values(cur, sql, values, page_size=100)
    count = cur.rowcount
    conn.commit()
    cur.close()
    return count


def seed_states(conn, states: list) -> int:
    """Insert or update states/provinces. Returns count of rows affected."""
    if not states:
        print("  No state data to seed.")
        return 0

    # Build a lookup of country_code -> actual DB UUID
    cur = conn.cursor()
    cur.execute("SELECT code, id FROM geo_countries")
    country_lookup = {row[0]: str(row[1]) for row in cur.fetchall()}
    cur.close()

    values = []
    skipped = 0
    for s in states:
        cc = s.get("country_code")
        sc = s.get("code")
        if not cc or not sc:
            skipped += 1
            continue
        cid = country_lookup.get(cc)
        if not cid:
            skipped += 1
            continue
        values.append((
            state_uuid(cc, sc),
            cid,
            sc,
            s["name"],
            True,
        ))

    if skipped > 0:
        print(f"  Skipped {skipped} states with missing country_code or code.")

    if not values:
        print("  No valid state data to seed.")
        return 0

    sql = """
        INSERT INTO geo_states (id, country_id, code, name, is_active)
        VALUES %s
        ON CONFLICT (country_id, code) DO UPDATE SET
            name = EXCLUDED.name
    """

    cur = conn.cursor()
    execute_values(cur, sql, values, page_size=100)
    count = cur.rowcount
    conn.commit()
    cur.close()
    return count


def seed_regulatory_bodies(conn, bodies: list) -> int:
    """Insert or update regulatory bodies. Returns count of rows affected."""
    if not bodies:
        print("  No regulatory body data to seed.")
        return 0

    # Build lookups from actual DB UUIDs
    cur = conn.cursor()
    cur.execute("SELECT code, id FROM geo_countries")
    country_lookup = {row[0]: str(row[1]) for row in cur.fetchall()}
    cur.execute("SELECT country_id, code, id FROM geo_states")
    state_lookup = {(str(row[0]), row[1]): str(row[2]) for row in cur.fetchall()}
    cur.close()

    values = []
    for b in bodies:
        code = b["code"]
        cc = b.get("country_code")
        cid = country_lookup.get(cc) if cc else None
        # state_id lookup: if state_code and country_code are provided
        sc = b.get("state_code")
        sid = state_lookup.get((country_lookup.get(cc, ""), sc)) if (cc and sc) else None

        values.append((
            regulatory_uuid(code),
            code,
            b["name"],
            b["level"],
            cid,
            sid,
            b.get("description"),
            True,
        ))

    sql = """
        INSERT INTO regulatory_bodies (id, code, name, level, country_id, state_id, description, is_active)
        VALUES %s
        ON CONFLICT (code) DO UPDATE SET
            name = EXCLUDED.name,
            level = EXCLUDED.level,
            country_id = EXCLUDED.country_id,
            description = EXCLUDED.description
    """

    cur = conn.cursor()
    execute_values(cur, sql, values, page_size=100)
    count = cur.rowcount
    conn.commit()
    cur.close()
    return count


# ---------------------------------------------------------------------------
# Stats
# ---------------------------------------------------------------------------

def show_stats(conn):
    """Display current row counts for geo tables."""
    cur = conn.cursor()
    tables = [
        ("Countries", "geo_countries"),
        ("States/Provinces", "geo_states"),
        ("Regulatory Bodies", "regulatory_bodies"),
    ]
    print("\nCurrent database stats:")
    for label, table in tables:
        try:
            cur.execute(f"SELECT COUNT(*) FROM {table}")
            count = cur.fetchone()[0]
            print(f"  {label}: {count}")
        except psycopg2.Error:
            conn.rollback()
            print(f"  {label}: table not found (run migration 003 first)")
    cur.close()


# ---------------------------------------------------------------------------
# Interactive menu handlers
# ---------------------------------------------------------------------------

def handle_seed_countries(conn):
    """Menu option [1]: Seed all countries."""
    countries = load_json("countries.json")
    if not countries:
        return
    total = len(countries)
    print(f"Seeding countries... ", end="", flush=True)
    count = seed_countries(conn, countries)
    print(f"{total}/{total} done. ({count} rows affected)")


def handle_seed_states(conn):
    """Menu option [2]: Seed all states/provinces."""
    states = load_json("states.json")
    if not states:
        return
    total = len(states)
    print(f"Seeding states/provinces... ", end="", flush=True)
    count = seed_states(conn, states)
    print(f"{total}/{total} done. ({count} rows affected)")


def handle_seed_regulatory(conn):
    """Menu option [3]: Seed regulatory bodies."""
    bodies = load_json("regulatory_bodies.json")
    if not bodies:
        return
    total = len(bodies)
    print(f"Seeding regulatory bodies... ", end="", flush=True)
    count = seed_regulatory_bodies(conn, bodies)
    print(f"{total}/{total} done. ({count} rows affected)")


def handle_seed_all(conn):
    """Menu option [4]: Seed everything."""
    handle_seed_countries(conn)
    handle_seed_states(conn)
    handle_seed_regulatory(conn)
    print("\nAll geo data seeded successfully.")


def handle_seed_by_region(conn):
    """Menu option [5]: Seed by region."""
    print("\nAvailable regions:")
    region_names = list(REGIONS.keys())
    for i, name in enumerate(region_names, 1):
        codes = REGIONS[name]
        print(f"  [{i}] {name} ({len(codes)} countries)")
    print(f"  [0] Back to main menu")

    choice = input("\nSelect region: ").strip()
    if choice == "0":
        return

    try:
        idx = int(choice) - 1
        if idx < 0 or idx >= len(region_names):
            print("Invalid selection.")
            return
    except ValueError:
        print("Invalid input. Please enter a number.")
        return

    region = region_names[idx]
    region_codes = set(REGIONS[region])

    # Filter countries by region
    all_countries = load_json("countries.json")
    if not all_countries:
        return
    filtered_countries = [c for c in all_countries if c["code"] in region_codes]

    print(f"\nSeeding {region} countries... ", end="", flush=True)
    count = seed_countries(conn, filtered_countries)
    print(f"{len(filtered_countries)}/{len(filtered_countries)} done. ({count} rows affected)")

    # Filter states by region country codes
    all_states = load_json("states.json")
    if all_states:
        filtered_states = [s for s in all_states if s.get("country_code") in region_codes]
        if filtered_states:
            print(f"Seeding {region} states/provinces... ", end="", flush=True)
            count = seed_states(conn, filtered_states)
            print(f"{len(filtered_states)}/{len(filtered_states)} done. ({count} rows affected)")
        else:
            print(f"  No states found for {region}.")

    # Filter regulatory bodies by region country codes (include international bodies if any)
    all_bodies = load_json("regulatory_bodies.json")
    if all_bodies:
        filtered_bodies = [
            b for b in all_bodies
            if b.get("country_code") in region_codes
            or (b.get("country_code") is None and b.get("level") == "international")
        ]
        if filtered_bodies:
            print(f"Seeding {region} regulatory bodies... ", end="", flush=True)
            count = seed_regulatory_bodies(conn, filtered_bodies)
            print(f"{len(filtered_bodies)}/{len(filtered_bodies)} done. ({count} rows affected)")
        else:
            print(f"  No regulatory bodies found for {region}.")

    print(f"\n{region} geo data seeded successfully.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    database_url = read_database_url()
    db_params = parse_database_url(database_url)

    print("=== MedBrains World Geo Seeder ===")
    print(f"Database: {db_params['dbname']} @ {db_params['host']}:{db_params['port']}")
    print()

    conn = get_connection(db_params)

    try:
        while True:
            # Count available data
            countries = load_json("countries.json")
            states = load_json("states.json")
            bodies = load_json("regulatory_bodies.json")

            country_count = len(countries) if countries else 0
            state_count = len(states) if states else 0
            body_count = len(bodies) if bodies else 0

            print(f"[1] Seed all countries ({country_count})")
            print(f"[2] Seed all states/provinces ({state_count})")
            print(f"[3] Seed regulatory bodies ({body_count})")
            print("[4] Seed everything")
            print("[5] Seed by region (Asia, Europe, Americas, Africa, Oceania)")
            print("[6] Show current database stats")
            print("[7] Exit")
            print()

            choice = input("Select option: ").strip()
            print()

            if choice == "1":
                handle_seed_countries(conn)
            elif choice == "2":
                handle_seed_states(conn)
            elif choice == "3":
                handle_seed_regulatory(conn)
            elif choice == "4":
                handle_seed_all(conn)
            elif choice == "5":
                handle_seed_by_region(conn)
            elif choice == "6":
                show_stats(conn)
            elif choice == "7":
                print("Goodbye.")
                break
            else:
                print("Invalid option. Please select 1-7.")

            print()

    except KeyboardInterrupt:
        print("\n\nInterrupted. Goodbye.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
