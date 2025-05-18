# VS Code Extension: Remote-SSH

Develop on remote machines using Visual Studio Code and SSH.

*2024-08-08 Thu: [VS Code Insiders](https://code.visualstudio.com/insiders/) required due to bug in 1.91*

[Keycutter](https://github.com/mbailey/keycutter) supports VS Code Remote-SSH extension hosts with:

- FIDO SSH Keys (e.g. Yubikey)
- ssh-agent forwarding
- Confirmed working:
    - Linux
    - macOS
    - Windows (WSL Ubuntu)

## Install

1. **Enable extension:**

    ```
    code --install-extension ms-vscode-remote.remote-ssh
    ```

2. **Connect to remote host:**

    - CTRL-SHIFT-P
    - Select `Remote-SSH: Connect to Host`
    - Select a host
    - VSCode will install VS Code Server on remote host if not present.

## Configure

**See also:** [Some working VS Code settings files](./settings/).

These settings worked for me on Fedora and WSL Ubuntu however each needed one or two extra settings.

```json
{
    "remote.SSH.enableRemoteCommand": true,
    "remote.SSH.logLevel": "trace",
    "remote.SSH.permitPtyAllocation": true,
    "remote.SSH.useCurlAndWgetConfigurationFiles": true,

    "remote.SSH.defaultExtensions": [
        "vscodevim.vim",
        "fosshaas.fontsize-shortcuts",
        "eamodio.gitlens",
        "ms-python.python",
        "ms-python.pylint",
        "ms-toolsai.jupyter"
    ]
}
```

### Linux

Fedora required addition of the following to the base settings above:

```json
{
    "remote.SSH.enableDynamicForwarding": false,
}
```

Full settings file: [settings.json-fedora](./settings/settings.json-fedora)

### macOS

Tested on ???

### Windows with WSL

We can make VS Code on Windows use WSL for SSH.

**Benefits include:**

- Use config from `~/.ssh/config` instead of having to copy it to Windows.
- Use OpenSSH from linux instead of whatever Microsoft provides (they're not that into SSH).

We need to tell Windows to use WSL's SSH which means:

- No need to sync config from `~/.ssh` to Windows
- We can load our shell environment.

#### Steps

1. **Put a simple Windows batch file on the Windows filesystem:**

    ```
    # Filename: %USERPROFILE%/ssh.bat
    C:\Windows\system32\wsl.exe --exec bash -ic "echo 'Running in WSL: ssh %*'; ssh %*"
    ```
    
2. **Tell VS Code to use it by setting `remote.SSH.path`:**


    ```json
    {
        "remote.SSH.path": "%USERPROFILE%\\\\ssh.bat",
        "remote.SSH.useLocalServer": false,
    }
    ```

Full settings file: [settings.json-wsl-ubuntu](./settings/settings.json-wsl-ubuntu).

3. **Copy `scp.exe` to same location as `ssh.bat`**

    VSCode 1.93 (insiders build) looked for SCP in same dir as `ssh.bat`.
    More investigation would be good.

    ```
    cp /mnt/c/Program\ Files/OpenSSH/scp.exe /mnt/c/User/<username>/
    ```

## Notes

### Setting: remote.SSH.defaultExtensions

I maintain a list of [extensions](extensions.md)

If there are extensions that you would like to always have installed on any SSH host, you can specify which ones using the `remote.SSH.defaultExtensions`property in `settings.json`. 

For example:

```
"remote.SSH.defaultExtensions": [
    "vscodevim.vim",
    "fosshaas.fontsize-shortcuts",
    "eamodio.gitlens",
    "ms-python.python",
    "ms-python.pylint",
    "ms-toolsai.jupyter"
],
```


## See also

- ["Always installed" extensions (code.visualstudio.com)](https://code.visualstudio.com/docs/remote/ssh#_always-installed-extensions)
- [Developing on Remote Machines using SSH and Visual Studio Code (code.visualstudio.com)](https://code.visualstudio.com/docs/remote/ssh)
- [microsoft/vscode-remote-release (github.com)](https://github.com/Microsoft/vscode-remote-release)
