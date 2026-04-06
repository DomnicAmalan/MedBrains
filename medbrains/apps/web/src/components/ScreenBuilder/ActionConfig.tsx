import { Select, Stack, Switch, TextInput } from "@mantine/core";
import type { ActionNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { IconPicker } from "./IconPicker";

export function ActionConfig({ action }: { action: ActionNode }) {
  const updateAction = useScreenBuilderStore((s) => s.updateAction);

  return (
    <Stack gap="sm">
      <TextInput
        label="Key"
        placeholder="action_key"
        value={action.key}
        onChange={(e) =>
          updateAction(action.clientId, { key: e.currentTarget.value })
        }
      />

      <TextInput
        label="Label"
        placeholder="Button label"
        value={action.label}
        onChange={(e) =>
          updateAction(action.clientId, { label: e.currentTarget.value })
        }
      />

      <IconPicker
        label="Icon"
        value={action.icon}
        onChange={(icon) => updateAction(action.clientId, { icon })}
      />

      <Select
        label="Variant"
        data={[
          { value: "filled", label: "Filled" },
          { value: "light", label: "Light" },
          { value: "outline", label: "Outline" },
          { value: "subtle", label: "Subtle" },
          { value: "default", label: "Default" },
        ]}
        value={action.variant}
        onChange={(v) =>
          updateAction(action.clientId, { variant: v ?? "filled" })
        }
      />

      <Select
        label="Action type"
        data={[
          { value: "save", label: "Save" },
          { value: "delete", label: "Delete" },
          { value: "print", label: "Print" },
          { value: "navigate", label: "Navigate" },
          { value: "custom", label: "Custom" },
          { value: "api_call", label: "API Call" },
          { value: "refresh", label: "Refresh" },
        ]}
        value={action.action_type}
        onChange={(v) =>
          updateAction(action.clientId, { action_type: v ?? "custom" })
        }
      />

      <TextInput
        label="Permission code"
        placeholder="module.action"
        value={action.permission}
        onChange={(e) =>
          updateAction(action.clientId, { permission: e.currentTarget.value })
        }
      />

      {action.action_type === "navigate" && (
        <TextInput
          label="Route"
          placeholder="/patients/:id"
          value={action.route}
          onChange={(e) =>
            updateAction(action.clientId, { route: e.currentTarget.value })
          }
        />
      )}

      <Switch
        label="Require confirmation"
        checked={action.confirm}
        onChange={(e) =>
          updateAction(action.clientId, { confirm: e.currentTarget.checked })
        }
      />
    </Stack>
  );
}
