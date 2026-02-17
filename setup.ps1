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
    [switch]$Force
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
    Write-Host "Set up Claude Code configuration for a project."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -h, -Help           Show this help message"
    Write-Host "  -p, -Project NAME   Project name (default: directory name)"
    Write-Host "  -t, -Tech STACK     Tech stack: python, typescript, fullstack (default: fullstack)"
    Write-Host "  -f, -Force          Overwrite existing files"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup.ps1                          # Setup with defaults"
    Write-Host "  .\setup.ps1 -p `"My Project`"          # Custom project name"
    Write-Host "  .\setup.ps1 -t python                # Python-only project"
    Write-Host "  .\setup.ps1 -f                       # Force overwrite existing files"
}

# Show help if requested
if ($Help) {
    Show-Usage
    exit 0
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

    Copy-Item -Path $Source -Destination $Destination -Force
    Write-Host "  " -NoNewline
    Write-Color "+" "Green"
    Write-Host " Created $Description"
    return $true
}

# Copy templates
Write-Color "Copying configuration files..." "Yellow"

# Main files
Copy-TemplateFile "$ScriptDir\CLAUDE.template.md" "CLAUDE.md" "CLAUDE.md"
Copy-TemplateFile "$ScriptDir\CONTINUITY.template.md" "CONTINUITY.md" "CONTINUITY.md"

# Settings (Windows-specific with PowerShell hooks)
Copy-TemplateFile "$ScriptDir\settings\settings-windows.template.json" ".claude\settings.json" ".claude\settings.json"

# Hooks (PowerShell versions for Windows)
Copy-TemplateFile "$ScriptDir\hooks\check-state-updated.ps1" ".claude\hooks\check-state-updated.ps1" ".claude\hooks\check-state-updated.ps1"
Copy-TemplateFile "$ScriptDir\hooks\post-tool-format.ps1" ".claude\hooks\post-tool-format.ps1" ".claude\hooks\post-tool-format.ps1"

# Agents
Copy-TemplateFile "$ScriptDir\agents\verify-app.md" ".claude\agents\verify-app.md" ".claude\agents\verify-app.md"

# Commands - Workflow (ENFORCED)
Copy-TemplateFile "$ScriptDir\commands\new-feature.md" ".claude\commands\new-feature.md" ".claude\commands\new-feature.md"
Copy-TemplateFile "$ScriptDir\commands\fix-bug.md" ".claude\commands\fix-bug.md" ".claude\commands\fix-bug.md"
Copy-TemplateFile "$ScriptDir\commands\quick-fix.md" ".claude\commands\quick-fix.md" ".claude\commands\quick-fix.md"
Copy-TemplateFile "$ScriptDir\commands\finish-branch.md" ".claude\commands\finish-branch.md" ".claude\commands\finish-branch.md"
Copy-TemplateFile "$ScriptDir\commands\codex.md" ".claude\commands\codex.md" ".claude\commands\codex.md"

# Commands - PRD
Copy-TemplateFile "$ScriptDir\commands\prd\discuss.md" ".claude\commands\prd\discuss.md" ".claude\commands\prd\discuss.md"
Copy-TemplateFile "$ScriptDir\commands\prd\create.md" ".claude\commands\prd\create.md" ".claude\commands\prd\create.md"

# Rules based on tech stack
Write-Host ""
Write-Color "Copying rules for $Tech..." "Yellow"

# Common rules
$commonRules = @("security.md", "api-design.md", "testing.md")
foreach ($rule in $commonRules) {
    Copy-TemplateFile "$ScriptDir\rules\$rule" ".claude\rules\$rule" ".claude\rules\$rule"
}

# Tech-specific rules
switch ($Tech) {
    "python" {
        Copy-TemplateFile "$ScriptDir\rules\python-style.md" ".claude\rules\python-style.md" ".claude\rules\python-style.md"
        Copy-TemplateFile "$ScriptDir\rules\database.md" ".claude\rules\database.md" ".claude\rules\database.md"
    }
    "typescript" {
        Copy-TemplateFile "$ScriptDir\rules\typescript-style.md" ".claude\rules\typescript-style.md" ".claude\rules\typescript-style.md"
    }
    default {
        Copy-TemplateFile "$ScriptDir\rules\python-style.md" ".claude\rules\python-style.md" ".claude\rules\python-style.md"
        Copy-TemplateFile "$ScriptDir\rules\typescript-style.md" ".claude\rules\typescript-style.md" ".claude\rules\typescript-style.md"
        Copy-TemplateFile "$ScriptDir\rules\database.md" ".claude\rules\database.md" ".claude\rules\database.md"
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
Write-Color "Next steps:" "Yellow"
Write-Host ""
Write-Host "1. " -NoNewline
Write-Color "Edit CLAUDE.md" "Blue"
Write-Host " to add:"
Write-Host "   - Project description (What Is This?)"
Write-Host "   - Tech stack details"
Write-Host "   - File structure"
Write-Host "   - Project-specific commands"
Write-Host ""
Write-Host "2. " -NoNewline
Write-Color "Edit CONTINUITY.md" "Blue"
Write-Host " to add:"
Write-Host "   - Project goal"
Write-Host "   - Constraints and assumptions"
Write-Host "   - Current state (Done/Now/Next)"
Write-Host ""
Write-Host "3. " -NoNewline
Write-Color "Start Claude Code" "Blue"
Write-Host " and install plugins:"
Write-Host ""
Write-Host "   claude"
Write-Host ""
Write-Host "   # In Claude Code session:"
Write-Host "   /plugin marketplace add obra/superpowers-marketplace"
Write-Host "   /plugin install superpowers@superpowers-marketplace"
Write-Host ""
Write-Host "   /plugin marketplace add EveryInc/compound-engineering-plugin"
Write-Host "   /plugin install compound-engineering@compound-engineering-plugin"
Write-Host ""
Write-Host "   /plugin install code-simplifier"
Write-Host ""
Write-Host "4. " -NoNewline
Write-Color "Verify setup" "Blue"
Write-Host ":"
Write-Host "   /hooks      # Should show SessionStart, Stop, SubagentStop, PostToolUse"
Write-Host "   /permissions # Should show pre-allowed commands"
Write-Host "   /help       # Should show /superpowers:*, /workflows:*, /prd:*"
Write-Host ""
Write-Host "5. " -NoNewline
Write-Color "Commit the new files" "Blue"
Write-Host ":"
Write-Host "   git add .claude/ CLAUDE.md CONTINUITY.md docs/"
Write-Host "   git commit -m `"chore: add Claude Code automation setup`""
Write-Host "   git push"
Write-Host ""
Write-Color "Happy coding with Claude!" "Green"
