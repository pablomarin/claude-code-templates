# .claude/hooks/check-workflow-gates.ps1
# PreToolUse hook for Bash: blocks commit/push/PR if quality gates aren't complete.
#
# Fires BEFORE Bash commands. Only activates when:
# 1. An active workflow exists in CONTINUITY.md (Command != none)
# 2. The command is git commit, git push, or gh pr create
# 3. Always-required quality gate checklist items aren't checked off
#
# Only gates on ALWAYS-REQUIRED items (review, simplify, verify).
# Conditional items like "E2E tested (if API changed)" are NOT gated.
#
# Requirements: PowerShell 5.1+

# Read hook input from stdin
$jsonInput = [Console]::In.ReadToEnd()

# Parse JSON input
try {
    $data = $jsonInput | ConvertFrom-Json
} catch {
    exit 0
}

$command = $data.tool_input.command
if (-not $command) { exit 0 }

# --- Only gate ship actions ---
$isShip = $false
if ($command -match '^\s*git\s+commit\b') { $isShip = $true }
if ($command -match '^\s*git\s+push\b') { $isShip = $true }
if ($command -match '^\s*gh\s+pr\s+create\b') { $isShip = $true }

if (-not $isShip) { exit 0 }

# --- Check for active workflow ---
if (-not (Test-Path "CONTINUITY.md")) { exit 0 }

$content = Get-Content "CONTINUITY.md" -Raw 2>$null
$cmdLine = ($content -split "`n" | Select-String '\|\s*Command\s*\|' | Select-Object -First 1)
if (-not $cmdLine) { exit 0 }

$cmd = ($cmdLine -split '\|')[2].Trim()
if (-not $cmd -or $cmd -eq "none" -or $cmd -eq ([char]0x2014).ToString() -or $cmd -eq "-") { exit 0 }

# --- Active workflow: check always-required quality gates ---
# Extract checklist section
$inChecklist = $false
$unchecked = @()

foreach ($line in ($content -split "`n")) {
    if ($line -match '^### Checklist') { $inChecklist = $true; continue }
    if ($line -match '^## ' -and $inChecklist) { break }
    # Only gate on: "Code review loop", "Simplified", "Verified (tests"
    # Exclude: "PR reviews addressed" (post-PR), "Plugins verified" (pre-flight),
    #          "Plan review loop" (design phase discipline, not pre-ship gate)
    if ($inChecklist -and $line -match '- \[ \]' -and $line -match '(Code review loop|Simplified|Verified \(tests)') {
        $unchecked += $line
    }
}

if ($unchecked.Count -gt 0) {
    [Console]::Error.WriteLine("WORKFLOW GATE: $($unchecked.Count) required quality gate(s) incomplete.")
    [Console]::Error.WriteLine("Complete these before shipping:")
    foreach ($item in $unchecked) {
        [Console]::Error.WriteLine("  $($item.Trim() -replace '- \[ \] ', '- ')")
    }
    exit 2
}

exit 0
