# Evidence Index — homelab-elk-soc

This index maps every screenshot to the phase and claim it supports.
All screenshots are in `evidence/screenshots/`.

---

## Primary Evidence — Phase Mapped

| Screenshot | Phase | What It Proves | Related Rule |
|------------|-------|----------------|--------------|
| [20260427_elk-siem_static-ip-confirmed.png](screenshots/20260427_elk-siem_static-ip-confirmed.png) | Phase 1 — ELK-SIEM Setup | Static IP 192.168.10.100 set on ens33 | — |
| [20260427_elk-siem_elasticsearch-running.png](screenshots/20260427_elk-siem_elasticsearch-running.png) | Phase 2 — Elasticsearch | Elasticsearch active (running) | — |
| [20260427_elk-siem_all-services-running.png](screenshots/20260427_elk-siem_all-services-running.png) | Phase 3 — Full ELK Stack | All 3 ELK services confirmed running simultaneously | — |
| [20260427_elk-siem_kibana-home.png](screenshots/20260427_elk-siem_kibana-home.png) | Phase 3 — Full ELK Stack | Kibana accessible at 192.168.10.100:5601 | — |
| [20260427_win10-endpoint_vm-settings.png](screenshots/20260427_win10-endpoint_vm-settings.png) | Phase 4 — Beat Agents | WIN10 VM hardware settings confirmed | — |
| [20260427_win10-endpoint_ipconfig.png](screenshots/20260427_win10-endpoint_ipconfig.png) | Phase 4 — Beat Agents | WIN10 on 192.168.10.197, gateway 192.168.10.1 | — |
| [20260428_elk-siem_winlogbeat-indices.png](screenshots/20260428_elk-siem_winlogbeat-indices.png) | Phase 4 — Beat Agents | Winlogbeat indices with 4,500+ events | — |
| [20260428_elk-siem_sysmon-events-confirmed.png](screenshots/20260428_elk-siem_sysmon-events-confirmed.png) | Phase 4 — Beat Agents | 192 Sysmon events indexed in ELK | — |
| [20260428_linux-endpoint_filebeat-auditbeat-running.png](screenshots/20260428_linux-endpoint_filebeat-auditbeat-running.png) | Phase 4 — Beat Agents | Filebeat and Auditbeat both active (running) on LINUX-ENDPOINT | Rule 10 |
| [20260428_linux-endpoint_opnsense-syslog-received.png](screenshots/20260428_linux-endpoint_opnsense-syslog-received.png) | Phase 4 — Beat Agents | OPNsense packets arriving on LINUX-ENDPOINT UDP 514 | Rule 06 |
| [20260428_elk-siem_all-indices-flowing.png](screenshots/20260428_elk-siem_all-indices-flowing.png) | Phase 4 — Beat Agents | All indices present with 29,000+ total events | — |
| [20260428_kibana_rule1-brute-force-created.png](screenshots/20260428_kibana_rule1-brute-force-created.png) | Phase 5 — Detection Rules | Rule 01: Brute Force detection rule created in Kibana Security | Rule 01 |
| [20260429_kibana_alerts-firing.png](screenshots/20260429_kibana_alerts-firing.png) | Phase 5 — Detection Rules | 21 alerts firing — Rules 01 and 08 verified | Rules 01, 08 |
| [20260429_kibana_security-overview-dashboard.png](screenshots/20260429_kibana_security-overview-dashboard.png) | Phase 6 — Dashboards | Security Overview Dashboard live in Kibana | — |
| [20260429_kibana_authentication-dashboard.png](screenshots/20260429_kibana_authentication-dashboard.png) | Phase 6 — Dashboards | Authentication Activity Dashboard live in Kibana | — |
| [20260429_kibana_network-traffic-dashboard.png](screenshots/20260429_kibana_network-traffic-dashboard.png) | Phase 6 — Dashboards | Network Traffic Dashboard live in Kibana | — |

---

## Supporting Evidence — Detection Rules

| Screenshot | What It Shows | Related Rule |
|------------|---------------|--------------|
| [20260428_kibana_rule2-new-user-created.png](screenshots/20260428_kibana_rule2-new-user-created.png) | Rule 02: New User Account Created — rule created | Rule 02 |
| [20260428_kibana_rule3-powershell-execution.png](screenshots/20260428_kibana_rule3-powershell-execution.png) | Rule 03: Suspicious PowerShell Execution — rule created | Rule 03 |
| [20260428_kibana_rule4-scheduled-task.png](screenshots/20260428_kibana_rule4-scheduled-task.png) | Rule 04: New Scheduled Task — rule created | Rule 04 |
| [20260428_kibana_rule5-rdp-external.png](screenshots/20260428_kibana_rule5-rdp-external.png) | Rule 05: RDP Login from External IP — rule created | Rule 05 |
| [20260428_kibana_rule6-firewall-deny.png](screenshots/20260428_kibana_rule6-firewall-deny.png) | Rule 06: Firewall Deny Spike — rule created | Rule 06 |
| [20260428_kibana_rule7-new-service.png](screenshots/20260428_kibana_rule7-new-service.png) | Rule 07: New Service Installed — rule created | Rule 07 |
| [20260428_kibana_rule8-privilege-escalation.png](screenshots/20260428_kibana_rule8-privilege-escalation.png) | Rule 08: Privilege Escalation Special Logon — rule created | Rule 08 |
| [20260428_kibana_rule9-dns-tunneling.png](screenshots/20260428_kibana_rule9-dns-tunneling.png) | Rule 09: DNS Tunneling Indicator — rule created | Rule 09 |
| [20260428_kibana_rule10-file-integrity.png](screenshots/20260428_kibana_rule10-file-integrity.png) | Rule 10: File Integrity Alert /etc/passwd — rule created | Rule 10 |

---

## Supporting Evidence — Infrastructure

| Screenshot | What It Shows |
|------------|---------------|
| [20260427_elk-siem_vm-hardware-settings.png](screenshots/20260427_elk-siem_vm-hardware-settings.png) | ELK-SIEM VM hardware config (vCPU, RAM, disk) |
| [20260427_elk-siem_ip-a-output.png](screenshots/20260427_elk-siem_ip-a-output.png) | Interface names and initial IP state on ELK-SIEM |
| [20260427_elk-siem_ubuntu-profile-setup.png](screenshots/20260427_elk-siem_ubuntu-profile-setup.png) | Ubuntu Server 24.04 install completed |
| [20260427_elk-siem_logstash-running.png](screenshots/20260427_elk-siem_logstash-running.png) | Logstash active (running) |
| [20260427_elk-siem_kibana-running.png](screenshots/20260427_elk-siem_kibana-running.png) | Kibana active (running) |
| [20260427_elk-siem_snapshot-phase1.png](screenshots/20260427_elk-siem_snapshot-phase1.png) | VMware snapshot taken at Phase 1 completion |
| [20260428_elk-siem_filebeat-index-confirmed.png](screenshots/20260428_elk-siem_filebeat-index-confirmed.png) | Filebeat index confirmed in Elasticsearch |
| [20260428_elk-siem_opnsense-syslog-flowing.png](screenshots/20260428_elk-siem_opnsense-syslog-flowing.png) | OPNsense syslog events visible in ELK |
| [20260428_elk-siem_all-indices-confirmed.png](screenshots/20260428_elk-siem_all-indices-confirmed.png) | All expected indices present in Kibana |
| [20260429_kibana_dashboard1-panel1-severity-pie.png](screenshots/20260429_kibana_dashboard1-panel1-severity-pie.png) | Security Overview — severity breakdown panel |

---

*Total screenshots: 35 | Phases covered: 1 through 6*  
*Project: homelab-elk-soc | Author: John Medina*
