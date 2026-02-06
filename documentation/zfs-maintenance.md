# ZFS Maintenance Configuration

## Automated Scrub Schedule

**Status**: ✅ Configured and active

### Schedule Details
- **Frequency**: Monthly
- **Day**: 1st of each month
- **Time**: 2:00 AM EST
- **Pool**: `storage`
- **Duration**: ~43 minutes (based on last scrub)

### Cron Configuration
```bash
# ZFS monthly scrub - runs on 1st of each month at 2 AM
0 2 1 * * /usr/sbin/zpool scrub storage
```

### Scrub History
- **Last scrub**: January 11, 2026 at 1:07 AM
  - Duration: 43 minutes 22 seconds
  - Data repaired: 0B
  - Errors found: 4 (documented in zfs-data-corruption.md)
- **Next scheduled scrub**: March 1, 2026 at 2:00 AM

### Manual Scrub Commands
```bash
# Start a manual scrub
zpool scrub storage

# Stop a running scrub
zpool scrub -s storage

# Check scrub status
zpool status storage | grep scan

# View detailed status
zpool status -v storage
```

### What Scrubs Do
- **Purpose**: Detect and repair data corruption
- **Process**: Reads all data blocks and verifies checksums
- **Impact**: Low performance impact, safe to run while system is active
- **Frequency**: Monthly is recommended for home use
- **RAIDZ1 Benefits**: Can automatically repair corrupt blocks using parity

### Monitoring Scrub Results
Check scrub results via:
1. **Proxmox Web UI**: Node → Storage → ZFS → Select pool
2. **Command line**: `zpool status storage`
3. **Email alerts**: Configure Proxmox to send email on ZFS errors (TODO)

---

## Automated Snapshots

**Status**: ⏳ Pending configuration

### Planned Configuration
Using **sanoid** for automated snapshot management:

```bash
# Install sanoid
apt install sanoid

# Configuration: /etc/sanoid/sanoid.conf
[storage/vms/prod]
  use_template = production
  recursive = yes

[storage/vms/dev]
  use_template = development
  recursive = yes

[storage/vms/sandbox]
  use_template = testing
  recursive = yes

[storage/data]
  use_template = backup
  recursive = yes

[template_production]
  frequently = 0
  hourly = 24
  daily = 7
  weekly = 4
  monthly = 3
  yearly = 0
  autosnap = yes
  autoprune = yes

[template_development]
  frequently = 0
  hourly = 12
  daily = 3
  weekly = 2
  monthly = 1
  yearly = 0
  autosnap = yes
  autoprune = yes

[template_testing]
  frequently = 0
  hourly = 4
  daily = 1
  weekly = 0
  monthly = 0
  yearly = 0
  autosnap = yes
  autoprune = yes

[template_backup]
  frequently = 0
  hourly = 0
  daily = 7
  weekly = 4
  monthly = 6
  yearly = 0
  autosnap = yes
  autoprune = yes
```

### Snapshot Retention Policy
| Environment | Hourly | Daily | Weekly | Monthly | Total Snapshots |
|-------------|--------|-------|--------|---------|-----------------|
| Production  | 24     | 7     | 4      | 3       | 38              |
| Development | 12     | 3     | 2      | 1       | 18              |
| Sandbox     | 4      | 1     | 0      | 0       | 5               |
| Data/Backup | 0      | 7     | 4      | 6       | 17              |

### Manual Snapshot Commands
```bash
# Create snapshot
zfs snapshot storage/vms/prod@manual-$(date +%Y%m%d-%H%M%S)

# List snapshots
zfs list -t snapshot

# Rollback to snapshot
zfs rollback storage/vms/prod@snapshot-name

# Delete snapshot
zfs destroy storage/vms/prod@snapshot-name

# Send snapshot to another system (backup)
zfs send storage/vms/prod@snapshot-name | ssh backup-host zfs receive backup/prod
```

---

## ZFS Health Monitoring

### Daily Checks (Manual or Automated)
```bash
# Pool health
zpool status storage

# Capacity
zfs list -o name,used,avail,refer,quota storage

# Recent errors
zpool status -v storage | grep -A 10 errors

# ARC statistics
arc_summary
```

### Recommended Grafana Metrics
- Pool health status (ONLINE/DEGRADED/FAULTED)
- Used/available space per dataset
- Quota utilization percentage
- Scrub age (days since last scrub)
- ARC hit rate
- SMART data for each disk

### Alert Thresholds
- **Critical**: Pool degraded or faulted
- **Warning**: Dataset >90% of quota
- **Warning**: Scrub older than 35 days
- **Warning**: SMART errors detected
- **Info**: Scrub completed with errors

---

## Backup Strategy

### On-Site Backups (Proxmox Backup Server)
- **Status**: Pending deployment
- **Schedule**: Daily incremental backups
- **Retention**: 14 days
- **Location**: `storage/backups` dataset

### Off-Site Backups
- **Status**: Pending configuration
- **Method**: ZFS send/receive or PBS remote sync
- **Schedule**: Weekly
- **Target**: External USB drive or cloud storage (Backblaze B2, Wasabi)
- **Retention**: 4 weeks

### 3-2-1 Backup Rule
- ✅ 3 copies: Original + PBS + Off-site
- ✅ 2 media types: ZFS + External/Cloud
- ⏳ 1 off-site: Pending configuration

---

## Maintenance Calendar

| Day of Month | Task | Duration | Impact |
|--------------|------|----------|--------|
| 1st @ 2 AM | ZFS scrub | ~45 min | Low |
| Weekly | Review monitoring alerts | 10 min | None |
| Monthly | Review SMART data | 15 min | None |
| Quarterly | Test backup restore | 1 hour | Test VM only |

---

## Recovery Procedures

### Disk Failure (RAIDZ1)
```bash
# 1. Check pool status
zpool status storage

# 2. Replace failed disk (after physical replacement)
zpool replace storage /dev/old-disk /dev/new-disk

# 3. Monitor resilver progress
watch zpool status storage
```

### Data Corruption
```bash
# 1. Identify corrupted files
zpool status -v storage

# 2. Restore from snapshot
zfs rollback storage/vms/prod@snapshot-name

# 3. Or restore specific file from snapshot
cp /storage/vms/prod/.zfs/snapshot/snapshot-name/path/to/file /restore/location
```

### Accidental Deletion
```bash
# 1. List available snapshots
zfs list -t snapshot -r storage/vms/prod

# 2. Access snapshot directly
ls /storage/vms/prod/.zfs/snapshot/

# 3. Restore entire dataset or specific files
zfs rollback storage/vms/prod@snapshot-name
# OR
cp -r /storage/vms/prod/.zfs/snapshot/snapshot-name/* /storage/vms/prod/
```

---

## References
- [ZFS Administration Guide](https://openzfs.github.io/openzfs-docs/)
- [Sanoid Documentation](https://github.com/jimsalterjrs/sanoid)
- [Proxmox ZFS Documentation](https://pve.proxmox.com/wiki/ZFS_on_Linux)
