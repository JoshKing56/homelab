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

# Create multiple LXC containers
module "container" {
  for_each    = { for container in var.containers : container.hostname => container }
  source      = "./modules/container"
  hostname    = each.value.hostname
  description = each.value.description
  ostemplate  = var.container_template

  # Container Resources
  cores  = each.value.cores != null ? each.value.cores : var.default_container_settings.cores
  memory = each.value.memory != null ? each.value.memory : var.default_container_settings.memory
  swap   = each.value.swap != null ? each.value.swap : var.default_container_settings.swap

  # Storage
  rootfs_size = each.value.rootfs_size != null ? each.value.rootfs_size : var.default_container_settings.rootfs_size

  # Network
  network_bridge = var.nic_name
  vlan_tag       = each.value.vlan_tag != null ? each.value.vlan_tag : var.vlan_num
  ip_address     = each.value.ip_address != null ? each.value.ip_address : var.ip_address

  # Features
  unprivileged    = each.value.unprivileged != null ? each.value.unprivileged : var.unprivileged
  nesting_enabled = each.value.nesting_enabled != null ? each.value.nesting_enabled : var.nesting_enabled
  fuse_enabled    = each.value.fuse_enabled != null ? each.value.fuse_enabled : false
  keyctl_enabled  = each.value.keyctl_enabled != null ? each.value.keyctl_enabled : false
  mknod_enabled   = each.value.mknod_enabled != null ? each.value.mknod_enabled : false

  # Authentication
  ssh_key = var.ssh_key

  # Startup configuration
  start = each.value.start != null ? each.value.start : var.start
}
