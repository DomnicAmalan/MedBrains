-- Migration 028: Security Hardening — Refresh Token Rotation
--
-- Adds columns to refresh_tokens for:
-- 1. Device fingerprint validation (detect cookie theft across browsers)
-- 2. Token family tracking (for reuse detection)
-- 3. Token replacement chain (for rotation)
-- 4. IP address + User-Agent logging

ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS device_fingerprint TEXT;
ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS ip_address INET;
ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS user_agent TEXT;
ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS family_id UUID DEFAULT gen_random_uuid();
ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS replaced_by UUID REFERENCES refresh_tokens(id);
ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS used_at TIMESTAMPTZ;

-- Index for looking up all tokens in a family (reuse detection)
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_family
    ON refresh_tokens(family_id);

-- Index for counting active sessions per user (session limits)
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_active
    ON refresh_tokens(user_id)
    WHERE revoked = false;
