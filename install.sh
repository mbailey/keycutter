#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/mbailey/keycutter.git"
COMMAND_NAME="keycutter"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/$COMMAND_NAME"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  if [[ "$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null)" != "$REPO_URL" ]]; then
    echo "Error: $INSTALL_DIR contains a different git repository." >&2
    exit 1
  fi
  echo "Updating existing repository..."
  git -C "$INSTALL_DIR" pull --quiet
else
  echo "Cloning repository..."
  git clone --quiet "$REPO_URL" "$INSTALL_DIR"
fi

mkdir -p "$BIN_DIR"
ln -sf "${INSTALL_DIR}/bin/${COMMAND_NAME}" "$BIN_DIR/$COMMAND_NAME"

# Install bash completion if the user has a completions directory
if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions" ]]; then
  ln -sf "${INSTALL_DIR}/shell/completions/${COMMAND_NAME}.bash" \
         "${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/$COMMAND_NAME"
  echo "Bash completion installed. You may need to restart your shell or source your profile."
elif [[ -d "/etc/bash_completion.d" && -w "/etc/bash_completion.d" ]]; then
  sudo ln -sf "${INSTALL_DIR}/shell/completions/${COMMAND_NAME}.bash" \
              "/etc/bash_completion.d/$COMMAND_NAME"
  echo "Bash completion installed system-wide."
else
  echo "To enable bash completion, source the completion file in your shell profile:"
  echo "  echo 'source ${INSTALL_DIR}/shell/completions/${COMMAND_NAME}.bash' >> ~/.bashrc"
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "Warning: $BIN_DIR is not in your PATH. Add it to your shell configuration:" >&2
  echo "  echo 'export PATH=\"\$PATH:$BIN_DIR\"' >> ~/.bashrc  # or your shell's config" >&2
else
  # echo "Installation complete. Running '$COMMAND_NAME update'."
  keycutter update
fi

