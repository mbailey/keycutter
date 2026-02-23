# Keycutter Troubleshooting

## `_init_completion: command not found`

Missing bash-completion package. On macOS:
```bash
brew install bash-completion@2
```

## Permission denied on key files

`ssh-agent-ensure` auto-fixes key file permissions to 600 before loading. If you see permission errors with older versions:
```bash
keycutter update
```

## Analyze SSH config for a host

```bash
keycutter config github.com    # Shows which files/settings affect this host
ssh -G github.com              # Dump resolved SSH config
```

## Debug ssh-agent-ensure

```bash
KEYCUTTER_DEBUG=1 ssh hostname                    # See agent debug output
eval "$(ssh-agent-ensure -e hostname)"            # Eval mode: exports SSH_AUTH_SOCK
```

## YubiKey touch not detected

Install the touch detector:
```bash
keycutter install-touch-detector
# or
keycutter update touch-detector
```

## Key not working after creation

1. Check the key exists: `keycutter keys`
2. Check it's assigned to an agent: `keycutter key agents <keyname>`
3. Check the host config: `keycutter config <hostname>`
4. Verify GitHub upload: `gh ssh-key list`

## OpenSSH version requirements

FIDO2 key types (`ed25519-sk`, `ecdsa-sk`) require OpenSSH 8.2+. Check with:
```bash
ssh -V
```

macOS ships a suitable version since Ventura. On older macOS, install via Homebrew:
```bash
brew install openssh
```
