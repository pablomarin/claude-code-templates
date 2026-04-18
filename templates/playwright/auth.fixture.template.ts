/**
 * Auth fixture — shared setup for authenticated tests.
 *
 * ⚠️ SECURITY WARNING
 * Playwright's `storageState` captures cookies, localStorage, AND sessionStorage
 * into a JSON file on disk. If Playwright tracing or video is enabled in CI,
 * anything in that storage can leak into CI artifacts that are downloadable by
 * anyone with repo read access. The shipped playwright.config.ts defaults trace
 * and video to `off` on CI for that reason — keep it that way unless you've
 * reviewed the risk for your project.
 *
 * Pattern: authenticate ONCE, save storage state, reuse across all specs.
 * Avoids per-test UI login (slow, flaky).
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
 *   TEST_USER_EMAIL + TEST_USER_PASSWORD
 *
 * The default (cookie-based session login) is the secure path: the session
 * cookie goes into storageState but is typically httpOnly/Secure, and browser
 * JS cannot exfiltrate it. The API-key-in-localStorage alternative is commented
 * out below because persisting bearer tokens in client-accessible storage
 * increases the blast radius of any artifact leak.
 */
import { test as setup, expect } from "@playwright/test";
import path from "path";

const authFile = path.join(__dirname, "../.auth/user.json");

setup("authenticate", async ({ page, context }): Promise<void> => {
  const email = process.env.TEST_USER_EMAIL;
  const password = process.env.TEST_USER_PASSWORD;

  if (!email || !password) {
    throw new Error(
      "[auth] Missing credentials. Set TEST_USER_EMAIL + TEST_USER_PASSWORD. " +
        "For API-key auth, see the commented example in this file — but read " +
        "the security warning at the top first.",
    );
  }

  // Default: cookie/session login via API.
  // context.request posts through the browser context so session cookies
  // land in the browser's cookie jar (the top-level `request` fixture has
  // a SEPARATE jar — using it here would NOT persist cookies).
  const response = await context.request.post("/api/auth/login", {
    data: { email, password },
  });
  expect(response.ok()).toBeTruthy();
  console.log("[auth] Authenticated via email/password (session cookie)");

  // Save authenticated browser state (cookies) for reuse across specs.
  await context.storageState({ path: authFile });
  console.log(`[auth] State saved to ${authFile}`);

  /*
   * --- INSECURE ALTERNATIVE — LOCAL DEV ONLY ---
   *
   * Some apps expect a bearer token in localStorage instead of a cookie.
   * Persisting one here means it ends up in storageState on disk AND,
   * if tracing/video is ever turned on in CI, inside CI artifacts.
   *
   * Only use this path on a local dev machine with a throwaway token,
   * and NEVER commit the generated tests/e2e/.auth/*.json file
   * (the .gitignore shipped by setup.sh --with-playwright already excludes it).
   *
   *   const apiKey = process.env.TEST_API_KEY;
   *   if (apiKey) {
   *     await page.goto('/');
   *     await page.evaluate((token) => {
   *       window.localStorage.setItem('auth_token', token);
   *     }, apiKey);
   *     await context.storageState({ path: authFile });
   *   }
   */
});
