# ============================================================================
# Claude Code Project Setup Script (PowerShell)
# Company-wide template for consistent AI-assisted development workflow
# ============================================================================

param(
    [Alias("h")]
    [switch]$Help,

    [Alias("p")]
    [string]$Project = "",

    [Alias("t")]
    [ValidateSet("python", "typescript", "fullstack")]
    [string]$Tech = "fullstack",

    [Alias("f")]
    [switch]$Force,

    [Alias("u")]
    [switch]$Upgrade,

    [Alias("g")]
    [switch]$Global,

    [Alias("w")]
    [switch]$WithPlaywright
)

# Upgrade implies force for hooks/commands/rules
if ($Upgrade) { $Force = $true }

# Script directory (where templates live)
$ScriptDir = $PSScriptRoot

# Colors function
function Write-Color {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

# Usage
function Show-Usage {
    Write-Host "Usage: .\setup.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Set up Claude Code configuration for a project or globally."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -h, -Help           Show this help message"
    Write-Host "  -p, -Project NAME   Project name (default: directory name)"
    Write-Host "  -t, -Tech STACK     Tech stack: python, typescript, fullstack (default: fullstack)"
    Write-Host "  -f, -Force          Overwrite existing files"
    Write-Host "  -g, -Global         Set up global memory system (~/.claude/)"
    Write-Host "  -w, -WithPlaywright Install Playwright framework templates (requires -Tech fullstack or typescript)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup.ps1                          # Setup with defaults"
    Write-Host "  .\setup.ps1 -p `"My Project`"          # Custom project name"
    Write-Host "  .\setup.ps1 -t python                # Python-only project"
    Write-Host "  .\setup.ps1 -f                       # Force overwrite existing files"
    Write-Host "  .\setup.ps1 -Global                  # Set up global memory (run once per machine)"
    Write-Host "  .\setup.ps1 -Global -f               # Force overwrite global settings"
    Write-Host "  .\setup.ps1 -Tech fullstack -WithPlaywright  # Install Playwright framework templates"
}

# Show help if requested
if ($Help) {
    Show-Usage
    exit 0
}

# Copy function with force check
function Copy-TemplateFile {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )

    if (-not (Test-Path $Source)) {
        Write-Host "  " -NoNewline
        Write-Color "x" "Red"
        Write-Host " Template not found: $Source"
        return
    }

    if ((Test-Path $Destination) -and (-not $Force)) {
        Write-Host "  " -NoNewline
        Write-Color "o" "Blue"
        Write-Host " $Description already exists (use -f to overwrite)"
        return
    }

    # Ensure parent directory exists
    $parentDir = Split-Path -Parent $Destination
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    Copy-Item -Path $Source -Destination $Destination -Force
    Write-Host "  " -NoNewline
    Write-Color "+" "Green"
    Write-Host " Created $Description"
}

# ============================================================================
# GLOBAL SETUP (-Global flag)
# ============================================================================
if ($Global) {
    Write-Color "============================================" "Blue"
    Write-Color "  Claude Code Global Setup" "Blue"
    Write-Color "============================================" "Blue"
    Write-Host ""
    Write-Host "This sets up Claude Code's memory system for " -NoNewline
    Write-Color "ALL" "Green"
    Write-Host " your projects."
    Write-Host "After this, Claude will remember learnings across sessions and projects."
    Write-Host ""

    # Create global directories
    Write-Color "Step 1: Creating global directories..." "Yellow"

    $globalDirs = @(
        (Join-Path $HOME ".claude"),
        (Join-Path (Join-Path $HOME ".claude") "hooks"),
        (Join-Path (Join-Path $HOME ".claude") "rules")
    )

    foreach ($dir in $globalDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  " -NoNewline
            Write-Color "+" "Green"
            Write-Host " Created $dir"
        }
        else {
            Write-Host "  " -NoNewline
            Write-Color "o" "Blue"
            Write-Host " $dir already exists"
        }
    }
    Write-Host ""

    # Copy global CLAUDE.md
    Write-Color "Step 2: Installing global configuration..." "Yellow"
    Write-Host "  These files tell Claude how to manage its memory."
    Copy-TemplateFile (Join-Path $ScriptDir "GLOBAL-CLAUDE.template.md") (Join-Path (Join-Path $HOME ".claude") "CLAUDE.md") "~\.claude\CLAUDE.md (global instructions)"

    # Copy global hooks
    Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "pre-compact-memory.ps1") (Join-Path (Join-Path (Join-Path $HOME ".claude") "hooks") "pre-compact-memory.ps1") "~\.claude\hooks\pre-compact-memory.ps1"

    # Merge global hooks into existing settings (preserves user's plugins, statusLine, etc.)
    $globalSettings = Join-Path (Join-Path $HOME ".claude") "settings.json"
    $templateSettings = Join-Path (Join-Path $ScriptDir "settings") "global-settings.template.json"
    if (Test-Path $globalSettings) {
        try {
            $existing = Get-Content $globalSettings -Raw | ConvertFrom-Json
            $template = Get-Content $templateSettings -Raw | ConvertFrom-Json
            # Merge just the hooks key, preserving everything else
            $existing | Add-Member -MemberType NoteProperty -Name "hooks" -Value $template.hooks -Force
            $existing | ConvertTo-Json -Depth 10 | Set-Content $globalSettings -Encoding UTF8
            Write-Host "  " -NoNewline
            Write-Color "+" "Green"
            Write-Host " Merged hooks into existing ~\.claude\settings.json (your settings preserved)"
        }
        catch {
            Write-Host "  " -NoNewline
            Write-Color "!" "Yellow"
            Write-Host " Could not merge hooks. Manually add hooks from:"
            Write-Host "    $templateSettings"
        }
    }
    else {
        Copy-TemplateFile $templateSettings $globalSettings "~\.claude\settings.json (global hooks)"
    }

    Write-Host ""
    Write-Color "============================================" "Green"
    Write-Color "  Global Setup Complete!" "Green"
    Write-Color "============================================" "Green"
    Write-Host ""
    Write-Color "What was created:" "Yellow"
    Write-Host ""
    Write-Host "  ~\.claude\CLAUDE.md         Instructions that tell Claude how to use its memory"
    Write-Host "  ~\.claude\settings.json     Hooks that auto-save learnings before context loss"
    Write-Host "  ~\.claude\hooks\            Scripts that provide context to memory hooks"
    Write-Host "  ~\.claude\rules\            Personal rules that apply to all your projects"
    Write-Host ""
    Write-Color "What this means:" "Yellow"
    Write-Host ""
    Write-Host "  Claude will now:"
    Write-Host "  - Save bug fixes, patterns, and preferences to persistent memory"
    Write-Host "  - Automatically preserve learnings before context compression"
    Write-Host "  - Load its memory at the start of every session"
    Write-Host "  - Get smarter over time as it accumulates project knowledge"
    Write-Host ""
    Write-Color "Now set up your first project:" "Yellow"
    Write-Host ""
    Write-Host "  cd C:\your\project"
    Write-Host "  & $ScriptDir\setup.ps1 -p `"Project Name`""
    Write-Host ""
    exit 0
}

# ============================================================================
# PROJECT SETUP (default, no -Global flag)
# ============================================================================

# Validate -WithPlaywright flag
if ($WithPlaywright) {
    if ($Tech -ne "fullstack" -and $Tech -ne "typescript") {
        Write-Color "ERROR: -WithPlaywright requires -Tech fullstack or -Tech typescript." "Red"
        Write-Color "Playwright framework only applies to web/TS projects." "Yellow"
        exit 1
    }
}

# Default project name to directory name
if ([string]::IsNullOrEmpty($Project)) {
    $Project = Split-Path -Leaf (Get-Location)
}

Write-Color "============================================" "Blue"
Write-Color "  Claude Code Setup for: $Project" "Green"
Write-Color "  Tech Stack: $Tech" "Green"
Write-Color "============================================" "Blue"
Write-Host ""

# Check prerequisites
Write-Color "Checking prerequisites..." "Yellow"

# Check for git
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    Write-Color "ERROR: git is required but not installed." "Red"
    exit 1
}

# Check if in git repository
$isGitRepo = git rev-parse --is-inside-work-tree 2>$null
if (-not $isGitRepo) {
    Write-Color "WARNING: Not in a git repository. Initializing..." "Yellow"
    git init
}

# Check if global setup has been done
$globalClaude = Join-Path (Join-Path $HOME ".claude") "CLAUDE.md"
if (-not (Test-Path $globalClaude)) {
    Write-Color "Warning: Global memory not set up. Run: & $ScriptDir\setup.ps1 -Global" "Yellow"
}

Write-Host "  " -NoNewline
Write-Color "+" "Green"
Write-Host " Prerequisites OK"
Write-Host ""

# Configure git for Windows long paths
# This is required for worktrees in projects with deeply nested file structures
Write-Color "Configuring git for Windows long paths..." "Yellow"

$longPathsEnabled = git config --get core.longpaths 2>$null
if ($longPathsEnabled -ne "true") {
    git config core.longpaths true
    Write-Host "  " -NoNewline
    Write-Color "+" "Green"
    Write-Host " Enabled core.longpaths for this repository"
    Write-Host ""
    Write-Color "NOTE: If you have very long file paths (>260 chars), you may also need to:" "Yellow"
    Write-Host "  1. Run as Admin: " -NoNewline
    Write-Color "New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force" "Cyan"
    Write-Host "  2. Or enable via Group Policy: Computer Configuration > Administrative Templates > System > Filesystem > Enable Win32 long paths"
    Write-Host ""
}
else {
    Write-Host "  " -NoNewline
    Write-Color "o" "Blue"
    Write-Host " core.longpaths already enabled"
}
Write-Host ""

# Create directory structure
Write-Color "Creating directory structure..." "Yellow"

$directories = @(
    ".claude\hooks",
    ".claude\rules",
    ".claude\commands\prd",
    ".claude\agents",
    "docs\prds",
    "docs\plans",
    "docs\solutions\build-errors",
    "docs\solutions\test-failures",
    "docs\solutions\runtime-errors",
    "docs\solutions\performance-issues",
    "docs\solutions\database-issues",
    "docs\solutions\security-issues",
    "docs\solutions\ui-bugs",
    "docs\solutions\integration-issues",
    "docs\solutions\logic-errors",
    "docs\solutions\patterns",
    ".claude\skills\ui-design\references",
    ".claude\skills\generate-image",
    ".claude\skills\release",
    ".claude\skills\council\references",
    "tests\e2e\use-cases",
    "tests\e2e\reports"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  " -NoNewline
        Write-Color "+" "Green"
        Write-Host " Created $dir"
    }
    else {
        Write-Host "  " -NoNewline
        Write-Color "o" "Blue"
        Write-Host " $dir already exists"
    }
}

# E2E reports are ephemeral — ignore everything except this gitignore itself.
$reportsGitignore = "tests\e2e\reports\.gitignore"
if (-not (Test-Path $reportsGitignore)) {
    Set-Content -Path $reportsGitignore -Value "*`n!.gitignore`n" -NoNewline
    Write-Host "  " -NoNewline
    Write-Color "+" "Green"
    Write-Host " Created tests\e2e\reports\.gitignore (reports are ephemeral)"
}
Write-Host ""

# Copy templates
Write-Color "Copying configuration files..." "Yellow"

# Main files — CLAUDE.md and CONTINUITY.md are NEVER overwritten (user content)
if (Test-Path "CLAUDE.md") {
    Write-Host "  " -NoNewline; Write-Color "o" "Blue"; Write-Host " CLAUDE.md already exists (never overwritten - user content)"
} else {
    Copy-TemplateFile (Join-Path $ScriptDir "CLAUDE.template.md") "CLAUDE.md" "CLAUDE.md"
}
if (Test-Path "CONTINUITY.md") {
    Write-Host "  " -NoNewline; Write-Color "o" "Blue"; Write-Host " CONTINUITY.md already exists (never overwritten - user content)"
} else {
    Copy-TemplateFile (Join-Path $ScriptDir "CONTINUITY.template.md") "CONTINUITY.md" "CONTINUITY.md"
}

# Resolve Python command (Windows uses 'python', Unix uses 'python3')
$PythonCmd = $null
if (Get-Command python -ErrorAction SilentlyContinue) { $PythonCmd = "python" }
elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $PythonCmd = "python3" }

# Settings — merge on upgrade, copy otherwise
if ($Upgrade -and (Test-Path ".claude\settings.json")) {
    Write-Color "  ^ Merging .claude\settings.json (upgrade mode)" "Yellow"
    if ($PythonCmd) {
        & $PythonCmd (Join-Path (Join-Path $ScriptDir "scripts") "merge-settings.py") (Join-Path (Join-Path $ScriptDir "settings") "settings-windows.template.json") ".claude\settings.json"
    } else {
        Write-Color "  ! Python not found -- cannot merge settings. Install Python or merge manually." "Yellow"
    }
} else {
    Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "settings") "settings-windows.template.json") ".claude\settings.json" ".claude\settings.json"
}

# MCP servers — merge on upgrade, copy otherwise
if ($Upgrade -and (Test-Path ".mcp.json")) {
    Write-Color "  ^ Merging .mcp.json (upgrade mode)" "Yellow"
    if ($PythonCmd) {
        & $PythonCmd (Join-Path (Join-Path $ScriptDir "scripts") "merge-settings.py") (Join-Path $ScriptDir "mcp.template.json") ".mcp.json"
    } else {
        Write-Color "  ! Python not found -- cannot merge .mcp.json. Install Python or merge manually." "Yellow"
    }
} else {
    Copy-TemplateFile (Join-Path $ScriptDir "mcp.template.json") ".mcp.json" ".mcp.json (MCP servers: Playwright + Context7)"
}

# Hooks (PowerShell versions for Windows)
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "session-start.ps1") ".claude\hooks\session-start.ps1" ".claude\hooks\session-start.ps1"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "check-state-updated.ps1") ".claude\hooks\check-state-updated.ps1" ".claude\hooks\check-state-updated.ps1"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "post-tool-format.ps1") ".claude\hooks\post-tool-format.ps1" ".claude\hooks\post-tool-format.ps1"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "pre-compact-memory.ps1") ".claude\hooks\pre-compact-memory.ps1" ".claude\hooks\pre-compact-memory.ps1"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "check-config-change.ps1") ".claude\hooks\check-config-change.ps1" ".claude\hooks\check-config-change.ps1"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "check-bash-safety.ps1") ".claude\hooks\check-bash-safety.ps1" ".claude\hooks\check-bash-safety.ps1"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "hooks") "check-workflow-gates.ps1") ".claude\hooks\check-workflow-gates.ps1" ".claude\hooks\check-workflow-gates.ps1"

# Agents
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "agents") "verify-app.md") ".claude\agents\verify-app.md" ".claude\agents\verify-app.md"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "agents") "verify-e2e.md") ".claude\agents\verify-e2e.md" ".claude\agents\verify-e2e.md"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "agents") "council-advisor.md") ".claude\agents\council-advisor.md" ".claude\agents\council-advisor.md"

# Skills (tech-agnostic)
$releaseDir = Join-Path (Join-Path (Join-Path $ScriptDir "skills") "release")
Copy-TemplateFile (Join-Path $releaseDir "SKILL.template.md") ".claude\skills\release\SKILL.md" ".claude\skills\release\SKILL.md"

# Engineering Council skill (tech-agnostic) — multi-perspective decision analysis
$councilDir = Join-Path (Join-Path (Join-Path $ScriptDir "skills") "council")
$councilRefDir = Join-Path $councilDir "references"
Copy-TemplateFile (Join-Path $councilDir "SKILL.template.md") ".claude\skills\council\SKILL.md" ".claude\skills\council\SKILL.md"
Copy-TemplateFile (Join-Path $councilRefDir "advisors.md") ".claude\skills\council\references\advisors.md" ".claude\skills\council\references\advisors.md"
Copy-TemplateFile (Join-Path $councilRefDir "output-schema.md") ".claude\skills\council\references\output-schema.md" ".claude\skills\council\references\output-schema.md"
Copy-TemplateFile (Join-Path $councilRefDir "peer-review-protocol.md") ".claude\skills\council\references\peer-review-protocol.md" ".claude\skills\council\references\peer-review-protocol.md"

# Commands - Workflow (ENFORCED)
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "commands") "new-feature.md") ".claude\commands\new-feature.md" ".claude\commands\new-feature.md"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "commands") "fix-bug.md") ".claude\commands\fix-bug.md" ".claude\commands\fix-bug.md"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "commands") "quick-fix.md") ".claude\commands\quick-fix.md" ".claude\commands\quick-fix.md"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "commands") "finish-branch.md") ".claude\commands\finish-branch.md" ".claude\commands\finish-branch.md"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "commands") "codex.md") ".claude\commands\codex.md" ".claude\commands\codex.md"
Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "commands") "review-pr-comments.md") ".claude\commands\review-pr-comments.md" ".claude\commands\review-pr-comments.md"

# Commands - PRD
Copy-TemplateFile (Join-Path (Join-Path (Join-Path $ScriptDir "commands") "prd") "discuss.md") ".claude\commands\prd\discuss.md" ".claude\commands\prd\discuss.md"
Copy-TemplateFile (Join-Path (Join-Path (Join-Path $ScriptDir "commands") "prd") "create.md") ".claude\commands\prd\create.md" ".claude\commands\prd\create.md"

# Rules based on tech stack
Write-Host ""
Write-Color "Copying rules for $Tech..." "Yellow"

# Common rules
# Common rules (apply to all tech stacks)
$commonRules = @("security.md", "skill-audit.md", "api-design.md", "testing.md", "principles.md", "workflow.md", "worktree-policy.md", "critical-rules.md", "memory.md")
foreach ($rule in $commonRules) {
    Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") $rule) ".claude\rules\$rule" ".claude\rules\$rule"
}

# Tech-specific rules
switch ($Tech) {
    "python" {
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "python-style.md") ".claude\rules\python-style.md" ".claude\rules\python-style.md"
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "database.md") ".claude\rules\database.md" ".claude\rules\database.md"
    }
    "typescript" {
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "typescript-style.md") ".claude\rules\typescript-style.md" ".claude\rules\typescript-style.md"
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "frontend-design.md") ".claude\rules\frontend-design.md" ".claude\rules\frontend-design.md"
        # UI Design skill (auto-triggers for frontend work) — all 10 references
        $skillDir = Join-Path (Join-Path (Join-Path $ScriptDir "skills") "ui-design")
        $refsDir = Join-Path $skillDir "references"
        Copy-TemplateFile (Join-Path $skillDir "SKILL.template.md") ".claude\skills\ui-design\SKILL.md" ".claude\skills\ui-design\SKILL.md"
        Copy-TemplateFile (Join-Path $refsDir "animation-techniques.md") ".claude\skills\ui-design\references\animation-techniques.md" ".claude\skills\ui-design\references\animation-techniques.md"
        Copy-TemplateFile (Join-Path $refsDir "typography-and-color.md") ".claude\skills\ui-design\references\typography-and-color.md" ".claude\skills\ui-design\references\typography-and-color.md"
        Copy-TemplateFile (Join-Path $refsDir "polish-checklist.md") ".claude\skills\ui-design\references\polish-checklist.md" ".claude\skills\ui-design\references\polish-checklist.md"
        Copy-TemplateFile (Join-Path $refsDir "media-assets.md") ".claude\skills\ui-design\references\media-assets.md" ".claude\skills\ui-design\references\media-assets.md"
        Copy-TemplateFile (Join-Path $refsDir "industry-design-guide.md") ".claude\skills\ui-design\references\industry-design-guide.md" ".claude\skills\ui-design\references\industry-design-guide.md"
        Copy-TemplateFile (Join-Path $refsDir "ux-antipatterns.md") ".claude\skills\ui-design\references\ux-antipatterns.md" ".claude\skills\ui-design\references\ux-antipatterns.md"
        Copy-TemplateFile (Join-Path $refsDir "landing-patterns.md") ".claude\skills\ui-design\references\landing-patterns.md" ".claude\skills\ui-design\references\landing-patterns.md"
        Copy-TemplateFile (Join-Path $refsDir "21st-dev-components.md") ".claude\skills\ui-design\references\21st-dev-components.md" ".claude\skills\ui-design\references\21st-dev-components.md"
        Copy-TemplateFile (Join-Path $refsDir "product-ui-patterns.md") ".claude\skills\ui-design\references\product-ui-patterns.md" ".claude\skills\ui-design\references\product-ui-patterns.md"
        Copy-TemplateFile (Join-Path $refsDir "trust-first-patterns.md") ".claude\skills\ui-design\references\trust-first-patterns.md" ".claude\skills\ui-design\references\trust-first-patterns.md"
        # Image generation skill (Gemini API — checks docs for current model)
        $genImgDir = Join-Path (Join-Path (Join-Path $ScriptDir "skills") "generate-image")
        Copy-TemplateFile (Join-Path $genImgDir "SKILL.template.md") ".claude\skills\generate-image\SKILL.md" ".claude\skills\generate-image\SKILL.md"
    }
    default {
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "python-style.md") ".claude\rules\python-style.md" ".claude\rules\python-style.md"
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "typescript-style.md") ".claude\rules\typescript-style.md" ".claude\rules\typescript-style.md"
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "database.md") ".claude\rules\database.md" ".claude\rules\database.md"
        Copy-TemplateFile (Join-Path (Join-Path $ScriptDir "rules") "frontend-design.md") ".claude\rules\frontend-design.md" ".claude\rules\frontend-design.md"
        # UI Design skill (auto-triggers for frontend work) — all 10 references
        $skillDir = Join-Path (Join-Path (Join-Path $ScriptDir "skills") "ui-design")
        $refsDir = Join-Path $skillDir "references"
        Copy-TemplateFile (Join-Path $skillDir "SKILL.template.md") ".claude\skills\ui-design\SKILL.md" ".claude\skills\ui-design\SKILL.md"
        Copy-TemplateFile (Join-Path $refsDir "animation-techniques.md") ".claude\skills\ui-design\references\animation-techniques.md" ".claude\skills\ui-design\references\animation-techniques.md"
        Copy-TemplateFile (Join-Path $refsDir "typography-and-color.md") ".claude\skills\ui-design\references\typography-and-color.md" ".claude\skills\ui-design\references\typography-and-color.md"
        Copy-TemplateFile (Join-Path $refsDir "polish-checklist.md") ".claude\skills\ui-design\references\polish-checklist.md" ".claude\skills\ui-design\references\polish-checklist.md"
        Copy-TemplateFile (Join-Path $refsDir "media-assets.md") ".claude\skills\ui-design\references\media-assets.md" ".claude\skills\ui-design\references\media-assets.md"
        Copy-TemplateFile (Join-Path $refsDir "industry-design-guide.md") ".claude\skills\ui-design\references\industry-design-guide.md" ".claude\skills\ui-design\references\industry-design-guide.md"
        Copy-TemplateFile (Join-Path $refsDir "ux-antipatterns.md") ".claude\skills\ui-design\references\ux-antipatterns.md" ".claude\skills\ui-design\references\ux-antipatterns.md"
        Copy-TemplateFile (Join-Path $refsDir "landing-patterns.md") ".claude\skills\ui-design\references\landing-patterns.md" ".claude\skills\ui-design\references\landing-patterns.md"
        Copy-TemplateFile (Join-Path $refsDir "21st-dev-components.md") ".claude\skills\ui-design\references\21st-dev-components.md" ".claude\skills\ui-design\references\21st-dev-components.md"
        Copy-TemplateFile (Join-Path $refsDir "product-ui-patterns.md") ".claude\skills\ui-design\references\product-ui-patterns.md" ".claude\skills\ui-design\references\product-ui-patterns.md"
        Copy-TemplateFile (Join-Path $refsDir "trust-first-patterns.md") ".claude\skills\ui-design\references\trust-first-patterns.md" ".claude\skills\ui-design\references\trust-first-patterns.md"
        # Image generation skill (Gemini API — checks docs for current model)
        $genImgDir = Join-Path (Join-Path (Join-Path $ScriptDir "skills") "generate-image")
        Copy-TemplateFile (Join-Path $genImgDir "SKILL.template.md") ".claude\skills\generate-image\SKILL.md" ".claude\skills\generate-image\SKILL.md"
    }
}

# Playwright framework templates (opt-in via -WithPlaywright)
if ($WithPlaywright) {
    Write-Host ""
    Write-Color "Installing Playwright framework templates..." "Yellow"

    # Create the specs/ directory (not in the default directories array —
    # only relevant when framework is installed)
    if (-not (Test-Path "tests\e2e\specs")) {
        New-Item -ItemType Directory -Path "tests\e2e\specs" -Force | Out-Null
        Write-Host "  " -NoNewline
        Write-Color "+" "Green"
        Write-Host " Created tests\e2e\specs (for graduated .spec.ts files)"
    }

    $pwTemplateDir = Join-Path (Join-Path $ScriptDir "templates") "playwright"
    $ciTemplateDir = Join-Path (Join-Path $ScriptDir "templates") "ci-workflows"

    # Playwright config
    Copy-TemplateFile (Join-Path $pwTemplateDir "playwright.config.template.ts") "playwright.config.ts" "playwright.config.ts"

    # Auth fixture
    if (-not (Test-Path "tests\e2e\fixtures")) {
        New-Item -ItemType Directory -Path "tests\e2e\fixtures" -Force | Out-Null
    }
    Copy-TemplateFile (Join-Path $pwTemplateDir "auth.fixture.template.ts") "tests\e2e\fixtures\auth.ts" "tests\e2e\fixtures\auth.ts"

    # Auth storage directory - gitignored because it contains credentials
    if (-not (Test-Path "tests\e2e\.auth")) {
        New-Item -ItemType Directory -Path "tests\e2e\.auth" -Force | Out-Null
    }
    if (-not (Test-Path "tests\e2e\.auth\.gitignore")) {
        @"
# Auth storage state contains credentials - never commit
*
!.gitignore
"@ | Set-Content -Path "tests\e2e\.auth\.gitignore" -NoNewline
        Write-Host "  " -NoNewline
        Write-Color "+" "Green"
        Write-Host " Created tests\e2e\.auth\.gitignore (credentials protected)"
    }

    # CI workflow reference (NOT auto-activated)
    if (-not (Test-Path "docs\ci-templates")) {
        New-Item -ItemType Directory -Path "docs\ci-templates" -Force | Out-Null
    }
    Copy-TemplateFile (Join-Path $ciTemplateDir "e2e.yml") "docs\ci-templates\e2e.yml" "docs\ci-templates\e2e.yml (reference - NOT auto-activated)"
    Copy-TemplateFile (Join-Path $ciTemplateDir "README.md") "docs\ci-templates\README.md" "docs\ci-templates\README.md"

    Write-Host ""
    Write-Color "Playwright templates installed." "Green"
    Write-Color "Next steps to complete Playwright setup:" "Yellow"
    Write-Host "  1. Install the framework: " -NoNewline
    Write-Color "pnpm add -D @playwright/test" "Blue"
    Write-Host "     (or npm: " -NoNewline
    Write-Color "npm install --save-dev @playwright/test" "Blue"
    Write-Host ")"
    Write-Host "  2. Install browsers:      " -NoNewline
    Write-Color "pnpm exec playwright install" "Blue"
    Write-Host "  3. Review " -NoNewline
    Write-Color "playwright.config.ts" "Blue"
    Write-Host " - set baseURL and uncomment webServer if needed"
    Write-Host "  4. (Optional) Activate CI:"
    Write-Host "     " -NoNewline
    Write-Color "mkdir .github\workflows; cp docs\ci-templates\e2e.yml .github\workflows\e2e.yml" "Blue"
    Write-Host "     Note: CI template uses pnpm - adjust for npm/yarn in .github\workflows\e2e.yml if needed"
    Write-Host "  5. Configure auth via env vars: TEST_API_KEY or TEST_USER_EMAIL + TEST_USER_PASSWORD"
    Write-Host "  6. Run tests: " -NoNewline
    Write-Color "pnpm exec playwright test" "Blue"
}

Write-Host ""

# Create CHANGELOG if it doesn't exist
if ((-not (Test-Path "docs\CHANGELOG.md")) -or $Force) {
    Write-Color "Creating docs\CHANGELOG.md..." "Yellow"

    $changelogLines = @(
        "# Changelog",
        "",
        "All notable changes to $Project will be documented in this file.",
        "",
        "## [Unreleased]",
        "",
        "### Added",
        "- Initial project setup with Claude Code configuration",
        "",
        "### Changed",
        "",
        "### Fixed",
        "",
        "### Removed",
        "",
        "---",
        "",
        "## Format",
        "",
        "Each entry should include:",
        "- Date (YYYY-MM-DD)",
        "- Brief description",
        "- Related issue/PR if applicable"
    )

    $changelogLines | Out-File -FilePath "docs\CHANGELOG.md" -Encoding UTF8
    Write-Host "  " -NoNewline
    Write-Color "+" "Green"
    Write-Host " Created docs\CHANGELOG.md"
}
else {
    Write-Host "  " -NoNewline
    Write-Color "o" "Blue"
    Write-Host " docs\CHANGELOG.md already exists"
}

# Update CLAUDE.md with project name
if (Test-Path "CLAUDE.md") {
    # Read with UTF8 encoding to preserve Unicode characters (arrows, box chars)
    $content = [System.IO.File]::ReadAllText((Resolve-Path "CLAUDE.md"), [System.Text.Encoding]::UTF8)
    $content = $content -replace '\[Project Name\]', $Project
    # Write back with UTF8 without BOM to preserve Unicode
    [System.IO.File]::WriteAllText((Resolve-Path "CLAUDE.md"), $content, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "  " -NoNewline
    Write-Color "+" "Green"
    Write-Host " Updated CLAUDE.md with project name"
}

Write-Host ""
if ($Upgrade) {
    Write-Color "============================================" "Green"
    Write-Color "  Upgrade Complete!" "Green"
    Write-Color "============================================" "Green"
    Write-Host ""
    Write-Color "What was updated:" "Yellow"
    Write-Host ""
    Write-Host "  .claude\commands\        Workflow commands (refreshed)"
    Write-Host "  .claude\hooks\           Hook scripts (refreshed)"
    Write-Host "  .claude\rules\           Coding standards (refreshed)"
    Write-Host "  .claude\agents\          Subagent definitions (refreshed)"
    Write-Host "  .claude\skills\          Skills (release, council, ui-design if typescript/fullstack)"
    Write-Host "  .claude\settings.json    Hooks and permissions (merged - your customizations kept)"
    Write-Host "  .mcp.json                MCP servers (merged - your customizations kept)"
    Write-Host ""
    Write-Color "Not touched:" "Yellow"
    Write-Host ""
    Write-Host "  CLAUDE.md                Your project description (preserved)"
    Write-Host "  CONTINUITY.md            Your task state (preserved)"
    Write-Host ""
    Write-Color "Next steps:" "Yellow"
    Write-Host ""
    Write-Host "1. " -NoNewline
    Write-Color "Verify everything works" "Blue"
    Write-Host ":"
    Write-Host ""
    Write-Host "   /hooks       -> Should show: SessionStart, Stop, PreToolUse, PostToolUse, PreCompact, SubagentStop, ConfigChange"
    Write-Host "   /help        -> Should show: /superpowers:*, /new-feature, /fix-bug, /prd:*"
    Write-Host ""
    Write-Host "2. " -NoNewline
    Write-Color "Commit and push" "Blue"
    Write-Host ":"
    Write-Host ""
    Write-Host "   git add .claude/ .mcp.json"
    Write-Host "   git commit -m `"chore: upgrade Claude Code automation templates`""
    Write-Host "   git push"
    Write-Host ""
    Write-Color "Upgrade done! Your CLAUDE.md and CONTINUITY.md were not modified." "Green"
} else {
    Write-Color "============================================" "Green"
    Write-Color "  Setup Complete!" "Green"
    Write-Color "============================================" "Green"
    Write-Host ""
    Write-Color "What was created:" "Yellow"
    Write-Host ""
    Write-Host "  CLAUDE.md                Your project description (edit this!)"
    Write-Host "  CONTINUITY.md            Task state that persists across sessions"
    Write-Host "  .claude\settings.json    Hooks and permissions"
    Write-Host "  .mcp.json                MCP servers (Playwright + Context7)"
    Write-Host "  .claude\commands\        Workflow commands: /new-feature, /fix-bug, /quick-fix"
    Write-Host "  .claude\hooks\           Auto-run scripts (format, verify, memory)"
    Write-Host "  .claude\agents\          Subagent definitions (verify-app, verify-e2e)"
    Write-Host "  .claude\rules\           Coding standards + workflow rules (safe to update)"
    Write-Host "  .claude\skills\           Skills (release, council, ui-design if typescript/fullstack)"
    Write-Host "  docs\                    Changelog, PRDs, solutions knowledge base"
    Write-Host ""
    Write-Color "Plugins pre-enabled in .claude\settings.json:" "Yellow"
    Write-Host ""
    Write-Host "  - superpowers              (requires install - see step 3 below)"
    Write-Host "  - pr-review-toolkit        (built-in, no install needed)"
    Write-Host "  - frontend-design          (built-in, no install needed)"
    Write-Host ""
    # Check if global setup needed
    $globalClaude = Join-Path (Join-Path $HOME ".claude") "CLAUDE.md"
    if (-not (Test-Path $globalClaude)) {
        Write-Color "+--------------------------------------------------------------+" "Red"
        Write-Color "|  WARNING: Global memory not set up yet!                       |" "Red"
        Write-Color "|                                                               |" "Red"
        Write-Color "|  Without global setup:                                        |" "Red"
        Write-Color "|  - Claude won't save learnings before context compression     |" "Red"
        Write-Color "|  - /memory won't show your auto memory directory              |" "Red"
        Write-Color "|  - Session knowledge will be lost on compaction               |" "Red"
        Write-Color "|                                                               |" "Red"
        Write-Host  "|  Run: " -NoNewline -ForegroundColor Red
        Write-Host  "& $ScriptDir\setup.ps1 -Global" -NoNewline -ForegroundColor Green
        Write-Color "                          |" "Red"
        Write-Color "+--------------------------------------------------------------+" "Red"
        Write-Host ""
    }
    Write-Color "Next steps:" "Yellow"
    Write-Host ""
    Write-Host "1. " -NoNewline
    Write-Color "Edit CLAUDE.md" "Blue"
    Write-Host " - Fill in your project description, tech stack, and commands"
    Write-Host "   (It's intentionally short - all rules live in .claude\rules\)"
    Write-Host ""
    Write-Host "2. " -NoNewline
    Write-Color "Edit CONTINUITY.md" "Blue"
    Write-Host " - Set your current goal and task state"
    Write-Host ""
    Write-Host "3. " -NoNewline
    Write-Color "Install the Superpowers plugin" "Blue"
    Write-Host " (one time):"
    Write-Host ""
    Write-Host "   claude"
    Write-Host "   /plugin marketplace add obra/superpowers-marketplace"
    Write-Host "   /plugin install superpowers@superpowers-marketplace"
    Write-Host ""
    Write-Host "   Then restart Claude Code."
    Write-Host ""
    Write-Host "   Note: pr-review-toolkit and frontend-design are built-in Claude Code plugins -"
    Write-Host "   no install needed. /simplify is a built-in command. They're already"
    Write-Host "   enabled in .claude\settings.json."
    Write-Host ""
    Write-Host "4. " -NoNewline
    Write-Color "Verify everything works" "Blue"
    Write-Host ":"
    Write-Host ""
    Write-Host "   /hooks       -> Should show: SessionStart, Stop, PreToolUse, PostToolUse, PreCompact, SubagentStop, ConfigChange"
    Write-Host "   /help        -> Should show: /superpowers:*, /new-feature, /fix-bug, /prd:*"
    Write-Host "   /memory      -> Should show your auto memory directory"
    Write-Host ""
    Write-Host "5. " -NoNewline
    Write-Color "Commit and push" "Blue"
    Write-Host ":"
    Write-Host ""
    Write-Host "   git add .claude/ .mcp.json CLAUDE.md CONTINUITY.md docs/"
    Write-Host "   git commit -m `"chore: add Claude Code automation setup`""
    Write-Host "   git push"
    Write-Host ""
    Write-Color "You're ready! Run /new-feature <name> to start your first guided workflow." "Green"
}
