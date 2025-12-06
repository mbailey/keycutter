#!/usr/bin/env bash

_keycutter_completion() {
  local cur prev words cword
  _init_completion || return

  local commands="create authorized-keys push-keys update install-touch-detector config check-requirements agents hosts keys tokens agent host key ssh-known-hosts git-signing gpg"
  local agent_subcommands="show keys hosts add-key remove-key"
  local host_subcommands="show agent keys config edit"
  local key_subcommands="show agents hosts"
  local hosts_subcommands="edit"
  local update_subcommands="git config requirements touch-detector"
  local ssh_known_hosts_subcommands="delete-line remove fix backup list-backups restore"
  local git_signing_subcommands="enable disable status help"
  local gpg_subcommands="key setup backup yubikeys help"
  local gpg_key_subcommands="list create install renew help"

  # GPG command options
  local gpg_key_list_opts="--all"
  local gpg_key_create_opts="--identity --key-type --expiration --master-expiration --passphrase --master-only --subkeys --fingerprint --yes -y"
  local gpg_key_install_opts="--backup --backup-pass --passphrase --admin-pin --force --label --all --yes -y"
  local gpg_key_renew_opts="--backup --backup-pass --passphrase --expiration --revoke --keyserver --admin-pin --force --yes -y"
  local gpg_setup_opts="--enable-ssh --skip-packages --skip-config --skip-launchagent --skip-wsl-relay --yes -y"
  local gpg_backup_opts="--fingerprint --output-dir --passphrase --backup-pass --yes -y"
  local gpg_yubikeys_opts="--fingerprint --json --quiet -q --connected --remove"

  # Get the command (first argument after keycutter)
  local cmd=""
  if [[ ${#words[@]} -gt 1 ]]; then
    cmd="${words[1]}"
  fi

  # Get the subcommand (second argument after keycutter)
  local subcmd=""
  if [[ ${#words[@]} -gt 2 ]]; then
    subcmd="${words[2]}"
  fi

  case "$prev" in
  keycutter)
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return
    ;;
  create)
    # Add completion for create subcommand options
    COMPREPLY=($(compgen -W "--resident --type" -- "$cur"))
    return
    ;;
  --type)
    COMPREPLY=($(compgen -W "ecdsa-sk ed25519-sk rsa ecdsa ed25519" -- "$cur"))
    return
    ;;
  agent)
    COMPREPLY=($(compgen -W "$agent_subcommands" -- "$cur"))
    return
    ;;
  host)
    COMPREPLY=($(compgen -W "$host_subcommands" -- "$cur"))
    return
    ;;
  key)
    COMPREPLY=($(compgen -W "$key_subcommands" -- "$cur"))
    return
    ;;
  hosts)
    COMPREPLY=($(compgen -W "$hosts_subcommands" -- "$cur"))
    return
    ;;
  update)
    COMPREPLY=($(compgen -W "$update_subcommands" -- "$cur"))
    return
    ;;
  ssh-known-hosts)
    COMPREPLY=($(compgen -W "$ssh_known_hosts_subcommands" -- "$cur"))
    return
    ;;
  git-signing)
    COMPREPLY=($(compgen -W "$git_signing_subcommands" -- "$cur"))
    return
    ;;
  gpg)
    COMPREPLY=($(compgen -W "$gpg_subcommands" -- "$cur"))
    return
    ;;
  esac

  # Handle subcommand completions
  case "$cmd" in
  agent)
    case "$subcmd" in
    show|keys|hosts|add-key|remove-key)
      # Complete with agent names
      if [[ -d "$HOME/.ssh/keycutter/agents" ]]; then
        local agents=$(ls -1 "$HOME/.ssh/keycutter/agents" 2>/dev/null | grep -v '^\\.')
        COMPREPLY=($(compgen -W "$agents" -- "$cur"))
      fi
      return
      ;;
    esac
    ;;
  host)
    case "$subcmd" in
    show|agent|keys|config|edit)
      # Complete with host names from SSH config (excluding README files)
      if [[ -f "$HOME/.ssh/config" ]] || [[ -f "$HOME/.ssh/keycutter/keycutter.conf" ]]; then
        local config_files=$(find "$HOME/.ssh/keycutter/hosts" -name "*.conf" 2>/dev/null)
        local hosts=$(grep -h "^Host " "$HOME/.ssh/config" "$HOME/.ssh/keycutter/keycutter.conf" $config_files 2>/dev/null | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '\*' | sort -u)
        COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
      fi
      return
      ;;
    esac
    ;;
  key)
    case "$subcmd" in
    show|agents|hosts)
      # Complete with key names
      if [[ -d "$HOME/.ssh/keycutter/keys" ]]; then
        local keys=$(ls -1 "$HOME/.ssh/keycutter/keys" 2>/dev/null | grep -v '\\.pub$' | grep -v '^\\.')
        COMPREPLY=($(compgen -W "$keys" -- "$cur"))
      fi
      return
      ;;
    esac
    ;;
  agents|keys|tokens|install-touch-detector)
    # No additional completion needed for these commands
    return
    ;;
  hosts)
    if [[ $cword -eq 2 ]]; then
      # Complete with hosts subcommands
      COMPREPLY=($(compgen -W "$hosts_subcommands" -- "$cur"))
    elif [[ $subcmd == "edit" && $cword -eq 3 ]]; then
      # Complete with host files
      if [[ -d "$HOME/.ssh/keycutter/hosts" ]]; then
        local host_files=$(ls -1 "$HOME/.ssh/keycutter/hosts" 2>/dev/null | grep -v '^\\.')
        COMPREPLY=($(compgen -W "$host_files" -- "$cur"))
      fi
    fi
    return
    ;;
  authorized-keys|push-keys|config)
    # Complete with host names
    if [[ -f "$HOME/.ssh/config" ]] || [[ -f "$HOME/.ssh/keycutter/keycutter.conf" ]]; then
      local hosts=$(grep -h "^Host " "$HOME/.ssh/config" "$HOME/.ssh/keycutter/keycutter.conf" "$HOME/.ssh/keycutter/hosts"/* 2>/dev/null | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '\*' | sort -u)
      COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
    fi
    return
    ;;
  ssh-known-hosts)
    case "$subcmd" in
    delete-line)
      # No completion for line numbers
      return
      ;;
    remove|fix)
      # Complete with host names (excluding README files)
      if [[ -f "$HOME/.ssh/config" ]] || [[ -f "$HOME/.ssh/keycutter/keycutter.conf" ]]; then
        local config_files=$(find "$HOME/.ssh/keycutter/hosts" -name "*.conf" 2>/dev/null)
        local hosts=$(grep -h "^Host " "$HOME/.ssh/config" "$HOME/.ssh/keycutter/keycutter.conf" $config_files 2>/dev/null | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '\*' | sort -u)
        COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
      fi
      return
      ;;
    restore)
      # Complete with backup files
      if [[ -d "$HOME/.ssh/known_hosts_backups" ]]; then
        local backups=$(ls -1 "$HOME/.ssh/known_hosts_backups" 2>/dev/null | grep '^known_hosts\.')
        COMPREPLY=($(compgen -W "$backups" -- "$cur"))
      fi
      return
      ;;
    *)
      # Show subcommands if no valid subcommand is specified
      COMPREPLY=($(compgen -W "$ssh_known_hosts_subcommands" -- "$cur"))
      return
      ;;
    esac
    ;;
  git-signing)
    case "$subcmd" in
    enable)
      # Complete with --global flag or key files
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--global" -- "$cur"))
      elif [[ -d "$HOME/.ssh/keycutter/keys" ]]; then
        local keys=$(ls -1 "$HOME/.ssh/keycutter/keys" 2>/dev/null | grep '\.pub$')
        COMPREPLY=($(compgen -W "$keys" -- "$cur"))
        # Also support file path completion
        _filedir
      fi
      return
      ;;
    disable)
      # Complete with --global flag
      COMPREPLY=($(compgen -W "--global" -- "$cur"))
      return
      ;;
    status)
      # No additional completion for status
      return
      ;;
    esac
    ;;
  gpg)
    case "$subcmd" in
    key)
      # Complete with gpg key subcommands
      local gpg_key_cmd=""
      if [[ ${#words[@]} -gt 3 ]]; then
        gpg_key_cmd="${words[3]}"
      fi

      if [[ $cword -eq 3 ]]; then
        COMPREPLY=($(compgen -W "$gpg_key_subcommands" -- "$cur"))
      elif [[ "$cur" == -* ]]; then
        # Complete options based on gpg key subcommand
        case "$gpg_key_cmd" in
        list)
          COMPREPLY=($(compgen -W "$gpg_key_list_opts" -- "$cur"))
          ;;
        create)
          COMPREPLY=($(compgen -W "$gpg_key_create_opts" -- "$cur"))
          ;;
        install)
          COMPREPLY=($(compgen -W "$gpg_key_install_opts" -- "$cur"))
          ;;
        renew)
          COMPREPLY=($(compgen -W "$gpg_key_renew_opts" -- "$cur"))
          ;;
        esac
      elif [[ "$prev" == "--key-type" ]]; then
        COMPREPLY=($(compgen -W "ed25519 rsa4096" -- "$cur"))
      elif [[ "$prev" == "--fingerprint" ]]; then
        # Complete with GPG key fingerprints from keyring
        local fingerprints
        fingerprints=$(gpg --list-keys --keyid-format long 2>/dev/null | grep -E '^      [A-F0-9]{40}$' | tr -d ' ')
        COMPREPLY=($(compgen -W "$fingerprints" -- "$cur"))
      elif [[ "$prev" == "--backup" ]]; then
        # Complete with backup files
        _filedir 'tar.gz.gpg'
      elif [[ "$prev" == "--output-dir" ]]; then
        _filedir -d
      fi
      return
      ;;
    setup)
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$gpg_setup_opts" -- "$cur"))
      fi
      return
      ;;
    backup)
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$gpg_backup_opts" -- "$cur"))
      elif [[ "$prev" == "--fingerprint" ]]; then
        # Complete with GPG key fingerprints from keyring
        local fingerprints
        fingerprints=$(gpg --list-keys --keyid-format long 2>/dev/null | grep -E '^      [A-F0-9]{40}$' | tr -d ' ')
        COMPREPLY=($(compgen -W "$fingerprints" -- "$cur"))
      elif [[ "$prev" == "--output-dir" ]]; then
        _filedir -d
      fi
      return
      ;;
    yubikeys)
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$gpg_yubikeys_opts" -- "$cur"))
      elif [[ "$prev" == "--fingerprint" ]]; then
        # Complete with GPG key fingerprints from keyring
        local fingerprints
        fingerprints=$(gpg --list-keys --keyid-format long 2>/dev/null | grep -E '^      [A-F0-9]{40}$' | tr -d ' ')
        COMPREPLY=($(compgen -W "$fingerprints" -- "$cur"))
      elif [[ "$prev" == "--remove" ]]; then
        # Complete with registered YubiKey serial numbers
        local registry_file="$HOME/.config/keycutter/gpg-yubikeys.json"
        if [[ -f "$registry_file" ]] && command -v jq &>/dev/null; then
          local serials
          serials=$(jq -r 'keys[]' "$registry_file" 2>/dev/null)
          COMPREPLY=($(compgen -W "$serials" -- "$cur"))
        fi
      fi
      return
      ;;
    esac
    ;;
  esac

  # Handle agent add-key/remove-key second argument (key name)
  if [[ "$cmd" == "agent" ]] && [[ "$subcmd" == "add-key" || "$subcmd" == "remove-key" ]] && [[ ${#words[@]} -eq 4 ]]; then
    # Complete with key names
    if [[ -d "$HOME/.ssh/keycutter/keys" ]]; then
      local keys=$(ls -1 "$HOME/.ssh/keycutter/keys" 2>/dev/null | grep -v '\\.pub$' | grep -v '^\\.')
      COMPREPLY=($(compgen -W "$keys" -- "$cur"))
    fi
    return
  fi

  # Don't provide any completion if we don't recognize the context
  # This prevents showing random file contents
  return
}

complete -F _keycutter_completion keycutter