---
alias: Locking YubiKey FIDO2 Credentials
---
# Locking YubiKey FIDO2 Credentials

- [ykman-yubikey-manager](../../../docs/hardware/yubikeys/ykman-yubikey-manager.md)

A FIDO PIN can prevent your credentials being used by others if it falls into the wrong hands, or you if you forget the PIN.

> The resident credentials can be left unlocked and used for strong single-factor authentication, or they can be protected by a PIN for two-factor authentication.
> 
> - The FIDO2 PIN must be between 6 and 63 alphanumeric characters.
> - Once a FIDO2 PIN is set, it can be changed but it cannot be removed without resetting the FIDO2 application.
> - After 3 incorrect PIN entries, power cycle the FIDO2 application. This allows the FIDO2 PIN to be attempted again.
> - If the PIN is entered incorrectly 8 times in a row, the FIDO2 application locks and FIDO2 authentication is no longer possible. To use the FIDO2 application after the application has locked, a FIDO2 reset is required.
>
>  - [Locking FIDO2 Credentials (docs.yubico.com)](https://docs.yubico.com/hardware/yubikey/yk-tech-manual/yk5-apps.html#fido-two-label)

## Managing FIDO2 PIN

**Check FIDO PIN:**

```shell
$ ykman fido info
PIN: 8 attempt(s) remaining
Minimum PIN Length: 4
```

**Set FIDO PIN for first time:**

```shell
ykman fido access change-pin
```

**Change FIDO PIN:**

```shell
ykman fido access change-pin \
  --pin <pin> \
  --new-pin <new_pin>
```

## See also:

- [YubiKey Manager (ykman)](ykman-yubikey-manager.md)
