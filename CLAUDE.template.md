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

**Use workflow commands.** They contain the full process - follow them exactly.

---

## Decision Matrix

| Scenario | Action |
|----------|--------|
| Starting new feature | Run `/new-feature <name>` (creates worktree) |
| Fixing a bug | Run `/fix-bug <name>` (creates worktree) |
| Trivial change (< 3 files) | Run `/quick-fix <name>` (no worktree) |
| Creating PR to main | **Ask** |
| Merging PR to main | **Ask** |
| Skipping tests | **Never** |

---

## Worktree Policy

**`/new-feature` and `/fix-bug` ALWAYS create a worktree** (unless already inside one). This ensures parallel sessions never mix work - even if you're on an unrelated feature branch.

**`/quick-fix` does NOT create worktrees** - it's for trivial changes only.

When running Superpowers skills (`brainstorming`, `writing-plans`, `executing-plans`), these skills may attempt to create worktrees. **SKIP worktree creation** in these skills - you're already isolated.

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
