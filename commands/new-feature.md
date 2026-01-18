# New Feature Workflow

> **This workflow is MANDATORY. Follow every step in order.**

## Pre-Flight Checks

1. **Verify branch**: You must NOT be on `main`. If on main:
   ```bash
   git checkout -b feat/$ARGUMENTS
   ```

2. **Read project state**:
   ```bash
   cat CONTINUITY.md
   ```

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
/superpowers:brainstorm
```

### 3.2 Write the implementation plan

```
/superpowers:write-plan
```

### 3.3 Enhance the plan with parallel research

```
/deepen-plan
```

---

## Phase 4: Execute

Implement using TDD (Red-Green-Refactor):

```
/superpowers:execute-plan
```

**If you encounter bugs during implementation:**

```
/superpowers:systematic-debugging
```

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

### 6.1 Compound learnings (if any)

If you fixed bugs or discovered patterns:

```
/workflows:compound
```

### 6.2 Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next
2. **docs/CHANGELOG.md**: If 3+ files changed on branch

### 6.3 Complete the branch

```
/superpowers:finishing-a-development-branch
```

---

## Checklist Summary

- [ ] On feature branch (not main)
- [ ] Researched existing solutions and best practices
- [ ] PRD created via `/prd:create`
- [ ] Brainstormed via `/superpowers:brainstorm`
- [ ] Plan written via `/superpowers:write-plan`
- [ ] Plan enhanced via `/deepen-plan`
- [ ] Executed via `/superpowers:execute-plan` (TDD)
- [ ] Code reviewed via `/workflows:review`
- [ ] Simplified via `code-simplifier` agent
- [ ] Verified via `verify-app` agent
- [ ] E2E tested via `/playwright-test` (if UI/API)
- [ ] Learnings compounded via `/workflows:compound` (if any)
- [ ] CONTINUITY.md updated
- [ ] CHANGELOG.md updated (if 3+ files)
- [ ] Branch finished via `/superpowers:finishing-a-development-branch`
