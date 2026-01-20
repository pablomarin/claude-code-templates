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
    echo "Set up Claude Code configuration for a project."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -p, --project NAME  Project name (default: directory name)"
    echo "  -t, --tech STACK    Tech stack: python, typescript, fullstack (default: fullstack)"
    echo "  -f, --force         Overwrite existing files"
    echo ""
    echo "Examples:"
    echo "  $0                          # Setup with defaults"
    echo "  $0 -p \"My Project\"          # Custom project name"
    echo "  $0 -t python                # Python-only project"
    echo "  $0 -f                       # Force overwrite existing files"
}

# Parse arguments
PROJECT_NAME=""
TECH_STACK="fullstack"
FORCE=false

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
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

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
    echo -e "${RED}ERROR: jq is required but not installed.${NC}"
    echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}ERROR: git is required but not installed.${NC}"
    exit 1
fi

if ! git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
    echo -e "${YELLOW}WARNING: Not in a git repository. Initializing...${NC}"
    git init
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

# Copy templates
echo -e "${YELLOW}Copying configuration files...${NC}"

# Main files (directly in SCRIPT_DIR, not in templates subfolder)
copy_file "$SCRIPT_DIR/CLAUDE.template.md" "CLAUDE.md" "CLAUDE.md"
copy_file "$SCRIPT_DIR/CONTINUITY.template.md" "CONTINUITY.md" "CONTINUITY.md"

# Settings
copy_file "$SCRIPT_DIR/settings/settings.template.json" ".claude/settings.json" ".claude/settings.json"

# Hooks
copy_file "$SCRIPT_DIR/hooks/check-state-updated.sh" ".claude/hooks/check-state-updated.sh" ".claude/hooks/check-state-updated.sh"
copy_file "$SCRIPT_DIR/hooks/post-tool-format.sh" ".claude/hooks/post-tool-format.sh" ".claude/hooks/post-tool-format.sh"
chmod +x .claude/hooks/check-state-updated.sh 2>/dev/null || true
chmod +x .claude/hooks/post-tool-format.sh 2>/dev/null || true

# Agents
copy_file "$SCRIPT_DIR/agents/verify-app.md" ".claude/agents/verify-app.md" ".claude/agents/verify-app.md"

# Commands - Workflow (ENFORCED)
copy_file "$SCRIPT_DIR/commands/new-feature.md" ".claude/commands/new-feature.md" ".claude/commands/new-feature.md"
copy_file "$SCRIPT_DIR/commands/fix-bug.md" ".claude/commands/fix-bug.md" ".claude/commands/fix-bug.md"
copy_file "$SCRIPT_DIR/commands/quick-fix.md" ".claude/commands/quick-fix.md" ".claude/commands/quick-fix.md"

# Commands - PRD
copy_file "$SCRIPT_DIR/commands/prd/discuss.md" ".claude/commands/prd/discuss.md" ".claude/commands/prd/discuss.md"
copy_file "$SCRIPT_DIR/commands/prd/create.md" ".claude/commands/prd/create.md" ".claude/commands/prd/create.md"

# Rules based on tech stack
echo ""
echo -e "${YELLOW}Copying rules for ${TECH_STACK}...${NC}"

# Common rules
common_rules=("security.md" "api-design.md" "testing.md")
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
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. ${BLUE}Edit CLAUDE.md${NC} to add:"
echo "   - Project description (What Is This?)"
echo "   - Tech stack details"
echo "   - File structure"
echo "   - Project-specific commands"
echo ""
echo "2. ${BLUE}Edit CONTINUITY.md${NC} to add:"
echo "   - Project goal"
echo "   - Constraints and assumptions"
echo "   - Current state (Done/Now/Next)"
echo ""
echo "3. ${BLUE}Start Claude Code${NC} and install plugins:"
echo ""
echo "   claude"
echo ""
echo "   # In Claude Code session:"
echo "   /plugin marketplace add obra/superpowers-marketplace"
echo "   /plugin install superpowers@superpowers-marketplace"
echo ""
echo "   /plugin marketplace add EveryInc/compound-engineering-plugin"
echo "   /plugin install compound-engineering@compound-engineering-plugin"
echo ""
echo "   /plugin install code-simplifier"
echo ""
echo "4. ${BLUE}Verify setup${NC}:"
echo "   /hooks      # Should show SessionStart, Stop, SubagentStop, PostToolUse"
echo "   /permissions # Should show pre-allowed commands"
echo "   /help       # Should show /superpowers:*, /workflows:*, /prd:*"
echo ""
echo "5. ${BLUE}Commit the new files${NC}:"
echo "   git add .claude/ CLAUDE.md CONTINUITY.md docs/"
echo "   git commit -m \"chore: add Claude Code automation setup\""
echo "   git push"
echo ""
echo -e "${GREEN}Happy coding with Claude!${NC}"
