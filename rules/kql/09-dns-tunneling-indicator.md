# Rule 09 — DNS Tunneling Indicator

| Field | Value |
|-------|-------|
| **Rule Name** | DNS Tunneling Indicator |
| **Index Pattern** | `filebeat-*` |
| **Severity** | High |
| **MITRE ATT&CK** | T1071.004 — Application Layer Protocol: DNS |
| **Data Source** | DNS query logs (OPNsense syslog / Pi-hole / Zeek dns.log) via Filebeat |
| **Event ID / Signal** | DNS TXT/NULL record queries or abnormally long query names |
| **Status** | Created / pending full validation |

---

## Purpose

Detect indicators of DNS tunneling — a technique where attackers encode data inside DNS queries and responses to establish covert command and control channels over a protocol that is almost never blocked at the perimeter.

---

## KQL Query

```kql
(dns.question.type: ("TXT" OR "NULL")) OR
(dns.question.name: * AND dns.question.name.length > 50)
```

> **Field note:** DNS field availability depends on your log source. If using OPNsense syslog without Zeek, DNS fields may not be parsed into ECS format — the raw query may only appear in the `message` field. If using Zeek dns.log via Filebeat, fields like `dns.question.name` and `dns.question.type` should be populated. Verify field availability in Kibana Discover before deploying. If structured DNS fields are not available, consider a message-based query as a fallback.

**Fallback query (raw message parsing):**
```kql
message: (" TXT " OR " NULL ") AND syslog.facility_label: "local0"
```

---

## Rule Logic and Threshold

Apply as a **custom query rule** or **threshold rule**:

- **Option A (query rule):** Alert on every TXT/NULL query or long query name
- **Option B (threshold):** Alert when a single host generates 20+ DNS TXT queries within 5 minutes — more resistant to false positives from SPF/DKIM lookups

---

## Why It Matters

DNS is ubiquitous and rarely inspected. Tools like iodine, dnscat2, and DNSExfiltrator encode command and control data as DNS subdomain queries, using TXT or NULL records to receive responses. The traffic blends into normal DNS activity and most network monitoring tools won't flag it. Detecting based on record type and query length catches the two most common patterns without requiring deep packet inspection.

---

## Test Method

Full verification of this rule requires generating DNS TXT queries or long subdomain queries in the lab:

1. Confirm DNS events are present in `filebeat-*` by filtering in Kibana Discover
2. Check whether `dns.question.type` and `dns.question.name` fields exist in your indexed events
3. If Zeek is not deployed, DNS data may only be available in raw OPNsense syslog — adjust the query accordingly
4. Planned validation: dnscat2 test in Lab 2 (active-directory-attack-defense)

---

## Expected Result

Kibana Security generates an alert when DNS TXT/NULL queries or long subdomain queries are detected from lab endpoints.

---

## Evidence

- `evidence/screenshots/20260428_kibana_rule9-dns-tunneling.png` — Rule created in Kibana Security

---

## False Positive Considerations

- SPF, DKIM, and DMARC email authentication records are all TXT queries — high volume and completely legitimate
- CDN providers use long subdomains for traffic routing
- Some software update mechanisms query long CDN URLs
- Certificate transparency lookups can generate TXT queries

---

## Tuning Notes

- The threshold variant (20+ TXT queries from one host in 5 minutes) significantly reduces SPF/DKIM noise while catching actual tunneling
- The most reliable signal is TXT/NULL queries to domains with no established business relationship — combine with threat intelligence enrichment (domain age, registrar, reputation) for higher fidelity
- Long query name detection (>50 characters) is more specific than record type — most legitimate long queries go to known CDN domains; filtering out those domains improves precision
- Zeek integration would provide structured DNS logging and make this rule significantly more reliable — a planned improvement for Lab 2
