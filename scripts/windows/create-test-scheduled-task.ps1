# =============================================================================
# create-test-scheduled-task.ps1
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Creates and then removes a harmless scheduled task to trigger
#          Rule 04 (New Scheduled Task — Event ID 4698) in Kibana Security.
#          The task runs a benign command (echo) and is removed immediately
#          after the test.
#
# WARNING: Run this script ONLY in the lab VM (WIN10-ENDPOINT 192.168.10.197).
#          Do NOT run on production systems or domain controllers.
#
# Prerequisites:
#   - Winlogbeat must be running and shipping to Logstash
#   - Run as Administrator to generate Event ID 4698
#
# Usage:
#   Open PowerShell as Administrator
#   .\create-test-scheduled-task.ps1
#
# After running, check Kibana Discover for:
#   event.code: "4698"
# =============================================================================

#Requires -RunAsAdministrator

$TaskName   = "homelab-elk-soc-test-task"
$TaskAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c echo homelab-detection-test"
$TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
$TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Create Test Scheduled Task (Rule 04 Test)" -ForegroundColor Cyan
Write-Host "  WARNING: Lab VM only. Do not run on production systems." -ForegroundColor Yellow
Write-Host "============================================================"
Write-Host ""

# ---- Clean up any existing test task first ----
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "  [INFO] Task '$TaskName' already exists. Removing first..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "  [INFO] Removed existing task."
    Start-Sleep -Seconds 2
}

# ---- Create the test scheduled task ----
Write-Host "  Creating scheduled task: $TaskName"
Write-Host "  Action: cmd.exe /c echo homelab-detection-test (harmless)"
Write-Host ""

Register-ScheduledTask -TaskName $TaskName `
                       -Action $TaskAction `
                       -Trigger $TaskTrigger `
                       -Settings $TaskSettings `
                       -Description "Homelab detection rule test task — safe to delete" | Out-Null

Write-Host "  Task '$TaskName' created successfully." -ForegroundColor Green
Write-Host ""
Write-Host "  Waiting 5 seconds before cleanup (allow Winlogbeat to ship event)..."
Start-Sleep -Seconds 5

# ---- Remove the test task ----
Write-Host "  Removing test task: $TaskName"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "  Task '$TaskName' removed." -ForegroundColor Green

Write-Host ""
Write-Host "============================================================"
Write-Host "  Test complete."
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Wait 30-60 seconds for Winlogbeat to ship events"
Write-Host "  2. In Kibana Discover, filter: event.code: `"4698`""
Write-Host "  3. Look for TaskName containing '$TaskName' in the results"
Write-Host "  4. Rule 04 should generate a High severity alert"
Write-Host "============================================================"
