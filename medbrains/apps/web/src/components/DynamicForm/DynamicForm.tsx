import {
  Accordion,
  Alert,
  Button,
  LoadingOverlay,
  Stack,
} from "@mantine/core";
import type { CSSProperties } from "react";
import { IconAlertCircle, IconForms } from "@tabler/icons-react";
import { useDynamicForm } from "./useDynamicForm";
import { DynamicFormSection } from "./DynamicFormSection";
import { SectionIcon } from "./SectionIcon";
import classes from "./dynamic-form.module.scss";

export interface DynamicFormProps {
  /** The form code to load (e.g., "patient_registration") */
  formCode: string;
  /** Optional module code for context */
  moduleCode?: string;
  /** Show only quick-mode fields */
  quickMode?: boolean;
  /** Called when form is submitted with valid data */
  onSubmit: (data: Record<string, unknown>) => void | Promise<void>;
  /** Pre-populated values */
  defaultValues?: Record<string, unknown>;
  /** Tenant context for condition evaluation (e.g., country_code, regulatory_bodies) */
  tenantContext?: Record<string, unknown>;
  /** Escape hatch: override specific field renderers by field_code */
  renderOverrides?: Record<string, React.ReactNode>;
  /** Custom submit button label (overrides form config) */
  submitLabel?: string;
  /** Show cancel button */
  onCancel?: () => void;
  /** Loading state for external submit */
  isSubmitting?: boolean;
  /** Hide the form header */
  hideHeader?: boolean;
}

/** Build CSS custom properties for section icon color theming */
function sectionColorVars(color: string | null): CSSProperties {
  if (!color) return {};
  return {
    "--section-icon-bg": `var(--mantine-color-${color}-1)`,
    "--section-icon-color": `var(--mantine-color-${color}-6)`,
    "--section-icon-bg-dark": `var(--mantine-color-${color}-9)`,
    "--section-icon-color-dark": `var(--mantine-color-${color}-4)`,
  } as CSSProperties;
}

export function DynamicForm({
  formCode,
  quickMode = false,
  onSubmit,
  defaultValues,
  tenantContext,
  renderOverrides,
  submitLabel,
  onCancel,
  isSubmitting = false,
  hideHeader = false,
}: DynamicFormProps) {
  const { definition, form, isLoading, isError, error } = useDynamicForm({
    formCode,
    quickMode,
    defaultValues,
    tenantContext,
  });

  if (isLoading) {
    return <LoadingOverlay visible />;
  }

  if (isError || !definition) {
    return (
      <Alert icon={<IconAlertCircle size={16} />} title="Error" color="danger">
        {error instanceof Error
          ? error.message
          : "Failed to load form definition"}
      </Alert>
    );
  }

  const handleSubmit = form.handleSubmit(async (data) => {
    await onSubmit(data as Record<string, unknown>);
  });

  // Separate collapsible and non-collapsible sections
  const nonCollapsible = definition.sections.filter((s) => !s.is_collapsible);
  const collapsible = definition.sections.filter((s) => s.is_collapsible);

  // Default open sections
  const defaultOpenSections = collapsible
    .filter((s) => s.is_default_open)
    .map((s) => s.code);

  const formConfig = definition.config as Record<string, unknown> | null;
  const buttonLabel =
    submitLabel ??
    (formConfig?.submit_label as string | undefined) ??
    "Submit";
  const isCompact = (formConfig?.compact as boolean) ?? false;

  const totalFields = definition.sections.reduce(
    (sum, s) => sum + s.fields.length,
    0,
  );

  return (
    <form onSubmit={handleSubmit}>
      <Stack gap={isCompact ? "xs" : "md"}>
        {/* Form Header */}
        {!hideHeader && (
          <div className={classes.formHeader}>
            <div className={classes.formHeaderIcon}>
              <IconForms size={20} />
            </div>
            <div className={classes.formHeaderContent}>
              <div className={classes.formHeaderTitle}>
                {definition.form_name}
              </div>
              <div className={classes.formHeaderDescription}>
                {definition.sections.length} section{definition.sections.length !== 1 ? "s" : ""}
                {" \u00B7 "}
                {totalFields} field{totalFields !== 1 ? "s" : ""}
                {quickMode ? " \u00B7 Quick mode" : ""}
              </div>
            </div>
          </div>
        )}

        {/* Non-collapsible sections rendered flat */}
        {nonCollapsible.map((section) => (
          <DynamicFormSection
            key={section.code}
            section={section}
            form={form as unknown as import("react-hook-form").UseFormReturn<Record<string, unknown>>}
            tenantContext={tenantContext}
            renderOverrides={renderOverrides}
          />
        ))}

        {/* Collapsible sections in an Accordion */}
        {collapsible.length > 0 && (
          <Accordion
            multiple
            defaultValue={defaultOpenSections}
            variant="separated"
            classNames={{
              item: classes.accordionItem,
              control: classes.accordionControl,
              panel: classes.accordionPanel,
            }}
          >
            {collapsible.map((section) => (
              <Accordion.Item key={section.code} value={section.code}>
                <Accordion.Control>
                  <div className={classes.accordionLabel}>
                    <div className={classes.sectionIcon} style={sectionColorVars(section.color)}>
                      <SectionIcon icon={section.icon} size={14} />
                    </div>
                    {section.name}
                    <span className={classes.sectionFieldCount}>
                      {section.fields.length} field{section.fields.length !== 1 ? "s" : ""}
                    </span>
                  </div>
                </Accordion.Control>
                <Accordion.Panel>
                  <DynamicFormSection
                    section={section}
                    form={form as unknown as import("react-hook-form").UseFormReturn<Record<string, unknown>>}
                    tenantContext={tenantContext}
                    renderOverrides={renderOverrides}
                    flat
                  />
                </Accordion.Panel>
              </Accordion.Item>
            ))}
          </Accordion>
        )}

        {/* Actions */}
        <div className={classes.formActions}>
          {onCancel && (
            <Button variant="subtle" onClick={onCancel}>
              Cancel
            </Button>
          )}
          <Button type="submit" loading={isSubmitting}>
            {buttonLabel}
          </Button>
        </div>
      </Stack>
    </form>
  );
}
