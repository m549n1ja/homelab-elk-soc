# Rule 01 — Brute Force: Failed Logins

| Field | Value |
|-------|-------|
| **Rule Name** | Brute Force: Failed Logins |
| **Index Pattern** | `winlogbeat-*` |
| **Severity** | Medium |
| **MITRE ATT&CK** | T1110.001 — Brute Force: Password Guessing |
| **Data Source** | Windows Security Event Log via Winlogbeat |
| **Event ID** | 4625 — An account failed to log on |
| **Status** | Verified firing |

---

## Purpose

Detect repeated failed Windows logon attempts that may indicate a password guessing or brute force attack against a local or domain account.

---

## KQL Query

```kql
event.code: "4625"
```

---

## Rule Logic and Threshold

Apply as a **threshold rule** in Kibana Security:

- **Threshold:** 5 or more events
- **Time window:** 5 minutes
- **Group by:** `winlog.event_data.TargetUserName`

This suppresses single failed logons (common noise) and surfaces sustained attempts against the same account.

> **Field note:** Depending on your Elastic version and Winlogbeat ECS mapping, the target account field may appear as `winlog.event_data.TargetUserName` or `user.name`. Verify in Kibana Discover before creating the rule.

---

## Why It Matters

Failed login volume is one of the most reliable early indicators of a credential attack. A single failed logon is noise — five in five minutes against the same account is worth investigating. This rule catches both targeted brute force and low-and-slow password spraying when tuned to a low threshold.

---

## Prerequisite: Enable Windows Audit Policy

Event 4625 is **not logged by default**. You must enable it:

1. Open `secpol.msc` on WIN10-ENDPOINT
2. Navigate to: `Security Settings → Advanced Audit Policy Configuration → Logon/Logoff`
3. Enable **Audit Logon** → Failure

Without this, Winlogbeat will ship zero 4625 events regardless of how many failed logons occur.

---

## Test Method

1. On WIN10-ENDPOINT (192.168.10.197), attempt multiple failed RDP or local logons using an incorrect password
2. In Kibana Discover, filter: `event.code: "4625"`
3. Confirm events appear in the `winlogbeat-*` index within 60 seconds
4. Trigger the detection rule threshold by generating 5+ failures within the rule window

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: Brute Force: Failed Logins
- Severity: Medium
- Grouped by target username

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule1-brute-force-created.png` — Rule created in Kibana Security
- `evidence/screenshots/20260429_kibana_alerts-firing.png` — 20 alerts confirmed firing

---

## False Positive Considerations

- Legitimate users mistyping their password multiple times in quick succession
- Service accounts with stale or expired credentials retrying authentication automatically
- Automated scripts or backup agents using an outdated password

---

## Tuning Notes

- Raise the threshold to 10+ if alert volume is too high in environments with many users
- Filter out known service account names via `winlog.event_data.TargetUserName` exclusions
- Review `winlog.event_data.SubStatus` to distinguish wrong username (`0xC000006D`) from wrong password (`0xC000006A`) — wrong password attempts are higher fidelity
- Consider adding a secondary filter: `winlog.event_data.IpAddress` not equal to localhost to focus on network-sourced failures
