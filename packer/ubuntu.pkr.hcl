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

  insecure_skip_tls_verify = true
  node                     = var.target_node
}