import { Select, Stack, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { ColumnEditor, type ColumnDef } from "../ColumnEditor";

export function InfoPanelZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const fields = (zone.config.fields as ColumnDef[]) ?? [];
  const layout = (zone.config.layout as string) ?? "vertical";
  const dataSource = (zone.config.data_source as string) ?? "";

  const update = (key: string, value: unknown) => {
    updateZone(zone.clientId, { config: { ...zone.config, [key]: value } });
  };

  return (
    <Stack gap="sm">
      <TextInput
        label="Data source"
        placeholder="e.g., patient, visit"
        value={dataSource}
        onChange={(e) => update("data_source", e.currentTarget.value)}
      />

      <Select
        label="Layout"
        data={[
          { value: "vertical", label: "Vertical" },
          { value: "horizontal", label: "Horizontal" },
        ]}
        value={layout}
        onChange={(v) => update("layout", v ?? "vertical")}
      />

      <div>
        <div style={{ fontSize: "var(--mantine-font-size-sm)", fontWeight: 500, marginBottom: 4 }}>
          Fields
        </div>
        <ColumnEditor
          columns={fields}
          onChange={(f) => update("fields", f)}
          keyPlaceholder="field_key"
          labelPlaceholder="Display Label"
          addLabel="Add field"
        />
      </div>
    </Stack>
  );
}
