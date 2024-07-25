#!/usr/bin/env bash
# set -euo pipefail XXX restore this later

# install.sh - keycutter curl-pipe-bash installer

echo "Not working yet!"

# Safe boilerplate install.sh script with thorough binary conflict checking
# Usage: curl -sSL https://raw.githubusercontent.com/bash-my-aws/keycutter/main/install.sh | bash
# Or: ./install.sh (when run from within the repository)

# Configuration
REPO_URL="https://github.com/bash-my-aws/keycutter.git"
REPO_NAME=$(basename "$REPO_URL" .git)
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
INSTALL_DIR="${XDG_DATA_HOME}/${REPO_NAME}"
BIN_DIR="${HOME}/.local/bin"

# Error handling
error() {
    echo "Error: $1" >&2
    exit 1
}

# Check if a directory is in PATH
is_in_path() {
    case ":${PATH}:" in
        *":$1:"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Check if a command exists and get its full path
command_path() {
    command -v "$1" 2>/dev/null
}

# Check if two files are identical
files_are_identical() {
    cmp -s "$1" "$2"
}

# Function to install dependencies
install_dependencies() {
    if command_path apt-get >/dev/null; then
        sudo apt-get update
        sudo apt-get install -y git curl
    elif command_path yum >/dev/null; then
        sudo yum install -y git curl
    elif command_path brew >/dev/null; then
        brew install git curl
    else
        error "Unable to install dependencies. Please install git and curl manually."
    fi
}

# Check if running locally or via curl
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ -d ".git" ]] && [[ "$(git config --get remote.origin.url)" == "$REPO_URL" ]]; then
        INSTALL_DIR="$PWD"
    else
        # Clone the repository
        if [[ ! -d "$INSTALL_DIR" ]]; then
            echo "Cloning repository to $INSTALL_DIR..."
            git clone "$REPO_URL" "$INSTALL_DIR" || error "Failed to clone repository"
        fi
    fi
else
    # Script is being run via curl, so we need to clone
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo "Cloning repository to $INSTALL_DIR..."
        git clone "$REPO_URL" "$INSTALL_DIR" || error "Failed to clone repository"
    fi
fi

# Change to the installation directory
cd "$INSTALL_DIR" || error "Failed to change to installation directory"

# Run keycutter install
echo "Running keycutter installation..."
bin/keycutter update-ssh-config || error "Failed to run keycutter install"

# Symlink binaries
echo "Symlinking binaries..."
mkdir -p "$BIN_DIR"
for file in "$INSTALL_DIR"/bin/*; do
    if [[ -f "$file" && -x "$file" ]]; then
        bin_name=$(basename "$file")
        existing_path=$(command_path "$bin_name")
        
        if [[ -z "$existing_path" ]]; then
            # Command doesn't exist, create symlink
            ln -sf "$file" "$BIN_DIR/$bin_name"
            echo "Symlinked: $bin_name"
        elif [[ "$existing_path" == "$BIN_DIR/$bin_name" ]]; then
            # Command exists in our BIN_DIR, check if it's the same file
            if files_are_identical "$file" "$existing_path"; then
                echo "Already symlinked and up to date: $bin_name"
            else
                echo "Updating symlink: $bin_name"
                ln -sf "$file" "$BIN_DIR/$bin_name"
            fi
        else
            # Command exists elsewhere
            if files_are_identical "$file" "$existing_path"; then
                echo "Identical command already exists: $bin_name (at $existing_path)"
            else
                echo "Warning: Different version of $bin_name already exists at $existing_path. Skipping."
            fi
        fi
    fi
done

echo "Installation complete!"

# Check if BIN_DIR is in PATH and provide appropriate guidance
if is_in_path "$BIN_DIR"; then
    echo "Great! $BIN_DIR is already in your PATH."
else
    echo "To use the installed binaries, add the following line to your shell configuration file (.bashrc, .zshrc, etc.):"
    echo "export PATH=\"$BIN_DIR:\$PATH\""
    echo "Then, restart your shell or run 'source ~/.bashrc' (or your respective shell config file)."
fi

# List the status of all binaries
echo "Status of binaries:"
for file in "$INSTALL_DIR"/bin/*; do
    bin_name=$(basename "$file")
    existing_path=$(command_path "$bin_name")
    
    if [[ -z "$existing_path" ]]; then
        echo "  $bin_name: Newly installed"
    elif [[ "$existing_path" == "$BIN_DIR/$bin_name" ]]; then
        if files_are_identical "$file" "$existing_path"; then
            echo "  $bin_name: Already installed and up to date"
        else
            echo "  $bin_name: Updated"
        fi
    else
        if files_are_identical "$file" "$existing_path"; then
            echo "  $bin_name: Identical version already exists at $existing_path"
        else
            echo "  $bin_name: Different version exists at $existing_path (not overwritten)"
        fi
    fi
done
