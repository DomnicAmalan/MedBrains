import type { ModuleConfig, ScreenSummary } from "@medbrains/types";
import { create } from "zustand";

interface ModuleRegistryState {
  modules: ModuleConfig[];
  screensByModule: Record<string, ScreenSummary[]>;
  isLoaded: boolean;
  isLoading: boolean;

  loadRegistry: (
    fetchModules: () => Promise<ModuleConfig[]>,
    fetchScreens: (moduleCode: string) => Promise<ScreenSummary[]>,
  ) => Promise<void>;

  getModuleScreens: (moduleCode: string) => ScreenSummary[];

  getScreenRoute: (screen: ScreenSummary) => string;
}

export const useModuleRegistryStore = create<ModuleRegistryState>((set, get) => ({
  modules: [],
  screensByModule: {},
  isLoaded: false,
  isLoading: false,

  loadRegistry: async (fetchModules, fetchScreens) => {
    const { isLoaded, isLoading } = get();
    if (isLoaded || isLoading) return;

    set({ isLoading: true });

    try {
      const modules = await fetchModules();
      const enabledModules = modules.filter((m) => m.status === "enabled");

      const screensByModule: Record<string, ScreenSummary[]> = {};

      // Fetch screens for all enabled modules in parallel
      const results = await Promise.allSettled(
        enabledModules.map(async (mod) => {
          const screens = await fetchScreens(mod.code);
          return { code: mod.code, screens };
        }),
      );

      for (const result of results) {
        if (result.status === "fulfilled") {
          const active = result.value.screens
            .filter((s) => s.is_active)
            .sort((a, b) => a.sort_order - b.sort_order);
          if (active.length > 0) {
            screensByModule[result.value.code] = active;
          }
        }
      }

      set({
        modules: enabledModules,
        screensByModule,
        isLoaded: true,
        isLoading: false,
      });
    } catch {
      set({ isLoading: false });
    }
  },

  getModuleScreens: (moduleCode) => {
    return get().screensByModule[moduleCode] ?? [];
  },

  getScreenRoute: (screen) => {
    if (screen.route_path) return screen.route_path;
    const moduleCode = screen.module_code ?? "general";
    return `/m/${moduleCode}/${screen.code}`;
  },
}));
