# Rule: Brute Force — Failed Logins

**Event Code:** 4625  
**Index:** `winlogbeat-*`  
**Severity:** Medium  
**MITRE ATT&CK:** T1110.001 — Brute Force: Password Guessing  

---

## KQL Query

```kql
event.code: "4625"
```

> Applied as a threshold rule in Kibana Security: 5 or more events within 5 minutes grouped by `winlog.event_data.TargetUserName`.

---

## Why This Matters

Failed login volume is one of the most reliable early indicators of a password spray or brute force attempt. A single failed logon is noise — five in five minutes against the same account is a signal worth investigating.

---

## Test Method

Triggered by attempting multiple failed RDP and local logons against WIN10-ENDPOINT (192.168.10.197) using an invalid password. Audit Policy for "Logon/Logoff" was enabled via `secpol.msc` → Advanced Audit Policy Configuration to ensure 4625 events were generated.

---

## Evidence

`evidence/screenshots/20260429_kibana_alerts-firing.png` — 20 alerts firing for this rule  
`evidence/screenshots/20260428_kibana_rule1-brute-force-created.png` — rule created in Kibana Security

---

## False Positive Considerations

- Legitimate users mistyping their password will trigger this — tune the threshold higher (10+) or add a whitelist for known IT admin accounts
- Automated backup or service accounts with stale credentials hitting AD will generate sustained 4625 volume
- Consider suppressing alerts for logon failures where `winlog.event_data.SubStatus` is `0xC000006D` (wrong username) vs `0xC000006A` (wrong password) to separate noise from targeted attempts
