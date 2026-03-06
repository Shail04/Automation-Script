#!/bin/bash
# Logstash Installation Script
# Install and configure Logstash to ship data to Elasticsearch

set -e

ELASTIC_VERSION="9.1.2"
INSTALL_DIR="logstash-install-files"
ELASTICSEARCH_HOST="${ELASTICSEARCH_HOST:-localhost}"
ELASTICSEARCH_PORT="${ELASTICSEARCH_PORT:-9200}"

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

RPM_FILE="logstash-${ELASTIC_VERSION}-x86_64.rpm"
SHA_FILE="${RPM_FILE}.sha512"
BASE_URL="https://artifacts.elastic.co/downloads/logstash"

log_info "Logstash Installation"
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
log_info "Downloading Logstash ${ELASTIC_VERSION}"
[ -f "$RPM_FILE" ] || wget -q --show-progress "${BASE_URL}/${RPM_FILE}" || log_error "Failed to download RPM"
[ -f "$SHA_FILE" ] || wget -q --show-progress "${BASE_URL}/${SHA_FILE}" || log_error "Failed to download checksum"

# Step 4: Verify
log_info "Verifying package integrity"
sha512sum -c "$SHA_FILE" || log_error "Checksum verification failed"

# Step 5: Install
log_info "Installing Logstash"
sudo rpm --install "$RPM_FILE" || log_error "Installation failed"

# Step 6: Enable service
log_info "Enabling Logstash service"
sudo systemctl daemon-reload
sudo systemctl enable logstash.service

# Configure Logstash pipeline for Elasticsearch output
log_info "Creating sample pipeline configuration"
PIPELINE_DIR="/etc/logstash/conf.d"
PIPELINE_FILE="${PIPELINE_DIR}/elasticsearch_output.conf"

sudo mkdir -p "$PIPELINE_DIR"
sudo tee "$PIPELINE_FILE" > /dev/null << EOF
# Sample Logstash pipeline - sends stdin to Elasticsearch
input {
  stdin { }
}

filter {
  # Add custom filters here
}

output {
  elasticsearch {
    hosts => ["http://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
  stdout {
    codec => rubydebug
  }
}
EOF

log_success "Pipeline config created at ${PIPELINE_FILE}"

# Create pipelinelogs directory for keystore (avoids Logstash 8+ issues)
sudo mkdir -p /var/lib/logstash/pipelinelogs 2>/dev/null || true
sudo chown logstash:logstash /var/lib/logstash/pipelinelogs 2>/dev/null || true

log_info "Starting Logstash"
sudo systemctl start logstash.service 2>/dev/null || log_warning "Logstash may need pipeline config. Check: sudo systemctl status logstash"

log_info "Waiting for Logstash to start (15s)..."
sleep 15

# Verify
if systemctl is-active --quiet logstash 2>/dev/null; then
    log_success "Logstash is running!"
else
    log_warning "Check Logstash status: sudo systemctl status logstash"
    log_info "View logs: sudo journalctl -u logstash -f"
fi

echo ""
log_success "Logstash installation complete!"
log_info "Config directory: /etc/logstash/"
log_info "Pipeline configs: /etc/logstash/conf.d/"
log_info "Elasticsearch output: ${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}"
