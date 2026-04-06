import { Stack, TextInput } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";

export function DetailHeaderZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);

  const titleField = (zone.config.title_field as string) ?? "";
  const subtitleField = (zone.config.subtitle_field as string) ?? "";
  const avatarField = (zone.config.avatar_field as string) ?? "";
  const badgeField = (zone.config.badge_field as string) ?? "";
  const dataSource = (zone.config.data_source as string) ?? "";

  const update = (key: string, value: string) => {
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

      <TextInput
        label="Title field"
        placeholder="e.g., full_name"
        value={titleField}
        onChange={(e) => update("title_field", e.currentTarget.value)}
      />

      <TextInput
        label="Subtitle field"
        placeholder="e.g., uhid"
        value={subtitleField}
        onChange={(e) => update("subtitle_field", e.currentTarget.value)}
      />

      <TextInput
        label="Avatar field"
        placeholder="e.g., photo_url"
        value={avatarField}
        onChange={(e) => update("avatar_field", e.currentTarget.value)}
      />

      <TextInput
        label="Badge field"
        placeholder="e.g., status"
        value={badgeField}
        onChange={(e) => update("badge_field", e.currentTarget.value)}
      />
    </Stack>
  );
}
