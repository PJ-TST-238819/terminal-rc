#!/usr/bin/env bash

# SSH Config Management CLI Tool Installation Script
# This script installs the CLI tool for system-wide access

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_CLI_SCRIPT="$SCRIPT_DIR/ssh-cli"
# Use user's local bin directory instead of system-wide
INSTALL_DIR="$HOME/.local/bin"
SYMLINK_NAME="ssh-cli"
SYMLINK_PATH="$INSTALL_DIR/$SYMLINK_NAME"

show_help() {
    cat << EOF
SSH Config Management CLI Tool Installer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help, -h          Show this help message
    --uninstall, -u     Uninstall the CLI tool
    --install-dir DIR   Custom installation directory (default: ~/.local/bin)
    --name NAME         Custom command name (default: ssh-cli)

EXAMPLES:
    # Install with defaults (to ~/.local/bin)
    $0

    # Install to custom directory
    $0 --install-dir ~/bin

    # Install with custom name
    $0 --name my-ssh-tool

    # Uninstall
    $0 --uninstall

REQUIREMENTS:
    - devbox must be installed
    - The ssh-cli script must be executable
    - ~/.local/bin should be in your PATH (added automatically if missing)
EOF
}

setup_project() {
    print_info "Setting up SSH Config Management CLI Tool in current directory..."
    
    # Ensure ssh-cli script is executable
    if [[ ! -f "$SSH_CLI_SCRIPT" ]]; then
        print_error "ssh-cli script not found at: $SSH_CLI_SCRIPT"
        exit 1
    fi
    
    if [[ ! -x "$SSH_CLI_SCRIPT" ]]; then
        print_info "Making ssh-cli script executable..."
        chmod +x "$SSH_CLI_SCRIPT"
    fi
    
    # Set up devbox environment if not already done
    print_info "Ensuring devbox environment is set up..."
    if [[ ! -d ".devbox" ]]; then
        print_warning "Devbox not initialized. Run 'devbox shell' first."
    fi
    
    # Install dependencies if uv.lock doesn't exist or is outdated
    if [[ ! -f "uv.lock" ]] || [[ "pyproject.toml" -nt "uv.lock" ]]; then
        print_info "Installing/updating Python dependencies..."
        devbox run install || {
            print_warning "Could not update dependencies automatically."
            print_info "Please run 'devbox shell' and then 'devbox run install'"
        }
    fi
    
    print_success "Project setup completed!"
}

install_cli() {
    print_info "Installing SSH Config Management CLI Tool to user bin directory..."

    # First setup the project in current directory
    setup_project

    # Create user bin directory if it doesn't exist
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_info "Creating user bin directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi

    # Remove existing symlink if it exists
    if [[ -L "$SYMLINK_PATH" ]]; then
        print_info "Removing existing symlink..."
        rm "$SYMLINK_PATH"
    elif [[ -f "$SYMLINK_PATH" ]]; then
        print_error "File exists at $SYMLINK_PATH but is not a symlink"
        print_info "Please remove it manually: rm $SYMLINK_PATH"
        exit 1
    fi

    # Create symlink to the ssh-cli script in the current directory
    print_info "Creating symlink: $SYMLINK_PATH -> $SSH_CLI_SCRIPT"
    ln -sf "$SSH_CLI_SCRIPT" "$SYMLINK_PATH"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_warning "$INSTALL_DIR is not in your PATH"
        print_info "Add this to your shell profile (.bashrc, .zshrc, etc.):"
        echo "    export PATH=\"$INSTALL_DIR:\$PATH\""
        print_info "Or run: echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.$(basename $SHELL)rc"
        print_info "Then reload your shell: source ~/.$(basename $SHELL)rc"
    fi

    # Verify installation
    if [[ -L "$SYMLINK_PATH" ]] && [[ -x "$SYMLINK_PATH" ]]; then
        print_success "Installation completed successfully!"
        print_info "You can now run: $SYMLINK_NAME"
        print_info "Or with full path: $SYMLINK_PATH"
        
        # Test the installation
        print_info "Testing installation..."
        "$SYMLINK_PATH" --version 2>/dev/null || {
            print_warning "Installation test failed - this may be due to PATH issues"
            print_info "Try running with full path: $SYMLINK_PATH --version"
        }
        print_success "Installation completed!"
    else
        print_error "Installation failed - symlink not created properly"
        exit 1
    fi
}

uninstall_cli() {
    print_info "Uninstalling SSH Config Management CLI Tool..."

    if [[ -L "$SYMLINK_PATH" ]]; then
        # Check if we have write access
        if [[ ! -w "$INSTALL_DIR" ]]; then
            print_warning "No write access to $INSTALL_DIR, using sudo..."
            SUDO_CMD="sudo"
        else
            SUDO_CMD=""
        fi

        print_info "Removing symlink: $SYMLINK_PATH"
        $SUDO_CMD rm "$SYMLINK_PATH"
        print_success "Uninstallation completed successfully!"
    elif [[ -f "$SYMLINK_PATH" ]]; then
        print_error "$SYMLINK_PATH exists but is not a symlink"
        print_info "Please remove it manually if needed"
        exit 1
    else
        print_warning "$SYMLINK_NAME is not installed in $INSTALL_DIR"
        exit 0
    fi
}

main() {
    local uninstall=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --uninstall|-u)
                uninstall=true
                shift
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                SYMLINK_PATH="$INSTALL_DIR/$SYMLINK_NAME"
                shift 2
                ;;
            --name)
                SYMLINK_NAME="$2"
                SYMLINK_PATH="$INSTALL_DIR/$SYMLINK_NAME"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check if devbox is available
    if ! command -v devbox >/dev/null 2>&1; then
        print_error "devbox is not installed or not in PATH"
        print_info "Please install devbox from: https://www.jetify.com/devbox"
        exit 1
    fi

    if $uninstall; then
        uninstall_cli
    else
        install_cli
    fi
}

main "$@"
