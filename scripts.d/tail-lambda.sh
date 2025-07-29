#!/bin/bash

# Tail logs from a selected AWS Lambda function using partial name match

# Fetch list of Lambda function names
echo "Fetching list of Lambda functions..."
FUNCTION_NAMES=$(aws lambda list-functions --query 'Functions[*].FunctionName' --output text)

if [ -z "$FUNCTION_NAMES" ]; then
  echo "Failed to retrieve Lambda functions. Ensure you're authenticated and in the correct region."
  exit 1
fi

# Ask user for partial match
read -rp "Enter part of the Lambda function name to tail: " PARTIAL_NAME

# Match the partial name
MATCHES=($(echo "$FUNCTION_NAMES" | tr '\t' '\n' | grep -i "$PARTIAL_NAME"))

# Handle the results
if [ ${#MATCHES[@]} -eq 0 ]; then
  echo "No functions matched '$PARTIAL_NAME'."
  exit 1
elif [ ${#MATCHES[@]} -eq 1 ]; then
  SELECTED_FUNCTION="${MATCHES[0]}"
  echo "Found one match: $SELECTED_FUNCTION"
else
  echo "Multiple matches found:"
  select SELECTED_FUNCTION in "${MATCHES[@]}"; do
    if [[ -n "$SELECTED_FUNCTION" ]]; then
      break
    fi
    echo "Invalid selection."
  done
fi

# Derive the log group name
LOG_GROUP="/aws/lambda/$SELECTED_FUNCTION"

# Tail the logs
echo "Tailing logs for: $SELECTED_FUNCTION"
aws logs tail "$LOG_GROUP" --follow --format short