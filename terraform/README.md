# Proxmox LXC Containers Terraform Configuration

This directory contains Terraform configurations to manage multiple Proxmox LXC containers using the Telmate Proxmox provider.

## Prerequisites

- Terraform v1.0.0+
- Proxmox VE 6.0+ with API access
- API token with appropriate permissions
- LXC templates available on your Proxmox host

## Setup

1. Create an API token in Proxmox:
   - Navigate to Datacenter -> Permissions -> API Tokens
   - Add a new token (e.g., for user `root@pam`)
   - Make sure to save the token ID and secret

2. Copy the secrets example file to create your secrets file:
   ```bash
   cp terraform.secrets.example terraform.secrets.tfvars
   ```

3. Edit the variable files with your specific values:
   - In `terraform.secrets.tfvars`: Update API URL, token ID, token secret, and SSH key path
   - In `terraform.infra.tfvars`: Configure Proxmox host, network settings, and container specifications
   - The infrastructure file is already configured and safe to commit to version control
   - The secrets file should never be committed (it's excluded in .gitignore)

4. Copy the infrastructure example file if you don't have one:
   ```bash
   cp terraform.infra.tfvars.example terraform.infra.tfvars
   ```

## Directory Structure

```
terraform/
├── main.tf                   # Main configuration with provider and module definitions
├── variables.tf              # Variable definitions
├── outputs.tf                # Output definitions
├── terraform.infra.tfvars      # Infrastructure settings (safe to commit)
├── terraform.infra.tfvars.example # Example infrastructure settings
├── terraform.secrets.tfvars    # Sensitive values (do not commit)
├── terraform.secrets.example   # Example template for secrets file
├── modules/
│   ├── container/            # LXC container module
│   └── vm/                   # VM module (non cloud-init)
```

## Resource Configuration

### Container Configuration

The configuration creates multiple LXC containers with the following customizable parameters for each container:

- Container hostname
- CPU cores
- Memory allocation
- Root filesystem size
- Network settings (bridge, IP, VLAN)
- Container features (unprivileged, nesting, fuse, keyctl, mknod)
- SSH key for access
- Startup behavior (onboot, start)

You can define multiple containers in the `containers` variable in your `terraform.infra.tfvars` file. Each container should have its own specific settings. If any settings are not specified for a container, the module will use its default values defined in the module's variables.tf file.

#### Example Container Configuration

```hcl
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
  {
    hostname        = "debian-minimal"
    description     = "Minimal Debian container"
    cores           = 1
    memory          = 1024
    ip_address      = "192.168.1.150/24,gw=192.168.1.1"
  }
]
```

### VM Configuration

The configuration also supports creating multiple VMs (non cloud-init) with the following customizable parameters:

- VM hostname
- CPU cores and sockets
- Memory allocation
- Disk settings (type, size, storage, SSD emulation)
- Network settings (model, bridge, VLAN)
- Boot settings (BIOS type, boot device order)
- OS settings (ISO file, OS type, QEMU agent)
- Startup behavior (onboot, start)

You can define multiple VMs in the `vms` variable in your `terraform.infra.tfvars` file. Each VM should have its own specific settings. If any settings are not specified for a VM, the module will use its default values defined in the module's variables.tf file.

#### Example VM Configuration

```hcl
# ISO file for VM installation (optional)
iso_file = "local:iso/ubuntu-24.04.2-desktop-amd64.iso"

vms = [
  {
    hostname           = "ubuntu-server"
    description        = "Example Ubuntu desktop VM"
    cores              = 2
    sockets            = 1
    memory             = 4096
    disk_type          = "scsi"
    disk_size          = "32G"
    disk_ssd           = true
    # Storage is hardcoded to "storagezfs" in the module
    network_model      = "virtio"
    vlan_tag           = 0
    boot_device_order  = "order=scsi0;cdrom;net0"
    qemu_agent_enabled = true
    os_type            = "l26"
    start              = true
  },
  {
    hostname           = "debian-minimal"
    description        = "Minimal Debian VM"
    cores              = 1
    memory             = 2048
    disk_size          = "16G"
    # Will use the global ISO file defined above
  }
]
```

## Usage

Initialize Terraform:
```bash
terraform init
```

Plan your changes using both variable files:
```bash
terraform plan -var-file=terraform.infra.tfvars -var-file=terraform.secrets.tfvars
```

Apply the configuration:
```bash
terraform apply -var-file=terraform.infra.tfvars -var-file=terraform.secrets.tfvars
```

Destroy resources:
```bash
terraform destroy -var-file=terraform.infra.tfvars -var-file=terraform.secrets.tfvars
```

Note: You can also create a `.auto.tfvars` file for variables that should be automatically loaded, but be careful not to put secrets in auto-loaded files that might be committed.

## Outputs

After successful creation, Terraform will output for each container:

- Container ID
- Container Hostname
- Container IP address (once the container is running)

You can access these outputs using the container hostname as the key, for example:
```
terraform output container["ubuntu-web"].container_ip
```

## Notes

- For production use, set `pm_tls_insecure = false` and use proper TLS certificates
- The container module supports both DHCP and static IP configuration
- Unprivileged containers are more secure but have some limitations
- You may need to download LXC templates to your Proxmox host first
- The VM module has the storage parameter hardcoded to "storagezfs" - modify this in the module's main.tf if you need to use a different storage

## Troubleshooting

### Handling Manually Deleted VMs

If you manually delete a VM outside of Terraform (e.g., directly in the Proxmox UI), you'll encounter errors when running Terraform commands because the resource still exists in Terraform's state but not in Proxmox.

To fix this issue:

1. List the resources in your Terraform state:
   ```bash
   terraform state list
   ```

2. Identify the resource corresponding to the deleted VM (e.g., `module.container["ubuntu-example"].proxmox_lxc.container`)

3. Remove it from the state:
   ```bash
   terraform state rm 'module.container["ubuntu-example"].proxmox_lxc.container'
   ```

4. Now you can run Terraform commands without errors
