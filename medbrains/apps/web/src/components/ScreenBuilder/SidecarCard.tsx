import { ActionIcon, Badge, Text, Tooltip } from "@mantine/core";
import { IconTrash } from "@tabler/icons-react";
import type { SidecarNode } from "@medbrains/stores";
import { useScreenBuilderStore } from "@medbrains/stores";
import classes from "./screen-builder.module.scss";

const TRIGGER_COLORS: Record<string, string> = {
  screen_load: "teal",
  screen_exit: "gray",
  form_submit: "green",
  form_validate: "orange",
  form_save_draft: "yellow",
  field_change: "blue",
  row_select: "indigo",
  row_action: "violet",
  interval: "cyan",
  step_enter: "grape",
  step_leave: "pink",
};

export function SidecarCard({ sidecar, isLocked }: { sidecar: SidecarNode; isLocked: boolean }) {
  const selectedItemId = useScreenBuilderStore((s) => s.selectedItemId);
  const selectItem = useScreenBuilderStore((s) => s.selectItem);
  const removeSidecar = useScreenBuilderStore((s) => s.removeSidecar);
  const isSelected = selectedItemId === sidecar.clientId;

  const color = TRIGGER_COLORS[sidecar.trigger_event] ?? "gray";

  return (
    <div
      className={`${classes.sidecarCard} ${isSelected ? classes.sidecarCardSelected : ""}`}
      onClick={() => selectItem(sidecar.clientId, "sidecar")}
    >
      <Badge size="xs" color={color} variant="light">
        {sidecar.trigger_event}
      </Badge>

      <div className={classes.sidecarCardInfo}>
        <Text size="sm" fw={500} truncate>
          {sidecar.name}
        </Text>
        <Text size="xs" c="dimmed" truncate>
          {sidecar.pipeline_id ? "Pipeline" : sidecar.inline_action ? "Inline action" : "No action"}
          {!sidecar.is_active && " (inactive)"}
        </Text>
      </div>

      {!isLocked && (
        <div className={classes.sidecarCardActions}>
          <Tooltip label="Delete">
            <ActionIcon
              variant="subtle"
              color="red"
              size="xs"
              onClick={(e) => {
                e.stopPropagation();
                removeSidecar(sidecar.clientId);
              }}
            >
              <IconTrash size={14} />
            </ActionIcon>
          </Tooltip>
        </div>
      )}
    </div>
  );
}
