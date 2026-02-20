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

    [Alias("g")]
    [switch]$Global
)

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
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup.ps1                          # Setup with defaults"
    Write-Host "  .\setup.ps1 -p `"My Project`"          # Custom project name"
    Write-Host "  .\setup.ps1 -t python                # Python-only project"
    Write-Host "  .\setup.ps1 -f                       # Force overwrite existing files"
    Write-Host "  .\setup.ps1 -Global                  # Set up global memory (run once per machine)"
    Write-Host "  .\setup.ps1 -Global -f               # Force overwrite global settings"
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
        return $false
    }

    if ((Test-Path $Destination) -and (-not $Force)) {
        Write-Host "  " -NoNewline
        Write-Color "o" "Blue"
        Write-Host " $Description already exists (use -f to overwrite)"
        return $true
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
    return $true
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
        (Join-Path $HOME ".claude" "hooks")
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
    Copy-TemplateFile (Join-Path $ScriptDir "GLOBAL-CLAUDE.template.md") (Join-Path $HOME ".claude" "CLAUDE.md") "~\.claude\CLAUDE.md (global instructions)"

    # Copy global hooks
    Copy-TemplateFile (Join-Path $ScriptDir "hooks" "pre-compact-memory.ps1") (Join-Path $HOME ".claude" "hooks" "pre-compact-memory.ps1") "~\.claude\hooks\pre-compact-memory.ps1"

    # Copy global settings
    $globalSettings = Join-Path $HOME ".claude" "settings.json"
    if ((Test-Path $globalSettings) -and (-not $Force)) {
        Write-Host "  " -NoNewline
        Write-Color "o" "Blue"
        Write-Host " ~\.claude\settings.json already exists (use -f to overwrite)"
        Write-Host "  " -NoNewline
        Write-Color "TIP:" "Yellow"
        Write-Host " Manually merge hooks from settings\global-settings.template.json"
    }
    else {
        Copy-TemplateFile (Join-Path $ScriptDir "settings" "global-settings.template.json") $globalSettings "~\.claude\settings.json (global hooks)"
    }

    # Enable auto memory via environment variable
    Write-Host ""
    Write-Color "Step 3: Enabling auto memory..." "Yellow"
    Write-Host "  This lets Claude save learnings to persistent memory files."

    $currentValue = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_DISABLE_AUTO_MEMORY", "User")
    if ($currentValue -eq "0") {
        Write-Host "  " -NoNewline
        Write-Color "o" "Blue"
        Write-Host " Auto memory already enabled"
    }
    else {
        [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_DISABLE_AUTO_MEMORY", "0", "User")
        Write-Host "  " -NoNewline
        Write-Color "+" "Green"
        Write-Host " Set CLAUDE_CODE_DISABLE_AUTO_MEMORY=0 (user environment)"
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
$globalClaude = Join-Path $HOME ".claude" "CLAUDE.md"
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
    "docs\solutions\patterns"
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
Write-Host ""

# Copy templates
Write-Color "Copying configuration files..." "Yellow"

# Main files
Copy-TemplateFile (Join-Path $ScriptDir "CLAUDE.template.md") "CLAUDE.md" "CLAUDE.md"
Copy-TemplateFile (Join-Path $ScriptDir "CONTINUITY.template.md") "CONTINUITY.md" "CONTINUITY.md"

# Settings (Windows-specific with PowerShell hooks)
Copy-TemplateFile (Join-Path $ScriptDir "settings" "settings-windows.template.json") ".claude\settings.json" ".claude\settings.json"

# Hooks (PowerShell versions for Windows)
Copy-TemplateFile (Join-Path $ScriptDir "hooks" "check-state-updated.ps1") ".claude\hooks\check-state-updated.ps1" ".claude\hooks\check-state-updated.ps1"
Copy-TemplateFile (Join-Path $ScriptDir "hooks" "post-tool-format.ps1") ".claude\hooks\post-tool-format.ps1" ".claude\hooks\post-tool-format.ps1"
Copy-TemplateFile (Join-Path $ScriptDir "hooks" "pre-compact-memory.ps1") ".claude\hooks\pre-compact-memory.ps1" ".claude\hooks\pre-compact-memory.ps1"

# Agents
Copy-TemplateFile (Join-Path $ScriptDir "agents" "verify-app.md") ".claude\agents\verify-app.md" ".claude\agents\verify-app.md"

# Commands - Workflow (ENFORCED)
Copy-TemplateFile (Join-Path $ScriptDir "commands" "new-feature.md") ".claude\commands\new-feature.md" ".claude\commands\new-feature.md"
Copy-TemplateFile (Join-Path $ScriptDir "commands" "fix-bug.md") ".claude\commands\fix-bug.md" ".claude\commands\fix-bug.md"
Copy-TemplateFile (Join-Path $ScriptDir "commands" "quick-fix.md") ".claude\commands\quick-fix.md" ".claude\commands\quick-fix.md"
Copy-TemplateFile (Join-Path $ScriptDir "commands" "finish-branch.md") ".claude\commands\finish-branch.md" ".claude\commands\finish-branch.md"
Copy-TemplateFile (Join-Path $ScriptDir "commands" "codex.md") ".claude\commands\codex.md" ".claude\commands\codex.md"

# Commands - PRD
Copy-TemplateFile (Join-Path $ScriptDir "commands" "prd" "discuss.md") ".claude\commands\prd\discuss.md" ".claude\commands\prd\discuss.md"
Copy-TemplateFile (Join-Path $ScriptDir "commands" "prd" "create.md") ".claude\commands\prd\create.md" ".claude\commands\prd\create.md"

# Rules based on tech stack
Write-Host ""
Write-Color "Copying rules for $Tech..." "Yellow"

# Common rules
# Common rules (apply to all tech stacks)
$commonRules = @("security.md", "api-design.md", "testing.md", "principles.md", "workflow.md", "worktree-policy.md", "critical-rules.md", "memory.md")
foreach ($rule in $commonRules) {
    Copy-TemplateFile (Join-Path $ScriptDir "rules" $rule) ".claude\rules\$rule" ".claude\rules\$rule"
}

# Tech-specific rules
switch ($Tech) {
    "python" {
        Copy-TemplateFile (Join-Path $ScriptDir "rules" "python-style.md") ".claude\rules\python-style.md" ".claude\rules\python-style.md"
        Copy-TemplateFile (Join-Path $ScriptDir "rules" "database.md") ".claude\rules\database.md" ".claude\rules\database.md"
    }
    "typescript" {
        Copy-TemplateFile (Join-Path $ScriptDir "rules" "typescript-style.md") ".claude\rules\typescript-style.md" ".claude\rules\typescript-style.md"
    }
    default {
        Copy-TemplateFile (Join-Path $ScriptDir "rules" "python-style.md") ".claude\rules\python-style.md" ".claude\rules\python-style.md"
        Copy-TemplateFile (Join-Path $ScriptDir "rules" "typescript-style.md") ".claude\rules\typescript-style.md" ".claude\rules\typescript-style.md"
        Copy-TemplateFile (Join-Path $ScriptDir "rules" "database.md") ".claude\rules\database.md" ".claude\rules\database.md"
    }
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
Write-Color "============================================" "Green"
Write-Color "  Setup Complete!" "Green"
Write-Color "============================================" "Green"
Write-Host ""
Write-Color "What was created:" "Yellow"
Write-Host ""
Write-Host "  CLAUDE.md                Your project description (edit this!)"
Write-Host "  CONTINUITY.md            Task state that persists across sessions"
Write-Host "  .claude\settings.json    Hooks, permissions, and MCP servers"
Write-Host "  .claude\commands\        Workflow commands: /new-feature, /fix-bug, /quick-fix"
Write-Host "  .claude\hooks\           Auto-run scripts (format, verify, memory)"
Write-Host "  .claude\agents\          Subagent definitions (verify-app)"
Write-Host "  .claude\rules\           Coding standards + workflow rules (safe to update)"
Write-Host "  docs\                    Changelog, PRDs, solutions knowledge base"
Write-Host ""

# Check if global setup needed
$globalClaude = Join-Path $HOME ".claude" "CLAUDE.md"
if (-not (Test-Path $globalClaude)) {
    Write-Color "WARNING: Global memory not set up yet!" "Red"
    Write-Host ""
    Write-Host "  Run this first (once per machine):"
    Write-Host "  " -NoNewline
    Write-Color "& $ScriptDir\setup.ps1 -Global" "Green"
    Write-Host ""
    Write-Host "  Without global setup, Claude won't persist learnings across sessions."
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
Write-Host "   Note: code-review, pr-review-toolkit, and code-simplifier are"
Write-Host "   built-in Claude Code plugins - no install needed. They're already"
Write-Host "   enabled in .claude\settings.json."
Write-Host ""
Write-Host "4. " -NoNewline
Write-Color "Verify everything works" "Blue"
Write-Host ":"
Write-Host ""
Write-Host "   /hooks       -> Should show: SessionStart, Stop, PreCompact, SubagentStop, PostToolUse"
Write-Host "   /help        -> Should show: /superpowers:*, /new-feature, /fix-bug, /prd:*"
Write-Host "   /memory      -> Should show your auto memory directory"
Write-Host ""
Write-Host "5. " -NoNewline
Write-Color "Commit and push" "Blue"
Write-Host ":"
Write-Host ""
Write-Host "   git add .claude/ CLAUDE.md CONTINUITY.md docs/"
Write-Host "   git commit -m `"chore: add Claude Code automation setup`""
Write-Host "   git push"
Write-Host ""
Write-Color "You're ready! Run /new-feature <name> to start your first guided workflow." "Green"
