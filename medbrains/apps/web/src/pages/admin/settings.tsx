import { Tabs } from "@mantine/core";
import { P } from "@medbrains/types";
import { usePermissionStore } from "@medbrains/stores";
import { useTranslation } from "react-i18next";
import { createElement, useMemo } from "react";
import { PageHeader } from "../../components";
import { useRequirePermission } from "../../hooks/useRequirePermission";
import { useHashTabs } from "../../hooks/useHashTabs";
import { SETTINGS_TABS, SETTINGS_TAB_ICON_MAP } from "../../config/settings-tabs";

export function SettingsPage() {
  const { t } = useTranslation("admin");
  const hasPermission = usePermissionStore((s) => s.hasPermission);

  const visibleTabs = useMemo(
    () => SETTINGS_TABS.filter((tab) => !tab.requiredPermission || hasPermission(tab.requiredPermission)),
    [hasPermission],
  );

  useRequirePermission(visibleTabs[0]?.requiredPermission ?? P.ADMIN.SETTINGS.GENERAL.MANAGE);

  const validValues = useMemo(() => visibleTabs.map((tab) => tab.value), [visibleTabs]);
  const [tab, setTab] = useHashTabs(visibleTabs[0]?.value ?? "general", validValues);

  return (
    <div>
      <PageHeader title={t("settings.title")} subtitle={t("settings.subtitle")} />
      <Tabs value={tab} onChange={setTab} mt="md">
        <Tabs.List>
          {visibleTabs.map((cfg) => {
            const Icon = SETTINGS_TAB_ICON_MAP[cfg.icon];
            return (
              <Tabs.Tab
                key={cfg.value}
                value={cfg.value}
                leftSection={Icon ? createElement(Icon, { size: 16 }) : undefined}
              >
                {t(cfg.i18nKey)}
              </Tabs.Tab>
            );
          })}
        </Tabs.List>

        {visibleTabs.map((cfg) => (
          <Tabs.Panel key={cfg.value} value={cfg.value} pt="md">
            <cfg.component />
          </Tabs.Panel>
        ))}
      </Tabs>
    </div>
  );
}
