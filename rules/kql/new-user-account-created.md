# Rule: New User Account Created

**Event Code:** 4720  
**Index:** `winlogbeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1136.001 — Create Account: Local Account  

---

## KQL Query

```kql
event.code: "4720"
```

---

## Why This Matters

Attackers who gain a foothold on a Windows system often create a new local account as a persistence mechanism — it survives reboots, doesn't depend on a compromised domain account, and may go unnoticed if the name blends in. Any new local account creation outside of a managed provisioning process is worth investigating immediately.

---

## Test Method

Created a new local user account on WIN10-ENDPOINT via `net user testuser Password123! /add` from an elevated command prompt. Confirmed Event 4720 appeared in the `winlogbeat-*` index in Kibana within seconds.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule2-new-user-created.png` — rule created in Kibana Security

---

## False Positive Considerations

- Legitimate IT provisioning will generate this event — in a managed environment, correlate against your ITSM ticket system to distinguish authorized vs. unauthorized account creation
- Software installers occasionally create service accounts as part of setup — review `winlog.event_data.SubjectUserName` to identify the creating account
- Consider suppressing alerts when the creating account is a known provisioning service account
