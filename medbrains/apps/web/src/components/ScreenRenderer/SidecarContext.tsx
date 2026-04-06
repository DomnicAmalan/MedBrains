import { api } from "@medbrains/api";
import type { ResolvedScreen, ResolvedSidecar } from "@medbrains/types";
import { useQueryClient } from "@tanstack/react-query";
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  type ReactNode,
} from "react";
import { useNavigate } from "react-router";
import { evaluateCondition } from "./evaluateCondition";
import { executeInlineAction } from "./executeInlineAction";

interface SidecarContextValue {
  emit: (trigger: string, payload: Record<string, unknown>) => void;
}

const SidecarCtx = createContext<SidecarContextValue>({
  emit: () => {},
});

export function useSidecarEmit() {
  return useContext(SidecarCtx).emit;
}

interface SidecarProviderProps {
  screen: ResolvedScreen;
  context: Record<string, unknown>;
  children: ReactNode;
}

export function SidecarProvider({
  screen,
  context,
  children,
}: SidecarProviderProps) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const firingRef = useRef(false);

  // Resolved sidecars are already filtered to active-only by the backend
  const activeSidecars = useMemo(
    () => screen.sidecars ?? [],
    [screen.sidecars],
  );

  const emit = useCallback(
    async (trigger: string, payload: Record<string, unknown>) => {
      // Prevent re-entrant firing (e.g., action triggers another sidecar)
      if (firingRef.current) return;
      firingRef.current = true;

      try {
        const matching = activeSidecars.filter(
          (s) => s.trigger_event === trigger,
        );

        const mergedData = { ...context, ...payload };

        for (const sidecar of matching) {
          if (!evaluateCondition(sidecar.condition, mergedData)) continue;

          await executeSidecar(sidecar, mergedData);
        }
      } finally {
        firingRef.current = false;
      }
    },
    [activeSidecars, context],
  );

  const executeSidecar = async (
    sidecar: ResolvedSidecar,
    data: Record<string, unknown>,
  ) => {
    // Pipeline mode
    if (sidecar.pipeline_id) {
      try {
        await api.triggerPipeline(sidecar.pipeline_id, {
          input_data: data,
        });
      } catch {
        // Pipeline trigger failures are non-blocking
      }
      return;
    }

    // Inline action mode
    if (sidecar.inline_action) {
      await executeInlineAction(sidecar.inline_action, {
        navigate,
        queryClient,
        screenData: data,
      });
    }
  };

  const value = useMemo(() => ({ emit }), [emit]);

  return (
    <SidecarCtx.Provider value={value}>{children}</SidecarCtx.Provider>
  );
}
