import {
  Badge,
  Box,
  Drawer,
  Group,
  Stack,
  Text,
  Timeline,
} from "@mantine/core";
import { IconClock, IconPencil, IconPlus } from "@tabler/icons-react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@medbrains/api";

function timeAgo(dateStr: string): string {
  const now = Date.now();
  const d = new Date(dateStr).getTime();
  const diff = now - d;
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(dateStr).toLocaleDateString();
}

function formatValue(val: unknown): string {
  if (val === null || val === undefined) return "-";
  if (typeof val === "object") return JSON.stringify(val);
  return String(val);
}

interface Props {
  fieldId: string | null;
  fieldName: string;
  opened: boolean;
  onClose: () => void;
}

export function FieldAuditLog({ fieldId, fieldName, opened, onClose }: Props) {
  const { data: entries, isLoading } = useQuery({
    queryKey: ["field-audit", fieldId],
    queryFn: () => api.adminGetFieldAuditLog(fieldId!),
    enabled: opened && !!fieldId,
  });

  return (
    <Drawer
      opened={opened}
      onClose={onClose}
      title={`Audit Log: ${fieldName}`}
      position="right"
      size="md"
      padding="md"
    >
      {isLoading && <Text c="dimmed">Loading...</Text>}

      {entries && entries.length === 0 && (
        <Text c="dimmed" size="sm">
          No audit entries for this field.
        </Text>
      )}

      {entries && entries.length > 0 && (
        <Timeline active={entries.length - 1} bulletSize={24} lineWidth={2}>
          {entries.map((entry) => (
            <Timeline.Item
              key={entry.id}
              bullet={
                entry.action === "created" ? (
                  <IconPlus size={14} />
                ) : (
                  <IconPencil size={14} />
                )
              }
              title={
                <Group gap="xs">
                  <Badge
                    size="sm"
                    variant="light"
                    color={entry.action === "created" ? "success" : "primary"}
                  >
                    {entry.action}
                  </Badge>
                  {entry.changed_fields &&
                    entry.changed_fields.map((cf) => (
                      <Badge key={cf} size="xs" variant="outline">
                        {cf}
                      </Badge>
                    ))}
                </Group>
              }
            >
              <Stack gap={4} mt={4}>
                <Text size="xs" c="dimmed">
                  <IconClock
                    size={12}
                    style={{ verticalAlign: "middle", marginRight: 4 }}
                  />
                  {entry.changed_by_name ?? "System"} &middot;{" "}
                  {timeAgo(entry.changed_at)}
                </Text>

                {entry.action === "updated" &&
                  entry.changed_fields &&
                  entry.changed_fields.map((field) => {
                    const oldVal =
                      entry.previous_state?.[field];
                    const newVal =
                      entry.new_state[field];
                    return (
                      <Box
                        key={field}
                        p="xs"
                        style={{
                          background:
                            "var(--mantine-color-gray-0)",
                          borderRadius:
                            "var(--mantine-radius-xs)",
                        }}
                      >
                        <Text size="xs" fw={500}>
                          {field}
                        </Text>
                        <Group gap="xs">
                          <Text
                            size="xs"
                            c="danger"
                            td="line-through"
                          >
                            {formatValue(oldVal)}
                          </Text>
                          <Text size="xs" c="success">
                            {formatValue(newVal)}
                          </Text>
                        </Group>
                      </Box>
                    );
                  })}
              </Stack>
            </Timeline.Item>
          ))}
        </Timeline>
      )}
    </Drawer>
  );
}
