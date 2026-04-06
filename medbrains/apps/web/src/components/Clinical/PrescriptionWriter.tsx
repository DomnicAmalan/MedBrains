import { useMemo, useState } from "react";
import {
  ActionIcon,
  Alert,
  Badge,
  Button,
  Card,
  Collapse,
  Combobox,
  Group,
  InputBase,
  Menu,
  Modal,
  Select,
  Stack,
  Switch,
  Table,
  Text,
  TextInput,
  Textarea,
  Tooltip,
  useCombobox,
} from "@mantine/core";
import { useDisclosure } from "@mantine/hooks";
import { notifications } from "@mantine/notifications";
import {
  IconBookmark,
  IconChevronDown,
  IconChevronUp,
  IconDeviceFloppy,
  IconMedicineSyrup,
  IconPill,
  IconPlus,
  IconPrinter,
  IconTemplate,
  IconTrash,
  IconAlertTriangle,
  IconX,
} from "@tabler/icons-react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import { api } from "@medbrains/api";
import type {
  ComplianceSettings,
  CreatePrescriptionRequest,
  CreatePrescriptionTemplateRequest,
  DrugInteractionAlert,
  AllergyConflict,
  PharmacyCatalog,
  PrescriptionItemInput,
  PrescriptionTemplate,
  PrescriptionWithItems,
  TenantSettingsRow,
} from "@medbrains/types";
import styles from "./prescription-writer.module.scss";

const FREQUENCIES = [
  { value: "OD", label: "OD (Once daily)" },
  { value: "BD", label: "BD (Twice daily)" },
  { value: "TDS", label: "TDS (Thrice daily)" },
  { value: "QID", label: "QID (Four times)" },
  { value: "SOS", label: "SOS (As needed)" },
  { value: "PRN", label: "PRN (When required)" },
  { value: "STAT", label: "STAT (Immediately)" },
  { value: "HS", label: "HS (At bedtime)" },
];

const ROUTES = [
  { value: "Oral", label: "Oral" },
  { value: "IV", label: "IV" },
  { value: "IM", label: "IM" },
  { value: "SC", label: "SC" },
  { value: "Topical", label: "Topical" },
  { value: "Inhalation", label: "Inhalation" },
  { value: "Sublingual", label: "Sublingual" },
  { value: "Rectal", label: "Rectal" },
];

interface PrescriptionWriterProps {
  encounterId: string;
  patientId?: string;
  prescriptions: PrescriptionWithItems[];
  canUpdate: boolean;
  onSave: (data: CreatePrescriptionRequest) => void;
  isSaving?: boolean;
  onPrint?: (rx: PrescriptionWithItems) => void;
  onSendToPharmacy?: (rxId: string) => void;
}

export function PrescriptionWriter({
  patientId,
  prescriptions,
  canUpdate,
  onSave,
  isSaving,
  onPrint,
  onSendToPharmacy,
}: PrescriptionWriterProps) {
  const { t } = useTranslation("clinical");
  const queryClient = useQueryClient();
  const [showForm, { toggle: toggleForm, close: closeForm }] = useDisclosure(false);
  const [pendingItems, setPendingItems] = useState<PrescriptionItemInput[]>([]);
  const [rxNotes, setRxNotes] = useState("");
  const [notesOpen, { toggle: toggleNotes }] = useDisclosure(false);
  const [saveTemplateOpen, { open: openSaveTemplate, close: closeSaveTemplate }] = useDisclosure(false);
  const [templateName, setTemplateName] = useState("");
  const [templateDesc, setTemplateDesc] = useState("");
  const [templateShared, setTemplateShared] = useState(false);

  // Drug catalog
  const { data: drugCatalog = [] } = useQuery({
    queryKey: ["pharmacy-catalog"],
    queryFn: () => api.listPharmacyCatalog(),
    staleTime: 300_000,
  });

  // Compliance settings
  const { data: complianceRaw = [] } = useQuery<TenantSettingsRow[]>({
    queryKey: ["tenant-settings", "compliance"],
    queryFn: () => api.getTenantSettings("compliance"),
    staleTime: 300_000,
  });

  const compliance = useMemo(() => {
    const defaults: ComplianceSettings = {
      enforce_drug_scheduling: false,
      enforce_ndps_tracking: false,
      enforce_formulary: false,
      enforce_drug_interactions: false,
      enforce_antibiotic_stewardship: false,
      enforce_lasa_warnings: false,
      enforce_max_dose_check: false,
      enforce_batch_tracking: false,
      show_schedule_badges: true,
      show_controlled_warnings: true,
      show_formulary_status: true,
      show_aware_category: true,
    };
    for (const row of complianceRaw) {
      const key = row.key as keyof ComplianceSettings;
      if (key in defaults) {
        defaults[key] = row.value === true || row.value === "true";
      }
    }
    return defaults;
  }, [complianceRaw]);

  // Prescription templates
  const { data: templates = [] } = useQuery({
    queryKey: ["prescription-templates"],
    queryFn: () => api.listPrescriptionTemplates(),
    staleTime: 300_000,
  });

  const saveTemplateMutation = useMutation({
    mutationFn: (data: CreatePrescriptionTemplateRequest) => api.createPrescriptionTemplate(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["prescription-templates"] });
      notifications.show({ title: "Template saved", message: `"${templateName}" saved`, color: "green" });
      closeSaveTemplate();
      setTemplateName("");
      setTemplateDesc("");
      setTemplateShared(false);
    },
    onError: () => {
      notifications.show({ title: "Error", message: "Failed to save template", color: "red" });
    },
  });

  const deleteTemplateMutation = useMutation({
    mutationFn: (id: string) => api.deletePrescriptionTemplate(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["prescription-templates"] });
      notifications.show({ title: "Deleted", message: "Template removed", color: "yellow" });
    },
  });

  const handleLoadTemplate = (tpl: PrescriptionTemplate) => {
    setPendingItems(tpl.items);
    if (!showForm) toggleForm();
    notifications.show({ title: "Template loaded", message: `"${tpl.name}" loaded with ${tpl.items.length} items`, color: "blue" });
  };

  const handleSaveTemplate = () => {
    if (!templateName.trim() || pendingItems.length === 0) return;
    saveTemplateMutation.mutate({
      name: templateName.trim(),
      description: templateDesc.trim() || undefined,
      is_shared: templateShared,
      items: pendingItems,
    });
  };

  const combobox = useCombobox({
    onDropdownClose: () => combobox.resetSelectedOption(),
  });

  // Entry fields
  const [drugName, setDrugName] = useState("");
  const [drugSearch, setDrugSearch] = useState("");
  const [dosage, setDosage] = useState("");
  const [frequency, setFrequency] = useState<string | null>(null);
  const [duration, setDuration] = useState("");
  const [route, setRoute] = useState<string | null>(null);
  const [drugWarning, setDrugWarning] = useState<string | null>(null);

  const filteredDrugs = useMemo(() => {
    if (!drugSearch.trim()) return drugCatalog.filter((d: PharmacyCatalog) => d.is_active).slice(0, 20);
    const q = drugSearch.toLowerCase();
    return drugCatalog
      .filter((d: PharmacyCatalog) =>
        d.is_active && (
          d.name.toLowerCase().includes(q) ||
          d.code.toLowerCase().includes(q) ||
          (d.generic_name?.toLowerCase().includes(q) ?? false)
        )
      )
      .slice(0, 20);
  }, [drugCatalog, drugSearch]);

  const handleDrugSelect = (drugId: string) => {
    const drug = drugCatalog.find((d: PharmacyCatalog) => d.id === drugId);
    if (drug) {
      const label = drug.generic_name ? `${drug.name} (${drug.generic_name})` : drug.name;
      setDrugName(label);
      setDrugSearch(label);
      if (drug.unit && !dosage) setDosage(drug.unit);
    }
    combobox.closeDropdown();

    // Set warning for controlled/restricted drugs
    if (drug) {
      const warnings: string[] = [];
      if (compliance.show_controlled_warnings && drug.is_controlled) {
        warnings.push("Controlled substance \u2014 NDPS register required");
      }
      if (drug.drug_schedule === "X") {
        warnings.push("Schedule X \u2014 duplicate prescription required");
      }
      if (drug.formulary_status === "non_formulary" && compliance.enforce_formulary) {
        warnings.push("Non-formulary drug \u2014 DTC approval may be required");
      }
      if (drug.black_box_warning) {
        warnings.push(drug.black_box_warning);
      }
      setDrugWarning(warnings.length > 0 ? warnings.join(" \u2022 ") : null);
    }
  };

  const resetEntry = () => {
    setDrugName("");
    setDrugSearch("");
    setDosage("");
    setFrequency(null);
    setDuration("");
    setRoute(null);
    setDrugWarning(null);
  };

  const canAddItem = drugName.trim() && dosage.trim() && frequency && duration.trim();

  // Drug safety check state
  const [safetyAlerts, setSafetyAlerts] = useState<{
    interactions: DrugInteractionAlert[];
    allergy_conflicts: AllergyConflict[];
  }>({ interactions: [], allergy_conflicts: [] });

  const checkDrugSafety = async (items: PrescriptionItemInput[]) => {
    if (items.length === 0 || !compliance.enforce_drug_interactions) {
      setSafetyAlerts({ interactions: [], allergy_conflicts: [] });
      return;
    }
    try {
      const result = await api.checkDrugSafety({
        drug_names: items.map((i) => i.drug_name),
        patient_id: patientId,
      });
      setSafetyAlerts(result);
    } catch {
      // Silently fail — don't block prescription writing
    }
  };

  const handleAddItem = () => {
    if (!canAddItem) return;
    const item: PrescriptionItemInput = {
      drug_name: drugName.trim(),
      dosage: dosage.trim(),
      frequency: frequency as string,
      duration: duration.trim(),
      route: route ?? undefined,
    };
    const updated = [...pendingItems, item];
    setPendingItems(updated);
    resetEntry();
    checkDrugSafety(updated);
  };

  const handleRemoveItem = (index: number) => {
    const updated = pendingItems.filter((_, i) => i !== index);
    setPendingItems(updated);
    checkDrugSafety(updated);
  };

  const handleSave = () => {
    if (pendingItems.length === 0) return;
    onSave({
      notes: rxNotes.trim() || undefined,
      items: pendingItems,
    });
    setPendingItems([]);
    setRxNotes("");
    closeForm();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey && canAddItem) {
      e.preventDefault();
      handleAddItem();
    }
  };

  return (
    <Stack gap="sm">
      {canUpdate && (
        <Group>
          <Button
            size="xs"
            leftSection={<IconPlus size={14} />}
            onClick={toggleForm}
            variant={showForm ? "light" : "filled"}
          >
            {showForm ? t("common:cancel") : t("prescription.newPrescription")}
          </Button>
          {templates.length > 0 && (
            <Menu shadow="md" width={260}>
              <Menu.Target>
                <Button size="xs" variant="light" leftSection={<IconTemplate size={14} />}>
                  Templates
                </Button>
              </Menu.Target>
              <Menu.Dropdown>
                {templates.map((tpl: PrescriptionTemplate) => (
                  <Menu.Item
                    key={tpl.id}
                    leftSection={<IconBookmark size={14} />}
                    rightSection={
                      <ActionIcon
                        variant="subtle"
                        color="red"
                        size="xs"
                        onClick={(e) => {
                          e.stopPropagation();
                          deleteTemplateMutation.mutate(tpl.id);
                        }}
                      >
                        <IconTrash size={12} />
                      </ActionIcon>
                    }
                    onClick={() => handleLoadTemplate(tpl)}
                  >
                    <Text size="sm" fw={500}>{tpl.name}</Text>
                    <Text size="xs" c="dimmed">{tpl.items.length} items{tpl.is_shared ? " · Shared" : ""}</Text>
                  </Menu.Item>
                ))}
              </Menu.Dropdown>
            </Menu>
          )}
        </Group>
      )}

      {showForm && (
        <Card padding="sm" radius="md" withBorder className={styles.writerCard}>
          <Stack gap="xs">
            {/* Drug entry row */}
            <Group gap="xs" align="flex-end" wrap="nowrap">
              <Combobox
                store={combobox}
                onOptionSubmit={handleDrugSelect}
              >
                <Combobox.Target>
                  <InputBase
                    placeholder={t("prescription.drugName")}
                    value={drugSearch}
                    onChange={(e) => {
                      setDrugSearch(e.currentTarget.value);
                      setDrugName(e.currentTarget.value);
                      combobox.openDropdown();
                      combobox.updateSelectedOptionIndex();
                    }}
                    onFocus={() => combobox.openDropdown()}
                    onBlur={() => {
                      combobox.closeDropdown();
                      setDrugSearch(drugName);
                    }}
                    onKeyDown={handleKeyDown}
                    rightSectionPointerEvents="none"
                    style={{ flex: 1 }}
                    size="sm"
                  />
                </Combobox.Target>
                <Combobox.Dropdown>
                  <Combobox.Options>
                    {filteredDrugs.map((drug: PharmacyCatalog) => (
                      <Combobox.Option key={drug.id} value={drug.id}>
                        <Group gap={4} wrap="nowrap">
                          <div style={{ flex: 1 }}>
                            <Text size="sm" fw={500}>{drug.name}</Text>
                            {drug.generic_name && (
                              <Text size="xs" c="dimmed">{drug.generic_name}{drug.inn_name && drug.inn_name !== drug.generic_name ? ` (INN: ${drug.inn_name})` : ""}</Text>
                            )}
                          </div>
                          <Group gap={2}>
                            {compliance.show_schedule_badges && drug.drug_schedule && (
                              <Badge size="xs" variant="light" color={drug.drug_schedule === "X" || drug.drug_schedule === "NDPS" ? "red" : drug.drug_schedule === "H1" ? "orange" : "blue"}>
                                Sch-{drug.drug_schedule}
                              </Badge>
                            )}
                            {compliance.show_controlled_warnings && drug.is_controlled && (
                              <Badge size="xs" variant="filled" color="red">CTRL</Badge>
                            )}
                            {compliance.show_formulary_status && drug.formulary_status === "restricted" && (
                              <Badge size="xs" variant="light" color="yellow">Restricted</Badge>
                            )}
                            {compliance.show_formulary_status && drug.formulary_status === "non_formulary" && (
                              <Badge size="xs" variant="light" color="gray">Non-Formulary</Badge>
                            )}
                            {compliance.show_aware_category && drug.aware_category && (
                              <Badge size="xs" variant="light" color={drug.aware_category === "reserve" ? "red" : drug.aware_category === "watch" ? "orange" : "green"}>
                                {drug.aware_category.charAt(0).toUpperCase() + drug.aware_category.slice(1)}
                              </Badge>
                            )}
                          </Group>
                        </Group>
                      </Combobox.Option>
                    ))}
                    {filteredDrugs.length === 0 && drugSearch.trim() && (
                      <Combobox.Empty>
                        <Text size="xs">{t("prescription.typeCustomDrug")}</Text>
                      </Combobox.Empty>
                    )}
                  </Combobox.Options>
                </Combobox.Dropdown>
              </Combobox>
              <TextInput
                placeholder={t("prescription.dosage")}
                value={dosage}
                onChange={(e) => setDosage(e.currentTarget.value)}
                onKeyDown={handleKeyDown}
                w={100}
                size="sm"
              />
              <Select
                placeholder={t("prescription.frequency")}
                data={FREQUENCIES}
                value={frequency}
                onChange={setFrequency}
                w={160}
                size="sm"
                searchable
              />
              <TextInput
                placeholder={t("prescription.duration")}
                value={duration}
                onChange={(e) => setDuration(e.currentTarget.value)}
                onKeyDown={handleKeyDown}
                w={100}
                size="sm"
              />
              <Select
                placeholder={t("prescription.route")}
                data={ROUTES}
                value={route}
                onChange={setRoute}
                w={120}
                size="sm"
                clearable
              />
              <Button
                size="sm"
                leftSection={<IconPlus size={14} />}
                onClick={handleAddItem}
                disabled={!canAddItem}
              >
                {t("common:add")}
              </Button>
            </Group>

            {/* Drug regulatory warning */}
            {drugWarning && (
              <Text size="xs" c="red" fw={500}>
                {"\u26A0"} {drugWarning}
              </Text>
            )}

            {/* Drug interaction & allergy alerts */}
            {safetyAlerts.allergy_conflicts.length > 0 && (
              <Alert color="red" icon={<IconAlertTriangle size={16} />} title="Allergy Conflict Detected" variant="light">
                {safetyAlerts.allergy_conflicts.map((c, i) => (
                  <Text key={i} size="xs">
                    <Text span fw={700}>{c.drug_name}</Text> conflicts with known allergy to <Text span fw={700}>{c.allergen_name}</Text>
                    {c.severity && <> (severity: {c.severity})</>}
                    {c.reaction && <> — {c.reaction}</>}
                  </Text>
                ))}
              </Alert>
            )}
            {safetyAlerts.interactions.length > 0 && (
              <Alert color="orange" icon={<IconAlertTriangle size={16} />} title="Drug Interaction Warning" variant="light">
                {safetyAlerts.interactions.map((ia, i) => (
                  <Text key={i} size="xs">
                    <Badge size="xs" color={ia.severity === "contraindicated" ? "red" : ia.severity === "major" ? "orange" : "yellow"} mr={4}>
                      {ia.severity}
                    </Badge>
                    <Text span fw={700}>{ia.drug_a}</Text> + <Text span fw={700}>{ia.drug_b}</Text>: {ia.description}
                    {ia.management && <Text size="xs" c="dimmed" mt={2}>Management: {ia.management}</Text>}
                  </Text>
                ))}
              </Alert>
            )}

            {/* Notes toggle */}
            <Button
              variant="subtle"
              size="xs"
              onClick={toggleNotes}
              rightSection={notesOpen ? <IconChevronUp size={14} /> : <IconChevronDown size={14} />}
              style={{ alignSelf: "flex-start" }}
            >
              {t("prescription.instructions")}
            </Button>
            <Collapse in={notesOpen}>
              <Textarea
                placeholder={t("prescription.generalNotes")}
                value={rxNotes}
                onChange={(e) => setRxNotes(e.currentTarget.value)}
                autosize
                minRows={2}
                maxRows={4}
              />
            </Collapse>

            {/* Pending items */}
            {pendingItems.length > 0 && (
              <>
                <Table striped className={styles.pendingTable}>
                  <Table.Thead>
                    <Table.Tr>
                      <Table.Th>{t("prescription.drug")}</Table.Th>
                      <Table.Th>{t("prescription.dosage")}</Table.Th>
                      <Table.Th>{t("prescription.frequency")}</Table.Th>
                      <Table.Th>{t("prescription.duration")}</Table.Th>
                      <Table.Th>{t("prescription.route")}</Table.Th>
                      <Table.Th w={40} />
                    </Table.Tr>
                  </Table.Thead>
                  <Table.Tbody>
                    {pendingItems.map((item, idx) => (
                      <Table.Tr key={idx}>
                        <Table.Td>
                          <Text size="sm" fw={500}>{item.drug_name}</Text>
                        </Table.Td>
                        <Table.Td>{item.dosage}</Table.Td>
                        <Table.Td>
                          <Badge size="xs" variant="light">{item.frequency}</Badge>
                        </Table.Td>
                        <Table.Td>{item.duration}</Table.Td>
                        <Table.Td>{item.route ?? "—"}</Table.Td>
                        <Table.Td>
                          <ActionIcon
                            variant="subtle"
                            color="red"
                            size="xs"
                            onClick={() => handleRemoveItem(idx)}
                          >
                            <IconX size={12} />
                          </ActionIcon>
                        </Table.Td>
                      </Table.Tr>
                    ))}
                  </Table.Tbody>
                </Table>
                <Group justify="flex-end">
                  <Button
                    size="sm"
                    variant="light"
                    onClick={openSaveTemplate}
                    leftSection={<IconDeviceFloppy size={14} />}
                  >
                    Save as Template
                  </Button>
                  <Button
                    size="sm"
                    onClick={handleSave}
                    loading={isSaving}
                    leftSection={<IconPill size={14} />}
                  >
                    {t("prescription.savePrescription")} ({t("prescription.items", { count: pendingItems.length })})
                  </Button>
                </Group>
              </>
            )}
          </Stack>
        </Card>
      )}

      {/* Existing prescriptions */}
      {prescriptions.map((p) => (
        <Card key={p.prescription.id} padding="sm" radius="md" withBorder>
          <Group gap={8} mb="xs" justify="space-between">
            <Group gap={8}>
              <IconPill size={16} color="var(--mantine-color-primary-5)" />
              <Text size="xs" c="dimmed">
                {new Date(p.prescription.created_at).toLocaleString()}
              </Text>
              {p.prescription.notes && (
                <Text size="xs" c="dimmed" fs="italic">
                  — {p.prescription.notes}
                </Text>
              )}
            </Group>
            <Group gap={4}>
              {onSendToPharmacy && (
                <Tooltip label="Send to Pharmacy">
                  <ActionIcon variant="subtle" color="teal" size="sm" onClick={() => onSendToPharmacy(p.prescription.id)}>
                    <IconMedicineSyrup size={14} />
                  </ActionIcon>
                </Tooltip>
              )}
              {onPrint && (
                <Tooltip label={t("prescription.print")}>
                  <ActionIcon variant="subtle" size="sm" onClick={() => onPrint(p)}>
                    <IconPrinter size={14} />
                  </ActionIcon>
                </Tooltip>
              )}
            </Group>
          </Group>
          <Table striped>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>{t("prescription.drug")}</Table.Th>
                <Table.Th>{t("prescription.dosage")}</Table.Th>
                <Table.Th>{t("prescription.frequency")}</Table.Th>
                <Table.Th>{t("prescription.duration")}</Table.Th>
                <Table.Th>{t("prescription.route")}</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {p.items.map((item) => (
                <Table.Tr key={item.id}>
                  <Table.Td>
                    <Text size="sm" fw={500}>{item.drug_name}</Text>
                  </Table.Td>
                  <Table.Td>{item.dosage}</Table.Td>
                  <Table.Td>
                    <Badge size="xs" variant="light">{item.frequency}</Badge>
                  </Table.Td>
                  <Table.Td>{item.duration}</Table.Td>
                  <Table.Td>{item.route ?? "—"}</Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Card>
      ))}

      {!showForm && prescriptions.length === 0 && (
        <Text size="sm" c="dimmed" ta="center" py="md">
          {t("prescription.noPrescriptions")}
        </Text>
      )}

      {/* Save as Template modal */}
      <Modal opened={saveTemplateOpen} onClose={closeSaveTemplate} title="Save Prescription Template" size="sm">
        <Stack gap="sm">
          <TextInput
            label="Template Name"
            placeholder="e.g. Hypertension Standard"
            value={templateName}
            onChange={(e) => setTemplateName(e.currentTarget.value)}
            required
          />
          <Textarea
            label="Description"
            placeholder="Optional description"
            value={templateDesc}
            onChange={(e) => setTemplateDesc(e.currentTarget.value)}
            autosize
            minRows={2}
          />
          <Switch
            label="Share with department"
            description="Other doctors in your department can use this template"
            checked={templateShared}
            onChange={(e) => setTemplateShared(e.currentTarget.checked)}
          />
          <Text size="xs" c="dimmed">
            {pendingItems.length} medication{pendingItems.length !== 1 ? "s" : ""} will be saved
          </Text>
          <Group justify="flex-end">
            <Button variant="subtle" onClick={closeSaveTemplate}>Cancel</Button>
            <Button
              onClick={handleSaveTemplate}
              loading={saveTemplateMutation.isPending}
              disabled={!templateName.trim()}
              leftSection={<IconDeviceFloppy size={14} />}
            >
              Save Template
            </Button>
          </Group>
        </Stack>
      </Modal>
    </Stack>
  );
}
