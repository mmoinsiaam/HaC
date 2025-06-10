packer {
  required_plugins {
    proxmox = {
      version = ">= 1.13.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "api_url" {
  type = string
}

variable "token_id" {
  type = string
  sensitive = true
}

variable "token_secret" {
  type = string
  sensitive = true
}

