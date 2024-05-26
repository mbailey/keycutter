# Issues

Known issues / annoyances you may encounter.

1. **Keycutter does not specify userid for resident key:** Work in progress

2. **[Bundled version of OpenSSH with macOS Monterey doesn't support FIDO2 yubikeys (github.com)](https://github.com/Yubico/libfido2/issues/464):** OpenSSH 9.6p1 that ships with macOS doesn't work. homebrew? other library for FIDO2 support?

3. **[VSCode presents key fingerprint prompt for FIDO/U2F keys #165976](https://github.com/microsoft/vscode/pull/165976):** VSCode prompts user when FIDO SSH Key is used to sign / push commits

## Notes

### 1. Keycutter does not specify userid for resident key

Keycutter needs to be updated to specify userid for resident key.

```
$ ssh-keygen -t ecdsa-sk -f "foo" -C "yaas" -O resident
Generating public/private ecdsa-sk key pair.
You may need to touch your authenticator to authorize key generation.
Enter PIN for authenticator: 
You may need to touch your authenticator again to authorize key generation.
A resident key scoped to 'ssh:' with user id 'null' already exists.
Overwrite key in token (y/n)? 
```

### 2. Bundled version of OpenSSH with macOS Monterey doesn't support FIDO2 yubikeys (github.com)

- Confirm this is true.

### 3. VSCode prompts user when FIDO SSH Key is used to sign / push commits

**Cause:** unknown

Annoyance where user is prompted with 'yes/no' when using key to sign/push git commit in VSCode.

![](assets/vscode-prompts-with-key-has-fingerprint.png)

    "Key" has fingerprint ""
    Are you sure yuou want to coninue connecting?
