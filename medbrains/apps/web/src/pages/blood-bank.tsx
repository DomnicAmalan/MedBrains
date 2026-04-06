import { useMemo, useState } from "react";
import {
  ActionIcon,
  Badge,
  Button,
  Divider,
  Drawer,
  Group,
  NumberInput,
  Paper,
  SegmentedControl,
  Select,
  SimpleGrid,
  Stack,
  Table,
  Tabs,
  Text,
  TextInput,
  Textarea,
  Title,
  Tooltip,
} from "@mantine/core";
import { useDisclosure } from "@mantine/hooks";
import { notifications } from "@mantine/notifications";
import {
  IconAlertTriangle,
  IconDroplet,
  IconEye,
  IconPlus,
  IconTrash,
} from "@tabler/icons-react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@medbrains/api";
import { useHasPermission } from "@medbrains/stores";
import type {
  AdverseReaction,
  BloodComponent,
  BloodDonation,
  BloodDonor,
  CreateDonorRequest,
  CreateDonationRequest,
  CreateComponentRequest,
  CreateCrossmatchRequestBody,
  CreateTransfusionRequest,
  CrossmatchRequest,
  HemovigilanceRow,
  TransfusionRecord,
  TtiReportRow,
  UpdateDonationRequest,
} from "@medbrains/types";
import { P } from "@medbrains/types";
import { DataTable, PageHeader, StatusDot } from "../components";
import { useRequirePermission } from "../hooks/useRequirePermission";

const bagStatusColors: Record<string, string> = {
  collected: "gray",
  processing: "blue",
  tested: "cyan",
  available: "green",
  reserved: "yellow",
  crossmatched: "orange",
  issued: "teal",
  transfused: "violet",
  returned: "pink",
  expired: "red",
  discarded: "dark",
};

const crossmatchStatusColors: Record<string, string> = {
  requested: "blue",
  testing: "yellow",
  compatible: "green",
  incompatible: "red",
  issued: "teal",
  cancelled: "gray",
};

// ══════════════════════════════════════════════════════════
//  Main Page
// ══════════════════════════════════════════════════════════

export function BloodBankPage() {
  useRequirePermission(P.BLOOD_BANK.DONORS_LIST);

  return (
    <div>
      <PageHeader title="Blood Bank" subtitle="Donor management, inventory & transfusion" />
      <Tabs defaultValue="donors">
        <Tabs.List>
          <Tabs.Tab value="donors">Donors</Tabs.Tab>
          <Tabs.Tab value="inventory">Inventory</Tabs.Tab>
          <Tabs.Tab value="crossmatch">Crossmatch</Tabs.Tab>
          <Tabs.Tab value="transfusions">Transfusions</Tabs.Tab>
          <Tabs.Tab value="reports">Reports</Tabs.Tab>
        </Tabs.List>
        <Tabs.Panel value="donors"><DonorsTab /></Tabs.Panel>
        <Tabs.Panel value="inventory"><InventoryTab /></Tabs.Panel>
        <Tabs.Panel value="crossmatch"><CrossmatchTab /></Tabs.Panel>
        <Tabs.Panel value="transfusions"><TransfusionsTab /></Tabs.Panel>
        <Tabs.Panel value="reports"><ReportsTab /></Tabs.Panel>
      </Tabs>
    </div>
  );
}

// ══════════════════════════════════════════════════════════
//  Donors Tab
// ══════════════════════════════════════════════════════════

function DonorsTab() {
  const qc = useQueryClient();
  const canCreate = useHasPermission(P.BLOOD_BANK.DONORS_CREATE);
  const [createOpen, { open: openCreate, close: closeCreate }] = useDisclosure(false);
  const [detailDonor, setDetailDonor] = useState<BloodDonor | null>(null);
  const [bloodGroupFilter, setBloodGroupFilter] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  const params: Record<string, string> = { page: String(page), per_page: "20" };
  if (bloodGroupFilter) params.blood_group = bloodGroupFilter;

  const { data, isLoading } = useQuery({
    queryKey: ["blood-bank", "donors", params],
    queryFn: () => api.listBloodDonors(params),
  });

  const createMut = useMutation({
    mutationFn: (d: CreateDonorRequest) => api.createBloodDonor(d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank", "donors"] });
      closeCreate();
      notifications.show({ title: "Donor registered", message: "New blood donor added", color: "green" });
    },
  });

  const columns = [
    { key: "donor_number" as const, label: "Donor #", render: (d: BloodDonor) => d.donor_number },
    { key: "first_name" as const, label: "Name", render: (d: BloodDonor) => `${d.first_name} ${d.last_name}` },
    { key: "blood_group" as const, label: "Blood Group", render: (d: BloodDonor) => <Badge variant="light" color="red">{d.blood_group}</Badge> },
    { key: "total_donations" as const, label: "Donations", render: (d: BloodDonor) => String(d.total_donations) },
    { key: "is_deferred" as const, label: "Status", render: (d: BloodDonor) => d.is_deferred ? <Badge color="orange">Deferred</Badge> : <Badge color="green">Active</Badge> },
    {
      key: "id" as const,
      label: "",
      render: (d: BloodDonor) => (
        <Tooltip label="View details">
          <ActionIcon variant="subtle" onClick={() => setDetailDonor(d)}>
            <IconEye size={16} />
          </ActionIcon>
        </Tooltip>
      ),
    },
  ];

  return (
    <Stack mt="md">
      <Group>
        <Select
          placeholder="Blood group"
          data={["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]}
          clearable
          value={bloodGroupFilter}
          onChange={setBloodGroupFilter}
          w={160}
        />
        {canCreate && (
          <Button leftSection={<IconPlus size={16} />} onClick={openCreate}>
            Register Donor
          </Button>
        )}
      </Group>

      <DataTable
        columns={columns}
        data={data?.donors ?? []}
        loading={isLoading}
        rowKey={(d) => d.id}
        page={page}
        totalPages={data ? Math.ceil(data.total / data.per_page) : 1}
        onPageChange={setPage}
      />

      {/* Create Donor Drawer */}
      <Drawer opened={createOpen} onClose={closeCreate} title="Register Blood Donor" position="right" size="md">
        <CreateDonorForm
          onSubmit={(d) => createMut.mutate(d)}
          loading={createMut.isPending}
        />
      </Drawer>

      {/* Donor Detail Drawer */}
      <Drawer opened={!!detailDonor} onClose={() => setDetailDonor(null)} title="Donor Details" position="right" size="lg">
        {detailDonor && <DonorDetail donor={detailDonor} />}
      </Drawer>
    </Stack>
  );
}

function CreateDonorForm({ onSubmit, loading }: { onSubmit: (d: CreateDonorRequest) => void; loading: boolean }) {
  const [donorNumber, setDonorNumber] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [bloodGroup, setBloodGroup] = useState<string | null>(null);
  const [phone, setPhone] = useState("");
  const [gender, setGender] = useState<string | null>(null);

  return (
    <Stack>
      <TextInput label="Donor Number" required value={donorNumber} onChange={(e) => setDonorNumber(e.currentTarget.value)} />
      <Group grow>
        <TextInput label="First Name" required value={firstName} onChange={(e) => setFirstName(e.currentTarget.value)} />
        <TextInput label="Last Name" required value={lastName} onChange={(e) => setLastName(e.currentTarget.value)} />
      </Group>
      <Select label="Blood Group" required data={["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]} value={bloodGroup} onChange={setBloodGroup} />
      <Select label="Gender" data={["male", "female", "other"]} value={gender} onChange={setGender} clearable />
      <TextInput label="Phone" value={phone} onChange={(e) => setPhone(e.currentTarget.value)} />
      <Button
        onClick={() => {
          if (!donorNumber || !firstName || !lastName || !bloodGroup) return;
          onSubmit({
            donor_number: donorNumber,
            first_name: firstName,
            last_name: lastName,
            blood_group: bloodGroup,
            phone: phone || undefined,
            gender: gender ?? undefined,
          });
        }}
        loading={loading}
      >
        Register
      </Button>
    </Stack>
  );
}

function parseAdverseReaction(raw: string | null): AdverseReaction | null {
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AdverseReaction;
  } catch {
    return null;
  }
}

const reactionTypeLabels: Record<string, string> = {
  vasovagal: "Vasovagal",
  hematoma: "Hematoma",
  nerve_injury: "Nerve Injury",
  citrate_reaction: "Citrate Reaction",
  allergic: "Allergic",
  other: "Other",
};

function DonorDetail({ donor }: { donor: BloodDonor }) {
  const qc = useQueryClient();
  const canCreate = useHasPermission(P.BLOOD_BANK.DONORS_CREATE);
  const [donateOpen, { open: openDonate, close: closeDonate }] = useDisclosure(false);
  const [reactionDonation, setReactionDonation] = useState<BloodDonation | null>(null);

  const { data: donations } = useQuery({
    queryKey: ["blood-bank", "donations", donor.id],
    queryFn: () => api.listDonations(donor.id),
  });

  const donateMut = useMutation({
    mutationFn: (d: CreateDonationRequest) => api.createDonation(donor.id, d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank"] });
      closeDonate();
      notifications.show({ title: "Donation recorded", message: "Blood donation has been recorded", color: "green" });
    },
  });

  const reactionMut = useMutation({
    mutationFn: ({ donationId, data }: { donationId: string; data: UpdateDonationRequest }) =>
      api.updateDonation(donationId, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank", "donations", donor.id] });
      setReactionDonation(null);
      notifications.show({ title: "Reaction documented", message: "Adverse reaction has been recorded", color: "orange" });
    },
  });

  return (
    <Stack>
      <Group>
        <Text fw={700}>{donor.first_name} {donor.last_name}</Text>
        <Badge color="red" variant="light">{donor.blood_group}</Badge>
        {donor.is_deferred && <Badge color="orange">Deferred until {donor.deferral_until}</Badge>}
      </Group>
      <Table>
        <Table.Tbody>
          <Table.Tr><Table.Td>Donor #</Table.Td><Table.Td>{donor.donor_number}</Table.Td></Table.Tr>
          <Table.Tr><Table.Td>Phone</Table.Td><Table.Td>{donor.phone ?? "—"}</Table.Td></Table.Tr>
          <Table.Tr><Table.Td>Total Donations</Table.Td><Table.Td>{donor.total_donations}</Table.Td></Table.Tr>
          <Table.Tr><Table.Td>Last Donation</Table.Td><Table.Td>{donor.last_donation ? new Date(donor.last_donation).toLocaleDateString() : "—"}</Table.Td></Table.Tr>
        </Table.Tbody>
      </Table>

      {canCreate && (
        <Button leftSection={<IconDroplet size={16} />} variant="light" onClick={openDonate}>
          Record Donation
        </Button>
      )}

      <Text fw={600} mt="md">Donation History</Text>
      {donations?.length ? (
        <Table>
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Bag #</Table.Th>
              <Table.Th>Type</Table.Th>
              <Table.Th>Volume</Table.Th>
              <Table.Th>Date</Table.Th>
              <Table.Th>Reaction</Table.Th>
              {canCreate && <Table.Th>Actions</Table.Th>}
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {donations.map((d) => {
              const reaction = parseAdverseReaction(d.adverse_reaction);
              return (
                <Table.Tr key={d.id}>
                  <Table.Td>{d.bag_number}</Table.Td>
                  <Table.Td>{d.donation_type}</Table.Td>
                  <Table.Td>{d.volume_ml} ml</Table.Td>
                  <Table.Td>{new Date(d.donated_at).toLocaleDateString()}</Table.Td>
                  <Table.Td>
                    {reaction ? (
                      <Tooltip label={`${reactionTypeLabels[reaction.reaction_type] ?? reaction.reaction_type} — ${reaction.severity} — ${reaction.outcome}`}>
                        <Badge color="red" variant="light" leftSection={<IconAlertTriangle size={12} />}>
                          Adverse Reaction
                        </Badge>
                      </Tooltip>
                    ) : (
                      <Text c="dimmed" size="sm">None</Text>
                    )}
                  </Table.Td>
                  {canCreate && (
                    <Table.Td>
                      {!reaction && (
                        <Button
                          size="compact-xs"
                          variant="light"
                          color="red"
                          leftSection={<IconAlertTriangle size={12} />}
                          onClick={() => setReactionDonation(d)}
                        >
                          Adverse Reaction
                        </Button>
                      )}
                    </Table.Td>
                  )}
                </Table.Tr>
              );
            })}
          </Table.Tbody>
        </Table>
      ) : (
        <Text c="dimmed" size="sm">No donations recorded yet</Text>
      )}

      <Drawer opened={donateOpen} onClose={closeDonate} title="Record Donation" position="right" size="md">
        <CreateDonationForm onSubmit={(d) => donateMut.mutate(d)} loading={donateMut.isPending} />
      </Drawer>

      <Drawer
        opened={!!reactionDonation}
        onClose={() => setReactionDonation(null)}
        title="Document Adverse Reaction"
        position="right"
        size="md"
      >
        {reactionDonation && (
          <AdverseReactionForm
            donation={reactionDonation}
            onSubmit={(reaction) =>
              reactionMut.mutate({
                donationId: reactionDonation.id,
                data: { adverse_reaction: JSON.stringify(reaction) },
              })
            }
            loading={reactionMut.isPending}
          />
        )}
      </Drawer>
    </Stack>
  );
}

function CreateDonationForm({ onSubmit, loading }: { onSubmit: (d: CreateDonationRequest) => void; loading: boolean }) {
  const [bagNumber, setBagNumber] = useState("");
  const [donationType, setDonationType] = useState<string | null>("whole_blood");
  const [volumeMl, setVolumeMl] = useState<number>(450);
  const [campName, setCampName] = useState("");
  const [notes, setNotes] = useState("");

  return (
    <Stack>
      <TextInput label="Bag Number" required value={bagNumber} onChange={(e) => setBagNumber(e.currentTarget.value)} />
      <Select
        label="Donation Type"
        data={[
          { value: "whole_blood", label: "Whole Blood" },
          { value: "apheresis_platelets", label: "Apheresis Platelets" },
          { value: "apheresis_plasma", label: "Apheresis Plasma" },
        ]}
        value={donationType}
        onChange={setDonationType}
      />
      <NumberInput label="Volume (ml)" value={volumeMl} onChange={(v) => setVolumeMl(Number(v))} min={50} max={600} />
      <TextInput label="Camp Name" value={campName} onChange={(e) => setCampName(e.currentTarget.value)} />
      <Textarea label="Notes" value={notes} onChange={(e) => setNotes(e.currentTarget.value)} />
      <Button
        onClick={() => {
          if (!bagNumber) return;
          onSubmit({
            bag_number: bagNumber,
            donation_type: (donationType as CreateDonationRequest["donation_type"]) ?? undefined,
            volume_ml: volumeMl,
            camp_name: campName || undefined,
            notes: notes || undefined,
          });
        }}
        loading={loading}
      >
        Record Donation
      </Button>
    </Stack>
  );
}

function AdverseReactionForm({
  donation,
  onSubmit,
  loading,
}: {
  donation: BloodDonation;
  onSubmit: (reaction: AdverseReaction) => void;
  loading: boolean;
}) {
  const [reactionType, setReactionType] = useState<string | null>(null);
  const [severity, setSeverity] = useState<string | null>(null);
  const [description, setDescription] = useState("");
  const [treatmentGiven, setTreatmentGiven] = useState("");
  const [outcome, setOutcome] = useState<string | null>(null);

  return (
    <Stack>
      <Paper p="sm" withBorder>
        <Text size="sm" c="dimmed">Donation: <strong>{donation.bag_number}</strong> on {new Date(donation.donated_at).toLocaleDateString()}</Text>
      </Paper>
      <Select
        label="Reaction Type"
        required
        data={[
          { value: "vasovagal", label: "Vasovagal" },
          { value: "hematoma", label: "Hematoma" },
          { value: "nerve_injury", label: "Nerve Injury" },
          { value: "citrate_reaction", label: "Citrate Reaction" },
          { value: "allergic", label: "Allergic" },
          { value: "other", label: "Other" },
        ]}
        value={reactionType}
        onChange={setReactionType}
      />
      <Select
        label="Severity"
        required
        data={[
          { value: "mild", label: "Mild" },
          { value: "moderate", label: "Moderate" },
          { value: "severe", label: "Severe" },
        ]}
        value={severity}
        onChange={setSeverity}
      />
      <Textarea
        label="Description"
        required
        placeholder="Describe the adverse reaction..."
        value={description}
        onChange={(e) => setDescription(e.currentTarget.value)}
        minRows={3}
      />
      <Textarea
        label="Treatment Given"
        required
        placeholder="Describe the treatment administered..."
        value={treatmentGiven}
        onChange={(e) => setTreatmentGiven(e.currentTarget.value)}
        minRows={2}
      />
      <Select
        label="Outcome"
        required
        data={[
          { value: "resolved", label: "Resolved" },
          { value: "referred", label: "Referred" },
          { value: "hospitalized", label: "Hospitalized" },
        ]}
        value={outcome}
        onChange={setOutcome}
      />
      <Button
        color="red"
        onClick={() => {
          if (!reactionType || !severity || !description || !treatmentGiven || !outcome) return;
          onSubmit({
            reaction_type: reactionType as AdverseReaction["reaction_type"],
            severity: severity as AdverseReaction["severity"],
            description,
            treatment_given: treatmentGiven,
            outcome: outcome as AdverseReaction["outcome"],
          });
        }}
        loading={loading}
      >
        Save Adverse Reaction
      </Button>
    </Stack>
  );
}

// ══════════════════════════════════════════════════════════
//  Inventory Tab
// ══════════════════════════════════════════════════════════

const discardReasonLabels: Record<string, string> = {
  expired: "Expired",
  contaminated: "Contaminated",
  tti_positive: "TTI Positive",
  processing_failure: "Processing Failure",
  storage_failure: "Storage Failure",
  damaged: "Damaged",
  other: "Other",
};

function InventoryTab() {
  const qc = useQueryClient();
  const canManage = useHasPermission(P.BLOOD_BANK.INVENTORY_MANAGE);
  const [createOpen, { open: openCreate, close: closeCreate }] = useDisclosure(false);
  const [discardComponent, setDiscardComponent] = useState<BloodComponent | null>(null);
  const [statusFilter, setStatusFilter] = useState<string | null>(null);
  const [bgFilter, setBgFilter] = useState<string | null>(null);
  const [ctFilter, setCtFilter] = useState<string | null>(null);
  const [inventoryView, setInventoryView] = useState("active");

  const params: Record<string, string> = {};
  if (statusFilter) params.status = statusFilter;
  if (bgFilter) params.blood_group = bgFilter;
  if (ctFilter) params.component_type = ctFilter;

  const { data: components, isLoading } = useQuery({
    queryKey: ["blood-bank", "components", params],
    queryFn: () => api.listBloodComponents(params),
  });

  // Also fetch all components (unfiltered) for the discard report
  const { data: allComponents } = useQuery({
    queryKey: ["blood-bank", "components", {}],
    queryFn: () => api.listBloodComponents(),
  });

  const discardedComponents = useMemo(
    () => (allComponents ?? []).filter((c) => c.discarded_at !== null),
    [allComponents],
  );

  const discardStats = useMemo(() => {
    const stats: Record<string, number> = {};
    for (const c of discardedComponents) {
      const reason = c.discard_reason ?? "unknown";
      stats[reason] = (stats[reason] ?? 0) + 1;
    }
    return stats;
  }, [discardedComponents]);

  const statusMut = useMutation({
    mutationFn: ({ id, status, discard_reason }: { id: string; status: string; discard_reason?: string }) =>
      api.updateComponentStatus(id, { status: status as BloodComponent["status"], discard_reason }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank", "components"] });
      setDiscardComponent(null);
      notifications.show({ title: "Status updated", message: "Component status changed", color: "green" });
    },
  });

  const canDiscard = (c: BloodComponent) =>
    c.status !== "transfused" && c.status !== "discarded";

  const columns = [
    { key: "bag_number" as const, label: "Bag #", render: (c: BloodComponent) => c.bag_number },
    { key: "component_type" as const, label: "Component", render: (c: BloodComponent) => c.component_type.toUpperCase() },
    { key: "blood_group" as const, label: "Group", render: (c: BloodComponent) => <Badge variant="light" color="red">{c.blood_group}</Badge> },
    { key: "volume_ml" as const, label: "Volume", render: (c: BloodComponent) => `${c.volume_ml} ml` },
    { key: "status" as const, label: "Status", render: (c: BloodComponent) => <StatusDot label={c.status} color={bagStatusColors[c.status] ?? "gray"} /> },
    { key: "expiry_at" as const, label: "Expiry", render: (c: BloodComponent) => new Date(c.expiry_at).toLocaleDateString() },
    ...(canManage ? [{
      key: "id" as const,
      label: "Actions",
      render: (c: BloodComponent) => (
        <Group gap={4}>
          {c.status === "collected" && (
            <Button size="compact-xs" variant="light" onClick={() => statusMut.mutate({ id: c.id, status: "available" })}>
              Mark Available
            </Button>
          )}
          {c.status === "available" && (
            <Button size="compact-xs" variant="light" color="orange" onClick={() => statusMut.mutate({ id: c.id, status: "reserved" })}>
              Reserve
            </Button>
          )}
          {canDiscard(c) && (
            <Tooltip label="Discard component">
              <ActionIcon variant="subtle" color="red" size="sm" onClick={() => setDiscardComponent(c)}>
                <IconTrash size={14} />
              </ActionIcon>
            </Tooltip>
          )}
        </Group>
      ),
    }] : []),
  ];

  const discardColumns = [
    { key: "bag_number" as const, label: "Bag #", render: (c: BloodComponent) => c.bag_number },
    { key: "component_type" as const, label: "Component", render: (c: BloodComponent) => c.component_type.toUpperCase() },
    { key: "blood_group" as const, label: "Group", render: (c: BloodComponent) => <Badge variant="light" color="red">{c.blood_group}</Badge> },
    { key: "volume_ml" as const, label: "Volume", render: (c: BloodComponent) => `${c.volume_ml} ml` },
    { key: "discard_reason" as const, label: "Reason", render: (c: BloodComponent) => <Badge color="dark" variant="light">{discardReasonLabels[c.discard_reason ?? ""] ?? c.discard_reason ?? "—"}</Badge> },
    { key: "discarded_at" as const, label: "Discarded On", render: (c: BloodComponent) => c.discarded_at ? new Date(c.discarded_at).toLocaleDateString() : "—" },
  ];

  return (
    <Stack mt="md">
      <SegmentedControl
        value={inventoryView}
        onChange={setInventoryView}
        data={[
          { value: "active", label: "Active Inventory" },
          { value: "discards", label: `Discard Report (${discardedComponents.length})` },
        ]}
        w={360}
      />

      {inventoryView === "active" && (
        <>
          <Group>
            <Select placeholder="Status" data={["collected", "processing", "tested", "available", "reserved", "crossmatched", "issued", "expired"]} clearable value={statusFilter} onChange={setStatusFilter} w={160} />
            <Select placeholder="Blood group" data={["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]} clearable value={bgFilter} onChange={setBgFilter} w={140} />
            <Select placeholder="Component" data={[
              { value: "whole_blood", label: "Whole Blood" },
              { value: "prbc", label: "PRBC" },
              { value: "ffp", label: "FFP" },
              { value: "platelets", label: "Platelets" },
              { value: "cryoprecipitate", label: "Cryo" },
            ]} clearable value={ctFilter} onChange={setCtFilter} w={160} />
            {canManage && (
              <Button leftSection={<IconPlus size={16} />} onClick={openCreate}>
                Add Component
              </Button>
            )}
          </Group>

          <DataTable
            columns={columns}
            data={components ?? []}
            loading={isLoading}
            rowKey={(c) => c.id}
          />
        </>
      )}

      {inventoryView === "discards" && (
        <>
          {Object.keys(discardStats).length > 0 && (
            <SimpleGrid cols={{ base: 2, sm: 3, md: 4 }}>
              {Object.entries(discardStats).map(([reason, count]) => (
                <Paper key={reason} p="sm" withBorder>
                  <Text size="xs" c="dimmed">{discardReasonLabels[reason] ?? reason}</Text>
                  <Title order={4}>{count}</Title>
                </Paper>
              ))}
              <Paper p="sm" withBorder>
                <Text size="xs" c="dimmed">Total Discarded</Text>
                <Title order={4} c="red">{discardedComponents.length}</Title>
              </Paper>
            </SimpleGrid>
          )}
          <Divider />
          <DataTable
            columns={discardColumns}
            data={discardedComponents}
            loading={isLoading}
            rowKey={(c) => c.id}
          />
          {discardedComponents.length === 0 && (
            <Text c="dimmed" size="sm" ta="center">No discarded components found</Text>
          )}
        </>
      )}

      <Drawer opened={createOpen} onClose={closeCreate} title="Add Blood Component" position="right" size="md">
        <CreateComponentForm
          onSubmit={(d) => {
            api.createBloodComponent(d).then(() => {
              qc.invalidateQueries({ queryKey: ["blood-bank", "components"] });
              closeCreate();
              notifications.show({ title: "Component added", message: "Blood component registered", color: "green" });
            });
          }}
        />
      </Drawer>

      <Drawer
        opened={!!discardComponent}
        onClose={() => setDiscardComponent(null)}
        title="Discard Blood Component"
        position="right"
        size="md"
      >
        {discardComponent && (
          <DiscardComponentForm
            component={discardComponent}
            onSubmit={(reason, notes) =>
              statusMut.mutate({
                id: discardComponent.id,
                status: "discarded",
                discard_reason: notes ? `${reason}: ${notes}` : reason,
              })
            }
            loading={statusMut.isPending}
          />
        )}
      </Drawer>
    </Stack>
  );
}

function CreateComponentForm({ onSubmit }: { onSubmit: (d: CreateComponentRequest) => void }) {
  const [donationId, setDonationId] = useState("");
  const [componentType, setComponentType] = useState<string | null>("prbc");
  const [bagNumber, setBagNumber] = useState("");
  const [bloodGroup, setBloodGroup] = useState<string | null>(null);
  const [volumeMl, setVolumeMl] = useState<number>(300);
  const [expiryAt, setExpiryAt] = useState("");
  const [storageLocation, setStorageLocation] = useState("");

  return (
    <Stack>
      <TextInput label="Donation ID" required value={donationId} onChange={(e) => setDonationId(e.currentTarget.value)} placeholder="UUID of the donation" />
      <Select label="Component Type" required data={[
        { value: "whole_blood", label: "Whole Blood" },
        { value: "prbc", label: "PRBC" },
        { value: "ffp", label: "FFP" },
        { value: "platelets", label: "Platelets" },
        { value: "cryoprecipitate", label: "Cryoprecipitate" },
        { value: "granulocytes", label: "Granulocytes" },
      ]} value={componentType} onChange={setComponentType} />
      <TextInput label="Bag Number" required value={bagNumber} onChange={(e) => setBagNumber(e.currentTarget.value)} />
      <Select label="Blood Group" required data={["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]} value={bloodGroup} onChange={setBloodGroup} />
      <NumberInput label="Volume (ml)" value={volumeMl} onChange={(v) => setVolumeMl(Number(v))} min={50} max={600} />
      <TextInput label="Expiry Date" required placeholder="YYYY-MM-DD" value={expiryAt} onChange={(e) => setExpiryAt(e.currentTarget.value)} />
      <TextInput label="Storage Location" value={storageLocation} onChange={(e) => setStorageLocation(e.currentTarget.value)} />
      <Button
        onClick={() => {
          if (!donationId || !componentType || !bagNumber || !bloodGroup || !expiryAt) return;
          onSubmit({
            donation_id: donationId,
            component_type: componentType as CreateComponentRequest["component_type"],
            bag_number: bagNumber,
            blood_group: bloodGroup,
            volume_ml: volumeMl,
            expiry_at: expiryAt,
            storage_location: storageLocation || undefined,
          });
        }}
      >
        Add Component
      </Button>
    </Stack>
  );
}

function DiscardComponentForm({
  component,
  onSubmit,
  loading,
}: {
  component: BloodComponent;
  onSubmit: (reason: string, notes: string) => void;
  loading: boolean;
}) {
  const [reason, setReason] = useState<string | null>(null);
  const [notes, setNotes] = useState("");

  return (
    <Stack>
      <Paper p="sm" withBorder>
        <Text size="sm" c="dimmed">
          Component: <strong>{component.bag_number}</strong> ({component.component_type.toUpperCase()})
        </Text>
        <Text size="sm" c="dimmed">
          Blood Group: <strong>{component.blood_group}</strong> | Volume: <strong>{component.volume_ml} ml</strong>
        </Text>
        <Text size="sm" c="dimmed">
          Expiry: {new Date(component.expiry_at).toLocaleDateString()}
        </Text>
      </Paper>
      <Select
        label="Discard Reason"
        required
        data={[
          { value: "expired", label: "Expired" },
          { value: "contaminated", label: "Contaminated" },
          { value: "tti_positive", label: "TTI Positive" },
          { value: "processing_failure", label: "Processing Failure" },
          { value: "storage_failure", label: "Storage Failure" },
          { value: "damaged", label: "Damaged" },
          { value: "other", label: "Other" },
        ]}
        value={reason}
        onChange={setReason}
      />
      <Textarea
        label="Notes"
        placeholder="Additional details about the discard..."
        value={notes}
        onChange={(e) => setNotes(e.currentTarget.value)}
        minRows={3}
      />
      <Button
        color="red"
        leftSection={<IconTrash size={16} />}
        onClick={() => {
          if (!reason) return;
          onSubmit(reason, notes);
        }}
        loading={loading}
      >
        Confirm Discard
      </Button>
    </Stack>
  );
}

// ══════════════════════════════════════════════════════════
//  Crossmatch Tab
// ══════════════════════════════════════════════════════════

function CrossmatchTab() {
  const qc = useQueryClient();
  const canCreate = useHasPermission(P.BLOOD_BANK.CROSSMATCH_CREATE);
  const [createOpen, { open: openCreate, close: closeCreate }] = useDisclosure(false);

  const { data: requests, isLoading } = useQuery({
    queryKey: ["blood-bank", "crossmatch"],
    queryFn: () => api.listCrossmatchRequests(),
  });

  const createMut = useMutation({
    mutationFn: (d: CreateCrossmatchRequestBody) => api.createCrossmatchRequest(d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank", "crossmatch"] });
      closeCreate();
      notifications.show({ title: "Request created", message: "Crossmatch request submitted", color: "green" });
    },
  });

  const updateMut = useMutation({
    mutationFn: ({ id, status, result }: { id: string; status: string; result?: string }) =>
      api.updateCrossmatchRequest(id, { status: status as CrossmatchRequest["status"], result }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank", "crossmatch"] });
      notifications.show({ title: "Updated", message: "Crossmatch request updated", color: "green" });
    },
  });

  const columns = [
    { key: "blood_group" as const, label: "Group", render: (r: CrossmatchRequest) => <Badge variant="light" color="red">{r.blood_group}</Badge> },
    { key: "component_type" as const, label: "Component", render: (r: CrossmatchRequest) => r.component_type.toUpperCase() },
    { key: "units_requested" as const, label: "Units", render: (r: CrossmatchRequest) => String(r.units_requested) },
    { key: "status" as const, label: "Status", render: (r: CrossmatchRequest) => <StatusDot label={r.status} color={crossmatchStatusColors[r.status] ?? "gray"} /> },
    { key: "result" as const, label: "Result", render: (r: CrossmatchRequest) => r.result ?? "—" },
    { key: "created_at" as const, label: "Requested", render: (r: CrossmatchRequest) => new Date(r.created_at).toLocaleDateString() },
    ...(canCreate ? [{
      key: "id" as const,
      label: "Actions",
      render: (r: CrossmatchRequest) => (
        <Group gap={4}>
          {r.status === "requested" && (
            <Button size="compact-xs" variant="light" onClick={() => updateMut.mutate({ id: r.id, status: "testing" })}>
              Start Testing
            </Button>
          )}
          {r.status === "testing" && (
            <>
              <Button size="compact-xs" variant="light" color="green" onClick={() => updateMut.mutate({ id: r.id, status: "compatible", result: "compatible" })}>
                Compatible
              </Button>
              <Button size="compact-xs" variant="light" color="red" onClick={() => updateMut.mutate({ id: r.id, status: "incompatible", result: "incompatible" })}>
                Incompatible
              </Button>
            </>
          )}
        </Group>
      ),
    }] : []),
  ];

  return (
    <Stack mt="md">
      <Group>
        {canCreate && (
          <Button leftSection={<IconPlus size={16} />} onClick={openCreate}>
            New Crossmatch Request
          </Button>
        )}
      </Group>

      <DataTable
        columns={columns}
        data={requests ?? []}
        loading={isLoading}
        rowKey={(r) => r.id}
      />

      <Drawer opened={createOpen} onClose={closeCreate} title="New Crossmatch Request" position="right" size="md">
        <CreateCrossmatchForm onSubmit={(d) => createMut.mutate(d)} loading={createMut.isPending} />
      </Drawer>
    </Stack>
  );
}

function CreateCrossmatchForm({ onSubmit, loading }: { onSubmit: (d: CreateCrossmatchRequestBody) => void; loading: boolean }) {
  const [patientId, setPatientId] = useState("");
  const [bloodGroup, setBloodGroup] = useState<string | null>(null);
  const [componentType, setComponentType] = useState<string | null>("prbc");
  const [units, setUnits] = useState<number>(1);
  const [indication, setIndication] = useState("");

  return (
    <Stack>
      <TextInput label="Patient ID" required value={patientId} onChange={(e) => setPatientId(e.currentTarget.value)} placeholder="Patient UUID" />
      <Select label="Blood Group" required data={["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]} value={bloodGroup} onChange={setBloodGroup} />
      <Select label="Component Type" data={[
        { value: "prbc", label: "PRBC" },
        { value: "whole_blood", label: "Whole Blood" },
        { value: "ffp", label: "FFP" },
        { value: "platelets", label: "Platelets" },
      ]} value={componentType} onChange={setComponentType} />
      <NumberInput label="Units Requested" value={units} onChange={(v) => setUnits(Number(v))} min={1} max={10} />
      <Textarea label="Clinical Indication" value={indication} onChange={(e) => setIndication(e.currentTarget.value)} />
      <Button
        onClick={() => {
          if (!patientId || !bloodGroup) return;
          onSubmit({
            patient_id: patientId,
            blood_group: bloodGroup,
            component_type: (componentType as CreateCrossmatchRequestBody["component_type"]) ?? undefined,
            units_requested: units,
            clinical_indication: indication || undefined,
          });
        }}
        loading={loading}
      >
        Submit Request
      </Button>
    </Stack>
  );
}

// ══════════════════════════════════════════════════════════
//  Transfusions Tab
// ══════════════════════════════════════════════════════════

function TransfusionsTab() {
  const qc = useQueryClient();
  const canCreate = useHasPermission(P.BLOOD_BANK.TRANSFUSION_CREATE);
  const [createOpen, { open: openCreate, close: closeCreate }] = useDisclosure(false);
  const [reactionId, setReactionId] = useState<string | null>(null);

  const { data: transfusions, isLoading } = useQuery({
    queryKey: ["blood-bank", "transfusions"],
    queryFn: () => api.listTransfusions(),
  });

  const createMut = useMutation({
    mutationFn: (d: CreateTransfusionRequest) => api.createTransfusion(d),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank"] });
      closeCreate();
      notifications.show({ title: "Transfusion recorded", message: "Blood transfusion started", color: "green" });
    },
  });

  const reactionMut = useMutation({
    mutationFn: ({ id, ...data }: { id: string; reaction_type: string; reaction_severity: string; reaction_details?: string }) =>
      api.recordTransfusionReaction(id, {
        reaction_type: data.reaction_type,
        reaction_severity: data.reaction_severity as TransfusionRecord["reaction_severity"] & string,
        reaction_details: data.reaction_details,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["blood-bank", "transfusions"] });
      setReactionId(null);
      notifications.show({ title: "Reaction recorded", message: "Transfusion reaction has been reported", color: "orange" });
    },
  });

  const columns = [
    { key: "started_at" as const, label: "Started", render: (t: TransfusionRecord) => new Date(t.started_at).toLocaleString() },
    { key: "component_id" as const, label: "Component", render: (t: TransfusionRecord) => t.component_id.slice(0, 8) },
    { key: "patient_id" as const, label: "Patient", render: (t: TransfusionRecord) => t.patient_id.slice(0, 8) },
    { key: "has_reaction" as const, label: "Reaction", render: (t: TransfusionRecord) => t.has_reaction ? <Badge color="red">Yes — {t.reaction_severity}</Badge> : <Badge color="green">None</Badge> },
    { key: "completed_at" as const, label: "Completed", render: (t: TransfusionRecord) => t.completed_at ? new Date(t.completed_at).toLocaleString() : "In progress" },
    ...(canCreate ? [{
      key: "id" as const,
      label: "Actions",
      render: (t: TransfusionRecord) => (
        <Group gap={4}>
          {!t.has_reaction && (
            <Button size="compact-xs" variant="light" color="red" onClick={() => setReactionId(t.id)}>
              Report Reaction
            </Button>
          )}
        </Group>
      ),
    }] : []),
  ];

  return (
    <Stack mt="md">
      <Group>
        {canCreate && (
          <Button leftSection={<IconPlus size={16} />} onClick={openCreate}>
            Record Transfusion
          </Button>
        )}
      </Group>

      <DataTable
        columns={columns}
        data={transfusions ?? []}
        loading={isLoading}
        rowKey={(t) => t.id}
      />

      <Drawer opened={createOpen} onClose={closeCreate} title="Record Transfusion" position="right" size="md">
        <CreateTransfusionForm onSubmit={(d) => createMut.mutate(d)} loading={createMut.isPending} />
      </Drawer>

      <Drawer opened={!!reactionId} onClose={() => setReactionId(null)} title="Report Transfusion Reaction" position="right" size="md">
        {reactionId && <RecordReactionForm onSubmit={(data) => reactionMut.mutate({ id: reactionId, ...data })} loading={reactionMut.isPending} />}
      </Drawer>
    </Stack>
  );
}

function CreateTransfusionForm({ onSubmit, loading }: { onSubmit: (d: CreateTransfusionRequest) => void; loading: boolean }) {
  const [patientId, setPatientId] = useState("");
  const [componentId, setComponentId] = useState("");
  const [crossmatchId, setCrossmatchId] = useState("");

  return (
    <Stack>
      <TextInput label="Patient ID" required value={patientId} onChange={(e) => setPatientId(e.currentTarget.value)} placeholder="Patient UUID" />
      <TextInput label="Component ID" required value={componentId} onChange={(e) => setComponentId(e.currentTarget.value)} placeholder="Blood component UUID" />
      <TextInput label="Crossmatch ID" value={crossmatchId} onChange={(e) => setCrossmatchId(e.currentTarget.value)} placeholder="Optional crossmatch UUID" />
      <Button
        onClick={() => {
          if (!patientId || !componentId) return;
          onSubmit({
            patient_id: patientId,
            component_id: componentId,
            crossmatch_id: crossmatchId || undefined,
          });
        }}
        loading={loading}
      >
        Start Transfusion
      </Button>
    </Stack>
  );
}

function RecordReactionForm({ onSubmit, loading }: { onSubmit: (data: { reaction_type: string; reaction_severity: string; reaction_details?: string }) => void; loading: boolean }) {
  const [reactionType, setReactionType] = useState("");
  const [severity, setSeverity] = useState<string | null>(null);
  const [details, setDetails] = useState("");

  return (
    <Stack>
      <TextInput label="Reaction Type" required value={reactionType} onChange={(e) => setReactionType(e.currentTarget.value)} placeholder="e.g. Febrile, Allergic, Hemolytic" />
      <Select label="Severity" required data={[
        { value: "mild", label: "Mild" },
        { value: "moderate", label: "Moderate" },
        { value: "severe", label: "Severe" },
        { value: "fatal", label: "Fatal" },
      ]} value={severity} onChange={setSeverity} />
      <Textarea label="Details" value={details} onChange={(e) => setDetails(e.currentTarget.value)} />
      <Button
        color="red"
        onClick={() => {
          if (!reactionType || !severity) return;
          onSubmit({
            reaction_type: reactionType,
            reaction_severity: severity,
            reaction_details: details || undefined,
          });
        }}
        loading={loading}
      >
        Report Reaction
      </Button>
    </Stack>
  );
}

// ══════════════════════════════════════════════════════════
//  Reports Tab (TTI + Hemovigilance)
// ══════════════════════════════════════════════════════════

const ttiStatusColors: Record<string, string> = {
  tested: "green",
  pending: "yellow",
  reactive: "red",
  non_reactive: "teal",
};

function ReportsTab() {
  const [reportView, setReportView] = useState("tti");

  return (
    <Stack mt="md">
      <SegmentedControl
        value={reportView}
        onChange={setReportView}
        data={[
          { value: "tti", label: "TTI Report" },
          { value: "hemovigilance", label: "Hemovigilance" },
        ]}
        w={320}
      />

      {reportView === "tti" && <TtiReportView />}
      {reportView === "hemovigilance" && <HemovigilanceView />}
    </Stack>
  );
}

function TtiReportView() {
  const { data, isLoading } = useQuery({
    queryKey: ["blood-bank", "tti-report"],
    queryFn: () => api.getTtiReport(),
  });

  const reactiveCount = useMemo(
    () => (data?.by_status ?? []).filter((r) => r.tti_status === "reactive").reduce((sum, r) => sum + r.count, 0),
    [data],
  );

  const reactivePct = data?.total_components
    ? ((reactiveCount / data.total_components) * 100).toFixed(2)
    : "0.00";

  const columns = [
    { key: "tti_status" as const, label: "TTI Status", render: (r: TtiReportRow) => <Badge color={ttiStatusColors[r.tti_status] ?? "gray"}>{r.tti_status.replace(/_/g, " ")}</Badge> },
    { key: "count" as const, label: "Count", render: (r: TtiReportRow) => String(r.count) },
  ];

  return (
    <Stack>
      <SimpleGrid cols={{ base: 1, sm: 3 }}>
        <Paper p="md" withBorder>
          <Text size="xs" c="dimmed">Total Components Tested</Text>
          <Title order={3}>{data?.total_components ?? 0}</Title>
        </Paper>
        <Paper p="md" withBorder>
          <Text size="xs" c="dimmed">Reactive</Text>
          <Title order={3} c="red">{reactiveCount}</Title>
        </Paper>
        <Paper p="md" withBorder>
          <Text size="xs" c="dimmed">Reactive Rate</Text>
          <Title order={3} c={Number(reactivePct) > 0 ? "red" : "green"}>{reactivePct}%</Title>
        </Paper>
      </SimpleGrid>

      <Divider />

      <DataTable
        columns={columns}
        data={data?.by_status ?? []}
        loading={isLoading}
        rowKey={(r) => r.tti_status}
      />
    </Stack>
  );
}

function HemovigilanceView() {
  const { data, isLoading } = useQuery({
    queryKey: ["blood-bank", "hemovigilance"],
    queryFn: () => api.getHemovigilanceReport(),
  });

  const columns = [
    { key: "reaction_type" as const, label: "Reaction Type", render: (r: HemovigilanceRow) => r.reaction_type ?? "Unknown" },
    { key: "severity" as const, label: "Severity", render: (r: HemovigilanceRow) => r.severity ? <Badge color={r.severity === "severe" || r.severity === "fatal" ? "red" : r.severity === "moderate" ? "orange" : "yellow"}>{r.severity}</Badge> : <Text size="sm" c="dimmed">N/A</Text> },
    { key: "count" as const, label: "Count", render: (r: HemovigilanceRow) => String(r.count) },
  ];

  return (
    <Stack>
      <SimpleGrid cols={{ base: 1, sm: 4 }}>
        <Paper p="md" withBorder>
          <Text size="xs" c="dimmed">Reporting Period</Text>
          <Title order={4}>{data?.reporting_period ?? "—"}</Title>
        </Paper>
        <Paper p="md" withBorder>
          <Text size="xs" c="dimmed">Total Transfusions</Text>
          <Title order={3}>{data?.total_transfusions ?? 0}</Title>
        </Paper>
        <Paper p="md" withBorder>
          <Text size="xs" c="dimmed">Total Reactions</Text>
          <Title order={3} c="red">{data?.total_reactions ?? 0}</Title>
        </Paper>
        <Paper p="md" withBorder>
          <Text size="xs" c="dimmed">Reaction Rate</Text>
          <Title order={3} c={data?.reaction_rate_percent && data.reaction_rate_percent > 0 ? "orange" : "green"}>
            {data?.reaction_rate_percent?.toFixed(2) ?? "0.00"}%
          </Title>
        </Paper>
      </SimpleGrid>

      <Divider />

      <DataTable
        columns={columns}
        data={data?.reactions_by_type ?? []}
        loading={isLoading}
        rowKey={(r) => `${r.reaction_type ?? "unknown"}-${r.severity ?? "unknown"}`}
      />
    </Stack>
  );
}
