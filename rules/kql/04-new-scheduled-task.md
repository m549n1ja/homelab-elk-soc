# Rule 04 — New Scheduled Task

| Field | Value |
|-------|-------|
| **Rule Name** | New Scheduled Task |
| **Index Pattern** | `winlogbeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1053.005 — Scheduled Task/Job: Scheduled Task |
| **Data Source** | Windows Security Event Log via Winlogbeat |
| **Event ID** | 4698 — A scheduled task was created |
| **Status** | Created / pending full validation |

---

## Purpose

Detect the creation of a new Windows scheduled task, which is a common persistence and privilege escalation technique used after initial access.

---

## KQL Query

```kql
event.code: "4698"
```

---

## Rule Logic and Threshold

Apply as a **custom query rule**:

- **Rule type:** Custom query
- **Time window:** 5 minutes
- Every new task creation is an alert — volume in a lab environment is low enough to make threshold rules unnecessary

> **Field note:** Task name and XML definition are in `winlog.event_data.TaskName` and `winlog.event_data.TaskContent`. The creating account is in `winlog.event_data.SubjectUserName`.

---

## Why It Matters

Scheduled tasks execute on a defined schedule, run under any account context, survive reboots, and can call arbitrary executables or scripts. Attackers use them to maintain persistence after gaining access, re-establish C2 connections after cleanup, and execute payloads at intervals that avoid real-time detection. Any task created outside a known software deployment or admin action is worth reviewing.

---

## Test Method

1. Open an elevated command prompt on WIN10-ENDPOINT (192.168.10.197)
2. Run: `schtasks /create /tn "LabTestTask" /tr "cmd.exe /c echo lab-test" /sc onlogon /ru SYSTEM`
3. In Kibana Discover, filter: `event.code: "4698"` — confirm the task name appears in `winlog.event_data.TaskName`
4. Clean up: `schtasks /delete /tn "LabTestTask" /f`

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: New Scheduled Task
- Severity: High
- Task name and creating account visible in alert details

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule4-scheduled-task.png` — Rule created in Kibana Security

---

## False Positive Considerations

- Software installers that register scheduled tasks during installation (antivirus, backup agents, update managers)
- Windows Update and Windows Defender creating maintenance tasks
- IT automation tools registering recurring jobs

---

## Tuning Notes

- Build a baseline of known-good task names from your environment and add them to a suppression list
- Prioritize alerts where `winlog.event_data.SubjectUserName` is a standard (non-admin) user account
- Review `winlog.event_data.TaskContent` for the `<Exec>` element — tasks pointing to paths in `%TEMP%`, `%APPDATA%`, or `C:\Users\` are high priority regardless of the creating account
- Consider a tighter variant: alert only on tasks created outside business hours
