#!/bin/bash

# Path to the source file
SOURCE_SCRIPT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/source-workspace-scripts.sh"

# Check if the source script exists
if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "Error: Source script '$SOURCE_SCRIPT' not found."
  exit 1
fi

# Detect the current shell
CURRENT_SHELL=$(basename "$SHELL")

# Determine the appropriate RC file based on the shell
if [[ "$CURRENT_SHELL" == "bash" ]]; then
  RC_FILE="$HOME/.bashrc"
elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
  RC_FILE="$HOME/.zshrc"
else
  echo "Unsupported shell: $CURRENT_SHELL. Please add the source command manually to your shell's RC file."
  exit 1
fi

# Add the source command to the RC file if not already present
if ! grep -Fxq "source $SOURCE_SCRIPT" "$RC_FILE"; then
  echo "Adding source command to $RC_FILE..."
  echo "" >> "$RC_FILE"
  echo "# Workspace environment" >> "$RC_FILE"
  echo "source $SOURCE_SCRIPT" >> "$RC_FILE"
  echo "Source command added successfully to $RC_FILE."
else
  echo "Source command is already present in $RC_FILE. Exiting..."
  exit 0
fi

# Verify that the alias 'workspace-details' is available
if alias workspace-details &>/dev/null; then
  echo "Setup completed successfully. You can now use the 'workspace-details' command."
else
  echo "Setup completed, but the 'workspace-details' alias could not be set. Check the source script for issues."
fi

echo "Re-sourcing RC file"
source $RC_FILE