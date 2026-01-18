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
```

### Key Commands
```bash
[PROJECT-SPECIFIC COMMANDS - Fill in per project]

# Example format:
# Backend
cd src && uv run pytest                    # Run tests
cd src && uv run mypy --strict {package}   # Type check
cd src && uv run ruff check .              # Lint

# Frontend
cd frontend && pnpm test                   # Unit tests
cd frontend && pnpm build                  # Build
# E2E: Use /test-browser command (not pnpm)

# Git
git checkout -b feat/{name}                # Start feature
gh pr create --base main                   # Create PR
```
---

## Top-Level Principles

Work doggedly. Your goal is to be autonomous as long as possible. If you know the user's overall goal, and there is still progress you can make towards that goal, continue working until you can no longer make progress. Whenever you stop working, be prepared to justify why.

Work smart. When debugging, take a step back and think deeply about what might be going wrong. When something is not working as intended, add logging to check your assumptions.

Check your work. If you write a chunk of code, try to find a way to run it and make sure it does what you expect. If you kick off a long process, wait 30 seconds then check the logs to make sure it is running as expected.

Be cautious with terminal commands. Before every terminal command, consider carefully whether it can be expected to exit on its own, or if it will run indefinitely (e.g. launching a web server). For processes that run indefinitely, always launch them in a new process (e.g. nohup).

Research before implementing. AI knowledge has a cutoff date. ALWAYS use WebSearch and WebFetch tools to research current documentation, best practices, and library versions BEFORE implementing. Libraries and frameworks evolve rapidly—never assume your training data is current.

Learn from competitors. Before implementing any significant feature, research how established products solved the same problem. Their solutions have been battle-tested in production—study their patterns, edge cases, and UX decisions.

---

## Core Design Philosophy

### Simplicity First
- **Brutal simplicity** is preferred over clever or complex solutions
- **KISS principle** (Keep It Stupid Simple) - everything should be straightforward to understand
- Avoid over-engineering and unnecessary abstractions
- Only add complexity when truly required by the problem domain

### Composition Over Inheritance
- Prefer composition to inheritance - inheritance should be rare and strictly necessary
- Default to composition patterns for code reuse
- Avoid deep inheritance hierarchies

### Immutability Preference
- Favor immutable data structures and objects
- Only introduce mutability when strictly necessary for performance or design requirements

### DRY Principle
- Do not repeat code - if something appears twice, it should be extracted into a function
- The DRY principle naturally uncovers beautiful, maintainable code patterns

### Code Reuse Over Recreation
- **Always check if a utility exists before creating new code**
- Common utilities are constantly evolving, understand them before reaching for new solutions

---

## Workflow

> **CRITICAL:** This workflow is MANDATORY. Skills activate automatically and enforce it.

### Session Start (Automated via Hook)
The `SessionStart` hook automatically:
1. Shows current git branch
2. Loads CONTINUITY.md into context

**Your first actions:**
1. **CHECK THE BRANCH** - If on `main`, STOP and create a feature branch immediately
2. Confirm you've read the state
3. Ask what to work on

**⚠️ IF ON MAIN:** Do not proceed with any code changes. First:
```bash
git checkout -b feat/   # or fix/
```

### Full Workflow

```
START           → git checkout -b feat/{feature-name}
                        │
RESEARCH        → WebSearch/WebFetch/Context7 for current docs, best practices
                        │
PRD PHASE       → /prd:discuss → /prd:create (includes web research)
                        │
DESIGN          → /superpowers:brainstorm → /superpowers:write-plan
                        │
ENHANCE PLAN    → /deepen-plan (parallel research agents add depth to plan)
                        │
EXECUTE         → /superpowers:execute-plan (TDD enforced)
                        │
DEBUG (if bugs) → /superpowers:systematic-debugging (4-phase root cause analysis)
                        │
REVIEW          → /workflows:review (14 agents from Compound Engineering)
                        │
SIMPLIFY        → code-simplifier agent (simplify modified files)
                        │
VERIFY          → verify-app agent (unit tests, migrations, lint, types)
                        │
E2E             → /test-browser (if UI/API changed)
                        │
COMPOUND        → /workflows:compound (if learnings)
                        │
FINISH          → CONTINUITY.md → CHANGELOG.md → /superpowers:finishing-a-development-branch
```

### Before Finishing Work (MANDATORY)

> **These steps are NOT optional.** Complete them IN ORDER before saying "done".

1. **Review** - `/workflows:review` (14 agents from Compound Engineering, fix issues found)
2. **Simplify** - Use `code-simplifier` agent on modified files
4. **Verify Tests** - `verify-app` agent (unit tests, migrations, lint, types)
5. **E2E Tests** - `/test-browser` (if UI/API changed, uses agent-browser)
6. **Compound** - `/workflows:compound` (if bugs fixed or patterns learned)
7. **Update CONTINUITY.md** - Update Done (keep 2-3 recent), Now/Next
8. **Update CHANGELOG.md** - If 3+ files changed on branch
9. **Finish Branch** - `/superpowers:finishing-a-development-branch` (structured completion with 4 options)

---

## State Management

| File | Purpose | Who Updates | When |
|------|---------|-------------|------|
| `CONTINUITY.md` | Current goal, Done/Now/Next | **You (Claude)** | Every session |
| `docs/CHANGELOG.md` | Historical record | **You (Claude)** | After features/fixes |
| `docs/prds/*.md` | Product requirements | `/prd:create` | Before design |
| `docs/plans/*.md` | Design docs | Superpowers | Per feature |
| `docs/solutions/*.md` | Compounded learnings | `/workflows:compound` | After fixing bugs/discovering patterns |
| `todos/`| Document technical debt found by code review workflow| `/workflows:review` | After features/fixes |
| `CLAUDE.md` (this) | Rules + workflow | Manual | Rarely (process changes only) |

---

## Decision Matrix

| Scenario | Action |
|----------|--------|
| **Session start on main branch** | **Create feature branch immediately** (ask user for name) |
| Starting new feature | **Create feature branch** (no prompt) |
| Code within stated goal | **Proceed** |
| Committing to feature branch | **Proceed** (no prompt) |
| Pushing feature branch | **Proceed** (no prompt) |
| **Creating PR to main** | **Ask** |
| **Merging PR to main** | **Ask** |
| Architectural changes not discussed | **Ask** |
| Skipping tests | **Never** |

## Critical Rules
- **CHECK BRANCH FIRST** - If on main, create feature branch before ANY code changes
- **RESEARCH BEFORE IMPLEMENTING** - Use WebSearch/WebFetch/Context7 for current docs
- **SYSTEMATIC DEBUGGING** - Use `/superpowers:systematic-debugging` before ANY bug fix attempt
- **Never commit directly to main** - always use feature branches
- **Never merge without tests passing**
- **Never skip E2E tests** - if project has frontend, run `/test-browser` for UI/API changes
- **Never skip verification** - using verify-app agent
- **Always check for migrations** - if models/schema changed, create migration
- **TDD is mandatory** - Superpowers enforces RED-GREEN-REFACTOR
- **Update CONTINUITY.md before finishing** - Stop hook enforces this
- **Update CHANGELOG.md before finishing** - if 3+ files changed, Stop hook enforces this
-- **Always research before implementing.** Use WebSearch/WebFetch/Context7
- **Challenge me when there's a better way** - don't blindly agree

## Detailed Rules
See `.claude/rules/` for:
- `python-style.md` - Python coding standards
- `typescript-style.md` - TypeScript/React standards
- `database.md` - Database conventions
- `api-design.md` - REST API patterns
- `security.md` - Security requirements
- `testing.md` - Testing patterns

---

## Web Research

**Always research before implementing.** Use WebSearch/WebFetch/Context7 to verify:
- Current library versions and breaking changes
- Up-to-date documentation and best practices
- Known issues and security advisories

---

## E2E Testing

**Every user-facing change needs E2E verification.** Use `/test-browser` from Compound Engineering plugin.

### How It Works
```
/test-browser
    ↓
Detects affected routes from git diff
    ↓
Uses agent-browser to test each route
    ↓
Reports pass/fail for each test
```

### Prerequisites
```bash
npm install -g agent-browser
agent-browser install
```

### When to Run
- After any UI component changes
- After API endpoint changes that affect UI
- After routing changes
- Before creating PR for frontend features

---

## Migration Check

**If you changed models/schema, you need a migration.** The verify-app agent checks for pending migrations automatically.

---

## Knowledge Compounding

Learnings are stored in `docs/solutions/` as searchable markdown files with YAML frontmatter. This keeps CLAUDE.md clean while building institutional knowledge.

### How It Works

```
Bug fixed or pattern discovered
        ↓
Run /workflows:compound
        ↓
Creates: docs/solutions/[category]/[symptom]-[module]-[date].md
        ↓
Next occurrence → grep -r "error phrase" docs/solutions/
```

### Solution Categories (auto-detected)
```
docs/solutions/
├── build-errors/
├── test-failures/
├── runtime-errors/
├── performance-issues/
├── database-issues/
├── security-issues/
├── ui-bugs/
├── integration-issues/
├── logic-errors/
└── patterns/           ← consolidated when 3+ similar issues
```

### When to Compound

Run `/workflows:compound` after:
- Fixing a non-trivial bug
- Discovering a gotcha or workaround
- Finding a performance optimization
- Resolving a security issue
- Learning something non-obvious about the codebase

### Retrieving Solutions

When debugging, search for similar issues:
```bash
grep -r "error message" docs/solutions/
grep -r "tags:.*eager-loading" docs/solutions/
ls docs/solutions/performance-issues/
```

The compound-engineering plugin creates structured files with YAML frontmatter for searchability.

---

## Automation (Hooks)

| Hook | What It Does |
|------|--------------|
| `SessionStart` | Loads CONTINUITY.md into context automatically |
| `Stop` | Validates workflow is complete before stopping |
| `SubagentStop` | Validates subagent output quality |
| `PostToolUse` | Auto-formats Python/TypeScript after edits |

