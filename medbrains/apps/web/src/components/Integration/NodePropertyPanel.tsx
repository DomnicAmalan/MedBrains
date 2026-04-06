import {
  Badge,
  Box,
  Button,
  Divider,
  Group,
  NumberInput,
  Select,
  Stack,
  Switch,
  Text,
  Textarea,
  TextInput,
  ThemeIcon,
} from "@mantine/core";
import {
  IconBolt,
  IconGitBranch,
  IconLink,
  IconPlayerPlay,
  IconSettings,
  IconTrash,
  IconTransform,
} from "@tabler/icons-react";
import { useIntegrationBuilderStore } from "@medbrains/stores";
import { api } from "@medbrains/api";
import { useQuery } from "@tanstack/react-query";
import type { FormMaster } from "@medbrains/types";
import { useMemo } from "react";
import { FieldMappingEditor } from "./FieldMappingEditor";

const NODE_TYPE_ICONS: Record<string, typeof IconBolt> = {
  trigger: IconBolt,
  condition: IconGitBranch,
  action: IconPlayerPlay,
  transform: IconTransform,
};

const NODE_TYPE_LABELS: Record<string, string> = {
  trigger: "Trigger",
  condition: "Condition",
  action: "Action",
  transform: "Transform",
  delay: "Delay",
};

interface SchemaProperty {
  type?: string;
  enum?: string[];
  title?: string;
  description?: string;
  default?: unknown;
}

export function NodePropertyPanel() {
  const selectedNodeId = useIntegrationBuilderStore((s) => s.selectedNodeId);
  const nodes = useIntegrationBuilderStore((s) => s.nodes);
  const updateNodeData = useIntegrationBuilderStore((s) => s.updateNodeData);
  const removeNode = useIntegrationBuilderStore((s) => s.removeNode);

  const selectedNode = useMemo(
    () => nodes.find((n) => n.id === selectedNodeId),
    [nodes, selectedNodeId],
  );

  // Fetch all templates to get config_schema for selected node's template
  const { data: templates } = useQuery({
    queryKey: ["integration", "node-templates"],
    queryFn: () => api.listNodeTemplates(),
  });

  // Find the matching template for the selected node
  const matchingTemplate = useMemo(() => {
    if (!selectedNode || !templates) return null;
    const code = selectedNode.data.templateCode as string | undefined;
    if (!code) return null;
    return templates.find((t) => t.code === code) ?? null;
  }, [selectedNode, templates]);

  // Is this a trigger.internal_event node?
  const isTriggerEvent = useMemo(() => {
    if (!selectedNode) return false;
    return (
      (selectedNode.type ?? "") === "trigger" &&
      (selectedNode.data.templateCode as string) === "trigger.internal_event"
    );
  }, [selectedNode]);

  // Fetch forms list for the "Link Form" selector on trigger nodes
  const { data: formsList } = useQuery({
    queryKey: ["forms", "list"],
    queryFn: () => api.listForms(),
    enabled: isTriggerEvent,
  });

  const formSelectData = useMemo(() => {
    if (!formsList) return [];
    return (formsList as FormMaster[]).map((f) => ({
      value: f.code,
      label: `${f.name} (${f.code})`,
    }));
  }, [formsList]);

  if (!selectedNode) {
    return (
      <Box p="md">
        <Group gap="xs" mb="md">
          <ThemeIcon variant="light" color="gray" size="sm">
            <IconSettings size={14} />
          </ThemeIcon>
          <Text size="xs" fw={700} tt="uppercase" c="dimmed">
            Properties
          </Text>
        </Group>
        <Box
          style={{
            padding: 24,
            textAlign: "center",
            borderRadius: 8,
            border: "2px dashed var(--mantine-color-gray-3)",
          }}
        >
          <Text size="sm" c="dimmed" mb={4}>
            No node selected
          </Text>
          <Text size="xs" c="dimmed">
            Click a node on the canvas or drag one from the palette to get started.
          </Text>
        </Box>
      </Box>
    );
  }

  const config = (selectedNode.data.config ?? {}) as Record<string, unknown>;
  const nodeType = selectedNode.type ?? "";
  const Icon = NODE_TYPE_ICONS[nodeType] ?? IconPlayerPlay;
  const templateCode = selectedNode.data.templateCode as string | undefined;
  const isMapDataNode = nodeType === "transform" && templateCode === "transform.map_data";

  // Get config_schema from either node data or matching template
  const configSchema = (matchingTemplate?.config_schema ?? selectedNode.data.configSchema ?? {}) as Record<string, unknown>;
  const properties = (configSchema.properties ?? {}) as Record<string, SchemaProperty>;

  const handleConfigChange = (key: string, value: unknown) => {
    updateNodeData(selectedNode.id, {
      config: { ...config, [key]: value },
    });
  };

  const handleLabelChange = (label: string) => {
    updateNodeData(selectedNode.id, { label });
  };

  return (
    <Box p="md">
      <Group gap="xs" mb="md">
        <ThemeIcon variant="light" color="gray" size="sm">
          <IconSettings size={14} />
        </ThemeIcon>
        <Text size="xs" fw={700} tt="uppercase" c="dimmed">
          Properties
        </Text>
      </Group>

      {/* Node type header */}
      <Box
        mb="md"
        p="sm"
        style={{
          borderRadius: 8,
          background: "var(--mantine-color-gray-0)",
          border: "1px solid var(--mantine-color-gray-2)",
        }}
      >
        <Group gap="sm" mb={6}>
          <ThemeIcon
            variant="light"
            color={String(selectedNode.data.color ?? "gray")}
            size="md"
            radius="md"
          >
            <Icon size={16} />
          </ThemeIcon>
          <Box>
            <Text size="sm" fw={600}>
              {NODE_TYPE_LABELS[nodeType] ?? nodeType}
            </Text>
            {Boolean(selectedNode.data.templateCode) && (
              <Badge size="xs" variant="outline" color="gray">
                {String(selectedNode.data.templateCode)}
              </Badge>
            )}
          </Box>
        </Group>
      </Box>

      <Stack gap="sm">
        {/* Label */}
        <TextInput
          label="Display Name"
          size="xs"
          value={String(selectedNode.data.label ?? "")}
          onChange={(e) => handleLabelChange(e.currentTarget.value)}
          styles={{ label: { fontWeight: 600, fontSize: 11, textTransform: "uppercase", color: "var(--mantine-color-dimmed)" } }}
        />

        {/* Rich field mapper for Map Data transform nodes */}
        {isMapDataNode && (
          <>
            <Divider
              label={<Text size="xs" fw={700} tt="uppercase" c="dimmed" style={{ fontSize: 10 }}>Field Mapping</Text>}
              labelPosition="left"
            />
            <FieldMappingEditor nodeId={selectedNode.id} />
          </>
        )}

        {/* Config properties from schema (generic form for non-map_data nodes) */}
        {!isMapDataNode && Object.keys(properties).length > 0 && (
          <>
            <Divider
              label={<Text size="xs" fw={700} tt="uppercase" c="dimmed" style={{ fontSize: 10 }}>Configuration</Text>}
              labelPosition="left"
            />

            {Object.entries(properties).map(([key, schema]) => {
              const value = config[key];
              const fieldLabel = schema.title ?? key.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

              if (schema.enum) {
                return (
                  <Select
                    key={key}
                    label={fieldLabel}
                    description={schema.description}
                    size="xs"
                    data={schema.enum}
                    value={typeof value === "string" ? value : null}
                    onChange={(v) => handleConfigChange(key, v)}
                    clearable
                    styles={{ label: { fontWeight: 500 } }}
                  />
                );
              }

              if (schema.type === "number" || schema.type === "integer") {
                return (
                  <NumberInput
                    key={key}
                    label={fieldLabel}
                    description={schema.description}
                    size="xs"
                    value={typeof value === "number" ? value : undefined}
                    onChange={(v) => handleConfigChange(key, v)}
                    styles={{ label: { fontWeight: 500 } }}
                  />
                );
              }

              if (schema.type === "boolean") {
                return (
                  <Switch
                    key={key}
                    label={fieldLabel}
                    description={schema.description}
                    size="xs"
                    checked={Boolean(value)}
                    onChange={(e) =>
                      handleConfigChange(key, e.currentTarget.checked)
                    }
                  />
                );
              }

              // Long text fields
              if (key === "notes" || key === "description" || key === "body" || key === "message") {
                return (
                  <Textarea
                    key={key}
                    label={fieldLabel}
                    description={schema.description}
                    size="xs"
                    rows={3}
                    value={typeof value === "string" ? value : ""}
                    onChange={(e) => handleConfigChange(key, e.currentTarget.value)}
                    styles={{ label: { fontWeight: 500 } }}
                  />
                );
              }

              return (
                <TextInput
                  key={key}
                  label={fieldLabel}
                  description={schema.description}
                  size="xs"
                  value={typeof value === "string" ? value : ""}
                  onChange={(e) => handleConfigChange(key, e.currentTarget.value)}
                  styles={{ label: { fontWeight: 500 } }}
                />
              );
            })}
          </>
        )}

        {!isMapDataNode && Object.keys(properties).length === 0 && (
          <Text size="xs" c="dimmed" ta="center" py="sm">
            This node has no configurable properties.
          </Text>
        )}

        {/* Link Form selector for trigger.internal_event nodes */}
        {isTriggerEvent && (
          <>
            <Divider
              label={
                <Group gap={4}>
                  <IconLink size={10} />
                  <Text size="xs" fw={700} tt="uppercase" c="dimmed" style={{ fontSize: 10 }}>
                    Form Link
                  </Text>
                </Group>
              }
              labelPosition="left"
            />
            <Select
              label="Link Form"
              description="Link a form to expose its fields as available sources in field mappings"
              size="xs"
              data={formSelectData}
              value={typeof config.linked_form === "string" ? config.linked_form : null}
              onChange={(v) => handleConfigChange("linked_form", v)}
              clearable
              searchable
              placeholder="Select a form..."
              styles={{ label: { fontWeight: 500 } }}
            />
          </>
        )}

        <Divider my={4} />

        <Button
          variant="light"
          color="red"
          size="xs"
          fullWidth
          leftSection={<IconTrash size={14} />}
          onClick={() => removeNode(selectedNode.id)}
        >
          Delete Node
        </Button>
      </Stack>
    </Box>
  );
}
