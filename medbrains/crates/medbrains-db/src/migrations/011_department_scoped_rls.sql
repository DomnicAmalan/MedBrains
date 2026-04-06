-- Department-scoped RLS policies.
-- Tables with department_id get an additional policy that filters
-- by the user's assigned departments (stored in app.user_department_ids).
-- Bypass: if app.user_department_ids is empty or unset, no department
-- filtering is applied (admin/bypass roles see all).

-- Helper function: check if a department_id is in the user's department list.
-- Returns TRUE if no department restriction is set (empty/unset = full access).
CREATE OR REPLACE FUNCTION check_department_access(dept_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    dept_ids_raw TEXT;
    dept_ids UUID[];
BEGIN
    dept_ids_raw := current_setting('app.user_department_ids', true);
    IF dept_ids_raw IS NULL OR dept_ids_raw = '' OR dept_ids_raw = '{}' THEN
        RETURN TRUE;  -- no restriction
    END IF;
    dept_ids := dept_ids_raw::UUID[];
    RETURN dept_id = ANY(dept_ids) OR dept_id IS NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- Add department-scoped policies (these stack with existing tenant policies via AND)

CREATE POLICY dept_scope_encounters ON encounters
    USING (check_department_access(department_id));

CREATE POLICY dept_scope_opd_queues ON opd_queues
    USING (check_department_access(department_id));

CREATE POLICY dept_scope_services ON services
    USING (check_department_access(department_id));

CREATE POLICY dept_scope_lab_test_catalog ON lab_test_catalog
    USING (check_department_access(department_id));
