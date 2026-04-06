import { Button, type ButtonProps } from "@mantine/core";
import { IconPrinter } from "@tabler/icons-react";
import { useState } from "react";
import { DocumentPreviewModal } from "./DocumentPreviewModal";

interface PrintButtonProps extends Omit<ButtonProps, "onClick"> {
  templateCode: string;
  context: Record<string, unknown>;
  title?: string;
  patientId?: string;
  moduleCode?: string;
  sourceTable?: string;
  sourceId?: string;
  visitId?: string;
  admissionId?: string;
  label?: string;
}

export function PrintButton({
  templateCode,
  context,
  title,
  patientId,
  moduleCode,
  sourceTable,
  sourceId,
  visitId,
  admissionId,
  label = "Print",
  ...buttonProps
}: PrintButtonProps) {
  const [opened, setOpened] = useState(false);

  return (
    <>
      <Button
        leftSection={<IconPrinter size={16} />}
        variant="light"
        size="xs"
        onClick={() => setOpened(true)}
        {...buttonProps}
      >
        {label}
      </Button>
      <DocumentPreviewModal
        opened={opened}
        onClose={() => setOpened(false)}
        templateCode={templateCode}
        context={context}
        title={title ?? `Print ${templateCode}`}
        patientId={patientId}
        moduleCode={moduleCode}
        sourceTable={sourceTable}
        sourceId={sourceId}
        visitId={visitId}
        admissionId={admissionId}
      />
    </>
  );
}
