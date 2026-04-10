import { Anchor, Badge, Divider, Group, NumberInput, Select, Stack, Switch, Text, TextInput, Textarea } from "@mantine/core";
import type { SidecarNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import type { SidecarTrigger } from "@medbrains/types";
import { api } from "@medbrains/api";
import { useQuery } from "@tanstack/react-query";
import { PipelineLinker } from "./PipelineLinker";
import { ScreenConditionBuilder } from "./ConditionBuilder";

const SIDECAR_TRIGGER_OPTIONS: Array<{ value: SidecarTrigger; label: string }> = [
  { value: "screen_load", label: "Screen Load" },
  { value: "screen_exit", label: "Screen Exit" },
  { value: "form_submit", label: "Form Submit" },
  { value: "form_validate", label: "Form Validate" },
  { value: "form_save_draft", label: "Draft Save" },
  { value: "field_change", label: "Field Change" },
  { value: "row_select", label: "Row Select" },
  { value: "row_action", label: "Row Action" },
  { value: "interval", label: "Interval" },
  { value: "step_enter", label: "Step Enter" },
  { value: "step_leave", label: "Step Leave" },
];

const INLINE_ACTION_TYPES = [
  { value: "api_call", label: "API Call" },
  { value: "navigate", label: "Navigate" },
  { value: "notification", label: "Notification" },
  { value: "refresh_zone", label: "Refresh Zone" },
  { value: "set_field", label: "Set Field Value" },
  { value: "open_modal", label: "Open Modal" },
];

function TriggerSpecificConfig({ sidecar }: { sidecar: SidecarNode }) {
  const updateSidecar = useScreenBuilderStore((s) => s.updateSidecar);
  const config = sidecar.trigger_config;

  switch (sidecar.trigger_event) {
    case "field_change":
      return (
        <TextInput
          label="Field code"
          placeholder="e.g., status, category_id"
          value={(config.field_code as string) ?? ""}
          onChange={(e) =>
            updateSidecar(sidecar.clientId, {
              trigger_config: { ...config, field_code: e.currentTarget.value },
            })
          }
        />
      );

    case "interval":
      return (
        <>
          <NumberInput
            label="Interval (seconds)"
            value={(config.seconds as number) ?? 30}
            onChange={(v) =>
              updateSidecar(sidecar.clientId, {
                trigger_config: { ...config, seconds: typeof v === "number" ? v : 30 },
              })
            }
            min={5}
            max={3600}
          />
          <NumberInput
            label="Max retries"
            value={(config.max_retries as number) ?? 0}
            onChange={(v) =>
              updateSidecar(sidecar.clientId, {
                trigger_config: { ...config, max_retries: typeof v === "number" ? v : 0 },
              })
            }
            min={0}
          />
        </>
      );

    case "form_submit":
      return (
        <>
          <TextInput
            label="Success redirect"
            placeholder="/patients/:id"
            value={(config.success_redirect as string) ?? ""}
            onChange={(e) =>
              updateSidecar(sidecar.clientId, {
                trigger_config: { ...config, success_redirect: e.currentTarget.value },
              })
            }
          />
          <Select
            label="Error action"
            data={[
              { value: "show_toast", label: "Show toast" },
              { value: "show_inline", label: "Show inline errors" },
              { value: "retry", label: "Retry" },
            ]}
            value={(config.error_action as string) ?? "show_toast"}
            onChange={(v) =>
              updateSidecar(sidecar.clientId, {
                trigger_config: { ...config, error_action: v ?? "show_toast" },
              })
            }
          />
        </>
      );

    case "screen_load":
      return (
        <>
          <NumberInput
            label="Delay (ms)"
            value={(config.delay_ms as number) ?? 0}
            onChange={(v) =>
              updateSidecar(sidecar.clientId, {
                trigger_config: { ...config, delay_ms: typeof v === "number" ? v : 0 },
              })
            }
            min={0}
          />
          <Switch
            label="Run once"
            checked={(config.run_once as boolean) ?? false}
            onChange={(e) =>
              updateSidecar(sidecar.clientId, {
                trigger_config: { ...config, run_once: e.currentTarget.checked },
              })
            }
          />
        </>
      );

    default:
      return null;
  }
}

function InlineActionConfig({ sidecar }: { sidecar: SidecarNode }) {
  const updateSidecar = useScreenBuilderStore((s) => s.updateSidecar);
  const inlineAction = sidecar.inline_action ?? {};
  const actionType = (inlineAction.type as string) ?? "";

  const updateInlineAction = (updates: Record<string, unknown>) => {
    updateSidecar(sidecar.clientId, {
      inline_action: { ...inlineAction, ...updates },
    });
  };

  return (
    <Stack gap="sm">
      <Select
        label="Inline action type"
        placeholder="Select action..."
        data={INLINE_ACTION_TYPES}
        value={actionType || null}
        onChange={(v) => updateInlineAction({ type: v ?? "" })}
        clearable
      />

      {actionType === "api_call" && (
        <>
          <TextInput
            label="Endpoint"
            placeholder="/api/v1/..."
            value={(inlineAction.endpoint as string) ?? ""}
            onChange={(e) => updateInlineAction({ endpoint: e.currentTarget.value })}
          />
          <Select
            label="Method"
            data={["GET", "POST", "PUT", "PATCH", "DELETE"].map((m) => ({ value: m, label: m }))}
            value={(inlineAction.method as string) ?? "POST"}
            onChange={(v) => updateInlineAction({ method: v ?? "POST" })}
          />
        </>
      )}

      {actionType === "navigate" && (
        <TextInput
          label="Route"
          placeholder="/patients/:id"
          value={(inlineAction.route as string) ?? ""}
          onChange={(e) => updateInlineAction({ route: e.currentTarget.value })}
        />
      )}

      {actionType === "notification" && (
        <>
          <TextInput
            label="Title"
            value={(inlineAction.title as string) ?? ""}
            onChange={(e) => updateInlineAction({ title: e.currentTarget.value })}
          />
          <TextInput
            label="Message"
            value={(inlineAction.message as string) ?? ""}
            onChange={(e) => updateInlineAction({ message: e.currentTarget.value })}
          />
          <Select
            label="Type"
            data={[
              { value: "success", label: "Success" },
              { value: "error", label: "Error" },
              { value: "info", label: "Info" },
              { value: "warning", label: "Warning" },
            ]}
            value={(inlineAction.notification_type as string) ?? "success"}
            onChange={(v) => updateInlineAction({ notification_type: v ?? "success" })}
          />
        </>
      )}

      {actionType === "refresh_zone" && (
        <TextInput
          label="Zone key"
          placeholder="data_table_1"
          value={(inlineAction.zone_key as string) ?? ""}
          onChange={(e) => updateInlineAction({ zone_key: e.currentTarget.value })}
        />
      )}
    </Stack>
  );
}

const STATUS_COLORS: Record<string, string> = {
  active: "teal",
  draft: "slate",
  paused: "warning",
  archived: "danger",
};

function PipelinePreview({ pipelineId }: { pipelineId: string }) {
  const { data: pipeline } = useQuery({
    queryKey: ["pipeline-preview", pipelineId],
    queryFn: () => api.getPipeline(pipelineId),
    staleTime: 60_000,
  });

  if (!pipeline) return null;

  return (
    <Group gap="xs" mt={4}>
      <Text size="xs" fw={500} style={{ flex: 1 }} lineClamp={1}>
        {pipeline.name}
      </Text>
      <Badge size="xs" color={STATUS_COLORS[pipeline.status] ?? "slate"}>
        {pipeline.status}
      </Badge>
      <Anchor
        size="xs"
        href={`/admin/integration-builder/${pipelineId}`}
        target="_blank"
      >
        Open
      </Anchor>
    </Group>
  );
}

export function SidecarConfig({ sidecar }: { sidecar: SidecarNode }) {
  const updateSidecar = useScreenBuilderStore((s) => s.updateSidecar);
  const hasPipeline = Boolean(sidecar.pipeline_id);

  return (
    <Stack gap="sm">
      <TextInput
        label="Name"
        value={sidecar.name}
        onChange={(e) =>
          updateSidecar(sidecar.clientId, { name: e.currentTarget.value })
        }
      />

      <Textarea
        label="Description"
        value={sidecar.description}
        onChange={(e) =>
          updateSidecar(sidecar.clientId, { description: e.currentTarget.value })
        }
        minRows={2}
      />

      <Select
        label="Trigger event"
        data={SIDECAR_TRIGGER_OPTIONS}
        value={sidecar.trigger_event}
        onChange={(v) =>
          updateSidecar(sidecar.clientId, {
            trigger_event: (v ?? "screen_load") as SidecarTrigger,
          })
        }
      />

      <TriggerSpecificConfig sidecar={sidecar} />

      <Divider label="Action" labelPosition="center" />

      <div style={{ fontSize: "var(--mantine-font-size-sm)", fontWeight: 500, marginBottom: 4 }}>
        Pipeline
      </div>
      <PipelineLinker
        pipelineId={sidecar.pipeline_id}
        onChange={(id) =>
          updateSidecar(sidecar.clientId, {
            pipeline_id: id,
            inline_action: id ? null : sidecar.inline_action,
          })
        }
      />
      {hasPipeline && sidecar.pipeline_id && (
        <PipelinePreview pipelineId={sidecar.pipeline_id} />
      )}

      {!hasPipeline && (
        <>
          <Divider label="or Inline Action" labelPosition="center" />
          <InlineActionConfig sidecar={sidecar} />
        </>
      )}

      <Divider label="Condition" labelPosition="center" />

      <ScreenConditionBuilder
        condition={sidecar.condition}
        onChange={(condition) =>
          updateSidecar(sidecar.clientId, { condition })
        }
      />

      <Switch
        label="Active"
        checked={sidecar.is_active}
        onChange={(e) =>
          updateSidecar(sidecar.clientId, { is_active: e.currentTarget.checked })
        }
      />
    </Stack>
  );
}
