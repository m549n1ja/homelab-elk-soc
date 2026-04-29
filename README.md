# Homelab ELK SOC

## ELK Stack SIEM and Detection Lab

I built this lab because I wanted to understand what a SOC analyst actually works with every day — not just read about it. Coming from a background where operational readiness and attention to detail are non-negotiable, I wanted to prove that I could stand up a real detection environment from scratch: configure the stack, pull logs from multiple sources, write rules that actually fire, and document the process the way I would in a real environment.

This repository is the result: a single-node ELK 8.x SIEM ingesting logs from a Windows endpoint with Sysmon, a Linux endpoint, and an OPNsense firewall. The lab currently contains 29,000+ indexed events, 10 custom KQL detection rules mapped to MITRE ATT&CK, and 3 Kibana dashboards. Everything was built on commodity hardware using VMware, with no cloud shortcuts.

---

## Project Goals

The purpose of this project was to build a practical SOC-style monitoring environment and use it to answer four questions:

1. Can I deploy and configure the core Elastic Stack components myself?
2. Can I collect useful telemetry from Windows, Linux, and firewall sources?
3. Can I write detection logic that produces real alerts?
4. Can I document the build clearly enough that another analyst or hiring manager can understand what was done and why?

This is not meant to be a production blueprint. It is a hands-on lab focused on SIEM fundamentals, log ingestion, detection logic, alert validation, and evidence-based documentation.

---

## Skills Demonstrated

| Skill Area | How This Lab Demonstrates It |
|---|---|
| SIEM deployment | Installed and configured Elasticsearch, Logstash, and Kibana 8.x on Ubuntu Server |
| Log ingestion | Forwarded Windows, Linux, and firewall logs into ELK using Winlogbeat, Filebeat, Auditbeat, and syslog |
| Windows visibility | Collected Windows Security events and Sysmon telemetry from a Windows 10 endpoint |
| Linux visibility | Collected Linux system logs and Auditbeat file integrity monitoring data |
| Network visibility | Forwarded OPNsense firewall syslog events into the ELK pipeline |
| Detection engineering | Created 10 custom KQL detection rules for common SOC use cases |
| MITRE mapping | Mapped each detection rule to a relevant MITRE ATT&CK technique or sub-technique |
| Alert validation | Confirmed selected rules firing in Kibana Security and captured screenshot evidence |
| Dashboarding | Built dashboards for security overview, authentication activity, and network traffic |
| Documentation | Recorded build steps, lessons learned, screenshots, and production improvements |

---

## Lab Architecture

```text
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
|---|---:|---|
| Elasticsearch | 8.x | Stores and indexes security events |
| Logstash | 8.x | Receives, tags, and forwards log data |
| Kibana | 8.x | Dashboards, searches, detections, and alerts |
| Winlogbeat | 8.19.13 | Ships Windows Security and Sysmon events |
| Sysmon64 | Latest | Adds detailed Windows process and network telemetry |
| Filebeat | 8.x | Ships Linux system logs and relayed firewall syslog |
| Auditbeat | 8.x | Provides Linux audit and file integrity monitoring |
| OPNsense | 26.1 | Firewall and syslog source |
| VMware Workstation | — | Local virtualization platform |
| Ubuntu Server 24.04 | — | ELK server operating system |
| Ubuntu Desktop 24.04 | — | Linux endpoint operating system |
| Windows 10 Pro | — | Windows endpoint operating system |

---

## Log Sources

| Source | Telemetry | Index Pattern | Purpose |
|---|---|---|---|
| WIN10-ENDPOINT `192.168.10.197` | Windows Security events | `winlogbeat-*` | Authentication, account activity, privilege events |
| WIN10-ENDPOINT `192.168.10.197` | Sysmon telemetry | `winlogbeat-*` | Process, command-line, and network visibility |
| LINUX-ENDPOINT `192.168.10.155` | Linux system logs | `filebeat-*` | Authentication, system, and kernel events |
| LINUX-ENDPOINT `192.168.10.155` | Auditbeat and FIM events | `auditbeat-*` | Linux audit data and file integrity monitoring |
| OPNsense `192.168.10.1` | Firewall syslog | `filebeat-*` | Network allow/block activity |

**Current indexed event count:** 29,000+ events as of 2026-04-29.

---

## Detection Rules

| # | Rule Name | Main Signal | Severity | MITRE ATT&CK | Status |
|---:|---|---|---|---|---|
| 1 | Brute Force: Failed Logins | Event ID 4625 | Medium | T1110.001 | Verified firing |
| 2 | New User Account Created | Event ID 4720 | High | T1136.001 | Active |
| 3 | Suspicious PowerShell Execution | Event ID 4104 | High | T1059.001 | Active |
| 4 | New Scheduled Task | Event ID 4698 | High | T1053.005 | Active |
| 5 | RDP Login from External IP | Event ID 4624, Logon Type 10 | Critical | T1021.001 | Active |
| 6 | Firewall Deny Spike | OPNsense block events | High | T1046 | Active |
| 7 | New Service Installed | Event ID 7045 | High | T1543.003 | Active |
| 8 | Privilege Escalation: Special Logon | Event ID 4672 | High | T1068 | Verified firing |
| 9 | DNS Tunneling Indicator | DNS TXT activity | High | T1071.004 | Active |
| 10 | File Integrity Alert: `/etc/passwd` | Auditbeat FIM | High | T1565.001 | Active |

Rule logic is being organized under [`rules/kql/`](rules/kql/) with Sigma versions planned under [`rules/sigma/`](rules/sigma/).

---

## Dashboards Built

| Dashboard | Purpose |
|---|---|
| Security Overview | High-level view of notable security events and alert activity |
| Authentication Activity | Windows and Linux authentication trends, failed logons, and account activity |
| Network Traffic | OPNsense firewall activity, denied traffic, and network visibility |

---

## Evidence

The repository includes screenshot evidence showing the lab build and validation process, including:

- ELK services running
- Elasticsearch and Kibana access confirmed
- Windows endpoint configuration
- Linux endpoint telemetry
- OPNsense syslog ingestion
- Winlogbeat, Filebeat, and Auditbeat indices
- Sysmon events in Kibana
- Custom Kibana detection rules
- Alerts firing
- Final dashboards

A full evidence index is available here: [`evidence/EVIDENCE_INDEX.md`](evidence/EVIDENCE_INDEX.md)

---

## Key Lessons Learned

### 1. Beat agents should point to Logstash when pipeline control matters

I initially had Winlogbeat sending directly to Elasticsearch on port 9200. That works for simple ingestion, but it bypasses the Logstash pipeline. Moving Beats traffic to Logstash on port 5044 gave me a better place to tag, route, and standardize events before indexing.

### 2. Small Elasticsearch config mistakes can break cluster startup

A duplicated `cluster.initial_master_nodes` entry caused Elasticsearch to start incorrectly. The fix was straightforward, but the lesson was important: verify configuration files carefully before assuming a service problem is caused by the application itself.

### 3. Windows does not log everything by default

Failed logon detection depends on Windows actually generating Event ID 4625. Winlogbeat was working, but the event was not appearing until Advanced Audit Policy was configured correctly.

### 4. Kibana detection rules depend on the right data views

The Security app will not find events if the rules are pointed at the wrong index pattern. Creating and validating the correct `winlogbeat-*`, `filebeat-*`, and `auditbeat-*` data views was required before the rules could return results.

### 5. Sysmon setup order matters

The Sysmon event channel needs to exist before Winlogbeat is configured to collect from it. Installing Sysmon first, then updating the Winlogbeat configuration, avoided silent collection issues.

### 6. Firewall logs are much easier to work with when the source is consistent

OPNsense syslog used the expected facility, which made it easier to isolate firewall events in Kibana and build targeted searches for denied traffic.

---

## What I Would Improve for Production

This lab was built to learn and validate SOC workflows, not to represent a hardened production deployment. In a production environment, I would make the following changes:

1. **Use API keys or a dedicated least-privilege service account for Logstash.**  
   The lab uses a redacted credential in the Logstash output configuration. A production deployment should avoid broad credentials and use tightly scoped access.

2. **Enable full TLS certificate validation.**  
   Certificate verification was relaxed during the lab build to move quickly. Production traffic between Logstash and Elasticsearch should validate the certificate chain.

3. **Implement index lifecycle management from the beginning.**  
   A lab with 29,000 events is manageable. A real environment needs rollover, retention, and storage planning before event volume grows.

4. **Export detection rules and dashboards as version-controlled artifacts.**  
   Screenshots prove the work was completed, but exported Kibana objects make the project easier to reproduce and review.

5. **Add automated validation scripts.**  
   Simple checks for service health, listening ports, index growth, and recent events would make the lab easier to maintain and rebuild.

---

## Repository Status

This project is actively being documented and cleaned up for portfolio use. The lab itself is built and producing data; the remaining work is focused on making the repository easier to review, reproduce, and evaluate.

---

Built by **John Medina**  
GitHub: [m549n1ja](https://github.com/m549n1ja)
