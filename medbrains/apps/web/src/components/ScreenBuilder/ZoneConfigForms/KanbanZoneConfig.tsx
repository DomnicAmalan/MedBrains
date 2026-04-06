import { Stack, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { ColumnEditor, type ColumnDef } from "../ColumnEditor";

interface KanbanColumnDef extends ColumnDef {
  color?: string;
}

export function KanbanZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const columns = (zone.config.columns as KanbanColumnDef[]) ?? [];
  const dataSource = (zone.config.data_source as string) ?? "";
  const statusField = (zone.config.status_field as string) ?? "";

  return (
    <Stack gap="sm">
      <TextInput
        label="Data source"
        placeholder="e.g., tasks, tickets"
        value={dataSource}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, data_source: e.currentTarget.value },
          })
        }
      />

      <TextInput
        label="Status field"
        placeholder="e.g., status"
        value={statusField}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, status_field: e.currentTarget.value },
          })
        }
      />

      <div>
        <div style={{ fontSize: "var(--mantine-font-size-sm)", fontWeight: 500, marginBottom: 4 }}>
          Columns
        </div>
        <ColumnEditor
          columns={columns}
          onChange={(cols) =>
            updateZone(zone.clientId, { config: { ...zone.config, columns: cols } })
          }
          keyPlaceholder="status_key"
          labelPlaceholder="Column Label"
          addLabel="Add column"
        />
      </div>
    </Stack>
  );
}
