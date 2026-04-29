# Rule 06 — Firewall Deny Spike

| Field | Value |
|-------|-------|
| **Rule Name** | Firewall Deny Spike |
| **Index Pattern** | `filebeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1046 — Network Service Discovery |
| **Data Source** | OPNsense firewall syslog via UDP 514 → Filebeat → Logstash |
| **Event ID / Signal** | OPNsense filterlog block events (syslog facility: local0) |
| **Status** | Created / pending full validation |

---

## Purpose

Detect a spike in OPNsense firewall deny events from a single source IP, which may indicate network reconnaissance, port scanning, or an attacker probing for open services.

---

## KQL Query

```kql
syslog.facility_label: "local0" AND message: "block"
```

> **Field note:** OPNsense sends firewall logs via syslog using facility `local0` by default. After indexing through Filebeat, the facility label may appear as `syslog.facility_label`, `log.syslog.facility.name`, or similar. The `message` field contains the raw filterlog line. Verify the exact field names in Kibana Discover on an OPNsense event before deploying.

---

## Rule Logic and Threshold

Apply as a **threshold rule**:

- **Threshold:** 50 or more matching events
- **Time window:** 1 minute
- **Group by:** Source IP address field (verify field name in your indexed events — likely `source.ip` or parsed from the `message` field)

50+ blocked connections per minute from a single IP is well above normal background noise and strongly suggests active scanning.

---

## Why It Matters

Network service discovery is often the first step after initial access. An attacker who has compromised one host will scan the internal network to identify additional targets — open RDP, SMB shares, web services, and databases. A firewall deny spike is the earliest visible signal of that internal reconnaissance. Catching it here, before the attacker finds an open path, is the goal.

---

## Test Method

1. Confirm OPNsense syslog events are arriving in `filebeat-*` index:
   - In Kibana Discover, filter: `syslog.facility_label: "local0"`
   - Confirm events are present with firewall block/pass messages
2. Review the `message` field on a block event to confirm "block" appears in the raw syslog line
3. Threshold testing requires generating >50 blocked connections in 1 minute — use an authorized port scan against a firewalled IP in the lab (e.g., `nmap -p 1-1000 192.168.10.100` from WIN10-ENDPOINT, directed at a non-listening range)

---

## Expected Result

Kibana Security generates an alert with:
- Alert name: Firewall Deny Spike
- Severity: High
- Source IP grouped in alert details

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule6-firewall-deny.png` — Rule created in Kibana Security
- `evidence/screenshots/20260428_elk-siem_opnsense-syslog-flowing.png` — OPNsense syslog confirmed in ELK
- `evidence/screenshots/20260428_linux-endpoint_opnsense-syslog-received.png` — UDP 514 packets arriving on LINUX-ENDPOINT

---

## False Positive Considerations

- Authorized vulnerability scanners (Nessus, OpenVAS) running scheduled scans
- Misconfigured devices repeatedly attempting to reach a closed service
- High-volume internet background scanning hitting the WAN interface (these should be filtered by focusing on internal destination IPs only)

---

## Tuning Notes

- Create suppression exceptions for authorized scanner IPs (document the IP and owner in the exception note)
- Add a `destination.ip` filter scoped to your internal RFC1918 range to exclude WAN-side noise
- Consider a lower-severity companion rule at a lower threshold (10+ events/minute) to surface slower scans that stay under the 50-event radar
