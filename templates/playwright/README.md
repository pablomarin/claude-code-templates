# Playwright Framework Templates

Installed by `setup.sh --with-playwright` into fullstack/typescript projects.

Files:

- `playwright.config.template.ts` → `playwright.config.ts` at project root
- `auth.fixture.template.ts` → `tests/e2e/fixtures/auth.ts`
- `example.spec.template.ts` → reference for spec file structure (not auto-installed)

After setup, the user must:

1. `pnpm add -D @playwright/test` (or npm/yarn)
2. `pnpm exec playwright install` (downloads browser binaries)
3. Configure auth via env vars: `TEST_API_KEY` OR `TEST_USER_EMAIL` + `TEST_USER_PASSWORD`
4. Review `playwright.config.ts` — set `baseURL` and uncomment `webServer` if needed
5. Optionally activate CI: `cp docs/ci-templates/e2e.yml .github/workflows/e2e.yml`

The main implementation agent generates `.spec.ts` files in `tests/e2e/specs/` during Phase 6.2c of `/new-feature` and `/fix-bug`, using the verify-e2e agent's report (which documents observed selectors). The verify-e2e agent itself stays read-only.
