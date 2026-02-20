# Workflow

**Use workflow commands.** They contain the full process - follow them exactly.

## Decision Matrix

| Scenario | Action |
|----------|--------|
| Starting new feature | Run `/new-feature <name>` (creates worktree) |
| Fixing a bug | Run `/fix-bug <name>` (creates worktree) |
| Trivial change (< 3 files) | Run `/quick-fix <name>` (no worktree) |
| Want a second opinion | Run `/codex <instruction>` (code review or general) |
| Creating PR to main | **Ask** |
| Merging PR to main | **Ask** |
| Skipping tests | **Never** |
