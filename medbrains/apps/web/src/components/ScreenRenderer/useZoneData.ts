import { getApiBase } from "@medbrains/api";
import { useQuery } from "@tanstack/react-query";

interface UseZoneDataOptions {
  dataSource?: string;
  filters?: Record<string, string>;
  enabled?: boolean;
}

interface UseZoneDataResult {
  data: Record<string, unknown>[] | Record<string, unknown> | null;
  isLoading: boolean;
  error: Error | null;
  refetch: () => void;
}

async function fetchZoneData(
  apiPath: string,
  filters?: Record<string, string>,
): Promise<Record<string, unknown>[] | Record<string, unknown>> {
  const queryParams = filters
    ? `?${new URLSearchParams(filters).toString()}`
    : "";
  const url = `${getApiBase()}${apiPath}${queryParams}`;
  const res = await fetch(url, { credentials: "include" });
  if (!res.ok) throw new Error(`Zone data fetch failed: ${res.status}`);
  return res.json() as Promise<Record<string, unknown>[] | Record<string, unknown>>;
}

/**
 * Hook that resolves a zone's `data_source` config into live data.
 *
 * Conventions:
 * - `api:/path` → GET request to `/path` (relative to API base)
 * - empty / undefined → no fetch, returns null (zone uses context prop directly)
 */
export function useZoneData({
  dataSource,
  filters,
  enabled = true,
}: UseZoneDataOptions): UseZoneDataResult {
  const isApiSource = dataSource?.startsWith("api:") === true;
  const apiPath = isApiSource && dataSource ? dataSource.slice(4) : null;

  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ["zone-data", dataSource ?? "", filters],
    queryFn: () => fetchZoneData(apiPath!, filters),
    enabled: enabled && Boolean(apiPath),
    staleTime: 30_000,
  });

  return {
    data: data ?? null,
    isLoading,
    error: error as Error | null,
    refetch,
  };
}
