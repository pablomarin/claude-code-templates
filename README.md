# Claude Code Automation Setup

**Company-wide setup guide for Claude Code with Superpowers + Compound Engineering workflow.**

Based on Boris Cherny's (Claude Code creator) workflow and Anthropic's official best practices.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start (Automated)](#quick-start-automated)
3. [Manual Setup](#manual-setup)
4. [Workflow Overview](#workflow-overview)
5. [Commands Reference](#commands-reference)
6. [What's Automated](#whats-automated)
7. [File Structure](#file-structure)
8. [Troubleshooting](#troubleshooting)
9. [Security](#security)
10. [Token Optimization](#token-optimization)

---

## Prerequisites

Before starting, ensure you have:

- [ ] **Claude Code** installed and working (`claude --version`)
- [ ] **jq** installed (required for hooks): `brew install jq` (macOS) or `apt install jq` (Linux)
- [ ] **Node.js 18+** (for npx commands)
- [ ] **Git** initialized in your project
- [ ] **Python 3.12+** with `uv` (if Python project)
- [ ] **pnpm** or **npm** (if JavaScript/TypeScript project)

---

## Quick Start (Automated)

### Option A: Using Setup Script

```bash
# Clone the templates repository (or copy to your machine)
git clone <company-templates-repo> ~/claude-code-templates

# Navigate to your project
cd /path/to/your/project

# Run setup script
~/claude-code-templates/setup.sh

# Or with options:
~/claude-code-templates/setup.sh -p "My Project" -t fullstack
```

### Option B: One-Liner

```bash
# From your project root:
curl -sSL <company-templates-url>/setup.sh | bash -s -- -p "My Project"
```

After running the setup script, continue to [Step 5: Install Plugins](#step-5-install-plugins).

---

## Manual Setup

### Step 1: Create Directory Structure

```bash
cd /path/to/your/project

# Create required directories
mkdir -p .claude/hooks
mkdir -p .claude/rules
mkdir -p .claude/commands/prd
mkdir -p .claude/agents
mkdir -p docs/prds
mkdir -p docs/plans
```

### Step 2: Copy Core Configuration Files

```bash
# From company templates (adjust path as needed)
TEMPLATES=~/claude-code-templates

# Core files
cp $TEMPLATES/CLAUDE-base.md ./CLAUDE.md
cp $TEMPLATES/CONTINUITY-template.md ./CONTINUITY.md
cp $TEMPLATES/settings/settings-template.json ./.claude/settings.json
cp $TEMPLATES/hooks/check-state-updated.sh ./.claude/hooks/

# Make hook executable
chmod +x .claude/hooks/check-state-updated.sh
```

### Step 3: Copy Rules, Commands, and Agents

```bash
# Rules (coding standards)
cp $TEMPLATES/rules/*.md ./.claude/rules/

# Commands (custom slash commands)
cp -r $TEMPLATES/commands/prd ./.claude/commands/
cp $TEMPLATES/commands/handoff.md ./.claude/commands/

# Agents (subagents for specialized tasks)
cp $TEMPLATES/agents/*.md ./.claude/agents/
```

### Step 4: Create CHANGELOG

```bash
cat > docs/CHANGELOG.md << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Initial project setup

### Changed

### Fixed

### Removed

---

## Format

Each entry should include:
- Date (YYYY-MM-DD)
- Brief description
- Related issue/PR if applicable
EOF
```

### Step 5: Install Plugins

Start Claude Code and install required plugins:

```bash
# Start Claude Code
claude

# In Claude Code session:

# 1. Superpowers (design → plan → execute workflow)
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

# 2. Compound Engineering (review → compound learnings)
/plugin marketplace add EveryInc/compound-engineering-plugin
/plugin install compound-engineering@compound-engineering-plugin

# 3. Code Simplifier (official Anthropic plugin - cleans up code)
/plugin install code-simplifier

# 4. Verify installation
/help
```

You should see these commands available:
- `/superpowers:brainstorm`, `/superpowers:write-plan`, `/superpowers:execute-plan`
- `/workflows:review`, `/workflows:compound`, `/changelog`
- `/prd:discuss`, `/prd:create` (custom commands)

### Step 6: Customize for Your Project

Edit `CLAUDE.md` to add:
- Project description
- Tech stack
- Project-specific commands
- Any project-specific rules

Edit `CONTINUITY.md` to add:
- Project goal
- Constraints/assumptions
- Initial state (Done/Now/Next)

### Step 7: Verify Setup

```bash
# Restart Claude Code to load new settings
exit
claude

# Check hooks loaded
/hooks
# Should show: SessionStart, Stop, SubagentStop, PostToolUse

# Check permissions
/permissions
# Should show pre-allowed commands

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

The workflow ensures:
1. **Clear requirements** (PRD phase prevents scope creep)
2. **Thoughtful design** (Superpowers brainstorm before coding)
3. **Quality code** (TDD + review + simplify)
4. **Verified results** (verify-app agent)
5. **Continuous improvement** (compound learnings)

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
│   │   └── check-state-updated.sh     # Stop hook backup script
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

### Files Checklist

After setup, verify you have:

- [ ] `CLAUDE.md` in project root (customized for your project)
- [ ] `CONTINUITY.md` in project root (with goal and initial state)
- [ ] `docs/CHANGELOG.md` exists
- [ ] `docs/prds/` directory exists
- [ ] `.claude/settings.json` with permissions + hooks
- [ ] `.claude/hooks/check-state-updated.sh` (executable)
- [ ] `.claude/agents/verify-app.md`
- [ ] `.claude/commands/prd/discuss.md`
- [ ] `.claude/commands/prd/create.md`
- [ ] `.claude/rules/*.md` files
- [ ] Superpowers plugin installed
- [ ] Compound Engineering plugin installed
- [ ] code-simplifier plugin installed
- [ ] jq installed on system

---

## Troubleshooting

### Hooks not running?

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
   ```bash
   /plugin list
   ```

2. **Try reinstalling:**
   ```bash
   /plugin uninstall superpowers@superpowers-marketplace
   /plugin install superpowers@superpowers-marketplace
   ```

3. **Check marketplace added:**
   ```bash
   /plugin marketplace list
   ```

### Stop hook not blocking?

The Stop hook has two layers:
1. **Prompt-based** (intelligent evaluation)
2. **Script backup** (checks CONTINUITY.md modified)

The script only blocks if:
- There ARE uncommitted changes
- CONTINUITY.md was NOT modified

If no uncommitted changes, hook allows stop (nothing to save).

### code-simplifier not working?

```bash
# Verify installed
/plugin list
# Should show code-simplifier

# Use it explicitly
"Use the code-simplifier agent on src/services/my_service.py"
```

### verify-app agent not found?

Check the agent file exists:
```bash
cat .claude/agents/verify-app.md
```

If missing, copy from templates:
```bash
cp $TEMPLATES/agents/verify-app.md .claude/agents/
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

### To Add More Protection

Edit `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Bash(curl:*)",           // Block network calls
      "Read(src/config/*)",     // Protect config files
      "Write(migrations/*)"     // Protect migrations
    ]
  }
}
```

---

## Token Optimization

This setup is optimized for minimal token usage:

| Component | Tokens | Loaded When |
|-----------|--------|-------------|
| CLAUDE.md | ~1,500 | Every session (auto) |
| CONTINUITY.md | ~500 | Every session (via SessionStart hook) |
| Rules files | ~200 each | Only when Claude needs them |
| Superpowers skills | ~2,000 | When activated by pattern |
| Agents | ~500 each | When explicitly invoked |

**Typical baseline:** ~2,000-2,500 tokens/session

### Tips for Token Efficiency

1. **Keep CLAUDE.md concise** - Remove verbose explanations
2. **Keep CONTINUITY.md focused** - Just state, not history
3. **Use `/clear` strategically** - Resets context, reloads essentials
4. **Use agents for specialized tasks** - They have separate context windows

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
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
├─────────────────────────────────────────────────────────────┤
│ AGENTS                                                      │
├─────────────────────────────────────────────────────────────┤
│ code-simplifier → "Use code-simplifier on [files]"         │
│ verify-app      → "Use verify-app agent"                   │
├─────────────────────────────────────────────────────────────┤
│ BRANCH NAMING                                               │
├─────────────────────────────────────────────────────────────┤
│ feat/{name}     → New features                             │
│ fix/{name}      → Bug fixes                                │
│ refactor/{name} → Refactoring                              │
│ docs/{name}     → Documentation                            │
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
| 2.0 | 2026-01-10 | Added code-simplifier, verify-app agent, SubagentStop hook, prompt-based Stop hook, project-agnostic templates |
| 1.0 | 2026-01-02 | Initial setup with Superpowers + Compound Engineering |
