terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.71"
    }
  }
}

provider "proxmox" {
  endpoint = var.api_url
  api_token = "${var.token_id}=${var.token_secret}"
  insecure  = true # Set to false in production environments

  ssh {
    agent = true
  }
}

module "container" {
  for_each    = { for container in var.containers : container.hostname => container }
  source      = "./modules/container"
  node_name   = var.proxmox_host
  hostname    = each.value.hostname
  description = each.value.description
  ostemplate  = var.container_template

  cores  = coalesce(each.value.cores, 2)
  memory = coalesce(each.value.memory, 2048)
  swap   = coalesce(each.value.swap, 512)

  rootfs_size = coalesce(each.value.rootfs_size, "8G")

  network_bridge = var.nic_name
  vlan_tag       = each.value.vlan_tag != null ? each.value.vlan_tag : var.vlan_num
  ip_address     = each.value.ip_address != null ? each.value.ip_address : var.ip_address

  unprivileged    = each.value.unprivileged != null ? each.value.unprivileged : var.unprivileged
  nesting_enabled = each.value.nesting_enabled != null ? each.value.nesting_enabled : var.nesting_enabled
  fuse_enabled    = each.value.fuse_enabled != null ? each.value.fuse_enabled : false
  keyctl_enabled  = each.value.keyctl_enabled != null ? each.value.keyctl_enabled : false
  mknod_enabled   = each.value.mknod_enabled != null ? each.value.mknod_enabled : false

  ssh_key = var.ssh_key

  start = each.value.start != null ? each.value.start : var.start
}

module "vm" {
  for_each    = { for vm in var.vms : vm.hostname => vm }
  source      = "./modules/vm"
  node_name   = var.proxmox_host
  hostname    = each.value.hostname
  description = each.value.description

  cores   = coalesce(each.value.cores, 2)
  sockets = coalesce(each.value.sockets, 1)
  memory  = coalesce(each.value.memory, 2048)

  disk_type    = coalesce(each.value.disk_type, "scsi")
  disk_size    = coalesce(each.value.disk_size, "20G")
  disk_ssd     = coalesce(each.value.disk_ssd, true)
  storage_name = coalesce(each.value.storage_name, "local-lvm")

  network_model  = coalesce(each.value.network_model, "virtio")
  network_bridge = var.nic_name
  vlan_tag       = each.value.vlan_tag != null ? each.value.vlan_tag : var.vlan_num

  bios               = coalesce(each.value.bios, "seabios")
  boot               = coalesce(each.value.boot, "order=scsi0;cdrom;net0")
  qemu_agent_enabled = coalesce(each.value.qemu_agent_enabled, true)
  iso_file           = each.value.iso_file != null ? each.value.iso_file : var.iso_file
  os_type            = coalesce(each.value.os_type, "l26")

  onboot        = coalesce(each.value.onboot, true)
  startup_order = each.value.startup_order
  start         = each.value.start != null ? each.value.start : var.start
}
