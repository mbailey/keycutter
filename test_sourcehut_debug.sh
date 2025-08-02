#!/bin/bash
# Debug script for Sourcehut tests

# Set up environment like the tests do
export TEST_HOME="/tmp/keycutter_test_debug"
export HOME="$TEST_HOME"
export KEYCUTTER_ROOT="$(pwd)"
export KEYCUTTER_CONFIG="$TEST_HOME/.ssh/keycutter/keycutter.conf"
export KEYCUTTER_CONFIG_DIR="$TEST_HOME/.ssh/keycutter"
export KEYCUTTER_SSH_KEY_DIR="$TEST_HOME/.ssh/keycutter/keys"
export KEYCUTTER_TEST_MODE=1

# Create test directories
mkdir -p "$TEST_HOME/.ssh/keycutter/"{keys,agents,hosts,scripts}

# Create mock bin directory
mkdir -p /tmp/mock_bin
export PATH="/tmp/mock_bin:$PATH"

# Create mock commands
cat > /tmp/mock_bin/ssh-keygen << 'EOF'
#!/bin/bash
echo "Mock ssh-keygen called with: $@"
# Create fake key files
touch "${@: -1}"
touch "${@: -1}.pub"
exit 0
EOF
chmod +x /tmp/mock_bin/ssh-keygen

cat > /tmp/mock_bin/hut << 'EOF'
#!/bin/bash
echo "Mock hut called with: $@"
if [[ "$1" == "ssh-key" && "$2" == "list" ]]; then
    exit 1  # Simulate not authenticated
fi
echo "hut is not authenticated"
exit 1
EOF
chmod +x /tmp/mock_bin/hut

echo "Running keycutter create git.sr.ht_testuser..."
echo "n" | "$KEYCUTTER_ROOT/bin/keycutter" create git.sr.ht_testuser

echo -e "\n\nDone. Check output above for debugging."

# Cleanup
rm -rf "$TEST_HOME"
rm -rf /tmp/mock_bin