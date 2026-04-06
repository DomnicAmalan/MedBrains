import { Text, Title } from "@mantine/core";
import {
  SortableContext,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { useDroppable } from "@dnd-kit/core";
import { IconLayout, IconSection } from "@tabler/icons-react";
import { useScreenBuilderStore } from "@medbrains/stores";
import { ZoneCard } from "./ZoneCard";
import { ActionCard } from "./ActionCard";
import { SidecarCard } from "./SidecarCard";
import classes from "./screen-builder.module.scss";

function HeaderBlock() {
  const header = useScreenBuilderStore((s) => s.header);
  const selectedItemId = useScreenBuilderStore((s) => s.selectedItemId);
  const selectedItemType = useScreenBuilderStore((s) => s.selectedItemType);
  const selectItem = useScreenBuilderStore((s) => s.selectItem);
  const isSelected = selectedItemType === "header" && selectedItemId === "__header__";

  return (
    <div
      className={`${classes.headerBlock} ${isSelected ? classes.headerBlockSelected : ""}`}
      onClick={() => selectItem("__header__", "header")}
    >
      <Title order={5}>
        {header.title || "Page Title"}
      </Title>
      {(header.subtitle || !header.title) && (
        <Text size="xs" c="dimmed">
          {header.subtitle || "Click to configure header"}
        </Text>
      )}
    </div>
  );
}

function ZoneDropArea() {
  const { setNodeRef } = useDroppable({ id: "zone-drop-area" });

  return (
    <div ref={setNodeRef} style={{ minHeight: 40 }}>
      <Text size="sm" c="dimmed" ta="center" py="md">
        Drag zones from the palette or click to add
      </Text>
    </div>
  );
}

export function ScreenCanvas() {
  const zoneOrder = useScreenBuilderStore((s) => s.zoneOrder);
  const zones = useScreenBuilderStore((s) => s.zones);
  const actionOrder = useScreenBuilderStore((s) => s.actionOrder);
  const actions = useScreenBuilderStore((s) => s.actions);
  const sidecarOrder = useScreenBuilderStore((s) => s.sidecarOrder);
  const sidecars = useScreenBuilderStore((s) => s.sidecars);
  const isLocked = useScreenBuilderStore((s) => s.screen.status) === "active";

  const hasZones = zoneOrder.length > 0;
  const hasActions = actionOrder.length > 0;
  const hasSidecars = sidecarOrder.length > 0;
  const isEmpty = !hasZones && !hasActions && !hasSidecars;

  if (isEmpty) {
    return (
      <div className={classes.canvas}>
        <HeaderBlock />
        <div className={classes.canvasEmpty}>
          <IconLayout size={48} stroke={1} />
          <Text size="sm" fw={500}>
            No zones yet
          </Text>
          <Text size="xs" c="dimmed">
            Drag zone types from the left palette to build your screen layout.
            <br />
            Click actions and triggers to add them.
          </Text>
        </div>
      </div>
    );
  }

  return (
    <div className={classes.canvas}>
      <HeaderBlock />

      {/* Actions Bar */}
      {hasActions && (
        <div className={classes.canvasSection}>
          <div className={classes.canvasSectionLabel}>
            <IconSection size={12} />
            Actions
          </div>
          {actionOrder.map((id) => {
            const action = actions[id];
            if (!action) return null;
            return <ActionCard key={id} action={action} isLocked={isLocked} />;
          })}
        </div>
      )}

      {/* Zones */}
      <div className={classes.canvasSection}>
        <div className={classes.canvasSectionLabel}>
          <IconSection size={12} />
          Zones ({zoneOrder.length})
        </div>
        <SortableContext
          items={zoneOrder}
          strategy={verticalListSortingStrategy}
        >
          {zoneOrder.map((id) => {
            const zone = zones[id];
            if (!zone) return null;
            return <ZoneCard key={id} zone={zone} isLocked={isLocked} />;
          })}
        </SortableContext>
        {!isLocked && <ZoneDropArea />}
      </div>

      {/* Sidecars */}
      {hasSidecars && (
        <div className={classes.canvasSection}>
          <div className={classes.canvasSectionLabel}>
            <IconSection size={12} />
            Triggers / Sidecars ({sidecarOrder.length})
          </div>
          {sidecarOrder.map((id) => {
            const sidecar = sidecars[id];
            if (!sidecar) return null;
            return <SidecarCard key={id} sidecar={sidecar} isLocked={isLocked} />;
          })}
        </div>
      )}
    </div>
  );
}
