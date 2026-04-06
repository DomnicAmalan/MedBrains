-- 021: Add data_filters to dashboard_widgets for per-widget department scoping.
-- Supports "auto" (viewer's departments), "all" (hospital-wide), or "custom" (explicit department list).
-- Empty object {} defaults to scope "auto".

ALTER TABLE dashboard_widgets
    ADD COLUMN data_filters JSONB NOT NULL DEFAULT '{}';

COMMENT ON COLUMN dashboard_widgets.data_filters IS
    'Optional filters: {"scope":"auto"|"all"|"custom", "department_ids":[], "doctor_id":"", "date_range":"today|week|month|custom"}';
