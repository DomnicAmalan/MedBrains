import { Select, Stack, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";

export function CalendarZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const dataSource = (zone.config.data_source as string) ?? "";
  const dateField = (zone.config.date_field as string) ?? "";
  const titleField = (zone.config.title_field as string) ?? "";
  const viewMode = (zone.config.view_mode as string) ?? "month";

  const update = (key: string, value: string) => {
    updateZone(zone.clientId, { config: { ...zone.config, [key]: value } });
  };

  return (
    <Stack gap="sm">
      <TextInput
        label="Data source"
        placeholder="e.g., appointments, events"
        value={dataSource}
        onChange={(e) => update("data_source", e.currentTarget.value)}
      />

      <TextInput
        label="Date field"
        placeholder="e.g., scheduled_at"
        value={dateField}
        onChange={(e) => update("date_field", e.currentTarget.value)}
      />

      <TextInput
        label="Title field"
        placeholder="e.g., patient_name"
        value={titleField}
        onChange={(e) => update("title_field", e.currentTarget.value)}
      />

      <Select
        label="Default view"
        data={[
          { value: "month", label: "Month" },
          { value: "week", label: "Week" },
          { value: "day", label: "Day" },
        ]}
        value={viewMode}
        onChange={(v) => update("view_mode", v ?? "month")}
      />
    </Stack>
  );
}
