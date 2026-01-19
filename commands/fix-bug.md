# Bug Fix Workflow

> **This workflow is MANDATORY. Follow every step in order.**
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin | Skills/Commands Used |
|--------|---------------------|
| `superpowers@superpowers-marketplace` | `/superpowers:systematic-debugging`, `/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:executing-plans`, `/superpowers:finishing-a-development-branch` |
| `compound-engineering@every-marketplace` | `/compound-engineering:workflows:review`, `/compound-engineering:workflows:compound`, `/compound-engineering:playwright-test` |
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

**If ON_MAIN → Create worktree:**
```bash
FIX_NAME="$ARGUMENTS"
WORKTREE_PATH=".worktrees/$FIX_NAME"

# Ensure .worktrees exists and is gitignored
mkdir -p .worktrees
grep -qxF '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore

# Create worktree (handle existing branch/worktree cases)
if [ -d "$WORKTREE_PATH" ]; then
  echo "✓ Worktree exists - reusing $WORKTREE_PATH"
elif git show-ref --quiet "refs/heads/fix/$FIX_NAME" 2>/dev/null; then
  git worktree add "$WORKTREE_PATH" "fix/$FIX_NAME"
  echo "✓ Created worktree for existing branch at $WORKTREE_PATH"
else
  git worktree add "$WORKTREE_PATH" -b "fix/$FIX_NAME"
  echo "✓ Created new worktree at $WORKTREE_PATH"
fi

# Copy environment files
for f in .env .env.local .env.development .env.test; do
  [ -f "$f" ] && cp "$f" "$WORKTREE_PATH/"
done

# Write worktree path for hooks to read
echo "$WORKTREE_PATH" > .claude/.session_worktree

# Install dependencies in worktree (if applicable)
if [ -f "$WORKTREE_PATH/package.json" ] && [ ! -d "$WORKTREE_PATH/node_modules" ]; then
  echo "Installing Node dependencies in worktree..."
  (cd "$WORKTREE_PATH" && (pnpm install --silent 2>/dev/null || npm install --silent 2>/dev/null || yarn install --silent 2>/dev/null))
fi
if [ -f "$WORKTREE_PATH/pyproject.toml" ]; then
  echo "Installing Python dependencies in worktree..."
  (cd "$WORKTREE_PATH" && (uv sync 2>/dev/null || pip install -e . 2>/dev/null || echo "Run 'uv sync' or 'pip install' manually"))
fi
```

**⚠️ CRITICAL: Set SESSION_WORKTREE for this session:**
- `SESSION_WORKTREE=".worktrees/$FIX_NAME"`
- **ALL file operations for the rest of this workflow MUST use `$SESSION_WORKTREE/` as base path**
- Example: `$SESSION_WORKTREE/src/main.py`, `$SESSION_WORKTREE/CONTINUITY.md`
- Bash commands: `cd $SESSION_WORKTREE && command`

**If ALREADY_IN_WORKTREE or ON_FEATURE_BRANCH:**
- `SESSION_WORKTREE=""` (empty - use current directory)
- Clear any stale worktree marker: `rm -f .claude/.session_worktree`
- Continue with current workspace, already isolated

### 2. Read project state
```bash
cat ${SESSION_WORKTREE:-.}/CONTINUITY.md
```

### 3. Verify required plugins are available (test ONE skill)
```
/superpowers:systematic-debugging
```

**If "Unknown skill" error:**
- STOP immediately
- Tell user: "Required plugins not loaded. Please enable in ~/.claude/settings.json:
  ```json
  {
    "enabledPlugins": {
      "superpowers@superpowers-marketplace": true,
      "compound-engineering@every-marketplace": true
    }
  }
  ```
  Then restart Claude Code."
- Do NOT proceed with workarounds or skip mandatory steps

### 4. Worktree Policy Reminder

**DO NOT create additional worktrees** during this workflow. If `/superpowers:systematic-debugging` or other skills attempt to create a worktree, **SKIP that step** - you're already isolated.

---

## Phase 1: Research Existing Solutions

Before attempting ANY fix, check if this was solved before:

```bash
grep -r "error message or symptom" docs/solutions/
grep -r "related module name" docs/solutions/
ls docs/solutions/
```

If found, review the solution and apply it.

---

## Phase 2: Systematic Debugging (MANDATORY)

**DO NOT guess at fixes.** Run the 4-phase root cause analysis:

```
/superpowers:systematic-debugging
```

This will guide you through:
1. **Reproduce** - Confirm the bug exists
2. **Isolate** - Narrow down the cause
3. **Identify** - Find the root cause
4. **Verify** - Confirm understanding before fixing

> **⚠️ CRITICAL:** If this skill is unavailable, you MUST still follow the 4-phase process manually:
> 1. Reproduce the bug consistently
> 2. Isolate by adding logging/tracing at component boundaries
> 3. Identify root cause (not just symptoms)
> 4. Verify your understanding before proposing ANY fix
>
> **NEVER skip this phase. NEVER guess at fixes.**

---

## Phase 3: Plan the Fix

### For simple fixes (1-2 files):
Proceed directly to Phase 4.

### For complex fixes (3+ files or architectural):

#### 3.1 Brainstorm approaches

```
/superpowers:brainstorming
```

#### 3.2 Write the fix plan

```
/superpowers:writing-plans
```

---

## Phase 4: Execute the Fix

Implement using TDD (Red-Green-Refactor):

```
/superpowers:executing-plans
```

Or for simple fixes, write a failing test first, then fix.

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
- prompt: "Run verification in $SESSION_WORKTREE and report pass/fail verdict."
  (If SESSION_WORKTREE is empty, just say "Run verification and report pass/fail verdict.")
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
- ❌ "The fix is backend only" → Backend fixes can break frontend behavior

**Only skip if:** The change is purely backend with NO frontend consumers.

---

## Phase 6: Finish

### 6.1 Compound the learning (MANDATORY for bug fixes)

Every bug fix teaches something. Capture it:

```
/compound-engineering:workflows:compound
```

This creates a searchable solution in `docs/solutions/` so the same bug is never debugged twice.

**Fallback if unavailable:** Create solution doc manually:
```bash
mkdir -p docs/solutions/[category]
# Create docs/solutions/[category]/[descriptive-name].md with:
# - Problem: What was the symptom
# - Root Cause: What actually caused it
# - Solution: How to fix it
# - Prevention: How to avoid in future
```

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

**Only if SESSION_WORKTREE was set (worktree was created in Pre-Flight):**

After the branch is merged and deleted, clean up the worktree:

```bash
# Remove the worktree directory and metadata
git worktree remove $SESSION_WORKTREE

# Prune any stale worktree references
git worktree prune
```

> **⚠️ DO NOT delete `.claude/.session_worktree`** - other parallel sessions may be using it.
> The file is harmless if left behind; hooks handle missing worktrees gracefully.

**If PR is still open (not merged yet):**
- Keep the worktree for potential follow-up work
- Cleanup will happen after merge

**Ask the user:** "The branch has been pushed/merged. Should I clean up the worktree at `$SESSION_WORKTREE`?"

---

## ⚠️ IMPORTANT: Never Bypass Mandatory Steps

If any MANDATORY step cannot be completed:
1. **STOP** - Do not continue with workarounds
2. **ALERT** - Tell the user which step failed and why
3. **WAIT** - Get user guidance before proceeding
4. **NEVER** use bash/python scripts to bypass Edit hooks or skip workflow validation

The hooks exist to enforce quality. Bypassing them defeats their purpose.

---

## Checklist Summary

**Pre-Flight:**
- [ ] On fix branch (not main)
- [ ] Read CONTINUITY.md
- [ ] **Verified plugins loaded** (if "Unknown skill" → STOP, alert user)

**Investigation:**
- [ ] Searched docs/solutions/ for existing fixes
- [ ] Ran `/superpowers:systematic-debugging` OR manual 4-phase analysis (MANDATORY)

**Planning (if complex):**
- [ ] Brainstormed via `/superpowers:brainstorming`
- [ ] Plan written via `/superpowers:writing-plans`

**Implementation:**
- [ ] Executed fix with TDD (failing test FIRST, then fix)

**Quality Gates (ALL REQUIRED):**
- [ ] Code reviewed via `/compound-engineering:workflows:review` or `code-reviewer` agent
- [ ] Simplified via `code-simplifier` agent
- [ ] Verified via `verify-app` agent (tests, lint, types pass)
- [ ] **E2E tested via `/compound-engineering:playwright-test`** (MANDATORY if API changed)

**Finish:**
- [ ] **Learning compounded** via `/compound-engineering:workflows:compound` or manual doc (MANDATORY)
- [ ] CONTINUITY.md updated
- [ ] CHANGELOG.md updated (if 3+ files)
- [ ] Branch finished via `/superpowers:finishing-a-development-branch`
- [ ] **Worktree cleaned up** (if created) - ask user after merge
