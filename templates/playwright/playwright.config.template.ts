import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright configuration.
 * See https://playwright.dev/docs/test-configuration for full options.
 */
export default defineConfig({
  // Location of spec files (graduated from tests/e2e/use-cases/ via verify-e2e Phase 6.2c)
  testDir: "./tests/e2e/specs",

  // Parallelize tests in a single file. CI uses full parallelization.
  fullyParallel: true,

  // Fail build on CI if test.only is accidentally left in code
  forbidOnly: !!process.env.CI,

  // Retry on CI only — no retries locally for faster feedback
  retries: process.env.CI ? 2 : 0,

  // Workers: use all cores locally, limit on CI to avoid contention
  workers: process.env.CI ? 2 : undefined,

  // HTML reporter by default; JSON for CI artifact upload
  reporter: process.env.CI
    ? [
        ["html", { open: "never" }],
        ["json", { outputFile: "tests/e2e/reports/results.json" }],
      ]
    : "html",

  use: {
    // Base URL — override via PLAYWRIGHT_BASE_URL env var
    baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://localhost:3000",

    // SECURITY: trace and video are OFF by default in CI.
    //
    // Why: storageState (see below) persists cookies + localStorage for
    // authenticated tests. Playwright traces and videos can capture those
    // values into CI artifacts that are downloadable by anyone with repo
    // read access. Leaving trace/video on in CI is a credential-leak risk.
    //
    // Local dev: retain on failure — you want them for debugging.
    // CI: off by default. To opt in temporarily for a debugging session,
    // set PLAYWRIGHT_CI_TRACE=1 and PLAYWRIGHT_CI_VIDEO=1 on that run only,
    // and review artifacts before making the run public.
    //
    // See tests/e2e/fixtures/auth.ts for the auth/storage-state pattern.
    trace: process.env.CI
      ? process.env.PLAYWRIGHT_CI_TRACE
        ? "on-first-retry"
        : "off"
      : "retain-on-failure",

    // Screenshots on failure (no credentials in screenshots by default)
    screenshot: "only-on-failure",

    video: process.env.CI
      ? process.env.PLAYWRIGHT_CI_VIDEO
        ? "retain-on-failure"
        : "off"
      : "retain-on-failure",

    // Reuse authenticated storage state from auth fixture
    // Uncomment after running auth setup (see tests/e2e/fixtures/auth.ts):
    // storageState: 'tests/e2e/.auth/user.json',
  },

  // Browser projects. Chromium covers 80%+ of production bugs; enable Firefox/WebKit
  // as needed. See tests/e2e/fixtures/auth.ts to enable authenticated tests.
  projects: [
    // {
    //   name: 'setup',
    //   testDir: './tests/e2e/fixtures',
    //   testMatch: /auth\.ts$/,
    // },
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        // storageState: 'tests/e2e/.auth/user.json',
      },
      // dependencies: ['setup'],
    },
    // { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    // { name: 'webkit',  use: { ...devices['Desktop Safari'] } },
  ],

  // Dev server auto-start (optional — uncomment and adjust for your project)
  // webServer: {
  //   command: 'pnpm dev',
  //   url: 'http://localhost:3000',
  //   reuseExistingServer: !process.env.CI,
  //   timeout: 120_000,
  // },
});
