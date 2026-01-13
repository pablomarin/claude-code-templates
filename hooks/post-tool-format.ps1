# .claude/hooks/post-tool-format.ps1
# This hook runs after Edit or Write tool is used.
# It automatically formats the modified file based on its type.
#
# Requirements: PowerShell 5.1+
# Optional: ruff (for Python), prettier (for JS/TS/JSON/MD)

# Read the hook input from stdin
$jsonInput = [Console]::In.ReadToEnd()

# Parse JSON input
try {
    $data = $jsonInput | ConvertFrom-Json
} catch {
    exit 0
}

# Extract file path
$filePath = $data.tool_input.file_path

if (-not $filePath) {
    exit 0
}

# Get file extension
$extension = [System.IO.Path]::GetExtension($filePath).ToLower()

# Format based on file type
switch ($extension) {
    ".py" {
        # Python files - format with ruff (from src directory if it exists)
        $srcPath = Join-Path (Get-Location) "src"
        if (Test-Path $srcPath) {
            Push-Location $srcPath
            uv run ruff format $filePath 2>$null
            Pop-Location
        } else {
            uv run ruff format $filePath 2>$null
        }
    }
    { $_ -in ".ts", ".tsx", ".js", ".jsx" } {
        # TypeScript/JavaScript files - format with prettier
        npx prettier --write $filePath 2>$null
    }
    ".json" {
        # JSON files - format with prettier
        npx prettier --write $filePath 2>$null
    }
    ".md" {
        # Markdown files - format with prettier
        npx prettier --write $filePath 2>$null
    }
}

exit 0
