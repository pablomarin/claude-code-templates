# Upgrading an Existing Project

You already have `.claude/settings.json` or `CLAUDE.md` from a previous setup and want to get the latest hooks, commands, rules, and security fixes.

## Recommended: `--upgrade` (safe, preserves your customizations)

```bash
cd /path/to/your/project
~/claude-codex-forge/setup.sh --upgrade
```

### What `--upgrade` does

| File type                    | What happens                                                            |
| ---------------------------- | ----------------------------------------------------------------------- |
| `CLAUDE.md`, `CONTINUITY.md` | **Never touched** — your content is safe                                |
| `.claude/settings.json`      | **Merged** — adds new hooks/permissions/plugins, keeps your custom ones |
| `.mcp.json`                  | **Merged** — adds new MCP servers, keeps your custom ones               |
| `.claude/hooks/*`            | **Updated** — gets latest hook script fixes                             |
| `.claude/rules/*`            | **Updated** — gets latest coding standards                              |
| `.claude/commands/*`         | **Updated** — gets latest workflow commands                             |
| `.claude/agents/*`           | **Updated** — gets latest agent definitions                             |

A timestamped backup (`.bak`) is created before any merge. You'll see a summary of what changed:

```
  ↑ Merging .claude/settings.json (upgrade mode)
  Upgraded settings.json (backup: settings.bak.20260301212339):
    Added hook events: ConfigChange, PreToolUse
    Added permissions.deny: Bash(sudo:*), Bash(su:*)
    Added plugins: pr-review-toolkit@claude-plugins-official
  ↑ Merging .mcp.json (upgrade mode)
  .mcp.json: already up to date
  ✓ Created .claude/hooks/check-bash-safety.sh
  ✓ Created .claude/hooks/check-config-change.sh
```

## Alternative: Fresh install (destructive)

If you want to start completely fresh with the latest templates:

```bash
# 1. Backup your current setup
cp -r .claude .claude-backup
cp CLAUDE.md CLAUDE.md.backup

# 2. Force overwrite everything (except CLAUDE.md and CONTINUITY.md)
~/claude-codex-forge/setup.sh -f

# 3. Merge back any project-specific settings from backup
# Compare: diff .claude-backup/settings.json .claude/settings.json
```

> **When to use `-f` instead of `--upgrade`:** Only if your settings are corrupted, you want a clean slate, or you haven't customized anything yet.
