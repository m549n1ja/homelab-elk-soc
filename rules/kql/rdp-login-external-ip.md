# Rule: RDP Login from External IP

**Event Code:** 4624 (Logon Type 10)  
**Index:** `winlogbeat-*`  
**Severity:** Critical  
**MITRE ATT&CK:** T1021.001 — Remote Services: Remote Desktop Protocol  

---

## KQL Query

```kql
event.code: "4624" AND
winlog.event_data.LogonType: "10" AND
NOT winlog.event_data.IpAddress: ("192.168.10.*" OR "127.0.0.1" OR "::1")
```

> Logon Type 10 = RemoteInteractive (RDP). The NOT clause filters out the lab LAN (192.168.10.0/24) and localhost to isolate RDP sessions originating from outside the expected network.

---

## Why This Matters

Successful RDP logons from non-RFC1918 addresses mean someone authenticated to your Windows machine from the internet. In a lab this is almost certainly a misconfigured firewall or a deliberate test. In production, it means an attacker has valid credentials and remote access to an endpoint — this is a critical incident requiring immediate response.

---

## Test Method

Verified the rule logic by reviewing existing 4624 events in Kibana and confirming the LogonType field was populated. Confirmed no external RDP sessions in the lab environment (OPNsense is blocking inbound RDP). The rule fires against any future event matching the pattern.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule5-rdp-external.png` — rule created in Kibana Security

---

## False Positive Considerations

- VPN users connecting from external IPs before establishing VPN will appear as external — consider suppressing for known VPN egress ranges
- Cloud-based jump hosts or bastion servers may legitimately connect from non-RFC1918 addresses — whitelist those source IPs
- In a lab environment this rule should almost never fire — any hit should be treated as a priority investigation
