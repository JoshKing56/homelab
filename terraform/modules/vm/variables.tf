variable "hostname" {
  description = "Hostname of the VM"
  type        = string
}

# vmid is hardcoded to 0 in main.tf to use the next available ID
variable "description" {
  description = "Description of the VM"
  type        = string
  default     = ""
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 2048
}

variable "disk_type" {
  description = "Disk type (scsi, sata, virtio)"
  type        = string
  default     = "scsi"
}

variable "storage_name" {
  description = "Storage name where the disk will be created"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Size of the disk"
  type        = string
  default     = "20G"
}

variable "disk_ssd" {
  description = "Enable SSD emulation for the disk"
  type        = bool
  default     = true
}

variable "network_model" {
  description = "Network adapter model (e.g., virtio, e1000, rtl8139)"
  type        = string
  default     = "virtio"
}

variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag for the network interface"
  type        = number
  default     = null
}

variable "bios" {
  description = "BIOS type (seabios or ovmf)"
  type        = string
  default     = "seabios"
}

variable "boot_device_order" {
  description = "Boot device order in Proxmox format (e.g., 'order=scsi0;net0')"
  type        = string
  default     = "order=scsi0;cdrom;net0"
}

variable "qemu_agent_enabled" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = true
}

variable "iso_file" {
  description = "ISO file to use for installation"
  type        = string
  default     = null
}

variable "os_type" {
  description = "OS type (e.g., 'l26' for Linux 2.6/3.x/4.x Kernel)"
  type        = string
  default     = "l26"
}

variable "onboot" {
  description = "Start VM on boot"
  type        = bool
  default     = true
}

variable "startup_order" {
  description = "Boot order for the VM"
  type        = number
  default     = null
}

variable "start" {
  description = "Start the VM after creation"
  type        = bool
  default     = false
}
