# ELK Stack - 3-Node Elasticsearch, Logstash, Kibana

Automation scripts for installing a 3-node Elasticsearch cluster, Logstash, and Kibana (ELK stack).

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation Order](#installation-order)
- [Execution Steps](#execution-steps)
- [Scripts](#scripts)
- [Quick Start](#quick-start)
- [Detailed Steps](#detailed-steps)
- [Troubleshooting](#troubleshooting)

---

## Overview

| Script | Purpose |
|--------|---------|
| `elasticsearch_master_install.sh` | Install Elasticsearch on **Node 1** (master) |
| `elasticsearch_node_install.sh` | Install Elasticsearch on **Nodes 2 & 3** |
| `logstash_install.sh` | Install and configure Logstash |
| `kibana_install.sh` | Install and configure Kibana |

**Version:** Elasticsearch 9.1.2 (Logstash & Kibana match)

---

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Node 1        │     │   Node 2        │     │   Node 3        │
│   (Master)      │────▶│   (Data)        │────▶│   (Data)        │
│   Elasticsearch │     │   Elasticsearch │     │   Elasticsearch │
└────────┬────────┘     └─────────────────┘     └─────────────────┘
         │
         │  ┌──────────────┐    ┌──────────────┐
         └──│   Logstash   │───▶│   Kibana     │
            │   (ingest)   │    │   (UI)       │
            └──────────────┘    └──────────────┘
```

---

## Prerequisites

- **OS:** RHEL/CentOS/Rocky Linux (x86_64)
- **sudo/root** access
- **Internet** access for downloads
- **Java:** OpenJDK 17+ (Elasticsearch bundles its own)
- **wget** and **shasum** (or sha512sum)

---

## Installation Order

1. **Node 1** – Run `elasticsearch_master_install.sh`
2. **Node 2** – Run `elasticsearch_node_install.sh 2 <node1_ip> <node2_ip> <node3_ip>`
3. **Node 3** – Run `elasticsearch_node_install.sh 3 <node1_ip> <node2_ip> <node3_ip>`
4. **Logstash** – Run `logstash_install.sh` (can be on any host)
5. **Kibana** – Run `kibana_install.sh` (typically on a dedicated host or Node 1)

---

## Execution Steps

Follow these steps in order. Replace `192.168.1.10`, `192.168.1.11`, `192.168.1.12` with your actual node IPs.

### Step 1: Make scripts executable

Run once (e.g. after cloning or copying the Elasticsearch folder):

```bash
cd Elasticsearch
chmod +x elasticsearch_master_install.sh elasticsearch_node_install.sh logstash_install.sh kibana_install.sh
```

### Step 2: Install Elasticsearch on Node 1 (master)

On the first node (e.g. 192.168.1.10):

```bash
cd Elasticsearch
NODE_2_IP=192.168.1.11 NODE_3_IP=192.168.1.12 ./elasticsearch_master_install.sh
```

- Save any password shown in the output.
- Wait until Elasticsearch is running before proceeding.

### Step 3: Install Elasticsearch on Node 2

On the second node (e.g. 192.168.1.11):

```bash
cd Elasticsearch
./elasticsearch_node_install.sh 2 192.168.1.10 192.168.1.11 192.168.1.12
```

### Step 4: Install Elasticsearch on Node 3

On the third node (e.g. 192.168.1.12):

```bash
cd Elasticsearch
./elasticsearch_node_install.sh 3 192.168.1.10 192.168.1.11 192.168.1.12
```

### Step 5: Verify the cluster

On any node or a machine with network access to the cluster:

```bash
curl http://192.168.1.10:9200/_cluster/health?pretty
```

Expect `"status" : "green"` or `"yellow"` when healthy.

### Step 6: Install Logstash

On the host where Logstash will run (can be any node or a separate host):

```bash
cd Elasticsearch
ELASTICSEARCH_HOST=192.168.1.10 ./logstash_install.sh
```

Replace `192.168.1.10` with the IP of any Elasticsearch node if different.

### Step 7: Install Kibana

On the host where Kibana will run:

```bash
cd Elasticsearch
ELASTICSEARCH_HOST=192.168.1.10 ./kibana_install.sh
```

### Step 8: Access Kibana

Open a browser and go to:

```
http://<kibana-host-ip>:5601
```

Replace `<kibana-host-ip>` with the IP of the host where Kibana is installed.

---

## Scripts

### elasticsearch_master_install.sh

Installs Elasticsearch on the first node (master).

**Environment variables (optional):**

| Variable | Default | Description |
|----------|---------|-------------|
| CLUSTER_NAME | elastic-cluster | Cluster name |
| NODE_NAME | node-1 | Node name |
| NETWORK_HOST | 0.0.0.0 | Bind address |
| HTTP_PORT | 9200 | HTTP port |
| NODE_2_IP | - | Node 2 IP (for discovery) |
| NODE_3_IP | - | Node 3 IP (for discovery) |

**Usage:**
```bash
chmod +x elasticsearch_master_install.sh
./elasticsearch_master_install.sh

# Or with custom IPs for 3-node discovery:
NODE_2_IP=192.168.1.11 NODE_3_IP=192.168.1.12 ./elasticsearch_master_install.sh
```

---

### elasticsearch_node_install.sh

Installs Elasticsearch on Nodes 2 and 3.

**Usage:**
```bash
chmod +x elasticsearch_node_install.sh
./elasticsearch_node_install.sh <node_num> <master_ip> [node_2_ip] [node_3_ip]
```

**Examples:**
```bash
# Node 2:
./elasticsearch_node_install.sh 2 192.168.1.10 192.168.1.11 192.168.1.12

# Node 3:
./elasticsearch_node_install.sh 3 192.168.1.10 192.168.1.11 192.168.1.12
```

---

### logstash_install.sh

Installs Logstash and creates a sample pipeline that sends data to Elasticsearch.

**Environment variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| ELASTICSEARCH_HOST | localhost | Elasticsearch host |
| ELASTICSEARCH_PORT | 9200 | Elasticsearch port |

**Usage:**
```bash
chmod +x logstash_install.sh
./logstash_install.sh

# Or specify Elasticsearch:
ELASTICSEARCH_HOST=192.168.1.10 ELASTICSEARCH_PORT=9200 ./logstash_install.sh
```

**Pipeline config:** `/etc/logstash/conf.d/elasticsearch_output.conf`

---

### kibana_install.sh

Installs Kibana and configures it to connect to Elasticsearch.

**Environment variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| ELASTICSEARCH_HOST | localhost | Elasticsearch host |
| ELASTICSEARCH_PORT | 9200 | Elasticsearch port |
| KIBANA_HOST | 0.0.0.0 | Kibana bind address |
| KIBANA_PORT | 5601 | Kibana port |

**Usage:**
```bash
chmod +x kibana_install.sh
./kibana_install.sh

# With custom Elasticsearch:
ELASTICSEARCH_HOST=192.168.1.10 ./kibana_install.sh
```

**Access:** `http://<kibana-host>:5601`

---

## Quick Start

### 3-Node Elasticsearch

```bash
# On Node 1 (192.168.1.10):
cd Elasticsearch
NODE_2_IP=192.168.1.11 NODE_3_IP=192.168.1.12 ./elasticsearch_master_install.sh

# On Node 2 (192.168.1.11):
cd Elasticsearch
./elasticsearch_node_install.sh 2 192.168.1.10 192.168.1.11 192.168.1.12

# On Node 3 (192.168.1.12):
cd Elasticsearch
./elasticsearch_node_install.sh 3 192.168.1.10 192.168.1.11 192.168.1.12
```

### Logstash (on any host)

```bash
cd Elasticsearch
ELASTICSEARCH_HOST=192.168.1.10 ./logstash_install.sh
```

### Kibana (on any host)

```bash
cd Elasticsearch
ELASTICSEARCH_HOST=192.168.1.10 ./kibana_install.sh
```

---

## Detailed Steps

### Elasticsearch Node 1 (Master)

1. Create `elastic-install-files` and download RPM + checksum
2. Verify package with `shasum -a 512`
3. Install with `sudo rpm --install`
4. Configure `elasticsearch.yml`: cluster name, network host, port, security off
5. Set `transport.host: 0.0.0.0` and discovery seed hosts
6. Enable and start service

### Elasticsearch Nodes 2 & 3

1. Same download/install steps
2. Configure `elasticsearch.yml` with `discovery.seed_hosts` and `cluster.initial_master_nodes`
3. Point to master and peer nodes
4. Start service

### Logstash

1. Create `logstash-install-files`, download, verify
2. Install RPM, enable service
3. Create pipeline config in `/etc/logstash/conf.d/` with Elasticsearch output
4. Start Logstash

### Kibana

1. Create `kibana-install-files`, download, verify
2. Install RPM, enable service
3. Edit `kibana.yml`: `elasticsearch.hosts`, `server.port`, `server.host`
4. Start Kibana
5. Open `http://<host>:5601`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Checksum fails | Re-download files; ensure no corruption |
| Elasticsearch won't start | Check `/var/log/elasticsearch/`, ensure ports 9200/9300 free |
| Node won't join cluster | Verify `discovery.seed_hosts`, firewall (9300), same cluster name |
| Logstash keystore error | Add `xpack.management.elasticsearch.hosts` or adjust keystore path in `logstash.yml` |
| Kibana can't reach ES | Verify `elasticsearch.hosts` in `kibana.yml`, network/firewall |
| Cluster health yellow/red | Check shard allocation: `GET _cluster/health?pretty` |

**Useful commands:**
```bash
# Elasticsearch
sudo systemctl status elasticsearch
curl http://localhost:9200/_cluster/health?pretty

# Logstash
sudo systemctl status logstash
sudo journalctl -u logstash -f

# Kibana
sudo systemctl status kibana
sudo journalctl -u kibana -f
```
