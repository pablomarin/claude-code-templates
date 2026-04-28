# Setup Scenarios

Common project configurations. All assume you have already completed [global setup](../getting-started.md#step-2-global-setup-once-per-machine).

## Scenario A: New Project

Starting a brand new project with no existing files.

**macOS / Linux:**

```bash
# 1. Create and enter your project
mkdir my-new-project
cd my-new-project
git init

# 2. Run setup
~/claude-codex-forge/setup.sh -p "My New Project"

# 3. Start Claude Code and install plugin
claude
```

**Windows (PowerShell):**

```powershell
# 1. Create and enter your project
mkdir my-new-project
cd my-new-project
git init

# 2. Run setup
& $HOME\claude-codex-forge\setup.ps1 -p "My New Project"

# 3. Start Claude Code and install plugin
claude
```

Then install the Superpowers plugin (if not already done — see [getting-started Step 4](../getting-started.md#step-4-install-the-superpowers-plugin-once-per-machine)). Restart Claude Code.

> Plugins are pre-configured in `.claude/settings.json`. You only need to install Superpowers once per machine.

**Done!** Now [customize your project](customize-project.md).

---

## Scenario B: Existing Project WITHOUT Claude Code

You have a project but haven't set up Claude Code automation yet.

**macOS / Linux:**

```bash
# 1. Go to your project
cd /path/to/your/existing/project

# 2. Run setup
~/claude-codex-forge/setup.sh -p "My Project Name"

# 3. Start Claude Code
claude
```

**Windows (PowerShell):**

```powershell
# 1. Go to your project
cd C:\path\to\your\existing\project

# 2. Run setup
& $HOME\claude-codex-forge\setup.ps1 -p "My Project Name"

# 3. Start Claude Code
claude
```

Install the Superpowers plugin if not already done (see [getting-started Step 4](../getting-started.md#step-4-install-the-superpowers-plugin-once-per-machine)). Restart Claude Code.

```bash
# 4. Commit the new files
git add .claude/ .mcp.json CLAUDE.md docs/ .gitignore
git commit -m "chore: add Claude Code automation setup"
git push
```

**Done!** Now [customize your project](customize-project.md).

---

## Scenario C: Existing Project WITH Claude Code (Upgrade)

See [Upgrading](upgrading.md) — dedicated guide for upgrading existing setups.

---

## Optional: Add Playwright CI Bridge

For fullstack / typescript projects, append `--with-playwright` to either Scenario A or B. See [Playwright CI Bridge](playwright-ci-bridge.md) for details.
