import { MutationCache, QueryCache, QueryClient } from "@tanstack/react-query";
import { useAuthStore } from "./auth-store.js";

function handleGlobalError(error: Error): void {
  if (error.message === "session_expired") {
    useAuthStore.getState().clearAuth();
  }
}

export function createQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        retry: (failureCount, error) => {
          // Don't retry on session expiry
          if (error instanceof Error && error.message === "session_expired") {
            return false;
          }
          return failureCount < 1;
        },
      },
    },
    queryCache: new QueryCache({
      onError: (error) => handleGlobalError(error as Error),
    }),
    mutationCache: new MutationCache({
      onError: (error) => handleGlobalError(error as Error),
    }),
  });
}
