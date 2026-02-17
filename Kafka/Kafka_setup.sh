#!/usr/bin/env bash

set -euo pipefail

########################################################
# Kafka 4.0 KRaft Cluster Setup Script (cross-Linux)
# Usage:
# sudo bash Kafka_setup.sh <NODE_ID> <NODE_IP> [CLUSTER_ID] [NODE_LIST]
#
# NODE_LIST: comma-separated list of controller entries as id@ip[:controllerPort]
# Example: 1@192.168.1.101:9093,2@192.168.1.102:9093,3@192.168.1.103:9093
########################################################

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo or as root"
    echo "Usage: sudo bash $0 <NODE_ID> <NODE_IP> [CLUSTER_ID] [NODE_LIST]"
    exit 1
fi

NODE_ID=${1:-}
NODE_IP=${2:-}
CLUSTER_ID=${3:-}
NODE_LIST=${4:-}

# --- Optional: define all cluster nodes here (preferred) ---
# Comma-separated list of id@ip or id@ip:controllerPort
# Example: NODES="1@192.168.1.101,2@192.168.1.102,3@192.168.1.103"
NODES=${NODES:-}

# If NODE_ID or NODE_IP not provided as args, prompt the user (only ask for these two)
if [ -z "$NODE_ID" ]; then
    read -p "Enter NODE ID: " NODE_ID
fi
if [ -z "$NODE_IP" ]; then
    read -p "Enter NODE IP (the address other nodes will use to reach this node): " NODE_IP
fi

# If still missing and no NODES defined, abort
if [ -z "$NODE_ID" ] || [ -z "$NODE_IP" ]; then
    if [ -z "$NODES" ]; then
        echo "Usage: sudo bash $0 <NODE_ID> <NODE_IP> [CLUSTER_ID] [NODE_LIST]"
        echo "Or set NODES at the top of the script with all cluster entries"
        exit 1
    fi
fi

##########################################
## CONFIGURABLE
##########################################
KAFKA_VERSION="4.0.0"
SCALA_VERSION="2.13"
INSTALL_DIR="/opt/kafka"
DATA_DIR="/data/kafka"
CONFIG_DIR="$INSTALL_DIR/config/kraft"
CONFIG_FILE="$CONFIG_DIR/server.properties"
KAFKA_USER=${SUDO_USER:-$(whoami)}
JAVA_PKG_OPENJDK="openjdk-17-jdk"

# Default controller quorum (used if NODE_LIST not provided)
DEFAULT_CONTROLLER_QUORUM="1@192.168.1.101:9093,2@192.168.1.102:9093,3@192.168.1.103:9093"

##########################################
## Detect package manager
##########################################
if command -v apt-get &>/dev/null; then
    PM="apt"
    PM_INSTALL="apt-get install -y"
    PM_UPDATE="apt-get update -y"
elif command -v dnf &>/dev/null; then
    PM="dnf"
    PM_INSTALL="dnf install -y"
    PM_UPDATE="dnf makecache"
elif command -v yum &>/dev/null; then
    PM="yum"
    PM_INSTALL="yum install -y"
    PM_UPDATE="yum makecache"
else
    echo "Unsupported package manager. Please install Java (Java 17) and wget/tar/uuid-runtime manually."
    PM="" 
fi

##########################################
## Install Java + tools
##########################################
echo "Installing Java and required tools (if available package manager)..."
if [ -n "$PM" ]; then
    $PM_UPDATE || true
    if [ "$PM" = "apt" ]; then
        $PM_INSTALL $JAVA_PKG_OPENJDK wget tar uuid-runtime || true
    else
        # On RHEL/Fedora, package names differ
        $PM_INSTALL java-17-openjdk wget tar which || true
    fi
else
    echo "Skipping package manager install; ensure Java 17, wget, tar and uuidgen are installed."
fi

##########################################
## Prepare install and data directories
##########################################
mkdir -p "$INSTALL_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$CONFIG_DIR"
chown -R "$KAFKA_USER":"$KAFKA_USER" "$INSTALL_DIR" || true
chown -R "$KAFKA_USER":"$KAFKA_USER" "$DATA_DIR" || true

##########################################
## DOWNLOAD KAFKA if not present
##########################################
if [ ! -x "$INSTALL_DIR/bin/kafka-server-start.sh" ]; then
    echo "Downloading Kafka ${KAFKA_VERSION}..."
    cd /tmp
    TGZ="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
    URL="https://downloads.apache.org/kafka/${KAFKA_VERSION}/${TGZ}"
    wget -q --show-progress "$URL"
    tar -xzf "$TGZ"
    rm -f "$TGZ"
    EXTRACTED_DIR="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
    # Move the extracted directory into INSTALL_DIR. Some environments end up
    # with /opt/kafka/kafka_2.13-4.0.0 (nested) — flatten that so bin/ is at
    # $INSTALL_DIR/bin.
    mv "$EXTRACTED_DIR" "$INSTALL_DIR"
    # If bin is nested under a subdir, move its contents up
    if [ ! -x "$INSTALL_DIR/bin/kafka-server-start.sh" ] && [ -d "$INSTALL_DIR/$EXTRACTED_DIR/bin" ]; then
        echo "Flattening nested Kafka directory structure..."
        mv "$INSTALL_DIR/$EXTRACTED_DIR"/* "$INSTALL_DIR"/ || true
        rmdir "$INSTALL_DIR/$EXTRACTED_DIR" 2>/dev/null || true
    fi
    chown -R "$KAFKA_USER":"$KAFKA_USER" "$INSTALL_DIR"

    # Ensure shell scripts in bin are executable and don't have CRLFs (dos2unix or sed fallback)
    if [ -d "$INSTALL_DIR/bin" ]; then
        chmod +x "$INSTALL_DIR/bin/"*.sh 2>/dev/null || true
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$INSTALL_DIR/bin/"*.sh 2>/dev/null || true
        else
            # sed in-place: remove trailing CR if present
            sed -i 's/\r$//' "$INSTALL_DIR/bin/"*.sh 2>/dev/null || true
        fi
    fi
fi

##########################################
## CLUSTER ID
##########################################
if [ -z "$CLUSTER_ID" ]; then
    if command -v uuidgen &>/dev/null; then
        CLUSTER_ID=$(uuidgen)
    else
        CLUSTER_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$RANDOM")
    fi
    echo "Generated Cluster ID: $CLUSTER_ID"
else
    echo "Using provided Cluster ID: $CLUSTER_ID"
fi

# NOTE: do not write cluster.id yet — it will be written or retrieved
# after controller quorum is normalized and leader is determined so the
# same Cluster ID can be distributed to other nodes when needed.

##########################################
## Build controller.quorum.voters from NODES / NODE_LIST / default
##########################################
# Priority: NODES (in-script) > NODE_LIST (arg) > DEFAULT_CONTROLLER_QUORUM
if [ -n "$NODES" ]; then
    RAW_QUORUM="$NODES"
elif [ -n "$NODE_LIST" ]; then
    RAW_QUORUM="$NODE_LIST"
else
    RAW_QUORUM="$DEFAULT_CONTROLLER_QUORUM"
fi

# Normalize controller entries to include ports (default 9093)
IFS=',' read -r -a cq_arr <<< "$RAW_QUORUM"
normalized_quorum=""
for entry in "${cq_arr[@]}"; do
    entry=$(echo "$entry" | tr -d '[:space:]')
    id_part=$(echo "$entry" | cut -d'@' -f1)
    host_part=$(echo "$entry" | cut -d'@' -f2)
    if [ -z "$host_part" ]; then
        echo "Skipping invalid node entry: $entry"
        continue
    fi
    if [[ "$host_part" != *":"* ]]; then
        host_part="${host_part}:9093"
    fi
    if [ -z "$normalized_quorum" ]; then
        normalized_quorum="${id_part}@${host_part}"
    else
        normalized_quorum="${normalized_quorum},${id_part}@${host_part}"
    fi
done
CONTROLLER_QUORUM="$normalized_quorum"

# If NODE_ID/NODE_IP not provided as args, try to detect local node by matching local IP
if [ -z "$NODE_ID" ] || [ -z "$NODE_IP" ]; then
    LOCAL_IP=""
    if command -v hostname >/dev/null 2>&1; then
        LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi
    if [ -z "${LOCAL_IP:-}" ] && command -v ip >/dev/null 2>&1; then
        LOCAL_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1 || true)
    fi

    if [ -n "$LOCAL_IP" ]; then
        IFS=',' read -r -a match_arr <<< "$CONTROLLER_QUORUM"
        for e in "${match_arr[@]}"; do
            eid=$(echo "$e" | cut -d'@' -f1)
            ehostport=$(echo "$e" | cut -d'@' -f2)
            ehost=$(echo "$ehostport" | cut -d':' -f1)
            if [ "$ehost" = "$LOCAL_IP" ]; then
                NODE_ID="$eid"
                NODE_IP="$ehost"
                break
            fi
        done
    fi
fi

# Final safety check
if [ -z "$NODE_ID" ] || [ -z "$NODE_IP" ]; then
    echo "Could not determine node id/ip. Provide them as arguments or set NODES at top."
    echo "Controller quorum: $CONTROLLER_QUORUM"
    exit 1
fi

##########################################
## Distribute or retrieve Cluster ID across nodes
## Leader is selected as the node with the smallest numeric id
##########################################
SSH_USER=${SSH_USER:-$KAFKA_USER}
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5"

leader_id=""
leader_host=""
IFS=',' read -r -a qa <<< "$CONTROLLER_QUORUM"
for e in "${qa[@]}"; do
    eid=$(echo "$e" | cut -d'@' -f1)
    ehostport=$(echo "$e" | cut -d'@' -f2)
    ehost=$(echo "$ehostport" | cut -d':' -f1)
    if [ -z "$leader_id" ] || [ "$eid" -lt "$leader_id" ]; then
        leader_id="$eid"
        leader_host="$ehost"
    fi
done

echo "Cluster leader candidate: id=$leader_id host=$leader_host"

if [ -z "$CLUSTER_ID" ]; then
    # ensure CLUSTER_ID variable exists (should have been generated earlier if empty)
    if [ -z "$CLUSTER_ID" ]; then
        if command -v uuidgen &>/dev/null; then
            CLUSTER_ID=$(uuidgen)
        else
            CLUSTER_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$RANDOM")
        fi
        echo "Generated Cluster ID: $CLUSTER_ID"
    fi
fi

if [ "$NODE_ID" = "$leader_id" ]; then
    echo "This node ($NODE_ID) is leader — writing Cluster ID and attempting to distribute to peers"
    echo "$CLUSTER_ID" > "$INSTALL_DIR/cluster.id"
    chown "$KAFKA_USER":"$KAFKA_USER" "$INSTALL_DIR/cluster.id" || true

    for e in "${qa[@]}"; do
        eid=$(echo "$e" | cut -d'@' -f1)
        ehostport=$(echo "$e" | cut -d'@' -f2)
        ehost=$(echo "$ehostport" | cut -d':' -f1)
        if [ "$eid" = "$leader_id" ]; then
            continue
        fi
        echo "Attempting to copy Cluster ID to $ehost"
        scp $SSH_OPTS "$INSTALL_DIR/cluster.id" "${SSH_USER}@${ehost}:/tmp/cluster.id" 2>/dev/null || { echo "scp to $ehost failed"; continue; }
        ssh $SSH_OPTS "${SSH_USER}@${ehost}" "sudo mkdir -p $INSTALL_DIR && sudo mv /tmp/cluster.id $INSTALL_DIR/cluster.id && sudo chown $KAFKA_USER:$KAFKA_USER $INSTALL_DIR/cluster.id" 2>/dev/null || echo "remote move on $ehost failed"
    done
else
    # Try to retrieve cluster.id from leader (wait until available)
    echo "This node ($NODE_ID) will attempt to retrieve Cluster ID from leader $leader_host"
    attempts=0
    max_attempts=60
    while [ ! -f "$INSTALL_DIR/cluster.id" ] && [ $attempts -lt $max_attempts ]; do
        echo "Attempt $((attempts+1)) to fetch cluster.id from ${leader_host}..."
        scp $SSH_OPTS "${SSH_USER}@${leader_host}:/opt/kafka/cluster.id" /tmp/cluster.id 2>/dev/null && {
            sudo mv /tmp/cluster.id "$INSTALL_DIR/cluster.id"
            sudo chown "$KAFKA_USER":"$KAFKA_USER" "$INSTALL_DIR/cluster.id"
            echo "Cluster ID retrieved and saved"
            break
        }
        attempts=$((attempts+1))
        sleep 5
    done
    if [ ! -f "$INSTALL_DIR/cluster.id" ]; then
        echo "Failed to retrieve cluster.id from leader after $max_attempts attempts. You can set CLUSTER_ID manually or ensure SSH connectivity to $leader_host." >&2
        exit 1
    fi
    CLUSTER_ID=$(cat "$INSTALL_DIR/cluster.id")
fi


##########################################
## Create server.properties (use sudo tee for proper permissions)
##########################################
echo "Creating Kafka server.properties at $CONFIG_FILE"
sudo -u "$KAFKA_USER" mkdir -p "$(dirname "$CONFIG_FILE")"
cat > /tmp/server.properties.$$ <<EOF
node.id=$NODE_ID
process.roles=broker,controller

controller.quorum.voters=$CONTROLLER_QUORUM
controller.listener.names=CONTROLLER

listeners=PLAINTEXT://$NODE_IP:9092,CONTROLLER://$NODE_IP:9093
advertised.listeners=PLAINTEXT://$NODE_IP:9092

listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
inter.broker.listener.name=PLAINTEXT

log.dirs=$DATA_DIR

default.replication.factor=3
min.insync.replicas=2
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2

num.network.threads=5
num.io.threads=8
auto.create.topics.enable=false
EOF

sudo mv /tmp/server.properties.$$ "$CONFIG_FILE"
sudo chown "$KAFKA_USER":"$KAFKA_USER" "$CONFIG_FILE"

##########################################
## FORMAT STORAGE (only if not formatted)
##########################################
if [ ! -f "$DATA_DIR/meta.properties" ]; then
    echo "Formatting Kafka storage for CLUSTER ID $CLUSTER_ID"
    sudo -u "$KAFKA_USER" "$INSTALL_DIR/bin/kafka-storage.sh" format -t "$CLUSTER_ID" -c "$CONFIG_FILE"
else
    echo "Storage already formatted. Skipping."
fi

##########################################
## Create systemd unit
##########################################
SERVICE_FILE="/etc/systemd/system/kafka.service"
echo "Creating systemd unit at $SERVICE_FILE"
cat > /tmp/kafka.service.$$ <<EOF
[Unit]
Description=Apache Kafka
After=network.target

[Service]
User=$KAFKA_USER
ExecStart=$INSTALL_DIR/bin/kafka-server-start.sh $CONFIG_FILE
ExecStop=$INSTALL_DIR/bin/kafka-server-stop.sh
Restart=always
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF

mv /tmp/kafka.service.$$ "$SERVICE_FILE"
chmod 644 "$SERVICE_FILE"

systemctl daemon-reload
systemctl enable kafka
systemctl restart kafka || true

echo "=========================================="
echo "Kafka 4.0 Setup Completed"
echo "Cluster ID: $CLUSTER_ID"
echo "Controller quorum: $CONTROLLER_QUORUM"
echo "=========================================="

