packer {
  required_plugins {
    proxmox = {
      version = ">= 1.13.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}