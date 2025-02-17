terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

data "local_file" "ssh_public_key" {
  filename = var.ssh_key
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = var.vm_name
  node_name = "pve"
  # Do not provide vm_id, provider automatically geneartes
  # vm_id = null

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "ubuntu"
      password = "letmein123"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }

  memory {
    dedicated = 2048
    floating  = 2048 # set equal to dedicated to enable ballooning
  }

  cdrom {
    enabled = true
    file_id = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
  }

  disk {
    datastore_id = "storagezfs"
    interface    = "scsi0"
    file_format  = "raw"
    size         = "20"
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"

  url = "https://releases.ubuntu.com/24.04.1/ubuntu-24.04.1-live-server-amd64.iso"
}