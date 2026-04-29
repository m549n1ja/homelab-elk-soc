# Rule: New Service Installed

**Event Code:** 7045  
**Index:** `winlogbeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1543.003 — Create or Modify System Process: Windows Service  

---

## KQL Query

```kql
event.code: "7045"
```

---

## Why This Matters

Installing a new Windows service is a reliable persistence and privilege escalation technique. Services run as SYSTEM by default, survive reboots, and can execute arbitrary binaries. Attackers use service installation to maintain persistence after gaining initial access — tools like Metasploit's `psexec` module and many RATs establish themselves as services. Any new service installation that isn't tied to a known software deployment event should be reviewed.

---

## Test Method

Confirmed Event 7045 is generated when a new service is installed by reviewing existing events in Kibana from Winlogbeat's System log channel. The `winlog.event_data.ServiceName` and `winlog.event_data.ImagePath` fields were verified as populated and useful for triage.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule7-new-service.png` — rule created in Kibana Security

---

## False Positive Considerations

- Software installations are the most common source of 7045 events — build a baseline of expected service names from your standard application set
- Windows Update occasionally installs temporary services during patch application
- The `winlog.event_data.ImagePath` field is the most important triage field — services pointing to `%TEMP%`, `%APPDATA%`, or any user-writable directory are immediately suspicious regardless of the service name
- Also check `winlog.event_data.ServiceType` — driver installs (type `kernel mode driver`) are higher severity than standard services
