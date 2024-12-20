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

# Check if the scripts directory exists
if [[ ! -d "$SCRIPTS_DIR" ]]; then
  echo "Directory '$SCRIPTS_DIR' does not exist. Returning."
  return 1
fi

# Get the list of .sh files and count them
scripts=("$SCRIPTS_DIR"/*.sh)
total_scripts=${#scripts[@]}
alias_count=0

# Check if there are any scripts to process
if [[ $total_scripts -eq 0 ]]; then
  echo "No .sh files found in '$SCRIPTS_DIR'. Returning."
  return 0
fi

# Process each script to create an alias
for script in "${scripts[@]}"; do
  if [[ -f "$script" ]]; then
    # Extract the base name of the script without the extension
    script_name="$(basename "$script" .sh)"
    # Create an alias for the script
    alias "$script_name"="bash $script"
    # Record the alias creation
    echo "Alias created: $script_name -> $script" >> "$SOURCED_LIST_FILE"
    # Update and display progress
    ((alias_count++))
    echo "Processed $alias_count/$total_scripts: $script_name"
  fi
done

# Create an alias to list created aliases
alias workspace-details="cat $SOURCED_LIST_FILE"

echo "All aliases created successfully."
echo "Use the 'workspace-details' command to view the created aliases."
