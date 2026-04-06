-- IPD Phase 3a: Add nursery to ip_type enum for nursery bed management
ALTER TYPE ip_type ADD VALUE IF NOT EXISTS 'nursery';
