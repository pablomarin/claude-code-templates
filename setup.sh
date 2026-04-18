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
    echo "  -w, --with-playwright  Install Playwright framework templates (requires -t fullstack or typescript)"
    echo "  --playwright-dir DIR   Scaffold Playwright into DIR instead of repo root (monorepo layouts)"
    echo "                         If omitted: auto-detect frontend/apps/web/web/client if exactly one matches"
    echo ""
    echo "Examples:"
    echo "  $0                          # Setup with defaults"
    echo "  $0 -p \"My Project\"          # Custom project name"
    echo "  $0 -t python                # Python-only project"
    echo "  $0 -f                       # Force overwrite existing files"
    echo "  $0 --upgrade                # Upgrade: add new hooks/rules, merge settings"
    echo "  $0 --global                 # Set up global memory (run once per machine)"
    echo "  $0 --global -f              # Force overwrite global settings"
    echo "  $0 -t fullstack --with-playwright  # Install Playwright framework templates"
}

# Parse arguments
PROJECT_NAME=""
TECH_STACK="fullstack"
FORCE=false
UPGRADE=false
GLOBAL=false
WITH_PLAYWRIGHT=false

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
        -w|--with-playwright)
            WITH_PLAYWRIGHT=true
            shift
            ;;
        --playwright-dir)
            PLAYWRIGHT_DIR="$2"
            shift 2
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

# Validate --with-playwright flag
if [[ "$WITH_PLAYWRIGHT" == true ]]; then
    if [[ "$TECH_STACK" != "fullstack" && "$TECH_STACK" != "typescript" ]]; then
        echo -e "${RED}ERROR: --with-playwright requires -t fullstack or -t typescript.${NC}"
        echo -e "${YELLOW}Playwright framework only applies to web/TS projects.${NC}"
        exit 1
    fi
fi

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
    ".claude/skills/ui-design/references"
    ".claude/skills/generate-image"
    ".claude/skills/release"
    ".claude/skills/council/references"
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
    "docs/research"
    "tests/e2e/use-cases"
    "tests/e2e/reports"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo -e "  ${GREEN}✓${NC} Created $dir"
    else
        echo -e "  ${BLUE}○${NC} $dir already exists"
    fi
done

# E2E reports are ephemeral — ignore everything except this gitignore itself.
if [[ ! -f "tests/e2e/reports/.gitignore" ]]; then
    cat > tests/e2e/reports/.gitignore << 'EOF'
*
!.gitignore
EOF
    echo -e "  ${GREEN}✓${NC} Created tests/e2e/reports/.gitignore (reports are ephemeral)"
fi
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
copy_file "$SCRIPT_DIR/hooks/check-workflow-gates.sh" ".claude/hooks/check-workflow-gates.sh" ".claude/hooks/check-workflow-gates.sh"
chmod +x .claude/hooks/session-start.sh 2>/dev/null || true
chmod +x .claude/hooks/check-state-updated.sh 2>/dev/null || true
chmod +x .claude/hooks/post-tool-format.sh 2>/dev/null || true
chmod +x .claude/hooks/pre-compact-memory.sh 2>/dev/null || true
chmod +x .claude/hooks/check-config-change.sh 2>/dev/null || true
chmod +x .claude/hooks/check-bash-safety.sh 2>/dev/null || true
chmod +x .claude/hooks/check-workflow-gates.sh 2>/dev/null || true

# Agents
copy_file "$SCRIPT_DIR/agents/verify-app.md" ".claude/agents/verify-app.md" ".claude/agents/verify-app.md"
copy_file "$SCRIPT_DIR/agents/verify-e2e.md" ".claude/agents/verify-e2e.md" ".claude/agents/verify-e2e.md"
copy_file "$SCRIPT_DIR/agents/council-advisor.md" ".claude/agents/council-advisor.md" ".claude/agents/council-advisor.md"
copy_file "$SCRIPT_DIR/agents/research-first.md" ".claude/agents/research-first.md" ".claude/agents/research-first.md"

# Skills (tech-agnostic)
copy_file "$SCRIPT_DIR/skills/release/SKILL.template.md" ".claude/skills/release/SKILL.md" ".claude/skills/release/SKILL.md"

# Engineering Council skill (tech-agnostic) — multi-perspective decision analysis
copy_file "$SCRIPT_DIR/skills/council/SKILL.template.md" ".claude/skills/council/SKILL.md" ".claude/skills/council/SKILL.md"
copy_file "$SCRIPT_DIR/skills/council/references/advisors.md" ".claude/skills/council/references/advisors.md" ".claude/skills/council/references/advisors.md"
copy_file "$SCRIPT_DIR/skills/council/references/output-schema.md" ".claude/skills/council/references/output-schema.md" ".claude/skills/council/references/output-schema.md"
copy_file "$SCRIPT_DIR/skills/council/references/peer-review-protocol.md" ".claude/skills/council/references/peer-review-protocol.md" ".claude/skills/council/references/peer-review-protocol.md"

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
        # UI Design skill (auto-triggers for frontend work) — all 10 references
        copy_file "$SCRIPT_DIR/skills/ui-design/SKILL.template.md" ".claude/skills/ui-design/SKILL.md" ".claude/skills/ui-design/SKILL.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/animation-techniques.md" ".claude/skills/ui-design/references/animation-techniques.md" ".claude/skills/ui-design/references/animation-techniques.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/typography-and-color.md" ".claude/skills/ui-design/references/typography-and-color.md" ".claude/skills/ui-design/references/typography-and-color.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/polish-checklist.md" ".claude/skills/ui-design/references/polish-checklist.md" ".claude/skills/ui-design/references/polish-checklist.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/media-assets.md" ".claude/skills/ui-design/references/media-assets.md" ".claude/skills/ui-design/references/media-assets.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/industry-design-guide.md" ".claude/skills/ui-design/references/industry-design-guide.md" ".claude/skills/ui-design/references/industry-design-guide.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/ux-antipatterns.md" ".claude/skills/ui-design/references/ux-antipatterns.md" ".claude/skills/ui-design/references/ux-antipatterns.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/landing-patterns.md" ".claude/skills/ui-design/references/landing-patterns.md" ".claude/skills/ui-design/references/landing-patterns.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/21st-dev-components.md" ".claude/skills/ui-design/references/21st-dev-components.md" ".claude/skills/ui-design/references/21st-dev-components.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/product-ui-patterns.md" ".claude/skills/ui-design/references/product-ui-patterns.md" ".claude/skills/ui-design/references/product-ui-patterns.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/trust-first-patterns.md" ".claude/skills/ui-design/references/trust-first-patterns.md" ".claude/skills/ui-design/references/trust-first-patterns.md"
        # Image generation skill (Gemini API — checks docs for current model)
        copy_file "$SCRIPT_DIR/skills/generate-image/SKILL.template.md" ".claude/skills/generate-image/SKILL.md" ".claude/skills/generate-image/SKILL.md"
        ;;
    fullstack|*)
        copy_file "$SCRIPT_DIR/rules/python-style.md" ".claude/rules/python-style.md" ".claude/rules/python-style.md"
        copy_file "$SCRIPT_DIR/rules/typescript-style.md" ".claude/rules/typescript-style.md" ".claude/rules/typescript-style.md"
        copy_file "$SCRIPT_DIR/rules/database.md" ".claude/rules/database.md" ".claude/rules/database.md"
        copy_file "$SCRIPT_DIR/rules/frontend-design.md" ".claude/rules/frontend-design.md" ".claude/rules/frontend-design.md"
        # UI Design skill (auto-triggers for frontend work) — all 10 references
        copy_file "$SCRIPT_DIR/skills/ui-design/SKILL.template.md" ".claude/skills/ui-design/SKILL.md" ".claude/skills/ui-design/SKILL.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/animation-techniques.md" ".claude/skills/ui-design/references/animation-techniques.md" ".claude/skills/ui-design/references/animation-techniques.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/typography-and-color.md" ".claude/skills/ui-design/references/typography-and-color.md" ".claude/skills/ui-design/references/typography-and-color.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/polish-checklist.md" ".claude/skills/ui-design/references/polish-checklist.md" ".claude/skills/ui-design/references/polish-checklist.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/media-assets.md" ".claude/skills/ui-design/references/media-assets.md" ".claude/skills/ui-design/references/media-assets.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/industry-design-guide.md" ".claude/skills/ui-design/references/industry-design-guide.md" ".claude/skills/ui-design/references/industry-design-guide.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/ux-antipatterns.md" ".claude/skills/ui-design/references/ux-antipatterns.md" ".claude/skills/ui-design/references/ux-antipatterns.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/landing-patterns.md" ".claude/skills/ui-design/references/landing-patterns.md" ".claude/skills/ui-design/references/landing-patterns.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/21st-dev-components.md" ".claude/skills/ui-design/references/21st-dev-components.md" ".claude/skills/ui-design/references/21st-dev-components.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/product-ui-patterns.md" ".claude/skills/ui-design/references/product-ui-patterns.md" ".claude/skills/ui-design/references/product-ui-patterns.md"
        copy_file "$SCRIPT_DIR/skills/ui-design/references/trust-first-patterns.md" ".claude/skills/ui-design/references/trust-first-patterns.md" ".claude/skills/ui-design/references/trust-first-patterns.md"
        # Image generation skill (Gemini API — checks docs for current model)
        copy_file "$SCRIPT_DIR/skills/generate-image/SKILL.template.md" ".claude/skills/generate-image/SKILL.md" ".claude/skills/generate-image/SKILL.md"
        ;;
esac

# Playwright framework templates (opt-in via --with-playwright)
if [[ "$WITH_PLAYWRIGHT" == true ]]; then
    echo ""
    echo -e "${YELLOW}Installing Playwright framework templates...${NC}"

    # ------------------------------------------------------------------
    # Determine where Playwright lives.
    # Monorepos typically have package.json inside a frontend subdirectory
    # (frontend/, apps/web/, web/, client/). Flat repos have it at root.
    # We keep them as two separate concepts:
    #   - PW_DIR:     where playwright.config.ts + tests/e2e/ get scaffolded
    #   - PW_PKG_DIR: where `pnpm install` / `pnpm exec playwright` run
    # In most layouts PW_DIR == PW_PKG_DIR. If a user has an unusual
    # pnpm-workspace setup, they can override with --playwright-dir.
    # ------------------------------------------------------------------
    if [[ -n "$PLAYWRIGHT_DIR" ]]; then
        PW_DIR="$PLAYWRIGHT_DIR"
        echo -e "  ${BLUE}→${NC} Using explicit --playwright-dir: ${BLUE}$PW_DIR${NC}"
    else
        # Auto-detect: ONLY commit to a subdir if exactly one candidate matches.
        # Ambiguous detections (multiple apps) fall back to repo root with a warning.
        PW_CANDIDATES=()
        for candidate in frontend apps/web web client; do
            if [[ -f "$candidate/package.json" ]]; then
                PW_CANDIDATES+=("$candidate")
            fi
        done

        if [[ ${#PW_CANDIDATES[@]} -eq 1 ]]; then
            PW_DIR="${PW_CANDIDATES[0]}"
            echo -e "  ${GREEN}✓${NC} Detected frontend at ${BLUE}$PW_DIR${NC} — scaffolding Playwright there."
            echo -e "    (override with ${BLUE}--playwright-dir <path>${NC} if that's wrong)"
        elif [[ ${#PW_CANDIDATES[@]} -gt 1 ]]; then
            echo -e "  ${YELLOW}⚠${NC}  Multiple frontend candidates found: ${PW_CANDIDATES[*]}"
            echo -e "     Scaffolding at repo root to avoid picking wrong. Override with ${BLUE}--playwright-dir <path>${NC}."
            PW_DIR="."
        else
            PW_DIR="."
            echo -e "  ${BLUE}→${NC} No frontend subdirectory detected — scaffolding at repo root."
        fi
    fi

    # Create the target dir if it doesn't exist (explicit --playwright-dir may point to a new path)
    if [[ "$PW_DIR" != "." ]] && [[ ! -d "$PW_DIR" ]]; then
        mkdir -p "$PW_DIR"
        echo -e "  ${GREEN}✓${NC} Created $PW_DIR/"
    fi

    # All Playwright paths are relative to PW_DIR
    PW_SPECS_DIR="$PW_DIR/tests/e2e/specs"
    PW_FIXTURES_DIR="$PW_DIR/tests/e2e/fixtures"
    PW_AUTH_DIR="$PW_DIR/tests/e2e/.auth"

    if [[ ! -d "$PW_SPECS_DIR" ]]; then
        mkdir -p "$PW_SPECS_DIR"
        echo -e "  ${GREEN}✓${NC} Created $PW_SPECS_DIR (for graduated .spec.ts files)"
    fi

    # Playwright config
    copy_file "$SCRIPT_DIR/templates/playwright/playwright.config.template.ts" "$PW_DIR/playwright.config.ts" "$PW_DIR/playwright.config.ts"

    # Auth fixture
    mkdir -p "$PW_FIXTURES_DIR"
    copy_file "$SCRIPT_DIR/templates/playwright/auth.fixture.template.ts" "$PW_FIXTURES_DIR/auth.ts" "$PW_FIXTURES_DIR/auth.ts"

    # Auth storage directory — gitignored because it contains credentials
    mkdir -p "$PW_AUTH_DIR"
    if [[ ! -f "$PW_AUTH_DIR/.gitignore" ]]; then
        cat > "$PW_AUTH_DIR/.gitignore" << 'EOF'
# Auth storage state contains credentials - never commit
*
!.gitignore
EOF
        echo -e "  ${GREEN}✓${NC} Created $PW_AUTH_DIR/.gitignore (credentials protected)"
    fi

    # Persist the chosen PW_DIR so workflow commands (new-feature, fix-bug) can
    # pick it up in Phase 5.4b framework detection and dep-install loops.
    # Falls back to repo root via candidate list if this marker file is missing.
    mkdir -p .claude
    echo "$PW_DIR" > .claude/playwright-dir
    echo -e "  ${GREEN}✓${NC} Recorded Playwright dir in .claude/playwright-dir ($PW_DIR)"

    # CI workflow reference (NOT auto-activated).
    # Stamp PW_DIR into the workflow so defaults.run.working-directory matches
    # the actual scaffold location. Two important subtleties:
    # (1) Use awk with -v so metacharacters in user paths (&, |, \) are
    #     treated as literal text — NOT as sed replacement-string specials.
    # (2) Preserve user-edited files on non-force reruns (matches copy_file
    #     semantics). setup.sh --with-playwright should be idempotent; a
    #     second run without -f must not clobber CI customizations.
    stamp_ci_template() {
        local src="$1" dest="$2" desc="$3"
        [[ ! -f "$src" ]] && return 0
        if [[ -f "$dest" ]] && [[ "$FORCE" != true ]]; then
            echo -e "  ${BLUE}○${NC} $desc already exists (use -f to overwrite)"
            return 0
        fi
        awk -v replacement="$PW_DIR" \
            '{ gsub(/__PLAYWRIGHT_DIR__/, replacement); print }' \
            "$src" > "$dest"
        echo -e "  ${GREEN}✓${NC} Created $desc (working-directory stamped: $PW_DIR)"
    }

    mkdir -p docs/ci-templates
    stamp_ci_template "$SCRIPT_DIR/templates/ci-workflows/e2e.yml" "docs/ci-templates/e2e.yml" "docs/ci-templates/e2e.yml"
    stamp_ci_template "$SCRIPT_DIR/templates/ci-workflows/README.md" "docs/ci-templates/README.md" "docs/ci-templates/README.md"

    # Show the right commands in the next-steps summary based on PW_DIR
    if [[ "$PW_DIR" == "." ]]; then
        CD_HINT=""
        PW_RUN="pnpm exec playwright test"
    else
        CD_HINT="cd $PW_DIR && "
        PW_RUN="cd $PW_DIR && pnpm exec playwright test"
    fi

    echo ""
    echo -e "${GREEN}✓ Playwright templates installed into ${BLUE}$PW_DIR${GREEN}.${NC}"
    echo -e "${YELLOW}Next steps to complete Playwright setup:${NC}"
    echo -e "  1. Install the framework: ${BLUE}${CD_HINT}pnpm add -D @playwright/test${NC}"
    echo -e "     (or npm: ${BLUE}${CD_HINT}npm install --save-dev @playwright/test${NC})"
    echo -e "  2. Install browsers:      ${BLUE}${CD_HINT}pnpm exec playwright install${NC}"
    echo -e "  3. Review ${BLUE}$PW_DIR/playwright.config.ts${NC} — set baseURL and uncomment webServer if needed"
    echo -e "  4. (Optional) Activate CI:"
    echo -e "     ${BLUE}mkdir -p .github/workflows && cp docs/ci-templates/e2e.yml .github/workflows/e2e.yml${NC}"
    echo -e "     Note: CI template uses pnpm with working-directory=$PW_DIR — adjust in .github/workflows/e2e.yml if needed"
    echo -e "  5. Configure auth via env vars: TEST_USER_EMAIL + TEST_USER_PASSWORD (preferred)"
    echo -e "     TEST_API_KEY is supported but insecure — see tests/e2e/fixtures/auth.ts"
    echo -e "  6. Run tests: ${BLUE}$PW_RUN${NC}"
fi

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
    echo "  .claude/skills/          Skills (release, council, ui-design if typescript/fullstack)"
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
    echo "  .claude/agents/          Subagent definitions (verify-app, verify-e2e)"
    echo "  .claude/skills/           Skills (release, council, ui-design if typescript/fullstack)"
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
