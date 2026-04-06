import { NumberInput, Select, Stack, Switch, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { ColumnEditor, type ColumnDef } from "../ColumnEditor";

export function DataTableZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const columns = (zone.config.columns as ColumnDef[]) ?? [];
  const dataSource = (zone.config.data_source as string) ?? "";
  const pageSize = (zone.config.page_size as number) ?? 20;
  const searchable = (zone.config.searchable as boolean) ?? true;
  const selectable = (zone.config.selectable as boolean) ?? false;
  const sortable = (zone.config.sortable as boolean) ?? true;

  return (
    <Stack gap="sm">
      <TextInput
        label="Data source"
        placeholder="e.g., patients, opd_visits"
        value={dataSource}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, data_source: e.currentTarget.value },
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
          keyPlaceholder="field_key"
          labelPlaceholder="Column Label"
          addLabel="Add column"
        />
      </div>

      <NumberInput
        label="Page size"
        value={pageSize}
        onChange={(v) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, page_size: typeof v === "number" ? v : 20 },
          })
        }
        min={5}
        max={100}
        step={5}
      />

      <Switch
        label="Searchable"
        checked={searchable}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, searchable: e.currentTarget.checked },
          })
        }
      />

      <Switch
        label="Row selection"
        checked={selectable}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, selectable: e.currentTarget.checked },
          })
        }
      />

      <Switch
        label="Sortable columns"
        checked={sortable}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, sortable: e.currentTarget.checked },
          })
        }
      />

      <Select
        label="Row actions"
        placeholder="Add row actions..."
        data={[
          { value: "view", label: "View" },
          { value: "edit", label: "Edit" },
          { value: "delete", label: "Delete" },
          { value: "print", label: "Print" },
        ]}
        value={null}
        onChange={(v) => {
          if (!v) return;
          const existing = (zone.config.row_actions as string[]) ?? [];
          if (!existing.includes(v)) {
            updateZone(zone.clientId, {
              config: { ...zone.config, row_actions: [...existing, v] },
            });
          }
        }}
        clearable
      />
    </Stack>
  );
}
