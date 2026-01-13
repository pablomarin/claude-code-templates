# .claude/hooks/check-state-updated.ps1
# This hook runs when Claude is about to stop responding.
# It checks if there are uncommitted changes and reminds Claude to update state.
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

# Check for uncommitted changes
$uncommittedOutput = git status --porcelain 2>$null
$uncommitted = if ($uncommittedOutput) { ($uncommittedOutput | Measure-Object -Line).Lines } else { 0 }

# Check if CONTINUITY.md was modified in this session
$continuityOutput = git status --porcelain CONTINUITY.md 2>$null
$continuityModified = if ($continuityOutput) { ($continuityOutput | Measure-Object -Line).Lines } else { 0 }

# Build response
$issues = ""

if ($uncommitted -gt 0 -and $continuityModified -eq 0) {
    $issues = "You have uncommitted changes but CONTINUITY.md hasn't been updated. Please update the Done/Now/Next sections to reflect the current state before finishing."
}

# Check if CHANGELOG should be updated (if there are significant changes)
$changelogOutput = git status --porcelain docs/CHANGELOG.md 2>$null
$changelogModified = if ($changelogOutput) { ($changelogOutput | Measure-Object -Line).Lines } else { 0 }

# Count changed files
$changedFilesOutput = git diff --name-only HEAD 2>$null
$changedFiles = if ($changedFilesOutput) { ($changedFilesOutput | Measure-Object -Line).Lines } else { 0 }

if ($changedFiles -gt 3 -and $changelogModified -eq 0) {
    if ($issues) {
        $issues = "$issues Also, consider updating docs/CHANGELOG.md for the significant changes made ($changedFiles files changed)."
    } else {
        $issues = "Consider updating docs/CHANGELOG.md for the significant changes made ($changedFiles files changed)."
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
