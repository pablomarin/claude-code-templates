# Changelog

All notable changes to claude-codex-forge.

## 5.12 — 2026-04-21 · Template-drift notice on `setup.sh -f` / `--upgrade`

Closes the downstream pain path the user surfaced directly: after bumping the harness repo, running `./setup.sh -f` in a pre-existing project didn't warn that `CLAUDE.template.md` had evolved since their `CLAUDE.md` was originally copied. The user only saw `Your CLAUDE.md and CONTINUITY.md were not modified` and had to manually ask Claude to reconcile the template against the local file.

Codex second-opinion pass (5 plan-review iterations + 2 code-review iterations) locked the approach at: **loud notice, no auto-diff, no section-marker merging**. Rejected alternatives: auto-running `git diff` inline during install (noisy on heavily-customized CLAUDE.md) and section-marker-based partial ownership (user file is intentionally freeform).

- **`setup.sh` + `setup.ps1`** — new helper (`print_template_drift_hint` / `Write-TemplateDriftHint`) fired at the CLAUDE.md / CONTINUITY.md preserved-file branches; consolidated reminder block at the end-of-`--upgrade` summary. Both installers capture pre-copy `had_claude_md` / `$hadClaude` booleans so we only claim a file was preserved when this run actually preserved it (fixing a pre-existing bug where the summary lied if the user deleted one of the files before `--upgrade`). Emitted `git diff --no-index` command uses single-quoted paths + `$(pwd)`-absolutized local side so it survives copy-paste across shells and working dirs.
- **Final-summary line** now has four boolean-gated variants (both preserved / only CLAUDE / only CONTINUITY / neither). The legacy hardcoded `were not modified` is gone.
- **`tests/template/test-setup.sh`** — Test 8 extended with CONTINUITY.md sentinel + hash check + drift-notice assertions + first-install regression guard; new Test 10 (Scenarios A/B/C) covers the asymmetric preservation matrix (CLAUDE deleted, CONTINUITY deleted, both deleted). Suite grows from 75 → 100 assertions in test-setup.sh.
- **`tests/template/test-contracts.sh` Contract 7** — template-drift parity gate. Asserts both installers ship (i) the user-facing `Template may have drifted` string, (ii) both template filenames, (iii) `git diff --no-index`, (iv) exact call-site fingerprints like `print_template_drift_hint "CLAUDE.template.md" "CLAUDE.md"` (closes the dead-helper / missing-callsite loophole), (v) all three positive final-summary variants + negative guard against the legacy `were not modified` string. Contract 7 is the only Windows safety net — bash tests can't execute PowerShell — so variants must exist literally in both files.

Suite: 179 → 223 assertions across 5 bash suites, ~5s local run.

Explicitly NOT shipped (scope discipline, deferred per Codex iter-1 plan review):

- **`--global` / `GLOBAL-CLAUDE.template.md`** — currently goes through `copy_file` which overwrites. Adding drift notice there would first require deciding whether `~/.claude/CLAUDE.md` should become user-owned. Separate policy question, separate PR.
- **Auto-diff rendering** in the installer — Codex recommended deferring behind an opt-in `--show-template-diff` flag if demand emerges. Noisy by default on heavily-customized CLAUDE.md.
- **Path-apostrophe escape in emitted `git diff` command** — P3 from code review iter 2 (project path like `Client's Repo` would break single-quoting). Fixing properly requires `printf %q` (bash) + `EscapeSingleQuotedStringContent` (PowerShell); real overkill for a diff suggestion string. Out of scope.

**Remediation for existing installs:** `./setup.sh -f` to pick up the notice. The notice fires inside the existing-file branch which runs any time `CLAUDE.md` / `CONTINUITY.md` already exist — no new flags needed.

## 5.11 — 2026-04-20 · ARRANGE rule — close the E2E actor-boundary gap via text layer

Closes the MSAI field-testing gap where Claude ran `docker exec postgres psql -c "INSERT INTO ..."` during E2E setup, bypassing the ARRANGE rule. When the user caught it, Claude "backed out" with a raw `DELETE` (compounding the violation) and had also sidestepped a real bug in the sanctioned CLI path (violating NO BUGS LEFT BEHIND in the same flow).

**Council verdict on path forward** (5 advisors + Codex chairman, Contrarian reframe decisive): the failure is a rule-text + actor-boundary problem, not a command-detection problem. Ship text-layer fixes; shelf the shell-regex hook.

- **`rules/critical-rules.md:9`** — E2E TESTING bullet now names ARRANGE explicitly with concrete forbidden examples (`psql -c "INSERT"`, `mysql -e "UPDATE"`, `mongosh --eval`) and ties to NO BUGS LEFT BEHIND. Previously only mentioned "No cheating in VERIFY" — silent on ARRANGE, the phase that was actually violated.
- **`rules/testing.md:176`** — the sentence "This principle applies strictly to the VERIFY phase, **not** the ARRANGE phase" was a direct contradiction of the forbidden list immediately below. Rewritten: ARRANGE has flexibility about _which_ sanctioned interface to use, but not permission to sidestep them. Raw DB writes, internal endpoints, and file-injection are forbidden in both phases.
- **`agents/verify-e2e.md` Critical Constraint #2** — was "ARRANGE may use sanctioned setup paths"; now explicitly forbids raw DB writes and tells the agent to report FAIL_INFRA on broken sanctioned paths rather than routing around them.
- **`commands/new-feature.md` + `commands/fix-bug.md` Phase 5.4** — new phase-local ARRANGE-boundary reminder for the main agent _before_ verify-e2e dispatch. The Contrarian's actor-boundary insight: the cheat happened in the main session, not the subagent; bind the main agent to the same rule at the exact moment the behavior is decided.

5 files changed, 7 insertions, 3 deletions.

Explicitly NOT shipped — shell-regex PreToolUse hook:

- **v1** (stderr WARN): wrong output channel — per Anthropic docs, `PreToolUse` stderr only reaches Claude on exit 2; exit 0 drops stderr silently.
- **v2** (stdout JSON + pinned-start regex): still had greedy `.*` false positives on `SELECT ... '%INSERT%'` literals.
- **v3** (anti-FP guards): Guard 2 (quote-prefix rejection) introduced a new false negative on `docker exec pg bash -lc "psql -c \"INSERT\""` — the hook would have FAILED to catch a near-variant of the motivating MSAI cheat. Still had persistent false positives on `python -c`, `jq`, `curl -d` payloads where `psql` appears as a string literal.

Three rounds of polish traded one gap for another — the Scalability Hawk's original OBJECT was vindicated. Archived v3 plan + full council reasoning in `docs/plans/2026-04-20-arrange-rule-enforcement-plan.md` (gitignored). Revisit only if the text layer fails in field testing, and only with a different primitive (audit-log-only telemetry, Stop-hook phase-scoped reminder, etc. — **not** a PreToolUse shell-regex).

## 5.10 — 2026-04-18 · Evidence-based E2E gate (Phase 2 of the enforcement cycle)

Closes the Contrarian's deferred P0 from the 5.9 Council session: the paperwork-only gate let a bad-faith operator type `[x] E2E verified` without actually running the verify-e2e agent. Phase 2 binds the checkbox claim to a real filesystem artifact.

Motivation: user observed downstream sessions attempting `gh pr create` before code reviews, simplify, or E2E were actually done — Claude was checking boxes prematurely and the 5.9 checklist-only gate couldn't catch it.

- **Evidence check in `check-workflow-gates.sh` + `.ps1`**. When `- [x] E2E verified` is present WITHOUT an `N/A:` suffix, the hook now requires a file in `tests/e2e/reports/` whose mtime is later than the branch-off commit (`git merge-base HEAD main`, falling back to `master`). Without a fresh report: exit 2 with a specific "checkbox is typed but no report was produced" error. The N/A escape (`- [x] E2E verified — N/A: <reason>`) still bypasses the check.
- **Cross-platform mtime**: `stat -c %Y` for GNU, `stat -f %m` for BSD/macOS. PowerShell uses `LastWriteTime` against a UnixTime-derived `DateTimeOffset`. Detected at runtime.
- **Graceful degradation**: user on `main`, repo with neither `main` nor `master`, or missing git history → evidence check skipped. The checklist check still fires. Documented as degraded env, not policy violation.
- **`rules/testing.md`**: new "Evidence-based gate" subsection under "Canonical E2E gate vocabulary" explaining the two-phase check + degradation behavior.
- **`tests/template/test-hooks.sh`**: 8 new assertions (5 scenarios) exercising the evidence check — fresh report → 0, no report → 2 + stderr, stale report only → 2, N/A bypass → 0, degraded env (no main/master) → 0. Each scenario builds a real scratch git repo with a branch-off point to give the hook something to compare against.

Suite: 170 → 178 assertions, all pass.

Explicitly still NOT covered by evidence check:

- **Code review loop**, **Simplified**, **Verified (tests)** — these gates still use the paperwork-only check. They have no natural filesystem artifact convention yet. Adding them would require agents/commands to persist status files, which is a separate design pass.
- Report quality — only file existence + freshness is verified. A trivial report that claims PASS on no actual UCs still passes. Human reviewer catches this.

## 5.9 — 2026-04-18 · E2E verified gate — close the silent-skip loophole

Closes the loophole the Engineering Council flagged: before this release, `check-workflow-gates.sh` blocked commit/push/PR on `Code review loop` / `Simplified` / `Verified (tests`, but NOT on `E2E verified`. A downstream project (msai-v2) shipped 155 commits with every E2E checklist item unchecked. Council verdict (5 advisors + Codex chairman): ship narrow enforcement, canonicalize marker vocabulary in the same PR, defer operator-verification redesign.

- **`E2E verified` added to the gated markers** in `hooks/check-workflow-gates.sh` and `.ps1`. An active workflow with `- [ ] E2E verified` now blocks `git commit`, `git push`, and `gh pr create` with exit 2. The gate accepts either the checked-passing form (`- [x] E2E verified via verify-e2e agent (Phase 5.4)`) or the documented N/A escape (`- [x] E2E verified — N/A: <reason>`).
- **Canonical marker vocabulary** — `rules/testing.md` now has a "Canonical E2E gate vocabulary" section naming the exact stem (`E2E verified`) and N/A form. The old drifting string `E2E use cases tested — N/A` in the rules has been unified to match the hook + workflow commands.
- **Remediation message** — both hooks now print specific next-step commands when gates fail: `/codex review`, `/simplify`, `verify-app` agent, `verify-e2e` agent, plus the N/A format. Points at `rules/testing.md` for the full contract.
- **`tests/template/test-hooks.sh`** — new fixture-driven suite (13 assertions) feeding synthetic CONTINUITY.md into the hook and asserting exit codes: all checked → exit 0, E2E unchecked → exit 2 + correct stderr, E2E N/A → exit 0, non-ship command → always 0, inactive workflow → always 0, near-miss items (PR reviews addressed, Plan review loop, E2E use cases designed) NOT gated, PowerShell parity (skipped without pwsh).
- **`test-contracts.sh` Contract 6** — cross-file marker consistency: the exact stem `E2E verified` must appear in both hooks, both workflow commands, and `rules/testing.md`. The N/A form uses em-dash (—) literally, contracted across all files.

Suite grows 147 → 170 assertions, all pass on this branch.

Explicitly NOT in this PR (Council deferred):

- Operator-driven verify-e2e mode (contradicts current ARRANGE/VERIFY boundary; needs its own design pass)
- Non-fullstack guard reading `interface_type` from CLAUDE.md (acceptable risk for now — N/A escape handles library/CLI-only projects)
- Evidence-based gating that checks for an actual `tests/e2e/reports/*.md` artifact (larger contract change)
- CI activation via `setup.sh --with-ci` (separate PR)
- Structured HTML-comment marker anchors for drift immunity (deferred to hardening pass)

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
