# Kafka 4.0 KRaft 3-Node Cluster for Oracle Linux 9 / Red Hat 9

This folder contains the Kafka setup script for **Red Hat / Oracle Linux 9** with corporate proxy support, OpenLogic OpenJDK 21, and installation to `/apps/`.

## Overview

| Item | Value |
|------|-------|
| **Target OS** | Red Hat / Oracle Linux 9 |
| **Kafka Version** | 4.0.0 |
| **Java** | OpenLogic OpenJDK 21.0.6+7 |
| **Install Path** | `/apps/kafka_2.13-4.0.0` |
| **Data Path** | `/data/kafka` |
| **Proxy** | Pre-configured for cloudproxy-d.nat.bt.com:8080 |
| **Cluster** | 3-node KRaft (no ZooKeeper) |

## Prerequisites

- Run as root or with `sudo`
- Network access (with proxy if behind firewall)

## Usage

### Node 1 (generates CLUSTER_ID)

```bash
export HTTP_PROXY=http://cloudproxy-d.nat.bt.com:8080
export HTTPS_PROXY=https://cloudproxy-d.nat.bt.com:8080
sudo -E bash kafka_install_ol9.sh 1 192.168.1.101
```

Save the **CLUSTER_ID** from the output.

### Nodes 2 and 3 (use same CLUSTER_ID)

```bash
export HTTP_PROXY=http://cloudproxy-d.nat.bt.com:8080
export HTTPS_PROXY=https://cloudproxy-d.nat.bt.com:8080
sudo -E bash kafka_install_ol9.sh 2 192.168.1.102 <cluster-id>
sudo -E bash kafka_install_ol9.sh 3 192.168.1.103 <cluster-id>
```

### Custom controller quorum

```bash
export CONTROLLER_QUORUM="1@192.168.1.101:9093,2@192.168.1.102:9093,3@192.168.1.103:9093"
sudo -E bash kafka_install_ol9.sh 1 192.168.1.101
```

## File Locations

| Item | Path |
|------|------|
| Kafka Home | `/apps/kafka_2.13-4.0.0` |
| Config | `/apps/kafka_2.13-4.0.0/config/kraft/server.properties` |
| Data/Logs | `/data/kafka/` |
| Cluster ID | `/apps/kafka_2.13-4.0.0/cluster.id` |
| Java | `/usr/lib/jvm/openlogic-openjdk-21.0.6+7-linux-x64` |

## Ports

- **9092** – Broker (client connections)
- **9093** – Controller (inter-broker)
