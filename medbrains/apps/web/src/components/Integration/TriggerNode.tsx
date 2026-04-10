import { Badge, Box, Card, Group, Text, ThemeIcon } from "@mantine/core";
import { IconBolt, IconCircleFilled } from "@tabler/icons-react";
import { Handle, Position, type NodeProps } from "@xyflow/react";

interface TriggerNodeData {
  label?: string;
  icon?: string;
  color?: string;
  templateCode?: string;
  config?: Record<string, unknown>;
  [key: string]: unknown;
}

function getConfigSummary(code: string | undefined, config: Record<string, unknown>): string | null {
  if (!code) return null;
  if (code === "trigger.internal_event" && config.event_type) return String(config.event_type);
  if (code === "trigger.schedule" && config.cron) return `cron: ${String(config.cron)}`;
  if (code === "trigger.webhook" && config.path) return `/${String(config.path)}`;
  return null;
}

function isConfigured(config: Record<string, unknown>): boolean {
  return Object.values(config).some((v) => v !== null && v !== undefined && v !== "");
}

export function TriggerNode({ data, selected }: NodeProps) {
  const d = data as TriggerNodeData;
  const color = d.color ?? "primary";
  const config = (d.config ?? {}) as Record<string, unknown>;
  const summary = getConfigSummary(d.templateCode as string | undefined, config);
  const configured = isConfigured(config);

  return (
    <>
      <Card
        shadow={selected ? "lg" : "sm"}
        padding="sm"
        radius="xl"
        withBorder
        style={{
          borderColor: selected ? `var(--mantine-color-${color}-5)` : `var(--mantine-color-${color}-2)`,
          borderWidth: selected ? 2 : 1,
          minWidth: 200,
          background: `var(--mantine-color-${color}-0)`,
        }}
      >
        <Group gap="sm" wrap="nowrap">
          <ThemeIcon variant="filled" color={color} size="lg" radius="xl">
            <IconBolt size={18} />
          </ThemeIcon>
          <Box style={{ flex: 1, minWidth: 0 }}>
            <Group gap={6} wrap="nowrap">
              <Text size="sm" fw={600} truncate style={{ flex: 1 }}>
                {String(d.label ?? "Trigger")}
              </Text>
              <IconCircleFilled
                size={8}
                color={configured ? "var(--mantine-color-green-5)" : "var(--mantine-color-gray-4)"}
              />
            </Group>
            {summary && (
              <Badge size="xs" variant="light" color={color} mt={4}>
                {summary}
              </Badge>
            )}
            {!summary && d.templateCode && (
              <Text size="xs" c="dimmed" truncate>
                {String(d.templateCode).replace("trigger.", "")}
              </Text>
            )}
          </Box>
        </Group>
      </Card>
      <Handle
        type="source"
        position={Position.Bottom}
        style={{
          width: 10,
          height: 10,
          background: `var(--mantine-color-${color}-5)`,
          border: "2px solid white",
        }}
      />
    </>
  );
}
