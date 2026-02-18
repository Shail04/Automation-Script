#!/bin/bash

########################################################
# Kafka 4.0 Complete Uninstall Script
#
# Usage:
# bash kafka4_uninstall.sh
#
# This will completely remove Kafka and data.
########################################################

set -e

INSTALL_DIR="/opt/kafka"
DATA_DIR="/data/kafka"
SERVICE_FILE="/etc/systemd/system/kafka.service"

echo "=========================================="
echo "WARNING: This will completely remove Kafka"
echo "=========================================="
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

##########################################
# STOP KAFKA SERVICE
##########################################

if systemctl is-active --quiet kafka; then
    echo "Stopping Kafka service..."
    sudo systemctl stop kafka
fi

##########################################
# DISABLE SERVICE
##########################################

if systemctl is-enabled --quiet kafka; then
    echo "Disabling Kafka service..."
    sudo systemctl disable kafka
fi

##########################################
# REMOVE SYSTEMD SERVICE FILE
##########################################

if [ -f "$SERVICE_FILE" ]; then
    echo "Removing systemd service file..."
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload
fi

##########################################
# REMOVE KAFKA INSTALLATION
##########################################

if [ -d "$INSTALL_DIR" ]; then
    echo "Removing Kafka installation directory..."
    sudo rm -rf $INSTALL_DIR
fi

##########################################
# REMOVE DATA DIRECTORY
##########################################

if [ -d "$DATA_DIR" ]; then
    echo "Removing Kafka data directory..."
    sudo rm -rf $DATA_DIR
fi

##########################################
# REMOVE LOG FILES (OPTIONAL)
##########################################

if [ -d "/var/log/kafka" ]; then
    echo "Removing Kafka logs..."
    sudo rm -rf /var/log/kafka
fi

##########################################
# CLEAN TEMP FILES
##########################################

echo "Cleaning leftover temp files..."
sudo rm -rf /tmp/kafka-logs*

##########################################
# FINAL MESSAGE
##########################################

echo "=========================================="
echo "Kafka 4.0 has been completely removed."
echo "=========================================="
