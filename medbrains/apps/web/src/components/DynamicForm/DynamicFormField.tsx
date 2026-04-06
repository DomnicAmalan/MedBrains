import { useCallback, useEffect } from "react";
import {
  Button,
  FileInput,
  Group,
  Input,
  Loader,
  MultiSelect,
  NumberInput,
  Radio,
  Select,
  Switch,
  Text,
  TextInput,
  Textarea,
  Tooltip,
} from "@mantine/core";
import { Controller, type FieldError, type UseFormReturn } from "react-hook-form";
import type { FieldAction, ResolvedField } from "@medbrains/types";
import { evaluateComputed } from "@medbrains/expressions";
import { FieldTooltip } from "./FieldTooltip";
import { SectionIcon } from "./SectionIcon";
import { useFieldDataSource } from "../../hooks/useFieldDataSource";

interface DynamicFormFieldProps {
  field: ResolvedField;
  form: UseFormReturn<Record<string, unknown>>;
}

export function DynamicFormField({ field, form }: DynamicFormFieldProps) {
  const {
    setValue,
    watch,
    control,
    formState: { errors },
  } = form;

  const fieldError = errors[field.field_code] as FieldError | undefined;
  const errorMessage = fieldError?.message;
  const isRequired = field.requirement_level === "mandatory";
  const isViewOnly = field.access_level === "view";
  const value = watch(field.field_code);

  // Computed field support via mbx:expr
  const allValues = watch();
  const computedExpr = field.data_type === "computed"
    ? field.validation?.custom ?? null
    : null;

  useEffect(() => {
    if (!computedExpr) return;
    const result = evaluateComputed(
      computedExpr,
      allValues as Record<string, unknown>,
    );
    if (result.success && result.value !== undefined) {
      const displayValue = typeof result.value === "object" && result.value instanceof Date
        ? result.value.toISOString()
        : String(result.value);
      if (displayValue !== value) {
        setValue(field.field_code, displayValue);
      }
    }
  }, [computedExpr, allValues, field.field_code, setValue, value]);

  // Data source options (API / dependent)
  const { options: dsOptions, isLoading: dsLoading } = useFieldDataSource(
    field,
    allValues as Record<string, unknown>,
  );

  const options = field.validation?.options ?? [];
  const staticSelectData = options.map((opt) => ({
    value: opt,
    label: opt
      .replace(/_/g, " ")
      .replace(/\b\w/g, (c) => c.toUpperCase()),
  }));

  // API-fetched options win over static ones
  const selectData = dsOptions.length > 0 ? dsOptions : staticSelectData;

  // Field actions
  const fieldActions = (field.actions ?? []) as FieldAction[];
  const clickActions = fieldActions.filter((a) => a.trigger === "on_click");

  const executeAction = useCallback(async (action: FieldAction) => {
    if (action.actionType === "api_call" && action.endpoint) {
      // Security: Only allow internal API calls to prevent SSRF/data exfiltration
      if (!action.endpoint.startsWith("/api/")) return;

      const body: Record<string, unknown> = {};
      for (const [key, mapping] of Object.entries(action.bodyMapping ?? {})) {
        body[key] = mapping === "$self"
          ? value
          : (allValues as Record<string, unknown>)[mapping];
      }
      try {
        const resp = await fetch(action.endpoint, {
          method: action.method ?? "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });
        if (resp.ok) {
          const data = await resp.json();
          for (const [targetField, jsonPath] of Object.entries(action.responseMapping ?? {})) {
            const parts = jsonPath.split(".");
            let val: unknown = data;
            for (const part of parts) {
              if (val != null && typeof val === "object") {
                val = (val as Record<string, unknown>)[part];
              }
            }
            if (val !== undefined) {
              setValue(targetField, val);
            }
          }
        }
      } catch {
        // Action errors are silently ignored for now
      }
    } else if (action.actionType === "copy_value" && action.sourceField && action.targetField) {
      const sourceVal = (allValues as Record<string, unknown>)[action.sourceField];
      setValue(action.targetField, sourceVal);
    }
  }, [value, allValues, setValue]);

  // (i) icon shown next to the label — hover/click reveals regulatory & hint info
  const hintIcon = (
    <FieldTooltip
      description={field.description}
      uiHint={field.ui_hint}
      clauses={field.regulatory_clauses}
    />
  );

  /** Label with (i) hint icon */
  const labelWithHint = (
    <Group gap={4} wrap="nowrap">
      <Text size="sm" fw={500}>{field.label}</Text>
      {hintIcon}
    </Group>
  );

  // Field icon (left or right section)
  const fieldIcon = field.icon ? <SectionIcon icon={field.icon} size={16} /> : null;
  const iconPos = field.icon_position ?? "left";
  const leftIcon = fieldIcon && iconPos === "left" ? fieldIcon : undefined;
  const rightIcon = fieldIcon && iconPos === "right" ? fieldIcon : undefined;

  // rightSection: loading spinner takes priority, then icon
  const rightSection = dsLoading ? <Loader size={14} /> : rightIcon;

  /** Wraps a field element with on_click action buttons if any exist */
  const wrapWithActions = (element: React.ReactNode) => {
    if (clickActions.length === 0) return element;
    return (
      <Group gap="xs" align="flex-end" wrap="nowrap" style={{ width: "100%" }}>
        <div style={{ flex: 1 }}>{element}</div>
        {clickActions.map((action) => (
          <Tooltip key={action.id} label={action.label}>
            <Button
              size="xs"
              variant="light"
              onClick={() => { void executeAction(action); }}
              mt={22}
            >
              {action.label}
            </Button>
          </Tooltip>
        ))}
      </Group>
    );
  };

  switch (field.data_type) {
    case "text":
    case "phone":
    case "hidden":
      return wrapWithActions(
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <TextInput
              label={labelWithHint}
              placeholder={field.placeholder ?? undefined}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              rightSection={rightSection}
              type={field.data_type === "hidden" ? "hidden" : "text"}
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
              name={f.name}
              ref={f.ref}
              value={typeof f.value === "string" ? f.value : ""}
              onChange={f.onChange}
              onBlur={f.onBlur}
            />
          )}
        />
      );

    case "computed":
      return (
        <TextInput
          label={field.label}
          placeholder={field.placeholder ?? "Computed"}
          required={false}
          error={errorMessage}
          rightSection={rightSection}
          readOnly
          variant="filled"
          value={typeof value === "string" ? value : (value != null ? String(value) : "")}
        />
      );

    case "email":
      return wrapWithActions(
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <TextInput
              label={labelWithHint}
              placeholder={field.placeholder ?? "email@example.com"}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              rightSection={rightSection}
              type="email"
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
              name={f.name}
              ref={f.ref}
              value={typeof f.value === "string" ? f.value : ""}
              onChange={f.onChange}
              onBlur={f.onBlur}
            />
          )}
        />,
      );

    case "textarea":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Textarea
              label={labelWithHint}
              placeholder={field.placeholder ?? undefined}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              rows={3}
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
              name={f.name}
              ref={f.ref}
              value={typeof f.value === "string" ? f.value : ""}
              onChange={f.onChange}
              onBlur={f.onBlur}
            />
          )}
        />
      );

    case "number":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <NumberInput
              label={labelWithHint}
              placeholder={field.placeholder ?? undefined}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              rightSection={rightSection}
              value={typeof f.value === "number" ? f.value : undefined}
              onChange={f.onChange}
              onBlur={f.onBlur}
              ref={f.ref}
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
            />
          )}
        />
      );

    case "decimal":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <NumberInput
              label={labelWithHint}
              placeholder={field.placeholder ?? undefined}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              rightSection={rightSection}
              decimalScale={2}
              value={typeof f.value === "number" ? f.value : undefined}
              onChange={f.onChange}
              onBlur={f.onBlur}
              ref={f.ref}
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
            />
          )}
        />
      );

    case "date":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Input.Wrapper
              label={labelWithHint}
              required={isRequired && !isViewOnly}
              error={errorMessage}
            >
              <Input
                type="date"
                readOnly={isViewOnly}
                variant={isViewOnly ? "filled" : undefined}
                name={f.name}
                ref={f.ref}
                value={typeof f.value === "string" ? f.value : ""}
                onChange={f.onChange}
                onBlur={f.onBlur}
              />
            </Input.Wrapper>
          )}
        />
      );

    case "datetime":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Input.Wrapper
              label={labelWithHint}
              required={isRequired && !isViewOnly}
              error={errorMessage}
            >
              <Input
                type="datetime-local"
                readOnly={isViewOnly}
                variant={isViewOnly ? "filled" : undefined}
                name={f.name}
                ref={f.ref}
                value={typeof f.value === "string" ? f.value : ""}
                onChange={f.onChange}
                onBlur={f.onBlur}
              />
            </Input.Wrapper>
          )}
        />
      );

    case "time":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Input.Wrapper
              label={labelWithHint}
              required={isRequired && !isViewOnly}
              error={errorMessage}
            >
              <Input
                type="time"
                readOnly={isViewOnly}
                variant={isViewOnly ? "filled" : undefined}
                name={f.name}
                ref={f.ref}
                value={typeof f.value === "string" ? f.value : ""}
                onChange={f.onChange}
                onBlur={f.onBlur}
              />
            </Input.Wrapper>
          )}
        />
      );

    case "select":
      return wrapWithActions(
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Select
              label={labelWithHint}
              placeholder={field.placeholder ?? "Select..."}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              rightSection={rightSection}
              data={selectData}
              value={typeof f.value === "string" ? f.value : null}
              onChange={(val) => f.onChange(val ?? "")}
              onBlur={f.onBlur}
              searchable={selectData.length > 5}
              clearable={!isRequired}
              disabled={isViewOnly || dsLoading}
              variant={isViewOnly ? "filled" : undefined}
            />
          )}
        />,
      );

    case "multiselect":
      return wrapWithActions(
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <MultiSelect
              label={labelWithHint}
              placeholder={field.placeholder ?? "Select..."}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              data={selectData}
              value={Array.isArray(f.value) ? (f.value as string[]) : []}
              onChange={f.onChange}
              onBlur={f.onBlur}
              searchable
              clearable
              disabled={isViewOnly || dsLoading}
              variant={isViewOnly ? "filled" : undefined}
            />
          )}
        />,
      );

    case "radio":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Radio.Group
              label={labelWithHint}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              value={typeof f.value === "string" ? f.value : undefined}
              onChange={(val) => { if (!isViewOnly) f.onChange(val); }}
            >
              <Group mt="xs">
                {selectData.map((opt) => (
                  <Radio
                    key={opt.value}
                    value={opt.value}
                    label={opt.label}
                    disabled={isViewOnly}
                  />
                ))}
              </Group>
            </Radio.Group>
          )}
        />
      );

    case "boolean":
    case "checkbox":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Switch
              label={labelWithHint}
              checked={Boolean(f.value)}
              onChange={(e) => {
                if (!isViewOnly) f.onChange(e.currentTarget.checked);
              }}
              error={errorMessage}
              disabled={isViewOnly}
            />
          )}
        />
      );

    case "file":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <FileInput
              label={labelWithHint}
              placeholder={field.placeholder ?? "Upload file..."}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              accept="image/*,.pdf"
              value={f.value as File | null}
              onChange={f.onChange}
              disabled={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
            />
          )}
        />
      );

    case "uuid_fk":
      return wrapWithActions(
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <TextInput
              label={labelWithHint}
              placeholder={field.placeholder ?? undefined}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              rightSection={rightSection}
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
              name={f.name}
              ref={f.ref}
              value={typeof f.value === "string" ? f.value : ""}
              onChange={f.onChange}
              onBlur={f.onBlur}
            />
          )}
        />,
      );

    case "json":
      return (
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <Textarea
              label={labelWithHint}
              placeholder={field.placeholder ?? "{}"}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              rows={4}
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
              name={f.name}
              ref={f.ref}
              value={typeof f.value === "string" ? f.value : ""}
              onChange={f.onChange}
              onBlur={f.onBlur}
            />
          )}
        />
      );

    default:
      return wrapWithActions(
        <Controller
          name={field.field_code}
          control={control}
          render={({ field: f }) => (
            <TextInput
              label={labelWithHint}
              placeholder={field.placeholder ?? undefined}
              required={isRequired && !isViewOnly}
              error={errorMessage}
              leftSection={leftIcon}
              rightSection={rightSection}
              readOnly={isViewOnly}
              variant={isViewOnly ? "filled" : undefined}
              name={f.name}
              ref={f.ref}
              value={typeof f.value === "string" ? f.value : ""}
              onChange={f.onChange}
              onBlur={f.onBlur}
            />
          )}
        />,
      );
  }
}
