# ============================================================
# Bonin Skills 自动化同步程序
# Auto-Sync Program for bonin-skills
#
# 功能：
#   1. 监测源仓库（baoyu-skills, ljg-skills）的更新
#   2. 将更新同步到 bonin-skills（脱敏作者信息）
#   3. 更新文档
#   4. 执行全面代码审计
#   5. 提交并推送到 GitHub
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File auto-sync.ps1
#   powershell -ExecutionPolicy Bypass -File auto-sync.ps1 -DryRun
#   powershell -ExecutionPolicy Bypass -File auto-sync.ps1 -Force
# ============================================================

param(
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
$scriptStart = Get-Date
$script:LogFile = Join-Path $PSScriptRoot "sync.log"

# ============================================================
# 配置（硬编码，避免 YAML 解析问题）
# ============================================================

$baoyuRoot = "d:\Repo\baoyu-skills"
$ljgRoot = "d:\Repo\ljg-skills"
$boninRoot = "d:\Repo\bonin-skills"

$baoyuBaseline = "505a7e1"
$ljgBaseline = "0b77aa2"

$binaryExts = @(".png", ".webp", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".lock", ".lockb", ".pdf", ".zip", ".woff", ".woff2", ".ttf", ".eot")
$skipPatterns = @("^LICENSE$", "^\.gitignore$", "^package-lock\.json$", "^bun\.lockb$", "^\.releaserc\.yml$")

# ============================================================
# 工具函数
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
    Write-Log -Message "Sync failed. Elapsed: $((Get-Date) - $scriptStart)" -Level "ERROR"
    exit 1
}

# ============================================================
# Git 操作
# ============================================================

function Get-Repo-Head {
    param([string]$RepoPath)
    $head = git -C $RepoPath rev-parse HEAD 2>$null
    if ($head) { return $head.Trim() }
    return $null
}

function Get-Changed-Files {
    param([string]$RepoPath, [string]$FromCommit)
    return @(git -C $RepoPath diff --diff-filter=AM --name-only "$FromCommit..HEAD" 2>$null)
}

# ============================================================
# 内容转换
# ============================================================

function Transform-Content {
    param([string]$Content, [string]$Source)

    if ($Source -eq "baoyu") {
        $Content = $Content -replace 'github\.com/JimLiu/baoyu-skills', 'github.com/BoninEDU/bonin-skills'
        $Content = $Content -replace 'JimLiu/baoyu-skills', 'BoninEDU/bonin-skills'
        $Content = $Content -replace 'JimLiu', 'BoninEDU'
        $Content = $Content -creplace 'BAOYU', 'BONIN'
        $Content = $Content -creplace 'Baoyu', 'Bonin'
        $Content = $Content -creplace 'baoyu', 'bonin'
        # 贡献者脱敏
        $Content = $Content -replace ' \(by [^)\r\n]+\)', ''
        $Content = $Content -replace ' contributed by [^\s,]+', ''
        $Content = $Content -replace ' <[^>]+@[^>]+>', ''
        $Content = $Content -replace 'Credit to [^\r\n]+', ''
    }
    elseif ($Source -eq "ljg") {
        $Content = $Content -replace 'github\.com/lijigang/ljg-skills', 'github.com/BoninEDU/bonin-skills'
        $Content = $Content -replace 'lijigang/ljg-skills', 'BoninEDU/bonin-skills'
        $Content = $Content -replace 'github\.com/lijigang', 'github.com/BoninEDU'
        $Content = $Content -replace 'lijigang', 'BoninEDU'
        $Content = $Content -creplace 'LJG', 'BONIN'
        $Content = $Content -creplace 'Ljg', 'Bonin'
        $Content = $Content -creplace 'ljg', 'bonin'
        # SSH URL
        $at = [char]0x40
        $sshPattern = 'git' + $at + 'github\.com:lijigang/ljg-skills\.git'
        $sshReplacement = 'git' + $at + 'github.com:BoninEDU/bonin-skills.git'
        $Content = $Content -replace $sshPattern, $sshReplacement
    }

    return $Content
}

function Map-Path {
    param([string]$RelativePath, [string]$Source)
    if ($Source -eq "baoyu") {
        return $RelativePath -creplace 'baoyu', 'bonin'
    }
    elseif ($Source -eq "ljg") {
        return $RelativePath -creplace 'ljg', 'bonin'
    }
    return $RelativePath
}

# ============================================================
# 文件同步
# ============================================================

function Sync-File {
    param([string]$SrcRoot, [string]$RelPath, [string]$Source)

    $srcFile = Join-Path $SrcRoot $RelPath
    $destRelPath = Map-Path -RelativePath $RelPath -Source $Source
    $destFile = Join-Path $boninRoot $destRelPath

    if (-not (Test-Path $srcFile)) {
        Write-Log "  SKIP (not found): $RelPath"
        return $false
    }

    foreach ($pattern in $skipPatterns) {
        if ($RelPath -match $pattern) {
            Write-Log "  SKIP (pattern): $RelPath"
            return $false
        }
    }

    $destDir = Split-Path -Parent $destFile
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $ext = [System.IO.Path]::GetExtension($srcFile).ToLower()

    if ($binaryExts -contains $ext) {
        if (-not $DryRun) {
            Copy-Item -Path $srcFile -Destination $destFile -Force
        }
        Write-Log "  COPIED (binary): $destRelPath"
        return $true
    }

    $content = Get-Content -Path $srcFile -Raw -Encoding UTF8
    if ($null -eq $content) {
        Write-Log "  SKIP (empty): $RelPath"
        return $false
    }

    $transformed = Transform-Content -Content $content -Source $Source

    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($destFile, $transformed, [System.Text.UTF8Encoding]::new($false))
    }
    Write-Log "  SYNCED: $destRelPath"
    return $true
}

# ============================================================
# 审计
# ============================================================

function Invoke-Audit {
    Write-Log "=== AUDIT START ==="
    $issues = @()

    # 1. 检查 SKILL.md
    Write-Log "Checking SKILL.md files..."
    $skills = @(Get-ChildItem -Path (Join-Path $boninRoot "skills") -Directory -ErrorAction SilentlyContinue)
    foreach ($s in $skills) {
        $skillMd = Join-Path $s.FullName "SKILL.md"
        if (-not (Test-Path $skillMd)) {
            $issues += "MISSING SKILL.md: $($s.Name)"
            continue
        }
        $content = Get-Content -Path $skillMd -Raw -Encoding UTF8
        if (-not $content.StartsWith("---")) {
            $issues += "INVALID front matter: $($s.Name)"
        }
        if ($content -notmatch "name:\s*bonin-") {
            $issues += "MISSING name field: $($s.Name)"
        }
    }
    Write-Log "  Checked $($skills.Count) skills"

    # 2. 检查残留作者信息
    Write-Log "Checking for residual author info..."
    $forbidden = @("JimLiu", "lijigang", "baoyu-skills", "ljg-skills")
    foreach ($kw in $forbidden) {
        $matches = @(Select-String -Path (Join-Path $boninRoot "**\*") -Pattern $kw -SimpleMatch -ErrorAction SilentlyContinue |
            Where-Object { $_.Path -notmatch "\\.git\\" -and $_.Path -notmatch "node_modules" -and $_.Path -notmatch "\\.auto-sync\\" })
        if ($matches.Count -gt 0) {
            $issues += "FOUND '$kw': $($matches.Count) matches"
        }
    }

    # 3. 检查 package.json
    Write-Log "Checking package.json names..."
    $packageJsons = @(Get-ChildItem -Path $boninRoot -Recurse -Filter "package.json" |
        Where-Object { $_.FullName -notmatch "node_modules" })
    foreach ($p in $packageJsons) {
        $content = Get-Content -Path $p.FullName -Raw -Encoding UTF8
        if ($content -match '"name":\s*"baoyu' -or $content -match '"name":\s*"ljg') {
            $issues += "BAD package name: $($p.FullName)"
        }
    }
    Write-Log "  Checked $($packageJsons.Count) package.json files"

    # 4. 检查 bun.lock
    Write-Log "Checking bun.lock files..."
    $lockFiles = @(Get-ChildItem -Path $boninRoot -Recurse -Filter "bun.lock" |
        Where-Object { $_.FullName -notmatch "node_modules" })
    foreach ($f in $lockFiles) {
        $content = Get-Content -Path $f.FullName -Raw -Encoding UTF8
        if ($content -match 'baoyu' -or $content -match 'ljg') {
            $issues += "BAD lock file: $($f.FullName)"
        }
    }
    Write-Log "  Checked $($lockFiles.Count) bun.lock files"

    Write-Log "=== AUDIT RESULT ==="
    if ($issues.Count -eq 0) {
        Write-Log "  PASS: All checks passed"
        return $true
    }
    else {
        Write-Log "  FAIL: $($issues.Count) issues found"
        $issues | ForEach-Object { Write-Log "    - $_" }
        return $false
    }
}

# ============================================================
# 主流程
# ============================================================

Write-Log "========================================"
Write-Log "Bonin Skills Auto-Sync Started"
Write-Log "DryRun: $DryRun, Force: $Force"
Write-Log "========================================"

$totalSynced = 0
$totalSkipped = 0
$hasChanges = $false

# 处理 baoyu-skills
Write-Log ""
Write-Log "=== SOURCE: baoyu ==="
if (Test-Path $baoyuRoot) {
    $currentHead = Get-Repo-Head -RepoPath $baoyuRoot
    Write-Log "Baseline: $baoyuBaseline"
    Write-Log "Current HEAD: $currentHead"

    if ($currentHead -and ($currentHead -ne $baoyuBaseline -or $Force)) {
        $changedFiles = Get-Changed-Files -RepoPath $baoyuRoot -FromCommit $baoyuBaseline
        Write-Log "Changed files: $($changedFiles.Count)"

        if ($changedFiles.Count -gt 0 -or $Force) {
            $hasChanges = $true
            $synced = 0
            $skipped = 0
            foreach ($file in $changedFiles) {
                $result = Sync-File -SrcRoot $baoyuRoot -RelPath $file -Source "baoyu"
                if ($result) { $synced++ } else { $skipped++ }
            }
            $totalSynced += $synced
            $totalSkipped += $skipped
            Write-Log "baoyu: $synced synced, $skipped skipped"
        }
    }
    else {
        Write-Log "No changes since last sync"
    }
}
else {
    Write-Log "Source repo not found: $baoyuRoot" -Level "WARN"
}

# 处理 ljg-skills
Write-Log ""
Write-Log "=== SOURCE: ljg ==="
if (Test-Path $ljgRoot) {
    $currentHead = Get-Repo-Head -RepoPath $ljgRoot
    Write-Log "Baseline: $ljgBaseline"
    Write-Log "Current HEAD: $currentHead"

    if ($currentHead -and ($currentHead -ne $ljgBaseline -or $Force)) {
        $changedFiles = Get-Changed-Files -RepoPath $ljgRoot -FromCommit $ljgBaseline
        Write-Log "Changed files: $($changedFiles.Count)"

        if ($changedFiles.Count -gt 0 -or $Force) {
            $hasChanges = $true
            $synced = 0
            $skipped = 0
            foreach ($file in $changedFiles) {
                $result = Sync-File -SrcRoot $ljgRoot -RelPath $file -Source "ljg"
                if ($result) { $synced++ } else { $skipped++ }
            }
            $totalSynced += $synced
            $totalSkipped += $skipped
            Write-Log "ljg: $synced synced, $skipped skipped"
        }
    }
    else {
        Write-Log "No changes since last sync"
    }
}
else {
    Write-Log "Source repo not found: $ljgRoot" -Level "WARN"
}

# 修复 bun.lock
if ($hasChanges -and -not $DryRun) {
    Write-Log ""
    Write-Log "=== FIXING bun.lock FILES ==="
    $lockFiles = @(Get-ChildItem -Path $boninRoot -Recurse -Filter "bun.lock" |
        Where-Object { $_.FullName -notmatch "node_modules" })
    foreach ($f in $lockFiles) {
        $content = Get-Content -Path $f.FullName -Raw -Encoding UTF8
        $transformed = $content -creplace 'baoyu', 'bonin' -creplace 'Baoyu', 'Bonin' -creplace 'BAOYU', 'BONIN' -creplace 'ljg', 'bonin' -creplace 'Ljg', 'Bonin' -creplace 'LJG', 'BONIN'
        [System.IO.File]::WriteAllText($f.FullName, $transformed, [System.Text.UTF8Encoding]::new($false))
        Write-Log "  Fixed: $($f.FullName.Replace($boninRoot + '\', ''))"
    }
}

# 审计
if ($hasChanges -and -not $DryRun) {
    Write-Log ""
    $auditPassed = Invoke-Audit
    if (-not $auditPassed) {
        Exit-With-Error "Audit failed. Changes not committed."
    }

    # 提交
    Write-Log ""
    Write-Log "=== COMMITTING ==="
    git -C $boninRoot add -A 2>&1 | Out-Null
    $commitMsg = "feat: auto-sync from upstream - $totalSynced files synced"
    git -C $boninRoot commit -m $commitMsg 2>&1 | Out-Null
    Write-Log "Committed: $commitMsg"

    # 推送（重试 3 次）
    Write-Log ""
    Write-Log "=== PUSHING TO GITHUB ==="
    $pushed = $false
    for ($i = 1; $i -le 3; $i++) {
        Write-Log "Push attempt $i of 3..."
        git -C $boninRoot push origin master 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $pushed = $true
            Write-Log "Push succeeded"
            break
        }
        Write-Log "Push failed, retrying in 60s..." -Level "WARN"
        if ($i -lt 3) { Start-Sleep -Seconds 60 }
    }
    if (-not $pushed) {
        Write-Log "Push failed after 3 attempts. Committed locally." -Level "WARN"
    }
}

# 总结
Write-Log ""
Write-Log "========================================"
Write-Log "SYNC SUMMARY"
Write-Log "========================================"
Write-Log "Total synced: $totalSynced"
Write-Log "Total skipped: $totalSkipped"
Write-Log "Has changes: $hasChanges"
Write-Log "Dry run: $DryRun"
Write-Log "Elapsed: $((Get-Date) - $scriptStart)"
Write-Log "========================================"

if ($DryRun) {
    Write-Log "DRY RUN completed. No changes made."
}
elseif (-not $hasChanges) {
    Write-Log "No changes detected."
}
else {
    Write-Log "Sync completed successfully."
}

exit 0
