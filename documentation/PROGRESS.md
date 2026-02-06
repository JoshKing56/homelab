# Homelab Implementation Progress

Last updated: February 5, 2026

## Completed Tasks

### Storage Infrastructure ✅ (100% Complete)

#### ZFS Pool Configuration
- ✅ Pool: `storage` (RAIDZ1, 3x 4TB drives, ~8TB usable)
- ✅ Compression: Enabled (`on`)
- ✅ Pool Status: ONLINE (with known data corruption in backup file - documented)

#### Dataset Organization
Created structured dataset hierarchy:
```
storage/
├── vms/
│   ├── prod/ (500GB quota)
│   ├── dev/ (300GB quota)
│   └── sandbox/ (200GB quota)
├── containers/ (100GB quota)
├── services/ (300GB quota)
├── data/
│   ├── shared/ (1.5TB quota)
│   └── media/ (2TB quota)
└── backups/ (no quota - uses remaining space)
```

#### Proxmox Storage Configuration
Environment-specific storage definitions created:
- `storagezfs-prod` → storage/vms/prod
- `storagezfs-dev` → storage/vms/dev
- `storagezfs-sandbox` → storage/vms/sandbox
- `storagezfs-containers` → storage/containers

#### NFS Server Setup
Configured NFS exports for shared storage:
- `/storage/data/shared` - Read/write for all VMs (192.168.1.0/24)
- `/storage/data/media` - Read-only for VMs (192.168.1.0/24)
- `/storage/services` - Read/write for services (192.168.1.0/24)

#### Terraform Configuration
- ✅ Updated VM module default storage: `storagezfs`
- ✅ Added container storage variable
- ✅ Configured per-resource storage overrides
- ✅ Validated configuration

### Documentation ✅ (100% Complete)
- ✅ Updated architecture.md with actual pool names
- ✅ Created storage-setup-commands.md
- ✅ Documented ZFS data corruption issue
- ✅ Updated action items checklist
- ✅ Created this progress document

### SSH Access ✅
- ✅ Configured SSH key authentication for Proxmox host (100.68.123.106)
- ✅ Enabled automated command execution

---

## Pending Tasks

### Storage Maintenance
- [ ] Configure automated ZFS snapshots (sanoid or cron)
  - Daily snapshots with 7-day retention
  - Weekly snapshots with 4-week retention
  - Monthly snapshots with 3-month retention
- [ ] Set up monthly scrub schedule (1st of each month at 2 AM)
- [ ] Add ZFS monitoring to Grafana dashboard
- [ ] Deploy Proxmox Backup Server (PBS) as LXC container
- [ ] Test backup/restore procedure
- [ ] Document off-site backup process

### Infrastructure Deployment
- [ ] Create Prod VM via Terraform
  - OS: Debian 12 (headless)
  - Resources: TBD based on available capacity
  - Storage: storagezfs-prod
  - Purpose: Production Kubernetes node
- [ ] Create Dev VM via Terraform
  - OS: Debian 12 (headless)
  - Resources: TBD based on available capacity
  - Storage: storagezfs-dev
  - Purpose: Development/staging Kubernetes node
- [ ] Configure VMs to mount NFS shared storage at /mnt/shared

### Coolify Deployment Platform
- [ ] Create Coolify LXC container (Debian 12, 2 cores, 2GB RAM, 20GB disk)
- [ ] Install Coolify: `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash`
- [ ] Configure Coolify admin account
- [ ] Install Docker on Prod VM
- [ ] Install Docker on Dev VM
- [ ] Add Prod VM as deployment target (SSH key auth)
- [ ] Add Dev VM as deployment target (SSH key auth)
- [ ] Configure Git provider integration (GitHub/GitLab)
- [ ] Test deployment to Dev VM
- [ ] Test deployment to Prod VM
- [ ] Set up wildcard DNS for Coolify-managed domains

---

## Known Issues

### ZFS Data Corruption
- **File**: `storage/backup/vm-103-disk-0:<0x1>`
- **Status**: Documented, resolution deferred
- **Impact**: None on running VMs, 762GB space tied up
- **Details**: See [zfs-data-corruption.md](zfs-data-corruption.md)
- **Action**: Will address after VM 103 issues are resolved

### APT Warnings on Proxmox Host
- Duplicate package sources (nvidia.list, pve-no-subscription)
- Missing NVIDIA GPG keys
- **Impact**: Cosmetic warnings, no functional impact
- **Action**: Can be cleaned up later if needed

---

## Next Session Priorities

1. **Quick Wins** (30-45 minutes):
   - Set up monthly ZFS scrub schedule
   - Configure basic ZFS snapshot automation

2. **Infrastructure Deployment** (1-2 hours):
   - Create Coolify LXC container
   - Install and configure Coolify

3. **VM Deployment** (2-3 hours):
   - Define Prod/Dev VM specs in Terraform
   - Deploy VMs via Terraform
   - Install Docker
   - Configure Coolify deployment targets

---

## Architecture Decisions Made

1. **No Services VM**: Services will run in Docker on Proxmox host instead of dedicated VM
2. **Environment Separation**: Separate ZFS datasets and Proxmox storage for prod/dev/sandbox
3. **Shared Storage**: NFS for shared data between VMs rather than duplicating data
4. **Storage Defaults**: New VMs/containers default to ZFS pool, not LVM
5. **Sandbox VM**: Will reuse dad-sandbox VM (VM 103) once issues are resolved

---

## Resource Allocation

### Current Storage Usage
- Total: 10.9TB
- Used: 1.28TB (11%)
- Available: 9.63TB
- Quotas allocated: ~4.9TB
- Unallocated: ~4.7TB

### Proxmox Storage
- NVMe (local): 71GB (64% used) - ISOs and templates
- LVM (local-lvm): 148GB (18% used) - Some existing VMs
- ZFS (various): 7.6TB (14% used) - New infrastructure

---

## References

- [Architecture Document](architecture.md) - Overall system design
- [Storage Setup Commands](storage-setup-commands.md) - Step-by-step storage configuration
- [ZFS Data Corruption](zfs-data-corruption.md) - Known issue documentation
