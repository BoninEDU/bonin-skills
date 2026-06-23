# ============================================================
# Bonin Skills 自动化同步 - Windows 任务计划程序安装
# Installs a weekly scheduled task to run auto-sync every Monday 06:00
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File install-scheduled-task.ps1
#   powershell -ExecutionPolicy Bypass -File install-scheduled-task.ps1 -Uninstall
# ============================================================

param(
    [switch]$Uninstall = $false
)

$taskName = "BoninSkillsAutoSync"
$scriptPath = Join-Path $PSScriptRoot "auto-sync.ps1"

if ($Uninstall) {
    Write-Host "Uninstalling scheduled task: $taskName"
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        Write-Host "Task uninstalled successfully."
    }
    catch {
        Write-Host "Task not found or already removed: $_"
    }
    exit 0
}

# 检查脚本是否存在
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: auto-sync.ps1 not found at: $scriptPath"
    exit 1
}

Write-Host "Installing scheduled task: $taskName"
Write-Host "Script path: $scriptPath"
Write-Host "Schedule: Every Monday at 06:00"
Write-Host ""

# 创建任务动作
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""

# 创建触发器：每周一 06:00
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 6am

# 创建设置：允许强制启动，失败重试
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 30) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

# 注册任务（以当前用户运行，使用最高权限）
try {
    # 先删除已存在的任务
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Weekly auto-sync of bonin-skills from upstream repositories (baoyu-skills, ljg-skills)" `
        -RunLevel Highest `
        -Force | Out-Null

    Write-Host "Scheduled task installed successfully!"
    Write-Host ""
    Write-Host "Task details:"
    Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State, Description
    Write-Host ""
    Write-Host "Next run time:"
    (Get-ScheduledTaskInfo -TaskName $taskName).NextRunTime
    Write-Host ""
    Write-Host "To run manually:"
    Write-Host "  Start-ScheduledTask -TaskName '$taskName'"
    Write-Host ""
    Write-Host "To uninstall:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Uninstall"
}
catch {
    Write-Host "Error installing scheduled task: $_"
    Write-Host ""
    Write-Host "Try running as Administrator."
    exit 1
}
