import {
  Accordion,
  Badge,
  Box,
  Button,
  Group,
  ScrollArea,
  Stack,
  Text,
  TextInput,
  ThemeIcon,
  Tooltip,
  UnstyledButton,
} from "@mantine/core";
import {
  IconLayoutGrid,
  IconPlus,
  IconSearch,
} from "@tabler/icons-react";
import type { WidgetTemplate, WidgetType } from "@medbrains/types";
import { useMemo, useState } from "react";
import { useDraggable } from "@dnd-kit/core";
import { useDashboardBuilderStore } from "@medbrains/stores";
import { SectionIcon } from "../DynamicForm/SectionIcon";

interface WidgetPaletteProps {
  templates: WidgetTemplate[];
}

const CATEGORY_CONFIG: Record<
  string,
  { label: string; icon: string; color: string }
> = {
  metrics: { label: "Metrics", icon: "activity", color: "primary" },
  data: { label: "Data Views", icon: "clipboard", color: "teal" },
  actions: { label: "Actions", icon: "list-check", color: "violet" },
  module: { label: "Modules", icon: "hospital", color: "orange" },
  system: { label: "System", icon: "settings", color: "slate" },
  general: { label: "General", icon: "notes", color: "info" },
};

const WIDGET_TYPE_LABELS: Record<WidgetType, string> = {
  stat_card: "Stat Card",
  data_table: "Data Table",
  list: "List",
  chart: "Chart",
  quick_actions: "Quick Actions",
  module_embed: "Module Embed",
  form_embed: "Form Embed",
  system_health: "System Health",
  custom_html: "Custom HTML",
};

export function WidgetPalette({ templates }: WidgetPaletteProps) {
  const [search, setSearch] = useState("");
  const addCustomWidget = useDashboardBuilderStore((s) => s.addCustomWidget);

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return templates.filter(
      (t) =>
        t.name.toLowerCase().includes(q) ||
        t.category.toLowerCase().includes(q) ||
        t.widget_type.toLowerCase().includes(q),
    );
  }, [templates, search]);

  const grouped = useMemo(() => {
    const groups: Record<string, WidgetTemplate[]> = {};
    for (const t of filtered) {
      const cat = t.category;
      if (!groups[cat]) groups[cat] = [];
      groups[cat].push(t);
    }
    return groups;
  }, [filtered]);

  const categoryOrder = [
    "metrics",
    "data",
    "actions",
    "module",
    "system",
    "general",
  ];

  return (
    <Stack gap="sm" h="100%">
      <Group gap="xs">
        <ThemeIcon variant="light" color="primary" size={24} radius="md">
          <IconLayoutGrid size={14} />
        </ThemeIcon>
        <Text size="sm" fw={700} c="var(--mb-text-primary)">
          Widgets
        </Text>
        <Badge size="xs" variant="light" color="slate" ml="auto">
          {templates.length}
        </Badge>
      </Group>

      <TextInput
        placeholder="Search widgets..."
        leftSection={<IconSearch size={14} />}
        size="xs"
        value={search}
        onChange={(e) => setSearch(e.currentTarget.value)}
        styles={{ input: { borderRadius: 8 } }}
      />

      <ScrollArea style={{ flex: 1 }} offsetScrollbars scrollbarSize={4}>
        <Accordion
          multiple
          defaultValue={categoryOrder}
          styles={{
            item: { borderBottom: "none" },
            control: { padding: "4px 0" },
            content: { padding: "0 0 8px 0" },
          }}
        >
          {categoryOrder
            .filter((cat) => grouped[cat])
            .map((category) => {
              const config = CATEGORY_CONFIG[category] ?? {
                label: category,
                icon: "notes",
                color: "slate",
              };
              const items = grouped[category]!;
              return (
                <Accordion.Item key={category} value={category}>
                  <Accordion.Control>
                    <Group gap="xs">
                      <ThemeIcon
                        variant="light"
                        color={config.color}
                        size={20}
                        radius="md"
                      >
                        <SectionIcon icon={config.icon} size={11} />
                      </ThemeIcon>
                      <Text size="xs" fw={600}>
                        {config.label}
                      </Text>
                      <Badge size="xs" variant="light" color="slate" ml="auto">
                        {items.length}
                      </Badge>
                    </Group>
                  </Accordion.Control>
                  <Accordion.Panel>
                    <Stack gap={4}>
                      {items.map((template) => (
                        <DraggableTemplate
                          key={template.id}
                          template={template}
                        />
                      ))}
                    </Stack>
                  </Accordion.Panel>
                </Accordion.Item>
              );
            })}
        </Accordion>

        {filtered.length === 0 && (
          <Text size="xs" c="dimmed" ta="center" py="lg">
            No widgets match "{search}"
          </Text>
        )}
      </ScrollArea>

      {/* Create Custom Widget button */}
      <Box>
        <Button
          variant="light"
          size="xs"
          fullWidth
          leftSection={<IconPlus size={14} />}
          onClick={() => {
            addCustomWidget({
              widget_type: "custom_html",
              title: "Custom Widget",
              config: { content: "" },
              data_source: { type: "static" },
            });
          }}
        >
          Custom Widget
        </Button>
      </Box>
    </Stack>
  );
}

function DraggableTemplate({ template }: { template: WidgetTemplate }) {
  const addWidget = useDashboardBuilderStore((s) => s.addWidget);

  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `template-${template.id}`,
    data: { type: "template", template },
  });

  return (
    <Tooltip
      label={`${WIDGET_TYPE_LABELS[template.widget_type] ?? template.widget_type} — ${template.default_width}x${template.default_height} — Double-click to add`}
      position="right"
      withArrow
      openDelay={400}
    >
      <UnstyledButton
        ref={setNodeRef}
        {...attributes}
        {...listeners}
        onDoubleClick={() => addWidget(template, { x: 0, y: 0 })}
        style={{
          padding: "6px 8px",
          borderRadius: 8,
          cursor: isDragging ? "grabbing" : "grab",
          opacity: isDragging ? 0.4 : 1,
          border: "1px solid var(--mantine-color-gray-2)",
          background: isDragging
            ? "var(--mantine-color-primary-0)"
            : "var(--mantine-color-white)",
          transition: "all 150ms",
          display: "flex",
          alignItems: "center",
          gap: 8,
        }}
      >
        {template.icon && (
          <ThemeIcon
            variant="light"
            color={template.color ?? "slate"}
            size={26}
            radius="md"
          >
            <SectionIcon icon={template.icon} size={13} />
          </ThemeIcon>
        )}
        <div style={{ flex: 1, minWidth: 0 }}>
          <Text size="xs" fw={600} truncate lh={1.2}>
            {template.name}
          </Text>
          {template.description && (
            <Text fz={10} c="dimmed" truncate lh={1.2}>
              {template.description}
            </Text>
          )}
        </div>
        <Badge size="xs" variant="dot" color={template.color ?? "slate"}>
          {template.default_width}x{template.default_height}
        </Badge>
      </UnstyledButton>
    </Tooltip>
  );
}
