import {
  Checkbox,
  Group,
  SimpleGrid,
  Stack,
  Text,
  TextInput,
} from "@mantine/core";
import type { ReviewOfSystems as ROSType, ROSSystem } from "@medbrains/types";

interface ReviewOfSystemsProps {
  data: ROSType;
  canUpdate: boolean;
  onUpdate: (ros: ROSType) => void;
}

const ROS_SYSTEMS: { key: keyof ROSType; label: string }[] = [
  { key: "constitutional", label: "Constitutional" },
  { key: "eyes", label: "Eyes" },
  { key: "ent", label: "ENT (Ears/Nose/Throat)" },
  { key: "cardiovascular", label: "Cardiovascular" },
  { key: "respiratory", label: "Respiratory" },
  { key: "gi", label: "Gastrointestinal" },
  { key: "genitourinary", label: "Genitourinary" },
  { key: "musculoskeletal", label: "Musculoskeletal" },
  { key: "skin", label: "Skin / Integumentary" },
  { key: "neurological", label: "Neurological" },
  { key: "psychiatric", label: "Psychiatric" },
  { key: "endocrine", label: "Endocrine" },
  { key: "hematologic", label: "Hematologic / Lymphatic" },
  { key: "allergic_immunologic", label: "Allergic / Immunologic" },
];

export function ReviewOfSystems({ data, canUpdate, onUpdate }: ReviewOfSystemsProps) {
  const toggle = (key: keyof ROSType) => {
    const current = data[key] as ROSSystem | undefined;
    const abnormal = !current?.abnormal;
    onUpdate({
      ...data,
      [key]: { abnormal, details: current?.details ?? "" },
    });
  };

  const setDetails = (key: keyof ROSType, details: string) => {
    const current = data[key] as ROSSystem | undefined;
    onUpdate({
      ...data,
      [key]: { abnormal: current?.abnormal ?? true, details },
    });
  };

  const abnormalCount = ROS_SYSTEMS.filter((s) => (data[s.key] as ROSSystem | undefined)?.abnormal).length;

  return (
    <Stack gap="sm">
      <Group justify="space-between">
        <Text size="sm" fw={600}>Review of Systems</Text>
        {abnormalCount > 0 && (
          <Text size="xs" c="danger">{abnormalCount} abnormal</Text>
        )}
      </Group>
      <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="xs">
        {ROS_SYSTEMS.map((sys) => {
          const val = data[sys.key] as ROSSystem | undefined;
          return (
            <Stack key={sys.key} gap={4}>
              <Checkbox
                label={sys.label}
                checked={val?.abnormal ?? false}
                onChange={() => toggle(sys.key)}
                size="sm"
                disabled={!canUpdate}
                color="danger"
              />
              {val?.abnormal && (
                <TextInput
                  placeholder={`Details for ${sys.label}...`}
                  value={val.details ?? ""}
                  onChange={(e) => setDetails(sys.key, e.currentTarget.value)}
                  size="xs"
                  ml={28}
                  disabled={!canUpdate}
                />
              )}
            </Stack>
          );
        })}
      </SimpleGrid>
    </Stack>
  );
}
