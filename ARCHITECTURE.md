# Architecture — homelab-elk-soc

## Overview

The lab is designed around a single-node ELK stack acting as a centralized SIEM, receiving logs from two endpoint VMs and a physical firewall — all running on a single Ryzen 9 host via VMware Workstation. The goal was to mirror an enterprise SOC data flow at lab scale: endpoints ship logs via Beat agents to a Logstash ingestion layer, Logstash normalizes and tags the data, Elasticsearch stores and indexes it, and Kibana provides detection, alerting, and visualization. Every component is on an isolated 192.168.10.0/24 LAN segment behind an OPNsense firewall, which also serves as a log source itself via syslog.

---

## Network Topology

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────┐
│  OPNsense Firewall — 192.168.10.1               │
│  Chromebox CN60 (physical hardware)             │
│  WAN: ISP-assigned  LAN: 192.168.10.1/24        │
│  Syslog out: UDP 514 → 192.168.10.155           │
└───────────────────────┬─────────────────────────┘
                        │ Lab LAN: 192.168.10.0/24
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
│ WIN10-       │ │ LINUX-       │ │ ELK-SIEM         │
│ ENDPOINT     │ │ ENDPOINT     │ │ 192.168.10.100   │
│ 192.168.10.  │ │ 192.168.10.  │ │ Ubuntu 24.04 Svr │
│ 197 (DHCP)   │ │ 155 (static) │ │                  │
│              │ │              │ │ Elasticsearch    │
│ Winlogbeat   │ │ Filebeat     │ │   port 9200 HTTPS│
│ Sysmon64     │ │ Auditbeat    │ │ Logstash         │
│              │ │              │ │   port 5044 Beats│
└──────┬───────┘ └──────┬───────┘ │ Kibana           │
       │                │         │   port 5601 HTTP │
       └────────────────┘         └──────────────────┘
            Beats → Logstash:5044

┌─────────────────────────────────────────────────┐
│  Ryzen 9 Host — 192.168.10.10                   │
│  VMware Workstation | 64GB RAM                  │
│  Hosts: ELK-SIEM, WIN10-ENDPOINT, LINUX-ENDPOINT│
└─────────────────────────────────────────────────┘
```

---

## VM Specifications

| VM | OS | vCPU | RAM | Disk | IP | Role |
|----|----|----|-----|------|----|------|
| ELK-SIEM | Ubuntu 24.04 Server | 4 | 16GB | 100GB | 192.168.10.100 (static) | SIEM — Elasticsearch, Logstash, Kibana |
| WIN10-ENDPOINT | Windows 10 Pro | 2 | 4GB | 60GB | 192.168.10.197 (DHCP) | Windows log source — Winlogbeat, Sysmon64 |
| LINUX-ENDPOINT | Ubuntu 24.04 Desktop | 2 | 4GB | 40GB | 192.168.10.155 (static) | Linux log source — Filebeat, Auditbeat, syslog relay |
| OPNsense | OPNsense 26.1 | — | — | — | 192.168.10.1 (physical) | Perimeter firewall, syslog source |

---

## ELK Stack Configuration

| Service | Port | Protocol | Config File | Notes |
|---------|------|----------|-------------|-------|
| Elasticsearch | 9200 | HTTPS | `/etc/elasticsearch/elasticsearch.yml` | Single-node cluster; `cluster.initial_master_nodes` set once |
| Logstash | 5044 | TCP (Beats) | `/etc/logstash/conf.d/beats.conf` | Beats input → tag filter → ES output |
| Kibana | 5601 | HTTP | `/etc/kibana/kibana.yml` | `server.host: 0.0.0.0` to allow LAN access |

**JVM heap:** 4GB set at `/etc/elasticsearch/jvm.options.d/heap.options`

---

## Log Pipeline

```
Endpoint agent collects logs locally
    │
    ▼
Beat agent (Winlogbeat / Filebeat / Auditbeat)
    │  TCP port 5044 (Beats protocol, encrypted)
    ▼
Logstash — beats.conf pipeline
    │  Input: beats { port => 5044 }
    │  Filter: mutate — adds source tags (windows/linux/winlogbeat/filebeat/auditbeat)
    │  Output: elasticsearch { hosts => ["https://localhost:9200"] }
    ▼
Elasticsearch — stores and indexes by beat type
    │  Indices: winlogbeat-*, filebeat-*, auditbeat-*
    ▼
Kibana — data views, detection rules, dashboards, alerts
```

---

## Data Flow Diagram

**Windows endpoint:**
```
WIN10-ENDPOINT (192.168.10.197)
    Sysmon64 → Windows Event Log (Microsoft-Windows-Sysmon/Operational)
    Windows Security Log (4624, 4625, 4720, 4698, 4672, 7045, 4104)
        │
        ▼ Winlogbeat 8.19.13
        │ TCP 5044
        ▼
    Logstash → tagged: [windows, winlogbeat]
        │
        ▼
    Elasticsearch → index: winlogbeat-8.x-YYYY.MM.dd
        │
        ▼
    Kibana → winlogbeat-* data view → detection rules → alerts
```

**Linux endpoint:**
```
LINUX-ENDPOINT (192.168.10.155)
    /var/log/syslog, /var/log/auth.log, /var/log/kern.log
        │
        ▼ Filebeat 8.x (system module)
        │ TCP 5044
        ▼
    Logstash → tagged: [linux, filebeat]
        │
        ▼
    Elasticsearch → index: filebeat-8.x-YYYY.MM.dd
        │
        ▼
    Kibana → filebeat-* data view

    /etc/passwd, /etc/shadow, /etc/sudoers (file integrity)
        │
        ▼ Auditbeat 8.x (file_integrity module)
        │ TCP 5044
        ▼
    Logstash → tagged: [linux, auditbeat]
        │
        ▼
    Elasticsearch → index: auditbeat-8.x-YYYY.MM.dd
```

**OPNsense firewall:**
```
OPNsense (192.168.10.1)
    Firewall block/pass events (filterlog — facility local0)
        │
        ▼ Syslog UDP 514
        ▼
    LINUX-ENDPOINT (192.168.10.155) — listening on UDP 514
        │
        ▼ Filebeat 8.x (syslog input)
        │ TCP 5044
        ▼
    Logstash → tagged: [opnsense, firewall]
        │
        ▼
    Elasticsearch → index: filebeat-8.x-YYYY.MM.dd
        │
        ▼
    Kibana → firewall deny spike detection (T1046)
```

---

## Design Decisions

**1. Single-node Elasticsearch cluster.**
In production, Elasticsearch runs as a multi-node cluster for redundancy and performance. For this lab, a single node is intentional — it simplifies setup, reduces resource overhead on the Ryzen 9 host, and the tradeoff (no high availability) is acceptable in a lab environment where the goal is detection practice, not uptime SLAs.

**2. Bridged networking for all VMs.**
All VMs use VMware bridged networking (not NAT) so they appear as first-class devices on the 192.168.10.0/24 LAN. This means OPNsense enforces firewall rules for all VM traffic just like physical hosts. NAT would bypass the firewall entirely and defeat the purpose of having a perimeter device as a log source.

**3. Logstash as the ingestion layer instead of direct Elasticsearch output.**
Beat agents could ship directly to Elasticsearch, but routing everything through Logstash gives a single place to add tags, normalize field names, and apply conditional logic without touching every agent config individually. When a new log source gets added, the pipeline logic stays in one file.

**4. LINUX-ENDPOINT as the OPNsense syslog relay.**
OPNsense sends syslog over UDP 514 to the LINUX-ENDPOINT, which Filebeat picks up and forwards to Logstash. An alternative would be a dedicated syslog collector (rsyslog → Logstash), but using Filebeat keeps the architecture consistent — every log source uses a Beat agent as its forwarding mechanism.

---

## Production Considerations

| Lab Setup | Production Change | Reason |
|-----------|------------------|--------|
| Single-node Elasticsearch | 3-node cluster minimum | Redundancy, shard distribution, no single point of failure |
| `ssl_verification_mode: none` in Logstash | Full CA validation | Prevents man-in-the-middle on the log pipeline |
| Username/password in beats.conf | Elasticsearch API key | Scoped permissions, independent rotation, no shared credentials |
| No index lifecycle management | ILM hot/warm/cold tiers | Index rollover and retention policy required at enterprise data volumes |
| Manual data view creation | Automated via Kibana API or Terraform | Repeatable, version-controlled configuration |

---

*Project: homelab-elk-soc | Author: John Medina | github.com/m549n1ja*
