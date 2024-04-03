# Change to keytag format

## Change format?

- github.com-mike@x2
- m@x2
- m@keyring

**Full domain:** Setup SSH config for domain if present (e.g. github.com-mbailey@x2)


### Key Filename?

For consistency with ssh-keygen, Save file to id_{ssh_key_type}_{,_rk}_keytag
```
$ ssh-keygen -K
Enter PIN for authenticator: 
You may need to touch your authenticator to authorize key download.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Saved ECDSA-SK key to id_ecdsa_sk_rk
Saved ECDSA-SK key ssh:mikey@x2 to id_ecdsa_sk_rk_mikey@x2_usernom
Saved ECDSA-SK key ssh:mikey2@x2 to id_ecdsa_sk_rk_mikey2@x2_usernom
```

## Key comment?

ssh:mikey2@x2

```
$ cat *.pub | awk '{print $3}'
ssh:mikey2@x2
ssh:mikey@x2
ssh:
```
---
