# Arch Linux
# ---
# Packer Template to create Arch Linux on Proxmox

packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variable Definitions

# PVE connection
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

# VM variables
variable "iso_file" {
  type    = string
  default = "local:iso/archlinux-2024.03.01-x86_64.iso"
}
 
# variable "iso_url" {
#   type    = string
#   default = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
# }

variable "iso_checksum" {
  type    = string
  default = "0062e39e57d492672712467fdb14371fca4e3a5c57fed06791be95da8d4a60e3"
}

variable "cloudinit_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "proxmox_node" {
  type    = string
  default = "hv01"
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "cpu_type" {
  type    = string
  default = "host"
}

variable "vm_id" {
  type    = string
  default = "8020"
}

variable "bridge_name" {
  type    = string
  default = "vmbr100"
}

source "proxmox-iso" "arch" {

  # Proxmox Connection Settings
  proxmox_url               = var.proxmox_api_url
  username                  = var.proxmox_api_token_id
  token                     = var.proxmox_api_token_secret
  insecure_skip_tls_verify  = false

  # VM General Settings
  node                  = var.proxmox_node
  vm_id                 = var.vm_id
  vm_name               = "arch"
  template_description  = "Built from ${basename(var.iso_file)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  cores                 = "2"
  memory                = "2048"
  cpu_type              = "host"
  qemu_agent            = true
  bios                  = "ovmf"
  efi_config {
    efi_storage_pool    = "local-lvm"
  }

  # ISO file
  iso_file              = var.iso_file
  iso_checksum          = var.iso_checksum
  iso_storage_pool      = "local"
  unmount_iso           = true

  # VM Hard Disk Settings
  scsi_controller       = "virtio-scsi-single"
  disks {
    disk_size     = "10G"
    storage_pool  = var.storage_pool
    type          = "scsi"
  }

  # VM Network Settings
  network_adapters {
    model     = "virtio"
    bridge    = var.bridge_name
    firewall  = "false"
  }
  
  # VM Cloud-Init Settings
  cloud_init              = true
  cloud_init_storage_pool = var.cloudinit_storage_pool

  # PACKER Boot Commands
  boot_command    = [
    "<enter><wait33s>",
    "bash <(curl -s http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh)<enter>"
  ]
  boot            = "c"
  boot_wait       = "6s"

  # PACKER Autoinstall Settings
  http_directory  = "http" 
  ssh_username    = "root"
  # (Option 1) Add your Password here
  ssh_password = "packer" # temporary password
  # - or -
  # (Option 2) Add your Private SSH KEY file here
  # ssh_private_key_file = "~/.ssh/id_ed25519"
  # Raise the timeout, when installation takes longer
  ssh_timeout = "20m"
}

build {
  name    = "arch"
  sources = ["source.proxmox-iso.arch"]

  provisioner "shell" {
    inline = [
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo rm -f /etc/machine-id /var/lib/dbus/machine-id",
      "sudo dbus-uuidgen --ensure=/etc/machine-id",
      "sudo dbus-uuidgen --ensure",
      "sudo cloud-init clean",
      "/usr/bin/pacman -Scc --noconfirm",
      "sudo sync"
    ]
  }

  provisioner "file" {
    destination = "/etc/cloud/cloud.cfg"
    source      = "files/cloud.cfg"
  }
    
  provisioner "file" {
    destination = "/etc/cloud/99-pve.cfg"
    source      = "files/99-pve.cfg"
  }
}