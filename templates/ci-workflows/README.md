# CI Workflow Templates

Reference templates installed by `setup.sh` into `docs/ci-templates/`.

**These are NOT auto-activated.** To enable a workflow, move it to `.github/workflows/`:

```bash
mkdir -p .github/workflows
cp docs/ci-templates/e2e.yml .github/workflows/e2e.yml
git add .github/workflows/e2e.yml
git commit -m "ci: enable E2E regression workflow"
```

Available workflows:

- `e2e.yml` — Playwright E2E tests (smoke on PRs, full suite nightly)

Required GitHub secrets/vars:

- `TEST_API_KEY` (secret) — for auth fixture
- `PLAYWRIGHT_BASE_URL` (var) — staging/preview URL

Customize per project. Non-GitHub CI (GitLab, Jenkins, CircleCI): port manually — the `pnpm exec playwright test` command is the same.
