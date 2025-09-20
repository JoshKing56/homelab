# SSH key for container access
variable "ssh_key" {
  description = "Your public SSH key for container access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# Proxmox host to create the container on
variable "proxmox_host" {
  description = "Proxmox host name where container will be created"
  type        = string
  default     = "proxmox_host_name"
}

# OS template for the container
variable "container_template" {
  description = "OS template for the container (e.g., 'local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz')"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
}

# Network bridge to use
variable "nic_name" {
  description = "Network bridge to use for container network interface"
  type        = string
  default     = "vmbr0"
}

# VLAN tag for the network interface
variable "vlan_num" {
  description = "VLAN tag number for container network interface"
  type        = number
  default     = 10
}

# IP address configuration
variable "ip_address" {
  description = "IP address for the container (e.g., 'dhcp' or '192.168.1.100/24,gw=192.168.1.1')"
  type        = string
  default     = "dhcp"
}

# Proxmox API URL
variable "api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://<proxmox_host_ip>:8006/api2/json"
}

# Proxmox API token ID for authentication
variable "token_id" {
  description = "Proxmox API token ID (username@realm!tokenname)"
  type        = string
  sensitive   = true
}

# Proxmox API token secret for authentication
variable "token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

# Container privilege settings
variable "unprivileged" {
  description = "Create an unprivileged container"
  type        = bool
  default     = true
}

# Container nesting feature
variable "nesting_enabled" {
  description = "Enable nesting feature for the container"
  type        = bool
  default     = false
}

# Container settings
variable "default_container_settings" {
  description = "Default settings for containers"
  type = object({
    cores        = number
    memory       = number
    swap         = number
    rootfs_size  = string
    storage_name = string
  })
  default = {
    cores        = 2
    memory       = 2048
    swap         = 512
    rootfs_size  = "8G"
    storage_name = "local-lvm"
  }
}

# List of containers to create
variable "containers" {
  description = "List of containers to create"
  type = list(object({
    hostname        = string
    description     = optional(string, "")
    cores           = optional(number)
    memory          = optional(number)
    swap            = optional(number)
    rootfs_size     = optional(string)
    ip_address      = optional(string)
    vlan_tag        = optional(number)
    unprivileged    = optional(bool)
    nesting_enabled = optional(bool)
    fuse_enabled    = optional(bool)
    keyctl_enabled  = optional(bool)
    mknod_enabled   = optional(bool)
  }))
  default = [
    {
      hostname = "test-ubuntu"
    }
  ]
}