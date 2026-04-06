import { Anchor, Breadcrumbs, Card, Group, Text, ThemeIcon, Title } from "@mantine/core";
import type { ReactNode } from "react";
import styles from "./page-header.module.scss";

interface BreadcrumbItem {
  label: string;
  href?: string;
}

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  description?: string;
  actions?: ReactNode;
  icon?: ReactNode;
  color?: string;
  breadcrumbs?: BreadcrumbItem[];
}

export function PageHeader({
  title,
  subtitle,
  description,
  actions,
  icon,
  color,
  breadcrumbs,
}: PageHeaderProps) {
  return (
    <div className={styles.wrapper}>
      <Card className={styles.card} padding={0} radius="md" shadow="xs">
        {color ? (
          <div
            className={styles.accentBarColored}
            style={{
              background: `linear-gradient(90deg, var(--mantine-color-${color}-5), var(--mantine-color-${color}-3))`,
            }}
          />
        ) : (
          <div className={styles.accentBar} />
        )}

        <div className={styles.inner}>
          {breadcrumbs && breadcrumbs.length > 0 && (
            <Breadcrumbs className={styles.breadcrumbs} separator="/">
              {breadcrumbs.map((item) =>
                item.href ? (
                  <Anchor href={item.href} key={item.label} size="xs" c="var(--mb-text-muted)">
                    {item.label}
                  </Anchor>
                ) : (
                  <Text key={item.label} size="xs" c="var(--mb-text-muted)">
                    {item.label}
                  </Text>
                ),
              )}
            </Breadcrumbs>
          )}

          <div className={styles.titleRow}>
            <div className={styles.titleGroup}>
              {icon && (
                <ThemeIcon
                  variant="light"
                  color={color ?? "primary"}
                  size={40}
                  radius="lg"
                >
                  {icon}
                </ThemeIcon>
              )}
              <div className={styles.textBlock}>
                <Title order={3} fw={600} c="var(--mb-text-primary)" lh={1.2}>
                  {title}
                </Title>
                {subtitle && (
                  <Text size="sm" c="var(--mb-text-secondary)" mt={2}>
                    {subtitle}
                  </Text>
                )}
                {description && (
                  <Text size="sm" c="var(--mb-text-muted)" mt={4} maw={600}>
                    {description}
                  </Text>
                )}
              </div>
            </div>
            {actions && <Group gap="xs">{actions}</Group>}
          </div>
        </div>
      </Card>
    </div>
  );
}
