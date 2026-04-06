import { Alert, Center, Loader, Stack, Text } from "@mantine/core";
import { IconAlertCircle } from "@tabler/icons-react";
import { api } from "@medbrains/api";
import { useQuery } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router";
import { useRequirePermission } from "../../hooks/useRequirePermission";
import { ScreenRenderer } from "./ScreenRenderer";
import type { ScreenAction } from "@medbrains/types";

interface DynamicScreenPageProps {
  /** Explicit screen code — overrides URL-derived code. */
  screenCode?: string;
}

/**
 * Page-level wrapper that resolves a screen by code and renders it dynamically.
 *
 * Supports two routing patterns:
 * - `/m/:moduleCode/:screenCode` — generic dynamic screen route
 * - Explicit routes like `/patients/:id` — pass `screenCode` prop
 *
 * URL params (`:id`, etc.) are forwarded as screen context so zones
 * can reference them (e.g., `{{id}}` in data_source paths).
 */
export function DynamicScreenPage({ screenCode: codeProp }: DynamicScreenPageProps) {
  const params = useParams();
  const code = codeProp ?? params.screenCode;
  const navigate = useNavigate();

  const {
    data: screen,
    isLoading,
    error,
  } = useQuery({
    queryKey: ["resolve-screen", code],
    queryFn: () => api.resolveScreen(code!),
    enabled: Boolean(code),
    staleTime: 60_000,
  });

  // Guard with screen-level permission if set (skip if no permission code)
  const permCode = screen?.permission_code ?? "";
  useRequirePermission(permCode || "dashboard.view");

  if (isLoading) {
    return (
      <Center py="xl">
        <Loader size="md" />
      </Center>
    );
  }

  if (error || !screen) {
    return (
      <Alert icon={<IconAlertCircle size={16} />} color="red" title="Screen not found">
        <Stack gap="xs">
          <Text size="sm">
            Could not resolve screen &quot;{code}&quot;.
          </Text>
          {error && (
            <Text size="xs" c="dimmed">
              {String(error)}
            </Text>
          )}
        </Stack>
      </Alert>
    );
  }

  const handleAction = (action: ScreenAction) => {
    switch (action.action_type) {
      case "navigate":
        if (action.route) navigate(action.route);
        break;
      case "back":
        window.history.back();
        break;
      default:
        // Other action types (save, delete, print, custom) are handled
        // by sidecar orchestration via the emit system
        break;
    }
  };

  return <ScreenRenderer screen={screen} onAction={handleAction} context={params} />;
}
