# Bug Fix Workflow

> **This workflow is MANDATORY. Follow every step in order.**
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin                                      | Skills/Commands Used                                                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `superpowers@superpowers-marketplace`       | `/superpowers:systematic-debugging`, `/superpowers:brainstorming`, `/superpowers:writing-plans`, `/superpowers:executing-plans` |
| `pr-review-toolkit@claude-plugins-official` | `code-simplifier` agent, `code-reviewer` agent, `/pr-review-toolkit:review-pr`                                                  |

**To enable plugins**, add to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "pr-review-toolkit@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true
  }
}
```

---

## Pre-Flight Checks

### 1. Create Isolated Workspace (MANDATORY)

**Check if already in a worktree:**

```bash
if [[ "$(pwd)" == *".worktrees/"* ]]; then
  echo "STATE: ALREADY_IN_WORKTREE"
else
  echo "STATE: NEEDS_WORKTREE"
fi
```

**If ALREADY_IN_WORKTREE:**

- You're already isolated - continue with current workspace
- No action needed

**If NEEDS_WORKTREE → Create worktree and cd into it:**

> ⚠️ **ALWAYS create a worktree**, even if on a feature branch. Being on "a feature branch" doesn't mean it's the right branch for THIS fix. Worktrees ensure parallel sessions never mix work.

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

- All file paths are relative to the worktree (e.g., `src/main.py`, not `.worktrees/fix-name/src/main.py`)
- All git commands operate on the worktree's branch
- Hooks will automatically check the correct files

### 2. Read project state

```bash
cat CONTINUITY.md
```

### 3. Verify required plugins are available (test ONE skill)

```
/superpowers:systematic-debugging
```

**If "Unknown skill" error:**

- STOP immediately
- Tell user: "Required plugins not loaded. Please enable in ~/.claude/settings.json and restart Claude Code."
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
>
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

#### 3.3 Design Review — Second Opinion (MANDATORY)

Get an independent review of the fix plan before implementing. This catches mistakes early.

**Check if Codex CLI is available:**

```bash
command -v codex &>/dev/null && echo "Codex available" || echo "Codex not installed"
```

**If Codex is available:**

```
/codex review the fix plan and flag any concerns
```

**If Codex is NOT available:**

- Present a summary of the fix plan to the user
- Ask: "Does this fix approach look right before I start implementing?"
- Wait for user confirmation before proceeding to Phase 4

#### 3.4 Iterate until approved

**If the review finds P0 or P1 issues:**

1. Edit the plan to address the issues
2. Run `/codex review` again (or ask the user again)
3. Repeat until there are **no P0 or P1 issues** in the review response

Do NOT proceed to Phase 4 until the plan is approved.

> **Why mandatory?** A wrong fix plan leads to wasted effort and potentially new bugs. A quick review here prevents that.

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
>
> - Alert the user about missing plugins
> - Perform equivalent checks manually (see fallbacks below)
> - Do NOT skip quality gates

### 5.1 Code Review Loop (repeats until no P0/P1/P2 issues — P3s acceptable)

Run both reviews **in parallel**:

**a) Second Opinion (Codex CLI):**

Check if Codex CLI is available:

```bash
command -v codex &>/dev/null && echo "Codex available" || echo "Codex not installed"
```

If available:

```
/codex review
```

**b) Deep Review (PR Review Toolkit):**

```
/pr-review-toolkit:review-pr
```

This runs 6 specialized agents: code-reviewer, silent-failure-hunter, pr-test-analyzer, comment-analyzer, type-design-analyzer, and code-simplifier.

**Fallback if unavailable:** Use `pr-review-toolkit:code-reviewer` agent on modified files.

**Iterate:** If either review finds P0, P1, or P2 issues:

1. Fix the issues
2. Run **both** reviews again
3. Repeat until there are **no P0/P1/P2 issues** (P3s are acceptable)

### 5.2 Simplify

Run the built-in `/simplify` command on modified code:

```
/simplify
```

**Fallback (older Claude Code versions):** Use the `code-simplifier` agent on modified files.

### 5.3 Verify (USE SUBAGENT - saves context window)

**MUST use the verify-app subagent** - Do NOT run tests yourself.

Using a subagent keeps test output out of your context window, preserving tokens for actual work.

**Invoke the subagent:**

Launch the `verify-app` agent to run all tests, linting, and type checks. Report only the pass/fail verdict back.

```
Task tool → subagent_type: "verify-app", prompt: "Run verification and report pass/fail verdict."
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

**Step 2: Restart servers from worktree (CRITICAL if in worktree)**

> ⚠️ **If you're in a worktree**, the development servers are likely still running from the main directory, serving OLD code. You MUST restart them from the worktree to test your changes.

Stop the current development servers and start them from this worktree directory. Use the project's start/stop commands from CLAUDE.md.

Wait for servers to be ready before proceeding.

**Step 3: Run E2E tests using Playwright MCP**

Use the Playwright MCP server to run browser tests against affected routes. Navigate to the affected pages, interact with the changed functionality, and verify it works end-to-end.

**DO NOT skip this step by saying:**

- ❌ "No frontend exists for this endpoint" → Test the UI that USES the API
- ❌ "Unit tests cover it" → Unit tests don't catch integration issues
- ❌ "The fix is backend only" → Backend fixes can break frontend behavior

**Only skip if:** The change is purely backend with NO frontend consumers.

---

## Phase 6: Finish

### 6.1 Compound the learning (MANDATORY for bug fixes)

Every bug fix teaches something. Capture it:

1. **Create solution doc** in `docs/solutions/[category]/`:

   ```bash
   mkdir -p docs/solutions/[category]
   # Create docs/solutions/[category]/[descriptive-name].md with:
   # - Problem: What was the symptom
   # - Root Cause: What actually caused it
   # - Solution: How to fix it
   # - Prevention: How to avoid in future
   ```

2. **Save to auto memory** — write key learnings to your MEMORY.md or topic files

This creates a searchable solution so the same bug is never debugged twice.

### 6.2 Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next
2. **docs/CHANGELOG.md**: If 3+ files changed on branch

### 6.3 Commit and push

```bash
git add -A
git commit -m "fix: [descriptive message based on changes]"
git push -u origin HEAD
```

### 6.4 Create Pull Request

**Ask the user for confirmation before creating the PR:**

> "Branch pushed. Would you like me to create a PR to main?"

**Wait for explicit user confirmation before proceeding.**

```bash
gh pr create --base main --title "[PR title]" --body "[PR description]"
```

**Show the user the PR URL.**

### 6.5 Wait for PR reviews

Wait for automated reviewers (GitHub Copilot, Claude, Codex) and peer developer reviews to arrive on the PR.

### 6.6 Process PR review comments

```
/review-pr-comments
```

Address all review comments, fix issues, and push fixes.

**After fixing review comments, re-run quality gates** (5.1 Code Review Loop, 5.2 Simplify, 5.3 Verify) on the new changes to ensure no regressions were introduced. Repeat until the PR is approved.

### 6.7 Finish the branch (Merge + Cleanup)

Once the PR is approved:

```
/finish-branch
```

This command will:

1. Merge the PR to main (if not already merged)
2. Delete the remote branch
3. Delete the local branch and remove the worktree
4. Restart development servers from main

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

- [ ] Created worktree and cd'd into it (unless already in worktree)
- [ ] Read CONTINUITY.md
- [ ] **Verified plugins loaded** (if "Unknown skill" → STOP, alert user)

**Investigation:**

- [ ] Searched docs/solutions/ for existing fixes
- [ ] Ran `/superpowers:systematic-debugging` OR manual 4-phase analysis (MANDATORY)

**Planning (if complex — iterative loop, repeat until no P0/P1s):**

- [ ] Brainstormed via `/superpowers:brainstorming`
- [ ] Plan written via `/superpowers:writing-plans`
- [ ] **Design reviewed** via `/codex` OR user confirmation (MANDATORY)
- [ ] No P0/P1 issues remaining in review

**Implementation:**

- [ ] Executed fix with TDD (failing test FIRST, then fix)

**Quality Gates (ALL REQUIRED):**

- [ ] Code review loop (Codex + PR Review Toolkit in parallel) — no P0/P1/P2 issues remaining
- [ ] Simplified via `/simplify`
- [ ] Verified via `verify-app` agent (tests, lint, types pass)
- [ ] **E2E tested via Playwright MCP** (MANDATORY if API changed)

**Finish:**

- [ ] **Learning documented** in `docs/solutions/` + auto memory (MANDATORY)
- [ ] CONTINUITY.md updated
- [ ] CHANGELOG.md updated (if 3+ files)
- [ ] Committed, pushed, and PR created
- [ ] PR review comments addressed via `/review-pr-comments`
- [ ] Branch finished via `/finish-branch` (merged, worktree cleaned up)
