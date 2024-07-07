#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
if ! command_exists git; then
    print_color "$RED" "Error: git is not installed. Please install it and try again."
    exit 1
fi

# Set up variables
REPO_URL="https://github.com/bash-my-aws/keycutter.git"
DEFAULT_INSTALL_DIR="$HOME/.local/share/keycutter"
CONFIG_DIR="$HOME/.ssh/keycutter"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"

# Function to perform the installation
do_install() {
    local install_dir="$1"
    local bin_dir="$install_dir/bin"

    # Create necessary directories
    mkdir -p "$install_dir" "$CONFIG_DIR"

    # Copy configuration files
    print_color "$GREEN" "Copying configuration files..."
    cp -r "$install_dir/config/keycutter"/* "$CONFIG_DIR/"

    # Set up sshd configuration (requires sudo)
    if [ -d "$SSHD_CONFIG_DIR" ]; then
        print_color "$YELLOW" "Setting up sshd configuration (requires sudo)..."
        sudo cp "$install_dir/config/etc/ssh/sshd_config.d/50-keycutter.conf" "$SSHD_CONFIG_DIR/"
        print_color "$YELLOW" "Please restart sshd service to apply changes."
    else
        print_color "$YELLOW" "sshd config directory not found. Skipping sshd configuration."
    fi

    # Create necessary subdirectories in CONFIG_DIR
    mkdir -p "$CONFIG_DIR/keys" "$CONFIG_DIR/scripts" "$CONFIG_DIR/hosts" "$CONFIG_DIR/agents/default"

    # Add bin_dir to PATH if not already present
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        print_color "$YELLOW" "Adding $bin_dir to PATH in your shell configuration file..."
        echo "export PATH=\"\$PATH:$bin_dir\"" >> "$HOME/.bashrc"
        print_color "$YELLOW" "Please run 'source ~/.bashrc' or start a new shell session to update your PATH."
    fi

    print_color "$GREEN" "Keycutter has been successfully installed!"
    print_color "$YELLOW" "Installation directory: $install_dir"
    print_color "$YELLOW" "Configuration directory: $CONFIG_DIR"
    print_color "$YELLOW" "Make sure to add your keys, scripts, and host configurations to the respective directories."
    print_color "$GREEN" "To get started, run 'keycutter --help' or check the documentation at $install_dir/docs/README.md"
}

# Check if we're running from within the cloned repo
if [ -f "./install.sh" ] && [ -d "./bin" ]; then
    print_color "$GREEN" "Running installation from local repository..."
    INSTALL_DIR="$(pwd)"
    do_install "$INSTALL_DIR"
else
    # We're not in the repo, so clone it first
    print_color "$GREEN" "Cloning keycutter repository..."
    git clone "$REPO_URL" "$DEFAULT_INSTALL_DIR"
    cd "$DEFAULT_INSTALL_DIR"
    do_install "$DEFAULT_INSTALL_DIR"
fi
