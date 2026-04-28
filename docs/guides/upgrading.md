# Upgrading an Existing Project

You already have `.claude/settings.json` or `CLAUDE.md` from a previous setup and want to get the latest hooks, commands, rules, and security fixes.

## Recommended: `--upgrade` (safe, preserves your customizations)

```bash
cd /path/to/your/project
~/claude-codex-forge/setup.sh --upgrade
```

### What `--upgrade` does

| File type                                         | What happens                                                               |
| ------------------------------------------------- | -------------------------------------------------------------------------- |
| `CLAUDE.md`                                       | **Never touched** — your content is safe                                   |
| `.claude/local/state.md`                          | **Never touched** — gitignored per-developer state                         |
| Legacy `CONTINUITY.md` (if present from pre-5.15) | **Never touched** — preserved for `--migrate`; see migration section below |
| `.claude/settings.json`                           | **Merged** — adds new hooks/permissions/plugins, keeps your custom ones    |
| `.mcp.json`                                       | **Merged** — adds new MCP servers, keeps your custom ones                  |
| `.claude/hooks/*`                                 | **Updated** — gets latest hook script fixes                                |
| `.claude/rules/*`                                 | **Updated** — gets latest coding standards                                 |
| `.claude/commands/*`                              | **Updated** — gets latest workflow commands                                |
| `.claude/agents/*`                                | **Updated** — gets latest agent definitions                                |

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

# 2. Force overwrite everything (except CLAUDE.md, .claude/local/state.md, and any legacy CONTINUITY.md)
~/claude-codex-forge/setup.sh -f

# 3. Merge back any project-specific settings from backup
# Compare: diff .claude-backup/settings.json .claude/settings.json
```

> **When to use `-f` instead of `--upgrade`:** Only if your settings are corrupted, you want a clean slate, or you haven't customized anything yet.

## Migrating from CONTINUITY.md (5.14 → 5.15)

Forge 5.15 splits the legacy single-file `CONTINUITY.md` into three artifacts with appropriate ownership:

| Genre                                              | New home                              | Tracked in git?        |
| -------------------------------------------------- | ------------------------------------- | ---------------------- |
| Project goal + tech stack + key commands (durable) | `CLAUDE.md`                           | Yes                    |
| Architecture decisions (append-only history)       | `docs/adr/NNNN-*.md`                  | Yes                    |
| Workflow checklist + Done/Now/Next (volatile)      | `.claude/local/state.md`              | **No** (gitignored)    |
| Original `CONTINUITY.md` (your existing file)      | Preserved at the repo root, untouched | Yes (until you delete) |

The rationale is recorded in [`docs/adr/0001-volatile-state-not-auto-loaded.md`](../adr/0001-volatile-state-not-auto-loaded.md): keeping volatile per-developer state out of Claude Code's auto-loaded path means stale status from yesterday's session never silently re-enters today's context.

### How to migrate

After running `setup.sh --upgrade` (or `-f`), you'll have the new files installed alongside any legacy `CONTINUITY.md`. To migrate the content:

```bash
cd /path/to/your/project
~/claude-codex-forge/setup.sh --migrate
```

The migration assistant is **deterministic, idempotent, and non-destructive**:

- Extracts the `## Goal` section into `CLAUDE.md` under the `## Project Overview` → `### Goal` subsection (only if `CLAUDE.md` doesn't already have a populated Goal).
- Extracts each row of the `## Key Decisions` table into a new `docs/adr/NNNN-*.md` file, auto-numbered after the seed ADRs (0001–0005). Existing ADRs are not overwritten.
- Extracts `### Done` (trimmed to the most recent 2–3 entries), `### Now`, `### Next`, `## Open Questions`, and `## Blockers` into `.claude/local/state.md`. If `state.md` already has content, the migrate command preserves it and re-runs are no-ops.
- The original `CONTINUITY.md` is **preserved byte-for-byte**. The script never modifies or deletes it. Once you've reviewed the migrated outputs, you can delete the legacy file yourself.
- A sentinel marker is written into each migrated destination so re-running `--migrate` is safe — the assistant detects already-migrated content and skips it.

If your `CLAUDE.md` still contains a `@CONTINUITY.md` import line (the pre-5.15 default), the migration assistant **flags it and prints a prompt you can paste into Claude Code**. The prompt asks Claude to reconcile your `CLAUDE.md` against the latest `CLAUDE.template.md` (porting any new template sections you're missing while preserving project-specific content) AND to remove the dangling `@CONTINUITY.md` line in the same operation. Claude Code's `@`-imports fail silently when the target is missing, so the dangling import won't crash anything — but it's clutter that's worth a one-shot reconcile pass.

### Verifying the migration

```bash
# Goal moved into CLAUDE.md
grep -A1 "^### Goal" CLAUDE.md

# Decisions promoted to per-file ADRs
ls docs/adr/

# Volatile state in the gitignored path
cat .claude/local/state.md

# Legacy file preserved
ls -la CONTINUITY.md
```

If any of those four checks fails, see the [troubleshooting guide](../troubleshooting.md#migration-and-the-volatile-state-file) for recovery steps.

### Manual fallback (no Claude Code at hand)

If you're upgrading over SSH, in a CI pipeline, or in any context where you can't paste prompts into Claude Code, the migration's "ask Claude to reconcile" recommendation can be done manually:

```bash
# Remove the dangling @CONTINUITY.md import
sed -i.bak '/^@CONTINUITY\.md$/d' CLAUDE.md && rm CLAUDE.md.bak

# Diff your CLAUDE.md against the latest template
git diff --no-index -- ~/Code/claude-codex-forge/CLAUDE.template.md CLAUDE.md

# Manually merge any template sections you want, preserving project-specific content
```

(Substitute your actual Forge clone path if different.)

The Claude-mediated path is recommended because Claude can judge what counts as "project-specific" vs "stale template scaffolding"; the manual diff requires you to make those calls yourself.
