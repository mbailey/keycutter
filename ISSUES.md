# Issues

Known issues / annoyances you may encounter.


## Specify userid for resident key

```
$ ssh-keygen -t ecdsa-sk -f "foo" -C "yaas" -O resident
Generating public/private ecdsa-sk key pair.
You may need to touch your authenticator to authorize key generation.
Enter PIN for authenticator: 
You may need to touch your authenticator again to authorize key generation.
A resident key scoped to 'ssh:' with user id 'null' already exists.
Overwrite key in token (y/n)? 
```

## VSCode prompts user when FIDO SSH Key is used to sign / push commits

**Cause:** unknown

Annoyance where user is prompted with 'yes/no' when using key to sign/push git commit in VSCode.

![](assets/vscode-prompts-with-key-has-fingerprint.png)

    "Key" has fingerprint ""
    Are you sure yuou want to coninue connecting?

**GitHub Issues:**
- [Avoid key fingerprint prompt for FIDO/U2F keys #165976](https://github.com/microsoft/vscode/pull/165976)
