#!/bin/bash

set -e

echo "=================================="
echo " Jenkins Direct Package Installer "
echo "=================================="

# Install dependencies
sudo apt update -y
sudo apt install -y openjdk-17-jdk wget

echo "[INFO] Java Version:"
java -version

# Download latest Jenkins LTS package
echo "[INFO] Downloading Jenkins..."

wget https://pkg.jenkins.io/debian-stable/binary/jenkins_2.440.3_all.deb

# Install Jenkins
echo "[INFO] Installing Jenkins package..."
sudo dpkg -i jenkins_2.440.3_all.deb || sudo apt -f install -y

# Start Jenkins
echo "[INFO] Starting Jenkins..."
sudo systemctl enable jenkins
sudo systemctl start jenkins

sleep 5

# Check service
sudo systemctl status jenkins --no-pager

# Show access info
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=================================="
echo " Jenkins Installed Successfully "
echo "=================================="
echo "Access URL: http://$IP:8080"
echo ""
echo "Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
