import { Button, Group, Loader, Modal, Select, Stack, Text } from "@mantine/core";
import { useDisclosure } from "@mantine/hooks";
import { api } from "@medbrains/api";
import { IconAffiliate, IconLink, IconUnlink } from "@tabler/icons-react";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";

export function PipelineLinker({
  pipelineId,
  onChange,
}: {
  pipelineId: string | null;
  onChange: (id: string | null) => void;
}) {
  const [opened, { open, close }] = useDisclosure(false);
  const [selected, setSelected] = useState<string | null>(pipelineId);

  const { data: pipelines, isLoading } = useQuery({
    queryKey: ["admin-pipelines"],
    queryFn: () => api.listPipelines(),
    staleTime: 60_000,
    enabled: opened,
  });

  const pipelineList = pipelines?.pipelines ?? [];
  const pipelineOptions = pipelineList.map((p) => ({
    value: p.id,
    label: `${p.name} (${p.status})`,
  }));

  const handleConfirm = () => {
    onChange(selected);
    close();
  };

  const handleUnlink = () => {
    onChange(null);
  };

  return (
    <>
      <Group gap="xs">
        {pipelineId ? (
          <>
            <Text size="xs" c="dimmed" truncate style={{ flex: 1 }}>
              {pipelineId.slice(0, 8)}...
            </Text>
            <Button
              variant="light"
              size="compact-xs"
              leftSection={<IconLink size={12} />}
              onClick={open}
            >
              Change
            </Button>
            <Button
              variant="light"
              color="red"
              size="compact-xs"
              leftSection={<IconUnlink size={12} />}
              onClick={handleUnlink}
            >
              Unlink
            </Button>
          </>
        ) : (
          <Button
            variant="light"
            size="compact-xs"
            leftSection={<IconAffiliate size={14} />}
            onClick={open}
          >
            Link Pipeline
          </Button>
        )}
      </Group>

      <Modal opened={opened} onClose={close} title="Select Pipeline" size="sm">
        <Stack gap="md">
          {isLoading ? (
            <Loader size="sm" />
          ) : (
            <Select
              label="Pipeline"
              placeholder="Choose a pipeline..."
              data={pipelineOptions}
              value={selected}
              onChange={setSelected}
              searchable
              clearable
            />
          )}
          <Group justify="flex-end">
            <Button variant="light" onClick={close}>
              Cancel
            </Button>
            <Button onClick={handleConfirm}>Confirm</Button>
          </Group>
        </Stack>
      </Modal>
    </>
  );
}
