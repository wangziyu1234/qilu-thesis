param(
    [Parameter(Mandatory = $true)]
    [string]$TagName,
    [string]$TagMessage = "",
    [string]$Remote = "lunwen"
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

$exists = (& git tag -l $TagName)
if (-not [string]::IsNullOrWhiteSpace($exists)) {
    throw "Tag '$TagName' already exists. Please use a different name."
}

if ([string]::IsNullOrWhiteSpace($TagMessage)) {
    $TagMessage = "milestone: $TagName"
}

Run-Git tag -a $TagName -m $TagMessage
Run-Git push $Remote $TagName

Write-Host "Milestone tag created and pushed: $TagName"
