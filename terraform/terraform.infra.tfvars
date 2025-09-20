proxmox_host = "pve"

nic_name   = "vmbr0"
vlan_num   = 10
ip_address = "dhcp"
# For static IP, use format: "192.168.1.100/24,gw=192.168.1.1"

container_template = "local:vztmpl/ubuntu-25.04-standard_25.04-1.1_amd64.tar.zst"

unprivileged    = true
nesting_enabled = false

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
    start           = true
  },
]

iso_file = "local:iso/ubuntu-24.04.2-desktop-amd64.iso"

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
    network_model      = "virtio"
    vlan_tag           = 0
    boot_device_order  = "order=scsi0;cdrom;net0"
    qemu_agent_enabled = true
    os_type            = "l26"
    start              = true
  },
]
