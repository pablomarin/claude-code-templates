# Quick Fix Workflow

> **For trivial changes only.** If in doubt, use `/new-feature` or `/fix-bug` instead.

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
- **User-facing behavior changed** — UI, API response, CLI output, navigation, permissions. Quick-fix skips E2E verification; any user-facing change requires the `verify-e2e` agent via `/fix-bug`. Trivial = no behavior change (typos, comments, dead code removal, internal refactors that preserve behavior).

---

## Pre-Flight Check

1. **Verify branch**: You must NOT be on `main`. If on main:
   ```bash
   git checkout -b "fix/$ARGUMENTS"
   ```

---

## Research Check

Quick fixes skip the full research-first agent. However, if this change touches an external dependency or API (version bump, API call change, new library import):

- Check the library's current docs via Context7 or WebSearch before implementing
- Verify no breaking changes between your version and the one you're targeting

If purely internal (typo fix, config change, style cleanup): no research needed.

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
- subagent_type: "verify-app"
- prompt: "Run verification on current changes and report pass/fail verdict."
```

> **Note:** Quick-fix doesn't create worktrees. For parallel development, use `/new-feature` or `/fix-bug` instead.

**Only use fallback if Task tool fails:**

```bash
pytest && ruff check . && mypy .  # Python
npm test && npm run lint && npm run typecheck  # Node
```

---

## Finish

### Update state files

1. **.claude/local/state.md**: Update Done (keep 2-3 recent), Now, Next

### Commit the changes

```bash
git add -A
git commit -m "fix: [descriptive message]"
```

**Note:** Quick fixes are typically committed directly to the current branch. Since quick-fix doesn't create worktrees or feature branches, there's no PR/merge workflow - just commit and you're done.

**If you want to create a PR instead** (e.g., for review):

```bash
git push -u origin HEAD
gh pr create --base main --fill
```

---

## Checklist Summary

- [ ] On fix branch (not main)
- [ ] Change is truly trivial (< 3 files, no arch impact)
- [ ] Change verified manually or with tests
- [ ] Verified via `verify-app` agent
- [ ] .claude/local/state.md updated
- [ ] Changes committed

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
