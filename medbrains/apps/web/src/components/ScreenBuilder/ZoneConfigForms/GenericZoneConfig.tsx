import { JsonInput, Stack, TextInput, Textarea } from "@mantine/core";
import type { ZoneNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import { useState } from "react";

export function GenericZoneConfig({ zone }: { zone: ZoneNode }) {
  const updateZone = useScreenBuilderStore((s) => s.updateZone);
  const [jsonStr, setJsonStr] = useState(JSON.stringify(zone.config, null, 2));
  const [jsonError, setJsonError] = useState<string | null>(null);

  const title = (zone.config.title as string) ?? "";
  const description = (zone.config.description as string) ?? "";

  const handleJsonBlur = () => {
    try {
      const parsed = JSON.parse(jsonStr) as Record<string, unknown>;
      setJsonError(null);
      updateZone(zone.clientId, { config: parsed });
    } catch {
      setJsonError("Invalid JSON");
    }
  };

  return (
    <Stack gap="sm">
      <TextInput
        label="Title"
        placeholder="Zone title"
        value={title}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, title: e.currentTarget.value },
          })
        }
      />

      <Textarea
        label="Description"
        placeholder="Zone description"
        value={description}
        onChange={(e) =>
          updateZone(zone.clientId, {
            config: { ...zone.config, description: e.currentTarget.value },
          })
        }
        minRows={2}
      />

      <JsonInput
        label="Additional config"
        description={`Full config for ${zone.type} zone`}
        value={jsonStr}
        onChange={setJsonStr}
        onBlur={handleJsonBlur}
        minRows={6}
        maxRows={12}
        autosize
        formatOnBlur
        validationError={jsonError}
      />
    </Stack>
  );
}
