import { Grid } from "@mantine/core";
import type { CSSProperties } from "react";
import type { UseFormReturn } from "react-hook-form";
import type { ResolvedField, ResolvedSection } from "@medbrains/types";
import { evaluateFieldCondition } from "@medbrains/expressions";
import { SectionIcon } from "./SectionIcon";
import { DynamicFormField } from "./DynamicFormField";
import classes from "./dynamic-form.module.scss";

interface DynamicFormSectionProps {
  section: ResolvedSection;
  form: UseFormReturn<Record<string, unknown>>;
  tenantContext?: Record<string, unknown>;
  renderOverrides?: Record<string, React.ReactNode>;
  /** When true, renders only the field grid (no section wrapper/header) */
  flat?: boolean;
}

const WIDTH_MAP: Record<string, number> = {
  full: 12,
  half: 6,
  third: 4,
  quarter: 3,
};

function getSpan(width: string | null): number {
  return WIDTH_MAP[width ?? "half"] ?? 6;
}

function isFieldVisible(
  field: ResolvedField,
  formValues: Record<string, unknown>,
  tenantContext?: Record<string, unknown>,
): boolean {
  if (field.is_hidden) return false;
  if (field.access_level === "hidden") return false;
  if (!field.condition) return true;
  return evaluateFieldCondition(field.condition, formValues, tenantContext);
}

const VALID_MANTINE_COLORS = new Set([
  "dark", "gray", "red", "pink", "grape", "violet", "indigo", "blue",
  "cyan", "teal", "green", "lime", "yellow", "orange",
  "primary", "success", "warning", "danger", "info", "slate",
]);

/** Build CSS custom properties for section icon color theming */
function sectionColorVars(color: string | null): CSSProperties {
  if (!color || !VALID_MANTINE_COLORS.has(color)) return {};
  return {
    "--section-icon-bg": `var(--mantine-color-${color}-1)`,
    "--section-icon-color": `var(--mantine-color-${color}-6)`,
    "--section-icon-bg-dark": `var(--mantine-color-${color}-9)`,
    "--section-icon-color-dark": `var(--mantine-color-${color}-4)`,
  } as CSSProperties;
}

export function DynamicFormSection({
  section,
  form,
  tenantContext,
  renderOverrides,
  flat = false,
}: DynamicFormSectionProps) {
  const formValues = form.watch();

  const visibleFields = section.fields.filter((f) =>
    isFieldVisible(f, formValues as Record<string, unknown>, tenantContext),
  );

  if (visibleFields.length === 0) return null;

  const fieldGrid = (
    <Grid gap="md">
      {visibleFields.map((field) => {
        const override = renderOverrides?.[field.field_code];
        if (override) {
          return (
            <Grid.Col key={field.field_code} span={getSpan(field.ui_width)} className={classes.fieldCol}>
              {override}
            </Grid.Col>
          );
        }

        return (
          <Grid.Col key={field.field_code} span={getSpan(field.ui_width)} className={classes.fieldCol}>
            <DynamicFormField field={field} form={form} />
          </Grid.Col>
        );
      })}
    </Grid>
  );

  // Flat mode — used inside Accordion panels (header provided by Accordion.Control)
  if (flat) {
    return fieldGrid;
  }

  // Non-collapsible section — wrapped with header and border
  return (
    <div className={classes.section}>
      <div className={classes.sectionHeader}>
        <div className={classes.sectionIcon} style={sectionColorVars(section.color)}>
          <SectionIcon icon={section.icon} size={14} />
        </div>
        <div className={classes.sectionTitle}>{section.name}</div>
        <div className={classes.sectionFieldCount}>
          {visibleFields.length} field{visibleFields.length !== 1 ? "s" : ""}
        </div>
      </div>
      <div className={classes.sectionBody}>
        {fieldGrid}
      </div>
    </div>
  );
}
