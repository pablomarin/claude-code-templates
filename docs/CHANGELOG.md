# Changelog

All notable changes to claude-codex-forge.

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
