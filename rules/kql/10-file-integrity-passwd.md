# Rule 10 — File Integrity Alert: /etc/passwd

| Field | Value |
|-------|-------|
| **Rule Name** | File Integrity Alert: /etc/passwd |
| **Index Pattern** | `auditbeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1565.001 — Data Manipulation: Stored Data Manipulation |
| **Data Source** | Auditbeat file_integrity module on LINUX-ENDPOINT |
| **Event ID / Signal** | Auditbeat file change event for monitored critical paths |
| **Status** | Created / pending full validation |

---

## Purpose

Detect modifications to critical Linux authentication files using Auditbeat's file integrity monitoring (FIM) module. Changes to `/etc/passwd`, `/etc/shadow`, or `/etc/sudoers` outside authorized maintenance windows are high-priority events.

---

## KQL Query

```kql
event.module: "file_integrity" AND
event.type: "change" AND
file.path: ("/etc/passwd" OR "/etc/shadow" OR "/etc/sudoers")
```

> **Field note:** Field names should be stable across Auditbeat 8.x. The `file.path` field contains the full path of the modified file. The `file.hash.sha256` field (if enabled) provides a hash of the modified file for forensic comparison. Verify fields in Kibana Discover on an actual Auditbeat FIM event.

---

## Rule Logic and Threshold

Apply as a **custom query rule**:

- **Rule type:** Custom query
- **Time window:** 5 minutes
- Alert on every `change` event — file creation (`created`) and deletion (`deleted`) events for these paths are also worth monitoring

---

## Why It Matters

`/etc/passwd`, `/etc/shadow`, and `/etc/sudoers` are the core authentication and authorization files on a Linux system. An attacker with write access to any of these can add a backdoor account, modify password hashes, or grant unrestricted sudo access to a compromised account. Auditbeat's file_integrity module calculates hashes on a schedule and reports changes — providing the when and which file without relying on process-level detection.

---

## Auditbeat Configuration

The Auditbeat file_integrity module must be configured with the monitored paths. In `/etc/auditbeat/auditbeat.yml` on LINUX-ENDPOINT (192.168.10.155):

```yaml
- module: file_integrity
  paths:
    - /etc/passwd
    - /etc/shadow
    - /etc/sudoers
    - /etc/sudoers.d
    - /etc/ssh/sshd_config
```

After modifying the config: `sudo systemctl restart auditbeat`

---

## Test Method

**Do not modify /etc/passwd, /etc/shadow, or /etc/sudoers for testing purposes.**

Safe test method:
1. Add a monitored test path to your Auditbeat config (e.g., `/tmp/fim-test-file`)
2. Create and modify that file to confirm the FIM pipeline works end-to-end
3. Validate that `event.module: "file_integrity"` and `event.type: "change"` events appear in the `auditbeat-*` index
4. Once the pipeline is confirmed, the rule covering `/etc/passwd` will fire on any legitimate change to those paths

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: File Integrity Alert: /etc/passwd
- Severity: High
- `file.path` showing the modified file
- `file.hash.sha256` (if configured) for forensic comparison

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule10-file-integrity.png` — Rule created in Kibana Security
- `evidence/screenshots/20260428_linux-endpoint_filebeat-auditbeat-running.png` — Auditbeat confirmed running on LINUX-ENDPOINT

---

## False Positive Considerations

- Package manager operations (`apt install`, `apt upgrade`) modify `/etc/passwd` and `/etc/shadow` when adding system users for new packages
- Legitimate user administration (`useradd`, `passwd`, `visudo`) by authorized admins
- System updates that modify SSH configuration (`/etc/ssh/sshd_config`)

---

## Tuning Notes

- Correlate alert timestamps with known maintenance windows or change management records to separate authorized from unauthorized changes
- Expand monitored paths to cover additional persistence locations: `/etc/cron.d/`, `/etc/profile.d/`, `/root/.ssh/authorized_keys`, `/home/*/.ssh/authorized_keys`
- Consider alerting on `/etc/ssh/sshd_config` changes at High severity — attackers modify SSH config to allow password authentication or add authorized keys
- If Auditbeat hash comparison is enabled, store baseline hashes and alert on any deviation — stronger signal than change event alone
