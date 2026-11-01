# ============================================================
# Bonin Skills Auto-Sync Rollback (added 2026-11)
#
# Non-destructive rollback support for auto-sync changes.
#
# Modes:
#   -List                              List recent auto-sync commits (rollback candidates)
#   -Snapshot                          Record current HEAD as a restore anchor
#   -Revert [-Last <n>] [-RewindBaseline] [-Push]
#                                      git revert the last <n> sync commits (default 1)
#   -Restore -Path <dir> [-Anchor <sha>]
#                                      File-level restore of one skill dir to an
#                                      anchor commit state (default anchor = last snapshot)
#   -RestoreBaseline -Source <name>    Rewind one source baseline to its previous commit
#
# Common switches:
#   -DryRun    Show the plan without changing anything
#   -Yes       Skip the interactive confirmation prompt
#
# Safety design (by intent, NOT configurable here):
#   * git revert / git checkout <sha> -- <path> only - NO reset --hard,
#     NO push --force, NO branch -D, NO history rewrite.
#   * -Restore accepts only paths under skills/bonin-*
#   * Reverts and restores commit locally; push happens ONLY with -Push.
#   * Revert requires a clean working tree (user changes are never touched).
#   * Baselines: -Revert keeps the baseline by default (= skip the bad range on
#     next sync). Add -RewindBaseline to re-pull the same range after fixing
#     transform rules (re-sync scenario).
#
# Usage examples:
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -List
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -Snapshot
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -Revert -DryRun
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -Revert -Last 1 -RewindBaseline
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -Restore -Path skills/bonin-handraw-style
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -RestoreBaseline -Source handraw-style
# ============================================================

param(
    [switch]$List = $false,
    [switch]$Snapshot = $false,
    [switch]$Revert = $false,
    [switch]$Restore = $false,
    [switch]$RestoreBaseline = $false,
    [switch]$RewindBaseline = $false,
    [switch]$Push = $false,
    [switch]$DryRun = $false,
    [switch]$Yes = $false,
    [int]$Last = 1,
    [string]$Path = "",
    [string]$Anchor = "",
    [string]$Source = ""
)

$ErrorActionPreference = "Stop"
$scriptStart = Get-Date
$repo = "d:\Repo\bonin-skills"
$script:LogFile = Join-Path $PSScriptRoot "rollback.log"
$stateFile = Join-Path $PSScriptRoot "rollback-state.json"
$baselinesFile = Join-Path $PSScriptRoot "baselines.json"
$syncCommitGrep = "auto-sync from upstream"

# ============================================================
# Logging / helpers
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    $dir = Split-Path -Parent $script:LogFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -Path $script:LogFile -Value $line -Encoding UTF8
}

function Exit-With-Error {
    param([string]$Message)
    Write-Log -Message $Message -Level "ERROR"
    Write-Log -Message "Rollback aborted. Elapsed: $((Get-Date) - $scriptStart)" -Level "ERROR"
    exit 1
}

function Confirm-Action {
    param([string]$Message)
    if ($Yes) { return $true }
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow
    $answer = Read-Host "Proceed? (y/N)"
    return ($answer -eq "y" -or $answer -eq "Y")
}

function Get-GitOutput {
    param([string[]]$GitArgs)
    $out = & git -C $repo @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return $out
}

function Test-CleanTree {
    $status = Get-GitOutput @("status", "--porcelain")
    return ([string]::IsNullOrWhiteSpace(($status -join "")))
}

function Get-SyncCommits {
    param([int]$Count)
    # newest first, limited
    $out = Get-GitOutput @("log", "--grep=$syncCommitGrep", "-n", "$Count", "--format=%H|%h|%ad|%s", "--date=short")
    $result = @()
    foreach ($line in @($out)) {
        if (-not $line) { continue }
        $parts = $line -split '\|', 4
        if ($parts.Count -eq 4) {
            $result += [pscustomobject]@{
                Full    = $parts[0]
                Short   = $parts[1]
                Date    = $parts[2]
                Subject = $parts[3]
            }
        }
    }
    return $result
}

function Get-SourcesFromCommit {
    param([string]$Sha)
    $msg = Get-GitOutput @("log", "-1", "--format=%s", $Sha)
    if ($msg -match 'auto-sync from upstream \(([^)]*)\)') {
        return @(($Matches[1] -split ',\s*') | Where-Object { $_ -and $_ -ne "no source" })
    }
    return @()
}

function Get-AnchorCommit {
    if ($Anchor) { return $Anchor }
    if (Test-Path $stateFile) {
        try {
            $json = Get-Content -Path $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($json.anchor) { return [string]$json.anchor }
        }
        catch { }
    }
    return $null
}

function Rewind-Source-Baseline {
    param([string]$Name)
    if (-not (Test-Path $baselinesFile)) {
        Write-Log "  baselines.json not found; skip baseline rewind for [$Name]" -Level "WARN"
        return
    }
    try {
        $json = Get-Content -Path $baselinesFile -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        Write-Log "  baselines.json unreadable; skip baseline rewind for [$Name]" -Level "WARN"
        return
    }
    $entry = $json.$Name
    if (-not $entry) {
        Write-Log "  no baseline entry for [$Name] (hardcoded-baseline source); skip" -Level "WARN"
        return
    }
    $old = [string]$entry.baseline
    $new = [string]$entry.previous
    if (-not $new -or $new -eq $old) {
        Write-Log "  baseline for [$Name] already at its earliest point; skip" -Level "WARN"
        return
    }
    if ($DryRun) {
        Write-Log "  DRY RUN: would rewind baseline [$Name]: $old -> $new"
        return
    }
    $entry.baseline = $new
    $entry.previous = [string]$entry.initial
    $entry.updated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $jsonOut = $json | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($baselinesFile, $jsonOut, [System.Text.UTF8Encoding]::new($false))
    Write-Log "  Baseline rewound [$Name]: $old -> $new"
}

function Push-IfRequested {
    if (-not $Push) {
        Write-Log "Not pushing (local only). Push manually when ready:"
        Write-Log "  git -C $repo push origin master"
        return
    }
    Write-Log "Pushing to GitHub..."
    git -C $repo push origin master 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Push succeeded"
    }
    else {
        Write-Log "Push failed; commits remain local. Push manually when ready." -Level "WARN"
    }
}

function Show-Usage {
    Write-Host "Usage:"
    Write-Host "  rollback.ps1 -List"
    Write-Host "  rollback.ps1 -Snapshot"
    Write-Host "  rollback.ps1 -Revert [-Last <n>] [-RewindBaseline] [-Push]"
    Write-Host "  rollback.ps1 -Restore -Path <skills/bonin-*> [-Anchor <sha>]"
    Write-Host "  rollback.ps1 -RestoreBaseline -Source <book-to-skill|handraw-style>"
    Write-Host "Common switches: -DryRun -Yes"
}

# ============================================================
# Mode: List
# ============================================================

if ($List) {
    Write-Log "=== AUTO-SYNC COMMITS (newest first, last 20) ==="
    $commits = Get-SyncCommits -Count 20
    if ($commits.Count -eq 0) {
        Write-Log "  No auto-sync commits found"
    }
    foreach ($c in $commits) {
        Write-Log ("  {0}  {1}  {2}" -f $c.Short, $c.Date, $c.Subject)
    }
    Write-Log "Listed $($commits.Count) commit(s)"
    exit 0
}

# ============================================================
# Mode: Snapshot
# ============================================================

if ($Snapshot) {
    $head = Get-GitOutput @("rev-parse", "HEAD")
    if (-not $head) { Exit-With-Error "Cannot read HEAD of $repo" }
    if ($DryRun) {
        Write-Log "DRY RUN: would record anchor $head into rollback-state.json"
        exit 0
    }
    $state = @{
        anchor     = $head
        created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    $jsonOut = $state | ConvertTo-Json
    [System.IO.File]::WriteAllText($stateFile, $jsonOut, [System.Text.UTF8Encoding]::new($false))
    Write-Log "Snapshot recorded: anchor = $head"
    Write-Log "Anchor file: $stateFile"
    exit 0
}

# ============================================================
# Mode: Revert
# ============================================================

if ($Revert) {
    if ($Last -lt 1) { Exit-With-Error "-Last must be >= 1" }
    $commits = Get-SyncCommits -Count $Last
    if ($commits.Count -eq 0) {
        Write-Log "No auto-sync commits found; nothing to revert"
        exit 0
    }
    Write-Log "=== REVERT PLAN ==="
    Write-Log "Commits to revert (oldest first, so each revert applies cleanly):"
    $toRevert = @($commits)
    [array]::Reverse($toRevert)
    $affectedSources = @{}
    foreach ($c in $toRevert) {
        Write-Log ("  {0}  {1}" -f $c.Short, $c.Subject)
        foreach ($s in (Get-SourcesFromCommit -Sha $c.Full)) { $affectedSources[$s] = $true }
    }
    Write-Log "Affected sources: $(@($affectedSources.Keys) -join ', ')"
    if ($DryRun) {
        Write-Log "DRY RUN completed. No changes made."
        exit 0
    }

    if (-not (Test-CleanTree)) {
        Exit-With-Error "Working tree is not clean. Commit or stash your own changes first; this tool never touches them."
    }
    if (-not (Confirm-Action "Revert the $($commits.Count) commit(s) listed above?")) {
        Write-Log "Cancelled by user"
        exit 0
    }

    foreach ($c in $toRevert) {
        Write-Log "Reverting $($c.Short) ..."
        git -C $repo revert --no-edit $c.Full 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Exit-With-Error "git revert failed on $($c.Short). Resolve conflicts manually, then re-run remaining reverts."
        }
        Write-Log "Reverted $($c.Short)"
    }

    if ($RewindBaseline) {
        Write-Log "Rewinding baselines of affected sources (re-sync scenario)..."
        foreach ($name in @($affectedSources.Keys)) {
            Rewind-Source-Baseline -Name $name
        }
    }
    else {
        Write-Log "Baselines kept as-is (default): the reverted upstream range will be skipped on next sync."
        Write-Log "Use -RewindBaseline instead if you fixed transform rules and want to re-pull the same range."
    }

    Push-IfRequested
    Write-Log "Revert completed. Elapsed: $((Get-Date) - $scriptStart)"
    exit 0
}

# ============================================================
# Mode: Restore (file-level)
# ============================================================

if ($Restore) {
    if (-not $Path) { Exit-With-Error "-Restore requires -Path (e.g. skills/bonin-handraw-style)" }
    if ($Path -notmatch '^skills/bonin-[a-z0-9-]+$') {
        Exit-With-Error "-Path must match skills/bonin-* (safety guard: only skill dirs are restorable)"
    }
    $anchorCommit = Get-AnchorCommit
    if (-not $anchorCommit) {
        Exit-With-Error "No anchor available. Run -Snapshot first, or pass -Anchor <sha>."
    }
    Write-Log "=== RESTORE PLAN ==="
    Write-Log "Path:   $Path"
    Write-Log "Anchor: $anchorCommit"
    $diffStat = Get-GitOutput @("diff", "--stat", "$anchorCommit", "HEAD", "--", $Path)
    if (-not $diffStat) {
        Write-Log "No differences between anchor and HEAD for this path; nothing to restore"
        exit 0
    }
    $diffStat | Select-Object -First 20 | ForEach-Object { Write-Log "  $_" }
    if ($DryRun) {
        Write-Log "DRY RUN completed. No changes made."
        exit 0
    }
    if (-not (Confirm-Action "Restore $Path to anchor $anchorCommit? (Uncommitted changes inside that dir will be lost)")) {
        Write-Log "Cancelled by user"
        exit 0
    }

    git -C $repo checkout $anchorCommit -- $Path 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Exit-With-Error "git checkout failed for $Path"
    }
    $staged = Get-GitOutput @("status", "--porcelain", "--", $Path)
    if ($staged) {
        git -C $repo commit -m "chore(rollback): restore $Path to anchor $anchorCommit" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Exit-With-Error "Restore commit failed for $Path"
        }
        Write-Log "Restored $Path to anchor and committed"
    }
    else {
        Write-Log "Restored $Path - identical to HEAD, nothing to commit"
    }
    Push-IfRequested
    Write-Log "Restore completed. Elapsed: $((Get-Date) - $scriptStart)"
    exit 0
}

# ============================================================
# Mode: RestoreBaseline
# ============================================================

if ($RestoreBaseline) {
    if (-not $Source) { Exit-With-Error "-RestoreBaseline requires -Source (book-to-skill | handraw-style)" }
    Write-Log "=== BASELINE REWIND: $Source ==="
    Rewind-Source-Baseline -Name $Source
    Write-Log "Next auto-sync for [$Source] will re-pull from the rewound baseline"
    exit 0
}

# ============================================================
# No mode selected
# ============================================================

Show-Usage
exit 0
