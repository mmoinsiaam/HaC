packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "api_url" {
  type = string
}

variable "token_id" {
  type      = string
  sensitive = true
}

variable "token_secret" {
  type      = string
  sensitive = true
}

variable "target_node" {
  type = string
}

source "proxmox-iso" "ubuntu-ci-template" {
  proxmox_url = var.api_url
  username    = var.token_id
  token       = var.token_secret
  vm_name = "HaC_ubuntu"
  vm_id = 401
  template_name = "ubuntu-ci-template"

  insecure_skip_tls_verify = true
  node                     = var.target_node
  cores = 2
  memory = 2048
  cpu_type = "host"
  bios = "ovmf"

  efi_config {
    efi_storage_pool  = "local-lvm"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

}