# scripts/migrate-continuity.ps1
# PowerShell mirror of scripts/migrate-continuity.sh
# Same algorithm, same byte-equivalent outputs (AC-4 parity).
# Forge-internal -- not shipped to downstream installs.

# Do NOT set $ErrorActionPreference = "Stop" globally -- we handle errors explicitly,
# matching the bash 'set -u' (no -e) discipline.
Set-StrictMode -Version Latest

$LegacyFile = "CONTINUITY.md"
$SentinelPrefix = "<!-- forge:migrated"
$SentinelToday = "<!-- forge:migrated $(Get-Date -Format 'yyyy-MM-dd') -->"

# BOM-less UTF-8 encoding for all writes -- Set-Content -Encoding utf8 on
# Windows PowerShell 5.1 emits a BOM, which breaks AC-4 byte-equivalence with
# the bash mirror. PowerShell 7+ has -Encoding utf8NoBOM but 5.1 doesn't, so
# use System.IO.File + System.Text.UTF8Encoding($false) for portability.
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    # Resolve to absolute path. System.IO.File.WriteAllText needs an absolute
    # path because it uses .NET's CWD, not PowerShell's (these can diverge).
    if ([System.IO.Path]::IsPathRooted($Path)) {
        $abs = $Path
    } else {
        $abs = Join-Path (Get-Location).ProviderPath $Path
    }
    [System.IO.File]::WriteAllText($abs, $Content, $script:Utf8NoBom)
}

if (-not (Test-Path $LegacyFile)) {
    Write-Output "!  No CONTINUITY.md found in this directory. Nothing to migrate."
    exit 0
}

# --- Idempotency check ---
function Test-AlreadyMigrated {
    if ((Test-Path "CLAUDE.md") -and (Select-String -Path "CLAUDE.md" -SimpleMatch $SentinelPrefix -Quiet -ErrorAction SilentlyContinue)) { return $true }
    if ((Test-Path ".claude/local/state.md") -and (Select-String -Path ".claude/local/state.md" -SimpleMatch $SentinelPrefix -Quiet -ErrorAction SilentlyContinue)) { return $true }
    return $false
}

if (Test-AlreadyMigrated) {
    $existing = ""
    foreach ($f in @("CLAUDE.md", ".claude/local/state.md")) {
        if (Test-Path $f) {
            $found = Select-String -Path $f -Pattern '<!-- forge:migrated [^>]*-->' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) { $existing = $found.Matches[0].Value; break }
        }
    }
    # Strip "<!-- forge:migrated " prefix and " -->" suffix to get the date.
    $existingDate = $existing -replace '^<!--\s*forge:migrated\s+', '' -replace '\s+-->\s*$', ''
    if ($existingDate) {
        Write-Output "Already migrated on $existingDate."
    } else {
        Write-Output "Already migrated."
    }
    Write-Output "  Sentinel marker detected in CLAUDE.md or .claude/local/state.md."
    Write-Output "  No content was modified. To force a fresh migration, remove the marker line(s) and rerun."
    exit 0
}

# --- Sentinel write -- UNCONDITIONAL, before any extraction (Codex iter-2 P0 fix) ---
# Validate state.md presence FIRST (Codex iter-3 P1: bail before printing "Migrating...").
# P3 fix: don't pre-create .claude/local/ -- on the failure path it leaves an empty
# .claude/local/ behind in the user's repo. Skip the dir if state.md isn't present.
if (-not (Test-Path ".claude/local/state.md")) {
    # Byte-equivalent to bash variant for AC-4 parity.
    [Console]::Error.WriteLine("x .claude/local/state.md not found.")
    [Console]::Error.WriteLine("  Run setup -f first to install the state template, then rerun --migrate.")
    exit 1
}
# Prepend sentinel to state.md (line 1).
$stateContent = Get-Content ".claude/local/state.md" -Raw
if ($null -eq $stateContent) { $stateContent = "" }
Write-Utf8NoBom ".claude/local/state.md" "$SentinelToday`n$stateContent"

# Prepend sentinel to CLAUDE.md (line 1) -- matches state.md treatment + AC-10
# amendment. Forge dogfood result confirmed line-1 placement is the desired
# behavior; the original "after H1" wording was wrong.
if ((Test-Path "CLAUDE.md") -and -not (Select-String -Path "CLAUDE.md" -SimpleMatch $SentinelPrefix -Quiet -ErrorAction SilentlyContinue)) {
    $claudeRaw = Get-Content "CLAUDE.md" -Raw
    if ($null -eq $claudeRaw) { $claudeRaw = "" }
    Write-Utf8NoBom "CLAUDE.md" "$SentinelToday`n$claudeRaw"
}

# Print "Migrating..." AFTER validation passes (Codex iter-3 P1 fix).
Write-Output "Migrating $LegacyFile..."
Write-Output ""

$movedSections = New-Object System.Collections.ArrayList
$skippedSections = New-Object System.Collections.ArrayList
$createdAdrs = New-Object System.Collections.ArrayList
$warnings = New-Object System.Collections.ArrayList

# --- (a) Extract Goal section to CLAUDE.md ---
$legacyContent = Get-Content $LegacyFile
$goalLines = New-Object System.Collections.ArrayList
$inGoal = $false
foreach ($line in $legacyContent) {
    if ($line -match '^## Goal$') { $inGoal = $true; continue }
    if ($inGoal -and $line -match '^## ') { $inGoal = $false }
    if ($inGoal) { [void]$goalLines.Add($line) }
}
# Trim leading and trailing blank lines (preserve interior -- multi-paragraph goals).
while ($goalLines.Count -gt 0 -and $goalLines[0].Trim() -eq "") { $goalLines.RemoveAt(0) }
while ($goalLines.Count -gt 0 -and $goalLines[$goalLines.Count - 1].Trim() -eq "") { $goalLines.RemoveAt($goalLines.Count - 1) }

$goalText = ($goalLines -join "`n")
$goalTrimmed = $goalText.Trim()
$goalPlaceholder = "[PROJECT GOAL - One sentence describing what we're building]"

if ($goalTrimmed -ne "" -and $goalTrimmed -ne $goalPlaceholder) {
    if (Test-Path "CLAUDE.md") {
        if (Select-String -Path "CLAUDE.md" -Pattern '^## Project Overview' -Quiet -ErrorAction SilentlyContinue) {
            $claudeLines = Get-Content "CLAUDE.md"
            $newClaude = New-Object System.Collections.ArrayList
            foreach ($line in $claudeLines) {
                [void]$newClaude.Add($line)
                if ($line -match '^## Project Overview$') {
                    [void]$newClaude.Add("")
                    [void]$newClaude.Add("### Goal")
                    [void]$newClaude.Add("")
                    [void]$newClaude.Add($goalText)
                    [void]$newClaude.Add("")
                }
            }
            Write-Utf8NoBom "CLAUDE.md" (($newClaude -join "`n") + "`n")
            [void]$movedSections.Add("Goal -> CLAUDE.md (under ## Project Overview)")
        } else {
            [void]$skippedSections.Add("Goal (CLAUDE.md has no ## Project Overview section)")
        }
    } else {
        [void]$skippedSections.Add("Goal (CLAUDE.md not present)")
    }
} else {
    [void]$skippedSections.Add("Goal (placeholder content; not migrated)")
}

# --- (b) Extract Architecture/Key Decisions table rows to per-file ADRs ---
$decisionsLines = New-Object System.Collections.ArrayList
$inDecisions = $false
foreach ($line in $legacyContent) {
    if ($line -match '^## (Architecture Decisions|Key Decisions)$') { $inDecisions = $true; continue }
    if ($inDecisions -and $line -match '^## ') { $inDecisions = $false }
    if ($inDecisions) { [void]$decisionsLines.Add($line) }
}

if ($decisionsLines.Count -gt 0) {
    # Find next available ADR number. Test-Path with glob doesn't work like bash
    # globbing -- must use Get-ChildItem -Filter for actual wildcard matching.
    $nextNum = 6
    while (@(Get-ChildItem -Path "docs/adr" -Filter "$('{0:D4}' -f $nextNum)-*.md" -ErrorAction SilentlyContinue).Count -gt 0) {
        $nextNum++
    }

    foreach ($line in $decisionsLines) {
        # Only data rows of a markdown pipe table.
        if ($line -notmatch '^\|.*\|$') { continue }
        # Skip header (first cell == "Decision").
        if ($line -match '^\|\s*Decision\s*\|') { continue }
        # Skip separator (cells are dashes/colons).
        if ($line -match '^\|\s*[:\-]') { continue }
        # Skip empty/whitespace-only rows.
        $stripped = ($line -replace '[\s|]', '')
        if ($stripped -eq "") { continue }

        $cells = $line.Split('|') | ForEach-Object { $_.Trim() }
        # cells[0] is empty (before first |), cells[1]=decision, cells[2]=choice, cells[3]=why, cells[4] is empty
        $decision = if ($cells.Count -gt 1) { $cells[1] } else { "" }
        $choice = if ($cells.Count -gt 2) { $cells[2] } else { "" }
        $why = if ($cells.Count -gt 3) { $cells[3] } else { "" }

        if ($decision -eq "" -or $choice -eq "") { continue }

        $slug = ($decision.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-+|-+$', '')
        $adrNum = '{0:D4}' -f $nextNum
        $adrFile = "docs/adr/$adrNum-$slug.md"

        # Idempotency at slug level -- use Get-ChildItem -Filter for actual glob matching.
        if (@(Get-ChildItem -Path "docs/adr" -Filter "*-$slug.md" -ErrorAction SilentlyContinue).Count -gt 0) {
            [void]$skippedSections.Add("Decision '$decision' (ADR with slug '$slug' already exists)")
            continue
        }

        if (-not (Test-Path "docs/adr")) { New-Item -ItemType Directory -Path "docs/adr" -Force | Out-Null }
        $whyText = if ($why -eq "") { "(empty in legacy CONTINUITY.md - please fill in)" } else { $why }
        $adrContent = @"
# $adrNum -- $decision

## Status

Accepted (migrated $(Get-Date -Format 'yyyy-MM-dd'))

## Context

Migrated from legacy CONTINUITY.md Architecture Decisions table.

## Considered Options

- **$choice (chosen)**

## Decision

$choice

## Consequences

$whyText
"@
        # ADR content uses here-string with trailing newline; ensure file ends with newline.
        Write-Utf8NoBom $adrFile ($adrContent + "`n")
        [void]$createdAdrs.Add($adrFile)
        [void]$movedSections.Add("Decision '$decision' -> $adrFile")
        $nextNum++
    }
}

# --- (c) Extract volatile sections to .claude/local/state.md ---
# state.md presence already verified at the top.
# Done: keep the LAST 3 entries (most recent), not the first.
$doneLines = New-Object System.Collections.ArrayList
$inDone = $false
foreach ($line in $legacyContent) {
    if ($line -match '^### Done(\s|$|[^a-zA-Z0-9])') { $inDone = $true; continue }
    if ($inDone -and $line -match '^### ') { $inDone = $false }
    if ($inDone -and $line -match '^- ') { [void]$doneLines.Add($line) }
}
# Take last 3 entries.
$doneTail = if ($doneLines.Count -gt 3) {
    $doneLines | Select-Object -Last 3
} else {
    $doneLines
}

if ($doneTail.Count -gt 0) {
    $stateLines = Get-Content ".claude/local/state.md"
    $newState = New-Object System.Collections.ArrayList
    $inDoneState = $false
    foreach ($line in $stateLines) {
        if ($line -match '^### Done') {
            [void]$newState.Add($line)
            [void]$newState.Add("")
            foreach ($d in $doneTail) { [void]$newState.Add($d) }
            [void]$newState.Add("")
            $inDoneState = $true
            continue
        }
        if ($inDoneState -and $line -match '^### ') { $inDoneState = $false }
        if (-not $inDoneState) { [void]$newState.Add($line) }
    }
    Write-Utf8NoBom ".claude/local/state.md" (($newState -join "`n") + "`n")
    [void]$movedSections.Add("Done (last 3 entries) -> .claude/local/state.md")
}

# Now/Next: replace placeholder content with migrated content.
foreach ($section in @("Now", "Next")) {
    $sectionLines = New-Object System.Collections.ArrayList
    $inSection = $false
    foreach ($line in $legacyContent) {
        if ($line -match "^### $section(\s|`$|[^a-zA-Z0-9])") { $inSection = $true; continue }
        if ($inSection -and $line -match '^### ') { $inSection = $false }
        if ($inSection) { [void]$sectionLines.Add($line) }
    }

    if ($sectionLines.Count -gt 0) {
        $stateLines = Get-Content ".claude/local/state.md"
        $newState = New-Object System.Collections.ArrayList
        $inSectionState = $false
        foreach ($line in $stateLines) {
            if ($line -match "^### $section(\s|`$|[^a-zA-Z0-9])") {
                [void]$newState.Add($line)
                [void]$newState.Add("")
                foreach ($s in $sectionLines) { [void]$newState.Add($s) }
                $inSectionState = $true
                continue
            }
            if ($inSectionState -and $line -match '^### ') {
                $inSectionState = $false
                [void]$newState.Add($line)
                continue
            }
            if (-not $inSectionState) { [void]$newState.Add($line) }
        }
        Write-Utf8NoBom ".claude/local/state.md" (($newState -join "`n") + "`n")
        [void]$movedSections.Add("$section -> .claude/local/state.md")
    }
}

# --- (d) Flag dangling @CONTINUITY.md import in CLAUDE.md ---
if ((Test-Path "CLAUDE.md") -and (Select-String -Path "CLAUDE.md" -Pattern '^@CONTINUITY\.md\b' -Quiet -ErrorAction SilentlyContinue)) {
    [void]$warnings.Add("CLAUDE.md still contains a '@CONTINUITY.md' dangling import - Claude Code silently ignores missing imports, but you may want to remove the line manually for cleanliness.")
}

# --- (e) Print summary (byte-equivalent strings to bash) ---
Write-Output "Migration complete."
Write-Output ""
Write-Output "Moved:"
if ($movedSections.Count -eq 0) {
    Write-Output "  (nothing - content was either placeholder or already migrated)"
} else {
    foreach ($s in $movedSections) { Write-Output "  + $s" }
}
Write-Output ""
if ($skippedSections.Count -gt 0) {
    Write-Output "Skipped:"
    foreach ($s in $skippedSections) { Write-Output "  . $s" }
    Write-Output ""
}
if ($createdAdrs.Count -gt 0) {
    Write-Output "ADRs created:"
    foreach ($a in $createdAdrs) { Write-Output "  + $a" }
    Write-Output ""
}
if ($warnings.Count -gt 0) {
    Write-Output "Warnings:"
    foreach ($w in $warnings) { Write-Output "  ! $w" }
    Write-Output ""
}
Write-Output "Original CONTINUITY.md was preserved in place (byte-for-byte)."
Write-Output "Review the migrated content, then delete CONTINUITY.md when satisfied."
exit 0
