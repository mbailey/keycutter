# Configuration

## KEYCUTTER_ORIGIN

`KEYCUTTER_ORIGIN` is an optional environment variable that provides an alternative to using the hostname in your SSH keytags.

### Why use KEYCUTTER_ORIGIN?

- **Consistent Keytags**: When you use multiple devices but want to treat them as one logical device (e.g., multiple YubiKeys for the same laptop)
- **Meaningful Names**: When your hostname isn't meaningful (e.g., "LAPTOP-5CG2109T2N" vs "work-laptop")
- **Device Groups**: To group keys by their purpose rather than physical device (e.g., "yubikey" for all YubiKey-based keys)

### How Keycutter Uses It

1. **Creating Keys**: When you create a new key:
   ```bash
   # With KEYCUTTER_ORIGIN="work-laptop"
   keycutter create github.com_alex    # Creates: github.com_alex@work-laptop
   
   # Without KEYCUTTER_ORIGIN (uses hostname)
   keycutter create github.com_alex    # Creates: github.com_alex@LAPTOP-5CG2109T2N
   ```

2. **SSH Connections**: When matching keys to hosts:
   - Keycutter looks for keys with keytags ending in `@${KEYCUTTER_ORIGIN}`
   - If `KEYCUTTER_ORIGIN` isn't set, it falls back to the hostname
   - This affects which keys are offered to remote hosts via `authorized-keys`

### Setting KEYCUTTER_ORIGIN

You can set it:

1. **Temporarily** for a single command:
   ```bash
   KEYCUTTER_ORIGIN=yubikey keycutter create github.com_alex
   ```

2. **Permanently** in your shell profile:
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export KEYCUTTER_ORIGIN="work-laptop"
   ```

3. **Per Directory** in a .env file:
   ```bash
   # Add to .env in your project
   KEYCUTTER_ORIGIN=project-keys
   ```
