import { NumberInput, Stack, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";

export function WidgetGridZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const dashboardCode = (zone.config.dashboard_code as string) ?? "";
  const columnCount = (zone.config.column_count as number) ?? 3;

  const update = (key: string, value: unknown) => {
    updateZone(zone.clientId, { config: { ...zone.config, [key]: value } });
  };

  return (
    <Stack gap="sm">
      <TextInput
        label="Dashboard code"
        placeholder="e.g., main_dashboard"
        value={dashboardCode}
        onChange={(e) => update("dashboard_code", e.currentTarget.value)}
      />

      <NumberInput
        label="Column count"
        value={columnCount}
        onChange={(v) => update("column_count", typeof v === "number" ? v : 3)}
        min={1}
        max={6}
      />
    </Stack>
  );
}
