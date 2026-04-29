# =============================================================================
# create-test-user.ps1
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Creates and then removes a local test user account to trigger
#          Rule 02 (New User Account Created — Event ID 4720) in Kibana Security.
#
# WARNING: Run this script ONLY in the lab VM (WIN10-ENDPOINT 192.168.10.197).
#          Do NOT run on production systems or domain controllers.
#
# Prerequisites:
#   - Winlogbeat must be running and shipping to Logstash
#   - Windows Audit Policy must be enabled for Account Management events
#
# Usage:
#   Open PowerShell as Administrator
#   .\create-test-user.ps1
#
# After running, check Kibana Discover for:
#   event.code: "4720"
# =============================================================================

#Requires -RunAsAdministrator

$TestUsername = "lab-test-user"
$TestPassword = ConvertTo-SecureString "LabTest!Temp2026" -AsPlainText -Force

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Create Test User Account (Rule 02 Test)" -ForegroundColor Cyan
Write-Host "  WARNING: Lab VM only. Do not run on production systems." -ForegroundColor Yellow
Write-Host "============================================================"
Write-Host ""

# ---- Check if user already exists and clean up first ----
if (Get-LocalUser -Name $TestUsername -ErrorAction SilentlyContinue) {
    Write-Host "  [INFO] Test user '$TestUsername' already exists. Removing first..." -ForegroundColor Yellow
    Remove-LocalUser -Name $TestUsername
    Write-Host "  [INFO] Removed existing test user."
    Start-Sleep -Seconds 2
}

# ---- Create the test user ----
Write-Host "  Creating test user: $TestUsername"
New-LocalUser -Name $TestUsername `
              -Password $TestPassword `
              -Description "Homelab detection rule test account — safe to delete" `
              -PasswordNeverExpires `
              -UserMayNotChangePassword | Out-Null

Write-Host "  User '$TestUsername' created successfully." -ForegroundColor Green
Write-Host ""
Write-Host "  Waiting 5 seconds before cleanup (allow Winlogbeat to ship event)..."
Start-Sleep -Seconds 5

# ---- Remove the test user ----
Write-Host "  Removing test user: $TestUsername"
Remove-LocalUser -Name $TestUsername
Write-Host "  User '$TestUsername' removed." -ForegroundColor Green

Write-Host ""
Write-Host "============================================================"
Write-Host "  Test complete."
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Wait 30-60 seconds for Winlogbeat to ship events"
Write-Host "  2. In Kibana Discover, filter: event.code: `"4720`""
Write-Host "  3. Look for TargetUserName: lab-test-user in the results"
Write-Host "  4. Rule 02 should generate a High severity alert"
Write-Host "============================================================"
