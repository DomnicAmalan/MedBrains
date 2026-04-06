import { TextInput } from "@mantine/core";
import { useDraggable } from "@dnd-kit/core";
import { useScreenBuilderStore } from "@medbrains/stores";
import type { ScreenZoneType, SidecarTrigger } from "@medbrains/types";
import {
  IconCalendar,
  IconColumns,
  IconFilter,
  IconForms,
  IconInfoCircle,
  IconLayoutKanban,
  IconLayoutDashboard,
  IconList,
  IconSearch,
  IconStepInto,
  IconTable,
  IconUser,
  IconBolt,
  IconDeviceFloppy,
  IconNavigationFilled,
  IconPrinter,
  IconTrash,
  IconPlayerPlay,
  IconClock,
  IconArrowUp,
  IconEdit,
  IconRowInsertTop,
  IconAffiliate,
} from "@tabler/icons-react";
import { useState } from "react";
import classes from "./screen-builder.module.scss";

// ── Zone Type Definitions ─────────────────────────────

interface ZoneTypeDef {
  type: ScreenZoneType;
  label: string;
  icon: React.ReactNode;
}

const ZONE_TYPES: ZoneTypeDef[] = [
  { type: "form", label: "Form", icon: <IconForms size={16} /> },
  { type: "data_table", label: "Data Table", icon: <IconTable size={16} /> },
  { type: "filter_bar", label: "Filter Bar", icon: <IconFilter size={16} /> },
  { type: "tabs", label: "Tabs", icon: <IconColumns size={16} /> },
  { type: "stepper", label: "Stepper", icon: <IconStepInto size={16} /> },
  { type: "detail_header", label: "Detail Header", icon: <IconUser size={16} /> },
  { type: "info_panel", label: "Info Panel", icon: <IconInfoCircle size={16} /> },
  { type: "calendar", label: "Calendar", icon: <IconCalendar size={16} /> },
  { type: "kanban", label: "Kanban Board", icon: <IconLayoutKanban size={16} /> },
  { type: "widget_grid", label: "Widget Grid", icon: <IconLayoutDashboard size={16} /> },
];

// ── Action Type Definitions ──────────────────────────

interface ActionTypeDef {
  action_type: string;
  label: string;
  icon: React.ReactNode;
}

const ACTION_TYPES: ActionTypeDef[] = [
  { action_type: "save", label: "Save", icon: <IconDeviceFloppy size={16} /> },
  { action_type: "delete", label: "Delete", icon: <IconTrash size={16} /> },
  { action_type: "print", label: "Print", icon: <IconPrinter size={16} /> },
  { action_type: "navigate", label: "Navigate", icon: <IconNavigationFilled size={16} /> },
  { action_type: "custom", label: "Custom", icon: <IconBolt size={16} /> },
];

// ── Trigger Type Definitions ─────────────────────────

interface TriggerTypeDef {
  trigger: SidecarTrigger;
  label: string;
  icon: React.ReactNode;
}

const TRIGGER_TYPES: TriggerTypeDef[] = [
  { trigger: "screen_load", label: "Screen Load", icon: <IconPlayerPlay size={16} /> },
  { trigger: "form_submit", label: "Form Submit", icon: <IconArrowUp size={16} /> },
  { trigger: "field_change", label: "Field Change", icon: <IconEdit size={16} /> },
  { trigger: "interval", label: "Interval", icon: <IconClock size={16} /> },
  { trigger: "row_select", label: "Row Select", icon: <IconRowInsertTop size={16} /> },
  { trigger: "row_action", label: "Row Action", icon: <IconAffiliate size={16} /> },
  { trigger: "screen_exit", label: "Screen Exit", icon: <IconPlayerPlay size={16} /> },
  { trigger: "form_validate", label: "Form Validate", icon: <IconList size={16} /> },
  { trigger: "step_enter", label: "Step Enter", icon: <IconStepInto size={16} /> },
  { trigger: "step_leave", label: "Step Leave", icon: <IconStepInto size={16} /> },
];

// ── Draggable Zone Item ──────────────────────────────

function DraggableZoneItem({ def }: { def: ZoneTypeDef }) {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `palette-zone-${def.type}`,
    data: { type: "palette-zone", zoneType: def.type, label: def.label },
  });

  return (
    <div
      ref={setNodeRef}
      className={`${classes.paletteItem} ${isDragging ? classes.paletteItemDragging : ""}`}
      {...attributes}
      {...listeners}
    >
      {def.icon}
      {def.label}
    </div>
  );
}

// ── Main Palette Component ──────────────────────────

export function ZonePalette() {
  const addAction = useScreenBuilderStore((s) => s.addAction);
  const addSidecar = useScreenBuilderStore((s) => s.addSidecar);
  const [search, setSearch] = useState("");
  const isLocked = useScreenBuilderStore((s) => s.screen.status) === "active";

  const lowerSearch = search.toLowerCase();
  const filteredZones = ZONE_TYPES.filter((z) =>
    z.label.toLowerCase().includes(lowerSearch),
  );
  const filteredActions = ACTION_TYPES.filter((a) =>
    a.label.toLowerCase().includes(lowerSearch),
  );
  const filteredTriggers = TRIGGER_TYPES.filter((t) =>
    t.label.toLowerCase().includes(lowerSearch),
  );

  if (isLocked) {
    return (
      <div className={classes.palette}>
        <div className={classes.paletteHeader}>Components</div>
        <div className={classes.paletteContent}>
          <div className={classes.paletteGroupLabel}>Locked</div>
          <div style={{ padding: "8px 0", color: "var(--mantine-color-dimmed)", fontSize: "var(--mantine-font-size-xs)" }}>
            Screen is published. Create a new version to edit.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={classes.palette}>
      <div className={classes.paletteHeader}>Components</div>
      <div className={classes.paletteContent}>
        <TextInput
          size="xs"
          placeholder="Search..."
          leftSection={<IconSearch size={14} />}
          value={search}
          onChange={(e) => setSearch(e.currentTarget.value)}
          mb="sm"
        />

        {filteredZones.length > 0 && (
          <div className={classes.paletteGroup}>
            <div className={classes.paletteGroupLabel}>Zones</div>
            {filteredZones.map((z) => (
              <DraggableZoneItem key={z.type} def={z} />
            ))}
          </div>
        )}

        {filteredActions.length > 0 && (
          <div className={classes.paletteGroup}>
            <div className={classes.paletteGroupLabel}>Actions</div>
            {filteredActions.map((a) => (
              <div
                key={a.action_type}
                className={classes.paletteClickItem}
                onClick={() => addAction(a.action_type, a.label)}
              >
                {a.icon}
                {a.label}
              </div>
            ))}
          </div>
        )}

        {filteredTriggers.length > 0 && (
          <div className={classes.paletteGroup}>
            <div className={classes.paletteGroupLabel}>Triggers</div>
            {filteredTriggers.map((t) => (
              <div
                key={t.trigger}
                className={classes.paletteClickItem}
                onClick={() => addSidecar(t.trigger, t.label)}
              >
                {t.icon}
                {t.label}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
