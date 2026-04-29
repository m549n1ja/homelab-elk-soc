# Rule 08 — Privilege Escalation: Special Logon

| Field | Value |
|-------|-------|
| **Rule Name** | Privilege Escalation: Special Logon |
| **Index Pattern** | `winlogbeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1068 — Exploitation for Privilege Escalation |
| **Data Source** | Windows Security Event Log via Winlogbeat |
| **Event ID** | 4672 — Special privileges assigned to new logon |
| **Status** | Verified firing |

---

## Purpose

Detect when a user account is assigned sensitive privileges at logon. This surfaces elevated logon sessions that may indicate privilege escalation, token impersonation, or an attacker operating with elevated rights.

---

## KQL Query

```kql
event.code: "4672" AND
NOT winlog.event_data.SubjectUserName: (
  "SYSTEM" OR
  "LOCAL SERVICE" OR
  "NETWORK SERVICE" OR
  "ANONYMOUS LOGON" OR
  "DWM-*" OR
  "UMFD-*"
)
```

The exclusion filters out built-in system accounts that legitimately receive special privileges on every boot cycle. Without this filter the rule generates high alert volume from normal Windows operation.

> **Field note:** Subject account may appear as `winlog.event_data.SubjectUserName` or `user.name`. The `winlog.event_data.PrivilegeList` field contains the specific privileges assigned — this is a critical triage field.

---

## Rule Logic and Threshold

Apply as a **custom query rule**:

- **Rule type:** Custom query
- **Time window:** 5 minutes
- Alert on every non-system 4672 event after exclusions

In a lab with limited user accounts, post-filter volume is low and every alert is meaningful.

---

## Why It Matters

Event 4672 fires when an account with SeDebugPrivilege, SeTakeOwnershipPrivilege, SeImpersonatePrivilege, or other sensitive privileges logs on. These are the privileges attackers need for pass-the-hash, token impersonation, and process injection. Monitoring 4672 for non-system accounts provides visibility into when elevated sessions are active — especially valuable when correlated with other alerts like failed logon spikes or new user creation.

---

## Test Method

1. Log into WIN10-ENDPOINT (192.168.10.197) with a local administrator account
2. In Kibana Discover, filter: `event.code: "4672"` — confirm the event appears with `SubjectUserName` populated
3. Review the `PrivilegeList` field — administrator logons will show SeSecurityPrivilege, SeTakeOwnershipPrivilege, SeLoadDriverPrivilege, and others
4. Confirm the rule suppresses SYSTEM and service account events using the exclusion filter

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: Privilege Escalation: Special Logon
- Severity: High
- Subject username and privilege list visible in alert details

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule8-privilege-escalation.png` — Rule created in Kibana Security
- `evidence/screenshots/20260429_kibana_alerts-firing.png` — 1 alert confirmed firing

---

## False Positive Considerations

- Any administrator logon generates this event — in environments with frequent admin activity the rule produces significant volume
- Service accounts with elevated privileges will fire on every service start
- Domain administrator accounts generate this on every interactive or remote logon

---

## Tuning Notes

- This rule is most valuable in correlation, not isolation — a 4672 event following a 4625 brute force alert for the same account is a high-confidence escalation sequence
- Add `winlog.event_data.PrivilegeList` contains `SeDebugPrivilege` as an additional filter — this specific privilege is rarely needed legitimately and is a strong indicator of attack tooling
- Consider suppressing known admin account names during documented maintenance windows and alerting only on out-of-hours 4672 events from those accounts
- In environments with many admins, add a time-of-day condition to surface logons outside expected working hours
