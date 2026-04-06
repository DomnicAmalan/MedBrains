import { Tabs } from "@mantine/core";
import { useHashTabs } from "../../../hooks/useHashTabs";
import { FormMasterList } from "./FormMasterList";
import { FieldMasterList } from "./FieldMasterList";
import { ModuleFormLinks } from "./ModuleFormLinks";
import { TenantFieldOverrides } from "./TenantFieldOverrides";

const SUB_TABS = ["forms", "fields", "module-links", "overrides"] as const;

export function FormsManagement() {
  const [tab, setTab] = useHashTabs("forms", [...SUB_TABS], { nested: true });

  return (
    <Tabs value={tab} onChange={setTab}>
      <Tabs.List>
        <Tabs.Tab value="forms">Forms</Tabs.Tab>
        <Tabs.Tab value="fields">Fields</Tabs.Tab>
        <Tabs.Tab value="module-links">Module Links</Tabs.Tab>
        <Tabs.Tab value="overrides">Overrides</Tabs.Tab>
      </Tabs.List>

      <Tabs.Panel value="forms" pt="md">
        <FormMasterList />
      </Tabs.Panel>
      <Tabs.Panel value="fields" pt="md">
        <FieldMasterList />
      </Tabs.Panel>
      <Tabs.Panel value="module-links" pt="md">
        <ModuleFormLinks />
      </Tabs.Panel>
      <Tabs.Panel value="overrides" pt="md">
        <TenantFieldOverrides />
      </Tabs.Panel>
    </Tabs>
  );
}
