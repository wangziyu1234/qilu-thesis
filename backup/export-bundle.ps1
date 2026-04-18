param(
    [string]$OutputDir = "bundle",
    [string]$FilePrefix = "thesis-backup"
)

$ErrorActionPreference = "Stop"

function Run-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )
    & git @Args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Args -join ' ') failed"
    }
}

# Ensure we are inside a Git repository.
$insideRepo = (& git rev-parse --is-inside-work-tree 2>$null)
if ($LASTEXITCODE -ne 0 -or $insideRepo -ne "true") {
    throw "Current directory is not a Git repository."
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bundlePath = Join-Path $OutputDir "$FilePrefix-$timestamp.bundle"

Run-Git bundle create $bundlePath --all
Write-Host "Bundle exported: $bundlePath"
