# Storage Setup Commands

Run these commands on your Proxmox host to complete the storage configuration.

## Step 1: Create Environment-Specific Proxmox Storage

```bash
# Create storage for prod VMs
pvesm add zfspool storagezfs-prod --pool storage/vms/prod --content images,rootdir

# Create storage for dev VMs
pvesm add zfspool storagezfs-dev --pool storage/vms/dev --content images,rootdir

# Create storage for sandbox VMs
pvesm add zfspool storagezfs-sandbox --pool storage/vms/sandbox --content images,rootdir

# Create storage for containers
pvesm add zfspool storagezfs-containers --pool storage/containers --content rootdir

# Verify the storage was created
pvesm status
```

## Step 2: Set Up NFS Server for Shared Data

```bash
# Install NFS server
apt update && apt install -y nfs-kernel-server

# Configure NFS exports for shared datasets
cat >> /etc/exports <<'EOF'
# Shared data for all VMs
/storage/data/shared 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)

# Media files (read-only for VMs)
/storage/data/media 192.168.1.0/24(ro,sync,no_subtree_check)

# Services data (for Docker containers to share with VMs if needed)
/storage/services 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF

# Apply the NFS exports
exportfs -ra

# Enable and start NFS server
systemctl enable nfs-server
systemctl start nfs-server

# Verify exports are working
showmount -e localhost
```

**Important**: Change `192.168.1.0/24` to match your actual network subnet.

## Step 3: Test NFS Mounts (Optional)

From another machine on the network:

```bash
# Install NFS client
apt install nfs-common

# Test mount
mkdir -p /tmp/test-mount
mount -t nfs <proxmox-ip>:/storage/data/shared /tmp/test-mount

# Verify
ls -la /tmp/test-mount

# Cleanup
umount /tmp/test-mount
```

## Step 4: Update Terraform Configurations

Edit `terraform/terraform.infra.tfvars` to use environment-specific storage:

```hcl
# Example for future VMs
vms = [
  {
    hostname     = "prod-k8s-01"
    description  = "Production Kubernetes node"
    storage_name = "storagezfs-prod"  # Uses storage/vms/prod dataset
    cores        = 4
    memory       = 8192
    disk_size    = "100G"
    ...
  },
  {
    hostname     = "dev-k8s-01"
    description  = "Development Kubernetes node"
    storage_name = "storagezfs-dev"   # Uses storage/vms/dev dataset
    cores        = 2
    memory       = 4096
    disk_size    = "50G"
    ...
  },
]

containers = [
  {
    hostname     = "coolify"
    description  = "Coolify deployment server"
    storage_name = "storagezfs-containers"  # Uses storage/containers dataset
    cores        = 2
    memory       = 2048
    rootfs_size  = "20G"
    ...
  },
]
```

## Step 5: Mounting NFS in VMs (After VM Creation)

Once VMs are created, run these commands inside each VM:

```bash
# Install NFS client
apt update && apt install -y nfs-common

# Create mount point
mkdir -p /mnt/shared

# Mount the shared storage
mount -t nfs <proxmox-ip>:/storage/data/shared /mnt/shared

# Make it permanent - add to /etc/fstab
echo "<proxmox-ip>:/storage/data/shared /mnt/shared nfs defaults 0 0" >> /etc/fstab

# Verify
df -h | grep shared
```

## Summary of Storage Layout

```
storage (ZFS pool)
├── vms/
│   ├── prod/          → Proxmox storage: storagezfs-prod
│   ├── dev/           → Proxmox storage: storagezfs-dev
│   └── sandbox/       → Proxmox storage: storagezfs-sandbox
├── containers/        → Proxmox storage: storagezfs-containers
├── services/          → NFS export: /storage/services
├── data/
│   ├── shared/        → NFS export: /storage/data/shared (RW)
│   └── media/         → NFS export: /storage/data/media (RO)
└── backups/           → Future: Proxmox Backup Server

NVMe (local)
└── local/             → ISOs, templates
```

## Benefits of This Setup

1. **Organized VM Disks**: Each environment's VM disks are in separate datasets
2. **Independent Quotas**: Each environment has its own space limit
3. **Per-Environment Snapshots**: Can snapshot prod separately from dev
4. **Shared Data**: VMs can access common data via NFS without duplication
5. **Flexible**: Mix of local VM storage + network shared storage as needed
