# Handoff Command

Create a session handoff document for continuity.

## Instructions

When context is running low or before ending a session, create a handoff summary:

1. **Update CONTINUITY.md** with current state:
   - Move completed items to "Done"
   - Update "Now" with current task status
   - Update "Next" with remaining work

2. **Create handoff summary** with:
   - What was accomplished this session
   - Current state of work in progress
   - Files modified (list the important ones)
   - Any blockers or issues encountered
   - Recommended next steps

3. **Commit changes** (with permission):
   ```bash
   git add CONTINUITY.md
   git commit -m "chore: session handoff - [brief description]"
   ```

## Output Format

```markdown
## Session Handoff - [DATE]

### Accomplished
- [List of completed tasks]

### In Progress
- [Current task and its state]
- Files modified: [list]

### Blockers
- [Any issues preventing progress]

### Next Steps
1. [Immediate next action]
2. [Following action]
3. [...]

### Notes
- [Any important context for next session]
```

## When to Use
- Before `/clear`
- When context usage exceeds 70%
- Before ending a work session
- When switching to a different feature/task
