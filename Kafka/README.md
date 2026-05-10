# Kafka 4.0 KRaft Cluster Setup

This folder contains automated setup scripts for deploying Apache Kafka 4.0 in KRaft mode (no ZooKeeper) on Linux systems with support for multi-node clusters.

## Overview

- **Kafka Version**: 4.0.0
- **Architecture**: KRaft (Kraft mode - no ZooKeeper)
- **Default Port (Broker)**: 9092
- **Default Port (Controller)**: 9093
- **Installation Directory**: `/opt/kafka`
- **Data Directory**: `/data/kafka`
- **Support**: Cross-Linux (Ubuntu, Debian, RHEL, CentOS, Fedora)

## Files in This Folder

| File | Purpose |
|------|---------|
| `Kafka_setup.sh` | Main installation and cluster setup script |
| `Uninstall_kafka.sh` | Script to cleanly uninstall Kafka and remove data |
| `README.md` | This documentation file |

## Prerequisites

### System Requirements
- **OS**: Ubuntu, Debian, RHEL, CentOS, Fedora, or any Linux distribution with bash
- **User**: Must run with `sudo` or as `root`
- **Java**: OpenJDK 17 (auto-installed by script)
- **Tools**: wget, tar, uuid-runtime (auto-installed by script)

### Network Requirements (for Multi-Node Clusters)
- All nodes must be able to SSH to each other (passwordless SSH recommended)
- Port 9092 (broker) open between all nodes
- Port 9093 (controller) open between all nodes

## Quick Start

### Single Node Setup

Run the script with node ID and IP:

```bash
sudo bash Kafka_setup.sh 1 203.0.113.101
```

Or run interactively (you'll be prompted for NODE_ID and NODE_IP):

```bash
sudo bash Kafka_setup.sh
```

### Multi-Node Cluster Setup (Recommended Method)

#### Step 1: Define Your Cluster

Edit the top of `Kafka_setup.sh` and set the `NODES` variable with all cluster nodes:

```bash
# Edit Kafka_setup.sh, find this line and modify:
NODES="1@203.0.113.101,2@203.0.113.102,3@203.0.113.103"
```

Format: `id@ip` or `id@ip:9093` (port defaults to 9093 if omitted)

#### Step 2: Run on Each Node

On **Node 1** (203.0.113.101):
```bash
sudo bash Kafka_setup.sh 1 203.0.113.101
```

On **Node 2** (203.0.113.102):
```bash
sudo bash Kafka_setup.sh 2 203.0.113.102
```

On **Node 3** (203.0.113.103):
```bash
sudo bash Kafka_setup.sh 3 203.0.113.103
```

**Note**: The leader node (smallest numeric ID = Node 1) will generate the Cluster ID and attempt to distribute it to other nodes. Nodes 2 and 3 will wait to receive the Cluster ID from the leader.

> **Oracle Linux 9 / Red Hat OL9**: See the separate `Kafka-OL9/` folder for the OL9-specific script (proxy, OpenJDK 21, /apps path).

---

## Detailed Configuration

### Script Parameters

The script accepts command-line arguments or prompts interactively:

```bash
sudo bash Kafka_setup.sh <NODE_ID> <NODE_IP> [CLUSTER_ID] [NODE_LIST]
```

| Parameter | Required | Example | Description |
|-----------|----------|---------|-------------|
| `NODE_ID` | Yes | `1` | Unique numeric ID for this broker (smallest ID becomes leader) |
| `NODE_IP` | Yes | `203.0.113.101` | IP address other nodes will use to reach this broker |
| `CLUSTER_ID` | No | `a1b2c3d4-...` | UUID for Kafka cluster (auto-generated if omitted) |
| `NODE_LIST` | No | `1@203.0.113.101,2@203.0.113.102` | Override NODES variable with comma-separated list |

### Configuration Variables (Inside Script)

Edit these at the top of `Kafka_setup.sh` before running:

```bash
KAFKA_VERSION="4.0.0"           # Kafka version to download
SCALA_VERSION="2.13"            # Scala version (affects download URL)
INSTALL_DIR="/opt/kafka"        # Where to install Kafka binaries
DATA_DIR="/data/kafka"          # Where Kafka stores logs
CONFIG_DIR="$INSTALL_DIR/config/kraft"  # Configuration directory
KAFKA_USER="ubuntu"             # System user to run Kafka (defaults to $SUDO_USER)
```

### Multi-Node Configuration

To set up a 3-node cluster, modify the `NODES` variable:

```bash
# In Kafka_setup.sh, around line 26:
NODES="1@203.0.113.101,2@203.0.113.102,3@203.0.113.103"
```

Or pass as argument:

```bash
sudo bash Kafka_setup.sh 1 203.0.113.101 "" "1@203.0.113.101,2@203.0.113.102,3@203.0.113.103"
```

---

## Step-by-Step Installation

### For a 3-Node Cluster

#### **Cluster Planning**

| Node | ID | IP | Role |
|------|----|----|------|
| Node 1 | 1 | 203.0.113.101 | Leader + Broker + Controller |
| Node 2 | 2 | 203.0.113.102 | Broker + Controller |
| Node 3 | 3 | 203.0.113.103 | Broker + Controller |

#### **Procedure**

1. **SSH into Node 1 (Leader)**
   ```bash
   ssh user@203.0.113.101
   ```

2. **Copy the script to Node 1**
   ```bash
   scp Kafka_setup.sh user@203.0.113.101:~/
   ```

3. **Run setup on Node 1 (generates Cluster ID)**
   ```bash
   sudo bash ~/Kafka_setup.sh 1 203.0.113.101
   ```
   
   Expected output:
   ```
   Generated Cluster ID: 7637d2a4-e498-4df4-a3f6-aa835c4dae5d
   Cluster leader candidate: id=1 host=203.0.113.101
   This node (1) is leader — writing Cluster ID and attempting to distribute to peers
   Attempting to copy Cluster ID to 203.0.113.102
   Attempting to copy Cluster ID to 203.0.113.103
   Creating Kafka server.properties at /opt/kafka/config/kraft/server.properties
   Formatting Kafka storage for CLUSTER ID 7637d2a4-e498-4df4-a3f6-aa835c4dae5d
   Kafka 4.0 Setup Completed
   ```

4. **Run setup on Node 2**
   ```bash
   ssh user@203.0.113.102
   scp Kafka_setup.sh user@203.0.113.102:~/
   sudo bash ~/Kafka_setup.sh 2 203.0.113.102
   ```
   
   Expected output:
   ```
   This node (2) will attempt to retrieve Cluster ID from leader 203.0.113.101
   Attempt 1 to fetch cluster.id from 203.0.113.101...
   Cluster ID retrieved and saved
   Kafka 4.0 Setup Completed
   ```

5. **Run setup on Node 3** (same as Node 2)
   ```bash
   ssh user@203.0.113.103
   scp Kafka_setup.sh user@203.0.113.103:~/
   sudo bash ~/Kafka_setup.sh 3 203.0.113.103
   ```

### What the Script Installs

When you run `Kafka_setup.sh`, it automatically:

✅ Detects your Linux distribution (apt/dnf/yum)  
✅ Installs OpenJDK 17 and required tools  
✅ Downloads and extracts Kafka 4.0  
✅ Flattens directory structure  
✅ Creates necessary directories (`/opt/kafka`, `/data/kafka`)  
✅ Generates or distributes Cluster ID  
✅ Creates `server.properties` with correct configuration  
✅ Formats Kafka storage  
✅ Creates systemd service unit  
✅ Enables and starts the Kafka service  

---

## Verification

### Check Kafka Status

```bash
sudo systemctl status kafka
```

Expected output:
```
● kafka.service - Apache Kafka
   Loaded: loaded (/etc/systemd/system/kafka.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2026-02-18 10:30:45 UTC; 2min 15s ago
   Main PID: 1234 (java)
   Tasks: 45 (limit: 4915)
   Memory: 256.8M
```

### Check Kafka Logs

```bash
# View live logs
sudo tail -f /data/kafka/logs/server.log

# Or use systemd journal
sudo journalctl -u kafka -f
```

### Verify Cluster Formation

```bash
sudo -u kafka /opt/kafka/bin/kafka-metadata.sh \
  --snapshot /data/kafka/__cluster_metadata-0/00000000000000000000.log \
  --print
```

---

## Troubleshooting

### Issue: "Kafka-storage.sh: command not found"

**Cause**: Nested directory structure or missing execute permissions

**Fix**:
```bash
# Flatten nested directories
sudo bash -c 'cd /opt/kafka && if [ -d kafka_2.13-4.0.0 ] && [ ! -d bin ]; then mv kafka_2.13-4.0.0/* . || true; rmdir kafka_2.13-4.0.0 2>/dev/null || true; fi'

# Make scripts executable
sudo chmod +x /opt/kafka/bin/*.sh || true

# Remove CRLF line endings (if script was copied from Windows)
sudo sed -i 's/\r$//' /opt/kafka/bin/*.sh || true

# Verify
ls -la /opt/kafka/bin/kafka-storage.sh
```

### Issue: Cluster ID Distribution Failed

**Cause**: SSH keys not configured between nodes or no passwordless SSH

**Solution 1: Set up passwordless SSH**
```bash
# On Node 1, generate SSH key if not present
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""

# Copy public key to all other nodes
ssh-copy-id -i ~/.ssh/id_rsa.pub user@203.0.113.102
ssh-copy-id -i ~/.ssh/id_rsa.pub user@203.0.113.103
```

**Solution 2: Manually copy Cluster ID**
```bash
# On Node 1 (leader)
CLUSTER_ID=$(cat /opt/kafka/cluster.id)

# On Node 2 and Node 3
sudo bash -c "echo '$CLUSTER_ID' > /opt/kafka/cluster.id"
sudo chown kafka:kafka /opt/kafka/cluster.id
```

### Issue: Kafka Service Won't Start

**Diagnosis**:
```bash
sudo systemctl status kafka
sudo journalctl -u kafka -n 50
```

**Common causes**:
- Port 9092 or 9093 already in use
- Insufficient permissions on `/data/kafka`
- Invalid configuration in `server.properties`

**Fix**:
```bash
# Check port usage
sudo netstat -tulpn | grep 9092
sudo netstat -tulpn | grep 9093

# Fix permissions
sudo chown -R kafka:kafka /opt/kafka /data/kafka

# Restart service
sudo systemctl restart kafka
```

### Issue: Cluster Nodes Not Connecting

**Diagnosis**:
```bash
# Check network connectivity
ping 203.0.113.102
ssh -v user@203.0.113.102

# Check firewall
sudo ufw status
sudo firewall-cmd --list-all
```

**Fix**:
```bash
# Allow ports on firewall (Ubuntu/Debian)
sudo ufw allow 9092/tcp
sudo ufw allow 9093/tcp

# Or for RHEL/CentOS
sudo firewall-cmd --permanent --add-port=9092/tcp
sudo firewall-cmd --permanent --add-port=9093/tcp
sudo firewall-cmd --reload
```

---

## Advanced Configuration

### Custom Replication Factor

Edit the created `/opt/kafka/config/kraft/server.properties`:

```bash
sudo nano /opt/kafka/config/kraft/server.properties
```

Adjust these values:
```properties
default.replication.factor=3      # For 3-node cluster
min.insync.replicas=2             # Minimum replicas in-sync for writes
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
```

Then restart:
```bash
sudo systemctl restart kafka
```

### Custom Log Retention

```properties
log.retention.hours=168           # 7 days
log.segment.bytes=1073741824      # 1GB per segment
log.cleanup.policy=delete         # or 'compact'
```

---

## Uninstallation

### Complete Cleanup

```bash
sudo bash Uninstall_kafka.sh
```

This script will:
- Stop the Kafka service
- Backup `/opt/kafka` and `/data/kafka`
- Remove all Kafka files and directories
- Remove the systemd service
- Remove the kafka system user (optional prompt)

### Manual Cleanup

If you prefer manual removal:

```bash
# Stop the service
sudo systemctl stop kafka
sudo systemctl disable kafka

# Remove files
sudo rm -rf /opt/kafka /data/kafka

# Remove service file
sudo rm /etc/systemd/system/kafka.service
sudo systemctl daemon-reload

# Optional: remove user
sudo userdel -r kafka
```

---

## File Locations

| Item | Location |
|------|----------|
| Kafka Home | `/opt/kafka` |
| Configuration | `/opt/kafka/config/kraft/server.properties` |
| Data/Logs | `/data/kafka/` |
| Cluster ID | `/opt/kafka/cluster.id` |
| Systemd Unit | `/etc/systemd/system/kafka.service` |
| Java Home | System-dependent (usually `/usr/lib/jvm/...`) |

---

## Common Commands

### Start/Stop/Restart Kafka

```bash
# Start
sudo systemctl start kafka

# Stop
sudo systemctl stop kafka

# Restart
sudo systemctl restart kafka

# View status
sudo systemctl status kafka
```

### View Logs

```bash
# Live logs
sudo tail -f /data/kafka/logs/server.log

# Last 100 lines
sudo tail -n 100 /data/kafka/logs/server.log

# Systemd journal
sudo journalctl -u kafka -n 50 -f
```

### Test Connectivity Between Nodes

```bash
# From Node 1, verify connectivity to Node 2
nc -zv 203.0.113.102 9093
nc -zv 203.0.113.102 9092
```

### List Topics (if Kafka is running)

```bash
sudo -u kafka /opt/kafka/bin/kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092
```

---

## Support & Documentation

- **Apache Kafka Docs**: https://kafka.apache.org/documentation/
- **KRaft Configuration**: https://kafka.apache.org/documentation/#kraft_config
- **Troubleshooting**: Review logs at `/data/kafka/logs/server.log`

---

## Notes

- **Cluster ID**: Each Kafka cluster needs a unique UUID. The leader node (smallest ID) generates and distributes it to all other nodes.
- **Leader Election**: The node with the smallest numeric ID becomes the leader and coordinates Cluster ID distribution.
- **Passwordless SSH**: For seamless multi-node setup, configure passwordless SSH between nodes beforehand.
- **Network IPs**: Use network-reachable IPs (e.g., `192.168.x.x`), not localhost or `127.0.1.1`.
- **Java Version**: The script installs OpenJDK 17, which is required for Kafka 4.0.
- **Service Auto-start**: Kafka is configured to auto-start on system reboot via systemd.

---

**Last Updated**: February 18, 2026  
**Kafka Version**: 4.0.0  
**Architecture**: KRaft (No ZooKeeper)
