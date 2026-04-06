import { useQuery } from "@tanstack/react-query";
import { getApiBase } from "@medbrains/api";
import type { FieldDataSource, ResolvedField } from "@medbrains/types";

interface SelectOption {
  value: string;
  label: string;
}

/**
 * Fetches options from an API data source at runtime.
 *
 * - `static` or null data_source → returns empty (static options handled elsewhere)
 * - `api` → fetches endpoint, maps valueKey/labelKey
 * - `dependent` → same as api, but adds parent field value as query param;
 *   query is only enabled when parent value is truthy
 */
export function useFieldDataSource(
  field: ResolvedField,
  formValues: Record<string, unknown>,
): { options: SelectOption[]; isLoading: boolean } {
  const ds = field.data_source as FieldDataSource | null;

  const isApiSource = ds?.type === "api" || ds?.type === "dependent";
  const parentValue = ds?.type === "dependent" && ds.dependsOn
    ? formValues[ds.dependsOn]
    : undefined;

  const isEnabled = isApiSource
    && Boolean(ds?.endpoint)
    && (ds?.type !== "dependent" || Boolean(parentValue));

  const queryKey = [
    "field-data-source",
    ds?.endpoint ?? "",
    ds?.method ?? "GET",
    JSON.stringify(ds?.params ?? {}),
    ds?.type === "dependent" ? String(parentValue ?? "") : "",
  ];

  const { data, isLoading } = useQuery<SelectOption[]>({
    queryKey,
    queryFn: async () => {
      if (!ds?.endpoint) return [];

      const params = new URLSearchParams(ds.params ?? {});

      // For dependent sources, add parent value as query param
      if (ds.type === "dependent" && ds.parentParamKey && parentValue) {
        params.set(ds.parentParamKey, String(parentValue));
      }

      const base = ds.endpoint.startsWith("/") ? getApiBase() : "";
      const qs = params.toString();
      const url = `${base}${ds.endpoint}${qs ? `?${qs}` : ""}`;

      const resp = await fetch(url, {
        method: ds.method ?? "GET",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
      });

      if (!resp.ok) return [];

      const json = await resp.json();
      const items: unknown[] = Array.isArray(json)
        ? json
        : (json.data ?? json.items ?? []);

      const vk = ds.valueKey ?? "id";
      const lk = ds.labelKey ?? "name";

      return items.map((item) => {
        const rec = item as Record<string, unknown>;
        return {
          value: String(rec[vk] ?? ""),
          label: String(rec[lk] ?? ""),
        };
      });
    },
    enabled: isEnabled,
    staleTime: 30_000,
    refetchOnWindowFocus: false,
  });

  if (!isApiSource) {
    return { options: [], isLoading: false };
  }

  return { options: data ?? [], isLoading };
}
