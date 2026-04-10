import { useDraggable } from "@dnd-kit/core";
import {
  Badge,
  Loader,
  ScrollArea,
  TextInput,
} from "@mantine/core";
import { api } from "@medbrains/api";
import { useFormBuilderStore } from "@medbrains/stores";
import type { FieldDataType, FieldMasterFull } from "@medbrains/types";
import {
  IconCalendar,
  IconCalendarTime,
  IconCheck,
  IconClock,
  IconCode,
  IconHash,
  IconLetterCase,
  IconListCheck,
  IconMail,
  IconPhone,
  IconSearch,
  IconSelect,
  IconToggleLeft,
  IconUpload,
} from "@tabler/icons-react";
import { useQuery } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import classes from "./form-builder.module.scss";

// ── Data type → icon mapping ─────────────────────────────

const DATA_TYPE_ICONS: Record<string, React.ReactNode> = {
  text: <IconLetterCase size={14} />,
  email: <IconMail size={14} />,
  phone: <IconPhone size={14} />,
  number: <IconHash size={14} />,
  decimal: <IconHash size={14} />,
  textarea: <IconLetterCase size={14} />,
  date: <IconCalendar size={14} />,
  datetime: <IconCalendarTime size={14} />,
  time: <IconClock size={14} />,
  select: <IconSelect size={14} />,
  multiselect: <IconListCheck size={14} />,
  radio: <IconSelect size={14} />,
  checkbox: <IconCheck size={14} />,
  boolean: <IconToggleLeft size={14} />,
  computed: <IconCode size={14} />,
  file: <IconUpload size={14} />,
  json: <IconCode size={14} />,
  hidden: <IconCode size={14} />,
  uuid_fk: <IconSelect size={14} />,
};

function getIcon(dataType: string): React.ReactNode {
  return DATA_TYPE_ICONS[dataType] ?? <IconLetterCase size={14} />;
}

// ── Data type category grouping ──────────────────────────

const CATEGORY_ORDER = [
  "Demographics",
  "Contact",
  "Clinical",
  "Administrative",
  "Selection",
  "Date & Time",
  "Other",
];

function categorizeField(field: FieldMasterFull): string {
  const code = field.code.toLowerCase();
  const name = field.name.toLowerCase();

  if (code.includes("name") || code.includes("dob") || code.includes("birth") ||
      code.includes("gender") || code.includes("age") || code.includes("photo") ||
      code.includes("marital") || code.includes("blood_group") || code.includes("religion") ||
      code.includes("nationality") || code.includes("occupation") || code.includes("mother") ||
      code.includes("father") || code.includes("aadhaar") || code.includes("abha"))
    return "Demographics";

  if (code.includes("phone") || code.includes("email") || code.includes("address") ||
      code.includes("city") || code.includes("state") || code.includes("pin") ||
      code.includes("district") || code.includes("country") || code.includes("emergency") ||
      code.includes("contact"))
    return "Contact";

  if (code.includes("allerg") || code.includes("diagnos") || code.includes("vital") ||
      code.includes("bp") || code.includes("pulse") || code.includes("temp") ||
      code.includes("weight") || code.includes("height") || code.includes("bmi") ||
      code.includes("complaint") || code.includes("symptom") || code.includes("history") ||
      name.includes("clinical") || code.includes("medication"))
    return "Clinical";

  if (code.includes("category") || code.includes("insurance") || code.includes("referr") ||
      code.includes("payment") || code.includes("uhid") || code.includes("mrn") ||
      code.includes("consent") || code.includes("note") || code.includes("remark"))
    return "Administrative";

  if (field.data_type === "select" || field.data_type === "multiselect" ||
      field.data_type === "radio" || field.data_type === "checkbox")
    return "Selection";

  if (field.data_type === "date" || field.data_type === "datetime" || field.data_type === "time")
    return "Date & Time";

  return "Other";
}

// ── Custom field type palette (fallback) ─────────────────

interface PaletteFieldType {
  dataType: FieldDataType;
  label: string;
}

const CUSTOM_FIELD_TYPES: PaletteFieldType[] = [
  { dataType: "text", label: "Text" },
  { dataType: "number", label: "Number" },
  { dataType: "decimal", label: "Decimal" },
  { dataType: "textarea", label: "Text Area" },
  { dataType: "email", label: "Email" },
  { dataType: "phone", label: "Phone" },
  { dataType: "date", label: "Date" },
  { dataType: "datetime", label: "Date Time" },
  { dataType: "time", label: "Time" },
  { dataType: "select", label: "Dropdown" },
  { dataType: "multiselect", label: "Multi Select" },
  { dataType: "radio", label: "Radio" },
  { dataType: "checkbox", label: "Checkbox" },
  { dataType: "boolean", label: "Toggle" },
  { dataType: "computed", label: "Computed" },
  { dataType: "file", label: "File Upload" },
  { dataType: "json", label: "JSON" },
];

// ── Draggable Items ──────────────────────────────────────

function DraggableMasterField({ field }: { field: FieldMasterFull }) {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `master-${field.id}`,
    data: {
      type: "palette-field",
      dataType: field.data_type,
      label: field.name,
      fieldMasterId: field.id,
      fieldCode: field.code,
    },
  });

  return (
    <div
      ref={setNodeRef}
      className={`${classes.paletteItem} ${isDragging ? classes.paletteItemDragging : ""}`}
      {...listeners}
      {...attributes}
    >
      {getIcon(field.data_type)}
      <span className={classes.paletteItemLabel}>{field.name}</span>
      <Badge size="xs" variant="light" color="slate" ml="auto">
        {field.data_type}
      </Badge>
    </div>
  );
}

function DraggableCustomField({ field }: { field: PaletteFieldType }) {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `palette-${field.dataType}`,
    data: { type: "palette-field", dataType: field.dataType, label: field.label },
  });

  return (
    <div
      ref={setNodeRef}
      className={`${classes.paletteItem} ${isDragging ? classes.paletteItemDragging : ""}`}
      {...listeners}
      {...attributes}
    >
      {getIcon(field.dataType)}
      {field.label}
    </div>
  );
}

// ── Main Palette Component ───────────────────────────────

export function FieldPalette() {
  const formStatus = useFormBuilderStore((s) => s.form.status);
  const isLocked = formStatus === "active";
  const [search, setSearch] = useState("");

  const { data: fieldMasters, isLoading } = useQuery({
    queryKey: ["admin-fields-all"],
    queryFn: () => api.adminListFields(),
    staleTime: 60_000,
  });

  // Group masters by category, filtered by search
  const grouped = useMemo(() => {
    if (!fieldMasters?.length) return null;

    const filtered = search
      ? fieldMasters.filter(
          (f) =>
            f.name.toLowerCase().includes(search.toLowerCase()) ||
            f.code.toLowerCase().includes(search.toLowerCase()),
        )
      : fieldMasters;

    const groups = new Map<string, FieldMasterFull[]>();
    for (const field of filtered) {
      const cat = categorizeField(field);
      const existing = groups.get(cat) ?? [];
      existing.push(field);
      groups.set(cat, existing);
    }

    // Sort by predefined category order
    return CATEGORY_ORDER
      .filter((cat) => groups.has(cat))
      .map((cat) => ({ label: cat, fields: groups.get(cat)! }));
  }, [fieldMasters, search]);

  // Filter custom types by search
  const filteredCustom = useMemo(
    () =>
      search
        ? CUSTOM_FIELD_TYPES.filter((f) =>
            f.label.toLowerCase().includes(search.toLowerCase()),
          )
        : CUSTOM_FIELD_TYPES,
    [search],
  );

  return (
    <div className={classes.palette} style={isLocked ? { pointerEvents: "none", opacity: 0.5 } : undefined}>
      <div className={classes.paletteHeader}>Fields {isLocked && "(Locked)"}</div>

      <div style={{ padding: "0 8px 8px" }}>
        <TextInput
          size="xs"
          placeholder="Search fields..."
          leftSection={<IconSearch size={14} />}
          value={search}
          onChange={(e) => setSearch(e.currentTarget.value)}
        />
      </div>

      <ScrollArea className={classes.paletteContent} offsetScrollbars>
        {isLoading && (
          <div style={{ textAlign: "center", padding: 16 }}>
            <Loader size="sm" />
          </div>
        )}

        {/* Field Masters from API */}
        {grouped &&
          grouped.map((group) => (
            <div key={group.label} className={classes.paletteGroup}>
              <div className={classes.paletteGroupLabel}>
                {group.label}
                <Badge size="xs" variant="light" color="slate" ml={4}>
                  {group.fields.length}
                </Badge>
              </div>
              {group.fields.map((field) => (
                <DraggableMasterField key={field.id} field={field} />
              ))}
            </div>
          ))}

        {/* Custom field types (always shown) */}
        <div className={classes.paletteGroup}>
          <div className={classes.paletteGroupLabel}>
            Custom Types
          </div>
          {filteredCustom.map((field) => (
            <DraggableCustomField key={field.dataType} field={field} />
          ))}
        </div>
      </ScrollArea>
    </div>
  );
}
