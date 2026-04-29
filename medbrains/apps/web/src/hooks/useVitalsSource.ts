/**
 * useVitalsSource — unified data hook for vital signs that switches
 * between the cloud REST flow and the on-prem CRDT flow at runtime.
 *
 * Why a per-domain hook (instead of a generic one): vitals are T2
 * append-only events with a fixed schema; consumers can target this
 * narrow surface without learning Loro internals. Other domains
 * (notes, handoff, triage) get their own thin wrappers — each picks
 * the right CRDT primitive (LoroList vs LoroText) for that domain.
 *
 * REST mode = TanStack Query against `/opd/encounters/.../vitals`.
 * CRDT mode = `useAppendOnlyCrdtList` against the medbrains-edge
 * appliance on the hospital LAN. Records merge across browser tabs +
 * native devices; an offline-tolerant clinic keeps capturing vitals
 * while the WAN is down and drains on reconnect.
 *
 * Mode is selected by the consumer for now (prop). When tenant
 * settings expose `offline_mode`, a thin context provider can read
 * it once and pass it down — the hook signature won't change.
 */

import { useCallback } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@medbrains/api";
import type { CreateVitalRequest, Vital } from "@medbrains/types";
import {
  useAppendOnlyCrdtList,
  type CrdtConnectionStatus,
} from "@medbrains/crdt";

export type VitalsSourceMode = "rest" | "crdt";

export interface UseVitalsSourceOptions {
  encounterId: string;
  mode: VitalsSourceMode;
  /** Required when mode === "crdt" */
  edgeUrl?: string;
  tenantId?: string;
  deviceId?: string;
}

export interface VitalsSourceResult {
  records: Vital[];
  /**
   * Submit a new reading. REST mode round-trips to the server and
   * invalidates the query on success. CRDT mode appends to the local
   * Loro doc and queues a Push frame to the edge.
   */
  append: (data: CreateVitalRequest) => void;
  /**
   * Connection status. `"online"` means up-to-date with the source
   * of truth (cloud or edge); `"offline"` means writes are buffered
   * locally for later replay; `"error"` means the source is
   * unreachable and the consumer should show a banner.
   */
  status: CrdtConnectionStatus | "loading" | "online" | "error";
  ready: boolean;
  /** Number of writes queued locally that haven't synced yet. */
  unsyncedOps: number;
}

export function useVitalsSource(opts: UseVitalsSourceOptions): VitalsSourceResult {
  if (opts.mode === "crdt") {
    return useVitalsCrdt(opts);
  }
  return useVitalsRest(opts);
}

// ── REST path (existing cloud flow) ─────────────────────────────────

function useVitalsRest({
  encounterId,
}: UseVitalsSourceOptions): VitalsSourceResult {
  const qc = useQueryClient();
  const query = useQuery<Vital[]>({
    queryKey: ["vitals", encounterId],
    queryFn: () => api.listVitals(encounterId),
    enabled: !!encounterId,
  });
  const mutation = useMutation({
    mutationFn: (data: CreateVitalRequest) => api.createVital(encounterId, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["vitals", encounterId] });
    },
  });
  const append = useCallback(
    (data: CreateVitalRequest) => mutation.mutate(data),
    [mutation],
  );

  let status: VitalsSourceResult["status"];
  if (query.isLoading) status = "loading";
  else if (query.isError) status = "error";
  else status = "online";

  return {
    records: query.data ?? [],
    append,
    status,
    ready: !query.isLoading,
    unsyncedOps: mutation.isPending ? 1 : 0,
  };
}

// ── CRDT path (medbrains-edge LAN sync) ─────────────────────────────

interface CrdtVitalEntry extends Record<string, unknown> {
  ts: number;
  recordedBy: string;
  temperature?: number;
  pulse?: number;
  systolic_bp?: number;
  diastolic_bp?: number;
  respiratory_rate?: number;
  spo2?: number;
  weight_kg?: number;
  height_cm?: number;
  notes?: string;
}

function useVitalsCrdt({
  encounterId,
  edgeUrl,
  tenantId,
  deviceId,
}: UseVitalsSourceOptions): VitalsSourceResult {
  if (!edgeUrl || !tenantId || !deviceId) {
    throw new Error(
      "useVitalsSource: edgeUrl + tenantId + deviceId required when mode='crdt'",
    );
  }
  const list = useAppendOnlyCrdtList<CrdtVitalEntry>(`vitals/${encounterId}`, {
    edgeUrl,
    tenantId,
    deviceId,
  });

  const append = useCallback(
    (data: CreateVitalRequest) => {
      list.append({
        ts: Date.now(),
        recordedBy: deviceId,
        ...data,
      } as CrdtVitalEntry);
    },
    [list, deviceId],
  );

  // Adapt CrdtVitalEntry to the existing Vital shape so consumers
  // don't have to branch on mode. Numeric fields stay numeric in
  // CRDT but the existing Vital type uses string for decimals;
  // stringify them for shape compatibility.
  const records: Vital[] = list.entries.map((e) => ({
    id: `${encounterId}/${e.ts}`,
    tenant_id: tenantId,
    encounter_id: encounterId,
    temperature: e.temperature !== undefined ? String(e.temperature) : null,
    pulse: e.pulse ?? null,
    systolic_bp: e.systolic_bp ?? null,
    diastolic_bp: e.diastolic_bp ?? null,
    respiratory_rate: e.respiratory_rate ?? null,
    spo2: e.spo2 ?? null,
    weight_kg: e.weight_kg !== undefined ? String(e.weight_kg) : null,
    height_cm: e.height_cm !== undefined ? String(e.height_cm) : null,
    bmi: null,
    notes: e.notes ?? null,
    recorded_by: e.recordedBy,
    created_at: new Date(e.ts).toISOString(),
  }));

  return {
    records,
    append,
    status: list.status,
    ready: list.ready,
    unsyncedOps: list.unsyncedOps,
  };
}
