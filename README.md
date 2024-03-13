# arch-packer-proxmox
This simple [Packer](https://www.packer.io/) template can be used to build Arch Linux base image. It uses [proxmox-iso](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso) builer.
## Overview
I wanted to create base Arch image which could be used as a developer server. The installation script is based on [arch wiki installation guide](https://wiki.archlinux.org/title/installation_guide).
## Usage
```
packer build .
```
