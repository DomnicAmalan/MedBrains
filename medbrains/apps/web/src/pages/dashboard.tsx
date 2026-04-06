import {
  Badge,
  Box,
  Button,
  Card,
  Divider,
  Grid,
  Group,
  Loader,
  SimpleGrid,
  Stack,
  Text,
  ThemeIcon,
  UnstyledButton,
} from "@mantine/core";
import { useQuery } from "@tanstack/react-query";
import { api } from "@medbrains/api";
import { P } from "@medbrains/types";
import type { DashboardWithWidgets, RecentActivity } from "@medbrains/types";
import { useHasPermission } from "@medbrains/stores";
import { useNavigate } from "react-router";
import { useRequirePermission } from "../hooks/useRequirePermission";
import {
  IconActivity,
  IconArrowRight,
  IconBed,
  IconCalendar,
  IconClock,
  IconDashboard,
  IconFlask,
  IconHeartbeat,
  IconReceipt,
  IconServer,
  IconSettings,
  IconStethoscope,
  IconUserPlus,
  IconUsers,
} from "@tabler/icons-react";
import { PageHeader, StatCard } from "../components";
import { WidgetRenderer } from "../components/Dashboard/WidgetRenderer";

export function DashboardPage() {
  useRequirePermission(P.DASHBOARD.VIEW);
  const navigate = useNavigate();
  const canManage = useHasPermission(P.ADMIN.SETTINGS.GENERAL.MANAGE);

  // Try to load the user's configured dashboard
  const { data: dashboardData, isLoading } = useQuery({
    queryKey: ["my-dashboard"],
    queryFn: () => api.getMyDashboard(),
    retry: 1,
  });

  // Show configured dashboard if available
  if (isLoading) {
    return (
      <div>
        <PageHeader title="Dashboard" subtitle="Loading..." icon={<IconDashboard size={20} stroke={1.5} />} color="primary" />
        <Group justify="center" py="xl">
          <Loader />
        </Group>
      </div>
    );
  }

  // If we have a configured dashboard with widgets, render it dynamically
  if (dashboardData && dashboardData.widgets.length > 0) {
    return (
      <ConfiguredDashboard
        data={dashboardData}
        canManage={canManage}
        navigate={navigate}
      />
    );
  }

  // Fallback: render the default hardcoded dashboard
  return <DefaultDashboard navigate={navigate} canManage={canManage} />;
}

// ── Configured Dashboard (Dynamic) ──────────────────────

function ConfiguredDashboard({
  data,
  canManage,
  navigate,
}: {
  data: DashboardWithWidgets;
  canManage: boolean;
  navigate: ReturnType<typeof useNavigate>;
}) {
  const { dashboard, widgets } = data;
  const columns = (dashboard.layout_config as { columns?: number })?.columns ?? 12;

  return (
    <div>
      <PageHeader
        title={dashboard.name || "Dashboard"}
        subtitle={dashboard.description || "Overview of today's activity"}
        icon={<IconDashboard size={20} stroke={1.5} />}
        color="primary"
        actions={
          canManage ? (
            <Button
              variant="subtle"
              size="xs"
              leftSection={<IconSettings size={14} />}
              onClick={() =>
                navigate(`/admin/dashboard-builder/${dashboard.id}`)
              }
            >
              Customize
            </Button>
          ) : undefined
        }
      />

      <Box
        style={{
          display: "grid",
          gridTemplateColumns: `repeat(${columns}, 1fr)`,
          gap: 16,
        }}
      >
        {widgets.map((widget) => (
          <Box
            key={widget.id}
            style={{
              gridColumn: `${widget.position_x + 1} / span ${widget.width}`,
              gridRow: `${widget.position_y + 1} / span ${widget.height}`,
            }}
          >
            <WidgetRenderer widget={widget} />
          </Box>
        ))}
      </Box>
    </div>
  );
}

// ── Default Dashboard (Fallback) ────────────────────────

const quickActions = [
  {
    label: "Register Patient",
    description: "Add a new patient record",
    icon: IconUserPlus,
    color: "primary",
    path: "/patients",
  },
  {
    label: "New OPD Visit",
    description: "Create outpatient visit",
    icon: IconStethoscope,
    color: "teal",
    path: "/opd",
  },
  {
    label: "Lab Order",
    description: "Request lab investigation",
    icon: IconFlask,
    color: "orange",
    path: "/lab",
  },
  {
    label: "Generate Invoice",
    description: "Create billing invoice",
    icon: IconReceipt,
    color: "violet",
    path: "/billing",
  },
];

const ACTIVITY_ICON_MAP: Record<string, { icon: typeof IconActivity; color: string }> = {
  patient: { icon: IconUserPlus, color: "info" },
  opd: { icon: IconStethoscope, color: "teal" },
  lab: { icon: IconFlask, color: "success" },
  billing: { icon: IconReceipt, color: "violet" },
  appointment: { icon: IconCalendar, color: "blue" },
};

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function CardHeader({ title, action }: { title: string; action?: { label: string; onClick: () => void } }) {
  return (
    <>
      <Group justify="space-between" px="lg" py="sm">
        <Text size="sm" fw={600} c="var(--mb-text-primary)">{title}</Text>
        {action && (
          <Text
            size="xs"
            c="var(--mantine-color-primary-5)"
            fw={500}
            style={{ cursor: "pointer" }}
            onClick={action.onClick}
          >
            {action.label}
          </Text>
        )}
      </Group>
      <Divider />
    </>
  );
}

function DefaultDashboard({
  navigate,
  canManage,
}: {
  navigate: ReturnType<typeof useNavigate>;
  canManage: boolean;
}) {
  const { data: stats } = useQuery({
    queryKey: ["dashboard-stats"],
    queryFn: () => api.getDashboardStats(),
    refetchInterval: 30_000, // refresh every 30s
  });

  const formatRevenue = (val: string) => {
    const num = parseFloat(val);
    if (Number.isNaN(num) || num === 0) return "0";
    if (num >= 100_000) return `${(num / 100_000).toFixed(1)}L`;
    if (num >= 1_000) return `${(num / 1_000).toFixed(1)}K`;
    return num.toFixed(0);
  };

  return (
    <div>
      <PageHeader
        title="Dashboard"
        subtitle="Overview of today's activity"
        icon={<IconDashboard size={20} stroke={1.5} />}
        color="primary"
        actions={
          canManage ? (
            <Button
              variant="subtle"
              size="xs"
              leftSection={<IconSettings size={14} />}
              onClick={() => navigate("/admin/settings#dashboards")}
            >
              Customize
            </Button>
          ) : undefined
        }
      />

      {/* Stat Cards — Row 1 */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} mb="md">
        <StatCard
          label="Total Patients"
          value={stats?.total_patients ?? 0}
          icon={<IconUsers size={20} stroke={1.5} />}
          color="primary"
          trend={stats?.today_registrations ? { value: stats.today_registrations, label: "new today" } : undefined}
        />
        <StatCard
          label="OPD Queue"
          value={stats?.opd_queue_count ?? 0}
          icon={<IconStethoscope size={20} stroke={1.5} />}
          color="teal"
          trend={stats?.today_visits ? { value: stats.today_visits, label: "visits today" } : undefined}
        />
        <StatCard
          label="Lab Pending"
          value={stats?.lab_pending ?? 0}
          icon={<IconFlask size={20} stroke={1.5} />}
          color="orange"
        />
        <StatCard
          label="Revenue Today"
          value={stats ? `₹${formatRevenue(stats.today_revenue)}` : "--"}
          icon={<IconReceipt size={20} stroke={1.5} />}
          color="violet"
        />
      </SimpleGrid>

      {/* Stat Cards — Row 2 */}
      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} mb="xl">
        <StatCard
          label="Today's Appointments"
          value={stats?.today_appointments ?? 0}
          icon={<IconCalendar size={20} stroke={1.5} />}
          color="blue"
        />
        <StatCard
          label="IPD Active"
          value={stats?.ipd_active ?? 0}
          icon={<IconBed size={20} stroke={1.5} />}
          color="cyan"
        />
      </SimpleGrid>

      {/* Quick Actions + Activity */}
      <Grid mb="xl">
        <Grid.Col span={{ base: 12, md: 8 }}>
          <Card padding={0}>
            <CardHeader title="Quick Actions" />
            <SimpleGrid cols={{ base: 1, sm: 2 }} p="lg" spacing="md">
              {quickActions.map((action) => (
                <UnstyledButton
                  key={action.label}
                  onClick={() => navigate(action.path)}
                  className="clickable-card"
                  style={{
                    padding: 16,
                    borderRadius: 12,
                    background: "var(--mb-card-bg, #ffffff)",
                    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.06)",
                    display: "flex",
                    alignItems: "center",
                    gap: 12,
                  }}
                >
                  <ThemeIcon
                    variant="light"
                    color={action.color}
                    size={40}
                    radius="lg"
                  >
                    <action.icon size={20} stroke={1.5} />
                  </ThemeIcon>
                  <div style={{ flex: 1 }}>
                    <Text size="sm" fw={600} c="var(--mb-text-primary)">
                      {action.label}
                    </Text>
                    <Text size="xs" c="var(--mb-text-muted)">
                      {action.description}
                    </Text>
                  </div>
                  <IconArrowRight size={16} color="var(--mb-text-muted)" />
                </UnstyledButton>
              ))}
            </SimpleGrid>
          </Card>
        </Grid.Col>

        <Grid.Col span={{ base: 12, md: 4 }}>
          <Card padding={0} h="100%">
            <CardHeader title="Recent Activity" />
            <Stack gap={0}>
              {stats?.recent_activity && stats.recent_activity.length > 0 ? (
                stats.recent_activity.map((item: RecentActivity, i: number) => {
                  const meta = ACTIVITY_ICON_MAP[item.activity_type] ?? { icon: IconActivity, color: "slate" };
                  const ActivityIcon = meta.icon;
                  return (
                    <Box key={i}>
                      <Group gap="sm" wrap="nowrap" align="flex-start" px="lg" py="sm">
                        <ThemeIcon
                          variant="light"
                          color={meta.color}
                          size={28}
                          radius="lg"
                          mt={2}
                        >
                          <ActivityIcon size={14} stroke={1.5} />
                        </ThemeIcon>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <Text size="sm" c="var(--mb-text-primary)" lh={1.3}>
                            {item.description}
                          </Text>
                          <Group gap={4} mt={2}>
                            <IconClock size={11} color="var(--mb-text-muted)" />
                            <Text size="xs" c="var(--mb-text-muted)">
                              {timeAgo(item.occurred_at)}
                            </Text>
                          </Group>
                        </div>
                      </Group>
                      {i < stats.recent_activity.length - 1 && <Divider />}
                    </Box>
                  );
                })
              ) : (
                <Text size="sm" c="dimmed" ta="center" py="lg">
                  No recent activity
                </Text>
              )}
            </Stack>
          </Card>
        </Grid.Col>
      </Grid>

      {/* Bottom — Module Status + System Health */}
      <SimpleGrid cols={{ base: 1, sm: 2 }}>
        <Card padding={0}>
          <CardHeader title="Module Status" />
          <Stack gap="xs" p="lg">
            {[
              { name: "Patient Management", status: "Active" },
              { name: "OPD", status: "Active" },
              { name: "Appointments", status: "Active" },
              { name: "Laboratory", status: "Active" },
              { name: "Pharmacy", status: "Active" },
              { name: "Billing", status: "Active" },
              { name: "IPD", status: "Active" },
              { name: "Indent & Store", status: "Active" },
            ].map((mod) => (
              <Group key={mod.name} justify="space-between">
                <Text size="sm" c="var(--mb-text-secondary)">{mod.name}</Text>
                <Badge color="success" variant="light" size="sm">{mod.status}</Badge>
              </Group>
            ))}
          </Stack>
        </Card>
        <Card padding={0}>
          <CardHeader title="System Health" />
          <Stack gap="sm" p="lg">
            <Group justify="space-between">
              <Group gap="sm">
                <ThemeIcon variant="light" color="success" size={24} radius="lg">
                  <IconServer size={14} />
                </ThemeIcon>
                <Text size="sm" c="var(--mb-text-secondary)">API Server</Text>
              </Group>
              <Badge color="success" variant="light" size="sm">Healthy</Badge>
            </Group>
            <Group justify="space-between">
              <Group gap="sm">
                <ThemeIcon variant="light" color="success" size={24} radius="lg">
                  <IconServer size={14} />
                </ThemeIcon>
                <Text size="sm" c="var(--mb-text-secondary)">PostgreSQL</Text>
              </Group>
              <Badge color="success" variant="light" size="sm">Connected</Badge>
            </Group>
            <Group justify="space-between">
              <Group gap="sm">
                <ThemeIcon variant="light" color="slate" size={24} radius="lg">
                  <IconServer size={14} />
                </ThemeIcon>
                <Text size="sm" c="var(--mb-text-secondary)">YottaDB</Text>
              </Group>
              <Badge color="slate" variant="light" size="sm">Deferred</Badge>
            </Group>
            <Group justify="space-between">
              <Group gap="sm">
                <ThemeIcon variant="light" color="success" size={24} radius="lg">
                  <IconHeartbeat size={14} />
                </ThemeIcon>
                <Text size="sm" c="var(--mb-text-secondary)">Uptime</Text>
              </Group>
              <Text size="xs" c="var(--mb-text-secondary)" fw={500}>99.9%</Text>
            </Group>
          </Stack>
        </Card>
      </SimpleGrid>
    </div>
  );
}
