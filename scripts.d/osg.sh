#!/bin/bash

# This is a script to be turned into an alias for adding your current IP to the security groups
# on AWS so that you can access the resources.

# Retrieve the latest public IP address
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
if [ -z "$PUBLIC_IP" ]; then
  echo "Failed to retrieve public IP address."
  exit 1
fi
echo "Your public IP address is: $PUBLIC_IP"

# Define the list of security group rule IDs to update
RULE_IDS=("sgr-029111b2b23cd6114" "sgr-0a6a82e6a59e3f1c2")

# Define the desired description
DESCRIPTION="Jaak-Remote"

# Loop through each rule ID to update
for RULE_ID in "${RULE_IDS[@]}"; do
  # Retrieve the associated security group ID
  GROUP_ID=$(aws ec2 describe-security-group-rules --filter "Name=security-group-rule-id,Values=$RULE_ID" --query "SecurityGroupRules[0].GroupId" --output text)

  if [ -z "$GROUP_ID" ]; then
    echo "Failed to retrieve group ID for rule $RULE_ID."
    continue
  fi

  # Update the security group rule with the new IP and description
  aws ec2 modify-security-group-rules \
    --group-id "$GROUP_ID" \
    --security-group-rules \
    "[
      {
        \"SecurityGroupRuleId\": \"$RULE_ID\",
        \"SecurityGroupRule\": {
          \"CidrIpv4\": \"$PUBLIC_IP/32\",
          \"IpProtocol\": \"-1\",
          \"Description\": \"$DESCRIPTION\"
        }
      }
    ]"

  # Check if the update was successful
  if [ $? -eq 0 ]; then
    echo "Security group rule $RULE_ID successfully updated with IP $PUBLIC_IP and description '$DESCRIPTION'."
  else
    echo "Failed to update security group rule $RULE_ID."
  fi
done
