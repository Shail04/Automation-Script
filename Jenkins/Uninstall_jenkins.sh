#!/bin/bash

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Root check
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    exit 1
fi

echo ""
echo "======================================"
echo " Jenkins Complete Uninstall Script "
echo "======================================"
echo ""

# Confirmation
read -p "$(echo -e ${YELLOW}This will completely remove Jenkins. Continue? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Uninstall cancelled"
    exit 0
fi

echo ""

# Backup Jenkins configurations
BACKUP_DIR="/root/jenkins_backup_$(date +%Y%m%d_%H%M%S)"
if [ -d "/var/lib/jenkins" ]; then
    log_info "Backing up Jenkins configuration to ${BACKUP_DIR}..."
    mkdir -p "$BACKUP_DIR"
    cp -r /var/lib/jenkins "$BACKUP_DIR/" 2>/dev/null || log_warning "Could not backup Jenkins directory"
    log_success "Backup created at ${BACKUP_DIR}"
fi

echo ""

# Stop Jenkins service
log_info "Stopping Jenkins service..."
if systemctl is-active --quiet jenkins 2>/dev/null; then
    systemctl stop jenkins 2>/dev/null || log_warning "Could not stop Jenkins service"
    log_success "Jenkins service stopped"
else
    log_warning "Jenkins service is not running"
fi

# Disable service
log_info "Disabling Jenkins service..."
systemctl disable jenkins 2>/dev/null || log_warning "Could not disable Jenkins service"
log_success "Jenkins service disabled"

echo ""

# Detect OS and remove accordingly
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    log_error "Cannot detect OS"
    exit 1
fi

case "$OS" in
    ubuntu|debian)
        log_info "Detected: Ubuntu/Debian"
        log_info "Removing Jenkins package..."
        apt-get remove --purge -y jenkins 2>/dev/null || log_warning "Jenkins package not found or removal failed"
        
        log_info "Removing unused dependencies..."
        apt-get autoremove -y 2>/dev/null || true
        
        log_info "Cleaning apt cache..."
        apt-get clean 2>/dev/null || true
        ;;
    
    rhel|centos|fedora)
        log_info "Detected: RedHat/CentOS/Fedora"
        
        # Try dnf first (newer versions), then yum
        if command -v dnf &> /dev/null; then
            PM="dnf"
        else
            PM="yum"
        fi
        
        log_info "Removing Jenkins package with ${PM}..."
        $PM remove -y jenkins 2>/dev/null || log_warning "Jenkins package not found or removal failed"
        
        log_info "Cleaning ${PM} cache..."
        $PM clean all 2>/dev/null || true
        ;;
    
    *)
        log_warning "Unsupported OS: $OS"
        log_warning "Attempting manual removal..."
        ;;
esac

echo ""

# Remove Jenkins directories
log_info "Removing Jenkins directories..."
DIRS_TO_REMOVE=(
    "/var/lib/jenkins"
    "/var/log/jenkins"
    "/etc/jenkins"
    "/usr/share/jenkins"
    "/var/cache/jenkins"
    "/usr/lib/jenkins"
)

for dir in "${DIRS_TO_REMOVE[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir" && log_success "Removed: $dir" || log_warning "Could not remove: $dir"
    fi
done

echo ""

# Remove Jenkins user
if id "jenkins" &>/dev/null; then
    log_info "Removing Jenkins user and group..."
    userdel -r -f jenkins 2>/dev/null || log_warning "Could not remove Jenkins user"
    log_success "Jenkins user removed"
else
    log_warning "Jenkins user not found"
fi

echo ""

# Remove Jenkins repo entries
log_info "Removing Jenkins repositories..."

# Debian/Ubuntu repos
rm -f /etc/apt/sources.list.d/jenkins.list 2>/dev/null && log_success "Removed Jenkins APT repo" || true

# RedHat/CentOS repos
rm -f /etc/yum.repos.d/jenkins.repo 2>/dev/null && log_success "Removed Jenkins YUM repo" || true

echo ""

# Remove Jenkins keyrings
log_info "Removing Jenkins keyrings..."
rm -f /usr/share/keyrings/jenkins-keyring.* 2>/dev/null && log_success "Removed Jenkins keyrings" || true
rm -f /etc/apt/trusted.gpg.d/jenkins.* 2>/dev/null && log_success "Removed Jenkins GPG keys" || true

echo ""

# Remove downloaded packages
log_info "Cleaning downloaded Jenkins packages..."
rm -f jenkins_*.deb 2>/dev/null && log_success "Removed DEB packages" || true
rm -f jenkins-*.rpm 2>/dev/null && log_success "Removed RPM packages" || true
rm -f jenkins.war 2>/dev/null && log_success "Removed WAR file" || true

echo ""

# Reload systemctl daemon
log_info "Reloading systemctl daemon..."
systemctl daemon-reload 2>/dev/null || log_warning "Could not reload systemctl daemon"
log_success "Systemctl daemon reloaded"

echo ""
echo "======================================"
echo " Jenkins Uninstalled Successfully! "
echo "======================================"
echo ""
log_success "Jenkins has been completely removed"
log_info "Backup saved at: ${BACKUP_DIR}"
echo ""
