# Worktree Policy

**`/new-feature` and `/fix-bug` ALWAYS create a worktree** (unless already inside one). This ensures parallel sessions never mix work - even if you're on an unrelated feature branch.

**CRITICAL -- Always check if you are on a git worktree. If you are, never commit to the main folder ALWAYS TO THE WORKTREE**

**`/quick-fix` does NOT create worktrees** - it's for trivial changes only.

When running Superpowers skills (`brainstorming`, `writing-plans`, `executing-plans`), these skills may attempt to create worktrees. **SKIP worktree creation** in these skills - you're already isolated.
