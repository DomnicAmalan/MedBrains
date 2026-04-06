/**
 * ClinicalEventProvider — Decouples sidecar functionality from ScreenRenderer.
 *
 * Allows hardcoded clinical pages (OPD, Lab, Billing, etc.) to participate in
 * the sidecar/pipeline system by fetching module-level sidecars and providing
 * an `emit(trigger, payload)` function identical to SidecarProvider.
 *
 * Falls back gracefully: if no sidecars are configured, emit is a no-op.
 */
import { api } from "@medbrains/api";
import type { ResolvedSidecar } from "@medbrains/types";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  type ReactNode,
} from "react";
import { useNavigate } from "react-router";
import { evaluateCondition } from "./ScreenRenderer/evaluateCondition";
import { executeInlineAction } from "./ScreenRenderer/executeInlineAction";

interface ClinicalEventContextValue {
  emit: (trigger: string, payload: Record<string, unknown>) => void;
}

const ClinicalEventCtx = createContext<ClinicalEventContextValue>({
  emit: () => {},
});

export function useClinicalEmit() {
  return useContext(ClinicalEventCtx).emit;
}

interface ClinicalEventProviderProps {
  moduleCode: string;
  contextCode: string;
  children: ReactNode;
}

export function ClinicalEventProvider({
  moduleCode,
  contextCode,
  children,
}: ClinicalEventProviderProps) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const firingRef = useRef(false);

  const { data: sidecars } = useQuery({
    queryKey: ["module-sidecars", moduleCode, contextCode],
    queryFn: () => api.listModuleSidecars(moduleCode, contextCode),
    staleTime: 5 * 60 * 1000,
  });

  const activeSidecars = useMemo(() => sidecars ?? [], [sidecars]);

  const emit = useCallback(
    async (trigger: string, payload: Record<string, unknown>) => {
      if (firingRef.current) return;
      if (activeSidecars.length === 0) return;

      firingRef.current = true;
      try {
        const matching = activeSidecars.filter(
          (s) => s.trigger_event === trigger,
        );

        for (const sidecar of matching) {
          if (!evaluateCondition(sidecar.condition, payload)) continue;

          await executeSidecar(sidecar, payload);
        }
      } finally {
        firingRef.current = false;
      }
    },
    [activeSidecars],
  );

  const executeSidecar = async (
    sidecar: ResolvedSidecar,
    data: Record<string, unknown>,
  ) => {
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
    <ClinicalEventCtx.Provider value={value}>
      {children}
    </ClinicalEventCtx.Provider>
  );
}
