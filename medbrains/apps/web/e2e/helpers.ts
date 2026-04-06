/**
 * Shared E2E test helpers.
 *
 * Extracted from patients.spec.ts for reuse across smoke tests and
 * scenario tests.
 */

import type { Page, APIRequestContext } from "@playwright/test";

export const BACKEND_URL =
  process.env.E2E_BACKEND_URL ?? "http://127.0.0.1:3000";

/**
 * Intercept /api/* requests at the Playwright network layer and forward
 * them directly to the backend, bypassing Vite proxy issues in Playwright.
 */
export async function routeApiDirect(page: Page) {
  await page.route(
    (url) => url.pathname.startsWith("/api/") || url.pathname === "/api",
    async (route) => {
      const url = new URL(route.request().url());
      const backendUrl = `${BACKEND_URL}${url.pathname}${url.search}`;
      try {
        const response = await route.fetch({ url: backendUrl });
        await route.fulfill({ response });
      } catch {
        // Page navigated away while request was in flight
      }
    },
  );
}

/**
 * Re-authenticate inline if the session expired. Sets localStorage and
 * cookies so subsequent page navigations remain authenticated.
 */
export async function ensureAuthenticated(page: Page) {
  if (!page.url().includes("/login")) return;

  const resp = await page.request.post(`${BACKEND_URL}/api/auth/login`, {
    data: { username: "admin", password: "admin123" },
  });
  if (!resp.ok()) return;

  const data = await resp.json();

  await page.evaluate(
    (user) => {
      localStorage.setItem(
        "auth-storage",
        JSON.stringify({ state: { user }, version: 0 }),
      );
    },
    data.user,
  );

  const setCookieHeaders = resp
    .headersArray()
    .filter((h) => h.name.toLowerCase() === "set-cookie");
  const cookies = setCookieHeaders
    .map((h) => {
      const parts = h.value.split(";").map((p: string) => p.trim());
      const [nameVal] = parts;
      if (!nameVal) return null;
      const eqIdx = nameVal.indexOf("=");
      if (eqIdx < 0) return null;
      return {
        name: nameVal.slice(0, eqIdx),
        value: nameVal.slice(eqIdx + 1),
        domain: "localhost",
        path:
          parts
            .find((p: string) => p.toLowerCase().startsWith("path="))
            ?.split("=")[1] ?? "/",
        httpOnly: parts.some((p: string) => p.toLowerCase() === "httponly"),
        secure: false,
        sameSite: "Lax" as const,
      };
    })
    .filter(Boolean) as Array<{
    name: string;
    value: string;
    domain: string;
    path: string;
    httpOnly: boolean;
    secure: boolean;
    sameSite: "Lax";
  }>;

  if (cookies.length > 0) {
    await page.context().addCookies(cookies);
  }
}

/**
 * Navigate to a page path, re-authenticating if redirected to login.
 */
export async function navigateTo(page: Page, path: string) {
  await page.goto(path);
  await ensureAuthenticated(page);
  if (page.url().includes("/login")) {
    await page.goto(path);
  }
}

/**
 * Get a logged-in auth token for direct API calls (smoke tests).
 * Returns the full cookie header string.
 */
export async function getAuthToken(
  request: APIRequestContext,
): Promise<{
  token: string;
  cookies: string;
}> {
  const resp = await request.post(`${BACKEND_URL}/api/auth/login`, {
    data: { username: "admin", password: "admin123" },
  });

  const setCookieHeaders = resp
    .headersArray()
    .filter((h) => h.name.toLowerCase() === "set-cookie");

  const cookieParts = setCookieHeaders.map((h) => {
    const nameVal = h.value.split(";")[0];
    return nameVal;
  });

  return {
    token: "",
    cookies: cookieParts.join("; "),
  };
}
