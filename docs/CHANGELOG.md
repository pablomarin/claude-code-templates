# Changelog

All notable changes to claude-codex-forge.

## 5.8 — 2026-04-18 · Multi-project interpreter preflight + isolation guide

Handles the "I work on 5 projects with different Python/Node versions" case. Recommendation came from a 5-advisor Engineering Council session with Codex chairman synthesis.

- **`docs/guides/multi-project-isolation.md`** — canonical doc explaining the `uv` + `pnpm` dependency-isolation model, why the harness does NOT switch interpreter binaries for you, and which version managers to use (`uv python install`, `pyenv`, `fnm`, `nvm`, `volta`). Linked from `docs/getting-started.md` and `docs/guides/parallel-sessions.md`.
- **Warn-only preflight in `setup.sh` + `setup.ps1`** (before `Prerequisites OK`). Reads repo-root `.python-version`, `.nvmrc`, and root `package.json` `engines.node`. Prints a warning with install guidance if the declared runtime is unavailable. **Never changes exit code.** Silent when no pins exist. Detection checks in order: `uv python list` → `pyenv versions` → `python3.MAJOR.MINOR` → `python3 --version` match for Python; `node --version` major match → `fnm`/`nvm`/`volta` listings for Node.
- **Explicitly NOT shipped** per Council minority-report resolution: no session-start hook check (wrong layer), no `verify-app` preamble (another policy surface before installer/doc contract is settled), no subdir detection (monorepo pattern deferred), no silence flag (remove pin file to disable per-project).
- **Test suite grows 119 → 143 assertions.** `test-setup.sh` adds 4 scenarios (impossible Python version, impossible Node version, no pins → silent, matching version → green). `test-contracts.sh` adds a shell/PowerShell parity contract asserting both installers reference the same files and canonical guide.

## 5.7 — 2026-04-18 · Template self-test suite

Fast local regression protection for template changes — avoids the prior commit-push-merge-install-in-downstream-repo loop.

- **`tests/template/`** — 4 bash suites, 111 assertions, runs in ~5 seconds via `bash tests/template/run-all.sh`. Zero external dependencies beyond bash + jq.
- **test-setup.sh** (39 assertions) exercises `setup.sh --with-playwright` against flat, monorepo (`frontend/`), multi-candidate, `--playwright-dir` override, and `apps/r&d` metachar layouts. Covers idempotency (hash-based), `-f` force-refresh, and `--upgrade` smoke. The metachar test confirms PR #482's bash-parameter-expansion fix for the `&`-substitution bug.
- **test-fixtures.sh** (23 assertions) fingerprints template content: branding leak, trace/video CI security default, cookie-auth default with block-comment-aware check for the insecure `localStorage` pattern, verify-e2e response header, post-tool-format monorepo walk-up, prd/create.md fence balance.
- **test-contracts.sh** (23 assertions) cross-file consistency: every VERDICT value in `verify-e2e.md` is consumed by `new-feature.md` + `fix-bug.md` and vice versa, SUGGESTED_PATH is honored, `.claude/playwright-dir` marker has both a writer (setup.sh / setup.ps1) and readers (command docs), `__PLAYWRIGHT_DIR__` placeholder is handled in both shell and PowerShell.
- **test-lint.sh** (26 assertions) `bash -n` on every shell script, `pwsh` parse on `.ps1` files (skipped without pwsh), `jq empty` on JSON templates, placeholder-coverage check.

## 5.6 — 2026-04-17 · Template monorepo support + Playwright security fixes

Batch fix for 9 Copilot findings surfaced in a downstream user project (mcpgateway) plus 4 related "missed" items from a Codex review. All are template-level bugs — downstream users pick them up via `setup.sh --upgrade`.

- **Monorepo-aware Playwright scaffolding.** `setup.sh --with-playwright` now supports `--playwright-dir <path>` override and auto-detects `frontend/`, `apps/web/`, `web/`, `client/` when exactly one candidate has `package.json`. Multi-candidate falls back to repo root with a warning. Scaffolded CI workflow has the detected path stamped into `working-directory`, `cache-dependency-path`, and `upload-artifact` so monorepo installs work out of the box.
- **Playwright security hardening.** Default `trace` and `video` to `off` on CI (opt-in via `PLAYWRIGHT_CI_TRACE=1` / `PLAYWRIGHT_CI_VIDEO=1`) to prevent credential leaks via `storageState`-captured artifacts. Auth fixture now uses cookie/session login as the active default; the insecure API-key-in-localStorage path is demoted to a commented "LOCAL DEV ONLY" block with a security warning.
- **`verify-e2e` agent read-only contract fixed.** Agent frontmatter declared no Write tools but Step 5 instructed it to write markdown to `tests/e2e/reports/`. Agent now returns a structured `VERDICT: / SUGGESTED_PATH: / --- / <body>` response; main agent parses and persists. `commands/new-feature.md` and `commands/fix-bug.md` Phase 5.4 updated accordingly.
- **`post-tool-format` hook monorepo-aware.** Walks up from the edited file to find the nearest `pyproject.toml` instead of assuming `$CLAUDE_PROJECT_DIR/src`. Restores `ruff check --fix` (was silently dropped) and decouples it from `ruff format` so a lint failure doesn't skip formatting. Mirrored in `.ps1`.
- **`commands/prd/create.md` fence nesting.** Repaired misplaced four-backtick close that was ejecting Appendix B from the PRD template, plus three orphan triple-backticks at end of file.
- **`playwright.config.template.ts` header.** Removed "claude-codex-forge" from the docblock — template was leaking its own name into downstream projects' code.
- **Workflow commands monorepo-aware.** `commands/new-feature.md` and `commands/fix-bug.md` Pre-Flight dep install now iterates over common frontend/backend subdirectories instead of only checking repo root. Phase 5.4b framework detection locates `playwright.config.ts` across the same subdirectory set.
- **Docs sync.** `agents/verify-app.md`, `CLAUDE.template.md`, `rules/testing.md`, `templates/playwright/README.md`, `docs/guides/playwright-ci-bridge.md` updated to reflect the new `<pw-dir>` pattern and cookie-auth default.

## 5.5 — 2026-04-17 · E2E enforcement + research-first + repo rename

- **`verify-e2e` agent** — dedicated subagent for user-journey E2E through API/UI/CLI, accumulated regression suite in `tests/e2e/use-cases/` (PR #449).
- **Playwright CI bridge** — `--with-playwright` setup flag scaffolds `playwright.config.ts`, auth fixture, specs dir, and reference GitHub Actions workflow (PR #450).
- **`research-first` agent** — Phase 2 of `/new-feature` queries Context7/official docs/changelogs before design, producing structured briefs in `docs/research/` (PR #472).
- **Repo renamed** from `claude-code-templates` → `claude-codex-forge`.
- **README rebrand + restructure** — repositioned as "engineering harness powered by two coding agents" (PR #473); split into `docs/` tree with trailhead README (PR follows).
- **Codex skill flag reference** — added complete flag reference and powerful `-c` config overrides to `/codex` skill (PR #474).

## 5.4 — 2026-03-31 · Engineering Council

Multi-perspective decision analysis inspired by Karpathy's LLM Council. 5 engineering advisors (3 Claude + 2 Codex) with Codex chairman. Contrarian gate validates approach selection (no self-certification). Auto-triggers during `/new-feature` and `/fix-bug` brainstorming when genuine ambiguity detected. Configurable advisor profiles. Mandatory minority reports preserve dissent.

## 5.3 — 2026-03-01 · Silent context injection

SessionStart hook now uses `hookSpecificOutput.additionalContext` for clean, non-visible branch injection. Fires on all 4 events (startup, resume, clear, compact). External script replaces inline echo.

## 5.2 — 2026-02-20 · Frontend design

Added `frontend-design` plugin (built-in) and `rules/frontend-design.md` for TypeScript/fullstack projects — typography, color, spacing, responsive, accessibility, animation standards. Documented optional MCP add-ons (Vercel, Next.js DevTools).

## 5.1 — 2026-02-19 · CLAUDE.md split

Slimmed CLAUDE.md to ~50 lines (user-owned: project description, tech stack, commands). Moved workflow, principles, worktree policy, critical rules, and memory instructions to `.claude/rules/` files that are auto-loaded and safe to overwrite on updates. Following official best practice of keeping CLAUDE.md under 60-100 lines.

## 5.0 — 2026-02-19 · Removed Compound Engineering

Replaced with built-in Claude Code quality gates (`/review-pr-comments`, `/pr-review-toolkit:review-pr`, `/codex review`). E2E testing via standalone Playwright MCP. Knowledge compounding via `docs/solutions/` + auto memory. Only Superpowers remains as third-party plugin. Added standalone MCP servers (Playwright, Context7) to project settings.

## 4.0 — 2026-02-19 · Persistent memory

Added global memory system (`--global` flag), PreCompact hooks to save learnings before context compression, global Stop hook for memory reminders, `~/.claude/CLAUDE.md` template with memory instructions. Inspired by OpenClaw's pre-compaction memory flush pattern. Auto memory enabled by default.

## 3.4 — 2026-02-16 · Codex command

Added `/codex` command for getting second opinions from OpenAI's Codex CLI. Code review and general feedback modes.

## 3.3 — 2026-01-22 · Finish-branch command

Added `/finish-branch` command that handles PR merge + worktree cleanup. Removed `/superpowers:finishing-a-development-branch` from workflows (redundant testing, no worktree awareness). `/quick-fix` now just commits directly.

## 3.2 — 2026-01-19 · Simplified worktrees

Claude now `cd`s into worktrees instead of using path prefixes. Removed `.session_worktree` file — no shared state between sessions. Hooks and verify-app simplified to use current directory.

## 3.1 — 2026-01-19 · Parallel development

Workflow commands auto-create git worktrees for isolated parallel sessions. Hooks are worktree-aware. verify-app agent accepts worktree path.

## 3.0 — 2026-01-18 · Workflow commands

Added `/new-feature`, `/fix-bug`, `/quick-fix` commands that contain full workflows. Refactored CLAUDE.md to be lean (140 lines vs 318). E2E via Playwright MCP.

## 2.7 — 2026-01-18

Simplified CONTINUITY.md: Done section keeps only 2-3 recent items, removed redundant sections (Working Set, Test Status, Active Artifacts). Leaner template.

## 2.6 — 2026-01-18

Hooks follow Anthropic best practices: path traversal protection, sensitive file skip, `$CLAUDE_PROJECT_DIR` for absolute paths. Added external post-tool-format.sh script.

## 2.5 — 2026-01-17

E2E testing via Playwright MCP. Removed E2E from verify-app agent.

## 2.4 — 2026-01-17

Knowledge compounding now uses `docs/solutions/` instead of inline CLAUDE.md learnings. Searchable files with YAML frontmatter, auto-categorized by problem type.

## 2.3 — 2026-01-17

Enhanced workflow with Superpowers skills: systematic-debugging, verification-before-completion. Updated Stop hook checklist.

## 2.2 — 2026-01-17

Fixed MCP permissions — wildcards don't work, use explicit server names.

## 2.1 — 2026-01-11

Added native Windows/PowerShell support — hooks now work without jq on Windows, platform-specific settings templates.

## 2.0 — 2026-01-10

Added code-simplifier, verify-app agent, SubagentStop hook, prompt-based Stop hook, project-agnostic templates, clear setup scenarios.

## 1.0 — 2026-01-02

Initial setup with Superpowers.
