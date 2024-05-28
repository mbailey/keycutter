# Keycutter Tips and Tricks

Cool unadvertised tricks. Some may evolve into documented features.

## Recreate ssh configs for a key

Keycutter is composed of simple bash functions which can be run independantly.

1. Source keycutter functions:

    ```shell
    source "${KEYCUTTER_ROOT}/lib/functions"
    ```

2. Recreate ssh config files:

    ```shell
    $ ssh-config-create ~/.keycutter/ssh/keys/example.com_m\@keyring
    File is identical: /home/janedoe/.keycutter/ssh/config
    Line already present in /home/janedoe/.ssh/config
    SSH configuration file exists (/home/janedoe/.keycutter/ssh/hosts/example.com_m)
    Already in /home/janedoe/.keycutter/ssh/hosts/example.com_m:   IdentityFile ~/.keycutter/ssh/keys/example.com_m@keyring.pub
    Add key to default keycutter ssh-agent? [y/N] y
    Creating symlink: ln -sf /home/janedoe/.keycutter/ssh/keys/example.com_m@keyring /home/janedoe/.keycutter/ssh/agents/default/keys
    ```