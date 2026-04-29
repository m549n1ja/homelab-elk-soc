# Rule 05 — RDP Login from External IP

| Field | Value |
|-------|-------|
| **Rule Name** | RDP Login from External IP |
| **Index Pattern** | `winlogbeat-*` |
| **Severity** | Critical |
| **MITRE ATT&CK** | T1021.001 — Remote Services: Remote Desktop Protocol |
| **Data Source** | Windows Security Event Log via Winlogbeat |
| **Event ID** | 4624 — An account was successfully logged on (Logon Type 10) |
| **Status** | Created / pending full validation |

---

## Purpose

Detect successful RDP logons originating from IP addresses outside the lab's RFC1918 LAN segment, which would indicate an external actor has authenticated to a Windows endpoint.

---

## KQL Query

```kql
event.code: "4624" AND
winlog.event_data.LogonType: "10" AND
NOT winlog.event_data.IpAddress: ("192.168.10.*" OR "127.0.0.1" OR "::1" OR "-")
```

**Logon Type 10 = RemoteInteractive (RDP)**

The `NOT` clause excludes:
- `192.168.10.*` — the lab LAN
- `127.0.0.1` and `::1` — localhost
- `-` — Windows placeholder when source IP is unavailable

> **Field note:** Source IP may appear as `winlog.event_data.IpAddress` or `source.ip` depending on ECS mapping. Verify on an actual 4624 event in Kibana Discover before deploying.

---

## Rule Logic and Threshold

Apply as a **custom query rule**:

- **Rule type:** Custom query
- No threshold — any single match is a critical alert
- Every external RDP logon must be investigated

---

## Why It Matters

A successful RDP logon from a non-RFC1918 source means an external party authenticated to your endpoint with valid credentials. In this lab, OPNsense should be blocking all inbound RDP from the WAN — if this rule fires, it means either the firewall was bypassed, an endpoint was exposed directly, or an attacker is pivoting from a previously compromised internal host. Any firing of this rule should be treated as a priority incident.

---

## Test Method

This rule is intentionally difficult to trigger safely in the lab. Verification approach:

1. In Kibana Discover, filter: `event.code: "4624" AND winlog.event_data.LogonType: "10"` to confirm the fields are indexed
2. Review existing 4624 LogonType 10 events — confirm source IPs are all within `192.168.10.0/24`
3. Rule is active and will fire on any future event matching the non-RFC1918 pattern
4. Do not expose RDP to the internet to test — the expected result is zero alerts in a properly firewalled lab

---

## Expected Result

Under normal lab conditions: no alerts (OPNsense blocks inbound RDP from WAN).  
If the rule fires: critical alert requiring immediate investigation of the source IP and logon account.

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule5-rdp-external.png` — Rule created in Kibana Security

---

## False Positive Considerations

- VPN users who authenticate to RDP before their VPN tunnel is established may appear as external — whitelist known VPN egress IPs
- Cloud-based jump hosts or authorized bastion servers with public IPs — whitelist those specific source IPs
- In this lab environment, this rule should never produce a false positive

---

## Tuning Notes

- The most important tuning action is ensuring your internal RFC1918 ranges are fully captured in the exclusion (add `10.*` and `172.16.*` through `172.31.*` for completeness in environments using those ranges)
- Add an additional alert for Logon Type 10 events occurring outside business hours even from internal IPs — that's a secondary detection for lateral RDP movement
