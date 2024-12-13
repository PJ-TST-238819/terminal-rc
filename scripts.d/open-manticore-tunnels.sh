#!/bin/bash

# Define tunnel parameters
LOCAL_PORT=24180
REMOTE_PORT=80
SSH_HOST="manticore.new.1"
SSH_CONFIG_FILE="$HOME/.ssh/config"

# Check if the SSH configuration for manticore.new.1 exists
if ! grep -q "Host $SSH_HOST" "$SSH_CONFIG_FILE"; then
    echo "Error: The SSH configuration for $SSH_HOST is missing in $SSH_CONFIG_FILE."
    echo "Please add the configuration for $SSH_HOST to your SSH config file."
    exit 1
fi

# Command to create the SSH tunnel
echo "Setting up the HTTP port to the RE/MAX Manticore API Layer on port $LOCAL_PORT"
# SSH command to create the tunnel
/usr/bin/ssh -L $LOCAL_PORT:localhost:$REMOTE_PORT $SSH_HOST
