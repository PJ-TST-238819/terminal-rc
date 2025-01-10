#!/bin/bash

# Define variables
INSTANCE_ID="i-03548b6f8cfc00797"
SSH_CONFIG_FILE="$HOME/.ssh/config"
AWS_REGION="eu-west-1"
HOST_ENTRY="website.pre-prod"

# Fetch the public IPv4 address of the EC2 instance
IPV4_ADDRESS=$(
    aws ec2 describe-instances \
        --region eu-west-1 \
        --filters "Name=tag:Name,Values=*REMAX-Website-Pre-Prod-ASG*" \
        --query 'Reservations[*].Instances[*].PublicIpAddress' \
        --output text
)

# Check if the AWS CLI returned a valid IP address
if [[ -z "$IPV4_ADDRESS" || "$IPV4_ADDRESS" == "None" ]]; then
    echo "Error: Unable to fetch the public IPv4 address for instance $INSTANCE_ID"
    exit 1
fi

echo "Fetched IPv4 Address: $IPV4_ADDRESS"

# Update or add the HostName in the SSH config file
if grep -q "Host $HOST_ENTRY" "$SSH_CONFIG_FILE"; then
    # Update the existing HostName entry
    sed -i "/^Host $HOST_ENTRY$/,/^Host /{s/^\(\s*HostName\s\).*/\1$IPV4_ADDRESS/}" "$SSH_CONFIG_FILE"
    echo "Updated HostName for $HOST_ENTRY to $IPV4_ADDRESS in $SSH_CONFIG_FILE."
else
    # Add a new entry for the host
    {
        echo -e "\nHost $HOST_ENTRY"
        echo "    HostName $IPV4_ADDRESS"
    } >> "$SSH_CONFIG_FILE"
    echo "Added new Host entry for $HOST_ENTRY with HostName $IPV4_ADDRESS to $SSH_CONFIG_FILE."
fi
