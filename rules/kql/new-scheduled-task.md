# Rule: New Scheduled Task

**Event Code:** 4698  
**Index:** `winlogbeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1053.005 — Scheduled Task/Job: Scheduled Task  

---

## KQL Query

```kql
event.code: "4698"
```

---

## Why This Matters

Scheduled tasks are a go-to persistence mechanism — they survive reboots, run under any account context, and can execute at intervals designed to avoid analyst scrutiny. Attackers use them to maintain access, execute payloads periodically, and re-establish C2 connections after remediation attempts. Any new scheduled task that doesn't trace back to a known software install or admin action should be investigated.

---

## Test Method

Created a scheduled task on WIN10-ENDPOINT using `schtasks /create /tn "TestTask" /tr "cmd.exe /c whoami" /sc onlogon`. Confirmed Event 4698 generated and the task name was visible in the `winlog.event_data.TaskName` field in Kibana.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule4-scheduled-task.png` — rule created in Kibana Security

---

## False Positive Considerations

- Windows Update, antivirus products, and backup software create scheduled tasks as part of normal operation — build a baseline of known-good task names and suppress those
- Software installers are a common source of 4698 events immediately after installation
- The `winlog.event_data.SubjectUserName` field identifies who created the task — events where a non-admin user creates a task are higher fidelity than those created by SYSTEM or a known admin account
