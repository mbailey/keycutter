#!/bin/bash
# Find the libfido2 formula commit history

# Navigate to homebrew-core
cd $(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-core

# Show recent commits for libfido2
echo "Recent libfido2 formula changes:"
git log --oneline -10 -- Formula/l/libfido2.rb

echo ""
echo "To see what changed in a specific commit:"
echo "git show [COMMIT_HASH] -- Formula/l/libfido2.rb"

echo ""
echo "To install from a specific commit:"
echo "brew uninstall --ignore-dependencies libfido2"
echo "brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/[COMMIT_HASH]/Formula/l/libfido2.rb"