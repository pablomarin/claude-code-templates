# Quick Fix Workflow

> **For trivial changes only.** If in doubt, use `/new-feature` or `/fix-bug` instead.

## When to Use This

- Typo fixes
- Comment updates
- Single-line bug fixes with obvious cause
- Config tweaks
- Documentation-only changes
- Changes touching **fewer than 3 files**
- **No architectural impact**

**If ANY of these apply, use the full workflow instead:**
- You're not 100% sure of the fix
- Multiple files need changes
- The fix involves business logic
- Tests need to be added/modified
- Database/API changes involved

---

## Pre-Flight Check

1. **Verify branch**: You must NOT be on `main`. If on main:
   ```bash
   git checkout -b fix/$ARGUMENTS
   ```

---

## The Fix

1. Make the change
2. Verify it works (run relevant tests or check manually)

---

## Quality Gates (STILL REQUIRED)

### Verify

Run verification (unit tests, lint, types):

```
"Use the verify-app agent"
```

---

## Finish

### Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next

### Complete the branch

```
/superpowers:finishing-a-development-branch
```

---

## Checklist Summary

- [ ] On fix branch (not main)
- [ ] Change is truly trivial (< 3 files, no arch impact)
- [ ] Change verified manually or with tests
- [ ] Verified via `verify-app` agent
- [ ] CONTINUITY.md updated
- [ ] Branch finished via `/superpowers:finishing-a-development-branch`

---

## Escalation

If during the fix you discover:
- The change is more complex than expected
- Tests are failing unexpectedly
- You need to touch more files

**STOP and switch to the full workflow:**

```
/fix-bug
```
