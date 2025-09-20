terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  target_node = "pve"
  vmid        = 0 # 0 means it uses the next available
  name        = var.hostname
  desc        = var.description

  cores   = var.cores
  sockets = var.sockets
  memory  = var.memory

  disk {
    type    = var.disk_type
    storage = "storagezfs"
    size    = var.disk_size
    ssd     = var.disk_ssd ? 1 : 0
  }
  network {
    model  = var.network_model
    bridge = var.network_bridge
    tag    = var.vlan_tag
  }

  bios  = var.bios
  boot  = var.boot
  agent = var.qemu_agent_enabled ? 1 : 0
  iso   = var.iso_file

  os_type = var.os_type

  onboot   = var.onboot
  startup  = var.startup_order != null ? "order=${var.startup_order}" : null
  oncreate = var.start

  lifecycle {
    ignore_changes = [
      network
    ]
  }
}
