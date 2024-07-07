# Keycutter Tips and Tricks

Cool unadvertised tricks. Some may evolve into documented features.

## Using rsync or inline command

A workaround is employed in `~/.ssh/keycutter/config` to avoid a conflict with `RemoteCommand` when using `rsync` or inline commands that resulted in the following error:

```shell
$ ssh git date
Cannot execute command-line and remote command.
```

**Current workaround:** Check number of command arguments.

This is a bit of a hack, but it works. The following check in a Match condition will fail if the number of arguments is greater than 2. Passes for `ssh git` and fails for `ssh git date`.

```shell
[[ $(ps h o args p $PPID | wc -w) -eq 2 ]]
```

Issue: This will fail to run RemoteCommand is the user provides any arguments (e.g. `-p 443`).
The result is that remote host won't be able to request keys from the origin host.

**Alternative**: Unset `$KEYCUTTER_HOSTNAME` on command line.

This works by making us appear to not be on an origin host.

```shell
KEYCUTTER_HOSTNAME="" rsync -avz ~/.ssh/keycutter/ git:.ssh/keycutter/
```

**Alternative**: Export env vars for things that need them:

```
RSYNC_RSH="ssh -o RemoteCommand=none" rsync -avz ~/.ssh/keycutter/ git:.ssh/keycutter/
```

## Recreate ssh configs for a key

Keycutter is composed of simple bash functions which can be run independantly.

1. Source keycutter functions:

    ```shell
    source "${KEYCUTTER_ROOT}/lib/functions"
    ```

2. Recreate ssh config files:

    ```shell
    $ keycuitter-ssh-config-create ~/.ssh/keycutter/keys/example.com_m\@keyring
    File is identical: /home/alex/.ssh/keycutter/config
    Line already present in /home/alex/.ssh/config
    SSH configuration file exists (/home/alex/.ssh/keycutter/hosts/example.com_m)
    Already in /home/alex/.ssh/keycutter/hosts/example.com_m:   IdentityFile ~/.ssh/keycutter/keys/example.com_m@keyring.pub
    Add key to default keycutter ssh-agent? [y/N] y
    Creating symlink: ln -sf /home/alex/.ssh/keycutter/keys/example.com_m@keyring /home/alex/.ssh/keycutter/agents/default/keys
    ```
