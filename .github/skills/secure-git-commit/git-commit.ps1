# Secure Git Commit Script
# Purpose: Reusable script for committing and pushing changes without exposing credentials
# Requirements: SSH authentication configured (see SKILL.md for setup)
# Usage: .\git-commit.ps1 -Message "Your commit message" [-RepoPath "."]

param(
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoPath = "."
)

# Navigate to repo
Push-Location $RepoPath

try {
    # Verify we're in a git repository
    if (-not (Test-Path ".git")) {
        Write-Error "Not a git repository. Run from repo root or specify -RepoPath"
        exit 1
    }

    # Stage all changes
    Write-Host "Staging changes..." -ForegroundColor Cyan
    git add .
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }

    # Commit
    Write-Host "Committing with message: '$Message'" -ForegroundColor Cyan
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

    # Push
    Write-Host "Pushing to remote..." -ForegroundColor Cyan
    git push
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }

    Write-Host "✓ Commit pushed successfully!" -ForegroundColor Green
}
finally {
    Pop-Location
}
