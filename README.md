# homelab-elk-soc
## Enterprise-grade ELK Stack SIEM | SOC Detection Lab

I built this lab because I wanted to understand what a SOC analyst actually works with every day — not just read about it. Coming from a background where operational readiness and attention to detail are non-negotiable, I wanted to prove I could stand up a real detection environment from scratch: configure the stack, pull logs from multiple sources, write rules that actually fire, and document every step the way you would in a real environment. This repo is that proof. It's a single-node ELK 8.x SIEM ingesting logs from a Windows endpoint (with Sysmon), a Linux endpoint, and an OPNsense firewall — 29,000+ events, 10 custom KQL detection rules mapped to MITRE ATT&CK, and 3 Kibana dashboards. Everything is built on commodity hardware running VMware. No cloud shortcuts.

---

## Skills Demonstrated

| Skill | How This Repo Proves It |
|-------|------------------------|
| SIEM deployment and configuration | Stood up Elasticsearch, Logstash, and Kibana 8.x from scratch on Ubuntu Server — configured pipelines, data views, and index patterns |
| Log ingestion pipeline | Winlogbeat, Filebeat, and Auditbeat all shipping to Logstash 5044 → Elasticsearch 9200 with verified index growth |
| Windows endpoint visibility | Sysmon64 (SwiftOnSecurity config) + Winlogbeat — Sysmon events, Security events, and audit policy tuned for 4625 |
| Linux endpoint visibility | Filebeat (system logs) + Auditbeat (file integrity monitoring on /etc/passwd) — both confirmed in ELK |
| Network/firewall log ingestion | OPNsense syslog over UDP 514 → Filebeat → Logstash — firewall block events indexed and queryable |
| Detection engineering | 10 custom KQL detection rules — logic, thresholds, and index targets written by hand, not imported |
| MITRE ATT&CK mapping | All 10 rules tagged to specific sub-techniques across Credential Access, Persistence, Execution, Lateral Movement, C2, Impact |
| Alert verification | Rules 1 and 8 verified firing in Kibana Security — screenshots in evidence/ |
| Dashboard building | 3 Kibana dashboards built: Security Overview, Authentication Activity, Network Traffic |
| Documentation | Every phase documented with purpose, commands, lessons learned, and screenshot evidence |

---

## Lab Architecture

```
                        192.168.10.0/24
                   ┌─────────────────────────┐
                   │                         │
   Internet ──── OPNsense (192.168.10.1)     │
                   │   Chromebox CN60         │
                   │   Syslog UDP 514 ──────► │
                   │                         │
      ┌────────────┼────────────┐             │
      │            │            │             │
      ▼            ▼            ▼             │
 WIN10-ENDPOINT  LINUX-ENDPOINT  ELK-SIEM     │
 192.168.10.197  192.168.10.155  192.168.10.100
 Windows 10 Pro  Ubuntu 24.04   Ubuntu 24.04  │
 Winlogbeat ───► Filebeat   ──► Logstash:5044 │
 Sysmon64        Auditbeat  ──► Elasticsearch │
                                Kibana:5601   │
                   │                         │
                   └─────────────────────────┘
                   Ryzen 9 Host: 192.168.10.10
                   VMware Workstation | 64GB RAM
```

---

## Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Elasticsearch | 8.x | Log storage and indexing |
| Logstash | 8.x | Log ingestion pipeline (Beats input, ES output) |
| Kibana | 8.x | Visualization, detection rules, dashboards |
| Winlogbeat | 8.19.13 | Windows event log shipping (Security + Sysmon) |
| Sysmon64 | Latest | Windows process and network telemetry |
| Filebeat | 8.x | Linux system log shipping + OPNsense syslog relay |
| Auditbeat | 8.x | Linux file integrity monitoring and auditd |
| OPNsense | 26.1 | Perimeter firewall, syslog source |
| VMware Workstation | — | Hypervisor on Ryzen 9 host |
| Ubuntu Server 24.04 | — | ELK-SIEM OS |
| Ubuntu Desktop 24.04 | — | LINUX-ENDPOINT OS |
| Windows 10 Pro | — | WIN10-ENDPOINT OS |

---

## Log Sources

| Source | Type | Approx. Events/Day | Index Pattern |
|--------|------|--------------------|---------------|
| WIN10-ENDPOINT (192.168.10.197) | Windows Security Events (4624, 4625, 4720, 4698, 4672, 7045) | ~500 | `winlogbeat-*` |
| WIN10-ENDPOINT (192.168.10.197) | Sysmon process/network telemetry | ~200 | `winlogbeat-*` |
| LINUX-ENDPOINT (192.168.10.155) | Linux system logs (auth, syslog, kern) | ~1,000 | `filebeat-*` |
| LINUX-ENDPOINT (192.168.10.155) | Auditbeat file integrity + auditd | ~300 | `auditbeat-*` |
| OPNsense (192.168.10.1) | Firewall block/pass events via syslog UDP 514 | ~500 | `filebeat-*` |

**Total events in ELK as of 2026-04-29: 29,000+**

---

## Detection Rules (MITRE ATT&CK Mapped)

| # | Rule Name | Event Code | Severity | MITRE Sub-Technique | Status |
|---|-----------|------------|----------|---------------------|--------|
| 1 | Brute Force: Failed Logins | 4625 | Medium | T1110.001 | ✅ VERIFIED FIRING — 20 alerts |
| 2 | New User Account Created | 4720 | High | T1136.001 | ✅ Active |
| 3 | Suspicious PowerShell Execution | 4104 | High | T1059.001 | ✅ Active |
| 4 | New Scheduled Task | 4698 | High | T1053.005 | ✅ Active |
| 5 | RDP Login from External IP | 4624 + LogonType:10 | Critical | T1021.001 | ✅ Active |
| 6 | Firewall Deny Spike | OPNsense local0 block | High | T1046 | ✅ Active |
| 7 | New Service Installed | 7045 | High | T1543.003 | ✅ Active |
| 8 | Privilege Escalation: Special Logon | 4672 | High | T1068 | ✅ VERIFIED FIRING — 1 alert |
| 9 | DNS Tunneling Indicator | DNS TXT records | High | T1071.004 | ✅ Active |
| 10 | File Integrity Alert: /etc/passwd | Auditbeat FIM | High | T1565.001 | ✅ Active |

KQL queries and Sigma YAML skeletons: [rules/kql/](rules/kql/)

---

## Evidence Pack

Full screenshot index with phase mapping: [evidence/EVIDENCE_INDEX.md](evidence/EVIDENCE_INDEX.md)

35 screenshots covering all 6 phases — ELK stack deployment, endpoint agent configuration, OPNsense syslog integration, all 10 detection rules created, verified alert firing, and all 3 dashboards live.

---

## What I Learned

1. **Logstash, not Elasticsearch, is the correct output target for Beat agents in this stack.** I initially had Winlogbeat pointing at port 9200 (Elasticsearch direct). That works in simple setups but you lose pipeline filtering. Fixed it to 5044 (Logstash) — now every log gets tagged by source type before indexing.

2. **cluster.initial_master_nodes can silently break Elasticsearch if it appears twice in the config file.** It was present on lines 74 and 109 in my elasticsearch.yml. ES would start but fail to form the cluster. Lesson: grep your config files before assuming a setting is set once.

3. **Windows Audit Policy is not enabled by default — Event 4625 will not log without it.** You can have Winlogbeat running perfectly and get zero failed login events because Windows isn't generating them. Had to manually configure Advanced Audit Policy for Logon/Logoff.

4. **Kibana's Security detection engine requires the correct data view.** The default `logs-*` view doesn't include winlogbeat or filebeat indices. Created `winlogbeat-*` and `filebeat-*` data views manually and pointed the security engine at the right pattern before rules would return results.

5. **Sysmon must be installed before adding the Microsoft-Windows-Sysmon/Operational channel to winlogbeat.yml.** If the channel doesn't exist when Winlogbeat starts, it logs an error and skips it silently. The fix is order of operations: install Sysmon first, then update the config.

6. **OPNsense syslog uses facility local0 by default.** Knowing this let me write a precise KQL filter for firewall events instead of trying to parse every syslog message. Filtering on `syslog.facility_label: "local0"` cleanly isolates OPNsense traffic.

7. **VMware Tools is not optional if you want to work efficiently.** Copy-paste between the host and VMs is disabled without it. Small thing, but I lost time early on manually re-typing commands from documentation until I installed it.

---

## What I'd Do Differently in Production

1. **Use API keys instead of username/password in Logstash output.** The `beats.conf` pipeline uses `user: elastic` with a password. In production that password has to rotate, and every pipeline breaks when it does. API keys scope the permissions to exactly what Logstash needs and can be revoked individually without touching credentials elsewhere.

2. **Enable SSL certificate validation on the Elasticsearch output.** I used `ssl_verification_mode: "none"` to get the lab running quickly. In a real environment that's a man-in-the-middle waiting to happen — deploy a proper CA or use Elasticsearch's built-in CA and validate the cert chain.

3. **Run Logstash as a dedicated service account with minimal permissions.** In this lab Logstash runs as a standard user. In production it should have read access to pipeline configs and write access to its own log directory — nothing else.

4. **Implement index lifecycle management (ILM) from day one.** Letting indices grow unbounded works fine in a lab with 29,000 events. At enterprise scale with millions of events per day, you need hot/warm/cold tiering and automatic rollover configured before the cluster is under load — not after you've run out of disk.

---

## Resume Bullet

> Deployed enterprise-grade ELK 8.x SIEM ingesting 29,000+ events from Windows, Linux, and firewall sources — wrote 10 custom KQL detection rules mapped to MITRE ATT&CK with verified alert generation.

---

*Built by John Medina | [github.com/m549n1ja](https://github.com/m549n1ja) | Post-GCIH | 2026*
