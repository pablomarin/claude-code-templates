# CI Workflow Templates

Reference templates installed by `setup.sh` into `docs/ci-templates/`.

**These are NOT auto-activated.** To enable a workflow, move it to `.github/workflows/`:

```bash
mkdir -p .github/workflows
cp docs/ci-templates/e2e.yml .github/workflows/e2e.yml
git add .github/workflows/e2e.yml
git commit -m "ci: enable E2E regression workflow"
```

## Available workflows

- `e2e.yml` — Playwright E2E tests (smoke on PRs, full suite nightly)

## Working directory

When `setup.sh --with-playwright` runs, it detects where Playwright lives (repo root for flat layouts, `frontend/`, `apps/web/`, or a path passed to `--playwright-dir`). That path is stamped into `e2e.yml` at installation time as the job-level `working-directory` for every step.

If your repo uses pnpm workspaces and the install must happen at the repo root rather than inside the Playwright subdir, you can override per-step by adding `working-directory: .` to the **Install dependencies** step alone, leaving the rest pointing at the Playwright dir.

The same stamped path is also used for `actions/setup-node`'s `cache-dependency-path` and for the `upload-artifact` report path, so cache hits and artifact uploads work correctly out of the box.

## Required GitHub secrets / variables

- `TEST_USER_EMAIL` (secret) — credentials for the auth fixture (cookie-based session login, the secure default)
- `TEST_USER_PASSWORD` (secret) — paired with TEST_USER_EMAIL
- `PLAYWRIGHT_BASE_URL` (variable) — staging or preview URL the suite runs against

> `TEST_API_KEY` is supported by the scaffolded `auth.ts` fixture as a commented-out local-dev fallback. It is **not** recommended for CI — see the SECURITY WARNING in the fixture for why persisting bearer tokens into `storageState` increases the credential-leak blast radius if tracing or video is ever turned on.

## Non-GitHub CI

GitLab, Jenkins, CircleCI: port manually. The core commands are:

```bash
# From __PLAYWRIGHT_DIR__ (repo root or your frontend subdir):
pnpm install --frozen-lockfile
pnpm exec playwright install --with-deps chromium
pnpm exec playwright test [--grep @smoke]
```
