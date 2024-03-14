# arch-packer-proxmox
This simple [Packer](https://www.packer.io/) template can be used to build Arch Linux base image. It uses [proxmox-iso](https://developer.hashicorp.com/packer/integrations/hashicorp/proxmox/latest/components/builder/iso) builer.
## Overview
I wanted to create base Arch image which could be used as a developer server. The installation script is based on [arch wiki installation guide](https://wiki.archlinux.org/title/installation_guide). The template VM is installed on LVM root partition, using GPT schema, with UEFI. Used bootloader is systemd-boot.
## Usage
1. Have packer [installed](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).
2. Clone the repository.
3. `cd` into the cloned repo and run `packer init .`
4. Export environment variables based on the 'secrets_template' file (you can use direnv).
5. Run `packer build -var-file=variables.pkvars.hcl .`
