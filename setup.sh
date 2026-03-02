#!/bin/bash
# ============================================================================
# Claude Code Project Setup Script
# Company-wide template for consistent AI-assisted development workflow
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where templates live - same directory as this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Set up Claude Code configuration for a project or globally."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -p, --project NAME  Project name (default: directory name)"
    echo "  -t, --tech STACK    Tech stack: python, typescript, fullstack (default: fullstack)"
    echo "  -f, --force         Overwrite existing files (destructive)"
    echo "  -u, --upgrade       Smart upgrade: merge new hooks/permissions into existing settings"
    echo "  -g, --global        Set up global memory system (~/.claude/)"
    echo ""
    echo "Examples:"
    echo "  $0                          # Setup with defaults"
    echo "  $0 -p \"My Project\"          # Custom project name"
    echo "  $0 -t python                # Python-only project"
    echo "  $0 -f                       # Force overwrite existing files"
    echo "  $0 --upgrade                # Upgrade: add new hooks/rules, merge settings"
    echo "  $0 --global                 # Set up global memory (run once per machine)"
    echo "  $0 --global -f              # Force overwrite global settings"
}

# Parse arguments
PROJECT_NAME=""
TECH_STACK="fullstack"
FORCE=false
UPGRADE=false
GLOBAL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -p|--project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -t|--tech)
            TECH_STACK="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -u|--upgrade)
            UPGRADE=true
            FORCE=true  # upgrade implies force for hooks/commands/rules
            shift
            ;;
        -g|--global)
            GLOBAL=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Copy function with force check
copy_file() {
    local src="$1"
    local dest="$2"
    local desc="$3"

    if [[ ! -f "$src" ]]; then
        echo -e "  ${RED}✗${NC} Template not found: $src"
        return 1
    fi

    if [[ -f "$dest" ]] && [[ "$FORCE" != true ]]; then
        echo -e "  ${BLUE}○${NC} $desc already exists (use -f to overwrite)"
        return 0
    fi

    cp "$src" "$dest"
    echo -e "  ${GREEN}✓${NC} Created $desc"
}

# ============================================================================
# GLOBAL SETUP (--global flag)
# ============================================================================
if [[ "$GLOBAL" == true ]]; then
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Claude Code Global Setup${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    echo -e "This sets up Claude Code's memory system for ${GREEN}ALL${NC} your projects."
    echo "After this, Claude will remember learnings across sessions and projects."
    echo ""

    # Create global directories
    echo -e "${YELLOW}Step 1: Creating global directories...${NC}"

    global_dirs=(
        "$HOME/.claude"
        "$HOME/.claude/hooks"
        "$HOME/.claude/rules"
    )

    for dir in "${global_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo -e "  ${GREEN}✓${NC} Created $dir"
        else
            echo -e "  ${BLUE}○${NC} $dir already exists"
        fi
    done
    echo ""

    # Copy global CLAUDE.md
    echo -e "${YELLOW}Step 2: Installing global configuration...${NC}"
    echo "  These files tell Claude how to manage its memory."
    copy_file "$SCRIPT_DIR/GLOBAL-CLAUDE.template.md" "$HOME/.claude/CLAUDE.md" "~/.claude/CLAUDE.md (global instructions)"

    # Copy global hooks
    copy_file "$SCRIPT_DIR/hooks/pre-compact-memory.sh" "$HOME/.claude/hooks/pre-compact-memory.sh" "~/.claude/hooks/pre-compact-memory.sh"
    chmod +x "$HOME/.claude/hooks/pre-compact-memory.sh" 2>/dev/null || true

    # Merge global hooks into existing settings (preserves user's plugins, statusLine, etc.)
    GLOBAL_SETTINGS="$HOME/.claude/settings.json"
    TEMPLATE_SETTINGS="$SCRIPT_DIR/settings/global-settings.template.json"
    if [[ -f "$GLOBAL_SETTINGS" ]]; then
        MERGE_SUCCESS=false
        if command -v jq &> /dev/null; then
            # Use jq to merge just the hooks key, preserving everything else
            MERGED=$(jq -s '.[0] * {hooks: .[1].hooks}' "$GLOBAL_SETTINGS" "$TEMPLATE_SETTINGS" 2>/dev/null)
            if [[ $? -eq 0 ]] && [[ -n "$MERGED" ]]; then
                echo "$MERGED" > "$GLOBAL_SETTINGS"
                echo -e "  ${GREEN}✓${NC} Merged hooks into existing ~/.claude/settings.json (your settings preserved)"
                MERGE_SUCCESS=true
            fi
        fi
        if [[ "$MERGE_SUCCESS" != true ]] && command -v python3 &> /dev/null; then
            # Fallback: use Python to merge JSON
            python3 -c "
import json, sys
with open('$GLOBAL_SETTINGS') as f: existing = json.load(f)
with open('$TEMPLATE_SETTINGS') as f: template = json.load(f)
existing['hooks'] = template['hooks']
with open('$GLOBAL_SETTINGS', 'w') as f: json.dump(existing, f, indent=2)
" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                echo -e "  ${GREEN}✓${NC} Merged hooks into existing ~/.claude/settings.json (your settings preserved)"
                MERGE_SUCCESS=true
            fi
        fi
        if [[ "$MERGE_SUCCESS" != true ]]; then
            echo -e "  ${YELLOW}⚠${NC} Could not auto-merge hooks (install jq or python3). Manually add hooks from:"
            echo -e "    ${BLUE}$TEMPLATE_SETTINGS${NC}"
        fi
    else
        copy_file "$TEMPLATE_SETTINGS" "$GLOBAL_SETTINGS" "~/.claude/settings.json (global hooks)"
    fi

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Global Setup Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${YELLOW}What was created:${NC}"
    echo ""
    echo "  ~/.claude/CLAUDE.md         Instructions that tell Claude how to use its memory"
    echo "  ~/.claude/settings.json     Hooks that auto-save learnings before context loss"
    echo "  ~/.claude/hooks/            Scripts that provide context to memory hooks"
    echo "  ~/.claude/rules/            Personal rules that apply to all your projects"
    echo ""
    echo -e "${YELLOW}What this means:${NC}"
    echo ""
    echo "  Claude will now:"
    echo "  - Save bug fixes, patterns, and preferences to persistent memory"
    echo "  - Automatically preserve learnings before context compression"
    echo "  - Load its memory at the start of every session"
    echo "  - Get smarter over time as it accumulates project knowledge"
    echo ""
    echo -e "${YELLOW}Now set up your first project:${NC}"
    echo ""
    echo "  cd /your/project"
    echo "  $SCRIPT_DIR/setup.sh -p \"Project Name\""
    echo ""
    exit 0
fi

# ============================================================================
# PROJECT SETUP (default, no --global flag)
# ============================================================================

# Default project name to directory name
if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME=$(basename "$(pwd)")
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Claude Code Setup for: ${GREEN}$PROJECT_NAME${NC}"
echo -e "${BLUE}  Tech Stack: ${GREEN}$TECH_STACK${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v jq &> /dev/null; then
    echo -e "  ${YELLOW}⚠${NC} jq not found. The pre-compact-memory hook will output less session context."
    echo "    Install for best experience: brew install jq (macOS) or apt install jq (Linux)"
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}ERROR: git is required but not installed.${NC}"
    exit 1
fi

if ! git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
    echo -e "${YELLOW}WARNING: Not in a git repository. Initializing...${NC}"
    git init
fi

# Check if global setup has been done
if [[ ! -f "$HOME/.claude/CLAUDE.md" ]]; then
    echo -e "${YELLOW}⚠ Global memory not set up. Run: $SCRIPT_DIR/setup.sh --global${NC}"
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"

directories=(
    ".claude/hooks"
    ".claude/rules"
    ".claude/commands/prd"
    ".claude/agents"
    "docs/prds"
    "docs/plans"
    "docs/solutions/build-errors"
    "docs/solutions/test-failures"
    "docs/solutions/runtime-errors"
    "docs/solutions/performance-issues"
    "docs/solutions/database-issues"
    "docs/solutions/security-issues"
    "docs/solutions/ui-bugs"
    "docs/solutions/integration-issues"
    "docs/solutions/logic-errors"
    "docs/solutions/patterns"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo -e "  ${GREEN}✓${NC} Created $dir"
    else
        echo -e "  ${BLUE}○${NC} $dir already exists"
    fi
done
echo ""

# Copy templates
echo -e "${YELLOW}Copying configuration files...${NC}"

# Main files — CLAUDE.md and CONTINUITY.md are NEVER overwritten (user content)
if [[ -f "CLAUDE.md" ]]; then
    echo -e "  ${BLUE}○${NC} CLAUDE.md already exists (never overwritten — user content)"
else
    copy_file "$SCRIPT_DIR/CLAUDE.template.md" "CLAUDE.md" "CLAUDE.md"
fi
if [[ -f "CONTINUITY.md" ]]; then
    echo -e "  ${BLUE}○${NC} CONTINUITY.md already exists (never overwritten — user content)"
else
    copy_file "$SCRIPT_DIR/CONTINUITY.template.md" "CONTINUITY.md" "CONTINUITY.md"
fi

# Settings — merge on upgrade, copy otherwise
if [[ "$UPGRADE" == true ]] && [[ -f ".claude/settings.json" ]]; then
    echo -e "  ${YELLOW}↑${NC} Merging .claude/settings.json (upgrade mode)"
    python3 "$SCRIPT_DIR/scripts/merge-settings.py" "$SCRIPT_DIR/settings/settings.template.json" ".claude/settings.json"
else
    copy_file "$SCRIPT_DIR/settings/settings.template.json" ".claude/settings.json" ".claude/settings.json"
fi

# MCP servers — merge on upgrade, copy otherwise
if [[ "$UPGRADE" == true ]] && [[ -f ".mcp.json" ]]; then
    echo -e "  ${YELLOW}↑${NC} Merging .mcp.json (upgrade mode)"
    python3 "$SCRIPT_DIR/scripts/merge-settings.py" "$SCRIPT_DIR/mcp.template.json" ".mcp.json"
else
    copy_file "$SCRIPT_DIR/mcp.template.json" ".mcp.json" ".mcp.json (MCP servers: Playwright + Context7)"
fi

# Hooks
copy_file "$SCRIPT_DIR/hooks/session-start.sh" ".claude/hooks/session-start.sh" ".claude/hooks/session-start.sh"
copy_file "$SCRIPT_DIR/hooks/check-state-updated.sh" ".claude/hooks/check-state-updated.sh" ".claude/hooks/check-state-updated.sh"
copy_file "$SCRIPT_DIR/hooks/post-tool-format.sh" ".claude/hooks/post-tool-format.sh" ".claude/hooks/post-tool-format.sh"
copy_file "$SCRIPT_DIR/hooks/pre-compact-memory.sh" ".claude/hooks/pre-compact-memory.sh" ".claude/hooks/pre-compact-memory.sh"
copy_file "$SCRIPT_DIR/hooks/check-config-change.sh" ".claude/hooks/check-config-change.sh" ".claude/hooks/check-config-change.sh"
copy_file "$SCRIPT_DIR/hooks/check-bash-safety.sh" ".claude/hooks/check-bash-safety.sh" ".claude/hooks/check-bash-safety.sh"
chmod +x .claude/hooks/session-start.sh 2>/dev/null || true
chmod +x .claude/hooks/check-state-updated.sh 2>/dev/null || true
chmod +x .claude/hooks/post-tool-format.sh 2>/dev/null || true
chmod +x .claude/hooks/pre-compact-memory.sh 2>/dev/null || true
chmod +x .claude/hooks/check-config-change.sh 2>/dev/null || true
chmod +x .claude/hooks/check-bash-safety.sh 2>/dev/null || true

# Agents
copy_file "$SCRIPT_DIR/agents/verify-app.md" ".claude/agents/verify-app.md" ".claude/agents/verify-app.md"

# Commands - Workflow (ENFORCED)
copy_file "$SCRIPT_DIR/commands/new-feature.md" ".claude/commands/new-feature.md" ".claude/commands/new-feature.md"
copy_file "$SCRIPT_DIR/commands/fix-bug.md" ".claude/commands/fix-bug.md" ".claude/commands/fix-bug.md"
copy_file "$SCRIPT_DIR/commands/quick-fix.md" ".claude/commands/quick-fix.md" ".claude/commands/quick-fix.md"
copy_file "$SCRIPT_DIR/commands/finish-branch.md" ".claude/commands/finish-branch.md" ".claude/commands/finish-branch.md"
copy_file "$SCRIPT_DIR/commands/codex.md" ".claude/commands/codex.md" ".claude/commands/codex.md"
copy_file "$SCRIPT_DIR/commands/review-pr-comments.md" ".claude/commands/review-pr-comments.md" ".claude/commands/review-pr-comments.md"

# Commands - PRD
copy_file "$SCRIPT_DIR/commands/prd/discuss.md" ".claude/commands/prd/discuss.md" ".claude/commands/prd/discuss.md"
copy_file "$SCRIPT_DIR/commands/prd/create.md" ".claude/commands/prd/create.md" ".claude/commands/prd/create.md"

# Rules based on tech stack
echo ""
echo -e "${YELLOW}Copying rules for ${TECH_STACK}...${NC}"

# Common rules (apply to all tech stacks)
common_rules=("security.md" "skill-audit.md" "api-design.md" "testing.md" "principles.md" "workflow.md" "worktree-policy.md" "critical-rules.md" "memory.md")
for rule in "${common_rules[@]}"; do
    copy_file "$SCRIPT_DIR/rules/$rule" ".claude/rules/$rule" ".claude/rules/$rule"
done

# Tech-specific rules
case $TECH_STACK in
    python)
        copy_file "$SCRIPT_DIR/rules/python-style.md" ".claude/rules/python-style.md" ".claude/rules/python-style.md"
        copy_file "$SCRIPT_DIR/rules/database.md" ".claude/rules/database.md" ".claude/rules/database.md"
        ;;
    typescript)
        copy_file "$SCRIPT_DIR/rules/typescript-style.md" ".claude/rules/typescript-style.md" ".claude/rules/typescript-style.md"
        copy_file "$SCRIPT_DIR/rules/frontend-design.md" ".claude/rules/frontend-design.md" ".claude/rules/frontend-design.md"
        ;;
    fullstack|*)
        copy_file "$SCRIPT_DIR/rules/python-style.md" ".claude/rules/python-style.md" ".claude/rules/python-style.md"
        copy_file "$SCRIPT_DIR/rules/typescript-style.md" ".claude/rules/typescript-style.md" ".claude/rules/typescript-style.md"
        copy_file "$SCRIPT_DIR/rules/database.md" ".claude/rules/database.md" ".claude/rules/database.md"
        copy_file "$SCRIPT_DIR/rules/frontend-design.md" ".claude/rules/frontend-design.md" ".claude/rules/frontend-design.md"
        ;;
esac

echo ""

# Create CHANGELOG if it doesn't exist
if [[ ! -f "docs/CHANGELOG.md" ]] || [[ "$FORCE" == true ]]; then
    echo -e "${YELLOW}Creating docs/CHANGELOG.md...${NC}"
    cat > docs/CHANGELOG.md << EOF
# Changelog

All notable changes to $PROJECT_NAME will be documented in this file.

## [Unreleased]

### Added
- Initial project setup with Claude Code configuration

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
    echo -e "  ${GREEN}✓${NC} Created docs/CHANGELOG.md"
else
    echo -e "  ${BLUE}○${NC} docs/CHANGELOG.md already exists"
fi

# Update CLAUDE.md with project name
if [[ -f "CLAUDE.md" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/\[Project Name\]/$PROJECT_NAME/g" CLAUDE.md
    else
        sed -i "s/\[Project Name\]/$PROJECT_NAME/g" CLAUDE.md
    fi
    echo -e "  ${GREEN}✓${NC} Updated CLAUDE.md with project name"
fi

echo ""
if [[ "$UPGRADE" == true ]]; then
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Upgrade Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${YELLOW}What was updated:${NC}"
    echo ""
    echo "  .claude/commands/        Workflow commands (refreshed)"
    echo "  .claude/hooks/           Hook scripts (refreshed)"
    echo "  .claude/rules/           Coding standards (refreshed)"
    echo "  .claude/agents/          Subagent definitions (refreshed)"
    echo "  .claude/settings.json    Hooks and permissions (merged — your customizations kept)"
    echo "  .mcp.json                MCP servers (merged — your customizations kept)"
    echo ""
    echo -e "${YELLOW}Not touched:${NC}"
    echo ""
    echo "  CLAUDE.md                Your project description (preserved)"
    echo "  CONTINUITY.md            Your task state (preserved)"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo ""
    echo -e "1. ${BLUE}Verify everything works${NC}:"
    echo ""
    echo "   /hooks       → Should show: SessionStart, Stop, PreToolUse, PostToolUse, PreCompact, SubagentStop, ConfigChange"
    echo "   /help        → Should show: /superpowers:*, /new-feature, /fix-bug, /prd:*"
    echo ""
    echo -e "2. ${BLUE}Commit and push${NC}:"
    echo ""
    echo "   git add .claude/ .mcp.json"
    echo "   git commit -m \"chore: upgrade Claude Code automation templates\""
    echo "   git push"
    echo ""
    echo -e "${GREEN}Upgrade done! Your CLAUDE.md and CONTINUITY.md were not modified.${NC}"
else
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Setup Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${YELLOW}What was created:${NC}"
    echo ""
    echo "  CLAUDE.md                Your project description (edit this!)"
    echo "  CONTINUITY.md            Task state that persists across sessions"
    echo "  .claude/settings.json    Hooks and permissions"
    echo "  .mcp.json                MCP servers (Playwright + Context7)"
    echo "  .claude/commands/        Workflow commands: /new-feature, /fix-bug, /quick-fix"
    echo "  .claude/hooks/           Auto-run scripts (format, verify, memory)"
    echo "  .claude/agents/          Subagent definitions (verify-app)"
    echo "  .claude/rules/           Coding standards + workflow rules (safe to update)"
    echo "  docs/                    Changelog, PRDs, solutions knowledge base"
    echo ""
    echo -e "${YELLOW}Plugins pre-enabled in .claude/settings.json:${NC}"
    echo ""
    echo "  - superpowers              (requires install — see step 3 below)"
    echo "  - pr-review-toolkit        (built-in, no install needed)"
    echo "  - frontend-design          (built-in, no install needed)"
    echo ""
    if [[ ! -f "$HOME/.claude/CLAUDE.md" ]]; then
        echo -e "${RED}┌──────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${RED}│  ⚠ IMPORTANT: Global memory not set up yet!                 │${NC}"
        echo -e "${RED}│                                                              │${NC}"
        echo -e "${RED}│  Without global setup:                                       │${NC}"
        echo -e "${RED}│  • Claude won't save learnings before context compression    │${NC}"
        echo -e "${RED}│  • /memory won't show your auto memory directory             │${NC}"
        echo -e "${RED}│  • Session knowledge will be lost on compaction              │${NC}"
        echo -e "${RED}│                                                              │${NC}"
        echo -e "${RED}│  Run: ${GREEN}$SCRIPT_DIR/setup.sh --global${RED}           │${NC}"
        echo -e "${RED}└──────────────────────────────────────────────────────────────┘${NC}"
        echo ""
    fi
    echo -e "${YELLOW}Next steps:${NC}"
    echo ""
    echo -e "1. ${BLUE}Edit CLAUDE.md${NC} — Fill in your project description, tech stack, and commands"
    echo "   (It's intentionally short — all rules live in .claude/rules/)"
    echo ""
    echo -e "2. ${BLUE}Edit CONTINUITY.md${NC} — Set your current goal and task state"
    echo ""
    echo -e "3. ${BLUE}Install the Superpowers plugin${NC} (one time):"
    echo ""
    echo "   claude"
    echo "   /plugin marketplace add obra/superpowers-marketplace"
    echo "   /plugin install superpowers@superpowers-marketplace"
    echo ""
    echo "   Then restart Claude Code."
    echo ""
    echo "   Note: pr-review-toolkit and frontend-design are built-in Claude Code plugins —"
    echo "   no install needed. /simplify is a built-in command. They're already"
    echo "   enabled in .claude/settings.json."
    echo ""
    echo -e "4. ${BLUE}Verify everything works${NC}:"
    echo ""
    echo "   /hooks       → Should show: SessionStart, Stop, PreToolUse, PostToolUse, PreCompact, SubagentStop, ConfigChange"
    echo "   /help        → Should show: /superpowers:*, /new-feature, /fix-bug, /prd:*"
    echo "   /memory      → Should show your auto memory directory"
    echo ""
    echo -e "5. ${BLUE}Commit and push${NC}:"
    echo ""
    echo "   git add .claude/ .mcp.json CLAUDE.md CONTINUITY.md docs/"
    echo "   git commit -m \"chore: add Claude Code automation setup\""
    echo "   git push"
    echo ""
    echo -e "${GREEN}You're ready! Run /new-feature <name> to start your first guided workflow.${NC}"
fi
