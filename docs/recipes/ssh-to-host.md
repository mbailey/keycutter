---
alias: SSH to Host
---
# SSH to Host

This recipe shows how to SSH to a remote host using Keycutter.

## Prerequisites

- Keycutter installed and configured
- A FIDO SSH key created with Keycutter
- Remote host accessible via SSH
- (Optional) KEYCUTTER_ORIGIN env var - Alternative to hostname in keytag

## Steps

### 1. Create SSH Key for Host (if needed)

```shell
# Create a key for the remote host
keycutter create remote.example.com_alex@yubikey
```

### 2. Copy Public Key to Remote Host

Use `keycutter push-keys` to install your public keys on the remote host:

```shell
# Push the appropriate public keys to the remote host
keycutter push-keys remote.example.com
```

This command will:
- First attempt to use existing key authentication
- Fall back to password authentication if needed
- Automatically handle the RemoteCommand issue

Alternatively, you can manually use `ssh-copy-id` with `keycutter authorized-keys`:

```shell
# Manual approach (if needed)
keycutter authorized-keys remote.example.com | \
    ssh-copy-id \
        -o PreferredAuthentications=password \
        -o RemoteCommand=none \
        -i - \
        remote.example.com
```

### 3. Connect to Remote Host

```shell
# Connect using standard SSH command
ssh remote.example.com
```

Keycutter will automatically:

- Use the correct SSH key
- Handle YubiKey touch requests
- Forward SSH agent if configured for the host

## Troubleshooting

### Check Which Keys Would Be Offered

```shell
# See which keys would be offered to the host
keycutter authorized-keys remote.example.com
```

### Debug SSH Connection

```shell
# Show detailed SSH config for host
ssh -v remote.example.com
```

### Common Issues

1. **Key not offered to host:**
   - Ensure key filename matches Keycutter's SSH Keytag format
   - Check key permissions (should be 600)

2. **YubiKey not responding:**
   - Ensure YubiKey is inserted
   - Check if PIN is required
   - Try removing and reinserting YubiKey

3. **Permission denied:**
   - Verify public key was copied correctly to remote host
   - Check remote ~/.ssh/authorized_keys permissions
   - Ensure remote user has correct permissions

## See Also

- [SSH Keytags](../design/ssh-keytags.md)
- [Defense Layers](../design/defense-layers-to-protect-against-key-misuse.md)
- [SSH Agent Management](../../ssh_config/keycutter/agents/README.md)
