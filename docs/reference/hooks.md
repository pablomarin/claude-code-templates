# Hooks Reference

Hooks run automatically without manual intervention. Seven hook events configured across global and project scopes.

## Hooks (Run Automatically)

| Hook             | Trigger                                   | What Happens                                                                    | Scope            |
| ---------------- | ----------------------------------------- | ------------------------------------------------------------------------------- | ---------------- |
| `SessionStart`   | New session, resume, `/clear`, compaction | Silently injects current branch via `additionalContext` (no visible clutter)    | Project          |
| `Stop` (global)  | Claude finishes responding                | No-op pass-through (`exit 0`) — memory saving handled by PreCompact             | Global           |
| `Stop` (project) | Claude finishes responding                | Checks CONTINUITY.md + CHANGELOG updated (script only, blocks if needed)        | Project          |
| `PreToolUse`     | Before every Bash command                 | Logs commands to audit log, blocks dangerous patterns (pipe-to-shell, etc.)     | Project          |
| `PostToolUse`    | After Edit/Write on code files            | Auto-formats with ruff (Python) / prettier (JS/TS/JSON/Markdown)                | Project          |
| `PreCompact`     | Before context compression                | Reminds Claude to save learnings before context compression (blocks until done) | Global + Project |
| `SubagentStop`   | Subagent finishes                         | Validates subagent output quality                                               | Project          |
| `ConfigChange`   | Config file modified mid-session          | Logs changes to audit log; optional strict mode blocks deny-rule removals       | Project          |

## How Global and Project Hooks Interact

Global hooks (`~/.claude/settings.json`) and project hooks (`.claude/settings.json`) **both run**. They don't conflict — they complement each other:

- **Global Stop hook**: No-op (`exit 0`) — memory saving handled by PreCompact and CLAUDE.md rules
- **Project Stop hook**: Script checks if CONTINUITY.md + CHANGELOG are updated; only counts tracked modifications, ignores untracked files (blocks via exit code 2 if not updated)
- **Global PreCompact hook**: Command that blocks with memory save reminder (`exit 2` + stderr)
- **Project PreCompact hook**: Command reminder + project-specific context script

## Workflow Gates

Beyond the hooks above, `check-workflow-gates.sh` blocks **commit/push/PR** until the CONTINUITY workflow checklist contains the required markers (`Code review loop`, `Simplified`, `Verified`). This is the real "discipline enforcement" hook — it refuses to let you ship until the quality loop has run.
