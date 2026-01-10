# CONTINUITY

## Goal
[PROJECT GOAL - Fill in per project]
Example: Build MCP Gateway MVP - Enterprise MCP server management platform

## Constraints/Assumptions
[PROJECT CONSTRAINTS - Fill in per project]
Example:
- Tech: Python 3.12+, FastAPI, Next.js 15, PostgreSQL
- Timeline: Phase 1 MVP first
- Workflow: Superpowers (design/execute) + Compound Engineering (review)

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision 1] | [Choice] | [Why] |
| [Decision 2] | [Choice] | [Why] |

## State

### Done
- Initial project setup (YYYY-MM-DD)
- Claude Code configuration

### Now
Ready for first task - describe current focus here

### Next
- [Priority 1]
- [Priority 2]
- [Priority 3]

## Active Artifacts
- **Design:** `docs/plans/`
- **PRDs:** `docs/prds/`
- **Branch:** main

## Working Set
[List active directories and files relevant to current work]

## Test Status
- Backend: [X tests passing]
- Frontend: [X tests passing]
- Types: [passing/failing]
- Lint: [passing/failing]

## Open Questions
- [Question 1]
- [Question 2]

## Deferred to Later
- [Item 1]
- [Item 2]

---

## Update Protocol

> **IMPORTANT:** You (Claude) are responsible for updating this file. The Stop hook will remind you, but YOU must make the edits.

### When to Update This File

| Trigger | Action |
|---------|--------|
| Task completed | Move item from Now → Done |
| Starting new task | Update Now section |
| Planning future work | Update Next section |
| Session ending | Ensure Done/Now/Next reflects reality |
| Context compaction | Update before `/compact` |

### When to Update docs/CHANGELOG.md

| Trigger | What to Add |
|---------|-------------|
| Feature completed | Full entry with description |
| Bug fixed | Entry in Bug Fixes section |
| Significant refactor | Entry with rationale |
| Multiple small changes | Grouped entry |

### Quick Update Template

When finishing work, update this section:

```markdown
### Done
- [Previous items...]
- [NEW] What you just completed (YYYY-MM-DD)

### Now
What's the current focus (or "Ready for next task")

### Next
- Upcoming priorities
```

---

## Session Recovery

On context compaction or new session:

1. ✅ SessionStart hook auto-loads this file
2. Read the Goal and State sections
3. Check `docs/plans/` for active plans
4. Check `docs/prds/` for current PRDs
5. Check CLAUDE.md "Compound Engineering" section for learnings
6. Resume with current task or start new feature with `/prd:discuss`

**First message pattern:**
> "I've loaded the project state. You're at [Now]. Last completed: [most recent Done item]. Ready to continue with [Now] or would you like to start something else?"
