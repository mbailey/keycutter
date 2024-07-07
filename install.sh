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

# Function to check version
check_version() {
    local current_version="$1"
    local required_version="$2"

    if [[ $(printf '%s\n' "$required_version" "$current_version" | sort -V | head -n1) == "$required_version" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to check requirements
check_requirements() {
    local errors=0

    # Check Bash version
    bash_version=$(bash --version | head -n1 | awk '{print $4}')
    if [[ $(check_version "$bash_version" "4.0") == "false" ]]; then
        print_color "$YELLOW" "Bash version 4.0 or higher is required. Current version: $bash_version"
        errors=$((errors + 1))
    fi

    # Check Git version
    if command -v git &> /dev/null; then
        git_version=$(git --version | awk '{print $3}')
        if [[ $(check_version "$git_version" "2.34.0") == "false" ]]; then
            print_color "$YELLOW" "Git version 2.34.0 or higher is required. Current version: $git_version"
            errors=$((errors + 1))
        fi
    else
        print_color "$YELLOW" "Git is required but not installed."
        errors=$((errors + 1))
    fi

    # Check GitHub CLI version
    if command -v gh &> /dev/null; then
        gh_version=$(gh --version | head -n1 | awk '{print $3}')
        if [[ $(check_version "$gh_version" "2.4.0") == "false" ]]; then
            print_color "$YELLOW" "GitHub CLI version 2.4.0 or higher is required. Current version: $gh_version"
            errors=$((errors + 1))
        fi
    else
        print_color "$YELLOW" "GitHub CLI (gh) is required but not installed."
        errors=$((errors + 1))
    fi

    # Check OpenSSH version
    if command -v ssh &> /dev/null; then
        ssh_version=$(ssh -V 2>&1 | awk '{print $1}' | awk -F[_p] '{print $2}')
        if [[ $(check_version "$ssh_version" "8.2") == "false" ]]; then
            print_color "$YELLOW" "OpenSSH version 8.2p1 or higher is required. Current version: $ssh_version"
            errors=$((errors + 1))
        fi
    else
        print_color "$YELLOW" "OpenSSH is required but not installed."
        errors=$((errors + 1))
    fi

    # Check YubiKey Manager (ykman) version
    if command -v ykman &> /dev/null; then
        ykman_version=$(ykman --version | head -n1 | awk '{print $3}')
        if [[ $(check_version "$ykman_version" "0.0.0") == "false" ]]; then
            print_color "$YELLOW" "YubiKey Manager (ykman) is required. Current version: $ykman_version"
            errors=$((errors + 1))
        fi
    else
        print_color "$YELLOW" "YubiKey Manager (ykman) is required but not installed."
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        print_color "$RED" "Some requirements are not met. Please install or update the required tools."
        return 1
    else
        print_color "$GREEN" "All requirements are met."
        return 0
    fi
}

# Function to show diff and ask for confirmation
show_diff_and_confirm() {
    local source_file="$1"
    local dest_file="$2"
    
    if [[ -f "$dest_file" ]]; then
        if diff -q "$source_file" "$dest_file" >/dev/null; then
            # Files are identical, silently continue
            return 0
        else
            print_color "$YELLOW" "The file $dest_file already exists and is different. Here's the diff:"
            diff -u "$dest_file" "$source_file" || true
            read -p "Do you want to overwrite this file? [Y/n] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                return 1
            fi
        fi
    else
        print_color "$GREEN" "Creating new file: $dest_file"
    fi
    return 0
}

# Function to copy files and directories recursively
copy_with_confirmation() {
    local source="$1"
    local dest="$2"

    if [ -d "$source" ]; then
        # It's a directory
        if [ ! -d "$dest" ]; then
            print_color "$GREEN" "Creating new directory: $dest"
            mkdir -p "$dest"
        fi
        for item in "$source"/*; do
            local item_name=$(basename "$item")
            copy_with_confirmation "$item" "$dest/$item_name"
        done
    else
        # It's a file
        if [ -f "$dest" ]; then
            if show_diff_and_confirm "$source" "$dest"; then
                cp "$source" "$dest"
            fi
        else
            print_color "$GREEN" "Creating new file: $dest"
            cp "$source" "$dest"
        fi
    fi
}

# Function to copy files and directories recursively
copy_with_confirmation() {
    local source="$1"
    local dest="$2"

    if [ ! -e "$source" ]; then
        print_color "$YELLOW" "Warning: Source path does not exist: $source"
        return 0
    fi

    if [ -d "$source" ]; then
        # It's a directory
        if [ ! -d "$dest" ]; then
            print_color "$GREEN" "Creating new directory: $dest"
            mkdir -p "$dest"
        fi
        
        # Check if the directory is empty
        if [ -z "$(ls -A "$source")" ]; then
            print_color "$YELLOW" "Note: Directory is empty: $source"
            return 0
        fi

        for item in "$source"/*; do
            local item_name=$(basename "$item")
            copy_with_confirmation "$item" "$dest/$item_name"
        done
    else
        # It's a file
        if [ -f "$dest" ]; then
            if show_diff_and_confirm "$source" "$dest"; then
                cp "$source" "$dest"
            fi
        else
            print_color "$GREEN" "Creating new file: $dest"
            cp "$source" "$dest"
        fi
    fi
}

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
    copy_with_confirmation "$install_dir/config/keycutter" "$CONFIG_DIR"

    # Set up sshd configuration (requires sudo)
    if [ -d "$SSHD_CONFIG_DIR" ]; then
        print_color "$YELLOW" "SSHD Configuration:"
        echo "Keycutter can update your sshd_config to accept environment variables starting with KEYCUTTER_."
        echo "This allows passing Keycutter-specific environment variables to the SSH server."
        echo "However, this may have security implications if not properly managed."
        read -p "Do you want to update sshd_config to AcceptEnv KEYCUTTER_*? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Updating sshd configuration (requires sudo)..."
            source_file="$install_dir/config/etc/ssh/sshd_config.d/50-keycutter.conf"
            dest_file="$SSHD_CONFIG_DIR/50-keycutter.conf"
            if show_diff_and_confirm "$source_file" "$dest_file"; then
                sudo cp "$source_file" "$dest_file"
                print_color "$YELLOW" "Please restart sshd service to apply changes."
            fi
        else
            print_color "$GREEN" "Skipping sshd configuration update."
        fi
    else
        print_color "$YELLOW" "sshd config directory not found. Skipping sshd configuration."
    fi

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

# Check requirements before proceeding
if ! check_requirements; then
    print_color "$RED" "Please install or update the required tools and try again."
    exit 1
fi

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
