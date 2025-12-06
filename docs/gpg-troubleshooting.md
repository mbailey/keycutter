# GPG Troubleshooting

Common issues and solutions when using GPG with YubiKey.

## YubiKey Detection Issues

### "No YubiKey detected"

**Symptoms**: `keycutter gpg key list` shows no keys, or `gpg --card-status` fails.

**Solutions**:

1. **Check YubiKey is inserted**

   ```bash
   # List USB devices
   lsusb | grep Yubico
   ```

2. **Restart smartcard daemon**

   ```bash
   # Linux
   sudo systemctl restart pcscd
   gpgconf --kill scdaemon
   gpg --card-status

   # macOS
   gpgconf --kill scdaemon
   gpg --card-status
   ```

3. **Check pcscd service (Linux)**

   ```bash
   sudo systemctl status pcscd
   sudo systemctl enable --now pcscd
   ```

4. **YubiKey Manager check**

   ```bash
   ykman list
   ykman openpgp info
   ```

### "Card error" or "Operation not supported"

**Cause**: OpenPGP applet may be disabled on YubiKey.

**Solution**:

```bash
# Check applets
ykman info

# Enable OpenPGP if disabled
ykman openpgp reset  # Warning: destroys existing keys
```

## GPG Agent Issues

### "gpg-agent not running"

**Symptoms**: Signing operations fail with agent errors.

**Solutions**:

1. **Start gpg-agent**

   ```bash
   gpg-agent --daemon
   ```

2. **Check agent configuration**

   ```bash
   cat ~/.gnupg/gpg-agent.conf
   ```

3. **Restart agent**

   ```bash
   gpgconf --kill gpg-agent
   gpg-agent --daemon
   ```

### SSH not working with GPG agent

**Symptoms**: SSH connections don't see GPG auth key.

**Checklist**:

1. **Verify SSH support enabled in gpg-agent.conf**

   ```bash
   grep enable-ssh-support ~/.gnupg/gpg-agent.conf
   ```

2. **Check SSH_AUTH_SOCK**

   ```bash
   echo $SSH_AUTH_SOCK
   # Should point to gpg-agent socket
   ```

3. **Add to shell rc file**

   ```bash
   export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
   gpg-connect-agent updatestartuptty /bye >/dev/null
   ```

4. **Verify key visible to SSH**

   ```bash
   ssh-add -L
   ```

## PIN Issues

### "PIN blocked"

**Cause**: Too many incorrect PIN attempts (3 by default).

**Solutions**:

1. **Reset User PIN with Admin PIN**

   ```bash
   gpg --card-edit
   gpg/card> admin
   gpg/card> passwd
   # Choose option 2 to reset PIN using Admin PIN
   ```

2. **If Admin PIN also blocked** - YubiKey must be fully reset:

   ```bash
   ykman openpgp reset
   # Warning: This destroys all keys on the card
   ```

### "Wrong PIN"

**Tips**:

- Default User PIN: `123456`
- Default Admin PIN: `12345678`
- PINs must be 6+ digits (User) or 8+ digits (Admin)

## Key Creation Issues

### "No secret key"

**Symptoms**: Key creation fails with "no secret key" error.

**Cause**: GPG can't find the master key.

**Solutions**:

1. **Check key is in keyring**

   ```bash
   gpg --list-secret-keys
   ```

2. **Import from backup**

   ```bash
   keycutter gpg key install --backup /path/to/backup.tar.gz.gpg
   ```

### "Unusable public key"

**Cause**: Key may be expired or revoked.

**Solution**:

```bash
# Check key status
gpg --list-keys YOUR_KEY_ID

# If expired, extend with master key
gpg --edit-key YOUR_KEY_ID
gpg> expire
gpg> save
```

## Backup/Restore Issues

### "Decryption failed"

**Causes**:

- Wrong backup passphrase
- Corrupted backup file
- Wrong GPG version compatibility

**Solutions**:

1. **Verify file integrity**

   ```bash
   file backup.tar.gz.gpg
   # Should show "GPG symmetrically encrypted data"
   ```

2. **Try manual decryption**

   ```bash
   gpg -d backup.tar.gz.gpg > backup.tar.gz
   tar tzf backup.tar.gz
   ```

### "Cannot import secret key"

**Cause**: Key already exists or conflicts.

**Solution**:

```bash
# Delete existing key first (if you have backup!)
gpg --delete-secret-keys YOUR_KEY_ID
gpg --delete-keys YOUR_KEY_ID

# Then import
gpg --import master.key
```

## Platform-Specific Issues

### macOS

**Pinentry dialog not appearing**:

```bash
# Install pinentry-mac
brew install pinentry-mac

# Configure
echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

**Touch not triggering YubiKey**:

```bash
# Ensure ccid driver is used (not FIDO)
# Check: YubiKey should blink for GPG operations
```

### Linux

**PCSCD permission errors**:

```bash
# Add user to appropriate group
sudo usermod -a -G pcscd $USER
# Log out and back in
```

**SELinux blocking GPG**:

```bash
# Check for denials
ausearch -m avc -ts recent | grep gpg
# Create policy exception if needed
```

### WSL

**"No such device"**:

WSL cannot directly access USB devices. Use Windows GPG with relay.

```bash
# Run setup which configures the relay
keycutter gpg setup

# Verify relay is running
gpg_relay_status
```

**Relay not starting**:

```bash
# Check Windows GPG is installed
/mnt/c/Program\ Files/GnuPG/bin/gpg.exe --version

# Check socat is installed
which socat || sudo apt install socat

# Manually start relay
gpg_relay_start
```

## Debugging

### Enable verbose output

```bash
# GPG verbose mode
gpg --verbose --card-status

# Debug scdaemon
echo "debug-level guru" >> ~/.gnupg/scdaemon.conf
echo "log-file /tmp/scdaemon.log" >> ~/.gnupg/scdaemon.conf
gpgconf --kill scdaemon
gpg --card-status
cat /tmp/scdaemon.log
```

### Check component versions

```bash
gpg --version
gpgconf --list-components
ykman --version
```

### Reset GPG environment

```bash
# Kill all agents
gpgconf --kill all

# Clear caches
rm -rf ~/.gnupg/private-keys-v1.d/*

# Restart
gpg-agent --daemon
gpg --card-status
```

## Getting Help

If these solutions don't resolve your issue:

1. **Check Keycutter issues**: https://github.com/mbailey/keycutter/issues
2. **GPG documentation**: https://gnupg.org/documentation/
3. **drduh YubiKey Guide**: https://github.com/drduh/YubiKey-Guide
4. **YubiKey support**: https://support.yubico.com/

When reporting issues, include:

- Output of `gpg --version`
- Output of `ykman info`
- Your operating system and version
- Relevant error messages
