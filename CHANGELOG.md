# Changelog — homelab-elk-soc

All notable changes to this project are documented here.

---

## [Unreleased]

- Kibana detection rule and dashboard NDJSON exports
- Remaining 5 Sigma rules (rules 4–10)
- Full alert-firing validation for all 10 rules

---

## 2026-04-29

### Added
- `DEPLOYMENT.md` — full step-by-step deployment guide covering all 6 phases
- `CURRENT_LIMITATIONS.md` — honest documentation of lab constraints and planned improvements
- `CHANGELOG.md` — this file
- `rules/kql/01-brute-force-failed-logins.md` through `10-file-integrity-passwd.md` — complete numbered KQL rule documentation for all 10 detection rules
- `rules/sigma/` — 5 Sigma YAML rules: brute force, new user, suspicious PowerShell, new service, Linux passwd modified
- `scripts/linux/` — 4 validation and test scripts for Linux/ELK-SIEM
- `scripts/windows/` — 4 validation and test scripts for WIN10-ENDPOINT
- `evidence/EVIDENCE_INDEX.md` — updated with clickable screenshot links and Related Rule column

### Changed
- `configs/logstash/beats.conf` — replaced hardcoded credentials with `${ES_USER}` / `${ES_PASSWORD}` environment variables; added OPNsense firewall event tagging; documented TLS configuration options with production guidance
- `README.md` — rule statuses updated for unverified rules; links to DEPLOYMENT.md, ARCHITECTURE.md, and CURRENT_LIMITATIONS.md added
- `rules/kql/` — old unnumbered rule files deprecated in favor of numbered versions

---

## 2026-04-28

### Added
- LINUX-ENDPOINT VM (Ubuntu 24.04 Desktop, 192.168.10.155)
- Filebeat 8.x installed and running on LINUX-ENDPOINT → Logstash 192.168.10.100:5044
- Auditbeat 8.x installed and running on LINUX-ENDPOINT → Logstash 192.168.10.100:5044
- OPNsense syslog confirmed flowing via UDP 514 → Filebeat → ELK
- All 10 Kibana Security detection rules created
- Rules 1 and 8 verified firing (20 alerts and 1 alert respectively)
- Evidence screenshots for all 10 rules captured

### Changed
- Total ELK event count reached 29,000+
- Phase 4 (Beat Agents) marked complete

---

## 2026-04-27

### Added
- Initial lab build — ELK-SIEM VM (Ubuntu Server 24.04, 192.168.10.100)
- Elasticsearch 8.x installed and running
- Logstash 8.x installed and running
- Kibana 8.x installed and running — accessible at http://192.168.10.100:5601
- WIN10-ENDPOINT VM (Windows 10 Pro, 192.168.10.197 DHCP)
- Sysmon64 installed with SwiftOnSecurity config
- Winlogbeat 8.19.13 installed and shipping to Logstash 192.168.10.100:5044
- Windows Audit Policy enabled for Event 4625
- 4,500+ Winlogbeat events + 192 Sysmon events indexed in ELK
- Initial repo structure scaffolded
- `ARCHITECTURE.md` written
- `evidence/REDACTION.md` written
- `evidence/screenshots/` populated with Phase 1–3 evidence

---

*Project: homelab-elk-soc | Author: John Medina | github.com/m549n1ja*
