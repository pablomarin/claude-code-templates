# Workflow

**Use workflow commands.** They contain the full process - follow them exactly.

## Decision Matrix

| Scenario                   | Action                                              |
| -------------------------- | --------------------------------------------------- |
| Starting new feature       | Run `/new-feature <name>` (creates worktree)        |
| Fixing a bug               | Run `/fix-bug <name>` (creates worktree)            |
| Trivial change (< 3 files) | Run `/quick-fix <name>` (no worktree)               |
| Want a second opinion      | Run `/codex <instruction>` (code review or general) |
| Creating PR to main        | **Ask**                                             |
| Merging PR to main         | **Ask**                                             |
| Skipping tests             | **Never**                                           |

## Workflow Tracking

**When a workflow is active** (`## Workflow` in CONTINUITY.md has Command != `none`):

1. **Before each action**: Read `## Workflow` in CONTINUITY.md — check current Phase and Next step
2. **Execute only** the `Next step` listed
3. **After completing a step**: Check the box in the Checklist and advance `Next step` to the next unchecked item
4. **On phase transition**: Update the `Phase` field

The Stop hook reminds you of the current phase on every response. The PreToolUse hook blocks commit/push/PR if quality gates are incomplete. This rule is re-injected every turn — it survives context compaction.
