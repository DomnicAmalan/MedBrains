import { Select, Stack, Switch, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { api } from "@medbrains/api";
import { useQuery } from "@tanstack/react-query";

export function FormZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const { data: forms } = useQuery({
    queryKey: ["admin-forms"],
    queryFn: () => api.adminListForms(),
    staleTime: 60_000,
  });

  const formOptions = (forms ?? []).map((f: { id: string; code: string; name: string }) => ({
    value: f.code,
    label: `${f.name} (${f.code})`,
  }));

  const formCode = (zone.config.form_code as string) ?? "";
  const quickMode = (zone.config.quick_mode as boolean) ?? false;

  return (
    <Stack gap="sm">
      <Select
        label="Form"
        placeholder="Select a form..."
        data={formOptions}
        value={formCode || null}
        onChange={(v) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, form_code: v ?? "" },
          })
        }
        searchable
        clearable
      />
      <Switch
        label="Quick mode"
        description="Show only quick-mode fields"
        checked={quickMode}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, quick_mode: e.currentTarget.checked },
          })
        }
      />
      <TextInput
        label="Submit label"
        placeholder="Submit"
        value={(zone.config.submit_label as string) ?? ""}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, submit_label: e.currentTarget.value },
          })
        }
      />
    </Stack>
  );
}
