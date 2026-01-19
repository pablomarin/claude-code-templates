# .claude/hooks/check-state-updated.ps1
# This hook runs when Claude is about to stop responding.
# It checks if there are uncommitted changes and reminds Claude to update state.
#
# Supports worktrees: reads .claude/.session_worktree to check the correct directory.
#
# Requirements: PowerShell 5.1+, git
# No external dependencies needed - uses native ConvertFrom-Json

# Read the hook input from stdin
$jsonInput = [Console]::In.ReadToEnd()

# Parse JSON input
try {
    $data = $jsonInput | ConvertFrom-Json
} catch {
    # If JSON parsing fails, allow stop
    exit 0
}

# Check if stop_hook_active to prevent infinite loops
if ($data.stop_hook_active -eq $true) {
    exit 0
}

# Check for worktree path (set by /new-feature or /fix-bug workflows)
# Falls back to current directory if worktree doesn't exist (cleaned up or parallel session)
$workDir = "."
$sessionWorktreeFile = ".claude/.session_worktree"
if (Test-Path $sessionWorktreeFile) {
    $worktreePath = Get-Content $sessionWorktreeFile -Raw
    $worktreePath = $worktreePath.Trim()
    # Only use worktree if directory still exists (may have been cleaned up)
    if ($worktreePath -and (Test-Path $worktreePath -PathType Container)) {
        $workDir = $worktreePath
    }
}

# Helper function to run git in the work directory
function Invoke-Git {
    param([string[]]$Arguments)
    $allArgs = @("-C", $workDir) + $Arguments
    & git @allArgs 2>$null
}

# Check for uncommitted changes in work directory
$uncommittedOutput = Invoke-Git @("status", "--porcelain")
$uncommitted = if ($uncommittedOutput) { ($uncommittedOutput | Measure-Object -Line).Lines } else { 0 }

# Check if CONTINUITY.md was modified
$continuityOutput = Invoke-Git @("status", "--porcelain", "CONTINUITY.md")
$continuityModified = if ($continuityOutput) { ($continuityOutput | Measure-Object -Line).Lines } else { 0 }

# Check if CHANGELOG was modified
$changelogOutput = Invoke-Git @("status", "--porcelain", "docs/CHANGELOG.md")
$changelogModified = if ($changelogOutput) { ($changelogOutput | Measure-Object -Line).Lines } else { 0 }

# Get branch base for comparison
$branchBase = Invoke-Git @("merge-base", "main", "HEAD")
if (-not $branchBase) { $branchBase = "HEAD~10" }

# Count files changed on branch
$branchChangedOutput = Invoke-Git @("diff", "--name-only", $branchBase, "HEAD")
$branchChanged = if ($branchChangedOutput) { ($branchChangedOutput | Measure-Object -Line).Lines } else { 0 }

$uncommittedFilesOutput = Invoke-Git @("diff", "--name-only")
$uncommittedFiles = if ($uncommittedFilesOutput) { ($uncommittedFilesOutput | Measure-Object -Line).Lines } else { 0 }

$totalChanged = $branchChanged + $uncommittedFiles

# Check if CHANGELOG was updated anywhere on branch
$changelogInBranch = 0
if ($branchChangedOutput) {
    $changelogInBranch = ($branchChangedOutput | Select-String "CHANGELOG.md" | Measure-Object).Count
}

# Build response
$issues = ""

# Block: uncommitted changes but CONTINUITY.md not updated
if ($uncommitted -gt 0 -and $continuityModified -eq 0) {
    $issues = "Update CONTINUITY.md Done/Now/Next sections."
}

# Block: 3+ files changed on branch but CHANGELOG.md never updated
if ($totalChanged -gt 3 -and $changelogInBranch -eq 0 -and $changelogModified -eq 0) {
    if ($issues) {
        $issues = "$issues Update docs/CHANGELOG.md ($totalChanged files changed this session)."
    } else {
        $issues = "Update docs/CHANGELOG.md ($totalChanged files changed this session)."
    }
}

# If there are issues, block and ask Claude to continue
if ($issues) {
    # Output JSON that tells Claude to continue working
    $response = @{
        decision = "block"
        reason = $issues
    } | ConvertTo-Json -Compress
    Write-Output $response
    exit 0
}

# All good, allow stop
exit 0
