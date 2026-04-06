import { Stack, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { ColumnEditor, type ColumnDef } from "../ColumnEditor";

export function FilterBarZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const filters = (zone.config.filters as ColumnDef[]) ?? [];
  const searchPlaceholder = (zone.config.search_placeholder as string) ?? "";

  return (
    <Stack gap="sm">
      <TextInput
        label="Search placeholder"
        placeholder="Search..."
        value={searchPlaceholder}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, search_placeholder: e.currentTarget.value },
          })
        }
      />

      <div>
        <div style={{ fontSize: "var(--mantine-font-size-sm)", fontWeight: 500, marginBottom: 4 }}>
          Filter fields
        </div>
        <ColumnEditor
          columns={filters}
          onChange={(f) =>
            updateZone(zone.clientId, { config: { ...zone.config, filters: f } })
          }
          keyPlaceholder="field_key"
          labelPlaceholder="Filter Label"
          addLabel="Add filter"
        />
      </div>
    </Stack>
  );
}
