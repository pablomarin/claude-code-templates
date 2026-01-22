# Finish Branch Workflow

> **Use this command to complete a feature or fix branch.**
> This command handles PR creation and worktree cleanup.

---

## When to Use

- After all quality gates pass (review, tests, lint, types)
- After CONTINUITY.md and CHANGELOG.md are updated
- When you're ready to create a PR or merge to main

**Note:** This command is called automatically at the end of `/new-feature` and `/fix-bug` workflows.

---

## Phase 1: Commit and Push

### 1.1 Check for uncommitted changes

```bash
git status --porcelain
```

**If there are uncommitted changes:**

```bash
git add -A
git commit -m "feat: [descriptive message based on changes]"
```

### 1.2 Push to remote

```bash
git push -u origin HEAD
```

---

## Phase 2: Create Pull Request

### 2.1 Ask user for confirmation

**Ask the user:**
> "Branch pushed. Would you like me to create a PR to main?"

**Wait for explicit user confirmation before proceeding.**

### 2.2 Create PR (if user confirms)

```bash
gh pr create --base main --fill
```

Or with more details:
```bash
gh pr create --base main --title "[PR title]" --body "[PR description]"
```

**Show the user the PR URL.**

---

## Phase 3: Wait for Merge

**Tell the user:**
> "PR created: [URL]
>
> After the PR is reviewed and merged, tell me to clean up the worktree by saying 'clean up' or running `/finish-branch` again."

**STOP HERE.** Do not proceed to cleanup until the user confirms the PR has been merged.

---

## Phase 4: Cleanup (After Merge)

**Only proceed when user confirms the PR has been merged.**

### 4.1 Detect current context

```bash
# Check if we're in a worktree
if [[ "$(pwd)" == *".worktrees/"* ]]; then
  echo "STATE: IN_WORKTREE"
  # Extract worktree name from path
  WORKTREE_NAME=$(basename "$(pwd)")
  echo "WORKTREE_NAME: $WORKTREE_NAME"
else
  echo "STATE: NOT_IN_WORKTREE"
fi
```

### 4.2 Get branch name

```bash
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
echo "BRANCH_NAME: $BRANCH_NAME"
```

### 4.3 Navigate to main repository

```bash
# Go back to main repo root (works from inside worktree)
cd "$(git rev-parse --git-common-dir)/.."
echo "Now in: $(pwd)"
```

### 4.4 Remove the worktree

```bash
git worktree remove ".worktrees/$WORKTREE_NAME" --force
echo "✓ Removed worktree: .worktrees/$WORKTREE_NAME"
```

### 4.5 Delete local branch

```bash
git branch -d "$BRANCH_NAME"
echo "✓ Deleted local branch: $BRANCH_NAME"
```

**If branch not fully merged (force delete with user confirmation):**
```bash
git branch -D "$BRANCH_NAME"
```

### 4.6 Delete remote branch

```bash
git push origin --delete "$BRANCH_NAME"
echo "✓ Deleted remote branch: $BRANCH_NAME"
```

**Note:** This may fail if GitHub auto-deleted the branch on merge. That's fine.

### 4.7 Prune stale references

```bash
git worktree prune
git fetch --prune
echo "✓ Pruned stale references"
```

### 4.8 Switch to main and pull

```bash
git checkout main
git pull
echo "✓ Updated main branch"
```

---

### 4.9 Restart servers in main directory (if needed)

> ⚠️ **If you restarted servers in the worktree for E2E testing**, they are now stopped or pointing to a deleted directory.

Start the development servers from the main directory. Use the project's start commands from CLAUDE.md.

---

## Cleanup Summary

After successful cleanup, report to user:

```
✓ Cleanup complete:
  - Removed worktree: .worktrees/[name]
  - Deleted local branch: [branch]
  - Deleted remote branch: [branch]
  - Pruned stale references
  - Now on main branch (up to date)
  - Development servers restarted from main
```

---

## If NOT in a Worktree

If the user is not in a worktree (e.g., working directly on a feature branch):

1. **Skip worktree removal** (steps 4.3, 4.4)
2. **Still delete branches** (steps 4.5, 4.6)
3. **Still prune and update main** (steps 4.7, 4.8)

---

## Error Handling

### PR creation fails
- Check if `gh` CLI is authenticated: `gh auth status`
- Check if remote is set: `git remote -v`

### Worktree removal fails
- Check if worktree has uncommitted changes
- Use `--force` flag if changes are already in the merged PR

### Branch deletion fails
- If "not fully merged": The PR might not be merged yet. Confirm with user.
- If "remote ref does not exist": GitHub may have auto-deleted on merge. This is fine.

---

## Checklist Summary

- [ ] Changes committed and pushed
- [ ] PR created (with user confirmation)
- [ ] User confirmed PR is merged
- [ ] Worktree removed (if applicable)
- [ ] Local branch deleted
- [ ] Remote branch deleted
- [ ] Stale references pruned
- [ ] Now on main branch
