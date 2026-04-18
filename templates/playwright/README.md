# Playwright Framework Templates

Installed by `setup.sh --with-playwright` into fullstack/typescript projects.

## Where they land

Setup scaffolds into one of:

- **Repo root** — flat layouts (no detected frontend subdirectory)
- **`frontend/`, `apps/web/`, `web/`, or `client/`** — auto-detected if exactly one subdirectory contains `package.json`
- **Any path** — passed via `--playwright-dir <path>` (overrides auto-detection)

Multiple frontend candidates fall back to repo root with a warning; pick explicitly via `--playwright-dir` to resolve ambiguity.

## Files

- `playwright.config.template.ts` → `<pw-dir>/playwright.config.ts`
- `auth.fixture.template.ts` → `<pw-dir>/tests/e2e/fixtures/auth.ts`
- `example.spec.template.ts` → reference for spec file structure (not auto-installed)

## After setup

From `<pw-dir>` (repo root or the detected subdirectory):

1. `pnpm add -D @playwright/test` (or npm/yarn)
2. `pnpm exec playwright install` (downloads browser binaries)
3. Configure auth via env vars: `TEST_USER_EMAIL` + `TEST_USER_PASSWORD` (preferred cookie path). `TEST_API_KEY` is documented as an insecure local-dev-only alternative in `auth.ts` — see the SECURITY WARNING in that file.
4. Review `<pw-dir>/playwright.config.ts` — set `baseURL` and uncomment `webServer` if needed
5. Optionally activate CI: `cp docs/ci-templates/e2e.yml .github/workflows/e2e.yml`. The generated workflow already has the correct `working-directory` and `cache-dependency-path` stamped in based on the detected scaffold location.

## Spec generation

The main implementation agent generates `.spec.ts` files in `<pw-dir>/tests/e2e/specs/` during Phase 6.2c of `/new-feature` and `/fix-bug`, using the verify-e2e agent's report (which documents observed selectors). The verify-e2e agent itself stays read-only — it returns the report in its response and the main agent persists it.
