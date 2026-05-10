#!/bin/bash
# Kafka 4.0 KRaft 3-Node Cluster Setup Script for Red Hat / Oracle Linux 9
#
# Prerequisites: Run as root or with sudo
#
# Usage:
#   sudo bash kafka_install_ol9.sh <NODE_ID> <NODE_IP> [CLUSTER_ID] [CONTROLLER_QUORUM]
#
# Examples:
#   Node 1 (generates CLUSTER_ID): sudo bash kafka_install_ol9.sh 1 203.0.113.101
#   Node 2 (reuse CLUSTER_ID):     sudo bash kafka_install_ol9.sh 2 203.0.113.102 <cluster-id>
#   Node 3 (reuse CLUSTER_ID):     sudo bash kafka_install_ol9.sh 3 203.0.113.103 <cluster-id>
#
# Or set variables and run:
#   export HTTP_PROXY=http://cloudproxy-d.nat.bt.com:8080
#   export HTTPS_PROXY=https://cloudproxy-d.nat.bt.com:8080
#   export CONTROLLER_QUORUM="1@203.0.113.101:9093,2@203.0.113.102:9093,3@203.0.113.103:9093"
#   sudo -E bash kafka_install_ol9.sh 1 203.0.113.101

set -e

##########################################
## PROXY (set if behind corporate proxy)
##########################################
HTTP_PROXY="${HTTP_PROXY:-http://cloudproxy-d.nat.bt.com:8080}"
HTTPS_PROXY="${HTTPS_PROXY:-https://cloudproxy-d.nat.bt.com:8080}"
export http_proxy="${http_proxy:-$HTTP_PROXY}"
export https_proxy="${https_proxy:-$HTTPS_PROXY}"

##########################################
## CONFIGURABLE
##########################################
KAFKA_VERSION="4.1.1"
SCALA_VERSION="2.13"
KAFKA_BASE="/apps"
INSTALL_DIR="$KAFKA_BASE/kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
DATA_DIR="/apps/data/kafka"
CONFIG_FILE="$INSTALL_DIR/config/server.properties"

# OpenLogic OpenJDK 21
JAVA_VERSION="21.0.6+7"
JAVA_TAR="openlogic-openjdk-${JAVA_VERSION}-linux-x64.tar.gz"
JAVA_URL="https://builds.openlogic.com/downloadJDK/openlogic-openjdk/${JAVA_VERSION}/${JAVA_TAR}"
JAVA_HOME_DIR="/usr/lib/jvm/openlogic-openjdk-${JAVA_VERSION}-linux-x64"

# Kafka download
KAFKA_TGZ="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
KAFKA_URL="https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_TGZ}"

# Default 3-node controller quorum (override with arg or CONTROLLER_QUORUM env)
DEFAULT_CONTROLLER_QUORUM="1@203.0.113.101:9093,2@203.0.113.102:9093,3@203.0.113.103:9093"

KAFKA_USER="${SUDO_USER:-$(whoami)}"

##########################################
## COLORS & LOGGING
##########################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

##########################################
## ROOT CHECK
##########################################
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root or with sudo"
fi

##########################################
## ARGUMENTS
##########################################
NODE_ID=${1:-}
NODE_IP=${2:-}
CLUSTER_ID=${3:-}
CONTROLLER_QUORUM_INPUT=${4:-${CONTROLLER_QUORUM:-$DEFAULT_CONTROLLER_QUORUM}}

if [ -z "$NODE_ID" ]; then
    read -p "Enter NODE ID (1, 2, or 3): " NODE_ID
fi
if [ -z "$NODE_IP" ]; then
    read -p "Enter NODE IP (address other nodes use to reach this node): " NODE_IP
fi

if [ -z "$NODE_ID" ] || [ -z "$NODE_IP" ]; then
    log_error "NODE_ID and NODE_IP are required. Usage: sudo bash $0 <NODE_ID> <NODE_IP> [CLUSTER_ID] [CONTROLLER_QUORUM]"
fi

# Normalize controller quorum (ensure port 9093)
normalize_quorum() {
    local q="$1"
    local result=""
    IFS=',' read -ra arr <<< "$q"
    for e in "${arr[@]}"; do
        e=$(echo "$e" | tr -d '[:space:]')
        local id=$(echo "$e" | cut -d'@' -f1)
        local hostport=$(echo "$e" | cut -d'@' -f2)
        [[ "$hostport" != *:* ]] && hostport="${hostport}:9093"
        [ -n "$result" ] && result="${result},"
        result="${result}${id}@${hostport}"
    done
    echo "$result"
}
CONTROLLER_QUORUM=$(normalize_quorum "$CONTROLLER_QUORUM_INPUT")

##########################################
## STEP 1: Install OpenLogic OpenJDK 21
##########################################
install_java() {
    if [ -x "$JAVA_HOME_DIR/bin/java" ]; then
        log_info "OpenJDK 21 already installed at $JAVA_HOME_DIR"
        return 0
    fi

    log_info "Installing OpenLogic OpenJDK 21..."
    mkdir -p /usr/lib/jvm
    cd /usr/lib/jvm

    if [ ! -f "$JAVA_TAR" ]; then
        log_info "Downloading $JAVA_TAR (via proxy if set)..."
        wget -q --show-progress "$JAVA_URL" || log_error "Failed to download OpenJDK"
    fi

    tar -xzf "$JAVA_TAR"
    rm -f "$JAVA_TAR"

    # update-alternatives
    update-alternatives --install /usr/bin/java java "$JAVA_HOME_DIR/bin/java" 1
    update-alternatives --install /usr/bin/javac javac "$JAVA_HOME_DIR/bin/javac" 1
    update-alternatives --set java "$JAVA_HOME_DIR/bin/java"
    update-alternatives --set javac "$JAVA_HOME_DIR/bin/javac"

    export JAVA_HOME="$JAVA_HOME_DIR"
    export PATH="$PATH:$JAVA_HOME/bin"
    echo "export JAVA_HOME=$JAVA_HOME_DIR" > /etc/profile.d/kafka-java.sh
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/kafka-java.sh
    chmod +x /etc/profile.d/kafka-java.sh

    log_success "OpenJDK 21 installed"
}

export JAVA_HOME="$JAVA_HOME_DIR"
export PATH="$PATH:${JAVA_HOME}/bin"

if [ ! -x "$JAVA_HOME_DIR/bin/java" ]; then
    install_java
fi

# Ensure Java is in path for rest of script
export JAVA_HOME="$JAVA_HOME_DIR"
export PATH="$PATH:$JAVA_HOME/bin"

##########################################
## STEP 2: Install Kafka to /apps/
##########################################
install_kafka() {
    if [ -x "$INSTALL_DIR/bin/kafka-server-start.sh" ]; then
        log_info "Kafka ${KAFKA_VERSION} already installed at $INSTALL_DIR"
        return 0
    fi

    log_info "Installing Kafka ${KAFKA_VERSION} to $KAFKA_BASE..."
    mkdir -p "$KAFKA_BASE"
    cd "$KAFKA_BASE"

    if [ ! -f "$KAFKA_TGZ" ]; then
        log_info "Downloading Kafka (via proxy if set)..."
        wget -q --show-progress "$KAFKA_URL" || log_error "Failed to download Kafka"
    fi

    tar -xzf "$KAFKA_TGZ"

    # Fix line endings for Windows-edited scripts
    if [ -d "$INSTALL_DIR/bin" ]; then
        chmod +x "$INSTALL_DIR/bin/"*.sh 2>/dev/null || true
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$INSTALL_DIR/bin/"*.sh 2>/dev/null || true
        else
            sed -i 's/\r$//' "$INSTALL_DIR/bin/"*.sh 2>/dev/null || true
        fi
    fi

    log_success "Kafka installed at $INSTALL_DIR"
}

install_kafka

##########################################
## STEP 3: Create KRaft cluster config
##########################################
mkdir -p "$(dirname "$CONFIG_FILE")"

log_info "Creating server.properties for 3-node KRaft cluster..."

cat > "$CONFIG_FILE" << EOF
# KRaft 3-node cluster - Node $NODE_ID
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

chown -R "$KAFKA_USER:$KAFKA_USER" "$INSTALL_DIR"
mkdir -p "$DATA_DIR"
chown -R "$KAFKA_USER:$KAFKA_USER" "$DATA_DIR"

##########################################
## STEP 4: Generate or use CLUSTER_ID
##########################################
CLUSTER_ID_FILE="$INSTALL_DIR/cluster.id"

if [ -z "$CLUSTER_ID" ]; then
    if [ -f "$CLUSTER_ID_FILE" ]; then
        CLUSTER_ID=$(cat "$CLUSTER_ID_FILE")
        log_info "Using existing CLUSTER_ID from $CLUSTER_ID_FILE: $CLUSTER_ID"
    else
        log_info "Generating new KAFKA_CLUSTER_ID..."
        cd "$INSTALL_DIR"
        CLUSTER_ID=$(bin/kafka-storage.sh random-uuid)
        echo "$CLUSTER_ID" > "$CLUSTER_ID_FILE"
        chown "$KAFKA_USER:$KAFKA_USER" "$CLUSTER_ID_FILE"
        log_success "Generated CLUSTER_ID: $CLUSTER_ID"
        log_warning "IMPORTANT: Use this same CLUSTER_ID when running this script on nodes 2 and 3"
        log_info "  export KAFKA_CLUSTER_ID=$CLUSTER_ID"
        log_info "  Or: sudo bash $0 2 <NODE2_IP> $CLUSTER_ID"
    fi
else
    log_info "Using provided CLUSTER_ID: $CLUSTER_ID"
    echo "$CLUSTER_ID" > "$CLUSTER_ID_FILE"
    chown "$KAFKA_USER:$KAFKA_USER" "$CLUSTER_ID_FILE"
fi

export KAFKA_CLUSTER_ID="$CLUSTER_ID"

##########################################
## STEP 5: Format storage (cluster mode, not standalone)
##########################################
if [ ! -f "$DATA_DIR/meta.properties" ]; then
    log_info "Formatting Kafka storage for cluster (CLUSTER_ID=$CLUSTER_ID)..."
    cd "$INSTALL_DIR"
    sudo -u "$KAFKA_USER" env JAVA_HOME="$JAVA_HOME" PATH="$PATH" \
        bin/kafka-storage.sh format -t "$CLUSTER_ID" -c "$CONFIG_FILE"
    log_success "Storage formatted"
else
    log_info "Storage already formatted, skipping format step"
fi

##########################################
## STEP 6: Create systemd service
##########################################
SERVICE_FILE="/etc/systemd/system/kafka.service"
log_info "Creating systemd service..."

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Apache Kafka (KRaft 3-node cluster)
After=network.target

[Service]
Type=simple
User=$KAFKA_USER
Environment="JAVA_HOME=$JAVA_HOME_DIR"
Environment="PATH=/usr/local/bin:/usr/bin:/bin:$JAVA_HOME_DIR/bin"
ExecStart=$INSTALL_DIR/bin/kafka-server-start.sh $CONFIG_FILE
ExecStop=$INSTALL_DIR/bin/kafka-server-stop.sh
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kafka

##########################################
## STEP 7: Start Kafka
##########################################
log_info "Starting Kafka service..."
systemctl start kafka

log_info "Waiting for Kafka to start (15s)..."
sleep 15

if systemctl is-active --quiet kafka; then
    log_success "Kafka is running!"
    systemctl status kafka --no-pager
else
    log_warning "Kafka may still be starting. Check: systemctl status kafka"
    log_info "Logs: journalctl -u kafka -f"
fi

echo ""
log_success "Kafka 3-node cluster setup complete for Node $NODE_ID"
echo "========================================"
echo "  NODE_ID:          $NODE_ID"
echo "  NODE_IP:          $NODE_IP"
echo "  CLUSTER_ID:       $CLUSTER_ID"
echo "  CONTROLLER_QUORUM: $CONTROLLER_QUORUM"
echo "  INSTALL_DIR:      $INSTALL_DIR"
echo "  DATA_DIR:         $DATA_DIR"
echo "  Broker port:      9092"
echo "  Controller port:  9093"
echo "========================================"
log_info "For nodes 2 and 3, run with the same CLUSTER_ID:"
log_info "  sudo bash $0 2 <NODE2_IP> $CLUSTER_ID"
log_info "  sudo bash $0 3 <NODE3_IP> $CLUSTER_ID"
