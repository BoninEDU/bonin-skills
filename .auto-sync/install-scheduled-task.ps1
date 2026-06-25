# ============================================================
# Bonin Skills Auto-Sync - Windows Scheduled Task Installer
# Installs a weekly scheduled task to run auto-sync every Monday 06:00
#
# Usage:
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

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "Error: auto-sync.ps1 not found at: $scriptPath"
    exit 1
}

Write-Host "Installing scheduled task: $taskName"
Write-Host "Script path: $scriptPath"
Write-Host "Schedule: Every Monday at 06:00"
Write-Host ""

# Create task action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""

# Create trigger: every Monday at 06:00
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 6am

# Create settings: allow start on batteries, retry on failure
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 30) -ExecutionTimeLimit (New-TimeSpan -Hours 2)

# Register task (run as current user with highest privileges)
try {
    # Remove existing task first
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Weekly auto-sync of bonin-skills from upstream repositories (baoyu-skills, ljg-skills)" -Force | Out-Null

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
