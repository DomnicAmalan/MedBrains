import { useQuery } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import type { Resolver } from "react-hook-form";
import type { z } from "zod";
import { api } from "@medbrains/api";
import { buildFormSchema } from "@medbrains/schemas";
import { evaluateFieldCondition, evaluateComputed } from "@medbrains/expressions";
import type { FieldCondition, ResolvedFormDefinition } from "@medbrains/types";

/**
 * Flatten a nested object into dot-separated keys.
 * RHF interprets dots in field names as nested paths, so
 * { patient: { first_name: "X" } } becomes { "patient.first_name": "X" }.
 */
function flattenObject(
  obj: Record<string, unknown>,
  prefix = "",
): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, val] of Object.entries(obj)) {
    const fullKey = prefix ? `${prefix}.${key}` : key;
    if (
      val !== null &&
      typeof val === "object" &&
      !Array.isArray(val) &&
      !(val instanceof Date) &&
      !(val instanceof File)
    ) {
      Object.assign(
        result,
        flattenObject(val as Record<string, unknown>, fullKey),
      );
    } else {
      result[fullKey] = val;
    }
  }
  return result;
}

/**
 * Wrapper around zodResolver that flattens nested RHF data before Zod validation.
 * RHF stores "patient.first_name" as { patient: { first_name: "X" } },
 * but our Zod schema expects flat keys like { "patient.first_name": "X" }.
 */
function flatZodResolver(
  schema: z.ZodObject<Record<string, z.ZodTypeAny>>,
): Resolver<Record<string, unknown>> {
  const resolver = zodResolver(schema);
  return (values, context, options) => {
    const flat = flattenObject(values as Record<string, unknown>);
    return resolver(flat, context, options);
  };
}

interface UseDynamicFormOptions {
  formCode: string;
  quickMode?: boolean;
  defaultValues?: Record<string, unknown>;
  tenantContext?: Record<string, unknown>;
}

export function useDynamicForm(options: UseDynamicFormOptions) {
  const { formCode, quickMode = false, defaultValues, tenantContext } = options;

  // Fetch resolved form definition
  const definitionQuery = useQuery({
    queryKey: ["form-definition", formCode, quickMode],
    queryFn: () => api.getFormDefinition(formCode, { quick_mode: quickMode }),
    staleTime: 5 * 60 * 1000, // 5 min cache
  });

  const definition = definitionQuery.data;

  // Build Zod schema from definition
  const schema = definition
    ? buildFormSchema(definition, {
        quickMode,
        formValues: defaultValues,
        tenantContext,
      })
    : null;

  // Initialize React Hook Form
  const form = useForm({
    resolver: schema ? flatZodResolver(schema) : undefined,
    defaultValues: defaultValues as Record<string, unknown>,
    mode: "onBlur",
  });

  return {
    definition,
    form,
    schema,
    isLoading: definitionQuery.isLoading,
    isError: definitionQuery.isError,
    error: definitionQuery.error,

    /**
     * Evaluate a field/section visibility condition.
     * Uses MBX logic evaluator (JSON Logic under the hood) with
     * backward compatibility for existing FieldCondition format.
     */
    evaluateCondition: (condition: FieldCondition) => {
      return evaluateFieldCondition(
        condition,
        form.getValues() as Record<string, unknown>,
        tenantContext,
      );
    },

    /**
     * Evaluate a computed field expression (mbx:expr).
     * Returns the computed value or undefined on failure.
     */
    evaluateComputedField: (expression: string) => {
      const result = evaluateComputed(
        expression,
        form.getValues() as Record<string, unknown>,
      );
      return result.success ? result.value : undefined;
    },
  };
}

export type { ResolvedFormDefinition };
