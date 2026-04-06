import { Badge, Group } from "@mantine/core";
import {
  IconCheck,
  IconClock,
  IconPlayerPlay,
  IconX,
  IconAlertTriangle,
  IconHourglass,
  IconEye,
  IconFileCheck,
  IconCircleDot,
} from "@tabler/icons-react";
import type { ReactNode } from "react";

interface StatusConfig {
  color: string;
  icon: ReactNode;
  label: string;
}

// Semantic color mapping:
//   success (emerald) — completed, verified, paid, healthy, active
//   warning (amber)   — pending, called, partially paid, sample collected
//   info    (sky)     — waiting, ordered, issued, admitted, queued
//   danger  (rose)    — cancelled, no show, errors
//   orange            — in-progress actions (consultation, processing)
//   slate             — draft, deferred, neutral

const statusMap: Record<string, StatusConfig> = {
  // OPD statuses
  waiting: { color: "info", icon: <IconClock size={12} />, label: "Waiting" },
  called: { color: "warning", icon: <IconPlayerPlay size={12} />, label: "Called" },
  in_consultation: { color: "orange", icon: <IconEye size={12} />, label: "In Consultation" },
  completed: { color: "success", icon: <IconCheck size={12} />, label: "Completed" },
  no_show: { color: "danger", icon: <IconX size={12} />, label: "No Show" },

  // Lab statuses
  ordered: { color: "info", icon: <IconClock size={12} />, label: "Ordered" },
  sample_collected: { color: "warning", icon: <IconHourglass size={12} />, label: "Sample Collected" },
  processing: { color: "orange", icon: <IconCircleDot size={12} />, label: "Processing" },
  verified: { color: "success", icon: <IconFileCheck size={12} />, label: "Verified" },
  cancelled: { color: "danger", icon: <IconX size={12} />, label: "Cancelled" },

  // Billing statuses
  draft: { color: "slate", icon: <IconClock size={12} />, label: "Draft" },
  issued: { color: "info", icon: <IconFileCheck size={12} />, label: "Issued" },
  partially_paid: { color: "warning", icon: <IconAlertTriangle size={12} />, label: "Partially Paid" },
  paid: { color: "success", icon: <IconCheck size={12} />, label: "Paid" },

  // IPD statuses
  admitted: { color: "info", icon: <IconPlayerPlay size={12} />, label: "Admitted" },
  discharged: { color: "success", icon: <IconCheck size={12} />, label: "Discharged" },

  // Generic
  active: { color: "success", icon: <IconCircleDot size={12} />, label: "Active" },
  inactive: { color: "slate", icon: <IconX size={12} />, label: "Inactive" },
};

interface StatusBadgeProps {
  status: string;
}

export function StatusBadge({ status }: StatusBadgeProps) {
  const config = statusMap[status];
  if (!config) {
    return <Badge color="slate" radius="xl" size="md">{status}</Badge>;
  }

  return (
    <Badge
      color={config.color}
      radius="xl"
      size="md"
      leftSection={<Group gap={0}>{config.icon}</Group>}
    >
      {config.label}
    </Badge>
  );
}
