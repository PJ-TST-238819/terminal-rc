# Path to the source file
SOURCE_SCRIPT="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/source-workspace-scripts.sh"

# Logging function to handle debug messages
log() {
  if [[ "${TERMINAL_RC_DEBUG}" == "1" ]]; then
    echo "$@"
  fi
}

# Check if the source script exists
if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  log "Error: Source script '$SOURCE_SCRIPT' not found."
  return 1
fi

# Detect the current shell
CURRENT_SHELL=$(basename "$SHELL")

# Determine the appropriate RC file based on the shell
if [[ "$CURRENT_SHELL" == "bash" ]]; then
  RC_FILE="$HOME/.bashrc"
elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
  RC_FILE="$HOME/.zshrc"
else
  log "Unsupported shell: $CURRENT_SHELL. Please add the source command manually to your shell's RC file."
  return 1
fi

# Add the source command to the RC file if not already present
if ! grep -Fxq "source $SOURCE_SCRIPT" "$RC_FILE"; then
  log "Adding source command to $RC_FILE..."
  echo "source $SOURCE_SCRIPT" >> "$RC_FILE"
  log "Source command added successfully to $RC_FILE."
else
  log "Source command is already present in $RC_FILE."
  return 0
fi

# Source the file immediately for the current session
log "Sourcing: $SOURCE_SCRIPT"
# shellcheck disable=SC1090
source "$SOURCE_SCRIPT"

# Verify that the alias 'workspace-details' is available
if alias workspace-details &>/dev/null; then
  log "Setup completed successfully. You can now use the 'workspace-details' command."
else
  log "Setup completed, but the 'workspace-details' alias could not be set. Check the source script for issues."
fi
