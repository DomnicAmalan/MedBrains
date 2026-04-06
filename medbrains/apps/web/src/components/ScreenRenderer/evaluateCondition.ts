/**
 * Pure function that evaluates a sidecar condition against context data.
 *
 * Condition format (from ConditionBuilder):
 * {
 *   logic: "and" | "or",
 *   rules: [
 *     { field: "status", operator: "eq", value: "active" },
 *     { field: "amount", operator: "gt", value: 100 }
 *   ]
 * }
 */

interface ConditionRule {
  field: string;
  operator: string;
  value: unknown;
}

interface Condition {
  logic?: "and" | "or";
  rules?: ConditionRule[];
}

function resolveField(data: Record<string, unknown>, path: string): unknown {
  return path.split(".").reduce<unknown>((obj, key) => {
    if (obj !== null && typeof obj === "object" && key in (obj as Record<string, unknown>)) {
      return (obj as Record<string, unknown>)[key];
    }
    return undefined;
  }, data);
}

function evaluateRule(
  rule: ConditionRule,
  data: Record<string, unknown>,
): boolean {
  const actual = resolveField(data, rule.field);
  const expected = rule.value;

  switch (rule.operator) {
    case "eq":
      return actual === expected || String(actual) === String(expected);
    case "neq":
      return actual !== expected && String(actual) !== String(expected);
    case "gt":
      return Number(actual) > Number(expected);
    case "gte":
      return Number(actual) >= Number(expected);
    case "lt":
      return Number(actual) < Number(expected);
    case "lte":
      return Number(actual) <= Number(expected);
    case "contains":
      return String(actual).includes(String(expected));
    case "starts_with":
      return String(actual).startsWith(String(expected));
    case "ends_with":
      return String(actual).endsWith(String(expected));
    case "is_empty":
      return actual === undefined || actual === null || actual === "";
    case "is_not_empty":
      return actual !== undefined && actual !== null && actual !== "";
    case "in":
      return Array.isArray(expected) && expected.includes(actual);
    case "not_in":
      return Array.isArray(expected) && !expected.includes(actual);
    default:
      return false;
  }
}

/**
 * Evaluates a condition object against the given data.
 * Returns `true` if condition is null/undefined (no condition = always pass).
 */
export function evaluateCondition(
  condition: Record<string, unknown> | null | undefined,
  data: Record<string, unknown>,
): boolean {
  if (!condition) return true;

  const cond = condition as unknown as Condition;
  const rules = cond.rules;

  if (!rules || rules.length === 0) return true;

  const logic = cond.logic ?? "and";

  if (logic === "or") {
    return rules.some((rule) => evaluateRule(rule, data));
  }

  return rules.every((rule) => evaluateRule(rule, data));
}
