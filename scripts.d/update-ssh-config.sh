#!/bin/bash

# Script to update SSH config with EC2 instance public IP
# Usage: ./update-ssh-config.sh

set -e  # Exit on error

# Function to list EC2 instances and get user choice
list_instances() {
  echo "Fetching EC2 instances..."
  echo ""
  
  # Get instances with better formatting
  aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name,Tags[?Key==`Name`].Value|[0]]' \
    --output table
  
  echo ""
  echo "Please enter the Instance ID of the EC2 instance you want to use:"
  read -p "Instance ID: " instance_id
  
  # Validate instance ID format
  if [[ ! $instance_id =~ ^i-[0-9a-f]{8,17}$ ]]; then
    echo "Error: Invalid instance ID format. Should be like 'i-0123456789abcdef0'"
    exit 1
  fi
  
  # Get the public IP of the chosen instance
  echo "Getting public IP for instance $instance_id..."
  public_ip=$(aws ec2 describe-instances --instance-ids $instance_id \
    --query 'Reservations[*].Instances[*].PublicIpAddress' --output text 2>/dev/null)
  
  if [ -z "$public_ip" ] || [ "$public_ip" = "None" ]; then
    echo "Error: Could not get public IP for instance $instance_id. Instance may not exist or may not have a public IP."
    exit 1
  fi
  
  echo "Found public IP: $public_ip"
}

# Function to update SSH config
update_ssh_config() {
  ssh_config="$HOME/.ssh/config"
  
  # Check if SSH config file exists
  if [ ! -f "$ssh_config" ]; then
    echo "Error: SSH config file not found at $ssh_config"
    exit 1
  fi
  
  echo ""
  echo "Current SSH config entries:"
  echo "-------------------------"
  grep "^Host " "$ssh_config" | sed 's/Host //'
  
  echo ""
  echo "Enter the name of the SSH config entry you want to update:"
  read -p "SSH Host entry: " ssh_entry
  
  # Check if the SSH entry exists
  if ! grep -q "^Host $ssh_entry$" "$ssh_config"; then
    echo "Error: SSH Host entry '$ssh_entry' not found in config file."
    exit 1
  fi
  
  # Backup the original config
  cp "$ssh_config" "$ssh_config.backup.$(date +%Y%m%d_%H%M%S)"
  echo "Backup created: $ssh_config.backup.$(date +%Y%m%d_%H%M%S)"
  
  # Replace the HostName entry with the new IP
  # This sed command finds the Host entry and replaces the HostName in that block
  if sed -i '' "/^Host $ssh_entry$/,/^Host /{ /^Host $ssh_entry$/n; /^Host /!s/^[[:space:]]*HostName .*/    HostName $public_ip/; }" "$ssh_config"; then
    echo "Successfully updated SSH config entry '$ssh_entry' to use IP $public_ip"
  else
    echo "Error: Failed to update SSH config"
    exit 1
  fi
  
  echo ""
  echo "You can now connect using: ssh $ssh_entry"
}

# Main script execution
echo "=== EC2 SSH Config Updater ==="
echo ""
list_instances
update_ssh_config
echo ""
echo "Done!"
