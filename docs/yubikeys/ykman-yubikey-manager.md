---
aliases:
  - YubiKey Manager (ykman)
---
# YubiKey Manager  (`ykman`)

Command line tool for managing yubikey config on linux and macOS.

## Some Interesting Commands

| Action                  | Command                         |
| ----------------------- | ------------------------------- |
| List YubiKey info       | `ykman info`                    |
| List FIDO2 PIN details  | `ykman fido info`               |
| Change FIDO2 PIN        | `ykman fido access change-pin`  |
| Delete FIDO2 Credential | `ykman fido credentials delete` |
| List FIDO2 Credentials  | `ykman fido credentials list`   |

## `ykman info`

```shell
$ ykman info
Device type: YubiKey 5 Nano
Serial number: 20680971
Firmware version: 5.4.3
Form factor: Nano (USB-A)
Enabled USB interfaces: OTP, FIDO, CCID

Applications
Yubico OTP  	Enabled
FIDO U2F    	Enabled
FIDO2       	Enabled
OATH        	Enabled
PIV         	Enabled
OpenPGP     	Enabled
YubiHSM Auth	Enabled
```


## Install

- [Official package (yubico.com)](https://www.yubico.com/support/download/yubikey-manager/): Some distros lag behind.

The following show where you can find up to date versions of  `ykman`.

| Source              | Package                | Version |
| ------------------- | ---------------------- | ------- |
| Fedora 38           | yubikey-manager        | 5.4.0   |
| Ubuntu (Yubico PPA) | souryubikey-manager    | 5.4.0   |
| Ubuntu 22.04.4      | yubikey-manager        | 4.0.7   |
| Homebrew (macOS)    | yubico-yubikey-manager | 1.2.5   |

### Fedora 

**Install `ykman` from fedora repositories:**

```shell
sudo dnf install yubikey-manager
# Generate bash completion
source <(_YKMAN_COMPLETE=bash_source ykman | sudo tee /etc/bash_completion.d/ykman)
```

### debian / ubuntu

- **Ubuntu 22.04 is a major version behind:** `4.0.7` vs `5.4.0`

**Add and install `ykman` from yubico PPA repository:**

```shell
sudo add-apt-repository ppa:yubico/stable && sudo apt-get update
sudo apt install yubikey-manager # 2024-06-09 yubikey-manager-5.4.0
# Generate bash completion
source <(_YKMAN_COMPLETE=bash_source ykman | sudo tee /etc/bash_completion.d/ykman)
```

## WSL - Windows Subsystem for Linux

- Install YubiKey Manager GUI on Windows.
- Use ssh-sk-helper.exe to pass FIDO SSH requests to Windows.
- Configure passthrough to WSL Linux? I haven't. Maybe checkout `usbipd-win` but I'd rather not have to review the security of that.

### Windows

- [Download from yubico (yubico.com](https://www.yubico.com/support/download/yubikey-manager/#h-downloads)

### macOS

1. Download and install the [official package from Yubico (yubico.com](https://www.yubico.com/support/download/yubikey-manager/#h-downloads).
   
2. Add to your path:

    ```shell
    export PATH="$PATH:/Applications/YubiKey Manager.app/Contents/MacOS"
    ```
    
3. Setup bash completion:

```
source <(_YKMAN_COMPLETE=bash_source ykman | sudo tee /etc/bash_completion.d/ykman)
```
