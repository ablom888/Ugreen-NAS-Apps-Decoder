#!/bin/bash
# Enable strict error handling
set -e

# Define service name
SERVICE_NAME="ugminidlna.service"

# Define path to service unit file
FILE="/etc/systemd/system/$SERVICE_NAME"

# Stop the service if it's running
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Service is running, stopping..."
    systemctl stop "$SERVICE_NAME"
    echo "Service stopped"
fi

# Remove service file if it exists
if [[ -f "$FILE" ]]; then
    echo "Removing service file: $FILE"
    rm "$FILE"
    
    echo "Reloading systemd configuration..."
    systemctl daemon-reload
    echo "Configuration reloaded"
else
    echo "Service file does not exist, skipping removal"
fi

echo "Operation completed"