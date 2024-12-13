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

echo "Adding your current IP to the right Security Groups on AWS."
# Get the directory of the current script
bash "$(dirname "$(realpath "$0")")/remax-sgs.sh"
# Check if the previous command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to run remax-sgs.sh."
    exit 1
fi

# Command to create the SSH tunnel
echo "Setting up the HTTP port to the RE/MAX Manticore API Layer on port $LOCAL_PORT"
# SSH command to create the tunnel
/usr/bin/ssh -L $LOCAL_PORT:localhost:$REMOTE_PORT $SSH_HOST
