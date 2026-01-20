# New Feature Workflow

> **This workflow is MANDATORY. Follow every step in order.**
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin | Skills/Commands Used |
|--------|---------------------|
| `superpowers@superpowers-marketplace` | `/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:executing-plans`, `/superpowers:systematic-debugging`, `/superpowers:finishing-a-development-branch` |
| `compound-engineering@every-marketplace` | `/compound-engineering:workflows:review`, `/compound-engineering:workflows:compound`, `/compound-engineering:playwright-test`, `/compound-engineering:deepen-plan` |
| `pr-review-toolkit@claude-plugins-official` | `code-simplifier` agent, `code-reviewer` agent |

**To enable plugins**, add to `~/.claude/settings.json`:
```json
{
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "compound-engineering@every-marketplace": true,
    "pr-review-toolkit@claude-plugins-official": true
  }
}
```

---

## Pre-Flight Checks

### 1. Create Isolated Workspace (enables parallel sessions)

**Determine current state:**
```bash
if [[ "$(pwd)" == *".worktrees/"* ]]; then
  echo "STATE: ALREADY_IN_WORKTREE"
elif [[ "$(git branch --show-current)" =~ ^(main|master)$ ]]; then
  echo "STATE: ON_MAIN"
else
  echo "STATE: ON_FEATURE_BRANCH"
fi
```

**If ON_MAIN → Create worktree and cd into it:**
```bash
FEATURE_NAME="$ARGUMENTS"
WORKTREE_PATH=".worktrees/$FEATURE_NAME"

# Ensure .worktrees exists and is gitignored
mkdir -p .worktrees
grep -qxF '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore

# Create worktree (handle existing branch/worktree cases)
if [ -d "$WORKTREE_PATH" ]; then
  echo "✓ Worktree exists - reusing $WORKTREE_PATH"
elif git show-ref --quiet "refs/heads/feat/$FEATURE_NAME" 2>/dev/null; then
  git worktree add "$WORKTREE_PATH" "feat/$FEATURE_NAME"
  echo "✓ Created worktree for existing branch at $WORKTREE_PATH"
else
  git worktree add "$WORKTREE_PATH" -b "feat/$FEATURE_NAME"
  echo "✓ Created new worktree at $WORKTREE_PATH"
fi

# Copy environment files to worktree
for f in .env .env.local .env.development .env.test; do
  [ -f "$f" ] && cp "$f" "$WORKTREE_PATH/"
done
```

**Then cd into the worktree:**
```bash
cd "$WORKTREE_PATH"
```

**Install dependencies (if needed):**
```bash
# Node.js
if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
  pnpm install --silent 2>/dev/null || npm install --silent 2>/dev/null || yarn install --silent 2>/dev/null
fi

# Python
if [ -f "pyproject.toml" ]; then
  uv sync 2>/dev/null || pip install -e . 2>/dev/null || echo "Run 'uv sync' manually"
fi
```

**⚠️ IMPORTANT: You are now working inside the worktree.**
- All file paths are relative to the worktree (e.g., `src/main.py`, not `.worktrees/auth/src/main.py`)
- All git commands operate on the worktree's branch
- Hooks will automatically check the correct files

**If ALREADY_IN_WORKTREE or ON_FEATURE_BRANCH:**
- You're already isolated - continue with current workspace
- No cd needed

### 2. Read project state
```bash
cat CONTINUITY.md
```

### 3. Verify required plugins are available (test ONE skill)
```
/superpowers:brainstorming
```

**If "Unknown skill" error:**
- STOP immediately
- Tell user: "Required plugins not loaded. Please enable in ~/.claude/settings.json and restart Claude Code."
- Do NOT proceed with workarounds or skip mandatory steps

### 4. Worktree Policy Reminder

**DO NOT create additional worktrees** during this workflow. If `/superpowers:brainstorming` or other skills attempt to create a worktree, **SKIP that step** - you're already isolated.

---

## Phase 1: Research (DO NOT SKIP)

Before writing ANY code, research the problem space:

1. **Search existing solutions**:
   ```bash
   grep -r "relevant keywords" docs/solutions/
   ```

2. **Research current best practices**:
   - Use `WebSearch` for current documentation
   - Use `WebFetch` for specific library docs
   - Use `Context7` MCP for framework-specific guidance

3. **Study competitors**: How do established products solve this problem?

---

## Phase 2: Requirements

Run the PRD workflow:

```
/prd:discuss
```

Then create the PRD:

```
/prd:create
```

---

## Phase 3: Design

### 3.1 Brainstorm approaches

```
/superpowers:brainstorming
```

### 3.2 Write the implementation plan

```
/superpowers:writing-plans
```

### 3.3 Enhance the plan with parallel research

```
/compound-engineering:deepen-plan
```

---

## Phase 4: Execute

Implement using TDD (Red-Green-Refactor):

```
/superpowers:executing-plans
```

**If you encounter bugs during implementation:**

```
/superpowers:systematic-debugging
```

---

## Phase 5: Quality Gates (ALL REQUIRED)

> **If any command below fails with "Unknown skill":**
> - Alert the user about missing plugins
> - Perform equivalent checks manually (see fallbacks below)
> - Do NOT skip quality gates

### 5.1 Code Review (14 specialized agents)

```
/compound-engineering:workflows:review
```

Fix ALL issues found before proceeding.

**Fallback if unavailable:** Use `pr-review-toolkit:code-reviewer` agent on modified files.

### 5.2 Simplify

Use the code-simplifier agent on all modified files:

```
"Use the code-simplifier agent on [list modified files]"
```

**Fallback if unavailable:** Manually review for:
- Unnecessary complexity, dead code, duplicate logic
- Functions > 50 lines that could be split
- Over-engineered abstractions

### 5.3 Verify (USE SUBAGENT - saves context window)

**MUST use the verify-app subagent** - Do NOT run tests yourself.

Using a subagent keeps test output out of your context window, preserving tokens for actual work.

**Invoke the subagent:**
```
Use the Task tool with:
- subagent_type: "verify-app"
- prompt: "Run verification and report pass/fail verdict."
```

**Only use fallback if Task tool fails:**
```bash
pytest && ruff check . && mypy .  # Python
npm test && npm run lint && npm run typecheck  # Node
```

### 5.4 E2E Tests (MANDATORY if API changed)

**If you modified ANY API endpoint, you MUST run E2E tests.**

The API doesn't exist in isolation - frontend code depends on it. Even if you didn't touch the frontend, API changes can break existing UI functionality.

**Step 1: Find what uses the changed API**
```bash
# Search frontend for API endpoint usage
grep -r "your-endpoint-path" frontend/
```

**Step 2: Run E2E tests on affected UI**
```
/compound-engineering:playwright-test
```

**DO NOT skip this step by saying:**
- ❌ "No frontend exists for this endpoint" → Test the UI that USES the API
- ❌ "Unit tests cover it" → Unit tests don't catch integration issues
- ❌ "The API is new" → New APIs should be integration tested

**Only skip if:** The change is purely backend with NO frontend consumers (e.g., internal scripts, migrations).

---

## Phase 6: Finish

### 6.1 Compound learnings (if any)

If you fixed bugs or discovered patterns:

```
/compound-engineering:workflows:compound
```

**Fallback if unavailable:** Create solution doc manually in `docs/solutions/[category]/`.

### 6.2 Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next
2. **docs/CHANGELOG.md**: If 3+ files changed on branch

### 6.3 Complete the branch

```
/superpowers:finishing-a-development-branch
```

**Fallback if unavailable:** Complete manually:
1. Run final verification (tests, lint, types)
2. Stage and commit changes with descriptive message
3. Push branch to remote
4. Create PR if ready for review

### 6.4 Cleanup worktree (if created)

**Only if you created a worktree in Pre-Flight (started from main):**

After the branch is merged and deleted, clean up the worktree:

```bash
# First, go back to the main repository
cd "$(git rev-parse --git-common-dir)/.."

# Remove the worktree
git worktree remove ".worktrees/$FEATURE_NAME"

# Prune any stale worktree references
git worktree prune
```

**If PR is still open (not merged yet):**
- Keep the worktree for potential follow-up work (addressing review comments)
- Cleanup will happen after merge

**Ask the user:** "The branch has been pushed/merged. Should I clean up the worktree?"

---

## ⚠️ IMPORTANT: Never Bypass Mandatory Steps

If any MANDATORY step cannot be completed:
1. **STOP** - Do not continue with workarounds
2. **ALERT** - Tell the user which step failed and why
3. **WAIT** - Get user guidance before proceeding
4. **NEVER** use bash/python scripts to bypass Edit hooks or skip workflow validation

---

## Checklist Summary

**Pre-Flight:**
- [ ] Created worktree and cd'd into it (if on main)
- [ ] Read CONTINUITY.md
- [ ] **Verified plugins loaded** (if "Unknown skill" → STOP, alert user)

**Research & Requirements:**
- [ ] Researched existing solutions and best practices
- [ ] PRD created via `/prd:create`

**Design:**
- [ ] Brainstormed via `/superpowers:brainstorming`
- [ ] Plan written via `/superpowers:writing-plans`
- [ ] Plan enhanced via `/compound-engineering:deepen-plan`

**Implementation:**
- [ ] Executed via `/superpowers:executing-plans` (TDD)

**Quality Gates (ALL REQUIRED):**
- [ ] Code reviewed via `/compound-engineering:workflows:review` or `code-reviewer` agent
- [ ] Simplified via `code-simplifier` agent
- [ ] Verified via `verify-app` agent (tests, lint, types pass)
- [ ] **E2E tested via `/compound-engineering:playwright-test`** (MANDATORY if API changed)

**Finish:**
- [ ] Learnings compounded via `/compound-engineering:workflows:compound` (if any)
- [ ] CONTINUITY.md updated
- [ ] CHANGELOG.md updated (if 3+ files)
- [ ] Branch finished via `/superpowers:finishing-a-development-branch`
- [ ] **Worktree cleaned up** (if created) - ask user after merge
