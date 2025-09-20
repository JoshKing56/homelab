variable "hostname" {
  description = "Hostname of the container"
  type        = string
}

# target_node is now hardcoded to "pve" in main.tf

# vmid is now hardcoded to 0 in main.tf to use the next available ID

variable "description" {
  description = "Description of the container"
  type        = string
  default     = ""
}

variable "ostemplate" {
  description = "OS template for the container (e.g., 'local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.gz')"
  type        = string
}

variable "unprivileged" {
  description = "Create an unprivileged container"
  type        = bool
  default     = true
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 2048
}

variable "swap" {
  description = "Amount of swap in MB (if null, will be calculated based on memory)"
  type        = number
  default     = null
}

variable "rootfs_size" {
  description = "Size of the root filesystem"
  type        = string
  default     = "8G"
}

variable "network_bridge" {
  description = "Network bridge to use (if null, will default to vmbr0)"
  type        = string
  default     = null
}

variable "ip_address" {
  description = "IP address for the container (e.g., 'dhcp' or '192.168.1.100/24,gw=192.168.1.1')"
  type        = string
  default     = "dhcp"
}

variable "vlan_tag" {
  description = "VLAN tag for the network interface"
  type        = number
  default     = null
}

variable "firewall_enabled" {
  description = "Enable firewall for the container"
  type        = bool
  default     = false
}

variable "nesting_enabled" {
  description = "Enable nesting feature for the container"
  type        = bool
  default     = false
}

variable "fuse_enabled" {
  description = "Enable FUSE feature for the container"
  type        = bool
  default     = false
}

variable "keyctl_enabled" {
  description = "Enable keyctl feature for the container"
  type        = bool
  default     = false
}

variable "mknod_enabled" {
  description = "Enable mknod feature for the container"
  type        = bool
  default     = false
}

variable "ssh_key" {
  description = "SSH public key for container access"
  type        = string
}

variable "onboot" {
  description = "Start container on boot"
  type        = bool
  default     = true
}

variable "startup_order" {
  description = "Boot order for the container"
  type        = number
  default     = null
}

variable "start" {
  description = "Start the container after creation"
  type        = bool
  default     = false
}
