# Claude Code Automation Setup

**Company-wide setup guide for Claude Code with Superpowers + Compound Engineering workflow.**

Based on Boris Cherny's (Claude Code creator) workflow and Anthropic's official best practices.

**Repository:** https://github.com/pablomarin/claude-code-templates

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [One-Time Setup (Per Machine)](#one-time-setup-per-machine)
3. [Setup Scenarios](#setup-scenarios)
   - [Scenario A: New Project](#scenario-a-new-project)
   - [Scenario B: Existing Project WITHOUT Claude Code](#scenario-b-existing-project-without-claude-code)
   - [Scenario C: Existing Project WITH Claude Code](#scenario-c-existing-project-with-claude-code)
4. [After Setup: Customize Your Project](#after-setup-customize-your-project)
5. [Workflow Overview](#workflow-overview)
6. [Commands Reference](#commands-reference)
7. [What's Automated](#whats-automated)
8. [File Structure](#file-structure)
9. [Troubleshooting](#troubleshooting)
10. [Security](#security)

---

## Prerequisites

Before starting, ensure you have:

### macOS / Linux
- [ ] **Claude Code** installed and working (`claude --version`)
- [ ] **jq** installed (required for hooks): `brew install jq` (macOS) or `apt install jq` (Linux)
- [ ] **Node.js 18+** (for npx commands)
- [ ] **Git** initialized in your project
- [ ] **Python 3.12+** with `uv` (if Python project)
- [ ] **pnpm** or **npm** (if JavaScript/TypeScript project)

### Windows
- [ ] **Claude Code** installed and working (`claude --version`)
- [ ] **PowerShell 5.1+** (included with Windows 10/11)
- [ ] **Node.js 18+** (for npx commands)
- [ ] **Git** initialized in your project
- [ ] **Python 3.12+** with `uv` (if Python project)
- [ ] **pnpm** or **npm** (if JavaScript/TypeScript project)

> **Note:** Windows does NOT require `jq` - PowerShell has native JSON support via `ConvertFrom-Json`.

---

## One-Time Setup (Per Machine)

**Do this once on each developer's machine:**

### macOS / Linux

```bash
# Clone the templates repo to your home directory
git clone https://github.com/pablomarin/claude-code-templates.git ~/claude-code-templates

# Make setup script executable
chmod +x ~/claude-code-templates/setup.sh
```

To update templates later:
```bash
cd ~/claude-code-templates && git pull
```

### Windows (PowerShell)

```powershell
# Clone the templates repo to your home directory
git clone https://github.com/pablomarin/claude-code-templates.git $HOME\claude-code-templates
```

To update templates later:
```powershell
cd $HOME\claude-code-templates; git pull
```

> **Note:** If you get an execution policy error when running `setup.ps1`, run:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## Setup Scenarios

### Scenario A: New Project

Starting a brand new project with no existing files.

**macOS / Linux:**
```bash
# 1. Create and enter your project
mkdir my-new-project
cd my-new-project
git init

# 2. Run setup
~/claude-code-templates/setup.sh -p "My New Project"

# 3. Start Claude Code and install plugins
claude
```

**Windows (PowerShell):**
```powershell
# 1. Create and enter your project
mkdir my-new-project
cd my-new-project
git init

# 2. Run setup
& $HOME\claude-code-templates\setup.ps1 -p "My New Project"

# 3. Start Claude Code and install plugins
claude
```

Then run these commands inside Claude Code:
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
/plugin marketplace add EveryInc/compound-engineering-plugin
/plugin install compound-engineering@compound-engineering-plugin
/plugin install code-simplifier
```

**Done!** Now [customize your project](#after-setup-customize-your-project).

---

### Scenario B: Existing Project WITHOUT Claude Code

You have a project but haven't set up Claude Code automation yet.

**macOS / Linux:**
```bash
# 1. Go to your project
cd /path/to/your/existing/project

# 2. Run setup
~/claude-code-templates/setup.sh -p "My Project Name"

# 3. Start Claude Code and install plugins
claude
```

**Windows (PowerShell):**
```powershell
# 1. Go to your project
cd C:\path\to\your\existing\project

# 2. Run setup
& $HOME\claude-code-templates\setup.ps1 -p "My Project Name"

# 3. Start Claude Code and install plugins
claude
```

Then run these commands inside Claude Code:
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
/plugin marketplace add EveryInc/compound-engineering-plugin
/plugin install compound-engineering@compound-engineering-plugin
/plugin install code-simplifier
```

```bash
# 4. Commit the new files
git add .claude/ CLAUDE.md CONTINUITY.md docs/
git commit -m "chore: add Claude Code automation setup"
git push
```

**Done!** Now [customize your project](#after-setup-customize-your-project).

---

### Scenario C: Existing Project WITH Claude Code

You already have `.claude/settings.json` or `CLAUDE.md` from a previous setup.

#### What the Script Does (Safe by Default)

The setup script **will NOT override your existing files**. It checks each file:

| If file exists... | What happens |
|-------------------|--------------|
| `.claude/settings.json` | **Skipped** - your settings preserved |
| `CLAUDE.md` | **Skipped** - your file preserved |
| `CONTINUITY.md` | **Skipped** - your file preserved |
| `.claude/agents/verify-app.md` | Created (likely new for you) |

You'll see output like:
```
  ○ .claude/settings.json already exists (use -f to overwrite)
  ○ CLAUDE.md already exists (use -f to overwrite)
  ✓ Created .claude/agents/verify-app.md
```

#### Option 1: Add Only What's Missing (Recommended)

```bash
# 1. Go to your project
cd /path/to/your/project

# 2. Run setup - only creates files that don't exist
~/claude-code-templates/setup.sh -p "My Project"

# 3. Manually add new features to your existing settings.json
```

**New features to add manually to your `.claude/settings.json`:**

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate the subagent's output quality. Did it complete its task? Is output useful? Respond 'accept' if good, 'reject' with explanation if issues."
          }
        ]
      }
    ]
  }
}
```

**New plugin to install:**
```
/plugin install code-simplifier
```

#### Option 2: Backup and Replace Everything

If you want to fully adopt the new templates:

```bash
# 1. Backup your current setup
cp -r .claude .claude-backup
cp CLAUDE.md CLAUDE.md.backup
cp CONTINUITY.md CONTINUITY.md.backup 2>/dev/null

# 2. Force overwrite with new templates
~/claude-code-templates/setup.sh -p "My Project" -f

# 3. Manually merge back any project-specific content from backups
# Compare: diff CLAUDE.md.backup CLAUDE.md
```

#### Option 3: Just Get the New Stuff

If you only want the new agents and commands:

```bash
# Copy just the new agent
cp ~/claude-code-templates/agents/verify-app.md .claude/agents/

# Copy the PRD commands if you don't have them
cp -r ~/claude-code-templates/commands/prd .claude/commands/

# Install the new plugin
claude
/plugin install code-simplifier
```

#### What's New That You Probably Don't Have

| File/Feature | What it does | Priority |
|--------------|--------------|----------|
| `.claude/agents/verify-app.md` | Runs all tests, reports pass/fail | **High** |
| `code-simplifier` plugin | Cleans up code after review | **High** |
| `SubagentStop` hook | Validates subagent output | Medium |
| Prompt-based `Stop` hook | Intelligent completion check | Medium |
| `/prd:discuss` command | Refine user stories | Medium |
| `/prd:create` command | Generate structured PRD | Medium |

---

## After Setup: Customize Your Project

### 1. Edit CLAUDE.md

Add your project-specific content:

```markdown
## Project
My Awesome App - Description of what it does

## Tech Stack
- **Backend:** Python 3.12+ / FastAPI
- **Frontend:** Next.js 15 / React
- **Database:** PostgreSQL

## Commands
# Add your actual project commands
cd src && uv run pytest              # Run tests
cd frontend && pnpm build            # Build frontend
```

### 2. Edit CONTINUITY.md

Set your current project state:

```markdown
## Goal
Build MVP of feature X by end of Q1

## State

### Done
- Initial project setup

### Now
Working on user authentication

### Next
- API endpoints
- Frontend pages
```

### 3. Verify Setup

```bash
# Restart Claude Code
claude

# Check hooks loaded
/hooks
# Should show: SessionStart, Stop, SubagentStop, PostToolUse

# Check plugins
/help
# Should show: /superpowers:*, /workflows:*, /prd:*

# Test SessionStart hook
/clear
# Should display CONTINUITY.md content
```

---

## Workflow Overview

### The Complete Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. START: Create Feature Branch                             │
│    git checkout -b feat/{feature-name}                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. PRD PHASE (Custom Commands)                              │
│    /prd:discuss {feature}  → Refine user stories           │
│    /prd:create {feature}   → Generate structured PRD       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. DESIGN (Superpowers Plugin)                              │
│    /superpowers:brainstorm → Interactive design            │
│    /superpowers:write-plan → Detailed TDD tasks            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. EXECUTE (Superpowers Plugin)                             │
│    /superpowers:execute-plan                               │
│    → TDD enforced (RED-GREEN-REFACTOR)                     │
│    → Subagents handle individual tasks                     │
│    → Auto-format on save (ruff/prettier)                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. REVIEW (Compound Engineering Plugin)                     │
│    /workflows:review → 14 parallel review agents           │
│    → Fix any issues found                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. CODE SIMPLIFY (Official Anthropic Plugin)                │
│    "Use the code-simplifier agent on modified files"       │
│    → Cleans up architecture                                │
│    → Improves readability                                  │
│    → Preserves functionality                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. VERIFY (Custom Agent)                                    │
│    "Use the verify-app agent"                              │
│    → Runs ALL tests (unit + integration + E2E)             │
│    → Type check + lint                                     │
│    → Provides pass/fail verdict                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. COMPOUND (Compound Engineering Plugin)                   │
│    /workflows:compound (if bugs fixed or patterns learned) │
│    → Captures learnings in CLAUDE.md                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. FINISH                                                   │
│    → Update CONTINUITY.md (Done/Now/Next)                  │
│    → Update docs/CHANGELOG.md (if significant)             │
│    → Commit + Push feature branch (no prompt)              │
│    → Create PR (PROMPTS for permission)                    │
│    → Merge PR (PROMPTS for permission)                     │
│    → Clean up feature branch                               │
└─────────────────────────────────────────────────────────────┘
```

### Why This Workflow?

Based on Boris Cherny's key insight:

> "Probably the most important thing to get great results out of Claude Code — **give Claude a way to verify its work**. If Claude has that feedback loop, it will **2-3x the quality** of the final result."

---

## Commands Reference

### PRD Commands (Requirements)

| Command | Purpose | Output |
|---------|---------|--------|
| `/prd:discuss {feature}` | Interactive user story refinement | `docs/prds/{feature}-discussion.md` |
| `/prd:create {feature}` | Generate structured PRD | `docs/prds/{feature}.md` |

### Superpowers Commands (Design → Execute)

| Command | Purpose | Notes |
|---------|---------|-------|
| `/superpowers:brainstorm` | Interactive design refinement | Uses PRD context |
| `/superpowers:write-plan` | Create detailed implementation plan | TDD tasks |
| `/superpowers:execute-plan` | Execute plan with subagents | TDD enforced |

### Compound Engineering Commands (Review → Learn)

| Command | Purpose | Notes |
|---------|---------|-------|
| `/workflows:review` | 14-agent parallel code review | Run before commit |
| `/workflows:compound` | Capture learnings | Updates CLAUDE.md |
| `/changelog` | Generate changelog draft | From git history |

### Custom Agents

| Agent | How to Use | Purpose |
|-------|------------|---------|
| code-simplifier | "Use the code-simplifier agent on [files]" | Clean up code after review |
| verify-app | "Use the verify-app agent" | Run all tests, report results |

### Built-in Commands

| Command | Purpose |
|---------|---------|
| `/clear` | Clear context (triggers SessionStart hook) |
| `/compact` | Compact context manually |
| `/cost` | Show session costs |
| `/hooks` | View configured hooks |
| `/permissions` | View/modify permissions |
| `/help` | List all commands |
| `Shift+Tab` | Toggle auto-accept mode (mid-session) |

---

## What's Automated

### Hooks (Run Automatically)

| Hook | Trigger | What Happens |
|------|---------|--------------|
| `SessionStart` | New session, `/clear`, compact | CONTINUITY.md loaded into context |
| `Stop` | Claude finishes responding | Validates work complete (prompt + script) |
| `SubagentStop` | Subagent finishes | Validates subagent output quality |
| `PostToolUse` | After Edit/Write on code files | Auto-formats with ruff/prettier |

### Permissions (No Prompts Needed)

| Action | Prompt? | Why |
|--------|---------|-----|
| Read any file (except secrets) | ❌ No | Allowed |
| Edit/Write files (except .env) | ❌ No | Allowed |
| Run tests (pytest, pnpm test) | ❌ No | Allowed |
| Run linters (mypy, ruff) | ❌ No | Allowed |
| Git operations (commit, push) | ❌ No | Allowed on feature branch |
| **gh pr create** | ✅ Yes | Creating PR requires approval |
| **gh pr merge** | ✅ Yes | Merging requires approval |
| **rm -rf** | ✅ Yes | Destructive command |
| sudo, dangerous commands | 🚫 Denied | In deny list |

### Claude's Automatic Behaviors

These happen automatically per CLAUDE.md instructions:

| Task | When | Prompts? |
|------|------|----------|
| Create feature branch | Before new feature | No |
| `/workflows:review` | Before finishing code | No |
| Use code-simplifier | After review | No |
| Use verify-app | After simplify | No |
| `/workflows:compound` | After fixing bugs | No |
| Update CONTINUITY.md | Before finishing session | No |
| Update CHANGELOG.md | After features/fixes | No |
| Commit + push | After tests pass | No |
| **Create PR** | After push | **Yes** |
| **Merge PR** | After PR created | **Yes** |

---

## File Structure

After setup, your project should have:

```
your-project/
├── CLAUDE.md                          # Project rules + workflow + learnings
├── CONTINUITY.md                      # Current state (Done/Now/Next)
├── docs/
│   ├── CHANGELOG.md                   # Historical record
│   ├── prds/                          # Product requirements
│   │   ├── {feature}.md               # Structured PRD
│   │   └── {feature}-discussion.md    # Refinement conversation log
│   └── plans/                         # Design docs from Superpowers
│       └── YYYY-MM-DD-{feature}.md
├── .claude/
│   ├── settings.json                  # Permissions + Hooks + MCP servers
│   ├── hooks/
│   │   ├── check-state-updated.sh     # Stop hook script (macOS/Linux)
│   │   ├── check-state-updated.ps1    # Stop hook script (Windows)
│   │   ├── post-tool-format.sh        # Auto-formatter hook (macOS/Linux)
│   │   └── post-tool-format.ps1       # Auto-formatter hook (Windows)
│   ├── agents/                        # Custom subagents
│   │   └── verify-app.md              # Test verification agent
│   ├── commands/                      # Custom slash commands
│   │   ├── prd/
│   │   │   ├── discuss.md             # /prd:discuss command
│   │   │   └── create.md              # /prd:create command
│   │   └── handoff.md                 # /handoff command
│   └── rules/                         # Coding standards
│       ├── python-style.md
│       ├── typescript-style.md
│       ├── database.md
│       ├── api-design.md
│       ├── security.md
│       └── testing.md
└── ...
```

---

## Troubleshooting

### Setup script says files already exist

This is expected if you already have Claude Code set up. See [Scenario C](#scenario-c-existing-project-with-claude-code) for options.

### Hooks not running?

#### macOS / Linux

1. **Check jq is installed:**
   ```bash
   which jq
   # Should output path like /usr/bin/jq
   ```

2. **Check script is executable:**
   ```bash
   ls -la .claude/hooks/
   # Should show -rwxr-xr-x for check-state-updated.sh
   ```

3. **Check settings.json is valid:**
   ```bash
   cat .claude/settings.json | jq .
   # Should parse without errors
   ```

4. **Restart Claude Code** - Hooks snapshot at session start

#### Windows

1. **Check PowerShell execution policy:**
   ```powershell
   Get-ExecutionPolicy
   # If "Restricted", run:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Check hook scripts exist:**
   ```powershell
   Test-Path .claude\hooks\check-state-updated.ps1
   Test-Path .claude\hooks\post-tool-format.ps1
   # Both should return True
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

5. **Restart Claude Code** - Hooks snapshot at session start

### Permissions still prompting?

1. **Verify settings.json syntax:**
   ```bash
   cat .claude/settings.json | jq '.permissions'
   ```

2. **Check permission patterns:**
   - `Bash(uv:*)` matches `uv run pytest` ✅
   - `Bash(uv run pytest)` only matches exact command ❌
   - Use `:*` suffix for wildcards

3. **Restart Claude Code** after changing settings

### Plugins not showing in /help?

1. **Verify plugin installed:**
   ```
   /plugin list
   ```

2. **Try reinstalling:**
   ```
   /plugin uninstall superpowers@superpowers-marketplace
   /plugin install superpowers@superpowers-marketplace
   ```

### code-simplifier not working?

```bash
# Verify installed
/plugin list
# Should show code-simplifier

# Use it explicitly
"Use the code-simplifier agent on src/services/my_service.py"
```

---

## Security

### What's Protected

| Item | Protection |
|------|------------|
| `.env` files | Cannot be read or written |
| `secrets/` directory | Read blocked |
| `.ssh/` directory | Read blocked |
| `credentials*` files | Read blocked |
| `sudo` commands | Denied |
| `rm -rf /`, `rm -rf ~` | Denied |
| `chmod 777` | Denied |

### What Requires Confirmation

| Action | Why |
|--------|-----|
| `gh pr create` | Creating PR to main |
| `gh pr merge` | Merging to main |
| `rm -rf` with path | Destructive operation |

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│ FIRST TIME SETUP (once per machine)                         │
├─────────────────────────────────────────────────────────────┤
│ macOS/Linux:                                                │
│   git clone https://github.com/pablomarin/claude-code-templates.git ~/claude-code-templates
│   chmod +x ~/claude-code-templates/setup.sh                │
│                                                             │
│ Windows (PowerShell):                                       │
│   git clone https://github.com/pablomarin/claude-code-templates.git $HOME\claude-code-templates
├─────────────────────────────────────────────────────────────┤
│ ADD TO ANY PROJECT                                          │
├─────────────────────────────────────────────────────────────┤
│ macOS/Linux:                                                │
│   cd /your/project                                         │
│   ~/claude-code-templates/setup.sh -p "Project Name"       │
│                                                             │
│ Windows (PowerShell):                                       │
│   cd C:\your\project                                       │
│   & $HOME\claude-code-templates\setup.ps1 -p "Project Name"│
│                                                             │
│ # Then install plugins in Claude Code (see above)          │
├─────────────────────────────────────────────────────────────┤
│ DAILY WORKFLOW                                              │
├─────────────────────────────────────────────────────────────┤
│ START:                                                      │
│   git checkout -b feat/{feature-name}  ← ALWAYS FIRST      │
│   claude                               ← CONTINUITY loads   │
│                                                             │
│ PRD PHASE (new features):                                   │
│   /prd:discuss "feature-name"          ← Refine stories    │
│   /prd:create "feature-name"           ← Generate PRD      │
│                                                             │
│ DESIGN & EXECUTE:                                           │
│   /superpowers:brainstorm              ← Design            │
│   /superpowers:write-plan              ← Plan              │
│   /superpowers:execute-plan            ← Build (TDD)       │
│                                                             │
│ QUALITY:                                                    │
│   /workflows:review                    ← 14 agents review  │
│   "Use code-simplifier agent"          ← Clean up          │
│   "Use verify-app agent"               ← Verify all tests  │
│                                                             │
│ FINISH:                                                     │
│   /workflows:compound                  ← If learnings      │
│   Update CONTINUITY.md                 ← Done/Now/Next     │
│   Commit + push                        ← No prompt         │
│   gh pr create                         ← PROMPTS           │
│   gh pr merge                          ← PROMPTS           │
├─────────────────────────────────────────────────────────────┤
│ SHORTCUTS                                                   │
├─────────────────────────────────────────────────────────────┤
│ Shift+Tab  → Toggle auto-accept mode                       │
│ /clear     → Fresh context (reloads CONTINUITY.md)         │
│ /cost      → Check token usage                             │
│ Escape     → Interrupt Claude                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Getting Help

- **Claude Code Docs:** https://code.claude.com/docs
- **Anthropic Best Practices:** https://www.anthropic.com/engineering/claude-code-best-practices
- **Hooks Reference:** https://code.claude.com/docs/en/hooks
- **Subagents Guide:** https://code.claude.com/docs/en/sub-agents

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.1 | 2026-01-11 | Added native Windows/PowerShell support - hooks now work without jq on Windows, platform-specific settings templates |
| 2.0 | 2026-01-10 | Added code-simplifier, verify-app agent, SubagentStop hook, prompt-based Stop hook, project-agnostic templates, clear setup scenarios |
| 1.0 | 2026-01-02 | Initial setup with Superpowers + Compound Engineering |
