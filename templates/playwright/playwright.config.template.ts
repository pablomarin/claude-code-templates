import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright configuration for claude-codex-forge E2E tests.
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

    // Collect trace on retry; full trace on first failure in CI
    trace: process.env.CI ? "on-first-retry" : "retain-on-failure",

    // Screenshots on failure
    screenshot: "only-on-failure",

    // Video on failure
    video: "retain-on-failure",

    // Reuse authenticated storage state from auth fixture
    // Uncomment after running auth setup (see tests/e2e/fixtures/auth.ts):
    // storageState: 'tests/e2e/.auth/user.json',
  },

  // Browser projects. Chromium covers 80%+ of production bugs; enable Firefox/WebKit
  // as needed per project.
  //
  // To enable auth via tests/e2e/fixtures/auth.ts, uncomment the "setup" project
  // below and add `dependencies: ['setup']` + `storageState: 'tests/e2e/.auth/user.json'`
  // to the chromium project. See https://playwright.dev/docs/auth.
  projects: [
    // {
    //   name: 'setup',
    //   testMatch: /fixtures\/auth\.ts/,
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
