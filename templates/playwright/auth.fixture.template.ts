/**
 * Auth fixture — shared setup for authenticated tests.
 *
 * Pattern: authenticate ONCE via API (fast, deterministic), save storage state,
 * reuse across all specs. Avoids per-test UI login (slow, flaky).
 *
 * Usage:
 *   1. Customize the login call below to match your API
 *   2. In playwright.config.ts, set: storageState: 'tests/e2e/.auth/user.json'
 *   3. Run `pnpm exec playwright test --project=setup` before your main suite,
 *      OR use as a global setup (see https://playwright.dev/docs/auth)
 *
 * Env vars expected:
 *   TEST_USER_EMAIL, TEST_USER_PASSWORD, or TEST_API_KEY
 */
import { test as setup, expect } from "@playwright/test";
import path from "path";

const authFile = path.join(__dirname, "../.auth/user.json");

setup("authenticate", async ({ request, context }) => {
  // Prefer API-key auth for speed. Falls back to email/password if not provided.
  const apiKey = process.env.TEST_API_KEY;
  const email = process.env.TEST_USER_EMAIL;
  const password = process.env.TEST_USER_PASSWORD;

  if (apiKey) {
    // API key in header — adjust to your auth scheme (Bearer, X-API-Key, etc.)
    await context.setExtraHTTPHeaders({ Authorization: `Bearer ${apiKey}` });
    console.log("[auth] Using TEST_API_KEY for authentication");
  } else if (email && password) {
    // Example: POST to /api/auth/login and store session cookie
    const response = await request.post("/api/auth/login", {
      data: { email, password },
    });
    expect(response.ok()).toBeTruthy();
    console.log("[auth] Authenticated via email/password");
  } else {
    throw new Error(
      "[auth] No credentials found. Set TEST_API_KEY or TEST_USER_EMAIL + TEST_USER_PASSWORD.",
    );
  }

  // Save the authenticated browser state (cookies, localStorage) for reuse.
  await context.storageState({ path: authFile });
  console.log(`[auth] State saved to ${authFile}`);
});
