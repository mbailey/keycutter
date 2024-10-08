# YubiKey GPG on WSL

- WSL2 doesn't support sharing socket from Windows (?). WSL1 did (?)

## Strategies I've found online

### Add Yubikey as a device to WSL2 using USBIPD-WIN

- [Connect USB devices (learn.microsoft.com](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) 

### Forward gpg-agent requests from WSL using SOCAT

- [Yubikey GPG inside WSL2.md · GitHub (gist.github.com)](https://gist.github.com/dinvlad/a62d44325fa2b989a046fe984a06e140)
- [If you want to use Yubikey from WSL2 (socat passthrough), install gpg4win 3.1.16, NOT the latest (4.0) one  ryubikey (www.reddit.com)](https://www.reddit.com/r/yubikey/comments/t83z2n/if_you_want_to_use_yubikey_from_wsl2_socat/)


