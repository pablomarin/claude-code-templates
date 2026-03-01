# SessionStart hook: silently inject git branch into Claude's context
# Uses hookSpecificOutput.additionalContext for clean, non-visible injection

try {
    $branch = git branch --show-current 2>$null
    if (-not $branch) { $branch = "unknown" }
} catch {
    $branch = "unknown"
}

$output = @{
    hookSpecificOutput = @{
        hookEventName    = "SessionStart"
        additionalContext = "Current branch: $branch"
    }
} | ConvertTo-Json -Compress

Write-Output $output
exit 0
