# Rule: File Integrity Alert — /etc/passwd

**Event Code:** Auditbeat file_integrity module  
**Index:** `auditbeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1565.001 — Data Manipulation: Stored Data Manipulation  

---

## KQL Query

```kql
event.module: "file_integrity" AND
event.type: "change" AND
file.path: ("/etc/passwd" OR "/etc/shadow" OR "/etc/sudoers")
```

---

## Why This Matters

On a Linux system, `/etc/passwd`, `/etc/shadow`, and `/etc/sudoers` are the keys to the kingdom. Modifications to these files can mean an attacker is adding a backdoor account, modifying password hashes, or granting sudo rights to a compromised account. Auditbeat's file_integrity module calculates file hashes on a schedule and alerts on any detected change — this gives you the when and what without relying on process-based detection.

---

## Test Method

Auditbeat file_integrity module was configured on LINUX-ENDPOINT (192.168.10.155) with `/etc/passwd`, `/etc/shadow`, and `/etc/sudoers` in the monitored paths list (`/etc/auditbeat/auditbeat.yml`). Confirmed Auditbeat events are flowing to the `auditbeat-*` index in Kibana with the `event.module: "file_integrity"` field populated. Alert fires on any `event.type: "change"` event for the monitored paths.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule10-file-integrity.png` — rule created in Kibana Security  
`evidence/screenshots/20260428_linux-endpoint_filebeat-auditbeat-running.png` — Auditbeat confirmed running

---

## False Positive Considerations

- Package manager operations (`apt install`, `apt upgrade`) will modify `/etc/passwd` and `/etc/shadow` when adding system users for new packages — correlate the alert timestamp with known maintenance windows
- Manual user administration by legitimate admins (`useradd`, `passwd`, `visudo`) will trigger this rule — in production, tie these alerts to a change management workflow
- Consider expanding monitored paths to include `/etc/cron.d/`, `/etc/profile.d/`, and SSH `authorized_keys` files for broader persistence detection coverage
