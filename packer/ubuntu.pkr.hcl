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

source "proxmox-iso" "ubuntu_ci_template" {
  proxmox_url   = var.api_url
  username      = var.token_id
  token         = var.token_secret
  vm_name       = "hac-ubuntu"
  vm_id         = 401

  insecure_skip_tls_verify = true
  node                     = var.target_node
  cores                    = 2
  memory                   = 2048
  cpu_type                 = "host"
  bios                     = "ovmf"
  scsi_controller          = "virtio-scsi-single"
  machine                  = "q35"
  qemu_agent               = true

  disks {
    type         = "scsi"
    disk_size    = "15G"
    storage_pool = "local-lvm"
  }

  additional_iso_files {
    cd_files = [
      "./http/meta-data",
      "./http/user-data"
    ]
    cd_label         = "cidata"
    iso_storage_pool = "local"
    unmount          = true
  }

  boot_iso {
    iso_file = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
    unmount  = true
  }

  efi_config {
    efi_storage_pool  = "local-lvm"
    pre_enrolled_keys = true
    efi_type          = "4m"
  }

  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = true
  }

  serials = ["socket"]

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  http_directory          = "http"


  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ",
    "ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    "---<wait>",
    "<f10><wait>"
  ]

  boot_wait = "5s"
  boot      = "c"

  ssh_username         = "siaam"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  ssh_timeout          = "20m"
}

build {
  sources = ["source.proxmox-iso.ubuntu_ci_template"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync"
    ]
  }

  post-processors {
    post-processor "shell-local" {
      inline = [
        "cd ~/hashiWork/terraform",
        "terraform init",
        "terraform apply -auto-approve"
      ]
    }
  }

  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }
}