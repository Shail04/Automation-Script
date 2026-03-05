#!/bin/bash
# Elasticsearch Data Node (Node 2 or 3) Installation Script
# For 3-node cluster - run on second and third nodes
# Usage: ./elasticsearch_node_install.sh <node_number> <master_ip> [node_2_ip] [node_3_ip]

set -e

NODE_NUM="${1:-2}"
MASTER_IP="${2:-}"
NODE_2_IP="${3:-}"
NODE_3_IP="${4:-}"

if [ -z "$MASTER_IP" ]; then
    echo "Usage: $0 <node_number> <master_ip> [node_2_ip] [node_3_ip]"
    echo "Example: $0 2 192.168.1.10 192.168.1.11 192.168.1.12"
    exit 1
fi

ELASTIC_VERSION="9.1.2"
INSTALL_DIR="elastic-install-files"
CLUSTER_NAME="${CLUSTER_NAME:-elastic-cluster}"
NODE_NAME="node-${NODE_NUM}"
NETWORK_HOST="${NETWORK_HOST:-0.0.0.0}"
HTTP_PORT="${HTTP_PORT:-9200}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# OS detection / package manager
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID,,}"
        OS_LIKE="${ID_LIKE,,}"
    else
        OS_ID=""
        OS_LIKE=""
    fi

    if [[ "$OS_ID" =~ (rhel|centos|rocky|almalinux|ol|fedora) ]] \
       || [[ "$OS_LIKE" == *"rhel"* ]] || [[ "$OS_LIKE" == *"centos"* ]] || [[ "$OS_LIKE" == *"fedora"* ]]; then
        OS_FAMILY="rhel"
        if command -v dnf >/dev/null 2>&1; then
            PKG_MGR="dnf"
        else
            PKG_MGR="yum"
        fi
        PKG_TYPE="rpm"
    elif [[ "$OS_ID" =~ (ubuntu|debian) ]] || [[ "$OS_LIKE" == *"debian"* ]]; then
        OS_FAMILY="debian"
        PKG_MGR="apt-get"
        PKG_TYPE="deb"
    else
        OS_FAMILY="unknown"
        PKG_MGR=""
        PKG_TYPE=""
    fi
}

ensure_command() {
    local cmd="$1"
    local pkg="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi

    if [ -n "$PKG_MGR" ] && [ -n "$pkg" ]; then
        log_info "Installing package ${pkg} for command ${cmd}"
        sudo "$PKG_MGR" install -y "$pkg" || log_error "Failed to install ${pkg}"
    else
        log_error "Required command '${cmd}' is not available and package manager is unknown"
    fi
}

RPM_FILE="elasticsearch-${ELASTIC_VERSION}-x86_64.rpm"
SHA_FILE="${RPM_FILE}.sha512"
BASE_URL="https://artifacts.elastic.co/downloads/elasticsearch"

log_info "Elasticsearch Node ${NODE_NUM} Installation"
echo "========================================"

# Detect OS and basic requirements
detect_os

if [ "$PKG_TYPE" != "rpm" ]; then
    log_error "This script currently supports RPM-based Linux distributions (RHEL/CentOS/Rocky/OL/Fedora). For Debian/Ubuntu, please use the official .deb installation steps from Elastic."
fi

ensure_command "wget" "wget"
ensure_command "sha512sum" "coreutils"

# Create directory and download
log_info "Creating directory and downloading Elasticsearch"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

[ -f "$RPM_FILE" ] || wget -q --show-progress "${BASE_URL}/${RPM_FILE}" || log_error "Failed to download RPM"
[ -f "$SHA_FILE" ] || wget -q --show-progress "${BASE_URL}/${SHA_FILE}" || log_error "Failed to download checksum"

log_info "Verifying package integrity"
sha512sum -c "$SHA_FILE" || log_error "Checksum verification failed"

log_info "Installing Elasticsearch"
log_warning "Save the password from install output if shown!"
sudo rpm --install "$RPM_FILE" || log_error "Installation failed"

log_info "Enabling Elasticsearch service"
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

# Configure elasticsearch.yml
log_info "Configuring elasticsearch.yml for cluster node"
ES_YML="/etc/elasticsearch/elasticsearch.yml"
sudo cp "$ES_YML" "${ES_YML}.bak"

sudo sed -i "s/#cluster.name: my-application/cluster.name: ${CLUSTER_NAME}/" "$ES_YML"
sudo sed -i "s/#node.name: node-1/node.name: ${NODE_NAME}/" "$ES_YML"
sudo sed -i "s/#network.host: 192.168.0.1/network.host: ${NETWORK_HOST}/" "$ES_YML"
sudo sed -i "s/#http.port: 9200/http.port: ${HTTP_PORT}/" "$ES_YML"

sudo sed -i 's/xpack.security.enabled: true/xpack.security.enabled: false/' "$ES_YML" 2>/dev/null || true
sudo grep -q "xpack.security.enabled" "$ES_YML" || echo "xpack.security.enabled: false" | sudo tee -a "$ES_YML"
sudo sed -i 's/xpack.security.enrollment.enabled: true/xpack.security.enrollment.enabled: false/' "$ES_YML" 2>/dev/null || true
sudo grep -q "xpack.security.enrollment.enabled" "$ES_YML" || echo "xpack.security.enrollment.enabled: false" | sudo tee -a "$ES_YML"

sudo sed -i 's/#transport.host: 0.0.0.0/transport.host: 0.0.0.0/' "$ES_YML"

# Cluster discovery - point to master and other nodes
log_info "Configuring cluster discovery"
SEED_HOSTS="\"${MASTER_IP}\""
[ -n "$NODE_2_IP" ] && SEED_HOSTS="${SEED_HOSTS}, \"${NODE_2_IP}\""
[ -n "$NODE_3_IP" ] && SEED_HOSTS="${SEED_HOSTS}, \"${NODE_3_IP}\""

sudo sed -i '/discovery.seed_hosts/d' "$ES_YML" 2>/dev/null || true
echo "discovery.seed_hosts: [${SEED_HOSTS}]" | sudo tee -a "$ES_YML"

sudo sed -i '/cluster.initial_master_nodes/d' "$ES_YML" 2>/dev/null || true
echo "cluster.initial_master_nodes: [\"node-1\", \"node-2\", \"node-3\"]" | sudo tee -a "$ES_YML"

log_info "Starting Elasticsearch"
sudo systemctl start elasticsearch.service

log_info "Waiting for Elasticsearch to start (30s)..."
sleep 30

log_info "Verifying Elasticsearch"
if curl -s "http://localhost:${HTTP_PORT}" > /dev/null 2>&1; then
    log_success "Node ${NODE_NUM} is running!"
    curl -s "http://localhost:${HTTP_PORT}"
else
    log_warning "Check status: sudo systemctl status elasticsearch"
fi

echo ""
log_success "Node ${NODE_NUM} installation complete!"
