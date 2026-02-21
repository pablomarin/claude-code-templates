# .claude/hooks/check-state-updated.ps1
# This hook runs when Claude is about to stop responding.
# It checks if there are uncommitted changes and reminds Claude to update state.
#
# Uses exit code 2 + stderr to block (avoids JSON stdout parsing issues).
#
# Requirements: PowerShell 5.1+, git

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

# All git commands run in current directory (Claude cd's into worktrees)
# Only count tracked modifications (staged + unstaged), NOT untracked files (??)
$uncommittedOutput = git status --porcelain 2>$null | Where-Object { $_ -notmatch '^\?\?' }
$uncommitted = if ($uncommittedOutput) { @($uncommittedOutput).Count } else { 0 }

# Check if CONTINUITY.md was modified
$continuityOutput = git status --porcelain CONTINUITY.md 2>$null
$continuityModified = if ($continuityOutput) { ($continuityOutput | Measure-Object -Line).Lines } else { 0 }

# Check if CHANGELOG was modified
$changelogOutput = git status --porcelain docs/CHANGELOG.md 2>$null
$changelogModified = if ($changelogOutput) { ($changelogOutput | Measure-Object -Line).Lines } else { 0 }

# Get branch base for comparison
$branchBase = git merge-base main HEAD 2>$null
if (-not $branchBase) { $branchBase = "HEAD~10" }

# Count files changed on branch
$branchChangedOutput = git diff --name-only $branchBase HEAD 2>$null
$branchChanged = if ($branchChangedOutput) { ($branchChangedOutput | Measure-Object -Line).Lines } else { 0 }

$uncommittedFilesOutput = git diff --name-only 2>$null
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

# Block using exit code 2 + stderr (robust — immune to stdout pollution)
if ($issues) {
    [Console]::Error.WriteLine($issues)
    exit 2
}

# All good, allow stop
exit 0
