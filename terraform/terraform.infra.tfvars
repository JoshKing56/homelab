proxmox_host = "pve"

nic_name   = "vmbr0"
vlan_num   = 10
ip_address = "dhcp"
# For static IP, use format: "192.168.1.100/24,gw=192.168.1.1"

container_template = "local:vztmpl/ubuntu-25.04-standard_25.04-1.1_amd64.tar.zst"

unprivileged    = true
nesting_enabled = false

# Existing LXC Containers
containers = [
  {
    hostname        = "claude-code"
    description     = "Claude Code container"
    cores           = 4
    memory          = 4096
    swap            = 1024
    rootfs_size     = "64G"
    ip_address      = "dhcp"
    unprivileged    = true
    nesting_enabled = true
    start           = false  # Don't auto-start on import
  },
]

iso_file = "local:iso/ubuntu-24.04.2-desktop-amd64.iso"

# Existing VMs
vms = [
  {
    hostname           = "ubuntu-server"
    description        = "Example Ubuntu deskotp VM"
    cores              = 2
    sockets            = 1
    memory             = 4096
    disk_type          = "scsi"
    disk_size          = "32G"
    disk_ssd           = true
    storage_name       = "storagezfs"
    network_model      = "virtio"
    vlan_tag           = 0
    bios               = "seabios"
    qemu_agent_enabled = true
    os_type            = "l26"
    start              = false  # Don't auto-start on import
  },
  {
    hostname           = "dad-sandbox"
    description        = "Dad sandbox VM"
    cores              = 4
    sockets            = 1
    memory             = 32768
    disk_type          = "scsi"
    disk_size          = "750G"
    disk_ssd           = false
    storage_name       = "backup-storage"
    network_model      = "virtio"
    vlan_tag           = 0
    bios               = "seabios"
    qemu_agent_enabled = true
    os_type            = "l26"
    start              = false  # Don't auto-start on import
  },
  {
    hostname           = "glm-server"
    description        = "GLM server"
    cores              = 8
    sockets            = 1
    memory             = 32768
    disk_type          = "scsi"
    disk_size          = "120G"
    disk_ssd           = false
    storage_name       = "local-lvm"
    network_model      = "virtio"
    vlan_tag           = 0
    bios               = "ovmf"
    qemu_agent_enabled = false
    os_type            = "l26"
    start              = false  # Don't auto-start on import
  },
]
