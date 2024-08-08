# VS Code support

*2024-08-08 Thu: [VS Code Insiders](https://code.visualstudio.com/insiders/) required due to bug in 1.91*


## Remote-SSH Extension

Keycutter supports VS Code on remote hosts with:

- FIDO SSH Keys (e.g. Yubikey)
- ssh-agent forwarding
- Confirmed working:
    - Linux
    - macOS
    - Windows (WSL Ubuntu)

### Settings

Example of settings that work for me.

```
{
    "remote.SSH.path": "%USERPROFILE%\\\\ssh.bat",
    "remote.SSH.useCurlAndWgetConfigurationFiles": true,
    "files.autoSave": "afterDelay",
    "workbench.startupEditor": "none",
    "terminal.integrated.fontSize": 14,
    "remote.SSH.defaultExtensions": [
        "vscodevim.vim",
        "fosshaas.fontsize-shortcuts",
        "eamodio.gitlens",
        "ms-python.python",
        "ms-python.pylint",
        "ms-toolsai.jupyter"
    ],
    "remote.SSH.logLevel": "trace",
    "remote.SSH.enableRemoteCommand": true,
    "remote.SSH.remotePlatform": {
        "*": "linux"
    },
    "remote.SSH.permitPtyAllocation": true,
    "workbench.sideBar.location": "right",
    "remote.SSH.enableDynamicForwarding": false
}
```
