<h1 align="center">Claude Codex Forge</h1>

<p align="center">
  <strong>An engineering harness for disciplined software building — powered by two coding agents.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/pablomarin/claude-codex-forge?style=flat-square"></a>
  <a href="#version-history"><img alt="Version" src="https://img.shields.io/badge/version-5.5-blue?style=flat-square"></a>
  <a href="docs/getting-started.md"><img alt="Platform" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey?style=flat-square"></a>
  <a href="https://code.claude.com"><img alt="Claude Code" src="https://img.shields.io/badge/Claude_Code-enabled-purple?style=flat-square"></a>
  <a href="https://developers.openai.com/codex/"><img alt="Codex CLI" src="https://img.shields.io/badge/Codex_CLI-required-orange?style=flat-square"></a>
</p>

<p align="center">
  <a href="docs/getting-started.md">Quick Start</a>
  ·
  <a href="docs/reference/commands.md">Commands</a>
  ·
  <a href="docs/explanation/workflow.md">Workflow</a>
  ·
  <a href="docs/explanation/harness-philosophy.md">Philosophy</a>
  ·
  <a href="docs/troubleshooting.md">Troubleshooting</a>
  ·
  <a href="docs/CHANGELOG.md">Changelog</a>
</p>

---

Claude Codex Forge combines **Claude Code** and **OpenAI's Codex** into a single workflow. Two agents beat one: Claude designs, Codex independently reviews, and the Engineering Council adjudicates when they disagree. What started as a set of workflow templates has grown — through continuous iteration — into a full engineering harness.

## What you get

- **Dual-agent review** — `/codex review` (independent second opinion) + `/council` (5-advisor panel with Codex chairman) catch issues one agent alone would miss. Two separately-trained models flag different concerns — disagreement is the signal.
- **Discipline by construction** — workflow commands bake in TDD, research-before-design, and E2E testing. Hooks block dangerous Bash, enforce state updates, and gate commit/push/PR on explicit quality markers.
- **Continuous memory** — auto-memory persists locally across sessions and compaction (rescued by the `PreCompact` hook); `CONTINUITY.md`, `CHANGELOG.md`, and `docs/solutions/` travel with the repo so every root cause, decision, and pattern compounds across weeks and teammates via git.
- **Team-scale by default** — one GitHub repo becomes the hub. Multiple developers run parallel Claude sessions via auto-created git worktrees, each isolated but with full project context.

## Quick start

```bash
# 1. Clone once per machine
git clone https://github.com/pablomarin/claude-codex-forge.git ~/claude-codex-forge
chmod +x ~/claude-codex-forge/setup.sh

# 2. Global setup once per machine (installs memory system)
~/claude-codex-forge/setup.sh --global

# 3. Per-project setup
cd /path/to/your/project
~/claude-codex-forge/setup.sh -p "My Project"

# 4. Start Claude Code and kick off your first workflow
claude
> /new-feature my-feature
```

Full walkthrough with prerequisites, plugin install, and Codex CLI setup: **[Getting Started →](docs/getting-started.md)**

Windows users: [PowerShell instructions](docs/getting-started.md#windows).

## How it works

One feature goes from idea to merged PR across 14 enforced phases — from PRD through research, dual-reviewer design loops, TDD execution, parallel code review, simplify + verify + E2E, compound learnings, and PR reviewer handling.

See **[the full workflow diagram](docs/explanation/workflow.md)** for the complete view, or jump straight to:

- **[Why a harness, not a template](docs/explanation/harness-philosophy.md)** — the two-agent design, discipline by construction, continuous memory
- **[Commands reference](docs/reference/commands.md)** — every slash command and subagent
- **[Hooks reference](docs/reference/hooks.md)** — seven hook events that keep discipline structural

## Documentation

| Topic                                                              | What's inside                                                    |
| ------------------------------------------------------------------ | ---------------------------------------------------------------- |
| **[Getting Started](docs/getting-started.md)**                     | Prerequisites, 6-step install, verify setup                      |
| **[Setup Scenarios](docs/guides/setup-scenarios.md)**              | New project · existing project · upgrade                         |
| **[Customize Your Project](docs/guides/customize-project.md)**     | CLAUDE.md · CONTINUITY.md · optional MCPs · automated PR reviews |
| **[Upgrading](docs/guides/upgrading.md)**                          | `--upgrade` mode, merge behavior, fresh-install alternative      |
| **[Parallel Development](docs/guides/parallel-sessions.md)**       | Multiple sessions via git worktrees                              |
| **[Playwright CI Bridge](docs/guides/playwright-ci-bridge.md)**    | `--with-playwright` scaffold for deterministic E2E in CI         |
| **[Commands Reference](docs/reference/commands.md)**               | All slash commands and subagents                                 |
| **[Hooks Reference](docs/reference/hooks.md)**                     | Seven hook events + how they interact                            |
| **[Permissions & Security](docs/reference/permissions.md)**        | Deny / ask / skip rules                                          |
| **[File Structure](docs/reference/file-structure.md)**             | What setup creates and where                                     |
| **[Creating Skills](docs/reference/creating-skills.md)**           | Author your own slash commands                                   |
| **[Cheatsheet](docs/reference/cheatsheet.md)**                     | Copy-paste daily-workflow card                                   |
| **[Workflow (full)](docs/explanation/workflow.md)**                | 14-phase diagram with rationale                                  |
| **[Harness Philosophy](docs/explanation/harness-philosophy.md)**   | Why dual-agent, why discipline, why continuous memory            |
| **[Memory Architecture](docs/explanation/memory-architecture.md)** | Global + project + auto-memory layers                            |
| **[Troubleshooting](docs/troubleshooting.md)**                     | Memory · hooks · permissions · MCP · plugins · Codex             |

## Concrete guarantees

The pillars above cash out in specific, repo-verifiable behavior:

- **Compaction rescue** — `PreCompact` hook flushes session learnings to auto-memory _before_ context compression, so nothing is dropped silently
- **Review ordering enforced** — `/codex review` runs _first_ as an independent pass, then `/pr-review-toolkit:review-pr` (6 deep agents), then `/simplify`, then post-PR `/review-pr-comments`. Commits are blocked until quality markers are present.
- **Worktree isolation** — `/new-feature` and `/fix-bug` auto-create git worktrees so parallel Claude sessions never share filesystem state
- **E2E for user-facing changes** — `verify-e2e` subagent replays `tests/e2e/use-cases/*.md` as a growing regression suite; optional `--with-playwright` scaffolds deterministic `.spec.ts` for contributor PRs in CI

## Version history

Recent releases:

| Version | Date       | Highlights                                                                                      |
| ------- | ---------- | ----------------------------------------------------------------------------------------------- |
| 5.5     | 2026-04-17 | `verify-e2e` agent (#449) · Playwright CI bridge (#450) · `research-first` (#472) · repo rename |
| 5.4     | 2026-03-31 | Engineering Council — 5 advisors with Codex chairman                                            |
| 5.3     | 2026-03-01 | Silent SessionStart context injection via JSON `hookSpecificOutput`                             |
| 5.2     | 2026-02-20 | Frontend design plugin + `rules/frontend-design.md`                                             |
| 5.1     | 2026-02-19 | CLAUDE.md split — slim file + auto-loaded `.claude/rules/`                                      |
| 5.0     | 2026-02-19 | Removed Compound Engineering, replaced with built-in quality gates                              |

Full history: **[docs/CHANGELOG.md](docs/CHANGELOG.md)**

## Credits

Started from [Boris Cherny's workflow](https://www.anthropic.com/engineering/claude-code-best-practices) (Claude Code's creator), Anthropic's official best practices, and [OpenClaw's pre-compaction memory patterns](https://github.com/openclaw/openclaw/discussions/6038) — evolved into a dual-agent harness through ongoing iteration.

## Getting help

- [Claude Code Docs](https://code.claude.com/docs)
- [Memory Management](https://code.claude.com/docs/en/memory)
- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Skills & Commands](https://code.claude.com/docs/en/skills)
- [Anthropic Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Subagents Guide](https://code.claude.com/docs/en/sub-agents)

## License

See [LICENSE](LICENSE).
