import { Group, Stack, Text } from "@mantine/core";
import { useQuery } from "@tanstack/react-query";
import { api } from "@medbrains/api";

interface ModuleViewProps {
  module: string;
  viewMode: "stats" | "table" | "compact_list";
}

export function ModuleViews({ module, viewMode }: ModuleViewProps) {
  switch (module) {
    case "patients":
      return <PatientView viewMode={viewMode} />;
    case "opd":
      return <OpdView viewMode={viewMode} />;
    case "lab":
      return <LabView viewMode={viewMode} />;
    case "billing":
      return <BillingView viewMode={viewMode} />;
    case "ipd":
      return <IpdView viewMode={viewMode} />;
    default:
      return (
        <Text size="xs" c="dimmed" ta="center">
          Module: {module}
        </Text>
      );
  }
}

function PatientView({ viewMode }: { viewMode: string }) {
  const { data } = useQuery({
    queryKey: ["patients", 1, ""],
    queryFn: () => api.listPatients({ page: 1, per_page: 5 }),
  });

  if (viewMode === "stats") {
    return (
      <Stack gap={4}>
        <Text fz={24} fw={700} c="var(--mb-text-primary)">
          {data?.total ?? 0}
        </Text>
        <Text size="xs" c="var(--mb-text-muted)">Total Patients</Text>
      </Stack>
    );
  }

  return (
    <Stack gap={4}>
      {data?.patients.slice(0, 5).map((p) => (
        <Group key={p.id} justify="space-between">
          <Text size="xs">{p.first_name} {p.last_name}</Text>
          <Text size="xs" c="dimmed">{p.uhid}</Text>
        </Group>
      ))}
    </Stack>
  );
}

function OpdView({ viewMode }: { viewMode: string }) {
  return (
    <Text size="xs" c="dimmed" ta="center" py="sm">
      OPD {viewMode} view
    </Text>
  );
}

function LabView({ viewMode }: { viewMode: string }) {
  return (
    <Text size="xs" c="dimmed" ta="center" py="sm">
      Lab {viewMode} view
    </Text>
  );
}

function BillingView({ viewMode }: { viewMode: string }) {
  return (
    <Text size="xs" c="dimmed" ta="center" py="sm">
      Billing {viewMode} view
    </Text>
  );
}

function IpdView({ viewMode }: { viewMode: string }) {
  return (
    <Text size="xs" c="dimmed" ta="center" py="sm">
      IPD {viewMode} view
    </Text>
  );
}
