# SSH Keytags - device@service-identity

- Traditionally, SSH Key identification left to user:
    - Filename: id_rsa
    - Comment: user@host
- Keytags replace this with device@service-identity:
    - Device: where private key resides:
        - e.g.: A Security Key, Computer, Phone, etc
    - Service: this key is used to connect to
        - e.g. GitHub.com, Digital Ocean, AWS
    - Identity: the key authenticates as
        - e.g. alexdoe
- Example SSH Keytags:
    - sk01@github-alexdoe
    - sk02@github-alexdoe
    - sk02@github-alexwork01
- Places SSH Keytags are used:
    - SSH Key Filenames: 
        - ~/.ssh/sk01@github-alexdoe
        - ~/.ssh/sk01@github-alexdoe.pub
    - SSH Key Comment:
        - TODO
    - GitHub SSH Key name:
        - 
- If a device is compromised, the key tag can help in removing keys from services. It was approved for such as accounts.
- There may be a number of identities on a number of services that were present as SSH keys on the device, and this could make it much easier
- Auditing of keys on devices and services
- Security, key & identity
- Stored in the comment for the key, the key file name, Phone of kit and SSH config created for the key, use the identity part to allow for these configurations to be used on different machines with different security

Keytags are labels that help organise your keys and enable some helpers.

You're free to use any values you like for keytags but the following convention is recommended

## Keytag = device-part @ identity-part

|     | device-part                                                                                               | @   | identity-part                                                                                                 |
| --- | --------------------------------------------------------------------------------------------------------- | --- | ------------------------------------------------------------------------------------------------------------- |
|     | Hardware token or device SSH key is primarily used with (e.g. work-laptop, yubi-keyring, personal-phone). | @   | A user identity (e.g. GitHub user, unix user, etc) made up of two parts (service, user) separated by a hyphen |
|     | work-laptop                                                                                               | @   | github-alexdoe                                                                                                |
|     | yubi-keyring                                                                                              | @   | github-alexdoesopensource                                                                                     |
|     | yubi-keyring                                                                                              | @   | aws-alexdoe                                                                                                   |

## Keytag "Device Part"

The device part of an SSH Keytag should help you identify which Security Key it lives on. While you should have a spare Security Key, it's convenient to have a primary key for each device you use.

## Keytag "Service-Identity Part "

**Format (suggested)**: `<service>-<user_account>`

The identity part of an SSH Keytag should help you identify which service and user account the key is for. 

## Example: Alex and the three Security Keys

Alex has three Yubikeys:

- A Yubikey Nano in her work laptop (for convenience)
- A Yubikey Nano in her nsfwork laptop (for convenience)
- A Yubikey on her keyring (in case neither laptop is available)

These are the SSH Keytags for the keys she has created:

| Key Tag                       | Device                          | Service | User          |
| ----------------------------- | ------------------------------- | ------- | ------------- |
| keyring@aws-alexdoe           | Yubikey on keychain             | AWS     | @alexdoe      |
| keyring@github-alexdoe        | Yubikey on keychain             | GitHub  | @alexdoe      |
| nsfwork-laptop@aws-alexdoe    | Yubikey Nano on Personal Laptop | AWS     | @alexdoe      |
| nsfwork-laptop@github-alexdoe | Yubikey Nano on Personal Laptop | GitHub  | @alexdoe      |
| work-laptop@github-alexdoe    | Yubikey Nano on Work Laptop     | GitHub  | @alexdoe      |
| work-laptop@github-alexdoe    | Yubikey Nano on Work Laptop     | GitHub  | @alexdoe-work |
