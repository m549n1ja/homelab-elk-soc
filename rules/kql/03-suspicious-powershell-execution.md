# Rule 03 — Suspicious PowerShell Execution

| Field | Value |
|-------|-------|
| **Rule Name** | Suspicious PowerShell Execution |
| **Index Pattern** | `winlogbeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1059.001 — Command and Scripting Interpreter: PowerShell |
| **Data Source** | PowerShell Script Block Logging via Winlogbeat |
| **Event ID** | 4104 — Script block logging: script block contents recorded |
| **Status** | Created / pending full validation |

---

## Purpose

Detect PowerShell execution containing keywords commonly associated with download cradles, execution policy bypasses, obfuscated commands, and living-off-the-land attack patterns.

---

## KQL Query

```kql
event.code: "4104" AND
winlog.event_data.ScriptBlockText: (
  "Invoke-Expression" OR
  "IEX" OR
  "DownloadString" OR
  "DownloadFile" OR
  "EncodedCommand" OR
  "-enc" OR
  "-ExecutionPolicy Bypass" OR
  "bypass" OR
  "-WindowStyle Hidden" OR
  "hidden" OR
  "FromBase64String"
)
```

> **Field note:** Script block content may appear as `winlog.event_data.ScriptBlockText` or `powershell.file.script_block_text` depending on Winlogbeat version and ECS mapping. Verify in Kibana Discover on a known 4104 event before creating the rule.

---

## Rule Logic and Threshold

Apply as a **custom query rule** — every matching event is an alert:

- **Rule type:** Custom query
- **Index:** `winlogbeat-*`
- No threshold required; keyword matches are inherently meaningful

---

## Why It Matters

PowerShell is one of the most heavily abused living-off-the-land tools. It is present on every Windows system, can download and execute arbitrary code in memory, and many variations bypass AppLocker and script restrictions. Script block logging (Event 4104) captures the actual script content as it executes — including deobfuscated payloads — making it the most reliable PowerShell detection layer available without a dedicated EDR.

---

## Prerequisite: Enable PowerShell Script Block Logging

Event 4104 is **not enabled by default**. Enable via Group Policy on WIN10-ENDPOINT:

1. Open `gpedit.msc`
2. Navigate to: `Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell`
3. Enable: **Turn on PowerShell Script Block Logging**
4. Restart the WinRM service or reboot

---

## Test Method

1. Confirm 4104 logging is enabled (see prerequisite above)
2. Open PowerShell on WIN10-ENDPOINT (192.168.10.197)
3. Run a benign test: `Invoke-Expression "Write-Host 'test'"`
4. In Kibana Discover, filter: `event.code: "4104"` — confirm `ScriptBlockText` field is populated
5. Rule will fire on any execution containing the listed keywords

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: Suspicious PowerShell Execution
- Severity: High
- Script block content visible in alert details for triage

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule3-powershell-execution.png` — Rule created in Kibana Security

---

## False Positive Considerations

- Legitimate IT admin scripts that use `Invoke-Expression` for dynamic execution
- Software deployment tools (SCCM, PDQ Deploy) that use `-EncodedCommand` for package delivery
- Security tools and monitoring agents that invoke PowerShell with bypass flags during installation

---

## Tuning Notes

- Add a path-based filter: suppress alerts where `process.executable` or `winlog.event_data.Path` matches known safe script directories (e.g., `C:\Scripts\`, `C:\Program Files\`)
- Correlate with parent process — PowerShell spawned by `winword.exe`, `excel.exe`, or `mshta.exe` is significantly more suspicious than PowerShell launched from `powershell_ise.exe` or the terminal
- Consider a separate higher-severity rule scoped only to the most dangerous indicators: `DownloadString`, `FromBase64String`, and `-EncodedCommand` together in a single script block
