terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

resource "proxmox_lxc" "container" {
  target_node  = "pve"
  hostname     = var.hostname
  vmid         = 0 # Apparently 0 means it uses the next available
  description  = var.description
  ostemplate   = var.ostemplate
  unprivileged = var.unprivileged

  # Container Resources
  cores  = var.cores
  memory = var.memory
  swap   = var.swap != null ? var.swap : min(max(1024, var.memory / 2), 4096) #Logic based on recommendations from online, may need tweaking
  # Root Storage
  rootfs {
    storage = "local-lvm"
    size    = var.rootfs_size
  }

  # Network
  network {
    name     = "eth0"
    bridge   = var.network_bridge != null ? var.network_bridge : "vmbr0"
    ip       = var.ip_address
    tag      = var.vlan_tag
    firewall = var.firewall_enabled
  }

  # Features
  features {
    nesting = var.nesting_enabled
    fuse    = var.fuse_enabled
    keyctl  = var.keyctl_enabled
    mknod   = var.mknod_enabled
  }

  # SSH public key for root access
  ssh_public_keys = var.ssh_key

  # Startup/shutdown behavior
  onboot  = var.onboot
  startup = var.startup_order != null ? "order=${var.startup_order}" : null

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network
    ]
  }
}
