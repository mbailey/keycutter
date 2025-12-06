# GPG Security Best Practices

Security considerations and recommendations for using GPG with YubiKeys.

## Key Hierarchy

Keycutter follows the security best practice of separating key roles:

```
Master Key (Certify only)
├── Sign Subkey    → Signing commits, emails, documents
├── Encrypt Subkey → Encrypting files and messages
└── Auth Subkey    → SSH authentication
```

### Why Separate Keys?

- **Limited exposure**: Only subkeys on YubiKey; master key stays offline
- **Key rotation**: Replace compromised subkeys without changing identity
- **Capability isolation**: Compromise of one capability doesn't affect others

## Master Key Security

The master key is the root of trust for your GPG identity. Protect it carefully.

### Storage Recommendations

| Risk Level | Storage Location |
|------------|-----------------|
| High security | Encrypted USB in physical safe, hardware security module |
| Medium security | Encrypted cloud storage (Keybase, encrypted S3) |
| Minimum | Local encrypted backup with strong passphrase |

### Master Key Operations

The master key is only needed for:

- Signing other people's keys
- Revoking the master key or subkeys
- Creating new subkeys
- Extending key expiration

For day-to-day use, the subkeys on your YubiKey are sufficient.

## Passphrase Security

### Passphrase Requirements

- Use a strong, unique passphrase (20+ characters recommended)
- Never reuse passphrases from other accounts
- Consider a passphrase manager or diceware-style generation

### Passphrase vs. PIN

| Credential | Purpose | When Used |
|------------|---------|-----------|
| Key passphrase | Protects master key backup | Restoring backup |
| Backup passphrase | Encrypts backup archive | Decrypt backup file |
| YubiKey User PIN | Authorizes key operations | Every signature/decrypt |
| YubiKey Admin PIN | Manages YubiKey settings | Changing settings |

## YubiKey Security

### PIN Protection

YubiKeys have two PINs with retry limits:

| PIN | Default | Retries | After lockout |
|-----|---------|---------|---------------|
| User PIN | `123456` | 3 | Blocked until Admin PIN reset |
| Admin PIN | `12345678` | 3 | YubiKey requires reset (loses all data) |

**Change default PINs immediately after setup.**

### Touch Policy

Enable touch confirmation for all key operations:

- Prevents unauthorized use if YubiKey left inserted
- Confirms physical presence for each operation
- YubiKey blinks when waiting for touch

### Physical Security

- Don't leave YubiKey unattended in public
- Consider a backup YubiKey with same subkeys
- Store backup YubiKey separately from primary

## Backup Security

### Backup Best Practices

1. **Encrypt with strong passphrase** - Different from key passphrase
2. **Multiple copies** - At least 2 backups in different locations
3. **Offline storage** - Keep at least one backup offline
4. **Test restoration** - Periodically verify backups work

### Backup Locations

Consider storing backups in:

- Physical safe at home
- Bank safe deposit box
- Trusted family member's safe
- Encrypted cloud storage (with additional encryption layer)

### What to Never Backup

- Unencrypted private keys
- Keys over unencrypted email
- Keys on shared/public computers

## Key Expiration

### Why Keys Should Expire

- Limits damage from undetected compromise
- Forces periodic review of key security
- Encourages key rotation

### Recommended Expiration

| Key Type | Recommended Expiration |
|----------|----------------------|
| Master key | Never (with offline backup) or 5+ years |
| Subkeys | 1-2 years |

### Extending Expiration

Use your master key backup to extend expiration before keys expire:

```bash
# Load master key from backup
keycutter gpg key install --backup /path/to/backup.tar.gz.gpg

# Extend expiration (in gpg interactive mode)
gpg --edit-key YOUR_KEY_ID
gpg> expire
# Set new expiration
gpg> save

# Re-install to YubiKey
keycutter gpg key install
```

## Revocation

### When to Revoke

- Key compromise (suspected or confirmed)
- Lost YubiKey without backup
- Permanent retirement of key

### Revocation Certificate

Keycutter backups include a revocation certificate. Store it securely - anyone with this file can revoke your key.

### Revocation Process

```bash
# Import revocation certificate
gpg --import /path/to/revoke.asc

# Publish to keyserver
gpg --send-keys YOUR_KEY_ID
```

## Environment Security

### Key Creation Environment

For highest security, create keys in an isolated environment:

1. Boot from Tails USB (air-gapped if possible)
2. Create keys and backup
3. Transfer backup to secure storage
4. Install subkeys to YubiKey
5. Shut down - ephemeral environment leaves no traces

### Operational Security

- Verify key fingerprints out-of-band before trusting
- Be cautious of key signing parties from unknown sources
- Keep GPG and YubiKey firmware updated

## Threat Model Considerations

| Threat | Mitigation |
|--------|------------|
| Key theft | YubiKey - keys cannot be extracted |
| PIN guessing | Limited retries (3 attempts) |
| Physical YubiKey theft | Require PIN for operations |
| Malware | Touch policy confirms physical presence |
| Master key loss | Encrypted offline backups |
| Subkey compromise | Revoke and regenerate from master |

## See Also

- [GPG Quick Start](gpg-quickstart.md) - Getting started
- [GPG Commands](gpg-commands.md) - Command reference
- [drduh YubiKey Guide](https://github.com/drduh/YubiKey-Guide) - Comprehensive security guide
