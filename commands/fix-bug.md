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

1. **Verify branch**: You must NOT be on `main`. If on main:
   ```bash
   git checkout -b fix/$ARGUMENTS
   ```

2. **Read project state**:
   ```bash
   cat CONTINUITY.md
   ```

3. **Verify required plugins are available** (test ONE skill):
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
- prompt: "Run verification on current changes and report pass/fail verdict."
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
