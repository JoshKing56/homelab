terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.71.0"
    }
  }
}

locals {
  # Ensure disk_type is never null or empty string
  safe_disk_type = var.disk_type != null && var.disk_type != "" ? var.disk_type : "scsi"
}

resource "proxmox_virtual_environment_vm" "vm" {
  node_name = var.node_name
  # vm_id omitted to use next available
  name        = var.hostname
  description = var.description

  cpu {
    cores   = var.cores
    sockets = var.sockets
  }

  memory {
    dedicated = var.memory
  }

  agent {
    enabled = var.qemu_agent_enabled
  }

  bios = var.bios

  disk {
    datastore_id = var.storage_name
    file_format  = "raw"
    interface    = local.safe_disk_type
    size         = parseint(replace(var.disk_size, "G", ""), 10)
    ssd          = var.disk_ssd
  }

  dynamic "cdrom" {
    for_each = var.iso_file != null ? [1] : []
    content {
      enabled   = true
      file_id   = var.iso_file
      interface = "ide2"
    }
  }

  network_device {
    bridge  = var.network_bridge
    model   = var.network_model
    vlan_id = var.vlan_tag
  }

  operating_system {
    type = var.os_type
  }

  started = var.start
  on_boot = var.onboot

  dynamic "startup" {
    for_each = var.startup_order != null ? [1] : []
    content {
      order = var.startup_order
    }
  }

  lifecycle {
    ignore_changes = [
      network_device,
      disk,
      cdrom,
      efi_disk,
      hostpci,
      cpu,
      bios,
      kvm_arguments,
      machine,
      serial_device,
      vga
    ]
  }
}
