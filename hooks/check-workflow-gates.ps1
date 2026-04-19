# .claude/hooks/check-workflow-gates.ps1
# PreToolUse hook for Bash: blocks commit/push/PR if quality gates aren't complete.
#
# Fires BEFORE Bash commands. Only activates when:
# 1. An active workflow exists in CONTINUITY.md (Command != none)
# 2. The command is git commit, git push, or gh pr create
# 3. Always-required quality gate checklist items aren't checked off
#
# Gated markers (canonical vocabulary — see rules/testing.md):
#   "Code review loop"  — code review must pass
#   "Simplified"        — simplification must run
#   "Verified (tests"   — tests/lint/types/migrations must pass
#   "E2E verified"      — Phase 5.4 must pass OR be checked [x] with N/A reason
#
# Non-gated (conditional) items ("E2E use cases designed", "E2E regression
# passed", post-PASS housekeeping) stay advisory — the model decides.
# The E2E verified gate has an explicit N/A escape:
#   - [x] E2E verified — N/A: <reason>
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
    # Gate on the 4 canonical pre-ship markers:
    #   Code review loop | Simplified | Verified (tests | E2E verified
    # Exclude non-gate items that share words:
    #   "PR reviews addressed" (post-PR), "Plugins verified" (pre-flight),
    #   "Plan review loop" (design phase), "E2E use cases designed/graduated"
    #   (Phase 3.2b / 6.2b — conditional), "E2E regression passed" (Phase 5.4b).
    if ($inChecklist -and $line -match '- \[ \]' -and $line -match '(Code review loop|Simplified|Verified \(tests|E2E verified)') {
        $unchecked += $line
    }
}

if ($unchecked.Count -gt 0) {
    [Console]::Error.WriteLine("WORKFLOW GATE: $($unchecked.Count) required quality gate(s) incomplete.")
    [Console]::Error.WriteLine("Complete these before shipping:")
    foreach ($item in $unchecked) {
        [Console]::Error.WriteLine("  $($item.Trim() -replace '- \[ \] ', '- ')")
    }
    [Console]::Error.WriteLine("")
    [Console]::Error.WriteLine("How to clear each gate:")
    [Console]::Error.WriteLine("  - Code review loop:  run /codex review + /pr-review-toolkit:review-pr, fix findings")
    [Console]::Error.WriteLine("  - Simplified:        run /simplify")
    [Console]::Error.WriteLine("  - Verified (tests):  run the verify-app agent")
    [Console]::Error.WriteLine("  - E2E verified:      run the verify-e2e agent AND persist its report, OR mark N/A:")
    [Console]::Error.WriteLine('                         - [x] E2E verified — N/A: <specific reason>')
    [Console]::Error.WriteLine("  See .claude\rules\testing.md for the canonical gate vocabulary.")
    exit 2
}

# ---------------------------------------------------------------------------
# Evidence-based gate for E2E verified. Mirrors the .sh logic:
# a checked '[x] E2E verified' without 'N/A:' must have a fresh report file
# in tests/e2e/reports/ whose LastWriteTime is later than the branch-off
# commit. Skips gracefully if git state prevents determining branch-off.
# ---------------------------------------------------------------------------
$e2eCheckedLine = $null
foreach ($line in ($content -split "`n")) {
    if ($line -match '- \[x\]\s+E2E verified') {
        $e2eCheckedLine = $line
        break
    }
}

if ($e2eCheckedLine -and ($e2eCheckedLine -notmatch 'N/A:')) {
    # Find branch-off commit (try main, fall back to master, else skip)
    $branchOff = git merge-base HEAD main 2>$null
    if (-not $branchOff) { $branchOff = git merge-base HEAD master 2>$null }

    # If HEAD itself IS the branch-off point (user is on main/master, not a
    # feature branch), there's no meaningful "produced on this branch"
    # comparison. Skip the evidence check — matches the documented "on main
    # → skip" contract in rules/testing.md.
    $headSha = git rev-parse HEAD 2>$null
    if ($branchOff -and $headSha -and ($branchOff.Trim() -eq $headSha.Trim())) {
        $branchOff = $null  # Force the skip path below
    }

    if ($branchOff) {
        $branchOffTsStr = git log -1 --format=%ct $branchOff 2>$null
        $branchOffTs = 0
        if ($branchOffTsStr) { $branchOffTs = [long]$branchOffTsStr }

        $branchOffDate = [DateTimeOffset]::FromUnixTimeSeconds($branchOffTs).LocalDateTime

        $freshReportFound = $false
        if (Test-Path "tests/e2e/reports") {
            $reports = Get-ChildItem "tests/e2e/reports" -Filter "*.md" -File -ErrorAction SilentlyContinue
            foreach ($report in $reports) {
                if ($report.LastWriteTime -gt $branchOffDate) {
                    $freshReportFound = $true
                    break
                }
            }
        }

        if (-not $freshReportFound) {
            [Console]::Error.WriteLine("WORKFLOW GATE: E2E verified is checked, but no fresh report was found.")
            [Console]::Error.WriteLine("")
            [Console]::Error.WriteLine("The checklist says [x] E2E verified, but tests\e2e\reports\ has no")
            [Console]::Error.WriteLine("report file newer than this branch's commit off main. That usually means")
            [Console]::Error.WriteLine("the verify-e2e agent was never actually run on this branch.")
            [Console]::Error.WriteLine("")
            [Console]::Error.WriteLine("Either:")
            [Console]::Error.WriteLine("  (a) Run the verify-e2e agent and have the main agent persist its")
            [Console]::Error.WriteLine("      report to tests\e2e\reports\<YYYY-MM-DD-HH-MM>-<feature>.md,")
            [Console]::Error.WriteLine("  (b) Mark the gate N/A with justification:")
            [Console]::Error.WriteLine('        - [x] E2E verified — N/A: <specific reason>')
            [Console]::Error.WriteLine("")
            [Console]::Error.WriteLine("See .claude\rules\testing.md for the full policy.")
            exit 2
        }
    }
    # No branch-off (user on main / no main or master) → skip evidence check.
}

exit 0
