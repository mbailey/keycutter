# Troubleshooting

## Analyze SSH Configuration

Use the `keycutter config` command to see which configuration files and settings affect a specific hostname:

```shell
keycutter config github.com
```

This shows each setting, which file it comes from, and the line number where it's defined.

## Dump SSH config

Used for subsystems like `scp`: `ssh -G cloud9`
Used for subsystems like `scp`: `ssh -G -s cloud9`

### Dump SSHD config

