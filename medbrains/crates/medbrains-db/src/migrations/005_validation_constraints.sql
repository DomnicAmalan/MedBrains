-- 005: Add CHECK constraints for validation at the database layer
-- These are the last line of defense — frontend Zod + backend Rust validators run first.

-- ── Tenants ──────────────────────────────────────────────

ALTER TABLE tenants
    ADD CONSTRAINT chk_tenants_code_length
        CHECK (length(code) BETWEEN 2 AND 20),
    ADD CONSTRAINT chk_tenants_code_pattern
        CHECK (code ~ '^[A-Z0-9][A-Z0-9-]*[A-Z0-9]$'),
    ADD CONSTRAINT chk_tenants_name_length
        CHECK (length(name) BETWEEN 2 AND 100),
    ADD CONSTRAINT chk_tenants_fy_start_month
        CHECK (fy_start_month BETWEEN 1 AND 12),
    ADD CONSTRAINT chk_tenants_currency_length
        CHECK (length(currency) = 3),
    ADD CONSTRAINT chk_tenants_pincode_digits
        CHECK (pincode IS NULL OR pincode ~ '^\d{4,10}$'),
    ADD CONSTRAINT chk_tenants_email_pattern
        CHECK (email IS NULL OR email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

-- ── Facilities ───────────────────────────────────────────

ALTER TABLE facilities
    ADD CONSTRAINT chk_facilities_code_length
        CHECK (length(code) BETWEEN 2 AND 20),
    ADD CONSTRAINT chk_facilities_code_pattern
        CHECK (code ~ '^[A-Z0-9][A-Z0-9-]*[A-Z0-9]$'),
    ADD CONSTRAINT chk_facilities_name_length
        CHECK (length(name) BETWEEN 2 AND 100),
    ADD CONSTRAINT chk_facilities_bed_count_positive
        CHECK (bed_count >= 0);

-- ── Departments ──────────────────────────────────────────

ALTER TABLE departments
    ADD CONSTRAINT chk_departments_code_length
        CHECK (length(code) BETWEEN 2 AND 20),
    ADD CONSTRAINT chk_departments_code_pattern
        CHECK (code ~ '^[A-Z0-9][A-Z0-9-]*[A-Z0-9]$'),
    ADD CONSTRAINT chk_departments_name_length
        CHECK (length(name) BETWEEN 2 AND 100);

-- ── Locations ────────────────────────────────────────────

ALTER TABLE locations
    ADD CONSTRAINT chk_locations_code_length
        CHECK (length(code) BETWEEN 2 AND 20),
    ADD CONSTRAINT chk_locations_code_pattern
        CHECK (code ~ '^[A-Z0-9][A-Z0-9-]*[A-Z0-9]$'),
    ADD CONSTRAINT chk_locations_name_length
        CHECK (length(name) BETWEEN 2 AND 100);

-- ── Users ────────────────────────────────────────────────

ALTER TABLE users
    ADD CONSTRAINT chk_users_username_length
        CHECK (length(username) BETWEEN 3 AND 30),
    ADD CONSTRAINT chk_users_username_pattern
        CHECK (username ~ '^[a-z][a-z0-9_]*$'),
    ADD CONSTRAINT chk_users_email_pattern
        CHECK (email ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
    ADD CONSTRAINT chk_users_full_name_length
        CHECK (length(full_name) BETWEEN 2 AND 100);

-- ── Sequences ────────────────────────────────────────────

ALTER TABLE sequences
    ADD CONSTRAINT chk_sequences_prefix_length
        CHECK (length(prefix) <= 20),
    ADD CONSTRAINT chk_sequences_pad_width
        CHECK (pad_width BETWEEN 3 AND 10);

-- ── Roles ────────────────────────────────────────────────

ALTER TABLE roles
    ADD CONSTRAINT chk_roles_code_length
        CHECK (length(code) BETWEEN 2 AND 20),
    ADD CONSTRAINT chk_roles_name_length
        CHECK (length(name) BETWEEN 2 AND 100);

-- ── Module Config ────────────────────────────────────────

ALTER TABLE module_config
    ADD CONSTRAINT chk_module_config_code_length
        CHECK (length(code) >= 1);

-- ── Tenant Settings ──────────────────────────────────────

ALTER TABLE tenant_settings
    ADD CONSTRAINT chk_tenant_settings_key_length
        CHECK (length(key) >= 1);
