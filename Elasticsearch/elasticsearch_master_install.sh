#!/bin/bash
# Elasticsearch Master Node (Node 1) Installation Script
# For 3-node cluster setup - run this on the first node

set -e

# Configuration - Customize these
ELASTIC_VERSION="9.1.2"
INSTALL_DIR="elastic-install-files"
CLUSTER_NAME="${CLUSTER_NAME:-elastic-cluster}"
NODE_NAME="${NODE_NAME:-node-1}"
NETWORK_HOST="${NETWORK_HOST:-0.0.0.0}"
HTTP_PORT="${HTTP_PORT:-9200}"
NODE_2_IP="${NODE_2_IP:-}"
NODE_3_IP="${NODE_3_IP:-}"

# Colors
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

log_info "Elasticsearch Master Node (Node 1) Installation"
echo "========================================"

# Detect OS and basic requirements
detect_os

if [ "$PKG_TYPE" != "rpm" ]; then
    log_error "This script currently supports RPM-based Linux distributions (RHEL/CentOS/Rocky/OL/Fedora). For Debian/Ubuntu, please use the official .deb installation steps from Elastic."
fi

ensure_command "wget" "wget"
ensure_command "sha512sum" "coreutils"

# Step 1: Create directory
log_info "Step 1: Creating directory ${INSTALL_DIR}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Step 2 & 3: Download RPM and checksum
log_info "Step 2-3: Downloading Elasticsearch ${ELASTIC_VERSION}"
[ -f "$RPM_FILE" ] || wget -q --show-progress "${BASE_URL}/${RPM_FILE}" || log_error "Failed to download RPM"
[ -f "$SHA_FILE" ] || wget -q --show-progress "${BASE_URL}/${SHA_FILE}" || log_error "Failed to download checksum"

# Step 4: Verify checksum
log_info "Step 4: Verifying package integrity"
sha512sum -c "$SHA_FILE" || log_error "Checksum verification failed"
log_success "Package verified"

# Step 5: Install
log_info "Step 5: Installing Elasticsearch"
log_warning "Save the password from the install output - you will need it!"
sudo rpm --install "$RPM_FILE" || log_error "Installation failed"

# Step 6: Daemon and enable
log_info "Step 6: Enabling Elasticsearch service"
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

# Configure elasticsearch.yml
log_info "Step 6b: Configuring elasticsearch.yml"
ES_YML="/etc/elasticsearch/elasticsearch.yml"
sudo cp "$ES_YML" "${ES_YML}.bak"

# Cluster and node
sudo sed -i "s/#cluster.name: my-application/cluster.name: ${CLUSTER_NAME}/" "$ES_YML"
sudo sed -i "s/#node.name: node-1/node.name: ${NODE_NAME}/" "$ES_YML"

# Network
sudo sed -i "s/#network.host: 192.168.0.1/network.host: ${NETWORK_HOST}/" "$ES_YML"
sudo sed -i "s/#http.port: 9200/http.port: ${HTTP_PORT}/" "$ES_YML"

# Security (disabled for simplified setup)
sudo grep -q "xpack.security.enabled" "$ES_YML" || echo "xpack.security.enabled: false" | sudo tee -a "$ES_YML"
sudo sed -i 's/xpack.security.enabled: true/xpack.security.enabled: false/' "$ES_YML" 2>/dev/null || true

sudo grep -q "xpack.security.enrollment.enabled" "$ES_YML" || echo "xpack.security.enrollment.enabled: false" | sudo tee -a "$ES_YML"
sudo sed -i 's/xpack.security.enrollment.enabled: true/xpack.security.enrollment.enabled: false/' "$ES_YML" 2>/dev/null || true

# Transport
sudo sed -i 's/#transport.host: 0.0.0.0/transport.host: 0.0.0.0/' "$ES_YML"

# 3-node cluster discovery (if node IPs provided)
if [ -n "$NODE_2_IP" ] && [ -n "$NODE_3_IP" ]; then
    log_info "Configuring 3-node cluster discovery"
    NODE_1_IP="${NODE_1_IP:-$(hostname -I | awk '{print $1}')}"
    sudo sed -i '/^discovery.seed_hosts/d' "$ES_YML" 2>/dev/null || true
    echo "discovery.seed_hosts: [\"${NODE_1_IP}\", \"${NODE_2_IP}\", \"${NODE_3_IP}\"]" | sudo tee -a "$ES_YML"
    sudo sed -i '/^cluster.initial_master_nodes/d' "$ES_YML" 2>/dev/null || true
    echo "cluster.initial_master_nodes: [\"node-1\", \"node-2\", \"node-3\"]" | sudo tee -a "$ES_YML"
fi

# Step 7: Start service
log_info "Step 7: Starting Elasticsearch"
sudo systemctl start elasticsearch.service

# Wait for startup
log_info "Waiting for Elasticsearch to start (30s)..."
sleep 30

# Step 8: Verify
log_info "Step 8: Verifying Elasticsearch is running"
if curl -s "http://localhost:${HTTP_PORT}" > /dev/null 2>&1; then
    log_success "Elasticsearch is running!"
    curl -s "http://localhost:${HTTP_PORT}"
else
    log_warning "Elasticsearch may still be starting. Check: curl http://localhost:${HTTP_PORT}"
fi

echo ""
log_success "Master node installation complete!"
log_info "Access: http://${NETWORK_HOST}:${HTTP_PORT}"
log_info "For 3-node cluster, run elasticsearch_node_install.sh on nodes 2 and 3"
