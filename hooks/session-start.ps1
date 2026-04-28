# SessionStart hook: silently inject git context into Claude.
# Source-gated: git fetch + behind-check ONLY on startup|resume.

$ErrorActionPreference = 'SilentlyContinue'

# Read stdin JSON to get the session source ('startup'|'resume'|'clear'|'compact').
$inputJson = [Console]::In.ReadToEnd()
$source = ""
try {
    $data = $inputJson | ConvertFrom-Json
    if ($data.source) { $source = $data.source }
} catch { $source = "" }

try {
    $branch = git branch --show-current 2>$null
    if (-not $branch) { $branch = "unknown" }
} catch {
    $branch = "unknown"
}

$context = "Current branch: $branch"

if ($source -eq "startup" -or $source -eq "resume") {
    # Dot-source (not subprocess) — works in both PowerShell 5.1 (powershell.exe)
    # and 7 (pwsh). Spawning pwsh would fail on stock Windows.
    $hookDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $libPath = Join-Path $hookDir "lib\default-branch.ps1"
    $default = ""
    if (Test-Path $libPath) {
        . $libPath
        $detected = Get-DefaultBranch
        if ($detected) { $default = $detected }
    }

    if ($default) {
        # Run fetch with a 5s job timeout (PowerShell-native, no coreutils dependency).
        # CRITICAL: Start-Job's child runspace defaults its location to the user's
        # home directory (PS 5.1) or the parent's $PWD only if -WorkingDirectory is
        # passed (PS 6+). For 5.1 compatibility we capture $PWD outside and
        # Set-Location inside the job block so git runs in the actual repo.
        $cwd = (Get-Location).Path
        $job = Start-Job -ArgumentList $cwd -ScriptBlock {
            param($dir)
            Set-Location -LiteralPath $dir
            git fetch origin --quiet 2>$null
        }
        $completed = Wait-Job $job -Timeout 5
        Receive-Job $job -ErrorAction SilentlyContinue | Out-Null
        Remove-Job $job -Force -ErrorAction SilentlyContinue

        if ($completed) {
            $behind = git rev-list --count "$default..origin/$default" 2>$null
            if ($behind -and $behind -match '^\d+$' -and [int]$behind -gt 0) {
                $context = "$context (default branch '$default' is $behind commits behind origin — pull before starting work)"
            }
        }
    }
}

$output = @{
    hookSpecificOutput = @{
        hookEventName     = "SessionStart"
        additionalContext = $context
    }
} | ConvertTo-Json -Compress

Write-Output $output
exit 0
