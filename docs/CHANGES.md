# Keycutter CHANGES

## 2024-05-27 Mon

This is a big evolution for the project. 

- **Single git repo for `.keycutter` config:** Works everywhere
- **Add support for ssh-agents:** selective key forwarding to select hosts
- **SSH Identities work on local/remote:** **`IdentityFile ~/.keycutter/ssh/keys/github.com_example@home.pub`**: 
- **Name change:** `.keycutter/ssh/sshconfig-keycutter` -> `.keycutter/ssh/config`
- **Name change:** `.keycutter/ssh/config.d` -> `.keycutter/ssh/hosts`