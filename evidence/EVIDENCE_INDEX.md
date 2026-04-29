# Evidence Index — homelab-elk-soc

This index maps every screenshot to the phase and claim it supports.
All screenshots are in `evidence/screenshots/`.

| Screenshot | Phase | What It Proves |
|------------|-------|----------------|
| 20260427_elk-siem_static-ip-confirmed.png | Phase 1 — ELK-SIEM Setup | Static IP 192.168.10.100 set on ens33 |
| 20260427_elk-siem_elasticsearch-running.png | Phase 2 — Elasticsearch | Elasticsearch active (running) |
| 20260427_elk-siem_all-services-running.png | Phase 3 — Full ELK Stack | All 3 ELK services confirmed running |
| 20260427_elk-siem_kibana-home.png | Phase 3 — Full ELK Stack | Kibana accessible at 192.168.10.100:5601 |
| 20260427_win10-endpoint_vm-settings.png | Phase 4 — Beat Agents | WIN10 VM hardware settings confirmed |
| 20260427_win10-endpoint_ipconfig.png | Phase 4 — Beat Agents | WIN10 on 192.168.10.197, gateway 192.168.10.1 |
| 20260428_elk-siem_winlogbeat-indices.png | Phase 4 — Beat Agents | Winlogbeat indices with 4,500+ events |
| 20260428_elk-siem_sysmon-events-confirmed.png | Phase 4 — Beat Agents | 192 Sysmon events in ELK |
| 20260428_linux-endpoint_filebeat-auditbeat-running.png | Phase 4 — Beat Agents | Filebeat and Auditbeat active (running) |
| 20260428_linux-endpoint_opnsense-syslog-received.png | Phase 4 — Beat Agents | OPNsense packets arriving on port 514 |
| 20260428_elk-siem_all-indices-flowing.png | Phase 4 — Beat Agents | All indices with 29,000+ total events |
| 20260429_kibana_alerts-firing.png | Phase 5 — Detection Rules | 21 alerts firing across 2 rules |
| 20260428_kibana_rule1-brute-force-created.png | Phase 5 — Detection Rules | Rule 1 brute force detection created |
| 20260429_kibana_security-overview-dashboard.png | Phase 6 — Dashboards | Security Overview Dashboard live |
| 20260429_kibana_authentication-dashboard.png | Phase 6 — Dashboards | Authentication Activity Dashboard live |
| 20260429_kibana_network-traffic-dashboard.png | Phase 6 — Dashboards | Network Traffic Dashboard live |

---

## Additional Screenshots (Supporting Evidence)

| Screenshot | What It Shows |
|------------|---------------|
| 20260427_elk-siem_vm-hardware-settings.png | ELK-SIEM VM hardware config (vCPU, RAM, disk) |
| 20260427_elk-siem_ip-a-output.png | Interface names and initial IP state on ELK-SIEM |
| 20260427_elk-siem_ubuntu-profile-setup.png | Ubuntu 24.04 Server install completed |
| 20260427_elk-siem_logstash-running.png | Logstash active (running) |
| 20260427_elk-siem_kibana-running.png | Kibana active (running) |
| 20260427_elk-siem_snapshot-phase1.png | VMware snapshot taken at Phase 1 completion |
| 20260428_elk-siem_filebeat-index-confirmed.png | Filebeat index confirmed in Elasticsearch |
| 20260428_elk-siem_opnsense-syslog-flowing.png | OPNsense syslog events appearing in ELK |
| 20260428_elk-siem_all-indices-confirmed.png | All expected indices present in Kibana |
| 20260428_kibana_rule2-new-user-created.png | Rule 2: New User Account Created |
| 20260428_kibana_rule3-powershell-execution.png | Rule 3: Suspicious PowerShell Execution |
| 20260428_kibana_rule4-scheduled-task.png | Rule 4: New Scheduled Task |
| 20260428_kibana_rule5-rdp-external.png | Rule 5: RDP Login from External IP |
| 20260428_kibana_rule6-firewall-deny.png | Rule 6: Firewall Deny Spike |
| 20260428_kibana_rule7-new-service.png | Rule 7: New Service Installed |
| 20260428_kibana_rule8-privilege-escalation.png | Rule 8: Privilege Escalation (Special Logon) |
| 20260428_kibana_rule9-dns-tunneling.png | Rule 9: DNS Tunneling Indicator |
| 20260428_kibana_rule10-file-integrity.png | Rule 10: File Integrity Alert — /etc/passwd |
| 20260429_kibana_dashboard1-panel1-severity-pie.png | Security Overview — severity breakdown panel |

---

*Total screenshots: 35 | All phases covered: Phase 1 through Phase 6*
*Project: homelab-elk-soc | Author: John Medina*
