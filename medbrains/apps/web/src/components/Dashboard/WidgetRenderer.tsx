import {
  Badge,
  Box,
  Group,
  SimpleGrid,
  Stack,
  Text,
  ThemeIcon,
  UnstyledButton,
} from "@mantine/core";
import { useQuery } from "@tanstack/react-query";
import { api } from "@medbrains/api";
import type {
  DashboardWidget,
  DataTableConfig,
  ListConfig,
  QuickActionsConfig,
  StatCardConfig,
} from "@medbrains/types";
import { useHasPermission } from "@medbrains/stores";
import { useNavigate } from "react-router";
import {
  IconArrowRight,
  IconServer,
} from "@tabler/icons-react";
import { SectionIcon } from "../DynamicForm/SectionIcon";
import { WidgetCard } from "./WidgetCard";

interface WidgetRendererProps {
  widget: DashboardWidget;
}

export function WidgetRenderer({ widget }: WidgetRendererProps) {
  const { data, isLoading, isError, refetch, isFetching } = useQuery({
    queryKey: ["widget-data", widget.id],
    queryFn: () => api.getWidgetData(widget.id),
    refetchInterval: widget.refresh_interval
      ? widget.refresh_interval * 1000
      : undefined,
    enabled: widget.data_source.type !== "static",
  });

  const widgetData = data?.data;

  return (
    <WidgetCard
      title={widget.title}
      subtitle={widget.subtitle}
      icon={widget.icon}
      color={widget.color}
      widgetType={widget.widget_type}
      permissionCode={widget.permission_code}
      isLoading={isLoading}
      isError={isError}
      onRefresh={() => void refetch()}
      isRefreshing={isFetching}
    >
      <WidgetContent
        widget={widget}
        data={widgetData}
      />
    </WidgetCard>
  );
}

function WidgetContent({
  widget,
  data,
}: {
  widget: DashboardWidget;
  data: unknown;
}) {
  switch (widget.widget_type) {
    case "stat_card":
      return <StatCardContent config={widget.config as StatCardConfig} data={data} />;
    case "data_table":
      return <DataTableContent config={widget.config as unknown as DataTableConfig} data={data} />;
    case "list":
      return <ListContent config={widget.config as ListConfig} data={data} />;
    case "quick_actions":
      return <QuickActionsContent config={widget.config as unknown as QuickActionsConfig} />;
    case "system_health":
      return <SystemHealthContent data={data} />;
    case "chart":
      return <ChartPlaceholder />;
    case "custom_html":
      return <CustomHtmlContent config={widget.config} />;
    case "module_embed":
      return <ModuleEmbedContent data={data} />;
    default:
      return (
        <Text size="xs" c="dimmed" ta="center">
          Unknown widget type
        </Text>
      );
  }
}

// ── Stat Card ────────────────────────────────────────────

function StatCardContent({
  config,
  data,
}: {
  config: StatCardConfig;
  data: unknown;
}) {
  const d = data as Record<string, unknown> | undefined;
  const value = d?.value ?? "--";
  const label = d?.label as string | undefined;

  const formatted =
    config.format === "currency"
      ? `₹${value}`
      : String(value);

  return (
    <Stack gap={4}>
      <Text fz={28} fw={700} lh={1.1} c="var(--mb-text-primary)">
        {formatted}
      </Text>
      {label && (
        <Text size="xs" c="var(--mb-text-muted)">
          {label}
        </Text>
      )}
    </Stack>
  );
}

// ── Data Table ───────────────────────────────────────────

function DataTableContent({
  config,
  data,
}: {
  config: DataTableConfig;
  data: unknown;
}) {
  const d = data as Record<string, unknown> | undefined;
  const items = (d?.items ?? []) as Record<string, unknown>[];
  const columns = config.columns ?? [];

  if (items.length === 0) {
    return (
      <Text size="xs" c="dimmed" ta="center" py="sm">
        No data available
      </Text>
    );
  }

  return (
    <Box style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr>
            {columns.map((col) => (
              <th
                key={col.key}
                style={{
                  textAlign: "left",
                  padding: "4px 8px",
                  fontSize: 11,
                  fontWeight: 600,
                  color: "var(--mb-text-secondary)",
                  borderBottom: "1px solid var(--mantine-color-gray-2)",
                }}
              >
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {items.slice(0, config.page_size ?? 5).map((item, i) => (
            <tr key={i}>
              {columns.map((col) => (
                <td
                  key={col.key}
                  style={{
                    padding: "4px 8px",
                    fontSize: 12,
                    color: "var(--mb-text-primary)",
                    borderBottom: "1px solid var(--mantine-color-gray-1)",
                  }}
                >
                  {formatCellValue(item[col.key])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </Box>
  );
}

function formatCellValue(val: unknown): string {
  if (val === null || val === undefined) return "--";
  if (typeof val === "string" && val.includes("T")) {
    try {
      return new Date(val).toLocaleDateString();
    } catch {
      return String(val);
    }
  }
  return String(val);
}

// ── List ─────────────────────────────────────────────────

function ListContent({
  config,
  data,
}: {
  config: ListConfig;
  data: unknown;
}) {
  const d = data as Record<string, unknown> | undefined;
  const items = (d?.items ?? []) as Record<string, unknown>[];
  const maxItems = config.max_items ?? 5;

  if (items.length === 0) {
    return (
      <Text size="xs" c="dimmed" ta="center" py="sm">
        {config.empty_message ?? "No items"}
      </Text>
    );
  }

  return (
    <Stack gap={4}>
      {items.slice(0, maxItems).map((item, i) => {
        const iconVal = item.icon as string | undefined;
        const label = String(item.patient_name ?? item.text ?? item.name ?? "");
        const timestamp = item.updated_at as string | undefined;
        const status = item.status as string | undefined;
        return (
          <Group key={i} gap="xs" wrap="nowrap">
            {config.show_icon && iconVal && (
              <ThemeIcon variant="light" size={20} radius="lg">
                <SectionIcon icon={iconVal} size={12} />
              </ThemeIcon>
            )}
            <Text size="xs" c="var(--mb-text-primary)" style={{ flex: 1 }}>
              {label}
            </Text>
            {config.show_timestamp && timestamp && (
              <Text size="xs" c="var(--mb-text-muted)">
                {formatCellValue(timestamp)}
              </Text>
            )}
            {status && (
              <Badge size="xs" variant="light">
                {status}
              </Badge>
            )}
          </Group>
        );
      })}
    </Stack>
  );
}

// ── Quick Actions ────────────────────────────────────────

function QuickActionsContent({ config }: { config: QuickActionsConfig }) {
  const navigate = useNavigate();
  const actions = config.actions ?? [];

  return (
    <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="xs">
      {actions.map((action) => (
        <QuickActionItem
          key={action.path}
          action={action}
          onClick={() => navigate(action.path)}
        />
      ))}
    </SimpleGrid>
  );
}

function QuickActionItem({
  action,
  onClick,
}: {
  action: QuickActionsConfig["actions"][number];
  onClick: () => void;
}) {
  const hasPermission = useHasPermission(action.permission ?? "");
  if (action.permission && !hasPermission) return null;

  return (
    <UnstyledButton
      onClick={onClick}
      style={{
        padding: 8,
        borderRadius: 8,
        background: "var(--mb-card-bg, #ffffff)",
        border: "1px solid var(--mantine-color-gray-2)",
        display: "flex",
        alignItems: "center",
        gap: 8,
      }}
    >
      {action.icon && (
        <ThemeIcon
          variant="light"
          color={action.color ?? "primary"}
          size={28}
          radius="lg"
        >
          <SectionIcon icon={action.icon} size={14} />
        </ThemeIcon>
      )}
      <div style={{ flex: 1 }}>
        <Text size="xs" fw={600} c="var(--mb-text-primary)">
          {action.label}
        </Text>
        {action.description && (
          <Text size="xs" c="var(--mb-text-muted)" lh={1.2}>
            {action.description}
          </Text>
        )}
      </div>
      <IconArrowRight size={12} color="var(--mb-text-muted)" />
    </UnstyledButton>
  );
}

// ── System Health ────────────────────────────────────────

function SystemHealthContent({ data }: { data: unknown }) {
  const d = data as Record<string, unknown> | undefined;
  const services = (d?.services ?? []) as {
    name: string;
    status: string;
  }[];

  return (
    <Stack gap="xs">
      {services.map((svc) => (
        <Group key={svc.name} justify="space-between">
          <Group gap="sm">
            <ThemeIcon
              variant="light"
              color={svc.status === "healthy" || svc.status === "connected" ? "green" : "gray"}
              size={24}
              radius="lg"
            >
              <IconServer size={14} />
            </ThemeIcon>
            <Text size="sm" c="var(--mb-text-secondary)">
              {svc.name}
            </Text>
          </Group>
          <Badge
            color={svc.status === "healthy" || svc.status === "connected" ? "green" : "gray"}
            variant="light"
            size="sm"
          >
            {svc.status}
          </Badge>
        </Group>
      ))}
    </Stack>
  );
}

// ── Chart Placeholder ────────────────────────────────────

function ChartPlaceholder() {
  return (
    <Text size="xs" c="dimmed" ta="center" py="xl">
      Charts coming in Phase 2
    </Text>
  );
}

// ── Custom HTML ──────────────────────────────────────────

function CustomHtmlContent({ config }: { config: Record<string, unknown> }) {
  const content = String(config.content ?? "");
  return (
    <Text size="sm" c="var(--mb-text-primary)">
      {content}
    </Text>
  );
}

// ── Module Embed ─────────────────────────────────────────

function ModuleEmbedContent({ data }: { data: unknown }) {
  const d = data as Record<string, unknown> | undefined;
  if (!d) {
    return <Text size="xs" c="dimmed">No data</Text>;
  }

  if (d.value !== undefined) {
    return (
      <Stack gap={4}>
        <Text fz={24} fw={700} c="var(--mb-text-primary)">
          {String(d.value)}
        </Text>
        {typeof d.label === "string" && (
          <Text size="xs" c="var(--mb-text-muted)">
            {d.label}
          </Text>
        )}
      </Stack>
    );
  }

  return (
    <Text size="xs" c="dimmed" ta="center">
      Module view
    </Text>
  );
}
