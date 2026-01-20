# CLAUDE.md - [Project Name]

## Project Overview

### What Is This?
[PROJECT DESCRIPTION - 2-3 sentences explaining what this project does]

### Tech Stack
[TECH STACK - Fill in per project]
- **Backend:**
- **Frontend:**
- **Database:**
- **Deploy:**

### File Structure
```
[PROJECT STRUCTURE - Fill in per project]
project/
├── src/              # Backend code
├── frontend/         # Frontend code
├── tests/            # Test files
├── docs/             # Documentation
│   ├── prds/         # Product requirements
│   ├── plans/        # Design documents
│   ├── solutions/    # Compounded learnings (searchable)
│   └── CHANGELOG.md  # Historical record
└── .claude/          # Claude Code configuration
    └── commands/     # Workflow commands (ENFORCED)
```

### Key Commands
```bash
[PROJECT-SPECIFIC COMMANDS - Fill in per project]

# Workflows (MANDATORY - hooks enforce these)
/new-feature <name>     # Full feature workflow
/fix-bug <name>         # Bug fix with systematic debugging
/quick-fix <name>       # Trivial changes only (< 3 files)

# Example project commands:
cd src && uv run pytest                    # Run tests
cd src && uv run ruff check .              # Lint
git checkout -b feat/{name}                # Start feature
```

---

## Top-Level Principles

**Work doggedly.** Be autonomous. Continue working toward the user's goal until you can no longer make progress.

**Work smart.** When debugging, think deeply. Add logging to check assumptions.

**Check your work.** Run code to verify it works. Check logs after starting processes.

**Research first.** AI knowledge has a cutoff. Use WebSearch/WebFetch/Context7 for current docs.

**Learn from competitors.** Before implementing features, research how established products solved it.

---

## Core Design Philosophy

- **Brutal simplicity** over clever solutions (KISS)
- **Composition** over inheritance
- **Immutability** by default
- **DRY** - if it appears twice, extract it
- **Reuse** - check if a utility exists before creating new code

---

## Workflow

> **GUIDED via workflow commands.** SessionStart loads context. Stop hook validates completion.

| Task Type | Command | What It Contains |
|-----------|---------|------------------|
| New feature | `/new-feature <name>` | Research → PRD → Brainstorm → Plan → Execute → Review → Finish |
| Bug fix | `/fix-bug <name>` | Search solutions → Systematic debugging → Fix → Review → Compound → Finish |
| Trivial change | `/quick-fix <name>` | Verify → Fix → Verify → Finish |

**The commands contain the full workflow. Follow them exactly.**

---

## State Management

| File | Purpose | When |
|------|---------|------|
| `CONTINUITY.md` | Current goal, Done/Now/Next | Every session |
| `docs/CHANGELOG.md` | Historical record | After features/fixes (3+ files) |
| `docs/prds/*.md` | Product requirements | Before design |
| `docs/plans/*.md` | Design docs | Per feature |
| `docs/solutions/*.md` | Compounded learnings | After fixing bugs |

---

## Decision Matrix

| Scenario | Action |
|----------|--------|
| Session start on main | **Create worktree** via workflow command |
| Starting new feature | Run `/new-feature <name>` |
| Fixing a bug | Run `/fix-bug <name>` |
| Trivial change (< 3 files) | Run `/quick-fix <name>` |
| Creating PR to main | **Ask** |
| Merging PR to main | **Ask** |
| Skipping tests | **Never** |

---

## Parallel Development (Worktrees)

> **Enables multiple Claude sessions working simultaneously on different features.**

### How It Works

When `/new-feature` or `/fix-bug` runs and you're on `main`:
1. Creates isolated worktree at `.worktrees/<name>/`
2. Copies `.env*` files automatically
3. Installs dependencies
4. **cd's into the worktree** - all subsequent commands run there

> **CRITICAL**: Always run `claude` from the **project root**, not from inside `.worktrees/`. The `.claude/` folder with hooks and settings lives in the main repo only.

### Working Inside a Worktree

After `cd`ing into the worktree:
- All file paths are relative (e.g., `src/main.py`, not `.worktrees/auth/src/main.py`)
- All git commands operate on the worktree's branch
- Hooks run in the current directory and check the correct files

### No Nested Worktrees

**Worktrees are created ONLY at workflow start (Pre-Flight).**

When running Superpowers skills (`brainstorming`, `writing-plans`, `executing-plans`), these skills may attempt to create worktrees. **SKIP worktree creation** in these skills - you're already isolated.

### Multiple Sessions Example

```bash
# Terminal 1
cd /project && claude
> /new-feature auth        # Creates .worktrees/auth/, cd's into it

# Terminal 2
cd /project && claude
> /new-feature api         # Creates .worktrees/api/, cd's into it

# Terminal 3
cd /project && claude
> /fix-bug login-error     # Creates .worktrees/login-error/, cd's into it
```

Each session is fully isolated. No conflicts.

### Cleanup After Merge

After a branch is merged, clean up the worktree:

```bash
# Go back to main repo
cd "$(git rev-parse --git-common-dir)/.."

# Remove the worktree
git worktree remove ".worktrees/<name>"
git worktree prune
```

---

## Critical Rules

- **CHECK BRANCH** - Never work on `main`
- **USE WORKFLOW COMMANDS** - `/new-feature`, `/fix-bug`, or `/quick-fix`
- **SYSTEMATIC DEBUGGING** - Use `/superpowers:systematic-debugging` for bugs
- **TDD MANDATORY** - Red-Green-Refactor via Superpowers
- **E2E TESTING** - `/compound-engineering:playwright-test` for UI/API changes
- **UPDATE STATE** - CONTINUITY.md + CHANGELOG.md (Stop hook enforces)
- **RESEARCH FIRST** - WebSearch/WebFetch/Context7 before implementing
- **CHALLENGE ME** - Don't blindly agree

---

## Detailed Rules

See `.claude/rules/` for language-specific standards.

---

## Automation (Hooks)

| Hook | What It Does |
|------|--------------|
| `SessionStart` | Loads CONTINUITY.md, prompts for task type |
| `Stop` | Validates workflow complete, CONTINUITY.md updated |
| `SubagentStop` | Validates subagent output quality |
| `PostToolUse` | Auto-formats Python/TypeScript after edits |
