# Defence layers to protect against key misuse

You need to consider the following layers of defense when using FIDO SSH Keys.

These are not setup for you by Keycutter but are important to understand.

1. **Security Key PIN**: Unlocks key when inserted into computer
2. **FIDO SSH Key Passphrase**: May be stored in SSH Agent
3. **Presence Detection**: Requires touch from operator
4. **Screen Lock**: Prevent physical access to device (Security Key & SSH Agent)
