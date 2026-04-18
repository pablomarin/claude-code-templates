# Playwright CI Bridge (optional)

**Monday, 9 AM.** A first-time contributor opens a PR touching `/api/auth/login`. No Claude session, so your `verify-e2e` agent doesn't run. Their PR goes green, merges, and breaks login for a thousand users by Wednesday.

The bridge fixes that. Every passing use case the agent explores becomes a deterministic `.spec.ts` file that CI replays in ~90 seconds, on every PR, zero LLM cost.

## Enable it

Append `--with-playwright` to your setup command:

**macOS / Linux:**

```bash
~/claude-codex-forge/setup.sh -p "My App" -t fullstack --with-playwright
```

**Windows (PowerShell):**

```powershell
& $HOME\claude-codex-forge\setup.ps1 -p "My App" -t fullstack -WithPlaywright
```

## What gets scaffolded

| Path                         | Purpose                                                                                              |
| ---------------------------- | ---------------------------------------------------------------------------------------------------- |
| `playwright.config.ts`       | Playwright framework config (set `baseURL`, uncomment `setup` project)                               |
| `tests/e2e/fixtures/auth.ts` | Auth bypass fixture                                                                                  |
| `tests/e2e/specs/`           | Empty dir for deterministic specs (main agent writes into this)                                      |
| `tests/e2e/.auth/.gitignore` | Credential-safe (never committed)                                                                    |
| `docs/ci-templates/e2e.yml`  | Reference GitHub Actions workflow — copy to `.github/workflows/` when ready (**not** auto-activated) |

## One-time install after setup

(setup.sh prints this command at the end)

```bash
pnpm add -D @playwright/test && pnpm exec playwright install
# set TEST_API_KEY, or TEST_USER_EMAIL + TEST_USER_PASSWORD in .env
# review playwright.config.ts — set baseURL, uncomment the "setup" project
```

## How your workflow changes — two touchpoints

| Phase               | What happens                                                                                                                                               |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **5.4b regression** | Runs `pnpm exec playwright test` when every UC has a matching spec; falls through to the `verify-e2e` agent during partial migration — safe at every point |
| **6.2c (new)**      | **Main** implementation agent reads the `verify-e2e` report + markdown UC, writes `tests/e2e/specs/<feature>.spec.ts` using selectors the agent observed   |

The `verify-e2e` agent stays read-only. Only the main agent writes specs. This is a hard invariant.

## The two layers

- **`tests/e2e/use-cases/*.md`** — intent, lives with your plan
- **`tests/e2e/specs/*.spec.ts`** — deterministic replay, runs everywhere (local, CI, cron, contributor PRs)

See `.claude/rules/testing.md` for the full model.
