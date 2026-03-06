#!/bin/bash
# Kibana Installation Script
# Install Kibana to visualize Elasticsearch data

set -e

ELASTIC_VERSION="9.1.2"
INSTALL_DIR="kibana-install-files"
ELASTICSEARCH_HOST="${ELASTICSEARCH_HOST:-localhost}"
ELASTICSEARCH_PORT="${ELASTICSEARCH_PORT:-9200}"
KIBANA_HOST="${KIBANA_HOST:-0.0.0.0}"
KIBANA_PORT="${KIBANA_PORT:-5601}"

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

RPM_FILE="kibana-${ELASTIC_VERSION}-x86_64.rpm"
SHA_FILE="${RPM_FILE}.sha512"
BASE_URL="https://artifacts.elastic.co/downloads/kibana"

log_info "Kibana Installation"
echo "========================================"

# Detect OS and basic requirements
detect_os

if [ "$PKG_TYPE" != "rpm" ]; then
    log_error "This script currently supports RPM-based Linux distributions (RHEL/CentOS/Rocky/OL/Fedora). For Debian/Ubuntu, please use the official .deb installation steps from Elastic."
fi

ensure_command "wget" "wget"
ensure_command "sha512sum" "coreutils"

# Step 1-2: Create and enter directory
log_info "Creating directory ${INSTALL_DIR}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Step 3: Download
log_info "Downloading Kibana ${ELASTIC_VERSION}"
[ -f "$RPM_FILE" ] || wget -q --show-progress "${BASE_URL}/${RPM_FILE}" || log_error "Failed to download RPM"
[ -f "$SHA_FILE" ] || wget -q --show-progress "${BASE_URL}/${SHA_FILE}" || log_error "Failed to download checksum"

# Step 4: Verify
log_info "Verifying package integrity"
sha512sum -c "$SHA_FILE" || log_error "Checksum verification failed"

# Step 5: Install
log_info "Installing Kibana"
sudo rpm --install "$RPM_FILE" || log_error "Installation failed"

# Step 6: Enable service
log_info "Enabling Kibana service"
sudo systemctl daemon-reload
sudo systemctl enable kibana.service

# Step 7: Configure kibana.yml
log_info "Configuring Kibana"
KIBANA_YML="/etc/kibana/kibana.yml"
sudo cp "$KIBANA_YML" "${KIBANA_YML}.bak"

# Set Elasticsearch URL
sudo sed -i "s|#elasticsearch.hosts: \[\"http://localhost:9200\"\]|elasticsearch.hosts: [\"http://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}\"]|" "$KIBANA_YML"
sudo grep -q "elasticsearch.hosts" "$KIBANA_YML" || echo "elasticsearch.hosts: [\"http://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}\"]" | sudo tee -a "$KIBANA_YML"

# Server config
sudo sed -i "s/#server.port: 5601/server.port: ${KIBANA_PORT}/" "$KIBANA_YML"
sudo sed -i "s/#server.host: \"localhost\"/server.host: \"${KIBANA_HOST}\"/" "$KIBANA_YML"

# Step 8: Start Kibana
log_info "Starting Kibana"
sudo systemctl start kibana.service

log_info "Waiting for Kibana to start (30s)..."
sleep 30

# Step 9: Verify
log_info "Checking Kibana status"
if systemctl is-active --quiet kibana; then
    log_success "Kibana is running!"
    sudo systemctl status kibana --no-pager
else
    log_warning "Check: sudo systemctl status kibana"
    log_info "Logs: sudo journalctl -u kibana -f"
fi

echo ""
log_success "Kibana installation complete!"
log_info "Access Kibana: http://<this-host>:${KIBANA_PORT}"
log_info "Check status output for verification URL and code"
