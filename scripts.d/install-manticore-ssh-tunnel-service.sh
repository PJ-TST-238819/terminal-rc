#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# The path to the target file for the symbolic link
TARGET_SERVICE="$SCRIPT_DIR/../services/manticore-ssh-tunnel"
TUNNEL_SCRIPT="$SCRIPT_DIR/open-manticore-tunnels.sh"

# The location for the symbolic link to the service and executable
SYMLINK_PATH_SERVICE="/etc/systemd/system/manticore-ssh-tunnel.service"
SYMLINK_PATH_EXEC="/usr/local/bin/open-manticore-tunnels"

# Displaying a message for making the open-manticore-tunnels.sh file executable
echo "Making the open-manticore-tunnels.sh file executable."

# Granting execute permissions to the script
chmod +x "$TUNNEL_SCRIPT"

# Confirming that the file has been made executable
if [ -x "$TUNNEL_SCRIPT" ]; then
    echo "The open-manticore-tunnels.sh file is now executable."
else
    echo "Failed to make the open-manticore-tunnels.sh file executable."
    exit 1
fi

# Creating a symbolic link for the manticore-ssh-tunnel service
echo "Creating symbolic link from $TARGET_SERVICE to $SYMLINK_PATH_SERVICE."

sudo ln -sf "$TARGET_SERVICE" "$SYMLINK_PATH_SERVICE"

# Verify the symbolic link for the service
if [ -L "$SYMLINK_PATH_SERVICE" ]; then
    echo "Symbolic link for the service created successfully."
else
    echo "Failed to create symbolic link for the service."
    exit 1
fi

# Creating a symbolic link for the open-manticore-tunnels.sh script in /usr/local/bin
echo "Creating symbolic link from $TUNNEL_SCRIPT to $SYMLINK_PATH_EXEC."

sudo ln -sf "$TUNNEL_SCRIPT" "$SYMLINK_PATH_EXEC"

# Verify the symbolic link for the executable
if [ -L "$SYMLINK_PATH_EXEC" ]; then
    echo "Symbolic link for the executable created successfully."
else
    echo "Failed to create symbolic link for the executable."
    exit 1
fi

# Enabling and starting the systemd service
echo "Enabling and starting the manticore-ssh-tunnel service."

sudo systemctl enable manticore-ssh-tunnel.service
sudo systemctl start manticore-ssh-tunnel.service

# Reload the systemd daemon to recognize any changes
echo "Reloading systemd daemon."

sudo systemctl daemon-reload

# Restart the service to apply the new configuration
echo "Restarting the manticore-ssh-tunnel service."

sudo systemctl restart manticore-ssh-tunnel.service

# Verify the service status
if sudo systemctl is-active --quiet manticore-ssh-tunnel.service; then
    echo "Service is active and running."
else
    echo "Failed to start the manticore-ssh-tunnel service."
fi
