# =============================================================================
# generate-powershell-event.ps1
# homelab-elk-soc — Lab validation script
# =============================================================================
# Purpose: Generates a PowerShell Script Block Logging event (Event ID 4104)
#          containing keywords that trigger Rule 03 (Suspicious PowerShell
#          Execution) in Kibana Security.
#
#          This script uses BENIGN commands that contain detection keywords
#          in their syntax. No malicious code is executed. The intent is
#          purely to verify that Event 4104 is being generated, shipped by
#          Winlogbeat, and indexed in Kibana.
#
# WARNING: Run this script ONLY in the lab VM (WIN10-ENDPOINT 192.168.10.197).
#
# Prerequisites:
#   - PowerShell Script Block Logging must be enabled:
#     gpedit.msc → Computer Configuration → Administrative Templates →
#     Windows Components → Windows PowerShell →
#     Turn on PowerShell Script Block Logging → Enabled
#   - Winlogbeat must be configured to collect from the
#     Microsoft-Windows-PowerShell/Operational channel
#   - Winlogbeat must be running and shipping to Logstash
#
# Usage:
#   Open PowerShell (standard user is fine)
#   .\generate-powershell-event.ps1
#
# After running, check Kibana Discover for:
#   event.code: "4104"
# =============================================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Generate PowerShell Script Block Event (Rule 03 Test)" -ForegroundColor Cyan
Write-Host "  WARNING: Lab VM only." -ForegroundColor Yellow
Write-Host "============================================================"
Write-Host ""

Write-Host "  Step 1: Generating Event 4104 with 'Invoke-Expression' keyword..."

# This is a benign use of Invoke-Expression — it simply evaluates a string
# that writes a harmless message. The keyword itself triggers the detection rule.
Invoke-Expression "Write-Host 'homelab-elk-soc detection test: Invoke-Expression fired'"

Write-Host ""
Write-Host "  Step 2: Generating Event 4104 with 'bypass' keyword in comment..."

# Script block logging captures the full script text including comments.
# The word 'bypass' in any context within a script block will trigger the rule.
$testVar = "lab-detection-test"  # This tests bypass keyword detection
Write-Host "  Test variable set: $testVar"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Test complete."
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Wait 30-60 seconds for Winlogbeat to ship events"
Write-Host "  2. In Kibana Discover, filter: event.code: `"4104`""
Write-Host "  3. Look for ScriptBlockText containing 'Invoke-Expression'"
Write-Host "  4. If no events appear, verify Script Block Logging is enabled"
Write-Host "     via gpedit.msc and that Winlogbeat collects from the"
Write-Host "     Microsoft-Windows-PowerShell/Operational channel"
Write-Host "  5. Rule 03 should generate a High severity alert"
Write-Host "============================================================"
