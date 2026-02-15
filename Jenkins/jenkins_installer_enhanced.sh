#!/bin/bash

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JENKINS_VERSION="2.440.3"
JENKINS_DEB="jenkins_${JENKINS_VERSION}_all.deb"
JENKINS_URL="https://pkg.jenkins.io/debian-stable/binary/${JENKINS_DEB}"
JENKINS_HOME="/var/lib/jenkins"
JENKINS_SECRETS="${JENKINS_HOME}/secrets/initialAdminPassword"
MAX_WAIT_TIME=300  # 5 minutes timeout
WAIT_INTERVAL=10   # Check every 10 seconds

# Cleanup function
cleanup() {
    echo -e "${YELLOW}[INFO] Cleaning up...${NC}"
    if [ -f "${JENKINS_DEB}" ]; then
        rm -f "${JENKINS_DEB}"
        echo -e "${GREEN}[OK] Cleaned up downloaded file${NC}"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Error handler
error_exit() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

# Log function
log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Log success
log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Log warning
log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Main installation
main() {
    log_info "Starting Jenkins installation process"
    
    echo ""
    echo "===================================="
    echo " Jenkins Direct Package Installer "
    echo "===================================="
    echo ""
    
    # Check if running as root or with sudo
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo"
    fi
    
    # Update package manager
    log_info "Updating package manager..."
    apt-get update -y || error_exit "Failed to update package manager"
    log_success "Package manager updated"
    
    # Install dependencies
    log_info "Installing dependencies (Java 17 JDK and wget)..."
    apt-get install -y openjdk-17-jdk wget || error_exit "Failed to install dependencies"
    log_success "Dependencies installed"
    
    # Verify Java installation
    log_info "Verifying Java installation..."
    if ! command -v java &> /dev/null; then
        error_exit "Java installation failed"
    fi
    
    echo -e "${BLUE}[INFO] Java Version:${NC}"
    java -version
    echo ""
    
    # Check if Jenkins is already installed
    if systemctl is-active --quiet jenkins 2>/dev/null; then
        log_warning "Jenkins is already installed and running"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping installation"
            return 0
        fi
        log_info "Stopping existing Jenkins service..."
        systemctl stop jenkins || true
    fi
    
    # Download Jenkins package
    log_info "Downloading Jenkins ${JENKINS_VERSION}..."
    if [ -f "${JENKINS_DEB}" ]; then
        log_info "Jenkins package already exists locally, skipping download"
    else
        if ! wget -q --show-progress "${JENKINS_URL}" -O "${JENKINS_DEB}"; then
            error_exit "Failed to download Jenkins from ${JENKINS_URL}"
        fi
    fi
    log_success "Jenkins package downloaded"
    
    # Verify downloaded file
    if [ ! -f "${JENKINS_DEB}" ]; then
        error_exit "Jenkins package file not found after download"
    fi
    
    # Install Jenkins package
    log_info "Installing Jenkins package..."
    if ! dpkg -i "${JENKINS_DEB}"; then
        log_warning "dpkg installation had issues, fixing dependencies..."
        apt-get install -f -y || error_exit "Failed to fix dependencies"
    fi
    log_success "Jenkins package installed"
    
    # Start Jenkins service
    log_info "Enabling and starting Jenkins service..."
    systemctl enable jenkins || error_exit "Failed to enable Jenkins service"
    systemctl start jenkins || error_exit "Failed to start Jenkins service"
    log_success "Jenkins service started"
    
    # Wait for Jenkins to be ready
    log_info "Waiting for Jenkins to initialize (max ${MAX_WAIT_TIME} seconds)..."
    elapsed=0
    while [ ! -f "${JENKINS_SECRETS}" ] && [ $elapsed -lt $MAX_WAIT_TIME ]; do
        sleep $WAIT_INTERVAL
        elapsed=$((elapsed + WAIT_INTERVAL))
        echo -ne "${BLUE}[INFO] Waiting... ${elapsed}s${NC}\r"
    done
    echo ""
    
    # Check service status
    log_info "Checking Jenkins service status..."
    if systemctl is-active --quiet jenkins; then
        log_success "Jenkins service is running"
    else
        error_exit "Jenkins service failed to start"
    fi
    
    systemctl status jenkins --no-pager
    echo ""
    
    # Get IP address
    IP=$(hostname -I | awk '{print $1}')
    if [ -z "$IP" ]; then
        log_warning "Could not determine IP address, using localhost"
        IP="localhost"
    fi
    
    # Display success message
    echo ""
    echo "===================================="
    echo " Jenkins Installed Successfully! "
    echo "===================================="
    echo ""
    log_success "Jenkins is now running"
    echo -e "${BLUE}[INFO] Access URL: http://${IP}:8080${NC}"
    echo ""
    
    # Get and display initial admin password
    if [ -f "${JENKINS_SECRETS}" ]; then
        echo -e "${BLUE}[INFO] Initial Admin Password:${NC}"
        cat "${JENKINS_SECRETS}"
        echo ""
        echo -e "${YELLOW}[WARNING] Save this password securely!${NC}"
    else
        log_warning "Initial admin password file not found yet"
        echo -e "${YELLOW}[INFO] Jenkins may still be initializing. Try running:${NC}"
        echo -e "${YELLOW}    sudo cat ${JENKINS_SECRETS}${NC}"
    fi
    
    echo ""
    log_success "Installation complete!"
}

# Run main function
main
