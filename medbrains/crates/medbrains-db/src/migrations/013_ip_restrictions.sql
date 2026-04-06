-- IP-based access restriction support.
-- Tenants can configure allowed IP ranges (CIDR notation).
-- An empty array means no restriction (all IPs allowed).

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS
    allowed_ips JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN tenants.allowed_ips IS
    'Array of allowed IP ranges in CIDR notation, e.g. ["10.0.0.0/8", "192.168.1.0/24"]. Empty = no restriction.';
