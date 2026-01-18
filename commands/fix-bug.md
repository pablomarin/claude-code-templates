# Bug Fix Workflow

> **This workflow is MANDATORY. Follow every step in order.**

## Pre-Flight Checks

1. **Verify branch**: You must NOT be on `main`. If on main:
   ```bash
   git checkout -b fix/$ARGUMENTS
   ```

2. **Read project state**:
   ```bash
   cat CONTINUITY.md
   ```

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

This will:
1. **Reproduce** - Confirm the bug exists
2. **Isolate** - Narrow down the cause
3. **Identify** - Find the root cause
4. **Verify** - Confirm understanding before fixing

---

## Phase 3: Plan the Fix

### For simple fixes (1-2 files):
Proceed directly to Phase 4.

### For complex fixes (3+ files or architectural):

#### 3.1 Brainstorm approaches

```
/superpowers:brainstorm
```

#### 3.2 Write the fix plan

```
/superpowers:write-plan
```

---

## Phase 4: Execute the Fix

Implement using TDD (Red-Green-Refactor):

```
/superpowers:execute-plan
```

Or for simple fixes, write a failing test first, then fix.

---

## Phase 5: Quality Gates (ALL REQUIRED)

### 5.1 Code Review (14 specialized agents)

```
/workflows:review
```

Fix ALL issues found before proceeding.

### 5.2 Simplify

Use the code-simplifier agent on all modified files:

```
"Use the code-simplifier agent on [list modified files]"
```

### 5.3 Verify

Run verification (unit tests, migrations, lint, types):

```
"Use the verify-app agent"
```

### 5.4 E2E Tests (if UI/API changed)

```
/playwright-test
```

---

## Phase 6: Finish

### 6.1 Compound the learning (MANDATORY for bug fixes)

Every bug fix teaches something. Capture it:

```
/workflows:compound
```

This creates a searchable solution in `docs/solutions/` so the same bug is never debugged twice.

### 6.2 Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next
2. **docs/CHANGELOG.md**: If 3+ files changed on branch

### 6.3 Complete the branch

```
/superpowers:finishing-a-development-branch
```

---

## Checklist Summary

- [ ] On fix branch (not main)
- [ ] Searched docs/solutions/ for existing fixes
- [ ] Ran `/superpowers:systematic-debugging` (4-phase analysis)
- [ ] Brainstormed via `/superpowers:brainstorm` (if complex)
- [ ] Plan written via `/superpowers:write-plan` (if complex)
- [ ] Executed fix with TDD
- [ ] Code reviewed via `/workflows:review`
- [ ] Simplified via `code-simplifier` agent
- [ ] Verified via `verify-app` agent
- [ ] E2E tested via `/playwright-test` (if UI/API)
- [ ] **Learning compounded via `/workflows:compound`** (MANDATORY)
- [ ] CONTINUITY.md updated
- [ ] CHANGELOG.md updated (if 3+ files)
- [ ] Branch finished via `/superpowers:finishing-a-development-branch`
