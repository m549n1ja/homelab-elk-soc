# Current Limitations — homelab-elk-soc

This document is an honest accounting of what this lab does and does not do. Portfolio projects that claim perfection are not trustworthy. These are the real constraints.

---

## Architecture Limitations

**Single-node Elasticsearch cluster**
This lab runs a single Elasticsearch node. There is no redundancy, no shard replication, and no high availability. If the ELK-SIEM VM goes down, all log ingestion and detection stops. This is acceptable for a learning lab — it is not acceptable in production.

**No index lifecycle management (ILM)**
Indices are growing indefinitely. There is no rollover policy, no hot/warm/cold tiering, and no automatic deletion of old data. At the current event volume (~29,000 events) this is not a problem. At enterprise scale, this would exhaust disk space within days.

**Lab-only TLS configuration**
`ssl_verification_mode: none` is set in the Logstash pipeline to simplify the lab setup. This disables certificate validation on the Elasticsearch output connection and should not be used outside a closed RFC1918 network.

**Beat agents authenticate with the elastic superuser**
Logstash connects to Elasticsearch using environment variables that contain the elastic superuser password. In production, dedicated API keys scoped to write-only access on specific indices should be used instead.

---

## Detection Coverage Limitations

**Not all rules have full alert-firing validation**
Rules 1 (Brute Force) and 8 (Privilege Escalation: Special Logon) have been verified firing with screenshot evidence. Rules 2–7 and 9–10 were created in Kibana and confirmed active, but have not all been individually triggered and validated with dedicated test evidence. Rule 9 (DNS Tunneling) in particular requires Zeek or a structured DNS log source to be fully effective — the current OPNsense syslog pipeline may not parse DNS fields into the structured format the KQL query expects.

**No exported Kibana NDJSON objects**
The detection rules and dashboards exist in the Kibana instance but have not been exported as NDJSON files. This means the rules and dashboards cannot be imported into another Kibana instance from this repository without manual recreation. Exporting them is a planned next step.

**Sigma rules are experimental**
The five Sigma rules in `rules/sigma/` are documented for educational purposes and portfolio value. They have not been run through a Sigma converter (sigma-cli, uncoder.io) and validated against the actual indexed field names in this environment.

**No SOAR or case management integration**
Kibana Security alerts are generated but there is no downstream case management, automated enrichment, or ticketing integration. Alerts require manual triage in Kibana.

---

## Field Name Variance Warning

ELK field names for Windows events can vary between Winlogbeat versions and ECS mapping configurations. Several rule files note specific fields (e.g., `winlog.event_data.TargetUserName`, `winlog.event_data.IpAddress`) that may appear differently in your indexed events depending on your exact versions. Always verify field names in Kibana Discover on a real event before relying on a KQL rule in production.

---

## Network Scope

The lab uses private RFC1918 addressing (`192.168.10.0/24`). Internal lab IPs are retained in this repository intentionally — they are not public infrastructure and pose no exposure risk. No public-facing services are involved.

---

## Planned Improvements

| Item | Priority | Notes |
|------|----------|-------|
| Export Kibana detection rules and dashboards as NDJSON | High | Allows repo import into other Kibana instances |
| Add remaining Sigma rules (rules 4–10) | Medium | Complete the full 10-rule Sigma coverage |
| Validate all 10 rules with dedicated test evidence | High | Generate events for each rule type and capture screenshots |
| Add Zeek integration for structured DNS logging | Medium | Required for Rule 09 (DNS Tunneling) to be fully effective |
| Add TheHive or similar case management integration | Low | Lab 3+ scope |
| Add CI linting for Markdown, shell scripts, and Sigma YAML | Low | GitHub Actions workflow |
| Replace elastic superuser with API keys for all Beat agents | High | Pre-production hardening |
| Add ILM policy configuration to DEPLOYMENT.md | Medium | Complete the production hardening section |
| Lab 2: Active Directory attack-defense lab | High | Next project in portfolio build |

---

*Project: homelab-elk-soc | Author: John Medina | github.com/m549n1ja*
