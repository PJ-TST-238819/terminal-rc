#!/bin/bash

# List EC2 instances with their public IP addresses, state, and names
# Usage: ./list-ec2-instances.sh

aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table
