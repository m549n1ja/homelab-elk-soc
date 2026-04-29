# Rule 07 — New Service Installed

| Field | Value |
|-------|-------|
| **Rule Name** | New Service Installed |
| **Index Pattern** | `winlogbeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1543.003 — Create or Modify System Process: Windows Service |
| **Data Source** | Windows System Event Log via Winlogbeat |
| **Event ID** | 7045 — A new service was installed in the system |
| **Status** | Created / pending full validation |

---

## Purpose

Detect the installation of a new Windows service, which attackers use as a persistence mechanism and for privilege escalation, since services default to running as SYSTEM.

---

## KQL Query

```kql
event.code: "7045"
```

---

## Rule Logic and Threshold

Apply as a **custom query rule**:

- **Rule type:** Custom query
- **Time window:** 5 minutes
- Every new service installation is an alert

> **Field note:** Service name is in `winlog.event_data.ServiceName`. The binary path is in `winlog.event_data.ImagePath`. Service type is in `winlog.event_data.ServiceType`. These are the primary triage fields.

---

## Why It Matters

Windows services run with elevated privileges, are persistent across reboots, and can execute arbitrary binaries. Attackers install malicious services to maintain access after gaining a foothold — tools like Metasploit's `psexec` module and many remote access tools establish themselves as services. Event 7045 is recorded in the System log (not Security), so it is easy to miss without active monitoring.

---

## Test Method

1. Open an elevated command prompt on WIN10-ENDPOINT (192.168.10.197)
2. Run: `sc create LabTestService binPath= "C:\Windows\System32\cmd.exe"`
3. In Kibana Discover, filter: `event.code: "7045"` — confirm `ServiceName` and `ImagePath` fields are populated
4. Clean up: `sc delete LabTestService`

> Winlogbeat must be configured to collect from the **System** channel (channel: `System`) in addition to the Security channel. Verify this in `winlogbeat.yml`.

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: New Service Installed
- Severity: High
- Service name and image path visible in alert details

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule7-new-service.png` — Rule created in Kibana Security

---

## False Positive Considerations

- Software installations that register services as part of setup (antivirus engines, backup agents, monitoring tools, database servers)
- Windows feature installs and driver packages
- IT automation deployments registering management agents

---

## Tuning Notes

- The highest-value triage field is `winlog.event_data.ImagePath` — services whose binary paths point to user-writable locations (`%TEMP%`, `%APPDATA%`, `C:\Users\`, `C:\ProgramData\`) are immediately suspicious regardless of service name
- Check `winlog.event_data.ServiceType` — kernel mode driver installs (`kernel mode driver`) are higher severity than user-mode services and rare in normal operations
- Build a baseline allowlist of expected service names from your standard software stack and suppress those to reduce noise
