import {
  Alert,
  Badge,
  Stack,
  Text,
  Textarea,
} from "@mantine/core";
import { useFormBuilderStore } from "@medbrains/stores";
import type { FormBuilderFieldNode } from "@medbrains/types";
import { IconAlertCircle, IconCheck } from "@tabler/icons-react";
import { useCallback, useMemo, useState } from "react";
import classes from "./form-builder.module.scss";

// ── Function Categories ─────────────────────────────────

interface FunctionInfo {
  name: string;
  signature: string;
  category: string;
}

const BUILTIN_FUNCTIONS: FunctionInfo[] = [
  { name: "ROUND", signature: "ROUND(value, decimals)", category: "Math" },
  { name: "CEIL", signature: "CEIL(value)", category: "Math" },
  { name: "FLOOR", signature: "FLOOR(value)", category: "Math" },
  { name: "ABS", signature: "ABS(value)", category: "Math" },
  { name: "MIN", signature: "MIN(a, b, ...)", category: "Math" },
  { name: "MAX", signature: "MAX(a, b, ...)", category: "Math" },
  { name: "POW", signature: "POW(base, exp)", category: "Math" },
  { name: "SQRT", signature: "SQRT(value)", category: "Math" },
  { name: "BMI", signature: "BMI(weight_kg, height_cm)", category: "Medical" },
  { name: "BSA", signature: "BSA(weight_kg, height_cm)", category: "Medical" },
  { name: "EGFR", signature: "EGFR(creatinine, age, is_female)", category: "Medical" },
  { name: "AGE_YEARS", signature: "AGE_YEARS(dob)", category: "Date" },
  { name: "UPPER", signature: "UPPER(text)", category: "String" },
  { name: "LOWER", signature: "LOWER(text)", category: "String" },
  { name: "CONCAT", signature: "CONCAT(a, b, ...)", category: "String" },
  { name: "IF", signature: "IF(condition, then, else)", category: "Logic" },
];

const CATEGORIES = ["Math", "Medical", "Date", "String", "Logic"];

// ── Validation ──────────────────────────────────────────

interface ValidationState {
  valid: boolean;
  message: string;
}

function validateExpression(expr: string): ValidationState {
  if (!expr.trim()) {
    return { valid: true, message: "" };
  }

  // Basic syntax checks
  const openParens = (expr.match(/\(/g) ?? []).length;
  const closeParens = (expr.match(/\)/g) ?? []).length;
  if (openParens !== closeParens) {
    return { valid: false, message: "Unmatched parentheses" };
  }

  // Check for known functions
  const fnCalls = expr.match(/[A-Z_]+\s*\(/g) ?? [];
  const knownFunctions = new Set(BUILTIN_FUNCTIONS.map((f) => f.name));
  for (const call of fnCalls) {
    const fnName = call.replace(/\s*\($/, "");
    if (!knownFunctions.has(fnName)) {
      return { valid: false, message: `Unknown function: ${fnName}` };
    }
  }

  return { valid: true, message: "Expression looks valid" };
}

// ── Component ───────────────────────────────────────────

interface ComputedEditorProps {
  expression: string | null;
  onChange: (expr: string | null) => void;
}

export function ComputedEditor({ expression, onChange }: ComputedEditorProps) {
  const allFields = useFormBuilderStore((s) => s.fields);
  const [value, setValue] = useState(expression ?? "");

  const validation = useMemo(() => validateExpression(value), [value]);

  const fieldOptions = useMemo(
    () =>
      Object.values(allFields)
        .filter((f: FormBuilderFieldNode) => f.dataType !== "computed")
        .map((f: FormBuilderFieldNode) => ({
          code: f.fieldCode,
          label: f.label,
        })),
    [allFields],
  );

  const handleChange = useCallback(
    (newValue: string) => {
      setValue(newValue);
      onChange(newValue || null);
    },
    [onChange],
  );

  const insertAtCursor = useCallback(
    (text: string) => {
      const newValue = value ? `${value} ${text}` : text;
      setValue(newValue);
      onChange(newValue || null);
    },
    [value, onChange],
  );

  return (
    <div className={classes.computedEditor}>
      <Textarea
        label="Formula"
        placeholder="e.g. BMI(weight_kg, height_cm)"
        value={value}
        onChange={(e) => handleChange(e.currentTarget.value)}
        minRows={3}
        autosize
        styles={{ input: { fontFamily: "monospace", fontSize: "var(--mantine-font-size-sm)" } }}
      />

      {value && (
        <Alert
          color={validation.valid ? "success" : "danger"}
          icon={validation.valid ? <IconCheck size={14} /> : <IconAlertCircle size={14} />}
          variant="light"
          p="xs"
        >
          <Text size="xs">{validation.message || "Valid"}</Text>
        </Alert>
      )}

      {/* Function picker */}
      <Stack gap={8}>
        <Text size="xs" fw={600} c="dimmed" tt="uppercase">
          Functions
        </Text>
        {CATEGORIES.map((category) => {
          const fns = BUILTIN_FUNCTIONS.filter((f) => f.category === category);
          return (
            <div key={category}>
              <Text size="xs" c="dimmed" mb={4}>
                {category}
              </Text>
              <div className={classes.functionChips}>
                {fns.map((fn) => (
                  <Badge
                    key={fn.name}
                    size="sm"
                    variant="light"
                    className={classes.functionChip}
                    onClick={() => insertAtCursor(`${fn.name}()`)}
                    title={fn.signature}
                    style={{ cursor: "pointer" }}
                  >
                    {fn.name}
                  </Badge>
                ))}
              </div>
            </div>
          );
        })}
      </Stack>

      {/* Field picker */}
      {fieldOptions.length > 0 && (
        <Stack gap={8}>
          <Text size="xs" fw={600} c="dimmed" tt="uppercase">
            Fields
          </Text>
          <div className={classes.functionChips}>
            {fieldOptions.map((field) => (
              <Badge
                key={field.code}
                size="sm"
                variant="outline"
                className={classes.functionChip}
                onClick={() => insertAtCursor(field.code)}
                title={field.label}
                style={{ cursor: "pointer" }}
              >
                {field.code}
              </Badge>
            ))}
          </div>
        </Stack>
      )}

      {/* Live preview */}
      {value && (
        <Stack gap={4}>
          <Text size="xs" fw={600} c="dimmed" tt="uppercase">
            Preview
          </Text>
          <div className={classes.computedPreview}>
            {validation.valid ? (
              <Text size="sm" c="dimmed" fs="italic">
                Result will be computed at runtime
              </Text>
            ) : (
              <Text size="sm" c="danger">
                Fix errors above
              </Text>
            )}
          </div>
        </Stack>
      )}
    </div>
  );
}
