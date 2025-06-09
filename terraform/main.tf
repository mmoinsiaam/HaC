terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc9"
    }
  }
}

variable "api_url" {
  type = string
}

variable "node_to_target" {
  type = string
}

variable "ci_user" { #cloud init username and password
  type = string
}

variable "ci_password" {
  type      = string
  sensitive = true
}

variable "template_name" {
  type = string
}

variable "token_id" {
  type      = string
  sensitive = true
}

variable "secret" {
  type      = string
  sensitive = true
}

provider "proxmox" {
  pm_api_url          = var.api_url
  pm_api_token_id     = var.token_id
  pm_api_token_secret = var.secret

  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "test" {
  name        = "test"
  target_node = var.node_to_target
  clone       = var.template_name
  vmid        = 444
  bios        = "ovmf"
  scsihw      = "virtio-scsi-single"

  full_clone = true
  memory     = 4096
  onboot     = true
  boot       = "order=scsi0;net0"
  agent      = 1

  #cloud_init
  ciuser     = var.ci_user
  cipassword = var.ci_password
  ipconfig0  = "ip=dhcp"
  skip_ipv6  = true

  cpu {
    cores = 4
  }

  network {
    id        = 0
    model     = "virtio"
    bridge    = "vmbr0"
    firewall  = true
    link_down = false
  }

  disk {
    size    = "24G"
    type    = "disk"
    slot    = "scsi0"
    storage = "local-lvm"
    discard = true
  }

  disk {
    type    = "cloudinit"
    slot    = "ide2"
    storage = "local-lvm"
  }

  serial {
    id   = 0
    type = "socket"
  }
}
