# =============================================================================
# generate-failed-logons.ps1
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Generates multiple failed Windows logon attempts to trigger Rule 01
#          (Brute Force: Failed Logins — Event ID 4625) in Kibana Security.
#
# WARNING: Run this script ONLY in the lab VM (WIN10-ENDPOINT 192.168.10.197).
#          Do NOT run on production systems or domain controllers.
#          This script intentionally generates authentication failures.
#
# Prerequisites:
#   - Windows Audit Policy must be enabled for Logon/Logoff failures
#     (secpol.msc → Advanced Audit Policy → Logon/Logoff → Audit Logon → Failure)
#   - Winlogbeat must be running and shipping to Logstash
#
# Usage:
#   Open PowerShell as Administrator
#   .\generate-failed-logons.ps1
#
# After running, check Kibana Discover for:
#   event.code: "4625"
# =============================================================================

#Requires -RunAsAdministrator

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Generate Failed Logon Events (Rule 01 Test)" -ForegroundColor Cyan
Write-Host "  WARNING: Lab VM only. Do not run on production systems." -ForegroundColor Yellow
Write-Host "============================================================"
Write-Host ""

$TargetUser  = "lab-nonexistent-user"
$BadPassword = ConvertTo-SecureString "WrongPassword!Lab123" -AsPlainText -Force
$AttemptCount = 8
$DelaySeconds = 2

Write-Host "  Target account : $TargetUser (does not exist — intentional)"
Write-Host "  Attempt count  : $AttemptCount"
Write-Host "  Delay between  : ${DelaySeconds}s"
Write-Host ""

for ($i = 1; $i -le $AttemptCount; $i++) {
    Write-Host "  Attempt $i of $AttemptCount..." -NoNewline

    # Use Add-Type to invoke the LogonUser Win32 API — generates a real 4625 event
    # without relying on net use or other commands that may be blocked
    Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WinAPI {
            [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
            public static extern bool LogonUser(
                string lpszUsername,
                string lpszDomain,
                string lpszPassword,
                int dwLogonType,
                int dwLogonProvider,
                out IntPtr phToken
            );
        }
"@ -ErrorAction SilentlyContinue

    $token = [IntPtr]::Zero
    # LogonType 2 = Interactive | LogonProvider 0 = Default
    $result = [WinAPI]::LogonUser($TargetUser, ".", "WrongPassword!Lab123", 2, 0, [ref]$token)

    if (-not $result) {
        Write-Host " Failed logon generated (expected)" -ForegroundColor Green
    } else {
        Write-Host " Logon succeeded unexpectedly — check target username" -ForegroundColor Red
    }

    Start-Sleep -Seconds $DelaySeconds
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Test complete. $AttemptCount failed logon attempts generated."
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Wait 30-60 seconds for Winlogbeat to ship events"
Write-Host "  2. In Kibana Discover, filter: event.code: `"4625`""
Write-Host "  3. Confirm events appear in winlogbeat-* index"
Write-Host "  4. Rule 01 threshold (5+ failures/5 min) should fire an alert"
Write-Host "============================================================"
