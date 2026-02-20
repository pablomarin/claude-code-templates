# .claude\hooks\pre-compact-memory.ps1 (also used globally at ~\.claude\hooks\)
# This hook runs BEFORE context compaction.
# It outputs a reminder for Claude to save learnings to auto memory.
#
# The prompt-based PreCompact hook in settings.json handles the actual
# memory save instruction. This script provides additional context about
# the current session state.

$ErrorActionPreference = "Stop"

# Read JSON input from stdin
$jsonInput = $input | Out-String
if ([string]::IsNullOrWhiteSpace($jsonInput)) {
    $jsonInput = '{}'
}

try {
    $inputObj = $jsonInput | ConvertFrom-Json
} catch {
    $inputObj = @{}
}

$trigger = if ($inputObj.trigger) { $inputObj.trigger } else { "unknown" }
$sessionId = if ($inputObj.session_id) { $inputObj.session_id } else { "unknown" }
$cwd = if ($inputObj.cwd) { $inputObj.cwd } else { (Get-Location).Path }

# Determine the auto memory directory for this project
try {
    $gitRoot = (git -C $cwd rev-parse --show-toplevel 2>$null)
    if (-not $gitRoot) { $gitRoot = $cwd }
} catch {
    $gitRoot = $cwd
}

$projectKey = $gitRoot -replace '[/\\:]', '-'
$memoryDir = Join-Path $HOME ".claude" "projects" $projectKey "memory"

# Check if MEMORY.md exists and get its size
$memoryExists = $false
$memoryLines = 0
$memoryFile = Join-Path $memoryDir "MEMORY.md"
if (Test-Path $memoryFile) {
    $memoryExists = $true
    $memoryLines = (Get-Content $memoryFile | Measure-Object -Line).Lines
}

# Count topic files
$topicFiles = 0
if (Test-Path $memoryDir) {
    $topicFiles = (Get-ChildItem -Path $memoryDir -Filter "*.md" -File | Where-Object { $_.Name -ne "MEMORY.md" } | Measure-Object).Count
}

# Output context as additional information (shown in verbose mode)
Write-Output "Pre-compact memory check: trigger=$trigger, memory_exists=$memoryExists, memory_lines=$memoryLines, topic_files=$topicFiles"
exit 0
