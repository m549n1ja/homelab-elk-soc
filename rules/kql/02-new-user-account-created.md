# Rule 02 — New User Account Created

| Field | Value |
|-------|-------|
| **Rule Name** | New User Account Created |
| **Index Pattern** | `winlogbeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1136.001 — Create Account: Local Account |
| **Data Source** | Windows Security Event Log via Winlogbeat |
| **Event ID** | 4720 — A user account was created |
| **Status** | Created / pending full validation |

---

## Purpose

Detect the creation of a new local Windows user account, which may indicate an attacker establishing a persistence mechanism or a backdoor account after gaining initial access.

---

## KQL Query

```kql
event.code: "4720"
```

---

## Rule Logic and Threshold

Apply as a **query rule** (no threshold — every event is an alert):

- **Rule type:** Custom query
- **Time window:** 5 minutes
- **Suppress on:** `winlog.event_data.TargetUserName` to avoid duplicate alerts for the same account

Every new account creation outside a known provisioning window is worth reviewing.

> **Field note:** The newly created account name may appear as `winlog.event_data.TargetUserName` or `user.target.name` depending on ECS mapping. The creating account is in `winlog.event_data.SubjectUserName` or `user.name`.

---

## Why It Matters

Attackers who establish a foothold often create a local account as a backup persistence mechanism. A local account survives domain password resets, doesn't rely on a compromised domain account, and can blend in if named plausibly. Any new local account that doesn't trace back to an authorized provisioning action is a high-priority investigation.

---

## Test Method

1. On WIN10-ENDPOINT (192.168.10.197), open an elevated command prompt
2. Run: `net user lab-test-user Password1! /add`
3. In Kibana Discover, filter: `event.code: "4720"`
4. Confirm the event appears in `winlogbeat-*` with the new username visible
5. Clean up: `net user lab-test-user /delete`

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: New User Account Created
- Severity: High
- Target username visible in alert details

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule2-new-user-created.png` — Rule created in Kibana Security

---

## False Positive Considerations

- Authorized IT provisioning during onboarding
- Software installers that create local service accounts (common with monitoring agents, database engines, print spoolers)
- System accounts created by Windows Update or feature installs

---

## Tuning Notes

- Review `winlog.event_data.SubjectUserName` — account creations by SYSTEM or a known provisioning account are lower priority than creations by a standard user
- Build an allowlist of known software-generated service account name patterns (e.g., `_sql`, `_backup`) and suppress those
- Alert on any 4720 event where `winlog.event_data.SubjectUserName` is a standard user account — that combination is highly anomalous
