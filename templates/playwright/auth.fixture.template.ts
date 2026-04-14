/**
 * Auth fixture — shared setup for authenticated tests.
 *
 * Pattern: authenticate ONCE via API (fast, deterministic), save storage state,
 * reuse across all specs. Avoids per-test UI login (slow, flaky).
 *
 * Usage:
 *   1. Customize the login call below to match your API.
 *   2. Wire up a `setup` project in playwright.config.ts so this fixture
 *      runs before the main suite. See the commented block in the generated
 *      playwright.config.ts (search for "setup project").
 *   3. Set `storageState: 'tests/e2e/.auth/user.json'` on the main project's
 *      `use` config (or per-test with `test.use({ storageState: ... })`).
 *   4. See https://playwright.dev/docs/auth for patterns and options.
 *
 * Env vars expected:
 *   TEST_USER_EMAIL + TEST_USER_PASSWORD, or TEST_API_KEY
 *
 * IMPORTANT: storage state only persists cookies, localStorage, and
 * sessionStorage — NOT extra HTTP headers. The API-key path below writes
 * the token to localStorage so it survives into the storage state.
 */
import { test as setup, expect } from "@playwright/test";
import path from "path";

const authFile = path.join(__dirname, "../.auth/user.json");

setup("authenticate", async ({ page, context }): Promise<void> => {
  const apiKey = process.env.TEST_API_KEY;
  const email = process.env.TEST_USER_EMAIL;
  const password = process.env.TEST_USER_PASSWORD;

  if (apiKey) {
    // Persist API key via localStorage so it's captured in storage state.
    // Adjust the storage key ("auth_token") to whatever your frontend reads.
    await page.goto("/");
    await page.evaluate((token) => {
      window.localStorage.setItem("auth_token", token);
    }, apiKey);
    console.log("[auth] Using TEST_API_KEY (stored in localStorage)");
  } else if (email && password) {
    // Use context.request so session cookies land in the browser context
    // (the top-level `request` fixture has a SEPARATE storage jar).
    const response = await context.request.post("/api/auth/login", {
      data: { email, password },
    });
    expect(response.ok()).toBeTruthy();
    console.log("[auth] Authenticated via email/password");
  } else {
    throw new Error(
      "[auth] No credentials found. Set TEST_API_KEY or TEST_USER_EMAIL + TEST_USER_PASSWORD.",
    );
  }

  // Save authenticated browser state (cookies + localStorage) for reuse.
  await context.storageState({ path: authFile });
  console.log(`[auth] State saved to ${authFile}`);
});
