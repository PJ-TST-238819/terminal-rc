#!/bin/bash

# Directory containing the shell scripts
WORKSPACE_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/workspace.d"
SCRIPTS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/scripts.d"

# Exports the SCRIPTS_DIR variable to be used in the workspace.d aliases
export SCRIPTS_DIR=${SCRIPTS_DIR}

# Temporary file to store the list of sourced scripts
SOURCED_LIST_FILE="/tmp/sourced_scripts.txt"

# Clear the sourced list file
> "$SOURCED_LIST_FILE"

# Check if the directory exists
if [[ ! -d "$WORKSPACE_DIR" ]]; then
  echo "Directory '$WORKSPACE_DIR' does not exist. Returning."
  return 1
fi

# Get the list of .sh files and count them
scripts=("$WORKSPACE_DIR"/*.sh)
total_scripts=${#scripts[@]}
sourced_count=0

# Check if there are any scripts to source
if [[ $total_scripts -eq 0 ]]; then
  echo "No .sh files found in '$WORKSPACE_DIR'. Returning."
  return 0
fi

# Source each file and display progress
for script in "${scripts[@]}"; do
  if [[ -f "$script" ]]; then
    # Source the script
    # shellcheck disable=SC1090
    source "$script"
    # Record the sourced script
    echo "$script" >> "$SOURCED_LIST_FILE"
    # Update and display progress
    ((sourced_count++))
    echo "Sourced $sourced_count/$total_scripts: $script"
  fi
done

# Create an alias to list sourced scripts
alias workspace-details="cat $SOURCED_LIST_FILE"

echo "All scripts sourced successfully."
echo "Use the 'workspace-details' command to view the sourced files."
