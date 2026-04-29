# Deployment Guide — homelab-elk-soc

This guide documents how the lab was built and how to reproduce it. It is written from the actual build experience, including the order of operations that matters and the mistakes that were made along the way.

This is a single-node ELK 8.x lab. It is not a production blueprint. If you are deploying ELK in production, treat this as a starting point and review Elastic's official hardening guidance before going live.

---

## Prerequisites

### Host Hardware

| Component | Lab Spec | Minimum Recommended |
|-----------|----------|---------------------|
| CPU | AMD Ryzen 9 (8+ cores) | 8 cores |
| RAM | 64 GB | 32 GB |
| Storage | SSD (recommend 500 GB+) | 250 GB SSD |
| Hypervisor | VMware Workstation | VMware Workstation or VirtualBox |

> The ELK-SIEM VM alone needs 16 GB RAM and 4 vCPUs for stable operation. Running three VMs simultaneously (ELK-SIEM, WIN10, LINUX) requires the host RAM above.

### Network

- All VMs use **bridged networking** — they appear as first-class devices on the LAN
- Lab subnet: `192.168.10.0/24`
- Gateway / firewall: OPNsense at `192.168.10.1`
- Bridged networking is intentional — NAT would bypass OPNsense and defeat its value as a log source

### Software

- VMware Workstation (host)
- Ubuntu Server 24.04 ISO (ELK-SIEM)
- Ubuntu Desktop 24.04 ISO (LINUX-ENDPOINT)
- Windows 10 Pro ISO (WIN10-ENDPOINT)
- OPNsense 26.1 image (physical Chromebox CN60)

---

## VM Inventory

| VM | OS | vCPU | RAM | Disk | IP | Role |
|----|----|----|-----|------|----|------|
| ELK-SIEM | Ubuntu Server 24.04 | 4 | 16 GB | 100 GB | 192.168.10.100 (static) | Elasticsearch, Logstash, Kibana |
| WIN10-ENDPOINT | Windows 10 Pro | 2 | 4 GB | 60 GB | 192.168.10.197 (DHCP) | Winlogbeat, Sysmon64 |
| LINUX-ENDPOINT | Ubuntu Desktop 24.04 | 2 | 4 GB | 40 GB | 192.168.10.155 (static) | Filebeat, Auditbeat, syslog relay |

---

## Phase 1 — ELK-SIEM: Ubuntu Server Setup

### 1.1 Install Ubuntu Server 24.04

1. Create a new VM in VMware with the specs above
2. Boot from the Ubuntu Server 24.04 ISO
3. During installation, set a static IP:
   - Address: `192.168.10.100`
   - Netmask: `255.255.255.0`
   - Gateway: `192.168.10.1`
   - DNS: `192.168.10.1` (or your preferred resolver)
4. Create user: `medina_ja`
5. Enable OpenSSH during install for remote management

### 1.2 Post-Install Verification

```bash
# Confirm IP is set correctly
ip a show ens33

# Confirm internet connectivity
ping -c 4 8.8.8.8

# Update the system before installing ELK
sudo apt update && sudo apt upgrade -y
```

### 1.3 Configure Static IP (if not set during install)

Edit `/etc/netplan/00-installer-config.yaml`:

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.10.100/24
      routes:
        - to: default
          via: 192.168.10.1
      nameservers:
        addresses:
          - 192.168.10.1
```

Apply:
```bash
sudo netplan apply
ip a show ens33  # Confirm 192.168.10.100 is active
```

---

## Phase 2 — Elasticsearch Installation

### 2.1 Add Elastic Repository

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt update
```

### 2.2 Install Elasticsearch

```bash
sudo apt install elasticsearch -y
```

**Important:** During installation, Elasticsearch prints a one-time auto-generated password for the `elastic` user. **Copy this password immediately** — you will not see it again. Store it in your password manager (Notion Credentials Vault in this lab).

### 2.3 Configure Elasticsearch

Edit `/etc/elasticsearch/elasticsearch.yml`:

```yaml
cluster.name: homelab-soc
node.name: elk-siem

# Bind to the local interface only (single node lab)
network.host: 0.0.0.0
http.port: 9200

# Single-node cluster — only one occurrence of this setting is allowed
# Having it on two lines will prevent Elasticsearch from forming the cluster
cluster.initial_master_nodes: ["elk-siem"]

# Discovery settings for single-node
discovery.seed_hosts: []
```

> **Critical lesson:** `cluster.initial_master_nodes` appeared on two lines in the default config (lines 74 and 109). Both must be present with the correct value, or one must be commented out. Having duplicate entries caused the cluster to fail to start silently.

### 2.4 Configure JVM Heap

Create `/etc/elasticsearch/jvm.options.d/heap.options`:

```
-Xms4g
-Xmx4g
```

Set heap to 50% of available RAM (8 GB of 16 GB in this lab). Never exceed 32 GB or half of available RAM.

### 2.5 Enable and Start Elasticsearch

```bash
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Verify it is running
sudo systemctl status elasticsearch

# Test connectivity (use the password saved from installation)
curl -k -u elastic:[YOUR_PASSWORD_HERE] https://localhost:9200
```

Expected response: a JSON object with cluster name `homelab-soc` and status `green` or `yellow`.

---

## Phase 3 — Kibana Installation

### 3.1 Install Kibana

```bash
sudo apt install kibana -y
```

### 3.2 Configure Kibana

Edit `/etc/kibana/kibana.yml`:

```yaml
server.port: 5601

# Must be set to 0.0.0.0 to allow access from other hosts on the LAN.
# Default is localhost — if left commented out, Kibana is only accessible from the ELK-SIEM itself.
server.host: "0.0.0.0"

server.name: "elk-siem"
```

### 3.3 Generate Kibana Enrollment Token

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
```

Copy the token for use in the Kibana setup wizard.

### 3.4 Enable and Start Kibana

```bash
sudo systemctl enable kibana
sudo systemctl start kibana
sudo systemctl status kibana
```

### 3.5 Complete Kibana Setup

1. Open a browser and navigate to `http://192.168.10.100:5601`
2. Paste the enrollment token when prompted
3. Retrieve the Kibana verification code:
   ```bash
   sudo /usr/share/kibana/bin/kibana-verification-code
   ```
4. Complete setup and log in with `elastic` / [YOUR_PASSWORD_HERE]

---

## Phase 3 (continued) — Logstash Installation

### 3.6 Install Logstash

```bash
sudo apt install logstash -y
```

### 3.7 Configure Logstash Pipeline

Create `/etc/logstash/conf.d/beats.conf`. See `configs/logstash/beats.conf` in this repository for the full annotated pipeline.

Key points:
- Beats input listens on port 5044
- Filter block tags events by Beat agent type
- Output sends to Elasticsearch using `${ES_USER}` and `${ES_PASSWORD}` environment variables

Set credentials in the Logstash service environment:

```bash
sudo systemctl edit logstash
```

Add in the override file:
```ini
[Service]
Environment="ES_USER=elastic"
Environment="ES_PASSWORD=[YOUR_PASSWORD_HERE]"
```

### 3.8 Enable and Start Logstash

```bash
sudo systemctl enable logstash
sudo systemctl start logstash
sudo systemctl status logstash

# Logstash takes 60-90 seconds to fully initialize — check the log if it doesn't start immediately
sudo journalctl -u logstash -f
```

### 3.9 Verify All Three Services

```bash
sudo systemctl status elasticsearch kibana logstash
```

All three should show `active (running)`.

---

## Phase 4 — Windows Endpoint: WIN10-ENDPOINT

### 4.1 Install Windows 10 Pro

1. Create VM with specs listed in the VM inventory
2. Install Windows 10 Pro
3. Install VMware Tools — required for copy-paste between host and VM

### 4.2 Configure Network

The WIN10-ENDPOINT uses DHCP and receives 192.168.10.197 from OPNsense. No static IP configuration needed.

Verify network:
```
ipconfig
```
Expected: IPv4 Address `192.168.10.197`, Default Gateway `192.168.10.1`

### 4.3 Enable Windows Audit Policy

Event 4625 (failed logon) is **not logged by default**. Enable it before installing any Beat agents:

1. Open `secpol.msc`
2. Navigate to: `Security Settings → Advanced Audit Policy Configuration → System Audit Policies → Logon/Logoff`
3. Enable **Audit Logon** → check both **Success** and **Failure**
4. Apply and close

### 4.4 Install Sysmon (BEFORE Winlogbeat)

**Order matters:** Install Sysmon before adding the Sysmon channel to winlogbeat.yml. Winlogbeat will fail silently if it tries to subscribe to a channel that doesn't exist.

1. Download Sysmon64 from [Microsoft Sysinternals](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon)
2. Download SwiftOnSecurity Sysmon config from [GitHub](https://github.com/SwiftOnSecurity/sysmon-config)
3. Install:
   ```
   C:\Tools\Sysmon\Sysmon64.exe -accepteula -i C:\Tools\Sysmon\sysmonconfig.xml
   ```
4. Verify:
   ```
   sc query Sysmon64
   ```
   Expected: `STATE: 4 RUNNING`

### 4.5 Install Winlogbeat

1. Download Winlogbeat 8.19.13 from elastic.co
2. Extract to `C:\Tools\Winlogbeat\`
3. Edit `winlogbeat.yml`:

```yaml
winlogbeat.event_logs:
  - name: Security
    ignore_older: 72h
  - name: System
  - name: Microsoft-Windows-Sysmon/Operational

output.logstash:
  hosts: ["192.168.10.100:5044"]

# Do NOT use output.elasticsearch directly
# Route through Logstash to preserve pipeline tagging
```

4. Install and start the service:
   ```
   cd C:\Tools\Winlogbeat\winlogbeat-8.19.13-windows-x86_64\
   .\install-service-winlogbeat.ps1
   Start-Service winlogbeat
   Get-Service winlogbeat
   ```

### 4.6 Enable PowerShell Script Block Logging

Required for Event 4104 (Rule 03):

1. Open `gpedit.msc`
2. Navigate to: `Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell`
3. Enable: **Turn on PowerShell Script Block Logging**
4. Restart the WinRM service or reboot

### 4.7 Verify Winlogbeat is Shipping

On ELK-SIEM, after 2-3 minutes:

```bash
curl -k -u elastic:[YOUR_PASSWORD_HERE] "https://localhost:9200/winlogbeat-*/_count"
```

Expected: count greater than 0 and growing.

---

## Phase 4 (continued) — Linux Endpoint: LINUX-ENDPOINT

### 4.8 Install Ubuntu Desktop 24.04

1. Create VM with specs from the VM inventory
2. Boot from Ubuntu Desktop 24.04 ISO and install
3. Install VMware Tools via `sudo apt install open-vm-tools-desktop`

### 4.9 Set Static IP

Edit `/etc/netplan/01-network-manager-all.yaml` or create a new netplan config:

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.10.155/24
      routes:
        - to: default
          via: 192.168.10.1
      nameservers:
        addresses:
          - 192.168.10.1
```

```bash
sudo netplan apply
ip a show ens33  # Confirm 192.168.10.155
```

### 4.10 Install Filebeat

```bash
# Add Elastic repo (same as ELK-SIEM steps)
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt update
sudo apt install filebeat -y
```

Enable the system module:
```bash
sudo filebeat modules enable system
```

Edit `/etc/filebeat/filebeat.yml` — set the output to Logstash (not Elasticsearch):

```yaml
output.logstash:
  hosts: ["192.168.10.100:5044"]

# Comment out or remove any output.elasticsearch block
```

Configure syslog input for OPNsense (see Phase 4.12 below).

```bash
sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl status filebeat
```

### 4.11 Install Auditbeat

```bash
sudo apt install auditbeat -y
```

Edit `/etc/auditbeat/auditbeat.yml` — configure file integrity monitoring:

```yaml
- module: file_integrity
  paths:
    - /etc/passwd
    - /etc/shadow
    - /etc/sudoers
    - /etc/sudoers.d
    - /etc/ssh/sshd_config

output.logstash:
  hosts: ["192.168.10.100:5044"]
```

```bash
sudo systemctl enable auditbeat
sudo systemctl start auditbeat
sudo systemctl status auditbeat
```

### 4.12 Configure OPNsense Syslog Relay

OPNsense sends syslog to LINUX-ENDPOINT (192.168.10.155) on UDP port 514.

**On OPNsense (192.168.10.1):**

1. Navigate to: `System → Settings → Logging / Targets`
2. Add a new remote logging target:
   - IP: `192.168.10.155`
   - Port: `514`
   - Protocol: UDP
   - Facility: `local0`
   - Level: `informational`

**On LINUX-ENDPOINT — configure Filebeat syslog input:**

Add to `/etc/filebeat/filebeat.yml` under the `filebeat.inputs` section:

```yaml
filebeat.inputs:
  - type: syslog
    protocol.udp:
      host: "0.0.0.0:514"
    enabled: true
```

> Filebeat must bind to UDP 514 before OPNsense will successfully deliver events. Verify with: `sudo ss -ulnp | grep 514`

Restart Filebeat after config changes:
```bash
sudo systemctl restart filebeat
```

**Verify OPNsense syslog is arriving:**
```bash
# Watch for incoming packets on UDP 514
sudo tcpdump -i ens33 udp port 514
```

---

## Phase 5 — Kibana: Data Views and Detection Rules

### 5.1 Create Data Views

Before creating detection rules, the correct data views must exist in Kibana.

1. Open Kibana at `http://192.168.10.100:5601`
2. Navigate to: `Stack Management → Data Views`
3. Create three data views:
   - Name: `winlogbeat-*` | Index pattern: `winlogbeat-*` | Time field: `@timestamp`
   - Name: `filebeat-*` | Index pattern: `filebeat-*` | Time field: `@timestamp`
   - Name: `auditbeat-*` | Index pattern: `auditbeat-*` | Time field: `@timestamp`

> The Kibana Security detection engine uses the **Default** security data view. Confirm the Default data view includes `logs-*`, `winlogbeat-*`, `filebeat-*`, and `auditbeat-*`.  
> Navigate to: `Security → Manage → Rules → Detection rules → Update settings` to configure index patterns.

### 5.2 Create Detection Rules

For each rule, navigate to: `Security → Rules → Detection rules → Create new rule`

Use **Custom query** rule type for most rules. Use **Threshold** rule type for Rules 01 and 06 (brute force and firewall spike).

Refer to `rules/kql/` for the full KQL query, threshold settings, and MITRE mapping for each rule.

General rule creation steps:
1. Select rule type (Custom query or Threshold)
2. Enter KQL query from the corresponding rule doc
3. Set index pattern (winlogbeat-*, filebeat-*, or auditbeat-*)
4. Set severity and risk score
5. Set schedule (recommend: every 5 minutes, look-back 10 minutes)
6. Add MITRE ATT&CK tactic and technique
7. Save and enable

### 5.3 Verify Rules Are Running

After enabling all 10 rules:

```
Security → Rules → Detection rules
```

All rules should show status `Active`. Rules with matching events will show alert counts within one rule cycle (5 minutes).

---

## Phase 6 — Kibana Dashboards

### 6.1 Create Dashboards

Three dashboards were created manually in Kibana:

**Dashboard 1: Security Overview**
- Suggested panels: alert count by severity, top alert rule names, events over time, top source IPs

**Dashboard 2: Authentication Activity**
- Suggested panels: 4625 failed logons over time, 4624 successful logons, top target usernames, logon type breakdown

**Dashboard 3: Network Traffic**
- Suggested panels: OPNsense block events over time, top blocked source IPs, top destination ports blocked, firewall allow vs. deny ratio

To create: `Kibana → Dashboards → Create dashboard → Add panel`

> Kibana dashboard NDJSON exports are a planned addition to this repository. See `CURRENT_LIMITATIONS.md`.

---

## Validation Commands

Run these from the ELK-SIEM (192.168.10.100) to verify the full stack:

```bash
# Elasticsearch health
curl -k -u "${ES_USER}:${ES_PASSWORD}" https://localhost:9200/_cluster/health?pretty

# List all indices
curl -k -u "${ES_USER}:${ES_PASSWORD}" "https://localhost:9200/_cat/indices?v&s=index"

# Check Logstash is listening on 5044
ss -tlnp | grep 5044

# Check Winlogbeat index count
curl -k -u "${ES_USER}:${ES_PASSWORD}" "https://localhost:9200/winlogbeat-*/_count"

# Check Filebeat index count
curl -k -u "${ES_USER}:${ES_PASSWORD}" "https://localhost:9200/filebeat-*/_count"

# Check Auditbeat index count
curl -k -u "${ES_USER}:${ES_PASSWORD}" "https://localhost:9200/auditbeat-*/_count"

# Services status
sudo systemctl status elasticsearch logstash kibana
```

See also `scripts/linux/` for validation shell scripts.

---

## Troubleshooting

| Problem | Symptom | Resolution |
|---------|---------|------------|
| Elasticsearch won't start | Service fails, no cluster | Check for duplicate `cluster.initial_master_nodes` in `elasticsearch.yml` — must appear exactly once |
| Kibana not accessible from LAN | Browser times out | Confirm `server.host: "0.0.0.0"` in `kibana.yml` — default is localhost-only |
| Winlogbeat not shipping events | Index count stays at zero | Check output target — must point to Logstash on 5044, not Elasticsearch on 9200 |
| Sysmon channel not found | Winlogbeat startup error | Install Sysmon64 before adding `Microsoft-Windows-Sysmon/Operational` to `winlogbeat.yml` |
| Event 4625 not appearing | No failed logon events in Kibana | Enable Audit Policy: `secpol.msc → Advanced Audit Policy → Logon/Logoff → Audit Logon → Failure` |
| SSH connection refused after IP change | `ssh-keygen` known_hosts conflict | Run: `ssh-keygen -R 192.168.10.100` on the connecting host |
| No OPNsense events in ELK | `filebeat-*` index empty of syslog | Confirm Filebeat syslog input is bound to `0.0.0.0:514` and OPNsense target IP is `192.168.10.155` |
| Detection rules show no results | Rules active but zero alerts | Verify the Kibana Security default data view includes the correct index patterns |

---

## Production Caveats

This lab was built to learn and demonstrate SOC fundamentals. Before adapting any part of it for a production environment:

1. **Replace `ssl_verification_mode: none`** — Use a valid CA cert for the Elasticsearch TLS connection in beats.conf. Elastic generates a CA cert during installation at `/etc/elasticsearch/certs/http_ca.crt`.

2. **Replace username/password with API keys** — Logstash, Winlogbeat, Filebeat, and Auditbeat should each authenticate to Elasticsearch using scoped API keys rather than the elastic superuser password.

3. **Least privilege** — The `elastic` user is a superuser. Create dedicated roles and users for each Beat agent with only the permissions required to write to their specific indices.

4. **Index lifecycle management (ILM)** — Configure ILM policies before ingestion begins at scale. Hot/warm/cold tier policies and automatic index rollover are required for production data volumes.

5. **Multi-node Elasticsearch** — A single-node cluster has no redundancy. Production deployments require a minimum of 3 nodes for quorum.

6. **Logstash as a systemd service with environment variables** — Ensure credentials are set via the systemd override and are not visible in process listings or shell history.

---

*Project: homelab-elk-soc | Author: John Medina | github.com/m549n1ja*
