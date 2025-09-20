variable "ssh_key" {
  description = "Your public SSH key for container access"
  type        = string
}

variable "proxmox_host" {
  description = "Proxmox host name where container will be created"
  type        = string
}

variable "container_template" {
  description = "OS template for the container (e.g., 'local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz')"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz"
}

variable "nic_name" {
  description = "Network bridge to use for container network interface"
  type        = string
  default     = "vmbr0"
}

variable "vlan_num" {
  description = "VLAN tag number for container network interface"
  type        = number
  default     = 10
}

variable "ip_address" {
  description = "IP address for the container (e.g., 'dhcp' or '192.168.1.100/24,gw=192.168.1.1')"
  type        = string
  default     = "dhcp"
}

variable "api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "token_id" {
  description = "Proxmox API token ID (username@realm!tokenname)"
  type        = string
  sensitive   = true
}

variable "token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "unprivileged" {
  description = "Create an unprivileged container"
  type        = bool
  default     = true
}

variable "nesting_enabled" {
  description = "Enable nesting feature for the container"
  type        = bool
  default     = false
}

variable "start" {
  description = "Start the container after creation"
  type        = bool
  default     = false
}


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
    start           = optional(bool)
  }))
}

variable "iso_file" {
  description = "Default ISO file to use for VM installation"
  type        = string
  default     = null
}

variable "vms" {
  description = "List of VMs to create"
  type = list(object({
    hostname           = string
    description        = optional(string, "")
    cores              = optional(number)
    sockets            = optional(number)
    memory             = optional(number)
    disk_type          = optional(string)
    disk_size          = optional(string)
    disk_ssd           = optional(bool)
    storage_name       = optional(string)
    network_model      = optional(string)
    vlan_tag           = optional(number)
    bios               = optional(string)
    boot_order         = optional(string)
    qemu_agent_enabled = optional(bool)
    iso_file           = optional(string)
    os_type            = optional(string)
    onboot             = optional(bool)
    startup_order      = optional(number)
    start              = optional(bool)
  }))
  default = []
}