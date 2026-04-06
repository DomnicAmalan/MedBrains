import {
  ActionIcon,
  Badge,
  Card,
  Group,
  Loader,
  Skeleton,
  Text,
  Tooltip,
} from "@mantine/core";
import { IconFilter, IconLock, IconRefresh } from "@tabler/icons-react";
import type { CSSProperties, ReactNode } from "react";
import type { DataFilterScope } from "@medbrains/types";
import { SectionIcon } from "../DynamicForm/SectionIcon";

interface WidgetCardProps {
  title: string;
  subtitle?: string | null;
  icon?: string | null;
  color?: string | null;
  widgetType?: string | null;
  permissionCode?: string | null;
  dataScope?: DataFilterScope | null;
  isBuilderMode?: boolean;
  isLoading?: boolean;
  isError?: boolean;
  onRefresh?: () => void;
  isRefreshing?: boolean;
  children: ReactNode;
  onClick?: () => void;
  isSelected?: boolean;
  minHeight?: number;
}

/** Generate CSS custom properties for section-like color theming. */
function widgetColorVars(color: string | null): CSSProperties {
  if (!color) return {};
  return {
    "--widget-icon-bg": `var(--mantine-color-${color}-1)`,
    "--widget-icon-color": `var(--mantine-color-${color}-6)`,
    "--widget-header-border": `var(--mantine-color-${color}-2)`,
    "--widget-accent": `var(--mantine-color-${color}-5)`,
  } as CSSProperties;
}

export function WidgetCard({
  title,
  subtitle,
  icon,
  color,
  widgetType,
  permissionCode,
  dataScope,
  isBuilderMode,
  isLoading,
  isError,
  onRefresh,
  isRefreshing,
  children,
  onClick,
  isSelected,
  minHeight = 120,
}: WidgetCardProps) {
  const colorVars = widgetColorVars(color ?? null);
  const accentColor = color ?? "primary";

  return (
    <Card
      padding={0}
      onClick={onClick}
      style={{
        minHeight,
        cursor: onClick ? "pointer" : undefined,
        outline: isSelected
          ? `2px solid var(--mantine-color-${accentColor}-5)`
          : undefined,
        outlineOffset: -1,
        overflow: "hidden",
        ...colorVars,
      }}
    >
      {/* ── Header — form-builder section style ── */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          padding: "8px 12px",
          background: `var(--widget-icon-bg, var(--mantine-color-gray-0))`,
          borderBottom: `1px solid var(--widget-header-border, var(--mantine-color-gray-2))`,
          position: "relative",
        }}
      >
        {/* Background dot pattern */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            opacity: 0.04,
            backgroundImage:
              "radial-gradient(circle, var(--widget-icon-color, var(--mantine-color-gray-6)) 0.5px, transparent 0.5px)",
            backgroundSize: "8px 8px",
            pointerEvents: "none",
          }}
        />

        {/* Icon — matching form section icon style */}
        {icon && (
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: 28,
              height: 28,
              borderRadius: "var(--mantine-radius-sm)",
              flexShrink: 0,
              background: `var(--widget-icon-bg, var(--mantine-color-gray-1))`,
              color: `var(--widget-icon-color, var(--mantine-color-gray-7))`,
              position: "relative",
              zIndex: 1,
            }}
          >
            <SectionIcon icon={icon} size={14} />
          </div>
        )}

        {/* Title + subtitle */}
        <div style={{ flex: 1, minWidth: 0, position: "relative", zIndex: 1 }}>
          <Text size="xs" fw={600} c="var(--mb-text-primary)" lh={1.2} truncate>
            {title}
          </Text>
          {subtitle && (
            <Text fz={10} c="var(--mb-text-muted)" lh={1.2} truncate>
              {subtitle}
            </Text>
          )}
        </div>

        {/* Right badges + actions */}
        <Group gap={4} style={{ position: "relative", zIndex: 1, flexShrink: 0 }}>
          {permissionCode && (
            <Tooltip label={`Requires: ${permissionCode}`} withArrow>
              <Badge
                size="xs"
                variant="light"
                color="orange"
                leftSection={<IconLock size={8} />}
                style={{ cursor: "help" }}
              >
                Gated
              </Badge>
            </Tooltip>
          )}
          {isBuilderMode && dataScope && (
            <Tooltip
              label={
                dataScope === "auto"
                  ? "Filtered to viewer's departments"
                  : dataScope === "all"
                    ? "Hospital-wide data (no department filter)"
                    : "Filtered to specific departments"
              }
              withArrow
            >
              <Badge
                size="xs"
                variant="light"
                color={
                  dataScope === "auto"
                    ? "teal"
                    : dataScope === "all"
                      ? "gray"
                      : "blue"
                }
                leftSection={<IconFilter size={8} />}
                style={{ cursor: "help" }}
              >
                {dataScope === "auto"
                  ? "Dept"
                  : dataScope === "all"
                    ? "All"
                    : "Filtered"}
              </Badge>
            </Tooltip>
          )}
          {widgetType && (
            <Badge size="xs" variant="dot" color={accentColor}>
              {widgetType.replace(/_/g, " ")}
            </Badge>
          )}
          {onRefresh && (
            <Tooltip label="Refresh">
              <ActionIcon
                variant="subtle"
                size="xs"
                onClick={(e) => {
                  e.stopPropagation();
                  onRefresh();
                }}
              >
                {isRefreshing ? (
                  <Loader size={10} />
                ) : (
                  <IconRefresh size={12} />
                )}
              </ActionIcon>
            </Tooltip>
          )}
        </Group>
      </div>

      {/* ── Body ── */}
      <div style={{ padding: "8px 12px", flex: 1 }}>
        {isLoading ? (
          <div>
            <Skeleton height={20} mb="xs" />
            <Skeleton height={20} width="70%" />
          </div>
        ) : isError ? (
          <Text size="xs" c="red" ta="center" py="md">
            Failed to load data
          </Text>
        ) : (
          children
        )}
      </div>
    </Card>
  );
}
