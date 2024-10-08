#!/usr/bin/env bash
set -euo pipefail


# Create a temporary directory for the example SSH configuration
TEMP_SSH_DIR=$(mktemp -d)

# Set HOME to the temporary directory for this script
export HOME="$TEMP_SSH_DIR"

# Create .ssh directory in the temporary HOME
mkdir -p "$HOME/.ssh"

# Install keycutter config files
keycutter update-ssh-config

# Run keycutter commands
keycutter create github.com_work-user@example-device
keycutter create github.com_personal-user@example-device

# Generate tree output
tree_output=$(tree -L 3 "$HOME/.ssh")

# Output the tree structure
echo "Example ~/.ssh directory structure:"
echo "$tree_output"

# Clean up
rm -rf "$TEMP_SSH_DIR"
