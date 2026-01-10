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
cd frontend && pnpm test:e2e               # E2E tests

# Git
git checkout -b feat/{name}                # Start feature
gh pr create --base main                   # Create PR
```

---

## Workflow

> **CRITICAL:** This workflow is MANDATORY. Skills activate automatically and enforce it.

### Session Start (Automated via Hook)
The `SessionStart` hook automatically loads CONTINUITY.md into context. You will see:
- Current goal and constraints
- Done/Now/Next state
- Active plans and artifacts

**Your first action:** Confirm you've read the state and ask what to work on.

### Full Workflow

```
START           → git checkout -b feat/{feature-name}
                        │
PRD PHASE       → /prd:discuss → /prd:create
                        │
DESIGN          → /superpowers:brainstorm → /superpowers:write-plan
                        │
EXECUTE         → /superpowers:execute-plan (TDD enforced)
                        │
REVIEW          → /workflows:review (14 agents)
                        │
SIMPLIFY        → "Use the code-simplifier agent on modified files"
                        │
VERIFY          → "Use the verify-app agent"
                        │
COMPOUND        → /workflows:compound (if learnings)
                        │
FINISH          → Update CONTINUITY.md → Commit → PR (prompts) → Merge (prompts)
```

### Before Finishing Work (MANDATORY)

> **These steps are NOT optional.** Complete them IN ORDER before saying "done".

1. **Review** - `/workflows:review` (14 agents, fix issues found)
2. **Simplify** - "Use the code-simplifier agent on modified files"
3. **Verify** - "Use the verify-app agent" OR run all tests manually
4. **Compound** - `/workflows:compound` (if bugs fixed or patterns learned)
5. **Update CONTINUITY.md** - Move items to Done, update Now/Next
6. **Update CHANGELOG.md** - If significant work
7. **Commit + Push** - To feature branch (no prompt needed)
8. **Create PR + Merge** - Will prompt for permission

---

## State Management

| File | Purpose | Who Updates | When |
|------|---------|-------------|------|
| `CONTINUITY.md` | Current goal, Done/Now/Next | **You (Claude)** | Every session |
| `docs/CHANGELOG.md` | Historical record | **You (Claude)** | After features/fixes |
| `docs/prds/*.md` | Product requirements | `/prd:create` | Before design |
| `docs/plans/*.md` | Design docs | Superpowers | Per feature |
| `CLAUDE.md` (this) | Rules + learnings | `/workflows:compound` | When mistakes happen |

---

## Decision Matrix

| Scenario | Action |
|----------|--------|
| Starting new feature | **Create feature branch** (no prompt) |
| Code within stated goal | **Proceed** |
| Committing to feature branch | **Proceed** (no prompt) |
| Pushing feature branch | **Proceed** (no prompt) |
| **Creating PR to main** | **Ask** |
| **Merging PR to main** | **Ask** |
| Architectural changes not discussed | **Ask** |
| Skipping tests | **Never** |

## Critical Rules
- **Never commit directly to main** - always use feature branches
- **Never merge without tests passing**
- **Never skip the verify step** - use verify-app agent
- **TDD is mandatory** - Superpowers enforces RED-GREEN-REFACTOR
- **Update CONTINUITY.md before finishing** - Stop hook enforces this
- **Use code-simplifier after review** - clean code ships
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

## Compound Engineering: Learnings & Don'ts

When Claude makes a mistake or we discover a better pattern, add it here via `/workflows:compound`. This section compounds knowledge over time.

### Don'ts (Learned from Mistakes)
<!-- Add entries when Claude does something incorrectly -->
<!-- Format: "Don't [action] - [consequence/reason]" -->
- **Don't** skip `/workflows:review` before commit (14 agents catch issues you won't)
- **Don't** finish work without updating CONTINUITY.md (Stop hook will catch this)
- **Don't** skip code-simplifier step (tech debt accumulates fast)
- **Don't** merge without running verify-app agent (untested code breaks prod)
<!-- Add project-specific don'ts below -->

### Do's (Discovered Better Patterns)
<!-- Add entries when we find better approaches -->
<!-- Format: "Do [action] - [benefit/reason]" -->
- **Do** use Superpowers brainstorm before any significant feature work
- **Do** run `/workflows:compound` after fixing non-trivial bugs
- **Do** update CONTINUITY.md Done/Now/Next at end of every work session
- **Do** use code-simplifier agent after review, before commit
- **Do** use verify-app agent to ensure comprehensive testing
<!-- Add project-specific do's below -->

### Project-Specific Gotchas
<!-- Add non-obvious things specific to THIS codebase -->
<!-- These are things that aren't obvious from reading the code -->
[ADD PROJECT-SPECIFIC LEARNINGS HERE - Examples:]
- [Example: EmbeddingsService must be lazy-loaded in ToolSyncService (avoid startup failures)]
- [Example: Frontend expects `deployed_server` object with: server_id, server_name, tool_count]
- [Example: Alembic migrations need idempotent enum creation for PostgreSQL]

### How to Update This File

When you (Claude) make a mistake or discover something non-obvious:

1. Run `/workflows:compound` (Compound Engineering plugin)
2. Or manually add to the appropriate section above
3. Be specific, include context
4. Keep it concise - one line per learning, searchable

This is "Compounding Engineering" - each mistake makes the codebase smarter.

---

## Automation (Hooks)

| Hook | What It Does |
|------|--------------|
| `SessionStart` | Loads CONTINUITY.md into context automatically |
| `Stop` | Validates work is complete before stopping |
| `SubagentStop` | Validates subagent output quality |
| `PostToolUse` | Auto-formats Python/TypeScript after edits |

The Stop hook is a **safety net** - Claude should update CONTINUITY.md proactively, not wait to be reminded.
