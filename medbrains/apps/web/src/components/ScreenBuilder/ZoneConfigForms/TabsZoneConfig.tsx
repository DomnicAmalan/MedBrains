import { Select, Stack } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { ColumnEditor, type ColumnDef } from "../ColumnEditor";

export function TabsZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const tabs = (zone.config.tabs as ColumnDef[]) ?? [];
  const defaultTab = (zone.config.default_tab as string) ?? "";
  const position = (zone.config.position as string) ?? "top";

  return (
    <Stack gap="sm">
      <div>
        <div style={{ fontSize: "var(--mantine-font-size-sm)", fontWeight: 500, marginBottom: 4 }}>
          Tabs
        </div>
        <ColumnEditor
          columns={tabs}
          onChange={(t) =>
            updateZone(zone.clientId, { config: { ...zone.config, tabs: t } })
          }
          keyPlaceholder="tab_key"
          labelPlaceholder="Tab Label"
          addLabel="Add tab"
        />
      </div>

      <Select
        label="Default tab"
        placeholder="Select default..."
        data={tabs.filter((t) => t.key).map((t) => ({ value: t.key, label: t.label || t.key }))}
        value={defaultTab || null}
        onChange={(v) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, default_tab: v ?? "" },
          })
        }
        clearable
      />

      <Select
        label="Position"
        data={[
          { value: "top", label: "Top" },
          { value: "left", label: "Left" },
          { value: "bottom", label: "Bottom" },
          { value: "right", label: "Right" },
        ]}
        value={position}
        onChange={(v) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, position: v ?? "top" },
          })
        }
      />
    </Stack>
  );
}
