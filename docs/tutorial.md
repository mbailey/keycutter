# Tutorial

This document walks you through some common workflows.

## Questions

## Tasks

- Add `.ssh/keycutter/devices/`: Contains files `{SERIAL}-[{ALIAS}]`. Used for alias mapping

## SSH Keys for GitHub

FIDO SSH keys make this possible (you can't do it using Yubikey GPG backed SSH).

### Create ssh keys for two different github accounts on the same yubikey

Set kc origin:

- KEYCUTTER_ORIGIN=yubikey1

Create an SSH key for GitHub user alex on dev1

- keycutter create github.com_alex
- ssh -T github.com_alex
- Git clone github.com_alex:alex/keycutter

Create SSH key for github user alexwork

- Keycutter create github.com_alexwork
- ssh -T github.com_alexwork
- Git clone github.com_alexwork:mbailey/keycutter

#### Create the same keys on dev2

- KEYCUTTER_ORIGIN=yubikey2
- Repeat the steps above

### Create SSH key for personal hosts

- KEYCUTTER_ORIGIN=yubikey1
- keycutter create personal
  Create entry in keycutter/hosts
  keycutter host key homeserver person
  Host homeserver
  IdentityFile keys/personal.pub
  - Copy public key to host
  - Keycutter
  - ssh homeserver

### Enable ssh agent forwarding to github from homeserver

Keycutter agent add-host github homeserver
Keycutter agent add-key github.com_alex

ssh homeserver
ssh -T github.com_alex
