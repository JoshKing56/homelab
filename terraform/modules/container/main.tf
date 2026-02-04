terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.71"
    }
  }
}

resource "proxmox_virtual_environment_container" "container" {
  node_name = "pve"
  # vm_id omitted to use next available

  description = var.description

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip_address == "dhcp" ? "dhcp" : var.ip_address
      }
    }

    user_account {
      keys = [trimspace(file(pathexpand(var.ssh_key)))]
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge != null ? var.network_bridge : "vmbr0"
    vlan_id = var.vlan_tag
    enabled = true
  }

  operating_system {
    template_file_id = var.ostemplate
    type             = "ubuntu"
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap != null ? var.swap : min(max(1024, var.memory / 2), 4096)
  }

  disk {
    datastore_id = "local-lvm"
    size         = parseint(replace(var.rootfs_size, "G", ""), 10)
  }

  features {
    nesting = var.nesting_enabled
    fuse    = var.fuse_enabled
    keyctl  = var.keyctl_enabled
  }

  started     = var.start
  start_on_boot = var.onboot
  startup {
    order = var.startup_order
  }

  unprivileged = var.unprivileged

  lifecycle {
    ignore_changes = [
      network_interface,
      operating_system,
      initialization
    ]
  }
}
