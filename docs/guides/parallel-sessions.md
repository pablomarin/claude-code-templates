# Parallel Development (Multiple Sessions)

Run multiple Claude Code sessions simultaneously on the same project — each working on a different feature without conflicts.

> **Working across multiple projects with different Python/Node versions?** Worktree isolation only covers one project. For per-project interpreter isolation see [Multi-Project Isolation](multi-project-isolation.md).

## How It Works

When you run `/new-feature` or `/fix-bug` from the `main` branch, the workflow automatically:

1. **Creates an isolated worktree** at `.worktrees/<feature-name>/`
2. **Copies environment files** (`.env*`) to the worktree
3. **Installs dependencies** (Node.js/Python)
4. **cd's into the worktree** — all subsequent commands run there

Each session works in its own isolated directory with its own branch. No conflicts, no shared state files.

## Example: 3 Parallel Sessions

```bash
# Terminal 1
cd /project && claude
> /new-feature auth        # Creates .worktrees/auth/, cd's into it

# Terminal 2
cd /project && claude
> /new-feature api         # Creates .worktrees/api/, cd's into it

# Terminal 3
cd /project && claude
> /fix-bug login-error     # Creates .worktrees/login-error/, cd's into it
```

## Critical: Always Run Claude from Project Root

> **WARNING**: Always start `claude` from the **main project directory**, NOT from inside a worktree.

```bash
# Correct - run from project root
cd /project && claude
> /new-feature auth

# Wrong - don't cd into worktree then run claude
cd /project/.worktrees/auth && claude  # Hooks won't work!
```

**Why?** The `.claude/` folder (with hooks, settings, agents) lives in the main repo. Running Claude from inside a worktree means it won't find these configurations.

## Important Notes

- **Worktrees are created automatically** when starting from `main`
- **No nested worktrees** — if already in a worktree or feature branch, the workflow uses the current directory
- **Hooks run in current directory** — after Claude cd's into a worktree, hooks check files there
- **File paths are relative** — use `src/main.py`, not `.worktrees/auth/src/main.py`
- **`.worktrees/` is gitignored** automatically
- **Dependencies are installed** automatically
- **Quick-fix does NOT create worktrees** — use `/new-feature` or `/fix-bug` for parallel work
- **Cleanup is safe** — each session is fully isolated, no shared state between sessions
- **Memory is per-worktree** — git worktrees get separate auto memory directories, so each session tracks its own learnings independently

## Cleanup

The `/finish-branch` command handles merge and cleanup (with user confirmation). It will:

1. Merge the PR to main (if not already merged) via `gh pr merge --squash --delete-branch`
2. Delete the remote branch
3. Delete the local branch and remove the worktree
4. Prune stale references
5. Switch to main and pull latest
6. Restart development servers from main

**Note:** `/finish-branch` does NOT commit, push, or create PRs — those steps happen before calling this command.

**Manual cleanup** (if needed):

```bash
# Go back to main repo (from inside worktree)
cd "$(git rev-parse --git-common-dir)/.."

# Remove a specific worktree (after merging its branch)
git worktree remove ".worktrees/auth"

# Clean up stale worktree metadata
git worktree prune

# Delete the merged branch
git branch -d feat/auth
git push origin --delete feat/auth
```

**Tip:** Use `/finish-branch` to automate cleanup and avoid forgetting steps.
