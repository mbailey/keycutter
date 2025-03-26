---
alias: Analyze SSH Configuration
---
# Analyze SSH Configuration Impact

This recipe shows how to analyze which SSH configuration files and settings affect a specific hostname.

## Prerequisites

- Keycutter installed and configured

## Usage

```shell
# Show which SSH config files and settings affect a hostname
keycutter config <hostname>
```

## Example

```shell
# Analyze configuration for github.com
keycutter config github.com
```

Example output:
```
/home/user/.ssh/keycutter/keycutter.conf:49  identitiesonly yes
/home/user/.ssh/keycutter/keycutter.conf:49  identityfile ~/.ssh/keycutter/keys/default
/home/user/.ssh/keycutter/hosts/personal:29  forwardagent yes
/home/user/.ssh/keycutter/hosts/personal:29  identityfile ~/.ssh/keycutter/keys/github.com_user@laptop
/home/user/.ssh/config:6                     hashknownhosts yes
/home/user/.ssh/config:6                     serveraliveinterval 300
```

## Understanding the Output

Each line in the output shows:

1. **File path and line number**: Where the setting is defined (`/path/to/file:line_number`)
2. **SSH setting**: The specific SSH configuration option that applies
3. **Value**: The value of that setting

The output is sorted by precedence, with settings from files applied later (which take precedence) shown first.

## Common Use Cases

- **Troubleshooting SSH connections**: Identify which configuration files are affecting your connection
- **Understanding key selection**: See which identity files are being offered to a host
- **Debugging forwarding issues**: Check if agent forwarding is enabled for a host
- **Auditing SSH settings**: Review all settings that apply to a specific host

## See Also

- [SSH Keytags](../design/ssh-keytags.md)
- [Keycutter Configuration](../keycutter-config/README.md)
- [Troubleshooting](../troubleshooting.md)
