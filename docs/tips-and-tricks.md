# Keycutter Tips and Tricks

Cool unadvertised tricks. Some may evolve into documented features.

## Using rsync or inline command

A workaround is employed in `~/.keycutter/ssh/config` to avoid a conflict
with `RemoteCommand` when using `rsync` or inline commands that would
otherwise result in the following error:

```shell
$ ssh git date
Cannot execute command-line and remote command.
```

**Solution:** Don't use `RemoteCommand` unless the command is `ssh` with one argument.

The following Match condition in keycutter.conf will allow `ssh` with one argument:

```shell
Match final exec "bash -c '[[ $(ps -o args= -p $PPID) =~ ^ssh[[:space:]]+((-[^T ]+[[:space:]]+)*[^-][^ ]*)?$ ]]'"
```

- `ssh git` = Match
- `ssh git date` = No Match
