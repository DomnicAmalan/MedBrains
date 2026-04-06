import { Button, Group, Stack, Text } from "@mantine/core";
import type { ResolvedScreen, ScreenLayout, ScreenAction } from "@medbrains/types";
import { useHasPermission } from "@medbrains/stores";
import { PageHeader } from "../PageHeader";
import { ZoneRenderer } from "./ZoneRenderer";
import { SidecarProvider, useSidecarEmit } from "./SidecarContext";
import { useState } from "react";

interface ScreenRendererProps {
  screen: ResolvedScreen;
  context?: Record<string, unknown>;
  onAction?: (action: ScreenAction) => void;
}

function ActionButton({
  action,
  onAction,
}: {
  action: ScreenAction;
  onAction?: (action: ScreenAction) => void;
}) {
  const hasPermission = useHasPermission(action.permission ?? "");

  // If permission is specified and user doesn't have it, hide the button.
  if (action.permission && !hasPermission) return null;

  const handleClick = () => {
    if (action.confirm) {
      const confirmed = window.confirm(`Are you sure you want to ${action.label.toLowerCase()}?`);
      if (!confirmed) return;
    }
    onAction?.(action);
  };

  return (
    <Button
      variant={(action.variant as "filled" | "light" | "outline") ?? "filled"}
      size="sm"
      onClick={handleClick}
    >
      {action.label}
    </Button>
  );
}

function ScreenContent({
  screen,
  context,
  onAction,
}: ScreenRendererProps) {
  const layout = screen.layout as unknown as ScreenLayout;
  const emit = useSidecarEmit();
  const [filters, setFilters] = useState<Record<string, string>>({});

  const handleAction = (action: ScreenAction) => {
    emit("button_click", { action_key: action.key, action_type: action.action_type });
    onAction?.(action);
  };

  const headerActions =
    layout.actions && layout.actions.length > 0 ? (
      <Group gap="xs">
        {layout.actions.map((action) => (
          <ActionButton
            key={action.key}
            action={action}
            onAction={handleAction}
          />
        ))}
      </Group>
    ) : undefined;

  return (
    <Stack gap="md">
      <PageHeader
        title={layout.header?.title ?? screen.name}
        subtitle={layout.header?.subtitle ?? screen.description ?? undefined}
        actions={headerActions}
      />

      {layout.zones?.length ? (
        layout.zones.map((zone) => (
          <ZoneRenderer
            key={zone.key}
            zone={zone}
            context={context}
            onEmit={emit}
            filters={filters}
            onFilterChange={setFilters}
          />
        ))
      ) : (
        <Text size="sm" c="dimmed">
          No zones configured for this screen.
        </Text>
      )}
    </Stack>
  );
}

/**
 * Renders a fully resolved screen definition dynamically.
 *
 * Wraps the content in a SidecarProvider so zones can emit events
 * that trigger sidecar actions (pipeline calls, inline actions, etc.).
 */
export function ScreenRenderer({
  screen,
  context = {},
  onAction,
}: ScreenRendererProps) {
  return (
    <SidecarProvider screen={screen} context={context}>
      <ScreenContent screen={screen} context={context} onAction={onAction} />
    </SidecarProvider>
  );
}
