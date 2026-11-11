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
# 2026-11 extension: also syncs book-to-skill -> skills/bonin-book-to-skill/
#                    and handraw-style -> skills/bonin-handraw-style/ (dest_prefix mapping).
#                    Baselines for the two new sources live in baselines.json
#                    (auto-advanced after a successful commit).
#                    Rollback support: see rollback.ps1 (revert sync commits /
#                    restore skill dirs / rewind baselines).
# 2026-11-10 extension: also syncs stickman-video-director ->
#                    skills/bonin-stickman-video-director/ (attribution-
#                    preserving: UTM strip + CRLF->LF normalize only; LICENSE /
#                    package-lock.json / .gitignore kept via keep-override;
#                    binary media ext added to $binaryExts).
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

# ------------------------------------------------------------
# Sources added 2026-11 (additive, backward compatible)
# ------------------------------------------------------------
$bookRoot = "d:\Repo\book-to-skill"
$handrawRoot = "d:\Repo\handraw-style"
$stickmanRoot = "d:\Repo\stickman-video-director"

# Initial baselines = upstream HEAD at migration time (2026-11-01).
# Live baselines are read from baselines.json at runtime (auto-advanced).
$bookInitialBaseline = "7540eefbe74933f5fc84c86becac52486b347778"
$handrawInitialBaseline = "572dff8f8cc1dc16ff9bef1422e90b3dfc42284d"
# stickman-video-director migrated 2026-11-10 (upstream HEAD at migration).
$stickmanInitialBaseline = "2f018c9112a87874ea83f88549ad93837b30b8df"

# dest_prefix: upstream repo root maps under this prefix inside bonin-skills
$bookDestPrefix = "skills/bonin-book-to-skill"
$handrawDestPrefix = "skills/bonin-handraw-style"
$stickmanDestPrefix = "skills/bonin-stickman-video-director"

# Source-specific skip patterns = files excluded at migration time
# (upstream-only promo / packaging / repo metadata, never synced)
$bookSkipPatterns = @(
    "^\.github/",
    "^BACKERS\.md$",
    "^CONTRIBUTING\.md$",
    "^LICENSE\.md$",
    "^SECURITY\.md$",
    "^SECURITY-NOTICE\.md$",
    "^README\.md$",
    "^README\.ru\.md$",
    "^README\.zh-CN\.md$",
    "^CLAUDE\.md$",
    "^mkdocs\.yml$",
    "^cliff\.toml$",
    "^overrides/",
    "^docs/index\.md$",
    "^docs/404\.md$",
    "^docs/CNAME$",
    "^docs/robots\.txt$",
    "^docs/assets/"
)
$handrawSkipPatterns = @(
    "^\.github/",
    "^README\.md$",
    "^README_en\.md$",
    "^RELEASE_AUDIT\.md$",
    "^build_workbuddy_release\.py$",
    "^scripts/workbuddy_check_audit\.py$",
    "^scripts/workbuddy_midnight_resubmit\.py$",
    "^scripts/sync_to_static\.py$",
    "^scripts/discourse_client\.py$",
    "^scripts/audit_release\.py$",
    "^scripts/package_skill\.py$"
)

$binaryExts = @(".png", ".webp", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".lock", ".lockb", ".pdf", ".zip", ".woff", ".woff2", ".ttf", ".eot", ".mp3", ".wav", ".mp4", ".m4a", ".ogg", ".flac")
$skipPatterns = @("^LICENSE$", "^\.gitignore$", "^package-lock\.json$", "^bun\.lockb$", "^\.releaserc\.yml$")

# stickman-video-director (added 2026-11-10)
# Source-specific skip patterns = files excluded at migration time
# (marketing preview media / sponsor banners / localized READMEs /
#  upstream-only QA harness depending on them or on git history).
$stickmanSkipPatterns = @(
    "^\.github/",
    "^assets/readme/",
    "^assets/sponsors/",
    "^scripts/optimize-readme-previews\.sh$",
    "^README(\.[a-zA-Z-]+)?\.md$",
    "^tests/reports/",
    "^tests/verify-chinese-onboarding\.py$",
    "^tests/verify-localized-readmes\.py$",
    "^tests/verify-thumbnail-kit\.py$",
    "^tests/verify-voice-continuity\.py$",
    "^tests/verify-first-use-guidance\.py$",
    "^tests/verify-readmes\.sh$"
)
# Keep-override for the global $skipPatterns: this source must sync
# LICENSE (MIT attribution preserved by design), package-lock.json
# (fingerprint / npm-ci stability) and .gitignore (node_modules/.env
# exclusions inside the skill dir) even though the global list drops
# them for legacy sources.
$stickmanKeepPatterns = @("^LICENSE$", "^\.gitignore$", "^package-lock\.json$")

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
# Baseline state (baselines.json) - added 2026-11
# Applied to the two new sources only; baoyu/ljg keep their
# hardcoded baselines (legacy behavior untouched).
# ============================================================

$script:BaselinesFile = Join-Path $PSScriptRoot "baselines.json"

function Get-Source-Baseline {
    param([string]$Name, [string]$Initial)
    if (Test-Path $script:BaselinesFile) {
        try {
            $json = Get-Content -Path $script:BaselinesFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $entry = $json.$Name
            if ($entry -and $entry.baseline) { return [string]$entry.baseline }
        }
        catch {
            Write-Log "WARN: baselines.json unreadable, using initial baseline for [$Name]" -Level "WARN"
        }
    }
    return $Initial
}

function Update-Source-Baseline {
    param([string]$Name, [string]$Commit, [string]$Initial)
    $state = [ordered]@{}
    if (Test-Path $script:BaselinesFile) {
        try {
            $raw = Get-Content -Path $script:BaselinesFile -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($p in $raw.PSObject.Properties) {
                $state[$p.Name] = @{
                    initial    = [string]$p.Value.initial
                    previous   = [string]$p.Value.previous
                    baseline   = [string]$p.Value.baseline
                    updated_at = [string]$p.Value.updated_at
                }
            }
        }
        catch {
            Write-Log "WARN: baselines.json unreadable, recreating it" -Level "WARN"
        }
    }
    if ($state.Contains($Name)) {
        $state[$Name].previous = $state[$Name].baseline
        $state[$Name].baseline = $Commit
    }
    else {
        $state[$Name] = @{
            initial  = $Initial
            previous = $Initial
            baseline = $Commit
        }
    }
    $state[$Name].updated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $jsonOut = $state | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($script:BaselinesFile, $jsonOut, [System.Text.UTF8Encoding]::new($false))
    Write-Log "  Baseline advanced [$Name] -> $Commit"
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
    elseif ($Source -eq "book") {
        # R1-R3: upstream GitHub URLs (longest first)
        $Content = $Content -replace 'github\.com/virgiliojr94/book-to-skill', 'github.com/BoninEDU/bonin-skills'
        $Content = $Content -replace 'virgiliojr94/book-to-skill', 'BoninEDU/bonin-skills'
        $Content = $Content -replace 'github\.com/virgiliojr94', 'github.com/BoninEDU'
        # R4: upstream author account
        $Content = $Content -replace 'virgiliojr94', 'BoninEDU'
        # R7: brand/title forms (case-sensitive, must run BEFORE the generic
        # hyphen form below, otherwise titles would be lowercased).
        # Negative lookbehind keeps re-runs idempotent: already-migrated
        # text like "Bonin Book-to-Skill" must not be prefixed twice.
        $Content = $Content -creplace '(?<!Bonin )Book-to-Skill', 'Bonin Book-to-Skill'
        $Content = $Content -creplace '(?<!BONIN-)BOOK-TO-SKILL', 'BONIN-BOOK-TO-SKILL'
        $Content = $Content -creplace 'Booklin', 'Bonin'
        $Content = $Content -creplace 'booklin', 'bonin'
        # R5: python package name (underscore form, lookbehind = idempotent)
        $Content = $Content -creplace '(?<!bonin_)book_to_skill', 'bonin_book_to_skill'
        # R6: CLI / skill name (hyphen form, lookbehind = idempotent)
        $Content = $Content -creplace '(?<!bonin-)book-to-skill', 'bonin-book-to-skill'
        # R8: email leftovers
        $Content = $Content -replace ' <[^>]+@[^>]+>', ''
    }
    elseif ($Source -eq "handraw") {
        # H1/H2: upstream domains -> Bonin site (longest first)
        $Content = $Content -replace 'static\.handraw-style\.com', 'www.boninaigc.top'
        $Content = $Content -replace 'img\.handraw-style\.com', 'www.boninaigc.top'
        $Content = $Content -replace 'handraw-style\.com', 'www.boninaigc.top'
        # H3: upstream GitHub URL
        $Content = $Content -replace 'github\.com/yang0/handraw-style', 'github.com/BoninEDU/bonin-skills'
        # H7: gitee mirror (MUST run before H4: the bare author-id rule
        # below would rewrite the URL before these specific patterns match)
        $gat = [char]0x40
        $giteeSshPattern = 'git' + $gat + 'gitee\.com:yang02010/handraw-style\.git'
        $giteeSshReplace = 'git' + $gat + 'github.com:BoninEDU/bonin-skills.git'
        $Content = $Content -replace $giteeSshPattern, $giteeSshReplace
        $Content = $Content -replace 'gitee\.com:yang02010/handraw-style', 'github.com/BoninEDU/bonin-skills'
        $Content = $Content -replace 'gitee\.com/yang02010/handraw-style', 'github.com/BoninEDU/bonin-skills'
        # H4: upstream author identifiers (longest first)
        $Content = $Content -replace 'yang02010', 'Bonin'
        $Content = $Content -replace 'yang0/handraw-style', 'BoninEDU/bonin-skills'
        $Content = $Content -replace '\byang0\b', 'Bonin'
        # H5: upstream studio brand
        $Content = $Content -replace 'HandRaw Style Studio', 'Bonin AIGC'
        # H6: third-party marketplace endpoint
        $Content = $Content -replace 'open\.workbuddy\.cn', 'www.boninaigc.top'
        # SKILL.md frontmatter name line ONLY.
        # The inner sub-skill dir skills/handdraw-style-prompter/ keeps its
        # name on purpose (install layout dependency) and must NOT be rewritten.
        $Content = $Content -replace '(?m)^name:\s*handdraw-style-prompter\s*$', 'name: bonin-handraw-style'
    }
    elseif ($Source -eq "stickman") {
        # Attribution-preserving port: ONLY strip promotion tracking params
        # from the Renoise MCP setup link; upstream URLs, copyright notices
        # and asset attributions are kept verbatim (MIT + third-party
        # licenses require it). Idempotent: the bare URL won't re-match.
        $Content = $Content -replace '\?utm_source=crazykaomei-aini-202610&utm_medium=xcom', ''
        # The local upstream clone has core.autocrlf=true (CRLF worktree),
        # but fingerprint manifests pin SHA-256 over LF bytes and contract
        # tests split on literal "\n". Normalize so synced text stays
        # byte-identical to the upstream Linux CI baseline.
        $Content = $Content -replace "`r`n", "`n"
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
    elseif ($Source -eq "book") {
        # package dir rename only: book_to_skill/ -> bonin_book_to_skill/
        return ($RelativePath -creplace '^book_to_skill/', 'bonin_book_to_skill/')
    }
    elseif ($Source -eq "handraw") {
        # no inner rewrite; dest prefix is applied by Sync-File
        return $RelativePath
    }
    elseif ($Source -eq "stickman") {
        # no inner rewrite; the inner package dir
        # skills/directing-stickman-videos/ keeps its name on purpose
        # (install layout + upstream regression tests depend on it).
        return $RelativePath
    }
    return $RelativePath
}

# ============================================================
# 文件同步
# ============================================================

function Sync-File {
    param(
        [string]$SrcRoot,
        [string]$RelPath,
        [string]$Source,
        # 2026-11 additions (backward compatible: empty defaults = legacy behavior)
        [string]$DestPrefix = "",
        [string[]]$SourceSkipPatterns = @(),
        # 2026-11-10 addition: keep-override for the global $skipPatterns
        # (a matching path bypasses the global skip list but still honors
        # $SourceSkipPatterns). Empty default = legacy behavior.
        [string[]]$SourceKeepPatterns = @()
    )

    $srcFile = Join-Path $SrcRoot $RelPath
    $destRelPath = Map-Path -RelativePath $RelPath -Source $Source
    if ($DestPrefix -ne "") {
        $destRelPath = "$DestPrefix/$destRelPath"
    }
    $destFile = Join-Path $boninRoot $destRelPath

    if (-not (Test-Path $srcFile)) {
        Write-Log "  SKIP (not found): $RelPath"
        return $false
    }

    $keepOverride = $false
    foreach ($pattern in $SourceKeepPatterns) {
        if ($RelPath -match $pattern) {
            $keepOverride = $true
            break
        }
    }

    if (-not $keepOverride) {
        foreach ($pattern in $skipPatterns) {
            if ($RelPath -match $pattern) {
                Write-Log "  SKIP (pattern): $RelPath"
                return $false
            }
        }
    }

    foreach ($pattern in $SourceSkipPatterns) {
        if ($RelPath -match $pattern) {
            Write-Log "  SKIP (source pattern): $RelPath"
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
    # forbidden keywords: legacy sources + 2026-11 sources (all verified zero-match repo-wide)
    $forbidden = @("JimLiu", "lijigang", "baoyu-skills", "ljg-skills", "virgiliojr94", "booklin", "yang02010", "handraw-style.com", "HandRaw Style Studio", "open.workbuddy.cn")
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
$syncedSources = @()
$bookNewHead = $null
$handrawNewHead = $null
$stickmanNewHead = $null

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
            $syncedSources += "baoyu"
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
            $syncedSources += "ljg"
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

# Process book-to-skill (added 2026-11)
Write-Log ""
Write-Log "=== SOURCE: book-to-skill ==="
if (Test-Path $bookRoot) {
    $bookBaseline = Get-Source-Baseline -Name "book-to-skill" -Initial $bookInitialBaseline
    $currentHead = Get-Repo-Head -RepoPath $bookRoot
    Write-Log "Baseline: $bookBaseline"
    Write-Log "Current HEAD: $currentHead"

    if ($currentHead -and ($currentHead -ne $bookBaseline -or $Force)) {
        $changedFiles = Get-Changed-Files -RepoPath $bookRoot -FromCommit $bookBaseline
        Write-Log "Changed files: $($changedFiles.Count)"

        if ($changedFiles.Count -gt 0 -or $Force) {
            $hasChanges = $true
            $syncedSources += "book-to-skill"
            $synced = 0
            $skipped = 0
            foreach ($file in $changedFiles) {
                $result = Sync-File -SrcRoot $bookRoot -RelPath $file -Source "book" -DestPrefix $bookDestPrefix -SourceSkipPatterns $bookSkipPatterns
                if ($result) { $synced++ } else { $skipped++ }
            }
            $totalSynced += $synced
            $totalSkipped += $skipped
            Write-Log "book-to-skill: $synced synced, $skipped skipped"
            $bookNewHead = $currentHead
        }
    }
    else {
        Write-Log "No changes since last sync"
    }
}
else {
    Write-Log "Source repo not found: $bookRoot" -Level "WARN"
}

# Process handraw-style (added 2026-11)
Write-Log ""
Write-Log "=== SOURCE: handraw-style ==="
if (Test-Path $handrawRoot) {
    $handrawBaseline = Get-Source-Baseline -Name "handraw-style" -Initial $handrawInitialBaseline
    $currentHead = Get-Repo-Head -RepoPath $handrawRoot
    Write-Log "Baseline: $handrawBaseline"
    Write-Log "Current HEAD: $currentHead"

    if ($currentHead -and ($currentHead -ne $handrawBaseline -or $Force)) {
        $changedFiles = Get-Changed-Files -RepoPath $handrawRoot -FromCommit $handrawBaseline
        Write-Log "Changed files: $($changedFiles.Count)"

        if ($changedFiles.Count -gt 0 -or $Force) {
            $hasChanges = $true
            $syncedSources += "handraw-style"
            $synced = 0
            $skipped = 0
            foreach ($file in $changedFiles) {
                $result = Sync-File -SrcRoot $handrawRoot -RelPath $file -Source "handraw" -DestPrefix $handrawDestPrefix -SourceSkipPatterns $handrawSkipPatterns
                if ($result) { $synced++ } else { $skipped++ }
            }
            $totalSynced += $synced
            $totalSkipped += $skipped
            Write-Log "handraw-style: $synced synced, $skipped skipped"
            $handrawNewHead = $currentHead
        }
    }
    else {
        Write-Log "No changes since last sync"
    }
}
else {
    Write-Log "Source repo not found: $handrawRoot" -Level "WARN"
}

# Process stickman-video-director (added 2026-11-10)
Write-Log ""
Write-Log "=== SOURCE: stickman-video-director ==="
if (Test-Path $stickmanRoot) {
    $stickmanBaseline = Get-Source-Baseline -Name "stickman-video-director" -Initial $stickmanInitialBaseline
    $currentHead = Get-Repo-Head -RepoPath $stickmanRoot
    Write-Log "Baseline: $stickmanBaseline"
    Write-Log "Current HEAD: $currentHead"

    if ($currentHead -and ($currentHead -ne $stickmanBaseline -or $Force)) {
        $changedFiles = Get-Changed-Files -RepoPath $stickmanRoot -FromCommit $stickmanBaseline
        Write-Log "Changed files: $($changedFiles.Count)"

        if ($changedFiles.Count -gt 0 -or $Force) {
            $hasChanges = $true
            $syncedSources += "stickman-video-director"
            $synced = 0
            $skipped = 0
            foreach ($file in $changedFiles) {
                $result = Sync-File -SrcRoot $stickmanRoot -RelPath $file -Source "stickman" -DestPrefix $stickmanDestPrefix -SourceSkipPatterns $stickmanSkipPatterns -SourceKeepPatterns $stickmanKeepPatterns
                if ($result) { $synced++ } else { $skipped++ }
            }
            $totalSynced += $synced
            $totalSkipped += $skipped
            Write-Log "stickman-video-director: $synced synced, $skipped skipped"
            $stickmanNewHead = $currentHead
        }
    }
    else {
        Write-Log "No changes since last sync"
    }
}
else {
    Write-Log "Source repo not found: $stickmanRoot" -Level "WARN"
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
    # NOTE: no `2>&1` redirection on git calls — with EAP=Stop, PowerShell 5
    # turns redirected stderr (e.g. CRLF hints) into terminating errors.
    Write-Log ""
    Write-Log "=== COMMITTING ==="
    git -C $boninRoot add -A | Out-Null
    $sourceTag = if ($syncedSources.Count -gt 0) { $syncedSources -join ', ' } else { "no source" }
    $commitMsg = "feat: auto-sync from upstream ($sourceTag) - $totalSynced files synced"
    git -C $boninRoot commit -m $commitMsg | Out-Null
    Write-Log "Committed: $commitMsg"

    # Advance new-source baselines after a successful commit (added 2026-11).
    # Kept after the audit gate so failed runs retry the same range next week.
    if ($bookNewHead) {
        Update-Source-Baseline -Name "book-to-skill" -Commit $bookNewHead -Initial $bookInitialBaseline
        $bookNewHead = $null
    }
    if ($handrawNewHead) {
        Update-Source-Baseline -Name "handraw-style" -Commit $handrawNewHead -Initial $handrawInitialBaseline
        $handrawNewHead = $null
    }
    if ($stickmanNewHead) {
        Update-Source-Baseline -Name "stickman-video-director" -Commit $stickmanNewHead -Initial $stickmanInitialBaseline
        $stickmanNewHead = $null
    }

    # 推送（重试 3 次）
    Write-Log ""
    Write-Log "=== PUSHING TO GITHUB ==="
    $pushed = $false
    for ($i = 1; $i -le 3; $i++) {
        Write-Log "Push attempt $i of 3..."
        git -C $boninRoot push origin master | Out-Null
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
