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

  cores  = var.cores
  memory = var.memory
  swap   = var.swap != null ? var.swap : min(max(1024, var.memory / 2), 4096) #Logic based on recommendations from online, may need tweaking
  # Root Storage
  rootfs {
    storage = "local-lvm"
    size    = var.rootfs_size
  }

  network {
    name     = "eth0"
    bridge   = var.network_bridge != null ? var.network_bridge : "vmbr0"
    ip       = var.ip_address
    tag      = var.vlan_tag
    firewall = var.firewall_enabled
  }

  features {
    nesting = var.nesting_enabled
    fuse    = var.fuse_enabled
    keyctl  = var.keyctl_enabled
    mknod   = var.mknod_enabled
  }

  # SSH public key for root access
  ssh_public_keys = file(pathexpand(var.ssh_key)) #This makes it so the ~ expands to a real path

  onboot  = var.onboot
  start   = var.start
  startup = var.startup_order != null ? "order=${var.startup_order}" : null

  lifecycle {
    ignore_changes = [
      network
    ]
  }
}
