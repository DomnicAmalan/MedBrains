import {
  Badge,
  Box,
  Group,
  Modal,
  Stack,
  Table,
  Text,
  ThemeIcon,
} from "@mantine/core";
import {
  IconArrowRight,
  IconMinus,
  IconPencil,
  IconPlus,
} from "@tabler/icons-react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@medbrains/api";
import type { FieldChange, SectionChange } from "@medbrains/types";

const changeColors: Record<string, string> = {
  added: "green",
  removed: "red",
  modified: "yellow",
  moved: "blue",
};

const changeIcons: Record<string, typeof IconPlus> = {
  added: IconPlus,
  removed: IconMinus,
  modified: IconPencil,
  moved: IconArrowRight,
};

function FieldChangeRow({ fc }: { fc: FieldChange }) {
  const Icon = changeIcons[fc.change_type] ?? IconPencil;
  return (
    <Table.Tr>
      <Table.Td>
        <Group gap="xs">
          <ThemeIcon
            size="xs"
            variant="light"
            color={changeColors[fc.change_type] ?? "gray"}
          >
            <Icon size={10} />
          </ThemeIcon>
          <Text size="xs" ff="monospace">
            {fc.field_code}
          </Text>
        </Group>
      </Table.Td>
      <Table.Td>
        <Text size="xs">{fc.field_name}</Text>
      </Table.Td>
      <Table.Td>
        <Badge
          size="xs"
          color={changeColors[fc.change_type] ?? "gray"}
          variant="light"
        >
          {fc.change_type}
        </Badge>
      </Table.Td>
      <Table.Td>
        {fc.property_changes.length > 0 && (
          <Text size="xs" c="dimmed">
            {fc.property_changes.map((pc) => pc.property).join(", ")}
          </Text>
        )}
      </Table.Td>
    </Table.Tr>
  );
}

function SectionChangeBlock({ sc }: { sc: SectionChange }) {
  const Icon = changeIcons[sc.change_type] ?? IconPencil;
  return (
    <Box
      p="sm"
      style={{
        border: `1px solid var(--mantine-color-${changeColors[sc.change_type] ?? "gray"}-3)`,
        borderRadius: "var(--mantine-radius-sm)",
        borderLeft: `4px solid var(--mantine-color-${changeColors[sc.change_type] ?? "gray"}-5)`,
      }}
    >
      <Group gap="xs" mb="xs">
        <ThemeIcon
          size="sm"
          variant="light"
          color={changeColors[sc.change_type] ?? "gray"}
        >
          <Icon size={12} />
        </ThemeIcon>
        <Text size="sm" fw={500}>
          {sc.name}
        </Text>
        <Text size="xs" c="dimmed" ff="monospace">
          {sc.code}
        </Text>
        <Badge
          size="xs"
          color={changeColors[sc.change_type] ?? "gray"}
          variant="light"
        >
          {sc.change_type}
        </Badge>
      </Group>

      {sc.field_changes.length > 0 && (
        <Table
          horizontalSpacing="xs"
          verticalSpacing={4}
          withTableBorder={false}
        >
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Code</Table.Th>
              <Table.Th>Name</Table.Th>
              <Table.Th>Change</Table.Th>
              <Table.Th>Details</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {sc.field_changes.map((fc) => (
              <FieldChangeRow key={fc.field_code} fc={fc} />
            ))}
          </Table.Tbody>
        </Table>
      )}
    </Box>
  );
}

interface Props {
  formId: string;
  v1: number;
  v2: number;
  opened: boolean;
  onClose: () => void;
}

export function VersionDiffView({ formId, v1, v2, opened, onClose }: Props) {
  const { data: diff, isLoading } = useQuery({
    queryKey: ["form-diff", formId, v1, v2],
    queryFn: () => api.adminDiffFormVersions(formId, v1, v2),
    enabled: opened && v1 !== v2,
  });

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title="Version Comparison"
      size="xl"
      fullScreen
    >
      <Stack gap="md">
        <Group>
          <Badge variant="filled" color="blue">
            v{v1 === 0 ? "current" : v1}
          </Badge>
          <IconArrowRight size={16} />
          <Badge variant="filled" color="blue">
            v{v2 === 0 ? "current" : v2}
          </Badge>
        </Group>

        {isLoading && <Text c="dimmed">Loading diff...</Text>}

        {diff && (
          <>
            <Group gap="xs">
              {diff.summary.sections_added > 0 && (
                <Badge color="green" variant="light">
                  +{diff.summary.sections_added} sections
                </Badge>
              )}
              {diff.summary.sections_removed > 0 && (
                <Badge color="red" variant="light">
                  -{diff.summary.sections_removed} sections
                </Badge>
              )}
              {diff.summary.sections_modified > 0 && (
                <Badge color="yellow" variant="light">
                  ~{diff.summary.sections_modified} sections modified
                </Badge>
              )}
              {diff.summary.fields_added > 0 && (
                <Badge color="green" variant="light">
                  +{diff.summary.fields_added} fields
                </Badge>
              )}
              {diff.summary.fields_removed > 0 && (
                <Badge color="red" variant="light">
                  -{diff.summary.fields_removed} fields
                </Badge>
              )}
              {diff.summary.fields_modified > 0 && (
                <Badge color="yellow" variant="light">
                  ~{diff.summary.fields_modified} fields modified
                </Badge>
              )}
            </Group>

            {diff.section_changes.length === 0 && (
              <Text c="dimmed" size="sm">
                No differences found between these versions.
              </Text>
            )}

            {diff.section_changes.map((sc) => (
              <SectionChangeBlock key={sc.code} sc={sc} />
            ))}
          </>
        )}
      </Stack>
    </Modal>
  );
}
