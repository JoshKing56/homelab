terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.api_url
  pm_api_token_id     = var.token_id
  pm_api_token_secret = var.token_secret
  pm_tls_insecure     = true # Set to false in production environments
}

module "container" {
  for_each    = { for container in var.containers : container.hostname => container }
  source      = "./modules/container"
  hostname    = each.value.hostname
  description = each.value.description
  ostemplate  = var.container_template

  cores  = each.value.cores
  memory = each.value.memory
  swap   = each.value.swap

  rootfs_size = each.value.rootfs_size

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
  hostname    = each.value.hostname
  description = each.value.description

  cores   = each.value.cores
  sockets = each.value.sockets
  memory  = each.value.memory

  disk_type    = each.value.disk_type
  disk_size    = each.value.disk_size
  disk_ssd     = each.value.disk_ssd
  storage_name = each.value.storage_name

  network_model  = each.value.network_model
  network_bridge = var.nic_name
  vlan_tag       = each.value.vlan_tag != null ? each.value.vlan_tag : var.vlan_num

  bios               = each.value.bios
  boot               = each.value.boot
  qemu_agent_enabled = each.value.qemu_agent_enabled
  iso_file           = each.value.iso_file != null ? each.value.iso_file : var.iso_file
  os_type            = each.value.os_type

  onboot        = each.value.onboot
  startup_order = each.value.startup_order
  start         = each.value.start != null ? each.value.start : var.start
}
