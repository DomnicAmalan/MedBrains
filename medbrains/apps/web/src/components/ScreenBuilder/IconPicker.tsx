import { Select } from "@mantine/core";
import { SectionIcon } from "../DynamicForm/SectionIcon";

const ICON_OPTIONS = [
  { group: "People", items: [
    { value: "user", label: "User" },
    { value: "users", label: "Users" },
    { value: "nurse", label: "Nurse" },
    { value: "hi-doctor", label: "Doctor" },
  ]},
  { group: "Departments", items: [
    { value: "stethoscope", label: "Stethoscope" },
    { value: "heart", label: "Heart" },
    { value: "hi-cardiology", label: "Cardiology" },
    { value: "hi-neurology", label: "Neurology" },
    { value: "hi-pediatrics", label: "Pediatrics" },
    { value: "hi-ophthalmology", label: "Ophthalmology" },
    { value: "hi-orthopedics", label: "Orthopedics" },
    { value: "hi-radiology", label: "Radiology" },
    { value: "hi-pharmacy", label: "Pharmacy" },
    { value: "hi-laboratory", label: "Laboratory" },
  ]},
  { group: "Clinical", items: [
    { value: "pill", label: "Pill" },
    { value: "vaccine", label: "Vaccine" },
    { value: "test-pipe", label: "Lab Test" },
    { value: "first-aid-kit", label: "First Aid" },
    { value: "hi-blood-bag", label: "Blood Bag" },
    { value: "hi-syringe", label: "Syringe" },
    { value: "clipboard", label: "Clipboard" },
    { value: "report-medical", label: "Medical Report" },
  ]},
  { group: "Facility", items: [
    { value: "building-hospital", label: "Hospital" },
    { value: "bed", label: "Bed" },
    { value: "wheelchair", label: "Wheelchair" },
    { value: "ambulance", label: "Ambulance" },
  ]},
  { group: "General", items: [
    { value: "settings", label: "Settings" },
    { value: "dashboard", label: "Dashboard" },
    { value: "list", label: "List" },
    { value: "calendar", label: "Calendar" },
    { value: "chart-bar", label: "Chart" },
    { value: "file-text", label: "File" },
    { value: "receipt", label: "Receipt" },
    { value: "id", label: "ID Card" },
    { value: "shield-check", label: "Shield" },
    { value: "layout", label: "Layout" },
  ]},
];

export function IconPicker({
  value,
  onChange,
  label = "Icon",
}: {
  value: string;
  onChange: (value: string) => void;
  label?: string;
}) {
  return (
    <Select
      label={label}
      data={ICON_OPTIONS}
      value={value || null}
      onChange={(v) => onChange(v ?? "")}
      clearable
      searchable
      placeholder="Select icon..."
      leftSection={value ? <SectionIcon icon={value} size={16} /> : undefined}
    />
  );
}
