# Configuration

## KEYCUTTER_ORIGIN

`KEYCUTTER_ORIGIN` is an optional environment variable that provides an
alternative to using the hostname in your SSH keytags.

e.g., "LAPTOP-5CG2109T2N" vs "work-laptop"

### Why set KEYCUTTER_ORIGIN?

Keycutter makes use of the [Keytag](./ssh-keytags.md) convention, which allows
for identical ssh configuration across devices, even when key names
include the device name.

If alex has one of the following keys on each of her laptops:

```txt
- github.com_alex@laptop-work
- github.com_alex@laptop-home
```

She can ssh to github.com using her account `alex` from either laptop with:

```shell
ssh github.com_alex
```

Keycutter defaults to appending the hostname of the current device. Setting
KEYCUTTER_ORIGIN allows you to override this with a preferred name.

### How Keycutter Uses It

1. **Creating Keys**: When you create a new key and don't specify a device:

   ```bash
   KEYCUTTER_ORIGIN=work-laptop keycutter create github.com_alex
    Info: Using the SSH Keytag convention allows the magic to happen
    🛈 Tip: Use an alias instead of hostname by setting KEYCUTTER_ORIGIN env var.
    See also: https://github.com/mbailey/keycutter/blob/master/docs/design/ssh-keytags.md
   ```

❓ Append the current device to the SSH Keytag? (github.com_alex@work-laptop). (Y/n)

# Without KEYCUTTER_ORIGIN (uses hostname)

keycutter create github.com_alex # Creates: github.com_alex@LAPTOP-5CG2109T2N

````

2. **SSH Connections**: When matching keys to hosts:

- Keycutter looks for keys with keytags ending in `@${KEYCUTTER_ORIGIN}`
- If `KEYCUTTER_ORIGIN` isn't set, it falls back to the hostname
- This affects which keys are offered to remote hosts via `authorized-keys`

3. **SSH Agent Forwarding**: Keycutter sets KEYCUTTER_ORIGIN on remote hosts to the origin host:
- It also copies the public keys enabled for forwarding to the remote host
- This allows keycutter to work on remote hosts.

### Setting KEYCUTTER_ORIGIN

You can set it:

1. **Temporarily** for a single command:

```bash
KEYCUTTER_ORIGIN=yubikey keycutter create github.com_alex
````

2. **Permanently** in your shell profile:

   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   [[ -z $SSH_CONNECTION ]] && export KEYCUTTER_ORIGIN="work-laptop"
   ```

   This only sets KEYCUTTER_ORIGIN when you're physically present (not when you SSH to the device). If you SSH to this host from another device then it will set KEYCUTTER_ORIGIN to the origin device.
