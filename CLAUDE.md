@CONTINUITY.md

# CLAUDE.md - claude-code-templates

## Project Overview

### What Is This?

A production-grade template toolkit that transforms Claude Code from a simple coding assistant into an autonomous, memory-aware software engineering system. It provides enforced workflows, persistent memory, coding standards, and quality gates — all installed via a single `setup.sh` script.

### Tech Stack

- **Scripts:** Bash (setup.sh) + PowerShell (setup.ps1) — cross-platform installers
- **Config:** JSON (settings, MCP) + Markdown (commands, rules, templates)
- **Hooks:** Bash (.sh) + PowerShell (.ps1) — auto-run quality gates
- **No runtime dependencies** — pure config/scripts, no build step

### File Structure

```
claude-code-templates/
├── setup.sh                    # Unix installer (main entry point)
├── setup.ps1                   # Windows installer (PowerShell)
├── README.md                   # Documentation for the community
│
├── CLAUDE.template.md          # Template → project CLAUDE.md
├── CONTINUITY.template.md      # Template → project CONTINUITY.md
├── GLOBAL-CLAUDE.template.md   # Template → ~/.claude/CLAUDE.md
├── mcp.template.json           # Template → project .mcp.json
│
├── commands/                   # Workflow commands (copied to .claude/commands/)
│   ├── new-feature.md          # Full feature lifecycle
│   ├── fix-bug.md              # Systematic debugging workflow
│   ├── quick-fix.md            # Trivial changes (< 3 files)
│   ├── finish-branch.md        # Merge PR + cleanup worktree
│   ├── codex.md                # Second opinion from Codex CLI
│   └── prd/                    # PRD subcommands
│       ├── discuss.md          # Interactive requirements refinement
│       └── create.md           # Generate structured PRD
│
├── rules/                      # Coding standards (copied to .claude/rules/)
│   ├── principles.md           # Core philosophy (KISS, DRY, composition)
│   ├── workflow.md             # Decision matrix for command choice
│   ├── critical-rules.md       # Non-negotiable rules
│   ├── worktree-policy.md      # Git worktree isolation
│   ├── memory.md               # Persistent memory usage
│   ├── security.md             # Auth, secrets, SQL injection
│   ├── testing.md              # AAA pattern, fixtures, E2E
│   ├── api-design.md           # REST conventions, error format
│   ├── python-style.md         # Python-specific conventions
│   ├── typescript-style.md     # TypeScript-specific conventions
│   ├── database.md             # SQLAlchemy patterns, naming
│   └── frontend-design.md      # UI/UX standards
│
├── hooks/                      # Hook scripts (copied to .claude/hooks/)
│   ├── session-start.sh        # SessionStart: silent context injection (branch)
│   ├── session-start.ps1       # Windows version
│   ├── check-state-updated.sh  # Stop hook: enforce CONTINUITY.md updates
│   ├── check-state-updated.ps1 # Windows version
│   ├── post-tool-format.sh     # PostToolUse: auto-format on save
│   ├── post-tool-format.ps1    # Windows version
│   ├── pre-compact-memory.sh   # PreCompact: save learnings before compression
│   └── pre-compact-memory.ps1  # Windows version
│
├── agents/                     # Subagent definitions (copied to .claude/agents/)
│   └── verify-app.md           # Full verification: tests + lint + types
│
└── settings/                   # Settings templates
    ├── settings.template.json          # Project-level (plugins, permissions, hooks)
    ├── global-settings.template.json   # Global-level (hooks only, merged)
    └── settings-windows.template.json  # Windows variant
```

### Key Commands

```bash
# Testing changes to the template
./setup.sh -p "Test" -t fullstack      # Test full setup in current dir
./setup.sh -p "Test" -t python         # Test Python-only setup
./setup.sh -p "Test" -f                # Test force-overwrite mode
./setup.sh --global                    # Test global setup

# Workflows (MANDATORY - hooks enforce these)
/new-feature <name>     # Full feature workflow
/fix-bug <name>         # Bug fix with systematic debugging
/quick-fix <name>       # Trivial changes only (< 3 files)
/finish-branch          # Merge PR + cleanup worktree
```

---

## Critical Conventions

### Template → Generated File Mapping

Templates in the root are **source of truth**. `setup.sh` copies them to target projects:

| Template (edit this)              | Generated file (never edit directly)      |
| --------------------------------- | ----------------------------------------- |
| `CLAUDE.template.md`              | `CLAUDE.md` in target project             |
| `CONTINUITY.template.md`          | `CONTINUITY.md` in target project         |
| `GLOBAL-CLAUDE.template.md`       | `~/.claude/CLAUDE.md`                     |
| `mcp.template.json`               | `.mcp.json` in target project             |
| `settings/settings.template.json` | `.claude/settings.json` in target project |
| `commands/*.md`                   | `.claude/commands/*.md` in target project |
| `rules/*.md`                      | `.claude/rules/*.md` in target project    |
| `hooks/*`                         | `.claude/hooks/*` in target project       |

### Platform Parity

Every hook has both `.sh` (Unix) and `.ps1` (Windows) versions. **Always update both** when changing hook logic. Same for `setup.sh` / `setup.ps1`.

### setup.sh Behavior

- `copy_file()` skips existing files unless `-f` (force) is passed
- CLAUDE.md and CONTINUITY.md are **never overwritten** even with `-f` (user content)
- Rules, commands, hooks, and settings CAN be safely refreshed with `-f`
- `-t python|typescript|fullstack` controls which language-specific rules are copied

### Hook Design

- **SessionStart hooks** (`session-start.sh`): Output JSON with `hookSpecificOutput.additionalContext` for silent context injection
- **Stop hooks** (`check-state-updated.sh`): Use `exit 2` + stderr message to block
- **PreCompact hooks**: Use `exit 0` (non-blocking) — just reminders
- **PostToolUse hooks**: Match file extensions, run formatters, `exit 0` always
- Prompt-type hooks must return `{"ok": true}` or `{"ok": false, "reason": "..."}`

---

## Detailed Rules

All coding standards, workflow rules, and policies are in `.claude/rules/`.
These files are auto-loaded by Claude Code with the same priority as this file.

**What's in `.claude/rules/`:**

- `principles.md` — Top-level principles and design philosophy
- `workflow.md` — Decision matrix for choosing the right command
- `worktree-policy.md` — Git worktree isolation rules
- `critical-rules.md` — Non-negotiable rules (branch safety, TDD, etc.)
- `memory.md` — How to use persistent memory and save learnings
- `security.md`, `testing.md`, `api-design.md` — Coding standards
- Language-specific: `python-style.md`, `typescript-style.md`, `database.md`, `frontend-design.md`
