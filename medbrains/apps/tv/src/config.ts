// TV app connects to backend over LAN — update host for deployment
const DEFAULT_HOST = "localhost";
const DEFAULT_PORT = "3000";

export const config = {
  apiBase: `http://${DEFAULT_HOST}:${DEFAULT_PORT}/api`,
  wsBase: `ws://${DEFAULT_HOST}:${DEFAULT_PORT}/ws`,
} as const;
