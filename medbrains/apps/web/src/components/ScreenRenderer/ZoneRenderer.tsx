import {
  Alert,
  Avatar,
  Badge,
  Card,
  Group,
  Indicator,
  Loader,
  ScrollArea,
  Select,
  SimpleGrid,
  Stack,
  Stepper,
  Tabs,
  Text,
  TextInput,
} from "@mantine/core";
import {
  IconAlertCircle,
  IconCalendar,
  IconFilter,
  IconSearch,
} from "@tabler/icons-react";
import type { ScreenZone } from "@medbrains/types";
import { DynamicForm } from "../DynamicForm";
import { DataTable } from "../DataTable";
import { useZoneData } from "./useZoneData";
import { useState } from "react";

// ── Shared types ──

export interface ZoneRendererProps {
  zone: ScreenZone;
  context?: Record<string, unknown>;
  onEmit?: (trigger: string, payload: Record<string, unknown>) => void;
  filters?: Record<string, string>;
  onFilterChange?: (filters: Record<string, string>) => void;
}

function getContextArray(
  context: Record<string, unknown> | undefined,
  key: string,
): Record<string, unknown>[] {
  if (!context) return [];
  const val = context[key];
  return Array.isArray(val) ? (val as Record<string, unknown>[]) : [];
}

function getContextObject(
  context: Record<string, unknown> | undefined,
  key: string,
): Record<string, unknown> {
  if (!context) return {};
  const val = context[key];
  return typeof val === "object" && val !== null && !Array.isArray(val)
    ? (val as Record<string, unknown>)
    : {};
}

// ── Form Zone ──

function FormZone({ zone, onEmit }: ZoneRendererProps) {
  const cfg = zone.config as {
    form_code?: string;
    quick_mode?: boolean;
  };

  if (!cfg.form_code) {
    return (
      <Alert icon={<IconAlertCircle size={16} />} color="warning">
        Form zone &quot;{zone.key}&quot; has no form_code configured.
      </Alert>
    );
  }

  return (
    <DynamicForm
      formCode={cfg.form_code}
      quickMode={cfg.quick_mode}
      onSubmit={(values) => {
        onEmit?.("form_submit", { zone_key: zone.key, values });
      }}
    />
  );
}

// ── Data Table Zone ──

function DataTableZone({ zone, context }: ZoneRendererProps) {
  const cfg = zone.config as {
    data_source?: string;
    columns?: Array<{ key: string; label: string }> | string[];
    page_size?: number;
    searchable?: boolean;
    selectable?: boolean;
  };

  const { data: fetched, isLoading } = useZoneData({
    dataSource: cfg.data_source,
  });

  const rows = fetched && Array.isArray(fetched)
    ? (fetched as Record<string, unknown>[])
    : getContextArray(context, zone.key);

  const columns = cfg.columns?.map((col) => {
    if (typeof col === "string") {
      return {
        key: col,
        label: col.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()),
        render: (row: Record<string, unknown>) => String(row[col] ?? ""),
      };
    }
    return {
      key: col.key,
      label: col.label,
      render: (row: Record<string, unknown>) => String(row[col.key] ?? ""),
    };
  }) ?? [];

  return (
    <DataTable
      columns={columns}
      data={rows}
      loading={isLoading}
      rowKey={(row: Record<string, unknown>) => String(row["id"] ?? "")}
    />
  );
}

// ── Filter Bar Zone ──

function FilterBarZone({ zone, filters, onFilterChange, onEmit }: ZoneRendererProps) {
  const cfg = zone.config as {
    search_placeholder?: string;
    filters?: Array<{ key: string; label: string; options?: Array<{ value: string; label: string }> }>;
  };

  const currentFilters = filters ?? {};

  const handleSearchChange = (value: string) => {
    const next = { ...currentFilters, search: value };
    onFilterChange?.(next);
    onEmit?.("field_change", { zone_key: zone.key, field: "search", value });
  };

  const handleFilterChange = (key: string, value: string | null) => {
    const next = { ...currentFilters };
    if (value) {
      next[key] = value;
    } else {
      delete next[key];
    }
    onFilterChange?.(next);
    onEmit?.("field_change", { zone_key: zone.key, field: key, value: value ?? "" });
  };

  return (
    <Group gap="sm" align="flex-end" wrap="wrap">
      <TextInput
        key="__search"
        placeholder={cfg.search_placeholder ?? "Search..."}
        leftSection={<IconSearch size={14} />}
        value={currentFilters["search"] ?? ""}
        onChange={(e) => handleSearchChange(e.currentTarget.value)}
        style={{ minWidth: 200 }}
      />
      {cfg.filters?.map((f) => (
        <Select
          key={f.key}
          label={f.label}
          placeholder={`All ${f.label}`}
          data={f.options ?? []}
          value={currentFilters[f.key] ?? null}
          onChange={(v) => handleFilterChange(f.key, v)}
          clearable
          size="sm"
          leftSection={<IconFilter size={14} />}
        />
      ))}
    </Group>
  );
}

// ── Tabs Zone ──

function TabsZone({ zone, context, onEmit, filters, onFilterChange }: ZoneRendererProps) {
  const cfg = zone.config as {
    tabs?: Array<{
      key: string;
      label: string;
      icon?: string;
      zones?: ScreenZone[];
    }>;
    default_tab?: string;
    position?: "top" | "left" | "bottom" | "right";
  };

  if (!cfg.tabs?.length) return null;

  return (
    <Tabs defaultValue={cfg.default_tab ?? cfg.tabs[0]?.key} orientation={cfg.position === "left" ? "vertical" : "horizontal"}>
      <Tabs.List>
        {cfg.tabs.map((tab) => (
          <Tabs.Tab key={tab.key} value={tab.key}>
            {tab.label}
          </Tabs.Tab>
        ))}
      </Tabs.List>
      {cfg.tabs.map((tab) => (
        <Tabs.Panel key={tab.key} value={tab.key} pt="md">
          {tab.zones?.map((childZone) => (
            <ZoneRenderer
              key={childZone.key}
              zone={childZone}
              context={context}
              onEmit={onEmit}
              filters={filters}
              onFilterChange={onFilterChange}
            />
          ))}
        </Tabs.Panel>
      ))}
    </Tabs>
  );
}

// ── Detail Header Zone ──

function DetailHeaderZone({ zone, context }: ZoneRendererProps) {
  const cfg = zone.config as {
    data_source?: string;
    title_field?: string;
    subtitle_field?: string;
    avatar_field?: string;
    badge_field?: string;
  };

  const { data: fetched } = useZoneData({ dataSource: cfg.data_source });
  const record = fetched && !Array.isArray(fetched)
    ? fetched
    : getContextObject(context, zone.key);

  const title = String(record[cfg.title_field ?? "name"] ?? "");
  const subtitle = cfg.subtitle_field ? String(record[cfg.subtitle_field] ?? "") : null;
  const avatarUrl = cfg.avatar_field ? (record[cfg.avatar_field] as string) : null;
  const badgeText = cfg.badge_field ? String(record[cfg.badge_field] ?? "") : null;

  return (
    <Card withBorder p="md">
      <Group gap="md" wrap="nowrap">
        <Avatar src={avatarUrl} size={56} radius="xl" color="primary">
          {title.charAt(0).toUpperCase()}
        </Avatar>
        <Stack gap={4} style={{ flex: 1 }}>
          <Group gap="sm" align="center">
            <Text size="lg" fw={600}>
              {title}
            </Text>
            {badgeText && (
              <Badge size="sm" variant="light">
                {badgeText}
              </Badge>
            )}
          </Group>
          {subtitle && (
            <Text size="sm" c="dimmed">
              {subtitle}
            </Text>
          )}
        </Stack>
      </Group>
    </Card>
  );
}

// ── Stepper Zone ──

function StepperZone({ zone, onEmit }: ZoneRendererProps) {
  const cfg = zone.config as {
    steps?: Array<{ key: string; label: string; description?: string }>;
  };
  const [active, setActive] = useState(0);

  if (!cfg.steps?.length) {
    return (
      <Text size="sm" c="dimmed">
        No steps configured for stepper zone.
      </Text>
    );
  }

  const handleStepChange = (step: number) => {
    const prevStep = cfg.steps?.[active];
    const nextStep = cfg.steps?.[step];
    if (prevStep) {
      onEmit?.("step_leave", { zone_key: zone.key, step_key: prevStep.key, step_index: active });
    }
    setActive(step);
    if (nextStep) {
      onEmit?.("step_enter", { zone_key: zone.key, step_key: nextStep.key, step_index: step });
    }
  };

  return (
    <Stepper active={active} onStepClick={handleStepChange}>
      {cfg.steps.map((step) => (
        <Stepper.Step key={step.key} label={step.label} description={step.description}>
          <Text size="sm" c="dimmed" pt="md">
            Content for step: {step.label}
          </Text>
        </Stepper.Step>
      ))}
    </Stepper>
  );
}

// ── Info Panel Zone ──

function InfoPanelZone({ zone, context }: ZoneRendererProps) {
  const cfg = zone.config as {
    data_source?: string;
    fields?: Array<{ key: string; label: string }>;
    layout?: "vertical" | "horizontal";
  };

  const { data: fetched } = useZoneData({ dataSource: cfg.data_source });
  const record = fetched && !Array.isArray(fetched)
    ? fetched
    : getContextObject(context, zone.key);

  const isHorizontal = cfg.layout === "horizontal";

  return (
    <Card withBorder p="md">
      {zone.label && (
        <Text fw={600} mb="sm">
          {zone.label}
        </Text>
      )}
      {isHorizontal ? (
        <Group gap="xl" wrap="wrap">
          {cfg.fields?.map((field) => (
            <Stack key={field.key} gap={2}>
              <Text size="xs" c="dimmed" tt="uppercase" fw={500}>
                {field.label}
              </Text>
              <Text size="sm" fw={500}>
                {String(record[field.key] ?? "—")}
              </Text>
            </Stack>
          ))}
        </Group>
      ) : (
        <Stack gap="xs">
          {cfg.fields?.map((field) => (
            <Group key={field.key} justify="space-between" wrap="nowrap">
              <Text size="sm" c="dimmed">
                {field.label}
              </Text>
              <Text size="sm" fw={500}>
                {String(record[field.key] ?? "—")}
              </Text>
            </Group>
          ))}
        </Stack>
      )}
      {!cfg.fields?.length && (
        <Text size="sm" c="dimmed" fs="italic">
          No fields configured.
        </Text>
      )}
    </Card>
  );
}

// ── Kanban Zone ──

interface KanbanCard {
  id?: string;
  title?: string;
  [key: string]: unknown;
}

function KanbanZone({ zone, context, onEmit }: ZoneRendererProps) {
  const cfg = zone.config as {
    data_source?: string;
    status_field?: string;
    columns?: Array<{ key: string; label: string; color?: string }>;
    title_field?: string;
  };

  const { data: fetched, isLoading } = useZoneData({ dataSource: cfg.data_source });
  const items = fetched && Array.isArray(fetched)
    ? (fetched as KanbanCard[])
    : (getContextArray(context, zone.key) as KanbanCard[]);

  const statusField = cfg.status_field ?? "status";
  const titleField = cfg.title_field ?? "title";

  if (isLoading) return <Loader size="sm" />;

  if (!cfg.columns?.length) {
    return (
      <Text size="sm" c="dimmed">
        No columns configured for kanban.
      </Text>
    );
  }

  return (
    <ScrollArea type="auto" offsetScrollbars>
      <Group gap="md" wrap="nowrap" align="flex-start" style={{ minWidth: cfg.columns.length * 260 }}>
        {cfg.columns.map((col) => {
          const colItems = items.filter(
            (item) => String(item[statusField] ?? "") === col.key,
          );

          return (
            <Stack
              key={col.key}
              gap="xs"
              style={{
                width: 240,
                minWidth: 240,
                flexShrink: 0,
              }}
            >
              <Group gap="xs" mb={4}>
                {col.color && (
                  <Indicator color={col.color} size={8} />
                )}
                <Text size="sm" fw={600}>
                  {col.label}
                </Text>
                <Badge size="xs" variant="light" color="slate">
                  {colItems.length}
                </Badge>
              </Group>

              {colItems.map((item, i) => (
                <Card
                  key={String(item.id ?? i)}
                  withBorder
                  p="xs"
                  shadow="xs"
                  style={{ cursor: "pointer" }}
                  onClick={() =>
                    onEmit?.("row_select", { zone_key: zone.key, row: item })
                  }
                >
                  <Text size="sm" lineClamp={2}>
                    {String(item[titleField] ?? `Item ${i + 1}`)}
                  </Text>
                </Card>
              ))}

              {colItems.length === 0 && (
                <Text size="xs" c="dimmed" fs="italic" ta="center" py="sm">
                  No items
                </Text>
              )}
            </Stack>
          );
        })}
      </Group>
    </ScrollArea>
  );
}

// ── Calendar Zone ──

function CalendarZone({ zone, context }: ZoneRendererProps) {
  const cfg = zone.config as {
    data_source?: string;
    date_field?: string;
    title_field?: string;
  };

  const { data: fetched, isLoading } = useZoneData({ dataSource: cfg.data_source });
  const events = fetched && Array.isArray(fetched)
    ? (fetched as Record<string, unknown>[])
    : getContextArray(context, zone.key);

  const dateField = cfg.date_field ?? "date";
  const titleField = cfg.title_field ?? "title";

  if (isLoading) return <Loader size="sm" />;

  return (
    <Card withBorder p="md">
      <Group gap="xs" mb="sm">
        <IconCalendar size={16} />
        <Text fw={600}>{zone.label ?? "Calendar"}</Text>
        <Badge size="xs" variant="light">
          {events.length} events
        </Badge>
      </Group>
      {events.length === 0 ? (
        <Text size="sm" c="dimmed" fs="italic">
          No events found.
        </Text>
      ) : (
        <Stack gap="xs">
          {events.slice(0, 20).map((ev, i) => (
            <Group key={String(ev["id"] ?? i)} gap="sm" wrap="nowrap">
              <Badge size="xs" variant="dot" color="primary" style={{ flexShrink: 0 }}>
                {String(ev[dateField] ?? "").slice(0, 10)}
              </Badge>
              <Text size="sm" lineClamp={1}>
                {String(ev[titleField] ?? `Event ${i + 1}`)}
              </Text>
            </Group>
          ))}
        </Stack>
      )}
    </Card>
  );
}

// ── Widget Grid Zone ──

function WidgetGridZone({ zone, context }: ZoneRendererProps) {
  const cfg = zone.config as {
    dashboard_code?: string;
    column_count?: number;
  };

  const widgets = getContextArray(context, zone.key);
  const cols = cfg.column_count ?? 3;

  if (!widgets.length && !cfg.dashboard_code) {
    return (
      <Text size="sm" c="dimmed">
        Widget grid: {cfg.dashboard_code ?? "not configured"}
      </Text>
    );
  }

  return (
    <SimpleGrid cols={cols} spacing="md">
      {widgets.map((w, i) => (
        <Card key={String(w["id"] ?? i)} withBorder p="md">
          <Text size="xs" c="dimmed" tt="uppercase" fw={500}>
            {String(w["label"] ?? "")}
          </Text>
          <Text size="xl" fw={700}>
            {String(w["value"] ?? "—")}
          </Text>
          {w["trend"] !== undefined && (
            <Text size="xs" c={Number(w["trend"]) >= 0 ? "teal" : "danger"}>
              {Number(w["trend"]) >= 0 ? "+" : ""}
              {String(w["trend"])}%
            </Text>
          )}
        </Card>
      ))}
    </SimpleGrid>
  );
}

// ── Fallback ──

function FallbackZone({ zone }: ZoneRendererProps) {
  return (
    <Alert icon={<IconAlertCircle size={16} />} color="slate">
      Unknown zone type: &quot;{zone.type}&quot; (key: {zone.key})
    </Alert>
  );
}

// ── Main Dispatcher ──

/**
 * Dispatches a screen zone to the appropriate component based on its type.
 * Each zone receives optional context data, filter state, and an event emitter
 * for sidecar integration.
 */
export function ZoneRenderer(props: ZoneRendererProps) {
  switch (props.zone.type) {
    case "form":
      return <FormZone {...props} />;
    case "data_table":
      return <DataTableZone {...props} />;
    case "filter_bar":
      return <FilterBarZone {...props} />;
    case "tabs":
      return <TabsZone {...props} />;
    case "detail_header":
      return <DetailHeaderZone {...props} />;
    case "stepper":
      return <StepperZone {...props} />;
    case "info_panel":
      return <InfoPanelZone {...props} />;
    case "kanban":
      return <KanbanZone {...props} />;
    case "calendar":
      return <CalendarZone {...props} />;
    case "widget_grid":
      return <WidgetGridZone {...props} />;
    default:
      return <FallbackZone {...props} />;
  }
}
