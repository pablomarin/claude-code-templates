# Claude Code Automation Setup

> **Transform Claude Code from a coding assistant into an autonomous software engineering system with persistent memory.**

This template adds structured workflows, automated quality gates, knowledge compounding, and **cross-session memory** to Claude Code — turning it into a reliable development partner that learns from every bug fix, remembers your preferences, and gets smarter over time.

## Why Use This?

| Problem | Solution |
|---------|----------|
| Claude forgets everything between sessions | **Persistent memory** — auto memory + PreCompact hooks preserve knowledge across sessions |
| Context lost during long sessions | **PreCompact hook** — saves learnings before context compression (inspired by [OpenClaw](https://github.com/openclaw/openclaw)) |
| Claude makes changes without testing | **Automated verification** — tests, lint, types checked before completion |
| Bugs get fixed but knowledge is lost | **Knowledge compounding** — solutions saved to `docs/solutions/` AND auto memory |
| No consistent development process | **Guided workflows** — `/new-feature`, `/fix-bug` commands enforce best practices |
| Context lost between sessions | **State persistence** — CONTINUITY.md tracks Done/Now/Next across sessions |
| Can't run multiple features in parallel | **Git worktrees** — isolated workspaces for parallel Claude sessions |
| Code review happens too late | **Multi-layer review** — `/code-review` (fast) + `/pr-review-toolkit:review-pr` (deep) + `/codex review` (second opinion) |
| E2E testing skipped | **Playwright MCP** — browser testing via standalone MCP server for UI/API changes |

## Key Features

- **Persistent Memory**: Global + project-level memory that survives across sessions and compaction
- **3 Workflow Commands**: `/new-feature`, `/fix-bug`, `/quick-fix` — each guides you through the complete process
- **5 Automated Hooks**: SessionStart, Stop, PreCompact, SubagentStop, PostToolUse — plus global memory hooks
- **Multi-Layer Code Review**: `/code-review` (fast, 5 agents) → `/pr-review-toolkit:review-pr` (deep, 6 agents) → `/codex review` (second opinion)
- **TDD Enforcement**: Red-Green-Refactor via Superpowers plugin
- **Parallel Development**: Multiple Claude sessions working on different features simultaneously
- **Knowledge Base**: Bug fixes automatically documented for future reference

Based on [Boris Cherny's workflow](https://www.anthropic.com/engineering/claude-code-best-practices) (Claude Code creator), Anthropic's official best practices, and [OpenClaw's memory patterns](https://github.com/openclaw/openclaw/discussions/6038).

---

## Quick Start

> **There are two setup steps**: (1) global setup (once per machine) and (2) project setup (once per project). Global setup MUST come first — it installs the memory system that all projects share.

### Step 1: Clone this repo (once per machine)

**macOS / Linux:**
```bash
git clone https://github.com/pablomarin/claude-code-templates.git ~/claude-code-templates
chmod +x ~/claude-code-templates/setup.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/pablomarin/claude-code-templates.git $HOME\claude-code-templates
```

### Step 2: Global setup (once per machine)

This installs Claude's memory system so it remembers things across ALL your projects.

**macOS / Linux:**
```bash
~/claude-code-templates/setup.sh --global
source ~/.zshrc   # ← IMPORTANT: reload your shell
```

**Windows (PowerShell):**
```powershell
& $HOME\claude-code-templates\setup.ps1 -Global
```

### Step 3: Project setup (once per project)

```bash
cd /path/to/your/project
~/claude-code-templates/setup.sh -p "My Project"
```

### Step 4: Install the Superpowers plugin (once per machine)

Start Claude Code and install the only third-party plugin you need:

```bash
claude
```

Then inside Claude Code:
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Restart Claude Code.

> **Note:** `code-review`, `pr-review-toolkit`, `code-simplifier`, and `feature-dev` are all **built-in** Claude Code plugins — no install needed. The setup script pre-configures them in `.claude/settings.json`.

### Step 5: Install Codex CLI (recommended)

Codex CLI gives Claude an independent second opinion on design plans and code reviews. The design review step uses it before any implementation begins.

**macOS / Linux:**
```bash
# Option A: npm (requires Node.js 22+)
npm install -g @openai/codex

# Option B: Homebrew (macOS only — no Node.js dependency)
brew install --cask codex
```

**Windows (via WSL2 — recommended):**
```bash
# Inside WSL:
npm install -g @openai/codex
```

> **Windows note:** Native Windows support is experimental. OpenAI recommends WSL2 for the best experience. See [Codex Windows guide](https://developers.openai.com/codex/windows/) for details.

**Authenticate (all platforms):**
```bash
codex          # Opens browser to sign in (requires ChatGPT Plus/Pro/Business/Enterprise)
```

Or with an API key:
```bash
codex login --with-api-key
```

**Verify:**
```bash
codex --version   # Should show version 0.101.0+
```

> **Don't have Codex?** The workflow still works — Claude will present design plans to you for manual review instead. But Codex provides a faster, independent validation.

### Step 6: Verify setup

Inside Claude Code, run:
```
/hooks       → Should show: SessionStart, Stop, PreCompact, SubagentStop, PostToolUse
/help        → Should show: /superpowers:*, /new-feature, /fix-bug, /prd:*
/memory      → Should show your auto memory directory
```

**Done!** Now use `/new-feature my-feature` to start your first guided workflow.

---

## What You Get

After setup, Claude Code goes from a generic coding assistant to an autonomous engineering system:

### Slim CLAUDE.md + Rules Split

Your `CLAUDE.md` is **intentionally short** (~50 lines) — just your project description, tech stack, and commands. All workflow rules, coding standards, and principles live in `.claude/rules/` files that are auto-loaded by Claude Code with the same priority.

**Why this matters:** When you re-run the setup script to get updated templates, your `CLAUDE.md` is preserved (never overwritten). The `.claude/rules/` files can be safely updated with `-f` since they don't contain your custom content.

### Custom Slash Commands (from `.claude/commands/`)

These are project-level commands that Claude loads from your `.claude/commands/` folder:

| Command | What it does |
|---------|-------------|
| `/new-feature <name>` | Guides you through: Research → PRD → Design → TDD → Review → PR. Creates an isolated git worktree. |
| `/fix-bug <name>` | Systematic 4-phase debugging → Fix → Review → Document solution. Creates an isolated worktree. |
| `/quick-fix <name>` | For trivial changes (< 3 files). Verify and commit directly. |
| `/finish-branch` | Commit → Push → Create PR → Wait for merge → Clean up worktree. |
| `/codex <instruction>` | Get a second opinion from OpenAI's Codex CLI. |
| `/prd:discuss` | Refine user stories interactively. |
| `/prd:create` | Generate a structured product requirements document. |

### Automated Hooks (run without you doing anything)

| Hook | When it fires | What it does |
|------|--------------|-------------|
| **SessionStart** | New session or `/clear` | Shows your current branch and loads CONTINUITY.md (your task state) |
| **Stop** | Claude finishes responding | Checks that CONTINUITY.md + CHANGELOG are updated (blocks if not) |
| **PreCompact** | Before context compression | Saves all session learnings to persistent memory before they're lost |
| **SubagentStop** | Subagent finishes | Validates the subagent's output quality |
| **PostToolUse** | After file edits | Auto-formats code with ruff (Python) or prettier (JS/TS) |

### Multi-Layer Quality Gates (no install needed)

| Gate | What it does |
|------|-------------|
| `/code-review` | Fast review: 5 parallel agents with confidence scoring (built-in) |
| `/pr-review-toolkit:review-pr` | Deep review: 6 specialized agents — silent failures, test coverage, type design (built-in) |
| `code-simplifier` agent | Cleans up code after review (built-in) |
| `verify-app` agent | Runs unit tests, lint, types, migration check (custom agent in `.claude/agents/`) |
| `/codex review` | Independent second opinion from OpenAI Codex (requires Codex CLI) |
| Playwright MCP | E2E browser testing for UI/API changes (standalone MCP server) |

### Persistent Memory System

Claude remembers things across sessions through three mechanisms:
1. **CONTINUITY.md** — Tracks your current task state (Done/Now/Next). Loaded every session.
2. **Auto memory** (`~/.claude/projects/<project>/memory/MEMORY.md`) — Claude writes learnings here: bug patterns, your preferences, architecture notes. First 200 lines loaded every session.
3. **docs/solutions/** — Searchable knowledge base of bug fixes organized by category.

---

## Table of Contents

1. [How Memory Works](#how-memory-works)
2. [Prerequisites](#prerequisites)
3. [One-Time Setup (Per Machine)](#one-time-setup-per-machine)
4. [Setup Scenarios](#setup-scenarios)
   - [Scenario A: New Project](#scenario-a-new-project)
   - [Scenario B: Existing Project WITHOUT Claude Code](#scenario-b-existing-project-without-claude-code)
   - [Scenario C: Existing Project WITH Claude Code](#scenario-c-existing-project-with-claude-code)
5. [After Setup: Customize Your Project](#after-setup-customize-your-project)
6. [Parallel Development (Multiple Sessions)](#parallel-development-multiple-sessions)
7. [Workflow Overview](#workflow-overview)
8. [Commands Reference](#commands-reference)
9. [What's Automated](#whats-automated)
10. [File Structure](#file-structure)
11. [Troubleshooting](#troubleshooting)
12. [Security](#security)

---

## How Memory Works

Claude Code has **two layers of memory** that this template configures. Together, they ensure Claude never "wakes up with amnesia."

### Memory Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    GLOBAL (all projects)                          │
│  ~/.claude/CLAUDE.md          ← Your personal instructions       │
│  ~/.claude/settings.json      ← Global hooks (PreCompact, Stop)  │
│  ~/.claude/hooks/             ← Global hook scripts               │
└──────────────────────────────────────────────────────────────────┘
         │ loaded every session
         ▼
┌──────────────────────────────────────────────────────────────────┐
│                PROJECT-LEVEL (per project)                        │
│  CLAUDE.md                    ← Project description (slim, yours) │
│  .claude/rules/               ← Coding standards + workflow rules │
│  CONTINUITY.md                ← Task state (Done/Now/Next)       │
│  .claude/settings.json        ← Project hooks + permissions      │
│  docs/solutions/              ← Compounded knowledge base        │
└──────────────────────────────────────────────────────────────────┘
         │ loaded every session
         ▼
┌──────────────────────────────────────────────────────────────────┐
│                AUTO MEMORY (Claude writes this)                   │
│  ~/.claude/projects/<project>/memory/                             │
│    MEMORY.md                  ← Index (first 200 lines loaded)   │
│    debugging.md               ← Debugging patterns               │
│    patterns.md                ← Code patterns discovered         │
│    preferences.md             ← Your preferences learned         │
└──────────────────────────────────────────────────────────────────┘
```

### What Each Layer Does

| Layer | Who writes it | What it contains | When it loads |
|-------|--------------|------------------|---------------|
| **Global CLAUDE.md** | You (once) | Memory instructions, personal preferences | Every session, all projects |
| **Project CLAUDE.md** | You | Project description, tech stack, commands (slim) | Every session, this project |
| **`.claude/rules/`** | Template | Workflow, principles, coding standards | Every session, this project |
| **CONTINUITY.md** | Claude | Task state: Done/Now/Next/Blockers | SessionStart hook loads it |
| **Auto Memory** | Claude | Learned patterns, solutions, preferences | MEMORY.md first 200 lines auto-loaded |
| **docs/solutions/** | Claude | Bug fixes, error solutions, patterns | On-demand when relevant |

### How Memory Persists

Three hooks work together to prevent memory loss:

```
Session Start                    During Session                Before Compaction
     │                               │                              │
     ▼                               ▼                              ▼
┌──────────┐                  ┌──────────────┐              ┌──────────────┐
│SessionStart│                │  Stop Hook   │              │PreCompact Hook│
│  Hook     │                │  (global)    │              │  (global +   │
│           │                │              │              │   project)   │
│ Loads:    │                │ Reminds:     │              │ Saves:       │
│ • Branch  │                │ "Save any    │              │ All session  │
│ • CONTI-  │                │  learnings   │              │ learnings to │
│   NUITY   │                │  to memory"  │              │ auto memory  │
│ • Memory  │                │              │              │ before       │
│   context │                │ (lightweight │              │ compression  │
│           │                │  - no block) │              │              │
└──────────┘                  └──────────────┘              └──────────────┘
```

### What Claude Remembers

Over time, Claude's auto memory accumulates:

- **Project patterns**: Build commands, test conventions, code style
- **Bug solutions**: Root causes and fixes (also in `docs/solutions/`)
- **Your preferences**: Tool choices, workflow habits, communication style
- **Architecture notes**: Key files, module relationships, abstractions
- **Debugging insights**: Common error causes, tricky edge cases

### Managing Memory

```bash
# View/edit memory files in Claude Code
/memory

# Tell Claude to remember something explicitly
"Remember that we use pnpm, not npm"
"Save to memory that the API tests require a local Redis instance"

# Tell Claude to forget something
"Forget the Redis requirement, we switched to in-memory cache"

# Force enable auto memory (done by --global setup)
export CLAUDE_CODE_DISABLE_AUTO_MEMORY=0
```

---

## Prerequisites

Before starting, ensure you have:

### macOS / Linux
- [ ] **Claude Code** installed and working (`claude --version`)
- [ ] **Node.js 22+** (for Codex CLI, npx commands, and Playwright MCP)
- [ ] **Git 2.23+** initialized in your project
- [ ] **jq** (recommended, not required): `brew install jq` (macOS) or `apt install jq` (Linux). Hooks work without it but with reduced features.
- [ ] **Codex CLI** (recommended): `npm i -g @openai/codex` or `brew install --cask codex` (macOS). Used for design review and code review second opinions. See [Step 5](#step-5-install-codex-cli-recommended) for full instructions.
- [ ] **Python 3.12+** with `uv` (if Python project)
- [ ] **pnpm** or **npm** (if JavaScript/TypeScript project)

### Windows
- [ ] **Claude Code** installed and working (`claude --version`)
- [ ] **WSL2** (recommended for Codex CLI): `wsl --install` from elevated PowerShell
- [ ] **PowerShell 5.1+** (included with Windows 10/11)
- [ ] **Node.js 22+** (for Codex CLI, npx commands, and Playwright MCP)
- [ ] **Git 2.23+** initialized in your project
- [ ] **Codex CLI** (recommended): `npm i -g @openai/codex` inside WSL. See [Step 5](#step-5-install-codex-cli-recommended) for full instructions.
- [ ] **Python 3.12+** with `uv` (if Python project)
- [ ] **pnpm** or **npm** (if JavaScript/TypeScript project)

> **Note:** Windows does NOT require `jq` - PowerShell has native JSON support via `ConvertFrom-Json`.
>
> **Note:** Codex CLI works best via WSL2 on Windows. Native Windows support is experimental. See [OpenAI's Windows guide](https://developers.openai.com/codex/windows/).

---

## One-Time Setup (Per Machine)

**Do this once on each developer's machine. It sets up global memory that applies to ALL projects.**

### Step 1: Clone Templates

**macOS / Linux:**
```bash
git clone https://github.com/pablomarin/claude-code-templates.git ~/claude-code-templates
chmod +x ~/claude-code-templates/setup.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/pablomarin/claude-code-templates.git $HOME\claude-code-templates
```

### Step 2: Set Up Global Memory

**macOS / Linux:**
```bash
~/claude-code-templates/setup.sh --global
```

**Windows (PowerShell):**
```powershell
& $HOME\claude-code-templates\setup.ps1 -Global
```

This creates:

| File | Purpose |
|------|---------|
| `~/.claude/CLAUDE.md` | Global instructions with memory management rules |
| `~/.claude/settings.json` | Global hooks: PreCompact (save before compression) + Stop (save learnings) |
| `~/.claude/hooks/` | Global hook scripts |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY=0` | Environment variable enabling auto memory |

**After global setup, reload your shell:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

### Step 3: Edit Global CLAUDE.md (Optional)

Add your personal preferences to `~/.claude/CLAUDE.md`:

```markdown
## Personal Preferences
- Always use uv for Python package management
- Prefer concise commit messages
- Use pnpm over npm for Node.js projects
- Default to TypeScript for new JavaScript projects
```

To update templates later:
```bash
cd ~/claude-code-templates && git pull
```

> **Note:** If you get an execution policy error on Windows when running `setup.ps1`, run:
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
& $HOME\claude-code-templates\setup.ps1 -p "My New Project"

# 3. Start Claude Code and install plugin
claude
```

Then install the Superpowers plugin (if not already done — see [Quick Start Step 4](#step-4-install-the-superpowers-plugin-once-per-machine)). Restart Claude Code.

> Plugins are pre-configured in `.claude/settings.json`. You only need to install Superpowers once per machine.

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

# 3. Start Claude Code
claude
```

**Windows (PowerShell):**
```powershell
# 1. Go to your project
cd C:\path\to\your\existing\project

# 2. Run setup
& $HOME\claude-code-templates\setup.ps1 -p "My Project Name"

# 3. Start Claude Code
claude
```

Install the Superpowers plugin if not already done (see [Quick Start Step 4](#step-4-install-the-superpowers-plugin-once-per-machine)). Restart Claude Code.

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

The setup script **will NOT override** your user-owned files (`CLAUDE.md`, `CONTINUITY.md`, `.claude/settings.json`). However, `.claude/rules/` files **are always safe to overwrite** since they contain template-managed standards, not your custom content.

| If file exists... | What happens |
|-------------------|--------------|
| `CLAUDE.md` | **Skipped** - your file preserved |
| `CONTINUITY.md` | **Skipped** - your file preserved |
| `.claude/settings.json` | **Skipped** - your settings preserved |
| `.claude/rules/*.md` | **Skipped** by default (use `-f` to update to latest standards) |
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
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "prompt",
            "model": "haiku",
            "prompt": "CONTEXT COMPACTION IMMINENT. Save any new learnings from this session to your auto memory (MEMORY.md or topic files). Include: bug root causes, patterns discovered, architecture insights. Do NOT save session-specific state. Keep MEMORY.md concise.",
            "timeout": 30
          }
        ]
      }
    ],
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

#### What's New That You Probably Don't Have

| File/Feature | What it does | Priority |
|--------------|--------------|----------|
| `PreCompact` hook | Saves learnings before context compression | **High** |
| Memory section in CLAUDE.md | Tells Claude to actively use auto memory | **High** |
| Global `~/.claude/CLAUDE.md` | Memory instructions for all projects | **High** |
| `.claude/agents/verify-app.md` | Runs all tests, reports pass/fail | **High** |
| Playwright MCP server | Standalone E2E browser testing | **High** |
| `SubagentStop` hook | Validates subagent output | Medium |
| `/prd:discuss` command | Refine user stories | Medium |
| `/prd:create` command | Generate structured PRD | Medium |

---

## After Setup: Customize Your Project

### 1. Edit CLAUDE.md

CLAUDE.md is intentionally **slim** (~50 lines). It only contains your project-specific info. All workflow rules, coding standards, and principles live in `.claude/rules/` (auto-loaded with the same priority).

Fill in the placeholders:

```markdown
## Project Overview
My Awesome App - Description of what it does

### Tech Stack
- **Backend:** Python 3.12+ / FastAPI
- **Frontend:** Next.js 15 / React
- **Database:** PostgreSQL

### Key Commands
cd src && uv run pytest              # Run tests
cd frontend && pnpm build            # Build frontend
```

> **Why so slim?** Official best practices recommend keeping CLAUDE.md under 60-100 lines. Shorter files = better Claude performance. Everything else lives in `.claude/rules/` which loads automatically.

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
# Should show: SessionStart, Stop, PreCompact, SubagentStop, PostToolUse

# Check commands available
/help
# Should show: /superpowers:*, /new-feature, /fix-bug, /prd:*

# Test SessionStart hook
/clear
# Should display CONTINUITY.md content

# Check memory
/memory
# Should show auto memory entry + CLAUDE.md files
```

---

## Parallel Development (Multiple Sessions)

Run multiple Claude Code sessions simultaneously on the same project — each working on a different feature without conflicts.

### How It Works

When you run `/new-feature` or `/fix-bug` from the `main` branch, the workflow automatically:

1. **Creates an isolated worktree** at `.worktrees/<feature-name>/`
2. **Copies environment files** (`.env*`) to the worktree
3. **Installs dependencies** (Node.js/Python)
4. **cd's into the worktree** — all subsequent commands run there

Each session works in its own isolated directory with its own branch. No conflicts, no shared state files.

### Example: 3 Parallel Sessions

```bash
# Terminal 1
cd /project && claude
> /new-feature auth        # Creates .worktrees/auth/, cd's into it

# Terminal 2
cd /project && claude
> /new-feature api         # Creates .worktrees/api/, cd's into it

# Terminal 3
cd /project && claude
> /fix-bug login-error     # Creates .worktrees/login-error/, cd's into it
```

### Critical: Always Run Claude from Project Root

> **WARNING**: Always start `claude` from the **main project directory**, NOT from inside a worktree.

```bash
# Correct - run from project root
cd /project && claude
> /new-feature auth

# Wrong - don't cd into worktree then run claude
cd /project/.worktrees/auth && claude  # Hooks won't work!
```

**Why?** The `.claude/` folder (with hooks, settings, agents) lives in the main repo. Running Claude from inside a worktree means it won't find these configurations.

### Important Notes

- **Worktrees are created automatically** when starting from `main`
- **No nested worktrees** — if already in a worktree or feature branch, the workflow uses the current directory
- **Hooks run in current directory** — after Claude cd's into a worktree, hooks check files there
- **File paths are relative** — use `src/main.py`, not `.worktrees/auth/src/main.py`
- **`.worktrees/` is gitignored** automatically
- **Dependencies are installed** automatically
- **Quick-fix does NOT create worktrees** — use `/new-feature` or `/fix-bug` for parallel work
- **Cleanup is safe** — each session is fully isolated, no shared state between sessions
- **Memory is per-worktree** — git worktrees get separate auto memory directories, so each session tracks its own learnings independently

### Cleanup

The `/finish-branch` command handles cleanup automatically after PR merge. It will:
1. Remove the worktree
2. Delete the local branch
3. Delete the remote branch
4. Prune stale references
5. Switch to main and pull latest

**Manual cleanup** (if needed):

```bash
# Go back to main repo (from inside worktree)
cd "$(git rev-parse --git-common-dir)/.."

# Remove a specific worktree (after merging its branch)
git worktree remove ".worktrees/auth"

# Clean up stale worktree metadata
git worktree prune

# Delete the merged branch
git branch -d feat/auth
git push origin --delete feat/auth
```

**Tip**: Use `/finish-branch` to automate cleanup and avoid forgetting steps

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
│ 2. RESEARCH (WebSearch/WebFetch/Context7)                   │
│    → Current library docs and best practices               │
│    → Breaking changes since AI knowledge cutoff            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. PRD PHASE (Custom Commands)                              │
│    /prd:discuss {feature}  → Refine user stories           │
│    /prd:create {feature}   → Generate structured PRD       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. DESIGN (Superpowers Plugin)                              │
│    /superpowers:brainstorming → Interactive design            │
│    /superpowers:writing-plans → Detailed TDD tasks            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 4b. DESIGN REVIEW (MANDATORY)                               │
│    /codex review the plan                                    │
│    → Independent validation before writing code             │
│    → If no Codex: present plan to user for confirmation     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. EXECUTE (Superpowers Plugin)                             │
│    /superpowers:executing-plans                               │
│    → TDD enforced (RED-GREEN-REFACTOR)                     │
│    → Subagents handle individual tasks                     │
│    → Auto-format on save (ruff/prettier)                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 5b. DEBUG (if bugs encountered)                             │
│    /superpowers:systematic-debugging                       │
│    → 4-phase root cause analysis                           │
│    → NO fixes without investigation first                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. FAST REVIEW (Built-in Code Review)                       │
│    /code-review → 5 parallel agents, confidence scoring    │
│    → Fix any high-confidence issues found                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. CODE SIMPLIFY                                            │
│    "Use the code-simplifier agent on modified files"       │
│    → Cleans up architecture, improves readability          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. VERIFY                                                   │
│    "Use the verify-app agent"                              │
│    → Unit tests + migrations + lint + types                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. DEEP REVIEW (PR Review Toolkit)                          │
│    /pr-review-toolkit:review-pr                              │
│    → 6 specialized agents (silent failures, test coverage, │
│      type design, comment quality, code review, simplify)  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 10. SECOND OPINION (Optional - Codex CLI)                   │
│    /codex review                                            │
│    → Independent review from OpenAI Codex                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 11. E2E TESTING (if UI/API changed)                         │
│    Playwright MCP server                                    │
│    → Browser tests against affected routes                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 12. COMPOUND LEARNINGS                                      │
│    docs/solutions/ + auto memory                            │
│    → Bug root causes, patterns, solutions saved            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 13. FINISH (Structured)                                     │
│    → Update CONTINUITY.md (Done/Now/Next)                  │
│    → Update docs/CHANGELOG.md (if 3+ files changed)        │
│    → /finish-branch                                        │
│      (commit, push, create PR, cleanup worktree after merge)│
└─────────────────────────────────────────────────────────────┘
```

### Why This Workflow?

Based on Boris Cherny's key insight:

> "Probably the most important thing to get great results out of Claude Code — **give Claude a way to verify its work**. If Claude has that feedback loop, it will **2-3x the quality** of the final result."

---

## Commands Reference

### Workflow Commands (ENFORCED - Start Here)

| Command | Purpose | Notes |
|---------|---------|-------|
| `/new-feature <name>` | Full feature workflow | Research → PRD → Brainstorm → Plan → Execute → Review → Finish |
| `/fix-bug <name>` | Bug fix workflow | Search solutions → Systematic debugging → Fix → Review → Compound |
| `/quick-fix <name>` | Trivial changes only | < 3 files, no arch impact, still requires verify |
| `/finish-branch` | Complete branch workflow | Commit → Push → PR → Wait for merge → Cleanup worktree |

**Workflow commands guide the process.** SessionStart loads context, Stop hook validates completion.

### PRD Commands (Requirements)

| Command | Purpose | Output |
|---------|---------|--------|
| `/prd:discuss {feature}` | Interactive user story refinement | `docs/prds/{feature}-discussion.md` |
| `/prd:create {feature}` | Generate structured PRD | `docs/prds/{feature}.md` |

### Superpowers Commands (Design → Execute → Debug)

| Command | Purpose | Notes |
|---------|---------|-------|
| `/superpowers:brainstorming` | Interactive design refinement | Uses PRD context |
| `/superpowers:writing-plans` | Create detailed implementation plan | TDD tasks |
| `/superpowers:executing-plans` | Execute plan with subagents | TDD enforced |
| `/superpowers:systematic-debugging` | 4-phase root cause analysis | Before ANY bug fix |
| `/superpowers:verification-before-completion` | Evidence-based completion check | Catches "should work" claims |

### Built-in Code Review & Quality

| Command / Agent | Purpose | Notes |
|-----------------|---------|-------|
| `/code-review` | Fast code review (5 parallel agents) | Confidence scoring 80+, high-signal |
| `/pr-review-toolkit:review-pr` | Deep multi-analyzer review (6 agents) | Silent failures, test coverage, type design |
| `code-simplifier` agent | Clean up modified files | "Use the code-simplifier agent on [files]" |
| `verify-app` agent | Unit tests, migration check, lint, types | "Use the verify-app agent" |

### Second Opinion (Codex CLI)

| Command | Purpose | Notes |
|---------|---------|-------|
| `/codex review` | Code review via OpenAI Codex | Uses `codex review` with uncommitted/base/commit options |
| `/codex {instruction}` | General second opinion | Runs `codex exec` in read-only sandbox |

### Built-in Commands

| Command | Purpose |
|---------|---------|
| `/clear` | Clear context (triggers SessionStart hook) |
| `/compact` | Compact context manually (triggers PreCompact hook) |
| `/memory` | View/edit memory files (auto memory + CLAUDE.md) |
| `/cost` | Show session costs |
| `/hooks` | View configured hooks |
| `/permissions` | View/modify permissions |
| `/help` | List all commands |
| `Shift+Tab` | Toggle auto-accept mode (mid-session) |

---

## What's Automated

### Hooks (Run Automatically)

| Hook | Trigger | What Happens | Scope |
|------|---------|--------------|-------|
| `SessionStart` | New session, `/clear`, compact | Loads CONTINUITY.md, shows branch | Project |
| `Stop` (global) | Claude finishes responding | Reminds Claude to save learnings to memory (lightweight, non-blocking) | Global |
| `Stop` (project) | Claude finishes responding | Checks CONTINUITY.md + CHANGELOG updated (script only, blocks if needed) | Project |
| `PreCompact` | Before context compression | Saves session knowledge to auto memory | Global + Project |
| `SubagentStop` | Subagent finishes | Validates subagent output quality | Project |
| `PostToolUse` | After Edit/Write on code files | Auto-formats with ruff/prettier | Project |

### How Global and Project Hooks Interact

Global hooks (`~/.claude/settings.json`) and project hooks (`.claude/settings.json`) **both run**. They don't conflict — they complement each other:

- **Global Stop hook**: Lightweight memory reminder (haiku model, 15s timeout, non-blocking)
- **Project Stop hook**: Script checks if CONTINUITY.md + CHANGELOG are updated (blocks via exit code 2 if not)
- **Global PreCompact hook**: Memory save reminder (haiku model)
- **Project PreCompact hook**: Memory save + project-specific context script

### Permissions (No Prompts Needed)

| Action | Prompt? | Why |
|--------|---------|-----|
| Read any file (except secrets) | No | Allowed |
| Edit/Write files (except .env) | No | Allowed |
| Run tests (pytest, pnpm test) | No | Allowed |
| Run linters (mypy, ruff) | No | Allowed |
| Git operations (commit, push) | No | Allowed on feature branch |
| Context7 MCP tools | No | Auto-approved for docs lookup |
| Playwright MCP tools | No | Auto-approved for E2E testing |
| **gh pr create** | Yes | Creating PR requires approval |
| **gh pr merge** | Yes | Merging requires approval |
| **rm -rf** | Yes | Destructive command |
| sudo, dangerous commands | Denied | In deny list |

---

## File Structure

After setup, your project should have:

```
your-project/
├── CLAUDE.md                          # Project description (slim, user-owned)
├── CONTINUITY.md                      # Current state (Done/Now/Next)
├── docs/
│   ├── CHANGELOG.md                   # Historical record
│   ├── prds/                          # Product requirements
│   │   ├── {feature}.md               # Structured PRD
│   │   └── {feature}-discussion.md    # Refinement conversation log
│   ├── plans/                         # Design docs from Superpowers
│   │   └── YYYY-MM-DD-{feature}.md
│   └── solutions/                     # Compounded learnings (searchable)
│       ├── build-errors/
│       ├── test-failures/
│       ├── runtime-errors/
│       ├── performance-issues/
│       ├── database-issues/
│       ├── security-issues/
│       ├── ui-bugs/
│       ├── integration-issues/
│       ├── logic-errors/
│       └── patterns/                  # Consolidated when 3+ similar
├── .claude/
│   ├── settings.json                  # Permissions + Hooks + MCP servers
│   ├── hooks/
│   │   ├── check-state-updated.sh     # Stop hook script (macOS/Linux)
│   │   ├── check-state-updated.ps1    # Stop hook script (Windows)
│   │   ├── pre-compact-memory.sh      # PreCompact hook script (macOS/Linux)
│   │   ├── pre-compact-memory.ps1     # PreCompact hook script (Windows)
│   │   ├── post-tool-format.sh        # Auto-formatter hook (macOS/Linux)
│   │   └── post-tool-format.ps1       # Auto-formatter hook (Windows)
│   ├── agents/                        # Custom subagents
│   │   └── verify-app.md              # Test verification agent
│   ├── commands/                      # Custom slash commands (ENFORCED)
│   │   ├── new-feature.md             # /new-feature - Full feature workflow
│   │   ├── fix-bug.md                 # /fix-bug - Bug fix workflow
│   │   ├── quick-fix.md              # /quick-fix - Trivial changes only
│   │   ├── finish-branch.md           # /finish-branch - PR + cleanup workflow
│   │   ├── codex.md                   # /codex - Second opinion via Codex CLI
│   │   └── prd/
│   │       ├── discuss.md             # /prd:discuss command
│   │       └── create.md             # /prd:create command
│   └── rules/                         # Auto-loaded standards (safe to overwrite)
│       ├── principles.md              # Top-level principles + design philosophy
│       ├── workflow.md                # Decision matrix for choosing commands
│       ├── worktree-policy.md         # Git worktree isolation rules
│       ├── critical-rules.md          # Non-negotiable rules (branch safety, TDD)
│       ├── memory.md                  # How to use persistent memory
│       ├── security.md                # Security standards
│       ├── testing.md                 # Testing standards
│       ├── api-design.md              # API design standards
│       ├── python-style.md            # Python coding style
│       ├── typescript-style.md        # TypeScript coding style
│       └── database.md               # Database conventions
└── ...
```

**Global files** (created by `setup.sh --global`):

```
~/.claude/
├── CLAUDE.md                          # Global instructions + memory management
├── settings.json                      # Global hooks (PreCompact, Stop)
└── hooks/
    ├── pre-compact-memory.sh          # PreCompact script (macOS/Linux)
    └── pre-compact-memory.ps1         # PreCompact script (Windows)

~/.claude/projects/<project>/memory/   # Auto memory (Claude writes this)
├── MEMORY.md                          # Index (first 200 lines loaded every session)
├── debugging.md                       # Debugging patterns (on-demand)
├── patterns.md                        # Code patterns (on-demand)
└── ...                                # Other topic files Claude creates
```

---

## Troubleshooting

### Setup script says files already exist

This is expected if you already have Claude Code set up. See [Scenario C](#scenario-c-existing-project-with-claude-code) for options.

### Memory not persisting?

1. **Check auto memory is enabled:**
   ```bash
   echo $CLAUDE_CODE_DISABLE_AUTO_MEMORY
   # Should output: 0
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

### Hooks not running?

#### macOS / Linux

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

### Permissions still prompting?

1. **Verify settings.json syntax:**
   ```bash
   cat .claude/settings.json | jq '.permissions'
   ```

2. **Check permission patterns:**
   - `Bash(uv:*)` matches `uv run pytest`
   - `Bash(uv run pytest)` only matches exact command
   - Use `:*` suffix for wildcards

3. **Restart Claude Code** after changing settings

### MCP servers still prompting for permission?

MCP permissions **do not support wildcards**. The pattern `mcp__*` does nothing.

**Correct syntax:**
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

### Plugins not showing in /help?

1. **Verify plugin installed:**
   ```
   /plugin list
   ```

2. **Verify plugin is ENABLED** in `~/.claude/settings.json`:
   ```json
   {
     "enabledPlugins": {
       "superpowers@superpowers-marketplace": true,
       "pr-review-toolkit@claude-plugins-official": true
     }
   }
   ```

3. **Restart Claude Code** after enabling plugins

4. **Try reinstalling:**
   ```
   /plugin uninstall superpowers@superpowers-marketplace
   /plugin install superpowers@superpowers-marketplace
   ```

### Codex CLI not working?

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

### code-simplifier not working?

```bash
# Verify installed
/plugin list
# Should show pr-review-toolkit (includes code-simplifier)

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
│   git clone ...claude-code-templates ~/claude-code-templates│
│   chmod +x ~/claude-code-templates/setup.sh                │
│   ~/claude-code-templates/setup.sh --global                │
│                                                             │
│ Windows (PowerShell):                                       │
│   git clone ...claude-code-templates $HOME\claude-code-templates
│   & $HOME\claude-code-templates\setup.ps1 -Global          │
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
│ # Then install Superpowers plugin in Claude Code            │
├─────────────────────────────────────────────────────────────┤
│ DAILY WORKFLOW (Hooks enforce this!)                        │
├─────────────────────────────────────────────────────────────┤
│ START:                                                      │
│   claude                               ← CONTINUITY loads   │
│   Answer: "What type of task?"         ← SessionStart asks  │
│                                                             │
│ THEN RUN ONE OF THESE COMMANDS:                             │
│   /new-feature <name>  ← Full workflow (Research→PRD→Plan) │
│   /fix-bug <name>      ← Debugging workflow (Systematic)   │
│   /quick-fix <name>    ← Trivial only (< 3 files)          │
│   /finish-branch       ← PR creation + worktree cleanup    │
│                                                             │
│ QUALITY GATES (built-in):                                   │
│   /code-review         ← Fast review (5 agents)            │
│   /pr-review-toolkit:review-pr  ← Deep review (6 agents)   │
│   /codex review        ← Second opinion (Codex CLI)        │
│                                                             │
│ MEMORY COMMANDS:                                            │
│   /memory              ← View/edit memory files             │
│   "Remember X"         ← Save to auto memory               │
│   "Forget X"           ← Remove from auto memory           │
├─────────────────────────────────────────────────────────────┤
│ SHORTCUTS                                                   │
├─────────────────────────────────────────────────────────────┤
│ Shift+Tab  → Toggle auto-accept mode                       │
│ /clear     → Fresh context (reloads CONTINUITY.md)         │
│ /compact   → Compact context (triggers PreCompact hook)    │
│ /cost      → Check token usage                             │
│ Escape     → Interrupt Claude                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Getting Help

- **Claude Code Docs:** https://code.claude.com/docs
- **Memory Management:** https://code.claude.com/docs/en/memory
- **Hooks Reference:** https://code.claude.com/docs/en/hooks
- **Skills & Commands:** https://code.claude.com/docs/en/skills
- **Anthropic Best Practices:** https://www.anthropic.com/engineering/claude-code-best-practices
- **Subagents Guide:** https://code.claude.com/docs/en/sub-agents

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 5.1 | 2026-02-19 | **CLAUDE.MD SPLIT**: Slimmed CLAUDE.md to ~50 lines (user-owned: project description, tech stack, commands). Moved workflow, principles, worktree policy, critical rules, and memory instructions to `.claude/rules/` files that are auto-loaded and safe to overwrite on updates. Following official best practice of keeping CLAUDE.md under 60-100 lines. |
| 5.0 | 2026-02-19 | **REMOVED COMPOUND ENGINEERING**: Replaced with built-in Claude Code quality gates (`/code-review`, `/pr-review-toolkit:review-pr`, `/codex review`). E2E testing via standalone Playwright MCP. Knowledge compounding via `docs/solutions/` + auto memory. Only Superpowers remains as third-party plugin. Added standalone MCP servers (Playwright, Context7) to project settings. |
| 4.0 | 2026-02-19 | **PERSISTENT MEMORY**: Added global memory system (`--global` flag), PreCompact hooks to save learnings before context compression, global Stop hook for memory reminders, `~/.claude/CLAUDE.md` template with memory instructions. Inspired by OpenClaw's pre-compaction memory flush pattern. Auto memory enabled by default. |
| 3.4 | 2026-02-16 | **CODEX COMMAND**: Added `/codex` command for getting second opinions from OpenAI's Codex CLI. Code review and general feedback modes. |
| 3.3 | 2026-01-22 | **FINISH-BRANCH COMMAND**: Added `/finish-branch` command that handles PR creation + worktree cleanup. Removed `/superpowers:finishing-a-development-branch` from workflows (redundant testing, no worktree awareness). `/quick-fix` now just commits directly. |
| 3.2 | 2026-01-19 | **SIMPLIFIED WORKTREES**: Claude now `cd`s into worktrees instead of using path prefixes. Removed `.session_worktree` file - no shared state between sessions. Hooks and verify-app simplified to use current directory. |
| 3.1 | 2026-01-19 | **PARALLEL DEVELOPMENT**: Workflow commands auto-create git worktrees for isolated parallel sessions. Hooks are worktree-aware. verify-app agent accepts worktree path. |
| 3.0 | 2026-01-18 | **WORKFLOW COMMANDS**: Added `/new-feature`, `/fix-bug`, `/quick-fix` commands that contain full workflows. Refactored CLAUDE.md to be lean (140 lines vs 318). E2E via Playwright MCP. |
| 2.7 | 2026-01-18 | Simplified CONTINUITY.md: Done section keeps only 2-3 recent items, removed redundant sections (Working Set, Test Status, Active Artifacts). Leaner template. |
| 2.6 | 2026-01-18 | Hooks follow Anthropic best practices: path traversal protection, sensitive file skip, `$CLAUDE_PROJECT_DIR` for absolute paths. Added external post-tool-format.sh script. |
| 2.5 | 2026-01-17 | E2E testing via Playwright MCP. Removed E2E from verify-app agent. |
| 2.4 | 2026-01-17 | Knowledge compounding now uses `docs/solutions/` instead of inline CLAUDE.md learnings. Searchable files with YAML frontmatter, auto-categorized by problem type. |
| 2.3 | 2026-01-17 | Enhanced workflow with Superpowers skills: systematic-debugging, verification-before-completion. Updated Stop hook checklist. |
| 2.2 | 2026-01-17 | Fixed MCP permissions - wildcards don't work, use explicit server names. |
| 2.1 | 2026-01-11 | Added native Windows/PowerShell support - hooks now work without jq on Windows, platform-specific settings templates. |
| 2.0 | 2026-01-10 | Added code-simplifier, verify-app agent, SubagentStop hook, prompt-based Stop hook, project-agnostic templates, clear setup scenarios. |
| 1.0 | 2026-01-02 | Initial setup with Superpowers. |
