# Keycutter tests


## Features

- **Create key**
  - **Resident**: Yes, No
  - **Type**: ecdsa-sk, ed25519-sk
  - **Already exists**: Yes, No
  - **Empty config**: Yes, No
- **SSH to keytag**: `ssh -T <keytag>`
- **Git commit signing**: git commit -S

*Future*

- **Init**: Create keycutter config dirs and base files, include from ssh/git
- **List Keys**
- **Remove Key**
- **Regenerate config**
    - Show diff
    - Get confirmation
- **Keycutter Config**: `~/keycutter/config[.env]`, `~/.keycutter/config.yaml` 
    - Alternative to command line options

