let apiBase = "/api";

export function setApiBase(base: string): void {
  apiBase = base.replace(/\/+$/, "");
}

export function getApiBase(): string {
  return apiBase;
}
