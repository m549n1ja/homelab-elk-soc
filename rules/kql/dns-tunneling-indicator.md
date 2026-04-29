# Rule: DNS Tunneling Indicator

**Event Code:** DNS query logs (Pi-hole / Zeek dns.log)  
**Index:** `filebeat-*`  
**Severity:** High  
**MITRE ATT&CK:** T1071.004 — Application Layer Protocol: DNS  

---

## KQL Query

```kql
dns.question.type: ("TXT" OR "NULL") OR
(dns.question.name: * AND dns.question.name.length > 50)
```

> Targets two patterns: unusual DNS record types (TXT and NULL are rarely queried by endpoints in normal operation) and abnormally long query names (encoded data tunneled through DNS subdomains). Either pattern in isolation is a weak signal — together, or in volume, they're a strong indicator.

---

## Why This Matters

DNS is almost never blocked outright, which makes it ideal for covert command and control. Tools like iodine, dnscat2, and DNSExfiltrator encode data as DNS subdomains and use TXT or NULL records to receive responses. The traffic looks like DNS to most network monitoring tools — you need to look at query frequency, record types, and subdomain length to catch it.

---

## Test Method

Confirmed DNS query fields (`dns.question.type`, `dns.question.name`) are populated in the `filebeat-*` index from OPNsense syslog and Filebeat system logs. Rule is configured and active — full verification requires generating DNS TXT queries or long subdomain queries in the lab to confirm alert firing. Planned for Lab 2 (active-directory-attack-defense) using dnscat2.

---

## Evidence

`evidence/screenshots/20260428_kibana_rule9-dns-tunneling.png` — rule created in Kibana Security

---

## False Positive Considerations

- SPF, DKIM, and DMARC email authentication records are TXT queries — these are high volume and completely legitimate; filter by destination domain or add known email infrastructure to a suppression list
- CDN providers and some software update mechanisms use long subdomains — review query destinations before escalating
- The most reliable signal is TXT or NULL queries to domains with no legitimate business relationship combined with high query frequency from a single endpoint
