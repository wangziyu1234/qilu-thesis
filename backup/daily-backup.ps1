param(
    [string]$CommitMessage = "",
    [string]$Remote = "lunwen",
    [string]$Branch = "main"
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

if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    $CommitMessage = "backup: " + (Get-Date -Format "yyyy-MM-dd HH:mm")
}

Run-Git add -A

$hasStagedChanges = (& git diff --cached --name-only)
if ([string]::IsNullOrWhiteSpace($hasStagedChanges)) {
    Write-Host "No changes to commit."
} else {
    Run-Git commit -m $CommitMessage
}

Run-Git push $Remote $Branch
Write-Host "Daily backup done: pushed to $Remote/$Branch"
