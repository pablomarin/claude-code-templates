# Troubleshooting

Common issues and their solutions.

## Setup script says files already exist

This is expected if you already have Claude Code set up. See [Upgrading](guides/upgrading.md) for options.

## Memory not persisting?

1. **Check auto memory is enabled** (it's on by default):

   ```bash
   # Inside Claude Code, run:
   /memory    # Should show auto-memory toggle
   ```

2. **Check global setup was run:**

   ```bash
   ls ~/.claude/CLAUDE.md
   ls ~/.claude/settings.json
   # Both should exist
   ```

3. **Check auto memory directory exists:**

   ```bash
   ls ~/.claude/projects/
   # Should show project directories
   ```

4. **View memory in Claude Code:**

   ```
   /memory
   # Should show MEMORY.md and CLAUDE.md files
   ```

5. **Tell Claude explicitly:**
   ```
   "Remember that we use pnpm for this project"
   "Save to memory that the database migrations use Alembic"
   ```

## Hooks not running?

### macOS / Linux

1. **Check script is executable:**

   ```bash
   ls -la .claude/hooks/
   # Should show -rwxr-xr-x for all .sh files
   ```

2. **Check settings.json is valid:**

   ```bash
   cat .claude/settings.json | jq .
   # Should parse without errors
   ```

3. **Check jq is installed (recommended):**

   ```bash
   which jq
   # Should output path like /usr/bin/jq
   # Note: hooks will work without jq but some features are reduced
   ```

4. **Restart Claude Code** — Hooks snapshot at session start

### Windows

1. **Check PowerShell execution policy:**

   ```powershell
   Get-ExecutionPolicy
   # If "Restricted", run:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Check hook scripts exist:**

   ```powershell
   Test-Path .claude\hooks\session-start.ps1
   Test-Path .claude\hooks\check-state-updated.ps1
   Test-Path .claude\hooks\post-tool-format.ps1
   Test-Path .claude\hooks\pre-compact-memory.ps1
   # All should return True
   ```

3. **Test hook script manually:**

   ```powershell
   echo '{"stop_hook_active": false}' | powershell -File .claude\hooks\check-state-updated.ps1
   # Should run without errors
   ```

4. **Check settings.json is valid:**

   ```powershell
   Get-Content .claude\settings.json | ConvertFrom-Json
   # Should parse without errors
   ```

5. **Restart Claude Code** — Hooks snapshot at session start

## Drift detection messages — what they mean

The SessionStart hook and `/new-feature` / `/fix-bug` Pre-Flight surface a few advisory messages tied to default-branch detection. None of them block (with one exception noted below); they're diagnostic hints.

### `default-branch helper bailed; assuming 'main'`

The helper at `.claude/hooks/lib/default-branch.{sh,ps1}` couldn't detect the default branch from cached refs. This is a fallback to `main` — wrong on `master`-default repos. Causes:

- The repo has no `origin` remote AND neither `main` nor `master` exists locally.
- The repo was cloned with `--no-checkout` and no branches have been created yet.

**Fix:** ensure your repo has a real default branch checked out. If you just cloned, run `git checkout main` (or `master`).

### `Parent '<branch>' is N commits behind origin`

Drift warning — your local default branch is behind the remote. Run `git pull` to update it. New worktrees are still based from `origin/<default>` automatically; this warning just nudges you to catch up your main checkout when you next switch back.

### `Could not resolve any default-branch ref; basing worktree on HEAD`

Last-resort fallback inside `/new-feature` / `/fix-bug`. The new worktree was based on whatever you currently have checked out — possibly a feature branch, a tag, or a detached HEAD. Verify this is what you wanted; if not, delete the worktree (`git worktree remove .worktrees/<name>`) and re-run with the right base checked out.

### Drift warnings show the wrong default branch (e.g., `master` after a remote rename)

Detection uses the locally cached `origin/HEAD` symbolic ref, which is set at clone time and **not refreshed by `git fetch`** even after the upstream renames its default branch. Symptom: helper returns `master` after the remote was renamed `master → main`, and drift checks compare against the retired branch.

**Fix:**

```bash
git remote set-head origin --auto
git fetch --prune
```

This refreshes `refs/remotes/origin/HEAD` to the current upstream default and prunes the dead remote-tracking branch. After running, the helper returns the correct name on next invocation.

## Permissions still prompting?

1. **Verify settings.json syntax:**

   ```bash
   cat .claude/settings.json | jq '.permissions'
   ```

2. **Check permission patterns:**
   - `Bash(uv:*)` matches `uv run pytest`
   - `Bash(uv run pytest)` only matches exact command
   - Use `:*` suffix for wildcards

3. **Restart Claude Code** after changing settings

## MCP servers not showing up in /mcp?

**`mcpServers` in `.claude/settings.json` is silently ignored.** This is a [known issue](https://github.com/anthropics/claude-code/issues/24477) — no error, no warning, they just don't load.

MCP servers must be in one of these files:

| File                       | Scope    | Shareable via git? |
| -------------------------- | -------- | ------------------ |
| `.mcp.json` (project root) | Project  | Yes                |
| `~/.claude.json`           | Personal | No                 |

The setup script creates `.mcp.json` at the project root. If you don't see servers:

1. **Check `.mcp.json` exists at project root** (not inside `.claude/`):

   ```bash
   cat .mcp.json
   ```

2. **If missing, re-run setup or create it manually:**

   ```json
   {
     "mcpServers": {
       "playwright": {
         "type": "stdio",
         "command": "npx",
         "args": ["-y", "@playwright/mcp@latest"],
         "env": {}
       },
       "context7": {
         "type": "http",
         "url": "https://mcp.context7.com/mcp"
       }
     }
   }
   ```

3. **Or use the CLI:**

   ```bash
   claude mcp add --transport stdio --scope project playwright -- npx -y @playwright/mcp@latest
   claude mcp add --transport http --scope project context7 https://mcp.context7.com/mcp
   ```

4. **Restart Claude Code** — MCP servers are loaded at session start.

## MCP servers still prompting for permission?

MCP permissions **do not support wildcards**. The pattern `mcp__*` does nothing.

Permissions go in `.claude/settings.json` (separate from MCP server definitions):

```json
// Wrong - wildcards don't work
"mcp__*"
"mcp__context7__*"

// Correct - use server name without wildcard
"mcp__context7"
"mcp__playwright"
```

The server name (without `__*`) approves ALL tools from that MCP server.

See: [GitHub Issue #3107](https://github.com/anthropics/claude-code/issues/3107)

## Plugins not showing in /help?

1. **Verify plugin installed:**

   ```
   /plugin list
   ```

2. **Verify plugin is ENABLED** in `~/.claude/settings.json`:

   ```json
   {
     "enabledPlugins": {
       "superpowers@superpowers-marketplace": true,
       "pr-review-toolkit@claude-plugins-official": true,
       "frontend-design@claude-plugins-official": true
     }
   }
   ```

3. **Restart Claude Code** after enabling plugins

4. **Try reinstalling:**
   ```
   /plugin uninstall superpowers@superpowers-marketplace
   /plugin install superpowers@superpowers-marketplace
   ```

## Codex CLI not working?

1. **Check it's installed:**

   ```bash
   codex --version
   # Should show 0.101.0 or higher
   ```

2. **Check authentication:**

   ```bash
   codex    # Should not prompt for login
   ```

3. **"command not found" on macOS:**

   ```bash
   # If installed via npm, check Node.js version
   node --version   # Must be 22+

   # If installed via Homebrew
   brew reinstall --cask codex
   ```

4. **Windows — "command not found" in WSL:**

   ```bash
   # Make sure you installed inside WSL, not Windows
   npm install -g @openai/codex
   ```

5. **Authentication from headless/remote environments:**

   ```bash
   codex login --device-auth
   # Gives a URL + code to enter on any browser
   ```

6. **Don't have a ChatGPT Plus/Pro/Business plan?**
   Use an API key instead:
   ```bash
   codex login --with-api-key
   ```

> **If Codex is unavailable**, the workflow still works — Claude will present designs to you for manual review. But Codex is faster and provides an independent perspective.

## /simplify not working?

`/simplify` is a built-in Claude Code command (v2.1.63+). If unavailable, update Claude Code or use the `code-simplifier` agent from `pr-review-toolkit` as a fallback.
