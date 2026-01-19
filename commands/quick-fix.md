# Quick Fix Workflow

> **For trivial changes only.** If in doubt, use `/new-feature` or `/fix-bug` instead.
> **If any required command/skill fails with "Unknown skill", STOP and alert the user.**

## Required Plugins

This workflow requires the following plugins to be **installed AND enabled**:

| Plugin | Skills/Commands Used |
|--------|---------------------|
| `superpowers@superpowers-marketplace` | `/superpowers:finishing-a-development-branch` |

**To enable plugins**, add to `~/.claude/settings.json`:
```json
{
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true
  }
}
```

---

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

### Verify (USE SUBAGENT - saves context window)

**MUST use the verify-app subagent** - Do NOT run tests yourself.

Using a subagent keeps test output out of your context window, preserving tokens for actual work.

**Invoke the subagent:**
```
Use the Task tool with:
- subagent_type: "general-purpose"
- prompt: "You are the verify-app agent. Run ALL verification: unit tests, migrations, lint, types. Read .claude/agents/verify-app.md for instructions. Report pass/fail verdict."
```

**Only use fallback if Task tool fails:**
```bash
pytest && ruff check . && mypy .  # Python
npm test && npm run lint && npm run typecheck  # Node
```

---

## Finish

### Update state files

1. **CONTINUITY.md**: Update Done (keep 2-3 recent), Now, Next

### Complete the branch

```
/superpowers:finishing-a-development-branch
```

**Fallback if unavailable:** Complete manually:
1. Run final verification (tests, lint, types)
2. Stage and commit changes with descriptive message
3. Push branch to remote
4. Create PR if ready for review

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
