#!/usr/bin/env bash

_keycutter_completion() {
  local cur prev words cword
  _init_completion || return

  local commands="create authorized-keys update config check-requirements agents hosts keys devices tokens agent host key"
  local agent_subcommands="show keys hosts add-key remove-key"
  local host_subcommands="show agent key config"
  local key_subcommands="show agents hosts"

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
    show|agent|key|config)
      # Complete with host names from SSH config
      if [[ -f "$HOME/.ssh/config" ]] || [[ -f "$HOME/.ssh/keycutter/keycutter.conf" ]]; then
        local hosts=$(grep -h "^Host " "$HOME/.ssh/config" "$HOME/.ssh/keycutter/keycutter.conf" "$HOME/.ssh/keycutter/hosts"/* 2>/dev/null | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '\*' | sort -u)
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
  agents|hosts|keys|devices|tokens)
    # No additional completion needed for these list commands
    return
    ;;
  authorized-keys|config)
    # Complete with host names
    if [[ -f "$HOME/.ssh/config" ]] || [[ -f "$HOME/.ssh/keycutter/keycutter.conf" ]]; then
      local hosts=$(grep -h "^Host " "$HOME/.ssh/config" "$HOME/.ssh/keycutter/keycutter.conf" "$HOME/.ssh/keycutter/hosts"/* 2>/dev/null | awk '{for(i=2;i<=NF;i++) print $i}' | grep -v '\*' | sort -u)
      COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
    fi
    return
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

  # Default to filename completion
  COMPREPLY=($(compgen -f -- "$cur"))
}

complete -F _keycutter_completion keycutter