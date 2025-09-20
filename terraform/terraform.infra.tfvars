# Proxmox host configuration
proxmox_host = "pve"

# Network configuration
nic_name   = "vmbr0"
vlan_num   = 10
ip_address = "dhcp"
# For static IP, use format: "192.168.1.100/24,gw=192.168.1.1"

# LXC container template
container_template = "local:vztmpl/ubuntu-25.04-standard_25.04-1_amd64.tar.gz"

# Container privilege settings
unprivileged    = true
nesting_enabled = false

# Default container settings
default_container_settings = {
  cores        = 2
  memory       = 2048
  swap         = 512
  rootfs_size  = "8G"
  storage_name = "local-lvm"
}

# List of containers to create
containers = [
  {
    hostname        = "ubuntu-example"
    description     = "Ubuntu example"
    ostemplate      = "local:vztmpl/ubuntu-25.04-standard_25.04-1_amd64.tar.gz"
    cores           = 2
    memory          = 4096
    rootfs_size     = "20G"
    ip_address      = "dhcp"
    unprivileged    = true
    nesting_enabled = false
  },
]
