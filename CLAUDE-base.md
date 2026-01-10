# CLAUDE.md - [Project Name]

## Project
[PROJECT DESCRIPTION - Fill in per project]

## Tech Stack
[TECH STACK - Fill in per project]
Example:
- **Backend:** Python 3.12+ / FastAPI / async
- **Frontend:** Next.js 15 / React / shadcn/ui
- **Database:** PostgreSQL + pgvector
- **Deploy:** Kubernetes + Helm

## Commands
[PROJECT-SPECIFIC COMMANDS - Fill in per project]
Example:
```bash
# Backend
cd src && uv run pytest                    # Tests
cd src && uv run mypy --strict {package}   # Types
cd src && uv run ruff check . && uv run ruff format .  # Lint

# Frontend
cd frontend && pnpm test                   # Unit tests
cd frontend && pnpm build                  # Build check
cd frontend && pnpm test:e2e               # E2E tests

# Git (Feature Branch Workflow)
git checkout -b feat/{name}                # Start feature
git push origin feat/{name}                # Push branch
gh pr create --base main                   # Create PR
gh pr merge --squash                       # Merge (after approval)
```

---

## Workflow (Superpowers + Compound Engineering)

> **CRITICAL:** This workflow is MANDATORY. Skills activate automatically and enforce it.

### Session Start (Automated via Hook)
The `SessionStart` hook automatically loads CONTINUITY.md into context. You will see:
- Current goal and constraints
- Done/Now/Next state
- Active plans and artifacts

**Your first action:** Confirm you've read the state and ask what to work on.

### Full Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ START: Create Feature Branch                                │
│ git checkout -b feat/{feature-name}                        │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    PRD PHASE                                │
│  /prd:discuss → /prd:create                                │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    SUPERPOWERS                              │
│  /superpowers:brainstorm → /superpowers:write-plan         │
│  → /superpowers:execute-plan (TDD)                         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│               COMPOUND ENGINEERING                          │
│  /workflows:review (14 agents)                             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│               CODE SIMPLIFY (Official Plugin)               │
│  "Use the code-simplifier agent on modified files"         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    VERIFY                                   │
│  "Use the verify-app agent" OR run tests manually          │
│  Unit + Integration + E2E + Types + Lint                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│               COMPOUND (if learnings)                       │
│  /workflows:compound → Updates this file                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    FINISH                                   │
│  Update CONTINUITY.md + CHANGELOG.md                       │
│  Commit + Push (no prompt)                                 │
│  Create PR (PROMPTS) → Merge (PROMPTS)                     │
└─────────────────────────────────────────────────────────────┘
```

| Phase | Command | Plugin/Custom | Notes |
|-------|---------|---------------|-------|
| **Branch** | `git checkout -b feat/{name}` | Git | Always start on feature branch |
| **Discuss** | `/prd:discuss` | Custom | Refine user stories, surface gaps |
| **PRD** | `/prd:create` | Custom | Structured PRD with acceptance criteria |
| Design | `/superpowers:brainstorm` | Superpowers | Technical design |
| Plan | `/superpowers:write-plan` | Superpowers | Creates bite-sized TDD tasks |
| Execute | `/superpowers:execute-plan` | Superpowers | Subagents, TDD enforced |
| Review | `/workflows:review` | Compound Engineering | 14 agents in parallel |
| **Simplify** | `Use code-simplifier agent` | Official Plugin | Clean up code |
| **Verify** | `Use verify-app agent` | Custom Agent | Run all tests |
| Learnings | `/workflows:compound` | Compound Engineering | Updates this file |
| **Merge** | `gh pr create` + `gh pr merge` | GitHub CLI | Only after all tests pass |

### PRD Phase (MANDATORY for new features)

> **Never start technical design without a written PRD.**

1. **Discuss First** - `/prd:discuss {feature-name}`
   - Ask targeted questions about gaps, edge cases, personas
   - Output: `docs/prds/{feature}-discussion.md`

2. **Create PRD** - `/prd:create {feature-name}`
   - Generates structured PRD from discussion
   - Output: `docs/prds/{feature}.md`

3. **Then Design** - `/superpowers:brainstorm`

### Before Finishing Work (MANDATORY - You Do This Automatically)

> **These steps are NOT optional.** Complete them IN ORDER before saying "done".

#### Step 1: Run Review (if code changed)
```
/workflows:review
```
Wait for 14 agents. Fix issues found.

#### Step 2: Simplify Code (NEW)
```
Use the code-simplifier agent on the files we modified
```
Clean up architecture, improve readability.

#### Step 3: Verify (Run ALL Tests)

**Option A: Use verify-app agent**
```
Use the verify-app agent to verify all changes
```

**Option B: Manual verification**
```bash
# Backend
cd src && uv run pytest
cd src && uv run mypy --strict {package}
cd src && uv run ruff check .

# Frontend
cd frontend && pnpm test
cd frontend && pnpm build
cd frontend && pnpm test:e2e
```

#### Step 4: Compound (if bugs fixed or patterns learned)
```
/workflows:compound
```

#### Step 5: Update CONTINUITY.md
Edit directly:
- Move completed items to **Done** (add date)
- Update **Now** to reflect current state
- Update **Next** if priorities changed

#### Step 6: Update docs/CHANGELOG.md (if significant work)

#### Step 7: Commit and Push Feature Branch (No Prompt Needed)
```bash
git add .
git commit -m "feat: {description}"
git push origin {feature-branch}
```

#### Step 8: Create PR and Merge to Main (ASKS PERMISSION)
```bash
gh pr create --base main --head {feature-branch} --title "feat: description"
gh pr merge --squash
```

#### Step 9: Clean Up
```bash
git checkout main
git pull origin main
git branch -d {feature-branch}
git push origin --delete {feature-branch}
```

---

## State Management

| File | Purpose | Who Updates | When |
|------|---------|-------------|------|
| `CONTINUITY.md` | Current goal, Done/Now/Next | **You (Claude)** | Every session, every milestone |
| `docs/CHANGELOG.md` | Historical record | **You (Claude)** | After features, bug fixes |
| `docs/prds/*.md` | Product requirements | `/prd:create` | Before technical design |
| `docs/plans/*.md` | Design docs & plans | Superpowers | Per-feature lifecycle |
| `CLAUDE.md` (this) | Rules, workflow, learnings | `/workflows:compound` or manual | When mistakes happen |

---

## Decision Matrix

| Scenario | Action |
|----------|--------|
| Starting new feature | **Create feature branch** (no prompt) |
| Code implementation within stated goal | **Proceed** |
| Adding/removing dependencies | **Proceed** |
| Committing to feature branch | **Proceed** (no prompt) |
| Pushing feature branch to origin | **Proceed** (no prompt) |
| **Creating PR to merge to main** | **Ask** |
| **Merging PR to main** | **Ask** |
| Architectural changes not discussed | **Ask** |
| Skipping E2E tests | **Never** |

## Critical Rules
- **Never commit features directly to main** - always use feature branches
- **Never merge to main without E2E tests passing**
- **Never skip E2E testing** - Chrome extension first, Playwright fallback
- **Challenge me when there's a better way** - don't blindly agree
- **No mocks in final validation** - real integration/e2e tests required
- **TDD is mandatory** - Superpowers enforces RED-GREEN-REFACTOR
- **Update CONTINUITY.md before finishing** - Stop hook enforces this
- **Use code-simplifier after review** - Clean code ships

## Detailed Rules
See `.claude/rules/` for:
- `python-style.md` - Python coding standards
- `database.md` - Database conventions
- `api-design.md` - REST API patterns
- `security.md` - Security requirements
- `testing.md` - Testing patterns

---

## Compound Engineering: Learnings & Don'ts

When Claude makes a mistake or we discover a better pattern, add it here via `/workflows:compound`.

### Don'ts (Learned from Mistakes)
<!-- Add entries when Claude does something incorrectly -->
- **Don't** skip `/workflows:review` before commit (14 agents catch issues you won't)
- **Don't** finish work without updating CONTINUITY.md (Stop hook will catch this)
- **Don't** skip code-simplifier step (clean code is maintainable code)

### Do's (Discovered Better Patterns)
<!-- Add entries when we find better approaches -->
- **Do** use Superpowers brainstorm before any significant feature work
- **Do** run `/workflows:compound` after fixing non-trivial bugs
- **Do** update CONTINUITY.md Done/Now/Next at end of every work session
- **Do** use code-simplifier agent after review, before commit
- **Do** use verify-app agent to ensure comprehensive testing

### Project-Specific Gotchas
<!-- Add non-obvious things specific to this codebase -->
[ADD PROJECT-SPECIFIC LEARNINGS HERE]

---

## Plugin Stack

```bash
# Install these plugins:
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

/plugin marketplace add EveryInc/compound-engineering-plugin
/plugin install compound-engineering@compound-engineering-plugin

# Official code simplifier (NEW - from Anthropic)
/plugin install code-simplifier
```

### Agents (in .claude/agents/)
- `verify-app.md` - End-to-end verification

### MCP Servers (in .claude/settings.json)
- `playwright` - Browser automation for E2E tests
- `context7` - Documentation lookup

---

## Automation (Hooks)

| Hook | What It Does |
|------|--------------|
| `SessionStart` | Loads CONTINUITY.md into context automatically |
| `Stop` | Validates work is complete (prompt-based + script backup) |
| `SubagentStop` | Validates subagent output quality |
| `PostToolUse` | Auto-formats Python/TypeScript after edits |

### Role of Stop Hook
The Stop hook is a **safety net**, not the primary enforcement:
- Prompt-based: Evaluates if work is truly complete
- Script backup: Checks if CONTINUITY.md was modified

**Claude should update proactively, not wait to be reminded.**

---

## How to Update This File

When you (Claude) make a mistake or discover something non-obvious:

1. Run `/workflows:compound` (Compound Engineering plugin)
2. Or manually add to the appropriate section above
3. Be specific, include context
4. Keep it concise - one line per learning, searchable

This is "Compounding Engineering" - each mistake makes the codebase smarter.
