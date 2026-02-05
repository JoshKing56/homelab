# Overall architecture
There should only be a few VMs, each with a specific usecase
1. Prod: This should be where _stable_ and _tested_ software should be deployed to
2. Dev: This should be a copy of prod architecturally, but where software can be deployed and tested
3. Sandbox: The unstable vm. Can be nuked at a moments notice, and where things can be tested. We can rename dad-sandbox and use as the sandbox
4. Services: This is the VM we can use to host COTS services and self-hosted tools. Anything from CICD to NAS to a shared calendar
5. Services failover: This is a future feature, we can start without it
6. Batch jobs/Automation: CICD runners, cron tasks. <!-- TODO: Do we need this-->
7. Workstation/VDI machines: As Needed

# VMS
I should define the resource allocation for each vm not in static numbers, but in terms of the data and util I get from `proxmox_virtual_environment_nodes`. 
## Prod and Dev for development
OS: Debian, headless
Running: Kubernetes with Docker
Should be on separate vnets

## Sandbox
OS: This can stay as ubuntu with a UI
Schedule a complete wipe every x number of days
On it's own vnet

## Services
May have to split this into multiple vms. Unsure yet.
Probably run a kuberntes cluster with lots of different services.
OS: Debian, may be useful to run a UI. Decide this once we have a more concrete list of what we want to run

## Batch jobs
Not sure if we need this, but I was thinking if we have to do routine backup jobs, or use this VM to host CICD runners

## Workstation
UI based, 

# Setup and manage VMs
- Set up on Packer
- Provision through terraform

# Networking
- Have both internal/external facing DNS. Should be simple to switch 
- Proxmox has an SDN capability

# Services and Tools 
## DNS/Auth/SSL
- [Netbox](https://netboxlabs.com/)
- [Nginx proxy manager](https://nginxproxymanager.com/)
- [Traefik](https://doc.traefik.io/traefik/)
- Proxmox 

## Deploy: Coolify

[Coolify](https://coolify.io/self-hosted/) is a self-hosted PaaS that handles deployments, SSL, and basic CI/CD.

### Architecture
```
┌─────────────────────────────────────────────────────────┐
│                     PROXMOX HOST                        │
├─────────────────────────────────────────────────────────┤
│  LXC: coolify                                           │
│    └── Coolify server (management UI, API)              │
│                                                         │
│  VM: prod                                               │
│    └── Coolify agent → production deployments           │
│                                                         │
│  VM: dev                                                │
│    └── Coolify agent → development/staging deployments  │
└─────────────────────────────────────────────────────────┘
```

### Components
- **Coolify Server (LXC):** Management interface, handles Git webhooks, orchestrates deployments
- **Coolify Agent (Prod VM):** Receives deployment commands, runs production containers
- **Coolify Agent (Dev VM):** Receives deployment commands, runs dev/staging containers

### LXC Requirements
- **OS:** Debian 12 (bookworm)
- **Resources:** 2 cores, 2GB RAM, 20GB disk
- **Network:** Static IP, accessible from Prod/Dev VMs
- **Privileged:** May need privileged container for Docker-in-LXC

### Deployment Flow
1. Push code to Git repo (GitHub, GitLab, Gitea)
2. Webhook triggers Coolify server
3. Coolify builds image (or pulls pre-built)
4. Coolify deploys to target server (Prod or Dev) via agent
5. Coolify configures reverse proxy and SSL automatically

### Configuration
```bash
# On Coolify LXC - install Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# On Prod/Dev VMs - install Docker and Coolify agent
curl -fsSL https://get.docker.com | sh
# Then add as "Server" in Coolify UI with SSH key
```

### Why Coolify over alternatives
- **vs Kubero:** Simpler, doesn't require Kubernetes
- **vs Kamal:** More features (UI, SSL, databases), less config
- **vs GitLab CI:** Lower resource footprint, built-in deployment targets
- Handles CI/CD, so no need for separate GitLab/Jenkins

## Artifact management
- Artifactory??? Pretty sure there's no free version. TODO research this.

## Monitoring and alerting
- Telegraf
- Influx
- Grafana
- Prometheus???

# Storage Architecture

## Current Setup
- **Hardware:** 4 drives total
  - 1x NVMe (256GB) - Proxmox host OS, EFI partition
  - 3x HDD (4TB each) - Data storage in RAIDZ1-0 configuration
- **Current ZFS Configuration:** RAIDZ1-0 pool (3x 4TB = ~8TB usable with single-disk fault tolerance)
- **Proxmox Storage:** `storagezfs` pool (referenced in Terraform modules)

## Storage Strategy Options

### Option 1: Leverage Existing RAIDZ1 with NVMe Boot (Recommended)
**Best for:** Your current setup - maximizes existing redundancy

**Configuration:**
```
├── local (NVMe 256GB)           → Proxmox OS, ISO storage, CT templates
└── raidz1-pool (3x 4TB = 8TB)   → All VM/CT disks, data, backups
    ├── /vms/prod                → Production VM disks
    ├── /vms/dev                 → Development VM disks
    ├── /vms/services            → Services VM disks
    ├── /containers              → LXC container rootfs
    ├── /data/shared             → NFS exports for VMs
    ├── /data/media              → Media files
    └── /backups                 → Proxmox backup target
```

**Pros:**
- **Already has redundancy** (can lose 1 drive without data loss)
- 8TB usable space is plenty for homelab
- Single pool simplifies management
- NVMe dedicated to host OS keeps it fast
- ZFS snapshots/replication across all data

**Cons:**
- NVMe not used for VM storage (but 256GB is small anyway)
- All VMs share HDD performance (acceptable for homelab)
- RAIDZ1 write performance penalty (mitigated by ZFS caching)

**Use Cases:**
- Everything except Proxmox OS → RAIDZ1 pool
- ISO files, templates → NVMe local storage
- Daily snapshots with 7-14 day retention

---

## Implementation: **Use Existing RAIDZ1 with Organized Datasets**

### Implementation Plan

#### 1. Storage Pool Configuration
```bash
# Verify current pools
zpool list
zpool status

# Identify your RAIDZ1 pool name (likely 'rpool', 'tank', or 'storagezfs')
# Replace 'raidz1-pool' below with your actual pool name

# Create datasets for organization
zfs create raidz1-pool/vms
zfs create raidz1-pool/vms/prod
zfs create raidz1-pool/vms/dev
zfs create raidz1-pool/vms/services
zfs create raidz1-pool/containers
zfs create raidz1-pool/data
zfs create raidz1-pool/data/shared
zfs create raidz1-pool/data/media
zfs create raidz1-pool/backups

# Enable compression (saves space, minimal CPU cost)
zfs set compression=lz4 raidz1-pool

# Set reasonable quotas to prevent runaway growth
zfs set quota=500G raidz1-pool/vms/prod
zfs set quota=300G raidz1-pool/vms/dev
zfs set quota=200G raidz1-pool/vms/services
zfs set quota=2T raidz1-pool/data/media
```

#### 2. Proxmox Storage Configuration
Add to Proxmox via GUI (Datacenter → Storage) or CLI:
```bash
# Main RAIDZ1 pool for VMs and containers
# Replace 'raidz1-pool' with your actual pool name
pvesm add zfspool raidz1-storage --pool raidz1-pool --content images,rootdir

# Backup storage on same pool (different dataset)
pvesm add dir backup-storage --path /raidz1-pool/backups --content backup

# Optional: NFS share for shared data between VMs
pvesm add nfs shared-data --server 127.0.0.1 --export /raidz1-pool/data/shared --content iso,vztmpl

# Keep local (NVMe) for ISOs and templates only
# This is already configured by default as 'local'
```

#### 3. Data Placement Strategy
| Workload Type | Storage Target | Dataset | Notes |
|---------------|----------------|---------|-------|
| Prod VM disks | RAIDZ1 | /vms/prod | Redundant, good enough performance |
| Dev VM disks | RAIDZ1 | /vms/dev | Redundant, can snapshot/clone easily |
| Services VM | RAIDZ1 | /vms/services | Redundant |
| Sandbox VM | RAIDZ1 | /vms/dev | Use snapshots for easy rollback |
| LXC containers | RAIDZ1 | /containers | Small, compression helps |
| Shared NFS data | RAIDZ1 | /data/shared | Accessible from all VMs |
| Media/archives | RAIDZ1 | /data/media | Large files, compression effective |
| Proxmox backups | RAIDZ1 | /backups | Redundant backup storage |
| ISOs/templates | NVMe | local | Fast access, small files |

**Note:** Everything uses RAIDZ1 except ISOs. This is fine - HDD RAIDZ1 provides adequate performance for homelab VMs, and you get redundancy everywhere.

#### 4. Terraform Integration
Update `terraform/modules/vm/main.tf` and `terraform/modules/container/main.tf`:
```hcl
# Make storage configurable per VM
variable "storage_pool" {
  type    = string
  default = "raidz1-storage"  # Your RAIDZ1 pool
}

# In disk configuration
disk {
  datastore_id = var.storage_pool
  # ...
}
```

**Action:** Update the hardcoded `"storagezfs"` reference in your modules to use the actual Proxmox storage name you configured.

#### 5. Backup Strategy
- **Proxmox Backup Server (PBS):** Deploy as LXC container on RAIDZ1 (`/backups` dataset)
- **Snapshot schedule:** 
  - Daily ZFS snapshots: `zfs snapshot -r raidz1-pool@daily-$(date +%Y%m%d)`
  - Keep 7 daily, 4 weekly, 3 monthly
  - Automated via cron or sanoid
- **PBS backup schedule:** Daily VM backups, 14-day retention
- **Off-site:** Weekly sync to external USB drive or cloud (Backblaze B2, Wasabi)
  - Use `zfs send/receive` for efficient incremental backups
- **Critical data:** 3-2-1 rule (3 copies, 2 media types, 1 off-site)

**Snapshot automation example:**
```bash
# Install sanoid for automated snapshots
apt install sanoid

# /etc/sanoid/sanoid.conf
[raidz1-pool/vms]
  use_template = production
[raidz1-pool/data]
  use_template = backup
```

#### 6. Monitoring
Add to Grafana dashboard:
- **ZFS pool health:** `zpool status` (check for degraded/faulted)
- **Disk space usage:** Per dataset (`zfs list -o space`)
- **SMART metrics:** All 3 HDDs (reallocated sectors, temperature, errors)
- **Snapshot age and count:** Ensure snapshots are running
- **Scrub status:** Monthly scrubs to detect silent corruption
- **ARC hit rate:** Monitor ZFS cache effectiveness

**Set up monthly scrubs:**
```bash
# Add to crontab
0 2 1 * * /usr/sbin/zpool scrub raidz1-pool
```

---

## Future Considerations

### Storage Enhancements
- **Add 4th 4TB drive** → Upgrade to RAIDZ2 for 2-disk fault tolerance
- **Add 2x SSDs in mirror** → Fast tier for databases/containers if HDD performance becomes a bottleneck
- **NVMe special vdev** → Accelerate metadata operations (advanced, adds risk)
- **External USB drive (4TB+)** → Off-site backup rotation

### Infrastructure
- **UPS** → Protect against power loss during writes (critical for ZFS)
- **10GbE NIC** → If doing heavy NFS/iSCSI workloads between VMs

### Advanced ZFS Features
- **ZFS replication** between Prod/Dev for quick cloning
- **Encryption** for sensitive data datasets
- **NFS kernel server** for shared storage between VMs

---

## Action Items
- [ ] Run `zpool list` and `zpool status` to verify RAIDZ1 health
- [ ] Run `zfs list` to see current dataset structure
- [ ] Create organized datasets (vms/prod, vms/dev, containers, data, backups)
- [ ] Enable compression: `zfs set compression=lz4 <pool-name>`
- [ ] Set quotas per dataset to prevent runaway growth
- [ ] Update Terraform modules to reference correct Proxmox storage name
- [ ] Deploy Proxmox Backup Server (PBS) as LXC container
- [ ] Configure automated ZFS snapshots (sanoid or cron)
- [ ] Set up monthly scrub schedule
- [ ] Add ZFS monitoring to Grafana dashboard
- [ ] Test backup/restore procedure
- [ ] Document off-site backup process

### Coolify Setup
- [ ] Create Coolify LXC container (Debian 12, 2 cores, 2GB RAM, 20GB disk)
- [ ] Install Coolify on LXC: `curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash`
- [ ] Configure Coolify admin account and initial settings
- [ ] Install Docker on Prod VM
- [ ] Install Docker on Dev VM
- [ ] Add Prod VM as deployment target in Coolify (SSH key auth)
- [ ] Add Dev VM as deployment target in Coolify (SSH key auth)
- [ ] Configure Git provider integration (GitHub/GitLab)
- [ ] Test deployment to Dev VM
- [ ] Test deployment to Prod VM
- [ ] Set up wildcard DNS for Coolify-managed domains

# Backup and data management
See Storage Architecture section above for comprehensive backup strategy.