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

## Directory Structure

```
terraform/
├── main.tf                   # Main configuration with provider and container definition
├── variables.tf              # Variable definitions
├── outputs.tf                # Output definitions
├── terraform.infra.tfvars    # Infrastructure settings (safe to commit)
├── terraform.secrets.tfvars  # Sensitive values (do not commit)
├── terraform.secrets.example # Example template for secrets file
├── modules/
│   └── container/            # LXC container module
```

## Container Configuration

The configuration creates multiple LXC containers with the following customizable parameters for each container:

- Container hostname
- CPU cores
- Memory allocation
- Root filesystem size
- Network settings (bridge, IP, VLAN)
- Container features (unprivileged, nesting, fuse, keyctl, mknod)
- SSH key for access

You can define multiple containers in the `containers` variable in your `terraform.tfvars` file. Each container can have its own specific settings, which will override the default settings if provided.

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
