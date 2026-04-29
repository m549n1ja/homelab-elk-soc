# Rule: Privilege Escalation — Special Privileges Assigned

**Event Code:** 4672  
**Index:** `winlogbeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1068 — Exploitation for Privilege Escalation  

---

## KQL Query

```kql
event.code: "4672" AND
NOT winlog.event_data.SubjectUserName: ("SYSTEM" OR "LOCAL SERVICE" OR "NETWORK SERVICE" OR "ANONYMOUS LOGON")
```

> The NOT clause filters out known system accounts that legitimately receive special privileges on every boot and service start. Without this filter the rule generates significant noise from normal Windows operations.

---

## Why This Matters

Event 4672 fires whenever an account with sensitive privileges (SeDebugPrivilege, SeTakeOwnershipPrivilege, SeImpersonatePrivilege, and others) logs on. These are the privileges attackers need for pass-the-hash, token impersonation, and process injection. A non-system account receiving a 4672 event means an elevated account is active — worth knowing about, especially outside business hours or in context with other alerts.

---

## Test Method

Logged into WIN10-ENDPOINT with an account that has local administrator rights. Confirmed Event 4672 was generated in the `winlogbeat-*` index and that the `winlog.event_data.PrivilegeList` field was populated with the assigned privileges. Verified the filter correctly suppressed SYSTEM account events.

---

## Evidence

`evidence/screenshots/20260429_kibana_alerts-firing.png` — 1 alert confirmed firing for this rule  
`evidence/screenshots/20260428_kibana_rule8-privilege-escalation.png` — rule created in Kibana Security

---

## False Positive Considerations

- Any admin logon will generate this event — in environments with frequent admin activity, this rule needs additional context (time of day, source host, correlation with other events) to be actionable
- Service accounts with elevated privileges will fire this on every service start — add known service account names to the suppression filter
- Most valuable when correlated with preceding 4624 events from unexpected source IPs, or paired with a 4625 brute force alert for the same account — isolated 4672 events are low fidelity without that context
