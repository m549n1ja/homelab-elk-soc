# Rule: Firewall Deny Spike

**Event Code:** OPNsense filterlog — syslog facility local0  
**Index:** `filebeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1046 — Network Service Discovery  

---

## KQL Query

```kql
syslog.facility_label: "local0" AND message: "block"
```

> Applied as a threshold rule: 50 or more matching events within 1 minute grouped by source IP. OPNsense sends firewall logs via syslog using facility `local0` — this cleanly separates firewall events from other syslog traffic on the same pipeline.

---

## Why This Matters

A spike in firewall deny events from a single source IP is the classic signature of port scanning or network reconnaissance. An attacker mapping your network before moving laterally will generate hundreds of blocked connection attempts in a short window. This rule catches that reconnaissance phase before the attacker finds an open path.

---

## Test Method

Confirmed OPNsense syslog events were arriving in the `filebeat-*` index by filtering on `syslog.facility_label: "local0"` in Kibana Discover. Verified the `message` field contained block event data from OPNsense filterlog. The rule threshold is calibrated against observed baseline block volume in the lab.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule6-firewall-deny.png` — rule created in Kibana Security  
`evidence/screenshots/20260428_elk-siem_opnsense-syslog-flowing.png` — OPNsense events confirmed in ELK  
`evidence/screenshots/20260428_linux-endpoint_opnsense-syslog-received.png` — packets arriving on UDP 514

---

## False Positive Considerations

- Misconfigured network devices repeatedly hitting closed ports will generate sustained block volume — identify by source IP and verify the device is not a scanner
- Vulnerability scanners run by authorized IT staff (Nessus, OpenVAS) will trigger this rule heavily — create a suppression exception for known scanner IPs or schedule scan windows
- Noisy internet background radiation (shodan-style scanning) hitting the WAN interface will generate block events — these are from OPNsense's perspective on the LAN side, so filter on `destination.ip` matching internal ranges to reduce WAN noise
