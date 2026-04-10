import {
  Accordion,
  Badge,
  Box,
  Divider,
  Drawer,
  Group,
  ScrollArea,
  Stack,
  Text,
  TextInput,
} from "@mantine/core";
import { api } from "@medbrains/api";
import { IconBook, IconSearch, IconShield } from "@tabler/icons-react";
import { useQuery } from "@tanstack/react-query";
import { useMemo, useState } from "react";

// ── Requirement Level Colors ─────────────────────────────

const REQUIREMENT_COLORS: Record<string, string> = {
  mandatory: "danger",
  conditional: "orange",
  recommended: "warning",
  optional: "slate",
};

// ── Types ────────────────────────────────────────────────

interface ClauseGroup {
  clause_code: string | null;
  clause_reference: string | null;
  requirement_level: string;
  description: string | null;
  fields: Array<{ field_code: string; field_name: string }>;
}

interface BodyGroup {
  body_code: string;
  body_name: string;
  body_level: string;
  clauses: ClauseGroup[];
}

// ── Component ────────────────────────────────────────────

interface RegulatoryBrowserProps {
  opened: boolean;
  onClose: () => void;
  fieldId?: string;
}

export function RegulatoryBrowser({
  opened,
  onClose,
  fieldId,
}: RegulatoryBrowserProps) {
  const [search, setSearch] = useState("");

  const { data: allClauses, isLoading } = useQuery({
    queryKey: ["admin-regulatory-clauses", fieldId ?? "all"],
    queryFn: () =>
      api.adminListRegulatoryClauses(
        fieldId ? { field_id: fieldId } : undefined,
      ),
    staleTime: 60_000,
    enabled: opened,
  });

  // Group into bible-verse structure: Body → Clause → Fields
  const bodyGroups = useMemo(() => {
    if (!allClauses) return [];

    // First apply search filter
    let filtered = allClauses;
    if (search.trim()) {
      const q = search.toLowerCase();
      filtered = allClauses.filter(
        (c) =>
          c.body_code.toLowerCase().includes(q) ||
          c.body_name.toLowerCase().includes(q) ||
          (c.clause_code?.toLowerCase().includes(q) ?? false) ||
          (c.clause_reference?.toLowerCase().includes(q) ?? false) ||
          (c.description?.toLowerCase().includes(q) ?? false) ||
          c.field_name.toLowerCase().includes(q) ||
          c.field_code.toLowerCase().includes(q) ||
          c.requirement_level.toLowerCase().includes(q),
      );
    }

    // Group by body, then by clause identity
    const bodyMap = new Map<string, BodyGroup>();

    for (const c of filtered) {
      let body = bodyMap.get(c.body_code);
      if (!body) {
        body = {
          body_code: c.body_code,
          body_name: c.body_name,
          body_level: c.body_level,
          clauses: [],
        };
        bodyMap.set(c.body_code, body);
      }

      // Group by clause identity (clause_code + clause_reference + requirement_level)
      const clauseKey = `${c.clause_code ?? ""}|${c.clause_reference ?? ""}|${c.requirement_level}|${c.description ?? ""}`;
      let clause = body.clauses.find(
        (cl) =>
          `${cl.clause_code ?? ""}|${cl.clause_reference ?? ""}|${cl.requirement_level}|${cl.description ?? ""}` ===
          clauseKey,
      );
      if (!clause) {
        clause = {
          clause_code: c.clause_code,
          clause_reference: c.clause_reference,
          requirement_level: c.requirement_level,
          description: c.description,
          fields: [],
        };
        body.clauses.push(clause);
      }

      // Avoid duplicate fields in the same clause
      if (
        !clause.fields.some((f) => f.field_code === c.field_code)
      ) {
        clause.fields.push({
          field_code: c.field_code,
          field_name: c.field_name,
        });
      }
    }

    return [...bodyMap.values()].sort((a, b) =>
      a.body_code.localeCompare(b.body_code),
    );
  }, [allClauses, search]);

  // When fieldId is set, auto-expand matching bodies
  const defaultExpanded = useMemo(() => {
    if (!fieldId) return undefined;
    return bodyGroups.map((b) => b.body_code);
  }, [fieldId, bodyGroups]);

  const totalClauses = useMemo(() => {
    return bodyGroups.reduce((acc, b) => acc + b.clauses.length, 0);
  }, [bodyGroups]);

  return (
    <Drawer
      opened={opened}
      onClose={onClose}
      position="right"
      size="lg"
      title={
        <Group gap="sm">
          <IconBook size={18} />
          <Text fw={600} size="sm">
            Regulatory Reference
          </Text>
          {fieldId && (
            <Badge size="xs" variant="light">
              Field-specific
            </Badge>
          )}
        </Group>
      }
    >
      <Stack gap="md" h="calc(100vh - 80px)">
        <TextInput
          placeholder="Search bodies, clauses, fields..."
          leftSection={<IconSearch size={14} />}
          value={search}
          onChange={(e) => setSearch(e.currentTarget.value)}
          size="sm"
        />

        <ScrollArea style={{ flex: 1 }} offsetScrollbars>
          {isLoading && (
            <Text size="sm" c="dimmed" ta="center" py="xl">
              Loading regulatory data...
            </Text>
          )}

          {!isLoading && bodyGroups.length === 0 && (
            <Text size="sm" c="dimmed" ta="center" py="xl">
              {allClauses?.length === 0
                ? "No regulatory clauses found."
                : "No clauses match your search."}
            </Text>
          )}

          {bodyGroups.length > 0 && (
            <Accordion
              multiple
              defaultValue={defaultExpanded}
              styles={{
                item: {
                  borderBottom: "1px solid var(--mantine-color-gray-2)",
                },
                control: {
                  paddingLeft: 8,
                  paddingRight: 8,
                },
              }}
            >
              {bodyGroups.map((body) => (
                <Accordion.Item key={body.body_code} value={body.body_code}>
                  <Accordion.Control>
                    <Group justify="space-between" wrap="nowrap" pr="xs">
                      <Group gap="xs">
                        <IconShield
                          size={16}
                          style={{ opacity: 0.5 }}
                        />
                        <div>
                          <Text size="sm" fw={600}>
                            {body.body_code}
                          </Text>
                          <Text size="xs" c="dimmed">
                            {body.body_name}
                          </Text>
                        </div>
                      </Group>
                      <Badge size="sm" variant="light" color="primary" circle>
                        {body.clauses.length}
                      </Badge>
                    </Group>
                  </Accordion.Control>
                  <Accordion.Panel>
                    <Stack gap="sm">
                      {body.clauses.map((clause, idx) => (
                        <Box
                          key={`${clause.clause_code ?? ""}-${clause.clause_reference ?? ""}-${idx}`}
                          p="sm"
                          style={{
                            border:
                              "1px solid var(--mantine-color-gray-2)",
                            borderRadius:
                              "var(--mantine-radius-sm)",
                            backgroundColor:
                              "var(--mantine-color-gray-0)",
                          }}
                        >
                          {/* Verse header: code + requirement */}
                          <Group
                            justify="space-between"
                            wrap="nowrap"
                            mb={clause.description ? 4 : 0}
                          >
                            <Text size="sm" fw={600} ff="monospace">
                              {clause.clause_code ??
                                clause.clause_reference ??
                                "—"}
                            </Text>
                            <Badge
                              size="xs"
                              variant="light"
                              color={
                                REQUIREMENT_COLORS[
                                  clause.requirement_level
                                ] ?? "slate"
                              }
                            >
                              {clause.requirement_level}
                            </Badge>
                          </Group>

                          {/* Clause reference if different from code */}
                          {clause.clause_code &&
                            clause.clause_reference && (
                              <Text size="xs" c="dimmed" mb={4}>
                                {clause.clause_reference}
                              </Text>
                            )}

                          {/* Description (the "verse text") */}
                          {clause.description && (
                            <Text size="xs" c="dimmed" mb="xs">
                              {clause.description}
                            </Text>
                          )}

                          {/* Linked fields */}
                          {clause.fields.length > 0 && (
                            <>
                              <Divider
                                my={6}
                                color="slate.2"
                              />
                              <Group gap={6}>
                                {clause.fields.map((f) => (
                                  <Badge
                                    key={f.field_code}
                                    size="xs"
                                    variant="outline"
                                    color="slate"
                                    leftSection="📎"
                                  >
                                    {f.field_code}
                                  </Badge>
                                ))}
                              </Group>
                            </>
                          )}
                        </Box>
                      ))}
                    </Stack>
                  </Accordion.Panel>
                </Accordion.Item>
              ))}
            </Accordion>
          )}

          {!isLoading && bodyGroups.length > 0 && (
            <Text size="xs" c="dimmed" ta="center" py="sm">
              {bodyGroups.length} bodies, {totalClauses} clauses
            </Text>
          )}
        </ScrollArea>
      </Stack>
    </Drawer>
  );
}
