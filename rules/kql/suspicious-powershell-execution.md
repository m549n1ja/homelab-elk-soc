# Rule: Suspicious PowerShell Execution

**Event Code:** 4104 (Script Block Logging)  
**Index:** `winlogbeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1059.001 — Command and Scripting Interpreter: PowerShell  

---

## KQL Query

```kql
event.code: "4104" AND winlog.event_data.ScriptBlockText: (
  "Invoke-Expression" OR
  "IEX" OR
  "DownloadString" OR
  "EncodedCommand" OR
  "-enc" OR
  "bypass" OR
  "hidden"
)
```

> Requires PowerShell Script Block Logging enabled via Group Policy:  
> `Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell → Turn on PowerShell Script Block Logging`

---

## Why This Matters

PowerShell is one of the most heavily abused living-off-the-land tools in attacker playbooks. Script block logging captures the actual content of scripts as they execute — including obfuscated or encoded payloads that would otherwise bypass process-based detection. The keywords in this query cover the most common patterns for download cradles, execution policy bypasses, and obfuscated execution.

---

## Test Method

Enabled PowerShell Script Block Logging on WIN10-ENDPOINT via Group Policy. Ran a benign test command using `Invoke-Expression` to confirm Event 4104 was generated and the `ScriptBlockText` field was populated in Kibana. No malicious payloads were executed.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule3-powershell-execution.png` — rule created in Kibana Security

---

## False Positive Considerations

- Legitimate admin scripts often use `Invoke-Expression` or download content from internal sources — tune by adding a whitelist on `winlog.event_data.Path` for known script directories (e.g., `C:\Scripts\`)
- Software deployment tools (SCCM, PDQ) may use `-EncodedCommand` for legitimate package installation
- Consider correlating with parent process — PowerShell spawned by `winword.exe` or `excel.exe` is significantly more suspicious than PowerShell spawned by `powershell_ise.exe`
