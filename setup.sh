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
    echo "  -f, --force         Overwrite existing files"
    echo "  -g, --global        Set up global memory system (~/.claude/)"
    echo ""
    echo "Examples:"
    echo "  $0                          # Setup with defaults"
    echo "  $0 -p \"My Project\"          # Custom project name"
    echo "  $0 -t python                # Python-only project"
    echo "  $0 -f                       # Force overwrite existing files"
    echo "  $0 --global                 # Set up global memory (run once per machine)"
    echo "  $0 --global -f              # Force overwrite global settings"
}

# Parse arguments
PROJECT_NAME=""
TECH_STACK="fullstack"
FORCE=false
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

    # Merge global settings (hooks only - don't override user's existing permissions/plugins)
    GLOBAL_SETTINGS="$HOME/.claude/settings.json"
    if [[ -f "$GLOBAL_SETTINGS" ]] && [[ "$FORCE" != true ]]; then
        echo -e "  ${BLUE}○${NC} ~/.claude/settings.json already exists (use -f to overwrite)"
        echo -e "  ${YELLOW}  TIP: Manually merge hooks from settings/global-settings.template.json${NC}"
    else
        copy_file "$SCRIPT_DIR/settings/global-settings.template.json" "$GLOBAL_SETTINGS" "~/.claude/settings.json (global hooks)"
    fi

    # Enable auto memory
    echo ""
    echo -e "${YELLOW}Step 3: Enabling auto memory...${NC}"
    echo "  This lets Claude save learnings to persistent memory files."

    # Check if auto memory env var is set in shell profile
    SHELL_RC=""
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        if grep -q "CLAUDE_CODE_DISABLE_AUTO_MEMORY" "$SHELL_RC" 2>/dev/null; then
            echo -e "  ${BLUE}○${NC} Auto memory env var already in $SHELL_RC"
        else
            echo "" >> "$SHELL_RC"
            echo "# Claude Code: Enable auto memory across sessions" >> "$SHELL_RC"
            echo "export CLAUDE_CODE_DISABLE_AUTO_MEMORY=0" >> "$SHELL_RC"
            echo -e "  ${GREEN}✓${NC} Added CLAUDE_CODE_DISABLE_AUTO_MEMORY=0 to $SHELL_RC"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} Could not find .zshrc or .bashrc. Manually add:"
        echo "     export CLAUDE_CODE_DISABLE_AUTO_MEMORY=0"
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
    echo ""
    echo -e "${YELLOW}What this means:${NC}"
    echo ""
    echo "  Claude will now:"
    echo "  - Save bug fixes, patterns, and preferences to persistent memory"
    echo "  - Automatically preserve learnings before context compression"
    echo "  - Load its memory at the start of every session"
    echo "  - Get smarter over time as it accumulates project knowledge"
    echo ""
    echo -e "${YELLOW}IMPORTANT — Reload your shell now:${NC}"
    echo ""
    echo -e "  ${GREEN}source $SHELL_RC${NC}"
    echo ""
    echo -e "${YELLOW}Then set up your first project:${NC}"
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
    echo -e "  ${YELLOW}⚠${NC} jq not found. Hooks will work with reduced features."
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

# Main files (directly in SCRIPT_DIR, not in templates subfolder)
copy_file "$SCRIPT_DIR/CLAUDE.template.md" "CLAUDE.md" "CLAUDE.md"
copy_file "$SCRIPT_DIR/CONTINUITY.template.md" "CONTINUITY.md" "CONTINUITY.md"

# Settings
copy_file "$SCRIPT_DIR/settings/settings.template.json" ".claude/settings.json" ".claude/settings.json"

# MCP servers (MUST be at project root as .mcp.json — .claude/settings.json ignores mcpServers)
copy_file "$SCRIPT_DIR/mcp.template.json" ".mcp.json" ".mcp.json (MCP servers: Playwright + Context7)"

# Hooks
copy_file "$SCRIPT_DIR/hooks/check-state-updated.sh" ".claude/hooks/check-state-updated.sh" ".claude/hooks/check-state-updated.sh"
copy_file "$SCRIPT_DIR/hooks/post-tool-format.sh" ".claude/hooks/post-tool-format.sh" ".claude/hooks/post-tool-format.sh"
copy_file "$SCRIPT_DIR/hooks/pre-compact-memory.sh" ".claude/hooks/pre-compact-memory.sh" ".claude/hooks/pre-compact-memory.sh"
chmod +x .claude/hooks/check-state-updated.sh 2>/dev/null || true
chmod +x .claude/hooks/post-tool-format.sh 2>/dev/null || true
chmod +x .claude/hooks/pre-compact-memory.sh 2>/dev/null || true

# Agents
copy_file "$SCRIPT_DIR/agents/verify-app.md" ".claude/agents/verify-app.md" ".claude/agents/verify-app.md"

# Commands - Workflow (ENFORCED)
copy_file "$SCRIPT_DIR/commands/new-feature.md" ".claude/commands/new-feature.md" ".claude/commands/new-feature.md"
copy_file "$SCRIPT_DIR/commands/fix-bug.md" ".claude/commands/fix-bug.md" ".claude/commands/fix-bug.md"
copy_file "$SCRIPT_DIR/commands/quick-fix.md" ".claude/commands/quick-fix.md" ".claude/commands/quick-fix.md"
copy_file "$SCRIPT_DIR/commands/finish-branch.md" ".claude/commands/finish-branch.md" ".claude/commands/finish-branch.md"
copy_file "$SCRIPT_DIR/commands/codex.md" ".claude/commands/codex.md" ".claude/commands/codex.md"

# Commands - PRD
copy_file "$SCRIPT_DIR/commands/prd/discuss.md" ".claude/commands/prd/discuss.md" ".claude/commands/prd/discuss.md"
copy_file "$SCRIPT_DIR/commands/prd/create.md" ".claude/commands/prd/create.md" ".claude/commands/prd/create.md"

# Rules based on tech stack
echo ""
echo -e "${YELLOW}Copying rules for ${TECH_STACK}...${NC}"

# Common rules (apply to all tech stacks)
common_rules=("security.md" "api-design.md" "testing.md" "principles.md" "workflow.md" "worktree-policy.md" "critical-rules.md" "memory.md")
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
        ;;
    fullstack|*)
        copy_file "$SCRIPT_DIR/rules/python-style.md" ".claude/rules/python-style.md" ".claude/rules/python-style.md"
        copy_file "$SCRIPT_DIR/rules/typescript-style.md" ".claude/rules/typescript-style.md" ".claude/rules/typescript-style.md"
        copy_file "$SCRIPT_DIR/rules/database.md" ".claude/rules/database.md" ".claude/rules/database.md"
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
if [[ ! -f "$HOME/.claude/CLAUDE.md" ]]; then
    echo -e "${RED}⚠ IMPORTANT: Global memory not set up yet!${NC}"
    echo ""
    echo "  Run this first (once per machine):"
    echo -e "  ${GREEN}$SCRIPT_DIR/setup.sh --global${NC}"
    echo ""
    echo "  Without global setup, Claude won't persist learnings across sessions."
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
echo "   Note: code-review, pr-review-toolkit, and code-simplifier are"
echo "   built-in Claude Code plugins — no install needed. They're already"
echo "   enabled in .claude/settings.json."
echo ""
echo -e "4. ${BLUE}Verify everything works${NC}:"
echo ""
echo "   /hooks       → Should show: SessionStart, Stop, PreCompact, SubagentStop, PostToolUse"
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
