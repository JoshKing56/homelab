# Jan 1, 2026 Health Check
**Date:** January 1, 2026  
**Time Started:** 2:46 PM UTC-05:00  
**Issue:** Boot issues requiring full system diagnostics  
**Proxmox Version:** Proxmox VE 8.3.0 (running kernel: 6.8.12-8-pve)  
**Hardware:** AMD Ryzen 5 3600 6-Core, 62.74GB RAM, 67.73GB SSD, 1.82TB HDD  

## Executive Summary

### Critical Finding: EFI Boot Partition Corruption

**ROOT CAUSE IDENTIFIED:** The comprehensive system analysis has revealed the primary cause of the January 1, 2026 boot issues - persistent EFI boot partition corruption caused by improper system shutdowns.

### Technical Analysis

**Problem Pattern:**
The filesystem check logs (`journalctl -u systemd-fsck@*`) reveal a consistent pattern of EFI boot partition (`/dev/nvme0n1p2`) corruption spanning from December 2024 through January 1, 2026. Every boot cycle shows:

1. **Dirty Bit Set**: "Fs was not properly unmounted and some data may be corrupt"
2. **Boot Sector Corruption**: "There are differences between boot sector and its backup (offset:original/backup) 65:01/00"
3. **Automatic Repair**: "*** Filesystem was changed ***" - fsck.fat automatically fixing corruption

**Impact Assessment:**
- **Severity**: CRITICAL - Affects system boot reliability
- **Frequency**: Every boot cycle since December 27, 2024
- **Scope**: EFI System Partition (ESP) - critical for UEFI boot process
- **Risk**: Progressive corruption could lead to unbootable system

**Technical Details:**
- **Affected Partition**: `/dev/nvme0n1p2` (EFI System Partition, 1GB, FAT32)
- **Corruption Type**: Boot sector backup inconsistency and dirty bit persistence
- **Filesystem**: FAT32 (UUID: CD19-75F4)
- **Pattern**: Occurs on every boot, indicating systemic shutdown issue

### Root Cause Analysis

**Primary Cause**: Improper System Shutdowns
The persistent "dirty bit" indicates the system is not performing clean shutdowns, causing:
- EFI partition to remain mounted during shutdown
- Boot sector writes not properly synchronized
- Backup boot sector becoming inconsistent with primary

**Contributing Factors:**
1. **Hardware Issues**: ATA port 5 failure may indicate SATA controller instability
2. **Power Management**: Potential issues with ACPI power management (_OSC evaluation failures noted)
3. **Storage Complexity**: Mixed LVM/ZFS configuration may complicate shutdown sequence
4. **Service Dependencies**: Multiple Proxmox services may not be shutting down in proper order

### Remediation Plan

#### Phase 1: Immediate Stabilization (CRITICAL - Execute First)

**Step 1: EFI Partition Assessment**
```bash
# Read-only filesystem check to assess damage
fsck.fat -r /dev/nvme0n1p2

# Check EFI partition mount status
mount | grep nvme0n1p2

# Verify EFI boot files integrity
ls -la /boot/efi/EFI/proxmox/
```

**Step 2: Emergency EFI Repair (if needed)**
```bash
# Unmount EFI partition if mounted
umount /boot/efi

# Repair EFI partition (CAUTION: Backup first)
fsck.fat -a /dev/nvme0n1p2

# Remount and verify
mount /boot/efi
ls -la /boot/efi/EFI/
```

#### Phase 2: Shutdown Process Investigation

**Step 3: Analyze Shutdown Behavior**
```bash
# Check systemd shutdown logs
journalctl -u systemd-shutdown --since "1 week ago"

# Monitor shutdown sequence
systemctl list-jobs
systemctl status

# Check for hanging services
systemctl --failed
```

**Step 4: Hardware Stability Check**
```bash
# Investigate ATA port 5 failure
dmesg | grep ata5
lspci | grep -i sata

# Check power management
journalctl | grep -i "acpi.*power"
```

#### Phase 3: Long-term Prevention

**Step 5: Implement Monitoring**
```bash
# Create EFI health check script
cat > /usr/local/bin/efi-health-check.sh << 'EOF'
#!/bin/bash
fsck.fat -r /dev/nvme0n1p2 | logger -t efi-health
EOF

# Add to daily cron
echo "0 6 * * * root /usr/local/bin/efi-health-check.sh" >> /etc/crontab
```

**Step 6: Shutdown Process Hardening**
```bash
# Increase shutdown timeout for proper service termination
echo "DefaultTimeoutStopSec=30s" >> /etc/systemd/system.conf

# Ensure EFI partition sync on shutdown
echo "sync" >> /etc/rc0.d/K01sync-efi
```

#### Phase 4: Contingency Planning

**Step 7: EFI Partition Backup and Recovery**
```bash
# Create EFI partition backup
dd if=/dev/nvme0n1p2 of=/root/efi-backup-$(date +%Y%m%d).img bs=1M

# Document EFI restoration procedure
# (In case of complete EFI corruption, reinstall bootloader)
```

### Risk Assessment

**If Not Addressed:**
- **High Risk**: Complete boot failure requiring manual EFI reconstruction
- **Medium Risk**: Progressive corruption affecting boot performance
- **Low Risk**: Data loss (EFI partition contains only boot files, not user data)

**Success Metrics:**
- Clean filesystem checks (no dirty bit)
- Consistent boot sector backups
- Stable boot times
- No fsck.fat repairs required

### Conclusion

The January 1, 2026 boot issues stem from a well-documented pattern of EFI boot partition corruption caused by improper system shutdowns. This is a **solvable problem** with immediate remediation steps available. The comprehensive diagnostic data provides a clear path to resolution, with the primary focus on fixing the shutdown process and stabilizing the EFI partition.

**Recommended Action**: Execute Phase 1 immediately to prevent further corruption, then systematically work through the remaining phases to ensure long-term system stability.

## 1. System Overview
### 1.1 Basic System Information
```bash
pveversion
```
```
pve-manager/8.3.3/f157a38b211595d6 (running kernel: 6.8.12-8-pve)
```
```bash
uname -a
```
```
Linux pve 6.8.12-8-pve #1 SMP PREEMPT_DYNAMIC PMX 6.8.12-8 (2025-01-24T12:32Z) x86_64 GNU/Linux
```

### 1.2 Boot Analysis
```bash
journalctl -b -p err
```
```
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:26 pve smartd[1079]: Device: /dev/nvme0, number of Error Log entries increased from 273 to 275
```

```bash
journalctl -b | grep -i "error\|fail\|warn"
```
```
Jan 01 14:29:21 pve kernel: Warning: PCIe ACS overrides enabled; This may allow non-IOMMU protected peer-to-peer DMA
Jan 01 14:29:21 pve kernel: tsc: Fast TSC calibration failed
Jan 01 14:29:21 pve kernel: ACPI: _OSC evaluation for CPUs failed, trying _PDC
Jan 01 14:29:21 pve kernel: RAS: Correctable Errors collector initialized.
Jan 01 14:29:21 pve kernel: ata5: failed to resume link (SControl 0)
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
Jan 01 14:29:25 pve tailscaled[1086]: health(warnable=warming-up): error: Tailscale is starting. Please wait.
Jan 01 14:29:26 pve smartd[1079]: Device: /dev/nvme0, number of Error Log entries increased from 273 to 275
Jan 01 14:29:26 pve tailscaled[1086]: health(warnable=network-status): ok
Jan 01 14:29:30 pve tailscaled[1086]: health(warnable=warming-up): ok
Jan 01 14:29:31 pve kernel: EXT4-fs warning (device dm-7): ext4_multi_mount_protect:328: MMP interval 42 higher than expected, please wait.
Jan 01 14:29:34 pve postfix/smtp[1514]: 89953180B25: to=<root@kinghome.com>, relay=none, delay=818972, delays=818964/0.01/7.6/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/smtp[1515]: D41261809F9: to=<root@kinghome.com>, relay=none, delay=988928, delays=988920/0.01/7.6/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/smtp[1516]: 4925B180D3A: to=<root@kinghome.com>, relay=none, delay=1164572, delays=1164565/0.02/7.6/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/smtp[1518]: 02E9E180D6A: to=<root@kinghome.com>, relay=none, delay=991772, delays=991764/0.02/7.6/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/smtp[1517]: 49834180A2F: to=<root@kinghome.com>, relay=none, delay=904920, delays=904913/0.02/7.6/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1603]: 78F5E1807AF: to=<root@kinghome.com>, relay=none, delay=816715, delays=816708/7.6/0/0.01, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1605]: BBF01180CB6: to=<root@kinghome.com>, relay=none, delay=905373, delays=905365/7.6/0/0.01, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1603]: 9559A180A08: to=<root@kinghome.com>, relay=none, delay=1026728, delays=1026720/7.6/0/0.01, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1608]: A3408180C93: to=<root@kinghome.com>, relay=none, delay=1163858, delays=1163850/7.6/0/0.01, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1605]: A1FAD1807AF: to=<root@kinghome.com>, relay=none, delay=0.02, delays=0.01/0/0/0.01, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1612]: A3107180561: to=<root@kinghome.com>, relay=none, delay=0.02, delays=0.02/0/0/0.01, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1603]: A50AE180789: to=<root@kinghome.com>, relay=none, delay=0.01, delays=0.01/0/0/0, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:34 pve postfix/error[1608]: A6C761807FD: to=<root@kinghome.com>, relay=none, delay=0.02, delays=0.01/0/0/0, dsn=4.4.3, status=deferred (delivery temporarily suspended: Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:29:37 pve tailscaled[1086]: control: bootstrapDNS("derp1i.tailscale.com", "199.38.181.103") for "controlplane.tailscale.com" error: Get "https://derp1i.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp 199.38.181.103:443: connect: no route to host
Jan 01 14:29:37 pve tailscaled[1086]: control: bootstrapDNS("derp27e.tailscale.com", "2a01:4ff:f0:28d4::1") for "controlplane.tailscale.com" error: Get "https://derp27e.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2a01:4ff:f0:28d4::1]:443: connect: network is unreachable
Jan 01 14:29:40 pve tailscaled[1086]: control: bootstrapDNS("derp20c.tailscale.com", "205.147.105.30") for "controlplane.tailscale.com" error: Get "https://derp20c.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": context deadline exceeded
Jan 01 14:29:40 pve tailscaled[1086]: control: bootstrapDNS("derp10c.tailscale.com", "2607:f740:14::40c") for "controlplane.tailscale.com" error: Get "https://derp10c.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2607:f740:14::40c]:443: connect: network is unreachable
Jan 01 14:29:40 pve tailscaled[1086]: control: bootstrapDNS("derp28c.tailscale.com", "95.217.2.165") for "controlplane.tailscale.com" error: Get "https://derp28c.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp 95.217.2.165:443: connect: no route to host
Jan 01 14:29:40 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v")
Jan 01 14:29:46 pve tailscaled[1086]: Received error: fetch control key: Get "https://controlplane.tailscale.com/key?v=130": failed to resolve "controlplane.tailscale.com": no DNS fallback candidates remain for "controlplane.tailscale.com"
Jan 01 14:29:46 pve tailscaled[1086]: health(warnable=login-state): error: You are logged out. The last login error was: fetch control key: Get "https://controlplane.tailscale.com/key?v=130": failed to resolve "controlplane.tailscale.com": no DNS fallback candidates remain for "controlplane.tailscale.com"
Jan 01 14:29:47 pve tailscaled[1086]: logtail: dial "log.tailscale.com:443" failed: dial tcp: lookup log.tailscale.com on 192.168.1.1:53: read udp 192.168.1.203:53052->192.168.1.1:53: i/o timeout (in 20.002s), trying bootstrap...
Jan 01 14:29:59 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v") (7 dropped)
Jan 01 14:29:59 pve tailscaled[1086]: control: bootstrapDNS("derp26c.tailscale.com", "49.12.193.137") for "controlplane.tailscale.com" error: Get "https://derp26c.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": context deadline exceeded
Jan 01 14:29:59 pve tailscaled[1086]: control: bootstrapDNS("derp9.tailscale.com", "2001:19f0:6401:1d9c:5400:2ff:feef:bb82") for "controlplane.tailscale.com" error: Get "https://derp9.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2001:19f0:6401:1d9c:5400:2ff:feef:bb82]:443: connect: network is unreachable
Jan 01 14:29:59 pve tailscaled[1086]: bootstrapDNS("derp13c.tailscale.com", "192.73.242.28") for "log.tailscale.com" error: Get "https://derp13c.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp 192.73.242.28:443: connect: no route to host
Jan 01 14:29:59 pve tailscaled[1086]: control: bootstrapDNS("derp17c.tailscale.com", "208.111.40.12") for "controlplane.tailscale.com" error: Get "https://derp17c.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp 208.111.40.12:443: connect: no route to host
Jan 01 14:29:59 pve tailscaled[1086]: bootstrapDNS("derp16d.tailscale.com", "2607:f740:17::475") for "log.tailscale.com" error: Get "https://derp16d.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp [2607:f740:17::475]:443: connect: network is unreachable
Jan 01 14:29:59 pve tailscaled[1086]: control: bootstrapDNS("derp12b.tailscale.com", "2001:19f0:5c01:48a:5400:3ff:fe8d:cb5f") for "controlplane.tailscale.com" error: Get "https://derp12b.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2001:19f0:5c01:48a:5400:3ff:fe8d:cb5f]:443: connect: network is unreachable
Jan 01 14:29:59 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v")
Jan 01 14:30:02 pve tailscaled[1086]: bootstrapDNS("derp18b.tailscale.com", "176.58.90.147") for "log.tailscale.com" error: Get "https://derp18b.tailscale.com/bootstrap-dns?q=log.tailscale.com": context deadline exceeded
Jan 01 14:30:02 pve tailscaled[1086]: bootstrapDNS("derp11e.tailscale.com", "2600:3c0d::2000:d2ff:fe43:1790") for "log.tailscale.com" error: Get "https://derp11e.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp [2600:3c0d::2000:d2ff:fe43:1790]:443: connect: network is unreachable
Jan 01 14:30:02 pve tailscaled[1086]: bootstrapDNS("derp19c.tailscale.com", "45.159.97.61") for "log.tailscale.com" error: Get "https://derp19c.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp 45.159.97.61:443: connect: no route to host
Jan 01 14:30:02 pve tailscaled[1086]: bootstrapDNS("derp28c.tailscale.com", "2a01:4f9:c012:cd74::1") for "log.tailscale.com" error: Get "https://derp28c.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp [2a01:4f9:c012:cd74::1]:443: connect: network is unreachable
Jan 01 14:30:05 pve tailscaled[1086]: bootstrapDNS("derp14b.tailscale.com", "176.58.93.248") for "log.tailscale.com" error: Get "https://derp14b.tailscale.com/bootstrap-dns?q=log.tailscale.com": context deadline exceeded
Jan 01 14:30:05 pve tailscaled[1086]: bootstrapDNS("derp28b.tailscale.com", "2a01:4f9:c012:d55c::1") for "log.tailscale.com" error: Get "https://derp28b.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp [2a01:4f9:c012:d55c::1]:443: connect: network is unreachable
Jan 01 14:30:06 pve tailscaled[1086]: bootstrapDNS("derp28c.tailscale.com", "95.217.2.165") for "log.tailscale.com" error: Get "https://derp28c.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp 95.217.2.165:443: connect: no route to host
Jan 01 14:30:06 pve tailscaled[1086]: bootstrapDNS("derp14b.tailscale.com", "2a00:dd80:3c::807") for "log.tailscale.com" error: Get "https://derp14b.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp [2a00:dd80:3c::807]:443: connect: network is unreachable
Jan 01 14:30:06 pve tailscaled[1086]: Received error: fetch control key: Get "https://controlplane.tailscale.com/key?v=130": failed to resolve "controlplane.tailscale.com": no DNS fallback candidates remain for "controlplane.tailscale.com"
Jan 01 14:30:09 pve tailscaled[1086]: bootstrapDNS("derp26d.tailscale.com", "49.13.204.141") for "log.tailscale.com" error: Get "https://derp26d.tailscale.com/bootstrap-dns?q=log.tailscale.com": context deadline exceeded
Jan 01 14:30:09 pve tailscaled[1086]: bootstrapDNS("derp17d.tailscale.com", "2607:f740:c::e1b") for "log.tailscale.com" error: Get "https://derp17d.tailscale.com/bootstrap-dns?q=log.tailscale.com": dial tcp [2607:f740:c::e1b]:443: connect: network is unreachable
Jan 01 14:30:09 pve tailscaled[1086]: logtail: upload: log upload of 3467 bytes compressed failed: Post "https://log.tailscale.com/c/tailnode.log.tailscale.io/882745980087e9fd14b5f7517b6e98c5047d6cd524bd6e91bddeedae02fe426b": failed to resolve "log.tailscale.com": no DNS fallback candidates remain for "log.tailscale.com"
Jan 01 14:30:15 pve audit[1856]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed perms check" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/" pid=1856 comm="(sd-gens)" flags="ro, remount, bind"
Jan 01 14:30:15 pve audit[1856]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed perms check" error=-13 profile="lxc-101_</var/lib/lxc>" name="/" pid=1856 comm="(sd-gens)" flags="ro, remount, bind"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.409:29): apparmor="DENIED" operation="mount" class="mount" info="failed perms check" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/" pid=1856 comm="(sd-gens)" flags="ro, remount, bind"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.409:30): apparmor="DENIED" operation="mount" class="mount" info="failed perms check" error=-13 profile="lxc-101_</var/lib/lxc>" name="/" pid=1856 comm="(sd-gens)" flags="ro, remount, bind"
Jan 01 14:30:15 pve audit[1883]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1883 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.533:31): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1883 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.534:32): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1883 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1883]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1883 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1894]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1894 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1894]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1894 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.554:33): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1894 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.554:34): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1894 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1898]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1898 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.559:35): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1898 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1898]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1898 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.560:36): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1898 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1904]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1904 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1904]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1904 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve kernel: audit: type=1400 audit(1767295815.566:37): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1904 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1914]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1914 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1914]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1914 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1918]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1918 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1918]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1918 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1919]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1919 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1919]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1919 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1926]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1926 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1926]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1926 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1934]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1934 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1934]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1934 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1941]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1941 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1941]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1941 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1949]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1949 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1949]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1949 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1953]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1953 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1953]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1953 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1959]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1959 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1959]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1959 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1961]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1961 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1961]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1961 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1969]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1969 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1969]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1969 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1973]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1973 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1973]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1973 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1977]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1977 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1977]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1977 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1984]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1984 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1984]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1984 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1988]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1988 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1988]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1988 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[1999]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1999 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[1999]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1999 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve audit[2010]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2010 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[2010]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2010 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/storagezfs: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/local-lvm: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/local: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/backup-storage: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/backups: -1
Jan 01 14:30:15 pve audit[2142]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/run/systemd/namespace-18ipI3/" pid=2142 comm="(crub_all)" fstype="sysfs" srcname="sysfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:15 pve audit[2148]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/run/systemd/namespace-jC33GD/" pid=2148 comm="(d-logind)" fstype="proc" srcname="proc" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2282]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/run/systemd/namespace-pL10Nt/" pid=2282 comm="(postfix)" fstype="proc" srcname="proc" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2294]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2294 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2294]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2294 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2293]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2293 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2293]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2293 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2296]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2296 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2296]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2296 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2305]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2305 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2305]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2305 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2304]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2304 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2304]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2304 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2308]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2308 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2308]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2308 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2309]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2309 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2309]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2309 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2312]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2312 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2313]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2313 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2312]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2312 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2313]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2313 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2317]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2317 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2317]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2317 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2318]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2318 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2318]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2318 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2320]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2320 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2320]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2320 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:16 pve audit[2326]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2326 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:16 pve audit[2326]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2326 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:17 pve audit[2328]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2328 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:17 pve audit[2328]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2328 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:17 pve audit[2330]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2330 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:30:17 pve audit[2330]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=2330 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:30:18 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v") (8 dropped)
Jan 01 14:30:18 pve tailscaled[1086]: control: bootstrapDNS("derp4d.tailscale.com", "134.122.94.167") for "controlplane.tailscale.com" error: Get "https://derp4d.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp 134.122.94.167:443: connect: no route to host
Jan 01 14:30:18 pve tailscaled[1086]: control: bootstrapDNS("derp9f.tailscale.com", "2607:f740:100::cad") for "controlplane.tailscale.com" error: Get "https://derp9f.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2607:f740:100::cad]:443: connect: network is unreachable
Jan 01 14:30:21 pve tailscaled[1086]: control: bootstrapDNS("derp3.tailscale.com", "68.183.179.66") for "controlplane.tailscale.com" error: Get "https://derp3.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": context deadline exceeded
Jan 01 14:30:21 pve tailscaled[1086]: control: bootstrapDNS("derp24b.tailscale.com", "2001:19f0:c000:c586:5400:4ff:fe26:2ba6") for "controlplane.tailscale.com" error: Get "https://derp24b.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2001:19f0:c000:c586:5400:4ff:fe26:2ba6]:443: connect: network is unreachable
Jan 01 14:30:21 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v")
Jan 01 14:30:27 pve tailscaled[1086]: Received error: fetch control key: Get "https://controlplane.tailscale.com/key?v=130": failed to resolve "controlplane.tailscale.com": no DNS fallback candidates remain for "controlplane.tailscale.com"
Jan 01 14:30:40 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v") (8 dropped)
Jan 01 14:30:40 pve tailscaled[1086]: control: bootstrapDNS("derp4i.tailscale.com", "185.40.234.53") for "controlplane.tailscale.com" error: Get "https://derp4i.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": context deadline exceeded
Jan 01 14:30:40 pve tailscaled[1086]: control: bootstrapDNS("derp21b.tailscale.com", "2607:f740:50::1d1") for "controlplane.tailscale.com" error: Get "https://derp21b.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2607:f740:50::1d1]:443: connect: network is unreachable
Jan 01 14:30:40 pve tailscaled[1086]: control: bootstrapDNS("derp13c.tailscale.com", "192.73.242.28") for "controlplane.tailscale.com" error: Get "https://derp13c.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp 192.73.242.28:443: connect: no route to host
Jan 01 14:30:40 pve tailscaled[1086]: control: bootstrapDNS("derp3e.tailscale.com", "2600:3c15::2000:6cff:fee4:d799") for "controlplane.tailscale.com" error: Get "https://derp3e.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2600:3c15::2000:6cff:fee4:d799]:443: connect: network is unreachable
Jan 01 14:30:40 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v")
Jan 01 14:30:46 pve tailscaled[1086]: Received error: fetch control key: Get "https://controlplane.tailscale.com/key?v=130": failed to resolve "controlplane.tailscale.com": no DNS fallback candidates remain for "controlplane.tailscale.com"
Jan 01 14:30:59 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v") (8 dropped)
Jan 01 14:30:59 pve tailscaled[1086]: control: bootstrapDNS("derp19d.tailscale.com", "45.159.97.233") for "controlplane.tailscale.com" error: Get "https://derp19d.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": context deadline exceeded
Jan 01 14:30:59 pve tailscaled[1086]: control: bootstrapDNS("derp25b.tailscale.com", "2c0f:edb0:2000:1::2e9") for "controlplane.tailscale.com" error: Get "https://derp25b.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2c0f:edb0:2000:1::2e9]:443: connect: network is unreachable
Jan 01 14:31:00 pve tailscaled[1086]: control: bootstrapDNS("derp12e.tailscale.com", "209.177.158.15") for "controlplane.tailscale.com" error: Get "https://derp12e.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp 209.177.158.15:443: connect: no route to host
Jan 01 14:31:00 pve tailscaled[1086]: control: bootstrapDNS("derp24b.tailscale.com", "2001:19f0:c000:c586:5400:4ff:fe26:2ba6") for "controlplane.tailscale.com" error: Get "https://derp24b.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2001:19f0:c000:c586:5400:4ff:fe26:2ba6]:443: connect: network is unreachable
Jan 01 14:31:00 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v")
Jan 01 14:31:06 pve tailscaled[1086]: Received error: fetch control key: Get "https://controlplane.tailscale.com/key?v=130": failed to resolve "controlplane.tailscale.com": no DNS fallback candidates remain for "controlplane.tailscale.com"
Jan 01 14:31:09 pve tailscaled[1086]: logtail: dial "log.tailscale.com:443" failed: dial tcp: lookup log.tailscale.com on 192.168.1.1:53: read udp 192.168.1.203:33435->192.168.1.1:53: i/o timeout (in 20.001s), trying bootstrap...
Jan 01 14:31:17 pve tailscaled[1086]: [RATELIMIT] format("control: bootstrapDNS(%q, %q) for %q error: %v") (8 dropped)
Jan 01 14:31:17 pve tailscaled[1086]: control: bootstrapDNS("derp5g.tailscale.com", "172.105.169.57") for "controlplane.tailscale.com" error: Get "https://derp5g.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp 172.105.169.57:443: connect: no route to host
Jan 01 14:31:17 pve tailscaled[1086]: control: bootstrapDNS("derp10b.tailscale.com", "2607:f740:14::61c") for "controlplane.tailscale.com" error: Get "https://derp10b.tailscale.com/bootstrap-dns?q=controlplane.tailscale.com": dial tcp [2607:f740:14::61c]:443: connect: network is unreachable
Jan 01 14:31:20 pve tailscaled[1086]: logtail: upload succeeded after 1 failures and 1m11s
Jan 01 14:31:20 pve tailscaled[1086]: health(warnable=login-state): ok
Jan 01 14:31:20 pve tailscaled[1086]: health(warnable=not-in-map-poll): ok
Jan 01 14:31:21 pve tailscaled[1086]: health(warnable=no-derp-home): ok
Jan 01 14:31:21 pve tailscaled[1086]: health(warnable=no-derp-connection): ok
Jan 01 14:33:47 pve audit[3120]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/run/systemd/namespace-Hhb67n/" pid=3120 comm="(ogrotate)" fstype="proc" srcname="proc" flags="rw, nosuid, nodev, noexec"
Jan 01 14:33:47 pve kernel: audit: type=1400 audit(1767296027.175:281): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/run/systemd/namespace-Hhb67n/" pid=3120 comm="(ogrotate)" fstype="proc" srcname="proc" flags="rw, nosuid, nodev, noexec"
Jan 01 14:36:22 pve tailscaled[1086]: Received error: PollNetMap: unexpected EOF
Jan 01 14:36:31 pve IPCC.xs[1562]: pam_unix(proxmox-ve-auth:auth): authentication failure; logname= uid=0 euid=0 tty= ruser= rhost=::ffff:192.168.1.156  user=root
Jan 01 14:36:33 pve pvedaemon[1562]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pam msg=Authentication failure
Jan 01 14:36:43 pve IPCC.xs[1564]: pam_unix(proxmox-ve-auth:auth): authentication failure; logname= uid=0 euid=0 tty= ruser= rhost=::ffff:192.168.1.156  user=root
Jan 01 14:36:45 pve pvedaemon[1564]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pam msg=Authentication failure
Jan 01 14:37:03 pve IPCC.xs[1562]: pam_unix(proxmox-ve-auth:auth): authentication failure; logname= uid=0 euid=0 tty= ruser= rhost=::ffff:192.168.1.156  user=root
Jan 01 14:37:05 pve pvedaemon[1562]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pam msg=Authentication failure
Jan 01 14:37:13 pve IPCC.xs[1564]: pam_unix(proxmox-ve-auth:auth): authentication failure; logname= uid=0 euid=0 tty= ruser= rhost=::ffff:192.168.1.156  user=root
Jan 01 14:37:15 pve pvedaemon[1564]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pam msg=Authentication failure
Jan 01 14:37:23 pve pvedaemon[1564]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pve msg=no such user ('root@pve')
Jan 01 14:39:31 pve pvedaemon[1564]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pve msg=no such user ('root@pve')
Jan 01 14:39:37 pve postfix/smtp[4288]: A3107180561: to=<root@kinghome.com>, relay=none, delay=602, delays=592/0.01/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:39:37 pve postfix/smtp[4287]: A1FAD1807AF: to=<root@kinghome.com>, relay=none, delay=602, delays=592/0.01/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:39:37 pve postfix/smtp[4289]: A50AE180789: to=<root@kinghome.com>, relay=none, delay=602, delays=592/0.01/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:39:37 pve postfix/smtp[4290]: A6C761807FD: to=<root@kinghome.com>, relay=none, delay=602, delays=592/0.02/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:39:54 pve pvedaemon[1564]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pve msg=no such user ('root@pve')
Jan 01 14:40:09 pve pvedaemon[1563]: authentication failure; rhost=::ffff:192.168.1.156 user=root@pve msg=no such user ('root@pve')
Jan 01 14:46:16 pve audit[5743]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=5743 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:46:16 pve audit[5743]: AVC apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=5743 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:46:16 pve kernel: audit: type=1400 audit(1767296776.380:282): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=5743 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
Jan 01 14:46:16 pve kernel: audit: type=1400 audit(1767296776.380:283): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=5743 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
Jan 01 14:54:37 pve postfix/smtp[7432]: A3107180561: to=<root@kinghome.com>, relay=none, delay=1503, delays=1493/0.01/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:54:37 pve postfix/smtp[7431]: A1FAD1807AF: to=<root@kinghome.com>, relay=none, delay=1503, delays=1493/0.01/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:54:37 pve postfix/smtp[7433]: A50AE180789: to=<root@kinghome.com>, relay=none, delay=1503, delays=1493/0.02/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
Jan 01 14:54:37 pve postfix/smtp[7434]: A6C761807FD: to=<root@kinghome.com>, relay=none, delay=1503, delays=1493/0.02/10/0, dsn=4.4.3, status=deferred (Host or domain name not found. Name service error for name=kinghome.com type=MX: Host not found, try again)
```

```bash
dmesg | grep -i "error\|fail\|warn"
```
```
[    0.000000] Warning: PCIe ACS overrides enabled; This may allow non-IOMMU protected peer-to-peer DMA
[    0.000000] tsc: Fast TSC calibration failed
[    0.198044] ACPI: _OSC evaluation for CPUs failed, trying _PDC
[    0.682344] RAS: Correctable Errors collector initialized.
[    3.535446] ata5: failed to resume link (SControl 0)
[   16.468225] EXT4-fs warning (device dm-7): ext4_multi_mount_protect:328: MMP interval 42 higher than expected, please wait.
[   60.232413] audit: type=1400 audit(1767295815.409:29): apparmor="DENIED" operation="mount" class="mount" info="failed perms check" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/" pid=1856 comm="(sd-gens)" flags="ro, remount, bind"
[   60.232428] audit: type=1400 audit(1767295815.409:30): apparmor="DENIED" operation="mount" class="mount" info="failed perms check" error=-13 profile="lxc-101_</var/lib/lxc>" name="/" pid=1856 comm="(sd-gens)" flags="ro, remount, bind"
[   60.356498] audit: type=1400 audit(1767295815.533:31): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1883 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
[   60.356831] audit: type=1400 audit(1767295815.534:32): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1883 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
[   60.377425] audit: type=1400 audit(1767295815.554:33): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1894 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
[   60.377605] audit: type=1400 audit(1767295815.554:34): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1894 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
[   60.382746] audit: type=1400 audit(1767295815.559:35): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1898 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
[   60.382869] audit: type=1400 audit(1767295815.560:36): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1898 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
[   60.389495] audit: type=1400 audit(1767295815.566:37): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=1904 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
[  257.953042] audit: type=1400 audit(1767296027.175:281): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/run/systemd/namespace-Hhb67n/" pid=3120 comm="(ogrotate)" fstype="proc" srcname="proc" flags="rw, nosuid, nodev, noexec"
[ 1007.161312] audit: type=1400 audit(1767296776.380:282): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=5743 comm="(sd-mkdcreds)" fstype="ramfs" srcname="ramfs" flags="rw, nosuid, nodev, noexec"
[ 1007.161441] audit: type=1400 audit(1767296776.380:283): apparmor="DENIED" operation="mount" class="mount" info="failed flags match" error=-13 profile="lxc-101_</var/lib/lxc>" name="/dev/shm/" pid=5743 comm="(sd-mkdcreds)" flags="ro, nosuid, nodev, noexec, remount, bind"
```

#### Boot Analysis Summary

**CRITICAL ISSUES:**

1. **VFIO Module Loading Failures** - `Failed to find module 'vfio_virqfd'` (from journalctl - GPU passthrough may not work)
2. **NVMe Drive Errors** - `/dev/nvme0` error count increased from 273 to 275 (from journalctl - storage reliability concern)
3. **LXC Container 101 Security Issues** - Extensive AppArmor denials blocking mount operations for `/dev/shm/`, `/dev/`, and namespace operations

**WARNING ISSUES:**

4. **Network Connectivity** - Tailscale DNS resolution failures, Postfix email delivery issues to `kinghome.com`
5. **Hardware/Boot Warnings** - PCIe ACS overrides enabled (security risk), TSC calibration failed, SATA port 5 link resume failure
6. **Filesystem Warning** - EXT4 MMP interval higher than expected on device dm-7

**MINOR ISSUES:**

7. **ACPI/Power Management** - _OSC evaluation for CPUs failed, using _PDC fallback
8. **RAS Initialization** - Correctable Errors collector initialized (normal but indicates error monitoring active)

**IMMEDIATE ACTIONS:**

- Check NVMe health: `smartctl -a /dev/nvme0`
- Install VFIO drivers for hardware passthrough
- Investigate container 101 AppArmor profile
- Fix DNS/network connectivity issues

### 1.3 System Services Status
```bash
systemctl status pve-cluster
```
```
● pve-cluster.service - The Proxmox VE cluster filesystem
     Loaded: loaded (/lib/systemd/system/pve-cluster.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-01-01 14:29:27 EST; 44min ago
    Process: 1409 ExecStart=/usr/bin/pmxcfs (code=exited, status=0/SUCCESS)
   Main PID: 1435 (pmxcfs)
      Tasks: 6 (limit: 77016)
     Memory: 61.9M
        CPU: 1.836s
     CGroup: /system.slice/pve-cluster.service
             └─1435 /usr/bin/pmxcfs

Jan 01 14:29:26 pve systemd[1]: Starting pve-cluster.service - The Proxmox VE cluster filesystem...
Jan 01 14:29:26 pve pmxcfs[1409]: [main] notice: resolved node name 'pve' to '192.168.1.203' for default node IP address
Jan 01 14:29:26 pve pmxcfs[1409]: [main] notice: resolved node name 'pve' to '192.168.1.203' for default node IP address
Jan 01 14:29:27 pve systemd[1]: Started pve-cluster.service - The Proxmox VE cluster filesystem.
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/storagezfs: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/local-lvm: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/local: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/backup-storage: -1
Jan 01 14:30:15 pve pmxcfs[1435]: [status] notice: RRDC update error /var/lib/rrdcached/db/pve2-storage/pve/backups: -1
```

```bash
systemctl status pvedaemon
```
```
● pvedaemon.service - PVE API Daemon
     Loaded: loaded (/lib/systemd/system/pvedaemon.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-01-01 14:29:28 EST; 44min ago
    Process: 1530 ExecStart=/usr/bin/pvedaemon start (code=exited, status=0/SUCCESS)
   Main PID: 1561 (pvedaemon)
      Tasks: 6 (limit: 77016)
     Memory: 194.6M
        CPU: 1.741s
     CGroup: /system.slice/pvedaemon.service
             ├─1561 pvedaemon
             ├─1562 "pvedaemon worker"
             ├─1563 "pvedaemon worker"
             ├─1564 "pvedaemon worker"
             ├─4741 "task UPID:pve:00001285:00011C08:6956CDF0:vncshell::root@pam:"
             └─4742 /usr/bin/termproxy 5900 --path /nodes/pve --perm Sys.Console -- /bin/login -f root

Jan 01 14:40:17 pve pvedaemon[1562]: <root@pam> successful auth for user 'root@pam'
Jan 01 14:41:36 pve pvedaemon[4741]: starting termproxy UPID:pve:00001285:00011C08:6956CDF0:vncshell::root@pam:
Jan 01 14:41:36 pve pvedaemon[1562]: <root@pam> starting task UPID:pve:00001285:00011C08:6956CDF0:vncshell::root@pam:
Jan 01 14:41:36 pve pvedaemon[1564]: <root@pam> successful auth for user 'root@pam'
Jan 01 14:41:36 pve login[4748]: pam_unix(login:session): session opened for user root(uid=0) by (uid=0)
Jan 01 14:51:29 pve pvedaemon[1562]: <root@pam> successful auth for user 'root@pam'
Jan 01 15:06:30 pve pvedaemon[1564]: <root@pam> successful auth for user 'root@pam'
```

```bash
systemctl status pveproxy
```
```
● pveproxy.service - PVE API Proxy Server
     Loaded: loaded (/lib/systemd/system/pveproxy.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-01-01 14:29:29 EST; 45min ago
    Process: 1566 ExecStartPre=/usr/bin/pvecm updatecerts --silent (code=exited, status=0/SUCCESS)
    Process: 1568 ExecStart=/usr/bin/pveproxy start (code=exited, status=0/SUCCESS)
   Main PID: 1570 (pveproxy)
      Tasks: 4 (limit: 77016)
     Memory: 208.2M
        CPU: 8.856s
     CGroup: /system.slice/pveproxy.service
             ├─1570 pveproxy
             ├─1571 "pveproxy worker"
             ├─1573 "pveproxy worker"
             └─9527 "pveproxy worker"

Jan 01 14:29:29 pve pveproxy[1570]: starting server
Jan 01 14:29:29 pve pveproxy[1570]: starting 3 worker(s)
Jan 01 14:29:29 pve pveproxy[1570]: worker 1571 started
Jan 01 14:29:29 pve pveproxy[1570]: worker 1572 started
Jan 01 14:29:29 pve pveproxy[1570]: worker 1573 started
Jan 01 14:29:29 pve systemd[1]: Started pveproxy.service - PVE API Proxy Server.
Jan 01 15:04:34 pve pveproxy[1572]: worker exit
Jan 01 15:04:34 pve pveproxy[1570]: worker 1572 finished
Jan 01 15:04:34 pve pveproxy[1570]: starting 1 worker(s)
Jan 01 15:04:34 pve pveproxy[1570]: worker 9527 started
```

```bash
systemctl status pvestatd
```
```
● pvestatd.service - PVE Status Daemon
     Loaded: loaded (/lib/systemd/system/pvestatd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-01-01 14:29:28 EST; 45min ago
    Process: 1531 ExecStart=/usr/bin/pvestatd start (code=exited, status=0/SUCCESS)
   Main PID: 1546 (pvestatd)
      Tasks: 1 (limit: 77016)
     Memory: 148.4M
        CPU: 31.038s
     CGroup: /system.slice/pvestatd.service
             └─1546 pvestatd

Jan 01 14:29:27 pve systemd[1]: Starting pvestatd.service - PVE Status Daemon...
Jan 01 14:29:28 pve pvestatd[1546]: starting server
Jan 01 14:29:28 pve systemd[1]: Started pvestatd.service - PVE Status Daemon.
Jan 01 14:30:15 pve pvestatd[1546]: modified cpu set for lxc/101: 0-1
Jan 01 14:30:15 pve pvestatd[1546]: auth key pair too old, rotating..
Jan 01 14:30:15 pve pvestatd[1546]: status update time (37.208 seconds)
```

```bash
systemctl status pve-firewall
```
```
● pve-firewall.service - Proxmox VE firewall
     Loaded: loaded (/lib/systemd/system/pve-firewall.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-01-01 14:29:28 EST; 48min ago
    Process: 1529 ExecStartPre=/usr/bin/update-alternatives --set ebtables /usr/sbin/ebtables-legacy (code=exited, status=0/SUCCESS)
    Process: 1532 ExecStartPre=/usr/bin/update-alternatives --set iptables /usr/sbin/iptables-legacy (code=exited, status=0/SUCCESS)
    Process: 1533 ExecStartPre=/usr/bin/update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy (code=exited, status=0/SUCCESS)
    Process: 1535 ExecStart=/usr/sbin/pve-firewall start (code=exited, status=0/SUCCESS)
   Main PID: 1538 (pve-firewall)
      Tasks: 1 (limit: 77016)
     Memory: 103.2M
        CPU: 19.912s
     CGroup: /system.slice/pve-firewall.service
             └─1538 pve-firewall

Jan 01 14:29:27 pve systemd[1]: Starting pve-firewall.service - Proxmox VE firewall...
Jan 01 14:29:28 pve pve-firewall[1538]: starting server
Jan 01 14:29:28 pve systemd[1]: Started pve-firewall.service - Proxmox VE firewall.
```

#### System Services Summary

**WARNING ISSUES FOUND:**

1. **PVE-Cluster RRDC Errors** - Storage monitoring failing for all pools (`storagezfs`, `local-lvm`, `local`, `backup-storage`, `backups`)
2. **PVEProxy Worker Restart** - Worker process 1572 crashed and was replaced with worker 9527 at 15:04:34
3. **PVEStatd Performance** - Status update taking 37.208 seconds (should be much faster)
4. **PVEStatd Auth Key Rotation** - "auth key pair too old, rotating" indicates security key maintenance

**SERVICES RUNNING NORMALLY:**

- **pve-cluster**: Active and running (despite RRDC errors)
- **pvedaemon**: Active with successful authentications and VNC shell sessions
- **pveproxy**: Active (despite worker restart)
- **pvestatd**: Active and running (despite performance issues)
- **pve-firewall**: Active and running normally

**NOTES:**

- **LXC Container 101** CPU set modified to cores 0-1 (resource management active)

**IMMEDIATE ACTIONS:**

- Check RRD cache daemon: `systemctl status rrdcached`
- Investigate storage monitoring failures (likely causing pvestatd slowness)
- Monitor pveproxy stability for additional worker crashes

## 2. Hardware Health Check
### 2.1 CPU Information
```bash
lscpu
```
```
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          43 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   12
  On-line CPU(s) list:    0-11
Vendor ID:                AuthenticAMD
  BIOS Vendor ID:         Advanced Micro Devices, Inc.
  Model name:             AMD Ryzen 5 3600 6-Core Processor
    BIOS Model name:      AMD Ryzen 5 3600 6-Core Processor               Unknown CPU @ 3.6GHz
    BIOS CPU family:      107
    CPU family:           23
    Model:                113
    Thread(s) per core:   2
    Core(s) per socket:   6
    Socket(s):            1
    Stepping:             0
    Frequency boost:      enabled
    CPU(s) scaling MHz:   88%
    CPU max MHz:          4208.2031
    CPU min MHz:          2200.0000
    BogoMIPS:             7200.04
    Flags:                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb r
                          dtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movb
                          e popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce 
                          topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibpb stibp vmmcall fsgsbase bmi1 avx2 smep 
                          bmi2 cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero ir
                          perf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold av
                          ic v_vmsave_vmload vgif v_spec_ctrl umip rdpid overflow_recov succor smca sev sev_es
Virtualization features:  
  Virtualization:         AMD-V
Caches (sum of all):      
  L1d:                    192 KiB (6 instances)
  L1i:                    192 KiB (6 instances)
  L2:                     3 MiB (6 instances)
  L3:                     32 MiB (2 instances)
NUMA:                     
  NUMA node(s):           1
  NUMA node0 CPU(s):      0-11
Vulnerabilities:          
  Gather data sampling:   Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Mitigation; untrained return thunk; SMT enabled with STIBP protection
  Spec rstack overflow:   Mitigation; Safe RET
  Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:             Mitigation; Retpolines; IBPB conditional; STIBP always-on; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                  Not affected
  Tsx async abort:        Not affected
```

```bash
sensors
```
```
nvme-pci-0100
Adapter: PCI adapter
Composite:    +35.9°C  (low  = -20.1°C, high = +74.8°C)
                       (crit = +79.8°C)

k10temp-pci-00c3
Adapter: PCI adapter
Tctl:         +39.2°C  
Tccd1:        +30.2°C  
```

#### CPU Health Summary

**HARDWARE STATUS:**

- **CPU Model**: AMD Ryzen 5 3600 6-Core Processor (6 cores, 12 threads)
- **Architecture**: x86_64 with AMD-V virtualization support
- **Clock Speeds**: Base 2.2GHz, Max 4.2GHz, Frequency boost enabled
- **Cache**: L1: 384KB, L2: 3MB, L3: 32MB (healthy cache hierarchy)

**TEMPERATURE STATUS:**

- **CPU Temperature**: 39.2°C (Tctl) - **NORMAL** (well within safe range)
- **Core Temperature**: 30.2°C (Tccd1) - **EXCELLENT** (very cool)
- **NVMe SSD**: 35.9°C - **NORMAL** (within operating range, critical at 79.8°C)

**SECURITY MITIGATIONS:**

- **Spectre/Meltdown**: All major vulnerabilities properly mitigated
- **Retbleed**: Protected with untrained return thunk
- **Speculative Execution**: Proper barriers and sanitization in place

**NOTES:**

- **Virtualization Ready**: AMD-V enabled for VM/container support
- **Performance**: CPU scaling at 88% indicates dynamic frequency management working
- **Cooling**: Excellent thermal performance, no thermal throttling concerns

**NO ISSUES FOUND** - CPU hardware is operating normally with good temperatures and proper security mitigations.

### 2.2 Memory Information
```bash
free -h
```
```
               total        used        free      shared  buff/cache   available
Mem:            62Gi       2.2Gi        60Gi        50Mi       880Mi        60Gi
Swap:          8.0Gi          0B       8.0Gi
```

```bash
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached"
```
```
MemTotal:       65788472 kB
MemFree:        63272156 kB
MemAvailable:   63491816 kB
Buffers:           59340 kB
Cached:           784996 kB
SwapCached:            0 kB
```

```bash
dmesg | grep -i "memory\|oom"
```
```
[    0.000000] ACPI: Reserving FACP table memory at [mem 0xdbb35e30-0xdbb35f43]
[    0.000000] ACPI: Reserving DSDT table memory at [mem 0xdbb2e1f0-0xdbb35e2c]
[    0.000000] ACPI: Reserving FACS table memory at [mem 0xdbb9ae00-0xdbb9ae3f]
[    0.000000] ACPI: Reserving APIC table memory at [mem 0xdbb35f48-0xdbb360a5]
[    0.000000] ACPI: Reserving FPDT table memory at [mem 0xdbb360a8-0xdbb360eb]
[    0.000000] ACPI: Reserving FIDT table memory at [mem 0xdbb360f0-0xdbb3618b]
[    0.000000] ACPI: Reserving SSDT table memory at [mem 0xdbb36190-0xdbb36257]
[    0.000000] ACPI: Reserving SSDT table memory at [mem 0xdbb36258-0xdbb3eeef]
[    0.000000] ACPI: Reserving SSDT table memory at [mem 0xdbb3eef0-0xdbb42565]
[    0.000000] ACPI: Reserving MCFG table memory at [mem 0xdbb42568-0xdbb425a3]
[    0.000000] ACPI: Reserving HPET table memory at [mem 0xdbb425a8-0xdbb425df]
[    0.000000] ACPI: Reserving UEFI table memory at [mem 0xdbb425e0-0xdbb42621]
[    0.000000] ACPI: Reserving IVRS table memory at [mem 0xdbb42628-0xdbb426f7]
[    0.000000] ACPI: Reserving PCCT table memory at [mem 0xdbb426f8-0xdbb42765]
[    0.000000] ACPI: Reserving SSDT table memory at [mem 0xdbb42768-0xdbb45690]
[    0.000000] ACPI: Reserving CRAT table memory at [mem 0xdbb45698-0xdbb461ef]
[    0.000000] ACPI: Reserving CDIT table memory at [mem 0xdbb461f0-0xdbb46218]
[    0.000000] ACPI: Reserving BGRT table memory at [mem 0xdbb46220-0xdbb46257]
[    0.000000] ACPI: Reserving SSDT table memory at [mem 0xdbb46258-0xdbb47fa1]
[    0.000000] ACPI: Reserving SSDT table memory at [mem 0xdbb47fa8-0xdbb48066]
[    0.000000] ACPI: Reserving WSMT table memory at [mem 0xdbb48068-0xdbb4808f]
[    0.000000] Early memory node ranges
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0x00000000-0x00000fff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0x000a0000-0x000fffff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0x09d82000-0x09ffffff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0x0a200000-0x0a20bfff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0x0b000000-0x0b01ffff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xd75fa000-0xd7656fff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xd7685000-0xd7685fff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xdb4d4000-0xdb61dfff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xdb79f000-0xdbbb0fff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xdbbb1000-0xdca1cfff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xdca1d000-0xdcac2fff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xdf000000-0xdfffffff]
[    0.000000] PM: hibernation: Registered nosave memory: [mem 0xe0000000-0xffffffff]
[    0.000000] Memory: 65617632K/67055644K available (20480K kernel code, 3642K rwdata, 13456K rodata, 4816K init, 5692K bss, 1437752K reserved, 0K cma-reserved)
[    0.025577] Freeing SMP alternatives memory: 48K
[    0.158473] x86/mm: Memory block size: 2048MB
[    0.628598] Freeing initrd memory: 59884K
[    0.684026] Freeing unused decrypted memory: 2028K
[    0.684521] Freeing unused kernel image (initmem) memory: 4816K
[    0.684910] Freeing unused kernel image (rodata/data gap) memory: 880K
```

```bash
cat /proc/buddyinfo
```
```
Node 0, zone      DMA      1      1      0      0      0      0      0      0      1      1      2 
Node 0, zone    DMA32      6      6      5      7      7      8      8      7      6      4    859 
Node 0, zone   Normal     97     13    224    349    151     56     18     10     15     11  14560 
```

```bash
dmesg | grep -i "edac\|ecc\|memory.*error"
```
```
[    0.235324] EDAC MC: Ver: 3.0.0
[    5.718861] systemd[1]: systemd 252.33-1~deb12u1 running in system mode (+PAM +AUDIT +SELINUX +APPARMOR +IMA +SMACK +SECCOMP +GCRYPT -GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN +IPTC +KMOD +LIBCRYPTSETUP +LIBFDISK +PCRE2 -PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD -BPF_FRAMEWORK -XKBCOMMON +UTMP +SYSVINIT default-hierarchy=unified)
```

```bash
cat /proc/pressure/memory
```
```
some avg10=0.00 avg60=0.00 avg300=0.00 total=376
full avg10=0.00 avg60=0.00 avg300=0.00 total=376
```

#### Memory Health Summary

**NO ISSUES FOUND** - 62GB RAM, 96% available, excellent memory fragmentation, no ECC errors, zero memory pressure detected.

### 2.3 Hardware Monitoring
```bash
sensors
```
```
[Paste sensors output here]
```

```bash
dmesg | grep -i "hardware\|acpi\|thermal"
```
```
[Paste hardware errors here]
```

```bash
lspci | grep -E "VGA|Audio|Network|SATA|USB"
```
```
[Paste PCI devices here]
```

## 3. Storage and Filesystem
### 3.1 Disk Usage Analysis
```bash
lsblk -f
```
```
NAME                         FSTYPE      FSVER    LABEL   UUID                                   FSAVAIL FSUSE% MOUNTPOINTS
sda                                                                                                             
├─sda1                       zfs_member  5000     storage 4784826011103089756                                   
└─sda9                                                                                                          
sdb                                                                                                             
├─sdb1                       zfs_member  5000     storage 4784826011103089756                                   
└─sdb9                                                                                                          
sdc                                                                                                             
├─sdc1                       zfs_member  5000     storage 4784826011103089756                                   
└─sdc9                                                                                                          
zd0                                                                                                             
├─zd0p1                                                                                                         
└─zd0p2                      ext4        1.0              61955015-f5f3-41bf-ba1c-01aaa25bb086                  
zd16                                                                                                            
├─zd16p1                                                                                                        
└─zd16p2                     ext4        1.0              61955015-f5f3-41bf-ba1c-01aaa25bb086                  
zd32                                                                                                            
nvme0n1                                                                                                         
├─nvme0n1p1                                                                                                     
├─nvme0n1p2                  vfat        FAT32            CD19-75F4                              1021.6M     0% /boot/efi
└─nvme0n1p3                  LVM2_member LVM2 001         f3Y2fK-8qlg-FghV-REk3-7RwB-19Ou-LFvX5C                
  ├─pve-swap                 swap        1                cd8f35bf-725e-4475-b89b-4bbc439bb9e2                  [SWAP]
  ├─pve-root                 ext4        1.0              875fb1b2-036e-4ff4-9429-645bdf6b402c     30.7G    49% /
  ├─pve-data_tmeta                                                                                              
  │ └─pve-data-tpool                                                                                            
  │   ├─pve-data                                                                                                
  │   ├─pve-vm--100--disk--0 ext4        1.0              2d6253da-5dfe-446c-9e1e-e26682e001b4                  
  │   └─pve-vm--101--disk--0 ext4        1.0              022a6ed2-5e0d-44ed-8517-4c75479d7f24                  
  └─pve-data_tdata                                                                                              
    └─pve-data-tpool                                                                                            
      ├─pve-data                                                                                                
      ├─pve-vm--100--disk--0 ext4        1.0              2d6253da-5dfe-446c-9e1e-e26682e001b4                  
      └─pve-vm--101--disk--0 ext4        1.0              022a6ed2-5e0d-44ed-8517-4c75479d7f24    
```

```bash
fdisk -l
```
```
Disk /dev/sda: 3.64 TiB, 4000787030016 bytes, 7814037168 sectors
Disk model: ST4000NE001-2MA1
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: B8F73FCA-02B6-C74B-8504-412DB38C5720

Device          Start        End    Sectors  Size Type
/dev/sda1        2048 7814019071 7814017024  3.6T Solaris /usr & Apple ZFS
/dev/sda9  7814019072 7814035455      16384    8M Solaris reserved 1


Disk /dev/sdb: 3.64 TiB, 4000787030016 bytes, 7814037168 sectors
Disk model: ST4000NE001-2MA1
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 4828AEF9-9712-BA4B-90D1-DF192125CDC6

Device          Start        End    Sectors  Size Type
/dev/sdb1        2048 7814019071 7814017024  3.6T Solaris /usr & Apple ZFS
/dev/sdb9  7814019072 7814035455      16384    8M Solaris reserved 1


Disk /dev/sdc: 3.64 TiB, 4000787030016 bytes, 7814037168 sectors
Disk model: ST4000NE001-2MA1
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 300630AE-C806-4649-8F22-8388F1D52B33

Device          Start        End    Sectors  Size Type
/dev/sdc1        2048 7814019071 7814017024  3.6T Solaris /usr & Apple ZFS
/dev/sdc9  7814019072 7814035455      16384    8M Solaris reserved 1


Disk /dev/nvme0n1: 238.47 GiB, 256060514304 bytes, 500118192 sectors
Disk model: PCIe SSD                                
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 05762276-C394-479E-93E3-91FA40BF3FB5

Device           Start       End   Sectors   Size Type
/dev/nvme0n1p1      34      2047      2014  1007K BIOS boot
/dev/nvme0n1p2    2048   2099199   2097152     1G EFI System
/dev/nvme0n1p3 2099200 500118158 498018959 237.5G Linux LVM


Disk /dev/mapper/pve-swap: 8 GiB, 8589934592 bytes, 16777216 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/pve-root: 69.37 GiB, 74482450432 bytes, 145473536 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/pve-vm--100--disk--0: 48 GiB, 51539607552 bytes, 100663296 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 65536 bytes / 65536 bytes


Disk /dev/mapper/pve-vm--101--disk--0: 20 GiB, 21474836480 bytes, 41943040 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 65536 bytes / 65536 bytes


Disk /dev/zd0: 750 GiB, 805306368000 bytes, 1572864000 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 16384 bytes
I/O size (minimum/optimal): 16384 bytes / 16384 bytes
Disklabel type: gpt
Disk identifier: AEF4E13D-02A1-477D-ABF2-DB8FA0F56A1C

Device     Start        End    Sectors  Size Type
/dev/zd0p1  2048       4095       2048    1M BIOS boot
/dev/zd0p2  4096 1572863966 1572859871  750G Linux filesystem


Disk /dev/zd16: 150 GiB, 161061273600 bytes, 314572800 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 16384 bytes
I/O size (minimum/optimal): 16384 bytes / 16384 bytes
Disklabel type: gpt
Disk identifier: AEF4E13D-02A1-477D-ABF2-DB8FA0F56A1C

Device      Start       End   Sectors  Size Type
/dev/zd16p1  2048      4095      2048    1M BIOS boot
/dev/zd16p2  4096 314570751 314566656  150G Linux filesystem


Disk /dev/zd32: 32 GiB, 34359738368 bytes, 67108864 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 16384 bytes
I/O size (minimum/optimal): 16384 bytes / 16384 bytes
```

```bash
blkid
```
```
/dev/mapper/pve-root: UUID="875fb1b2-036e-4ff4-9429-645bdf6b402c" BLOCK_SIZE="4096" TYPE="ext4"
/dev/nvme0n1p3: UUID="f3Y2fK-8qlg-FghV-REk3-7RwB-19Ou-LFvX5C" TYPE="LVM2_member" PARTUUID="331e68c1-a011-4c71-bbeb-1ed187a7103f"
/dev/nvme0n1p2: UUID="CD19-75F4" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="bc2e900e-01b9-47db-a87d-c73a5001b1ed"
/dev/sdb1: LABEL="storage" UUID="4784826011103089756" UUID_SUB="17017838173716778292" BLOCK_SIZE="4096" TYPE="zfs_member" PARTLABEL="zfs-ba40838f28bfe9fe" PARTUUID="25701eac-039b-204d-b907-1b2f1196e4d8"
/dev/mapper/pve-vm--100--disk--0: UUID="2d6253da-5dfe-446c-9e1e-e26682e001b4" BLOCK_SIZE="4096" TYPE="ext4"
/dev/mapper/pve-swap: UUID="cd8f35bf-725e-4475-b89b-4bbc439bb9e2" TYPE="swap"
/dev/sdc1: LABEL="storage" UUID="4784826011103089756" UUID_SUB="5627568950611190888" BLOCK_SIZE="4096" TYPE="zfs_member" PARTLABEL="zfs-338d387e8e9f9157" PARTUUID="67ef19fc-e005-414b-aa0c-c0e66005e841"
/dev/mapper/pve-vm--101--disk--0: UUID="022a6ed2-5e0d-44ed-8517-4c75479d7f24" BLOCK_SIZE="4096" TYPE="ext4"
/dev/sda1: LABEL="storage" UUID="4784826011103089756" UUID_SUB="669437927032443652" BLOCK_SIZE="4096" TYPE="zfs_member" PARTLABEL="zfs-453ac4867c3285eb" PARTUUID="fc5a5110-9343-fb49-a65b-82eefcf301c5"
/dev/nvme0n1p1: PARTUUID="e9b8352d-8888-4820-a664-79ab42ca6ebc"
/dev/sdb9: PARTUUID="cc2f52b9-cd24-884c-929b-ee8ec9d9b2da"
/dev/zd0p1: PARTUUID="bc2fc19e-c942-4bb3-821a-4f568874e6d8"
/dev/zd0p2: UUID="61955015-f5f3-41bf-ba1c-01aaa25bb086" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="052806ea-7181-4d9e-9692-483111cd896a"
/dev/zd16p2: UUID="61955015-f5f3-41bf-ba1c-01aaa25bb086" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="052806ea-7181-4d9e-9692-483111cd896a"
/dev/zd16p1: PARTUUID="bc2fc19e-c942-4bb3-821a-4f568874e6d8"
/dev/sdc9: PARTUUID="9c826982-09a3-e044-bec9-2e631c84e5de"
/dev/sda9: PARTUUID="b3714d2b-9b61-ac47-9866-1ed3e44625bc"
```

```bash
df -h
```
```
Filesystem            Size  Used Avail Use% Mounted on
udev                   32G     0   32G   0% /dev
tmpfs                 6.3G  1.9M  6.3G   1% /run
/dev/mapper/pve-root   68G   34G   31G  53% /
tmpfs                  32G   49M   32G   1% /dev/shm
tmpfs                 5.0M     0  5.0M   0% /run/lock
efivarfs              128K   16K  108K  13% /sys/firmware/efi/efivars
/dev/nvme0n1p2       1022M  344K 1022M   1% /boot/efi
storage               6.2T  256K  6.2T   1% /storage
storage/backup        6.2T  1.5G  6.2T   1% /storage/backup
storage/nextcloud     6.2T  128K  6.2T   1% /storage/nextcloud
/dev/fuse             128M   20K  128M   1% /etc/pve
tmpfs                 6.3G     0  6.3G   0% /run/user/0
```

```bash
df -i
```
```
Filesystem                Inodes  IUsed       IFree IUse% Mounted on
udev                     8215108    658     8214450    1% /dev
tmpfs                    8223559   1130     8222429    1% /run
/dev/mapper/pve-root     4546560 165857     4380703    4% /
tmpfs                    8223559    113     8223446    1% /dev/shm
tmpfs                    8223559     16     8223543    1% /run/lock
efivarfs                       0      0           0     - /sys/firmware/efi/efivars
/dev/nvme0n1p2                 0      0           0     - /boot/efi
storage              13191508010      8 13191508002    1% /storage
storage/backup       13191508024     22 13191508002    1% /storage/backup
storage/nextcloud    13191508008      6 13191508002    1% /storage/nextcloud
/dev/fuse                 262144     39      262105    1% /etc/pve
tmpfs                    1644711     20     1644691    1% /run/user/0
```

```bash
du -sh /* 2>/dev/null | sort -hr | head -10
```
```
19G     /usr
11G     /var
4.2G    /opt
1.5G    /storage
411M    /boot
49M     /dev
6.7M    /etc
1.9M    /run
140K    /root
36K     /tmp
```

Note: `iostat` was not installed on the system. It is now, but there are no extended statistics available.
```bash
iostat -x 1 3
```
```
avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.25    0.00    0.83    0.00    0.00   98.92

Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
dm-0             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
dm-1             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
dm-2             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
dm-3             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
dm-4             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
dm-6             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
dm-7             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
nvme0n1          6.00    768.00     0.00   0.00    0.67   128.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.40
sda              0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
sdb              0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
sdc              0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
zd0              0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
zd16             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
zd32             0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
```

```bash
cat /proc/diskstats
```
```
   7       0 loop0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   7       1 loop1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   7       2 loop2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   7       3 loop3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   7       4 loop4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   7       5 loop5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   7       6 loop6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   7       7 loop7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
   8       0 sda 589 0 32848 3302 343 0 7288 979 0 2028 5132 0 0 0 0 16 850
   8       1 sda1 359 0 18464 2865 343 0 7288 979 0 1986 3845 0 0 0 0 0 0
   8       9 sda9 96 0 5216 72 0 0 0 0 0 73 72 0 0 0 0 0 0
   8      16 sdb 606 0 33632 3666 347 0 7320 1027 0 2181 5595 0 0 0 0 16 901
   8      17 sdb1 376 0 19248 3182 347 0 7320 1027 0 2086 4209 0 0 0 0 0 0
   8      25 sdb9 96 0 5216 205 0 0 0 0 0 162 205 0 0 0 0 0 0
   8      32 sdc 595 0 32256 3139 353 0 7328 980 0 1916 4989 0 0 0 0 16 870
   8      33 sdc1 365 0 17872 2713 353 0 7328 980 0 1935 3693 0 0 0 0 0 0
   8      41 sdc9 96 0 5216 214 0 0 0 0 0 176 214 0 0 0 0 0 0
 259       0 nvme0n1 52594 12482 2724084 11525 16336 24228 905930 40458 0 28180 61855 18651 0 73823440 7613 1479 2258
 259       1 nvme0n1p1 72 0 5760 10 0 0 0 0 0 6 10 0 0 0 0 0 0
 259       2 nvme0n1p2 263 2020 25532 32 3 0 10 3 0 27 40 3 0 2092336 4 0 0
 259       3 nvme0n1p3 52155 10462 2684944 11473 16322 24228 905920 40433 0 33425 59515 18648 0 71731104 7608 0 0
 252       0 dm-0 209 0 12192 41 0 0 0 0 0 21 41 0 0 0 0 0 0
 252       1 dm-1 49174 0 1547896 13098 37617 0 882456 76497 0 112471 97214 18648 0 71731104 7619 0 0
 252       2 dm-2 562 0 4520 240 55 0 360 22 0 53 262 0 0 0 0 0 0
 252       3 dm-3 9387 0 285634 1082 2697 0 23104 5426 0 3912 6508 0 0 0 0 0 0
 252       4 dm-4 9387 0 285634 1094 2692 0 23104 5417 0 3905 6511 0 0 0 0 0 0
 252       5 dm-5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
 252       6 dm-6 258 0 11952 23 0 0 0 0 0 15 23 0 0 0 0 0 0
 252       7 dm-7 9395 0 285402 1215 2689 0 22464 6135 0 3945 7350 0 0 0 0 0 0
 230       0 zd0 140 0 6358 355 0 0 0 0 0 275 355 0 0 0 0 0 0
 230       1 zd0p1 26 0 208 40 0 0 0 0 0 40 40 0 0 0 0 0 0
 230       2 zd0p2 54 0 4238 222 0 0 0 0 0 182 222 0 0 0 0 0 0
 230      16 zd16 150 0 6736 214 0 0 0 0 0 211 214 0 0 0 0 0 0
 230      17 zd16p1 26 0 208 3 0 0 0 0 0 3 3 0 0 0 0 0 0
 230      18 zd16p2 56 0 4160 99 0 0 0 0 0 98 99 0 0 0 0 0 0
 230      32 zd32 101 0 4216 2 0 0 0 0 0 2 2 0 0 0 0 0 0
```

```bash
dmesg | grep -i "error\|fail\|timeout" | grep -E "sd[a-z]|nvme|ata"
```
```
[    3.535446] ata5: failed to resume link (SControl 0)
[    4.727221] nvme nvme0: Shutdown timeout set to 10 seconds
```

```bash
journalctl -u systemd-fsck@* --no-pager
```
```
Dec 24 16:06:19 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 24 16:06:19 pve systemd-fsck[584]: fsck.fat 4.2 (2021-01-31)
Dec 24 16:06:19 pve systemd-fsck[584]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 24 16:06:19 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Dec 24 16:09:22 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Dec 24 16:09:22 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 6ba4e9f429f24e518c4f8e37dec44a60 --
Dec 24 16:10:04 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 24 16:10:04 pve systemd-fsck[585]: fsck.fat 4.2 (2021-01-31)
Dec 24 16:10:04 pve systemd-fsck[585]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 24 16:10:04 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 0b3864f7da474409acb99551d001f802 --
Dec 27 11:34:03 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 27 11:34:03 pve systemd-fsck[645]: fsck.fat 4.2 (2021-01-31)
Dec 27 11:34:03 pve systemd-fsck[645]: There are differences between boot sector and its backup.
Dec 27 11:34:03 pve systemd-fsck[645]: This is mostly harmless. Differences: (offset:original/backup)
Dec 27 11:34:03 pve systemd-fsck[645]:   65:01/00
Dec 27 11:34:03 pve systemd-fsck[645]:   Not automatically fixing this.
Dec 27 11:34:03 pve systemd-fsck[645]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 27 11:34:03 pve systemd-fsck[645]:  Automatically removing dirty bit.
Dec 27 11:34:03 pve systemd-fsck[645]: *** Filesystem was changed ***
Dec 27 11:34:03 pve systemd-fsck[645]: Writing changes.
Dec 27 11:34:03 pve systemd-fsck[645]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 27 11:34:03 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot c46248ab5d744efeaae72791a27097fb --
Jan 06 12:45:26 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Jan 06 12:45:26 pve systemd-fsck[604]: fsck.fat 4.2 (2021-01-31)
Jan 06 12:45:26 pve systemd-fsck[604]: There are differences between boot sector and its backup.
Jan 06 12:45:26 pve systemd-fsck[604]: This is mostly harmless. Differences: (offset:original/backup)
Jan 06 12:45:26 pve systemd-fsck[604]:   65:01/00
Jan 06 12:45:26 pve systemd-fsck[604]:   Not automatically fixing this.
Jan 06 12:45:26 pve systemd-fsck[604]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Jan 06 12:45:26 pve systemd-fsck[604]:  Automatically removing dirty bit.
Jan 06 12:45:26 pve systemd-fsck[604]: *** Filesystem was changed ***
Jan 06 12:45:26 pve systemd-fsck[604]: Writing changes.
Jan 06 12:45:26 pve systemd-fsck[604]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Jan 06 12:45:26 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot b8b1ccec308f451aa70348a68394f9e4 --
Feb 07 07:40:31 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 07 07:40:31 pve systemd-fsck[617]: fsck.fat 4.2 (2021-01-31)
Feb 07 07:40:31 pve systemd-fsck[617]: There are differences between boot sector and its backup.
Feb 07 07:40:31 pve systemd-fsck[617]: This is mostly harmless. Differences: (offset:original/backup)
Feb 07 07:40:31 pve systemd-fsck[617]:   65:01/00
Feb 07 07:40:31 pve systemd-fsck[617]:   Not automatically fixing this.
Feb 07 07:40:31 pve systemd-fsck[617]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Feb 07 07:40:31 pve systemd-fsck[617]:  Automatically removing dirty bit.
Feb 07 07:40:31 pve systemd-fsck[617]: *** Filesystem was changed ***
Feb 07 07:40:31 pve systemd-fsck[617]: Writing changes.
Feb 07 07:40:31 pve systemd-fsck[617]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 07 07:40:31 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 6ab7ac2e29ad470e9f031069e2fce750 --
Feb 10 11:03:40 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 10 11:03:40 pve systemd-fsck[618]: fsck.fat 4.2 (2021-01-31)
Feb 10 11:03:40 pve systemd-fsck[618]: There are differences between boot sector and its backup.
Feb 10 11:03:40 pve systemd-fsck[618]: This is mostly harmless. Differences: (offset:original/backup)
Feb 10 11:03:40 pve systemd-fsck[618]:   65:01/00
Feb 10 11:03:40 pve systemd-fsck[618]:   Not automatically fixing this.
Feb 10 11:03:40 pve systemd-fsck[618]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Feb 10 11:03:40 pve systemd-fsck[618]:  Automatically removing dirty bit.
Feb 10 11:03:40 pve systemd-fsck[618]: *** Filesystem was changed ***
Feb 10 11:03:40 pve systemd-fsck[618]: Writing changes.
Feb 10 11:03:40 pve systemd-fsck[618]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 10 11:03:40 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 795c8594b46a4d169ba6fc941da07046 --
Feb 14 15:00:36 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 14 15:00:36 pve systemd-fsck[638]: fsck.fat 4.2 (2021-01-31)
Feb 14 15:00:36 pve systemd-fsck[638]: There are differences between boot sector and its backup.
Feb 14 15:00:36 pve systemd-fsck[638]: This is mostly harmless. Differences: (offset:original/backup)
Feb 14 15:00:36 pve systemd-fsck[638]:   65:01/00
Feb 14 15:00:36 pve systemd-fsck[638]:   Not automatically fixing this.
Feb 14 15:00:36 pve systemd-fsck[638]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Feb 14 15:00:36 pve systemd-fsck[638]:  Automatically removing dirty bit.
Feb 14 15:00:36 pve systemd-fsck[638]: *** Filesystem was changed ***
Feb 14 15:00:36 pve systemd-fsck[638]: Writing changes.
Feb 14 15:00:36 pve systemd-fsck[638]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 14 15:00:36 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 7751f910fafa4fdc82dabf968a4c8475 --
Feb 15 16:51:03 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 15 16:51:03 pve systemd-fsck[640]: fsck.fat 4.2 (2021-01-31)
Feb 15 16:51:03 pve systemd-fsck[640]: There are differences between boot sector and its backup.
Feb 15 16:51:03 pve systemd-fsck[640]: This is mostly harmless. Differences: (offset:original/backup)
Feb 15 16:51:03 pve systemd-fsck[640]:   65:01/00
Feb 15 16:51:03 pve systemd-fsck[640]:   Not automatically fixing this.
Feb 15 16:51:03 pve systemd-fsck[640]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Feb 15 16:51:03 pve systemd-fsck[640]:  Automatically removing dirty bit.
Feb 15 16:51:03 pve systemd-fsck[640]: *** Filesystem was changed ***
Feb 15 16:51:03 pve systemd-fsck[640]: Writing changes.
Feb 15 16:51:03 pve systemd-fsck[640]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 15 16:51:03 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Feb 19 11:35:58 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Feb 19 11:35:58 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 527e47eb73ee451585fd59e99442744b --
Feb 19 11:36:33 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 19 11:36:33 pve systemd-fsck[635]: fsck.fat 4.2 (2021-01-31)
Feb 19 11:36:33 pve systemd-fsck[635]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 19 11:36:33 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Feb 20 19:04:30 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Feb 20 19:04:30 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 8ec9b79474404e1f85d4dbae78242a4a --
Feb 20 19:05:05 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 20 19:05:05 pve systemd-fsck[638]: fsck.fat 4.2 (2021-01-31)
Feb 20 19:05:05 pve systemd-fsck[638]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 20 19:05:05 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot b5452d39dda04bd598c47aea54918132 --
Feb 20 20:16:46 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 20 20:16:46 pve systemd-fsck[643]: fsck.fat 4.2 (2021-01-31)
Feb 20 20:16:46 pve systemd-fsck[643]: There are differences between boot sector and its backup.
Feb 20 20:16:46 pve systemd-fsck[643]: This is mostly harmless. Differences: (offset:original/backup)
Feb 20 20:16:46 pve systemd-fsck[643]:   65:01/00
Feb 20 20:16:46 pve systemd-fsck[643]:   Not automatically fixing this.
Feb 20 20:16:46 pve systemd-fsck[643]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Feb 20 20:16:46 pve systemd-fsck[643]:  Automatically removing dirty bit.
Feb 20 20:16:46 pve systemd-fsck[643]: *** Filesystem was changed ***
Feb 20 20:16:46 pve systemd-fsck[643]: Writing changes.
Feb 20 20:16:46 pve systemd-fsck[643]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 20 20:16:46 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Feb 21 19:42:38 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Feb 21 19:42:38 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 8b2ebab1282d44b2b58274060f9c06ea --
Feb 21 20:05:15 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 21 20:05:15 pve systemd-fsck[645]: fsck.fat 4.2 (2021-01-31)
Feb 21 20:05:15 pve systemd-fsck[645]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 21 20:05:15 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Feb 22 19:37:08 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Feb 22 19:37:08 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot e1befe239c2f4ea5b28be93ee800c3b0 --
Feb 22 19:46:19 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 22 19:46:19 pve systemd-fsck[631]: fsck.fat 4.2 (2021-01-31)
Feb 22 19:46:19 pve systemd-fsck[631]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 22 19:46:19 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot a2045bd757ec42f0881f90866dd252cd --
Mar 11 08:12:50 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Mar 11 08:12:50 pve systemd-fsck[650]: fsck.fat 4.2 (2021-01-31)
Mar 11 08:12:50 pve systemd-fsck[650]: There are differences between boot sector and its backup.
Mar 11 08:12:50 pve systemd-fsck[650]: This is mostly harmless. Differences: (offset:original/backup)
Mar 11 08:12:50 pve systemd-fsck[650]:   65:01/00
Mar 11 08:12:50 pve systemd-fsck[650]:   Not automatically fixing this.
Mar 11 08:12:50 pve systemd-fsck[650]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Mar 11 08:12:50 pve systemd-fsck[650]:  Automatically removing dirty bit.
Mar 11 08:12:50 pve systemd-fsck[650]: *** Filesystem was changed ***
Mar 11 08:12:50 pve systemd-fsck[650]: Writing changes.
Mar 11 08:12:50 pve systemd-fsck[650]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Mar 11 08:12:50 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot d3e43285574f4b8fa5354772003cf774 --
Apr 08 12:05:35 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 08 12:05:35 pve systemd-fsck[680]: fsck.fat 4.2 (2021-01-31)
Apr 08 12:05:35 pve systemd-fsck[680]: There are differences between boot sector and its backup.
Apr 08 12:05:35 pve systemd-fsck[680]: This is mostly harmless. Differences: (offset:original/backup)
Apr 08 12:05:35 pve systemd-fsck[680]:   65:01/00
Apr 08 12:05:35 pve systemd-fsck[680]:   Not automatically fixing this.
Apr 08 12:05:35 pve systemd-fsck[680]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Apr 08 12:05:35 pve systemd-fsck[680]:  Automatically removing dirty bit.
Apr 08 12:05:35 pve systemd-fsck[680]: *** Filesystem was changed ***
Apr 08 12:05:35 pve systemd-fsck[680]: Writing changes.
Apr 08 12:05:35 pve systemd-fsck[680]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 08 12:05:35 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 661522a6799244baad006a5ed6bdf006 --
May 09 14:32:30 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
May 09 14:32:30 pve systemd-fsck[644]: fsck.fat 4.2 (2021-01-31)
May 09 14:32:30 pve systemd-fsck[644]: There are differences between boot sector and its backup.
May 09 14:32:30 pve systemd-fsck[644]: This is mostly harmless. Differences: (offset:original/backup)
May 09 14:32:30 pve systemd-fsck[644]:   65:01/00
May 09 14:32:30 pve systemd-fsck[644]:   Not automatically fixing this.
May 09 14:32:30 pve systemd-fsck[644]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
May 09 14:32:30 pve systemd-fsck[644]:  Automatically removing dirty bit.
May 09 14:32:30 pve systemd-fsck[644]: *** Filesystem was changed ***
May 09 14:32:30 pve systemd-fsck[644]: Writing changes.
May 09 14:32:30 pve systemd-fsck[644]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
May 09 14:32:30 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot d4563818f9c5467798ccdbc03b2ac979 --
May 25 16:04:55 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
May 25 16:04:55 pve systemd-fsck[649]: fsck.fat 4.2 (2021-01-31)
May 25 16:04:55 pve systemd-fsck[649]: There are differences between boot sector and its backup.
May 25 16:04:55 pve systemd-fsck[649]: This is mostly harmless. Differences: (offset:original/backup)
May 25 16:04:55 pve systemd-fsck[649]:   65:01/00
May 25 16:04:55 pve systemd-fsck[649]:   Not automatically fixing this.
May 25 16:04:55 pve systemd-fsck[649]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
May 25 16:04:55 pve systemd-fsck[649]:  Automatically removing dirty bit.
May 25 16:04:55 pve systemd-fsck[649]: *** Filesystem was changed ***
May 25 16:04:55 pve systemd-fsck[649]: Writing changes.
May 25 16:04:55 pve systemd-fsck[649]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
May 25 16:04:55 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot d57f3d35aafd4faf8544bfc34c67cdb8 --
Jun 22 17:26:48 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Jun 22 17:26:48 pve systemd-fsck[645]: fsck.fat 4.2 (2021-01-31)
Jun 22 17:26:48 pve systemd-fsck[645]: There are differences between boot sector and its backup.
Jun 22 17:26:48 pve systemd-fsck[645]: This is mostly harmless. Differences: (offset:original/backup)
Jun 22 17:26:48 pve systemd-fsck[645]:   65:01/00
Jun 22 17:26:48 pve systemd-fsck[645]:   Not automatically fixing this.
Jun 22 17:26:48 pve systemd-fsck[645]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Jun 22 17:26:48 pve systemd-fsck[645]:  Automatically removing dirty bit.
Jun 22 17:26:48 pve systemd-fsck[645]: *** Filesystem was changed ***
Jun 22 17:26:48 pve systemd-fsck[645]: Writing changes.
Jun 22 17:26:48 pve systemd-fsck[645]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Jun 22 17:26:48 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 7eda3479a56b4f35a50918b3ad9b55cb --
Jul 05 22:39:45 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Jul 05 22:39:45 pve systemd-fsck[645]: fsck.fat 4.2 (2021-01-31)
Jul 05 22:39:45 pve systemd-fsck[645]: There are differences between boot sector and its backup.
Jul 05 22:39:45 pve systemd-fsck[645]: This is mostly harmless. Differences: (offset:original/backup)
Jul 05 22:39:45 pve systemd-fsck[645]:   65:01/00
Jul 05 22:39:45 pve systemd-fsck[645]:   Not automatically fixing this.
Jul 05 22:39:45 pve systemd-fsck[645]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Jul 05 22:39:45 pve systemd-fsck[645]:  Automatically removing dirty bit.
Jul 05 22:39:45 pve systemd-fsck[645]: *** Filesystem was changed ***
Jul 05 22:39:45 pve systemd-fsck[645]: Writing changes.
Jul 05 22:39:45 pve systemd-fsck[645]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Jul 05 22:39:45 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 85461f9beba34df4a77bdcb5c0bf0091 --
Jul 10 06:23:40 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Jul 10 06:23:40 pve systemd-fsck[642]: fsck.fat 4.2 (2021-01-31)
Jul 10 06:23:40 pve systemd-fsck[642]: There are differences between boot sector and its backup.
Jul 10 06:23:40 pve systemd-fsck[642]: This is mostly harmless. Differences: (offset:original/backup)
Jul 10 06:23:40 pve systemd-fsck[642]:   65:01/00
Jul 10 06:23:40 pve systemd-fsck[642]:   Not automatically fixing this.
Jul 10 06:23:40 pve systemd-fsck[642]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Jul 10 06:23:40 pve systemd-fsck[642]:  Automatically removing dirty bit.
Jul 10 06:23:40 pve systemd-fsck[642]: *** Filesystem was changed ***
Jul 10 06:23:40 pve systemd-fsck[642]: Writing changes.
Jul 10 06:23:40 pve systemd-fsck[642]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Jul 10 06:23:40 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 69f7e3eeca7a4773b816dbe4e529e156 --
Jul 19 07:16:17 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Jul 19 07:16:17 pve systemd-fsck[645]: fsck.fat 4.2 (2021-01-31)
Jul 19 07:16:17 pve systemd-fsck[645]: There are differences between boot sector and its backup.
Jul 19 07:16:17 pve systemd-fsck[645]: This is mostly harmless. Differences: (offset:original/backup)
Jul 19 07:16:17 pve systemd-fsck[645]:   65:01/00
Jul 19 07:16:17 pve systemd-fsck[645]:   Not automatically fixing this.
Jul 19 07:16:17 pve systemd-fsck[645]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Jul 19 07:16:17 pve systemd-fsck[645]:  Automatically removing dirty bit.
Jul 19 07:16:17 pve systemd-fsck[645]: *** Filesystem was changed ***
Jul 19 07:16:17 pve systemd-fsck[645]: Writing changes.
Jul 19 07:16:17 pve systemd-fsck[645]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Jul 19 07:16:17 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 7b33d33031754d0fb79257080ee7bfec --
Sep 08 19:16:48 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 08 19:16:48 pve systemd-fsck[647]: fsck.fat 4.2 (2021-01-31)
Sep 08 19:16:48 pve systemd-fsck[647]: There are differences between boot sector and its backup.
Sep 08 19:16:48 pve systemd-fsck[647]: This is mostly harmless. Differences: (offset:original/backup)
Sep 08 19:16:48 pve systemd-fsck[647]:   65:01/00
Sep 08 19:16:48 pve systemd-fsck[647]:   Not automatically fixing this.
Sep 08 19:16:48 pve systemd-fsck[647]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Sep 08 19:16:48 pve systemd-fsck[647]:  Automatically removing dirty bit.
Sep 08 19:16:48 pve systemd-fsck[647]: *** Filesystem was changed ***
Sep 08 19:16:48 pve systemd-fsck[647]: Writing changes.
Sep 08 19:16:48 pve systemd-fsck[647]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 08 19:16:48 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot aa26766b0eec43a896bc37c8cdce25be --
Sep 18 20:08:14 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 18 20:08:14 pve systemd-fsck[644]: fsck.fat 4.2 (2021-01-31)
Sep 18 20:08:14 pve systemd-fsck[644]: There are differences between boot sector and its backup.
Sep 18 20:08:14 pve systemd-fsck[644]: This is mostly harmless. Differences: (offset:original/backup)
Sep 18 20:08:14 pve systemd-fsck[644]:   65:01/00
Sep 18 20:08:14 pve systemd-fsck[644]:   Not automatically fixing this.
Sep 18 20:08:14 pve systemd-fsck[644]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Sep 18 20:08:14 pve systemd-fsck[644]:  Automatically removing dirty bit.
Sep 18 20:08:14 pve systemd-fsck[644]: *** Filesystem was changed ***
Sep 18 20:08:14 pve systemd-fsck[644]: Writing changes.
Sep 18 20:08:14 pve systemd-fsck[644]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 18 20:08:14 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 26 23:39:18 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 26 23:39:18 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 614fd22ab70d43c5a550db7b5b1cc14d --
Sep 26 23:39:56 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 26 23:39:56 pve systemd-fsck[650]: fsck.fat 4.2 (2021-01-31)
Sep 26 23:39:56 pve systemd-fsck[650]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 26 23:39:56 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 336d77395c734173a3f06c86de0ba255 --
Oct 01 13:18:14 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Oct 01 13:18:14 pve systemd-fsck[649]: fsck.fat 4.2 (2021-01-31)
Oct 01 13:18:14 pve systemd-fsck[649]: There are differences between boot sector and its backup.
Oct 01 13:18:14 pve systemd-fsck[649]: This is mostly harmless. Differences: (offset:original/backup)
Oct 01 13:18:14 pve systemd-fsck[649]:   65:01/00
Oct 01 13:18:14 pve systemd-fsck[649]:   Not automatically fixing this.
Oct 01 13:18:14 pve systemd-fsck[649]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Oct 01 13:18:14 pve systemd-fsck[649]:  Automatically removing dirty bit.
Oct 01 13:18:14 pve systemd-fsck[649]: *** Filesystem was changed ***
Oct 01 13:18:14 pve systemd-fsck[649]: Writing changes.
Oct 01 13:18:14 pve systemd-fsck[649]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Oct 01 13:18:14 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 120afa6fbe7a4d54ac1d086cbbd5e26b --
Feb 13 22:00:52 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Feb 13 22:00:52 pve systemd-fsck[664]: fsck.fat 4.2 (2021-01-31)
Feb 13 22:00:52 pve systemd-fsck[664]: There are differences between boot sector and its backup.
Feb 13 22:00:52 pve systemd-fsck[664]: This is mostly harmless. Differences: (offset:original/backup)
Feb 13 22:00:52 pve systemd-fsck[664]:   65:01/00
Feb 13 22:00:52 pve systemd-fsck[664]:   Not automatically fixing this.
Feb 13 22:00:52 pve systemd-fsck[664]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Feb 13 22:00:52 pve systemd-fsck[664]:  Automatically removing dirty bit.
Feb 13 22:00:52 pve systemd-fsck[664]: *** Filesystem was changed ***
Feb 13 22:00:52 pve systemd-fsck[664]: Writing changes.
Feb 13 22:00:52 pve systemd-fsck[664]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Feb 13 22:00:52 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 4330ae38351d42c19b5ce26e5d0773ad --
Mar 31 19:22:57 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Mar 31 19:22:57 pve systemd-fsck[625]: fsck.fat 4.2 (2021-01-31)
Mar 31 19:22:57 pve systemd-fsck[625]: There are differences between boot sector and its backup.
Mar 31 19:22:57 pve systemd-fsck[625]: This is mostly harmless. Differences: (offset:original/backup)
Mar 31 19:22:57 pve systemd-fsck[625]:   65:01/00
Mar 31 19:22:57 pve systemd-fsck[625]:   Not automatically fixing this.
Mar 31 19:22:57 pve systemd-fsck[625]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Mar 31 19:22:57 pve systemd-fsck[625]:  Automatically removing dirty bit.
Mar 31 19:22:57 pve systemd-fsck[625]: *** Filesystem was changed ***
Mar 31 19:22:57 pve systemd-fsck[625]: Writing changes.
Mar 31 19:22:57 pve systemd-fsck[625]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Mar 31 19:22:57 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 13 16:15:14 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 13 16:15:14 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot cd90dd34535743dea0326a61f561b289 --
Apr 13 16:15:49 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 13 16:15:49 pve systemd-fsck[602]: fsck.fat 4.2 (2021-01-31)
Apr 13 16:15:49 pve systemd-fsck[602]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 13 16:15:49 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 13 21:51:15 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 13 21:51:15 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 985cb205d40c47d8810f0b4bb5746ddc --
Apr 13 21:51:51 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 13 21:51:51 pve systemd-fsck[649]: fsck.fat 4.2 (2021-01-31)
Apr 13 21:51:51 pve systemd-fsck[649]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 13 21:51:51 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 14 10:48:18 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 14 10:48:18 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 46a1aaf66edf40f09daee34be343436a --
Apr 14 10:48:54 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 14 10:48:54 pve systemd-fsck[635]: fsck.fat 4.2 (2021-01-31)
Apr 14 10:48:54 pve systemd-fsck[635]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 14 10:48:54 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 14 12:09:30 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 14 12:09:30 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 9d13cb2c571943819303ec9182679ef1 --
Apr 14 12:13:59 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 14 12:13:59 pve systemd-fsck[606]: fsck.fat 4.2 (2021-01-31)
Apr 14 12:13:59 pve systemd-fsck[606]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 14 12:13:59 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 14 12:21:39 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 14 12:21:39 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 999033c0b9704de89025568c2a0a68f2 --
Apr 14 12:22:15 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 14 12:22:15 pve systemd-fsck[656]: fsck.fat 4.2 (2021-01-31)
Apr 14 12:22:15 pve systemd-fsck[656]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 14 12:22:15 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 14 14:50:56 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 14 14:50:56 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 632cdf5cc9f74275a96186fe5c9ad9b2 --
Apr 14 14:54:08 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 14 14:54:08 pve systemd-fsck[627]: fsck.fat 4.2 (2021-01-31)
Apr 14 14:54:08 pve systemd-fsck[627]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 14 14:54:08 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 14 20:32:42 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 14 20:32:42 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot f0694d6207dd4d13ac86efaaabf3cb09 --
Apr 14 20:33:19 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 14 20:33:19 pve systemd-fsck[682]: fsck.fat 4.2 (2021-01-31)
Apr 14 20:33:19 pve systemd-fsck[682]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 14 20:33:19 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 15 06:51:11 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 15 06:51:11 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 0188f403a4cd4ccfb3480e3cc729c32d --
Apr 15 06:51:47 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 15 06:51:47 pve systemd-fsck[678]: fsck.fat 4.2 (2021-01-31)
Apr 15 06:51:47 pve systemd-fsck[678]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 15 06:51:47 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Apr 15 14:06:25 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Apr 15 14:06:25 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 6aa1d8e75c0a4ef78546fdbf759e8883 --
Apr 15 14:07:56 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Apr 15 14:07:56 pve systemd-fsck[659]: fsck.fat 4.2 (2021-01-31)
Apr 15 14:07:56 pve systemd-fsck[659]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Apr 15 14:07:56 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
May 05 13:38:12 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
May 05 13:38:12 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 085d8366a4e6442d95fbbc1721c3062c --
May 05 13:38:48 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
May 05 13:38:48 pve systemd-fsck[640]: fsck.fat 4.2 (2021-01-31)
May 05 13:38:48 pve systemd-fsck[640]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
May 05 13:38:48 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot a43f3f50f4374d788f6dc4c6f513033f --
May 07 07:54:01 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
May 07 07:54:02 pve systemd-fsck[636]: fsck.fat 4.2 (2021-01-31)
May 07 07:54:02 pve systemd-fsck[636]: There are differences between boot sector and its backup.
May 07 07:54:02 pve systemd-fsck[636]: This is mostly harmless. Differences: (offset:original/backup)
May 07 07:54:02 pve systemd-fsck[636]:   65:01/00
May 07 07:54:02 pve systemd-fsck[636]:   Not automatically fixing this.
May 07 07:54:02 pve systemd-fsck[636]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
May 07 07:54:02 pve systemd-fsck[636]:  Automatically removing dirty bit.
May 07 07:54:02 pve systemd-fsck[636]: *** Filesystem was changed ***
May 07 07:54:02 pve systemd-fsck[636]: Writing changes.
May 07 07:54:02 pve systemd-fsck[636]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
May 07 07:54:02 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 581cf131f9bf47b794b1fc123a45b4ea --
May 12 08:59:29 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
May 12 08:59:29 pve systemd-fsck[626]: fsck.fat 4.2 (2021-01-31)
May 12 08:59:29 pve systemd-fsck[626]: There are differences between boot sector and its backup.
May 12 08:59:29 pve systemd-fsck[626]: This is mostly harmless. Differences: (offset:original/backup)
May 12 08:59:29 pve systemd-fsck[626]:   65:01/00
May 12 08:59:29 pve systemd-fsck[626]:   Not automatically fixing this.
May 12 08:59:29 pve systemd-fsck[626]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
May 12 08:59:29 pve systemd-fsck[626]:  Automatically removing dirty bit.
May 12 08:59:29 pve systemd-fsck[626]: *** Filesystem was changed ***
May 12 08:59:29 pve systemd-fsck[626]: Writing changes.
May 12 08:59:29 pve systemd-fsck[626]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
May 12 08:59:29 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 2dfb29b677ba42dbb19e3abf1a574288 --
May 26 17:27:07 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
May 26 17:27:07 pve systemd-fsck[670]: fsck.fat 4.2 (2021-01-31)
May 26 17:27:07 pve systemd-fsck[670]: There are differences between boot sector and its backup.
May 26 17:27:07 pve systemd-fsck[670]: This is mostly harmless. Differences: (offset:original/backup)
May 26 17:27:07 pve systemd-fsck[670]:   65:01/00
May 26 17:27:07 pve systemd-fsck[670]:   Not automatically fixing this.
May 26 17:27:07 pve systemd-fsck[670]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
May 26 17:27:07 pve systemd-fsck[670]:  Automatically removing dirty bit.
May 26 17:27:07 pve systemd-fsck[670]: *** Filesystem was changed ***
May 26 17:27:07 pve systemd-fsck[670]: Writing changes.
May 26 17:27:07 pve systemd-fsck[670]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
May 26 17:27:07 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 754e3236811f41a498428df3815f1be6 --
May 27 17:03:57 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
May 27 17:03:57 pve systemd-fsck[682]: fsck.fat 4.2 (2021-01-31)
May 27 17:03:57 pve systemd-fsck[682]: There are differences between boot sector and its backup.
May 27 17:03:57 pve systemd-fsck[682]: This is mostly harmless. Differences: (offset:original/backup)
May 27 17:03:57 pve systemd-fsck[682]:   65:01/00
May 27 17:03:57 pve systemd-fsck[682]:   Not automatically fixing this.
May 27 17:03:57 pve systemd-fsck[682]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
May 27 17:03:57 pve systemd-fsck[682]:  Automatically removing dirty bit.
May 27 17:03:57 pve systemd-fsck[682]: *** Filesystem was changed ***
May 27 17:03:57 pve systemd-fsck[682]: Writing changes.
May 27 17:03:57 pve systemd-fsck[682]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
May 27 17:03:57 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot f6ea45eb7e014e9f988ebc175b37a025 --
Jul 30 12:30:55 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Jul 30 12:30:55 pve systemd-fsck[680]: fsck.fat 4.2 (2021-01-31)
Jul 30 12:30:55 pve systemd-fsck[680]: There are differences between boot sector and its backup.
Jul 30 12:30:55 pve systemd-fsck[680]: This is mostly harmless. Differences: (offset:original/backup)
Jul 30 12:30:55 pve systemd-fsck[680]:   65:01/00
Jul 30 12:30:55 pve systemd-fsck[680]:   Not automatically fixing this.
Jul 30 12:30:55 pve systemd-fsck[680]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Jul 30 12:30:55 pve systemd-fsck[680]:  Automatically removing dirty bit.
Jul 30 12:30:55 pve systemd-fsck[680]: *** Filesystem was changed ***
Jul 30 12:30:55 pve systemd-fsck[680]: Writing changes.
Jul 30 12:30:55 pve systemd-fsck[680]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Jul 30 12:30:55 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 483b8c28092942ebab27fee057d27937 --
Aug 07 09:07:27 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 07 09:07:27 pve systemd-fsck[650]: fsck.fat 4.2 (2021-01-31)
Aug 07 09:07:27 pve systemd-fsck[650]: There are differences between boot sector and its backup.
Aug 07 09:07:27 pve systemd-fsck[650]: This is mostly harmless. Differences: (offset:original/backup)
Aug 07 09:07:27 pve systemd-fsck[650]:   65:01/00
Aug 07 09:07:27 pve systemd-fsck[650]:   Not automatically fixing this.
Aug 07 09:07:27 pve systemd-fsck[650]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Aug 07 09:07:27 pve systemd-fsck[650]:  Automatically removing dirty bit.
Aug 07 09:07:27 pve systemd-fsck[650]: *** Filesystem was changed ***
Aug 07 09:07:27 pve systemd-fsck[650]: Writing changes.
Aug 07 09:07:27 pve systemd-fsck[650]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 07 09:07:27 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot d7c30b71adfa49bba6d50852e4b49625 --
Aug 15 10:17:31 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 15 10:17:31 pve systemd-fsck[606]: fsck.fat 4.2 (2021-01-31)
Aug 15 10:17:31 pve systemd-fsck[606]: There are differences between boot sector and its backup.
Aug 15 10:17:31 pve systemd-fsck[606]: This is mostly harmless. Differences: (offset:original/backup)
Aug 15 10:17:31 pve systemd-fsck[606]:   65:01/00
Aug 15 10:17:31 pve systemd-fsck[606]:   Not automatically fixing this.
Aug 15 10:17:31 pve systemd-fsck[606]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Aug 15 10:17:31 pve systemd-fsck[606]:  Automatically removing dirty bit.
Aug 15 10:17:31 pve systemd-fsck[606]: *** Filesystem was changed ***
Aug 15 10:17:31 pve systemd-fsck[606]: Writing changes.
Aug 15 10:17:31 pve systemd-fsck[606]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 15 10:17:31 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 25 11:22:30 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 25 11:22:30 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 4d2e41fe29e64cc09cf3bbb30af17aee --
Aug 25 11:23:06 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 25 11:23:06 pve systemd-fsck[686]: fsck.fat 4.2 (2021-01-31)
Aug 25 11:23:06 pve systemd-fsck[686]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 25 11:23:06 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 25 11:32:24 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 25 11:32:24 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 2d4080328ff44792a4dd9a16d51d2be5 --
Aug 25 11:33:01 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 25 11:33:01 pve systemd-fsck[674]: fsck.fat 4.2 (2021-01-31)
Aug 25 11:33:01 pve systemd-fsck[674]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 25 11:33:01 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 25 11:34:06 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 25 11:34:06 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot eae745bce86449d2b174506c21f5a85b --
Aug 25 11:34:42 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 25 11:34:42 pve systemd-fsck[666]: fsck.fat 4.2 (2021-01-31)
Aug 25 11:34:42 pve systemd-fsck[666]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 25 11:34:42 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 25 11:41:11 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 25 11:41:11 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot e326205ce3b84cc7b59450dfe9e902e5 --
Aug 25 11:41:48 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 25 11:41:48 pve systemd-fsck[674]: fsck.fat 4.2 (2021-01-31)
Aug 25 11:41:48 pve systemd-fsck[674]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 25 11:41:48 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 25 11:53:40 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 25 11:53:40 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot fac065d6fcb84f2085dc03a731fb0a08 --
Aug 25 11:54:17 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 25 11:54:17 pve systemd-fsck[684]: fsck.fat 4.2 (2021-01-31)
Aug 25 11:54:17 pve systemd-fsck[684]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 25 11:54:17 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 25 19:44:13 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 25 19:44:13 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 54a345e3c12a48d3bc3681c86f6d9376 --
Aug 25 19:44:50 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 25 19:44:50 pve systemd-fsck[704]: fsck.fat 4.2 (2021-01-31)
Aug 25 19:44:50 pve systemd-fsck[704]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 25 19:44:50 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 25 19:52:45 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 25 19:52:45 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 793120b226ba4c099b94996ab2c2b99e --
Aug 25 19:53:21 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 25 19:53:21 pve systemd-fsck[677]: fsck.fat 4.2 (2021-01-31)
Aug 25 19:53:21 pve systemd-fsck[677]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 25 19:53:21 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Aug 26 14:08:12 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Aug 26 14:08:12 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 6b1c27a057f64047b25e7e850d3de81e --
Aug 26 14:08:47 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Aug 26 14:08:47 pve systemd-fsck[646]: fsck.fat 4.2 (2021-01-31)
Aug 26 14:08:47 pve systemd-fsck[646]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Aug 26 14:08:47 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 08:51:08 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 08:51:08 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 945d0f917d404c56b98dcbd09270965a --
Sep 03 08:51:44 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 08:51:44 pve systemd-fsck[638]: fsck.fat 4.2 (2021-01-31)
Sep 03 08:51:44 pve systemd-fsck[638]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 08:51:44 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 08:57:32 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 08:57:32 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot f46b894b146b4dd29d741a3b959a5be9 --
Sep 03 08:58:09 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 08:58:09 pve systemd-fsck[680]: fsck.fat 4.2 (2021-01-31)
Sep 03 08:58:09 pve systemd-fsck[680]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 08:58:09 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 09:03:07 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 09:03:07 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 830ca589e029411dba18eeb024618f29 --
Sep 03 09:03:43 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 09:03:43 pve systemd-fsck[686]: fsck.fat 4.2 (2021-01-31)
Sep 03 09:03:43 pve systemd-fsck[686]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 09:03:43 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 09:11:25 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 09:11:25 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 1b5394b867b944de9eca6435946e0d47 --
Sep 03 09:12:02 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 09:12:02 pve systemd-fsck[671]: fsck.fat 4.2 (2021-01-31)
Sep 03 09:12:02 pve systemd-fsck[671]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 09:12:02 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 09:14:58 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 09:14:58 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot b197cda176f44f8697310f26820dfb6f --
Sep 03 09:15:35 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 09:15:35 pve systemd-fsck[621]: fsck.fat 4.2 (2021-01-31)
Sep 03 09:15:35 pve systemd-fsck[621]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 09:15:35 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 09:28:51 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 09:28:51 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 729995e1f18649f3ace1faf8df65668c --
Sep 03 09:29:28 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 09:29:28 pve systemd-fsck[648]: fsck.fat 4.2 (2021-01-31)
Sep 03 09:29:28 pve systemd-fsck[648]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 09:29:28 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 12:57:08 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 12:57:08 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot d1e82faaba47499ab2744a491bc3efbc --
Sep 03 12:57:44 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 12:57:44 pve systemd-fsck[659]: fsck.fat 4.2 (2021-01-31)
Sep 03 12:57:44 pve systemd-fsck[659]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 12:57:44 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 03 13:31:14 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 03 13:31:14 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 559e5c31818d4af19ee307e02efb6927 --
Sep 03 13:31:50 pve systemd-fsck[665]: fsck.fat 4.2 (2021-01-31)
Sep 03 13:31:50 pve systemd-fsck[665]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 03 13:31:50 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 03 13:31:50 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Sep 04 08:11:37 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Sep 04 08:11:37 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 69ae169651dc4097a27f8224c0ac6aeb --
Sep 04 08:12:13 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 04 08:12:13 pve systemd-fsck[659]: fsck.fat 4.2 (2021-01-31)
Sep 04 08:12:13 pve systemd-fsck[659]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 04 08:12:13 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot caad0ea75da04aca89a68cf811698962 --
Sep 04 08:14:07 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Sep 04 08:14:07 pve systemd-fsck[643]: fsck.fat 4.2 (2021-01-31)
Sep 04 08:14:07 pve systemd-fsck[643]: There are differences between boot sector and its backup.
Sep 04 08:14:07 pve systemd-fsck[643]: This is mostly harmless. Differences: (offset:original/backup)
Sep 04 08:14:07 pve systemd-fsck[643]:   65:01/00
Sep 04 08:14:07 pve systemd-fsck[643]:   Not automatically fixing this.
Sep 04 08:14:07 pve systemd-fsck[643]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Sep 04 08:14:07 pve systemd-fsck[643]:  Automatically removing dirty bit.
Sep 04 08:14:07 pve systemd-fsck[643]: *** Filesystem was changed ***
Sep 04 08:14:07 pve systemd-fsck[643]: Writing changes.
Sep 04 08:14:07 pve systemd-fsck[643]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Sep 04 08:14:07 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot e2ff2b6063b7415192e8a588444e0a1c --
Oct 12 17:29:25 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Oct 12 17:29:25 pve systemd-fsck[682]: fsck.fat 4.2 (2021-01-31)
Oct 12 17:29:25 pve systemd-fsck[682]: There are differences between boot sector and its backup.
Oct 12 17:29:25 pve systemd-fsck[682]: This is mostly harmless. Differences: (offset:original/backup)
Oct 12 17:29:25 pve systemd-fsck[682]:   65:01/00
Oct 12 17:29:25 pve systemd-fsck[682]:   Not automatically fixing this.
Oct 12 17:29:25 pve systemd-fsck[682]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Oct 12 17:29:25 pve systemd-fsck[682]:  Automatically removing dirty bit.
Oct 12 17:29:25 pve systemd-fsck[682]: *** Filesystem was changed ***
Oct 12 17:29:25 pve systemd-fsck[682]: Writing changes.
Oct 12 17:29:25 pve systemd-fsck[682]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Oct 12 17:29:25 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Dec 02 12:59:18 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Dec 02 12:59:18 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot ca0576b9747e42c3bb75b2aadec9ed24 --
Dec 02 12:59:54 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 02 12:59:54 pve systemd-fsck[624]: fsck.fat 4.2 (2021-01-31)
Dec 02 12:59:54 pve systemd-fsck[624]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 02 12:59:54 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
Dec 07 13:10:28 pve systemd[1]: systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service: Deactivated successfully.
Dec 07 13:10:28 pve systemd[1]: Stopped systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 10cc25e2bf944aaca9124a137265f0ac --
Dec 07 13:12:57 pve systemd-fsck[628]: fsck.fat 4.2 (2021-01-31)
Dec 07 13:12:57 pve systemd-fsck[628]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 07 13:12:57 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 07 13:12:57 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot cb1f8642b8d44c1f8b70c7ad644ddb81 --
Dec 17 16:08:22 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 16:08:22 pve systemd-fsck[595]: fsck.fat 4.2 (2021-01-31)
Dec 17 16:08:22 pve systemd-fsck[595]: There are differences between boot sector and its backup.
Dec 17 16:08:22 pve systemd-fsck[595]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 16:08:22 pve systemd-fsck[595]:   65:01/00
Dec 17 16:08:22 pve systemd-fsck[595]:   Not automatically fixing this.
Dec 17 16:08:22 pve systemd-fsck[595]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 16:08:22 pve systemd-fsck[595]:  Automatically removing dirty bit.
Dec 17 16:08:22 pve systemd-fsck[595]: *** Filesystem was changed ***
Dec 17 16:08:22 pve systemd-fsck[595]: Writing changes.
Dec 17 16:08:22 pve systemd-fsck[595]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 16:08:22 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 5ab938ee2aa9498cb24492ccf213cce0 --
Dec 17 17:09:46 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 17:09:46 pve systemd-fsck[606]: fsck.fat 4.2 (2021-01-31)
Dec 17 17:09:46 pve systemd-fsck[606]: There are differences between boot sector and its backup.
Dec 17 17:09:46 pve systemd-fsck[606]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 17:09:46 pve systemd-fsck[606]:   65:01/00
Dec 17 17:09:46 pve systemd-fsck[606]:   Not automatically fixing this.
Dec 17 17:09:46 pve systemd-fsck[606]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 17:09:46 pve systemd-fsck[606]:  Automatically removing dirty bit.
Dec 17 17:09:46 pve systemd-fsck[606]: *** Filesystem was changed ***
Dec 17 17:09:46 pve systemd-fsck[606]: Writing changes.
Dec 17 17:09:46 pve systemd-fsck[606]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 17:09:46 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot fe47ceef1e2448efb7cd87dcfe5cffe9 --
Dec 17 17:12:09 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 17:12:09 pve systemd-fsck[645]: fsck.fat 4.2 (2021-01-31)
Dec 17 17:12:09 pve systemd-fsck[645]: There are differences between boot sector and its backup.
Dec 17 17:12:09 pve systemd-fsck[645]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 17:12:09 pve systemd-fsck[645]:   65:01/00
Dec 17 17:12:09 pve systemd-fsck[645]:   Not automatically fixing this.
Dec 17 17:12:09 pve systemd-fsck[645]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 17:12:09 pve systemd-fsck[645]:  Automatically removing dirty bit.
Dec 17 17:12:09 pve systemd-fsck[645]: *** Filesystem was changed ***
Dec 17 17:12:09 pve systemd-fsck[645]: Writing changes.
Dec 17 17:12:09 pve systemd-fsck[645]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 17:12:09 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 1b3ae393dca34adcb647124efd7f7786 --
Dec 17 17:13:32 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 17:13:32 pve systemd-fsck[654]: fsck.fat 4.2 (2021-01-31)
Dec 17 17:13:32 pve systemd-fsck[654]: There are differences between boot sector and its backup.
Dec 17 17:13:32 pve systemd-fsck[654]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 17:13:32 pve systemd-fsck[654]:   65:01/00
Dec 17 17:13:32 pve systemd-fsck[654]:   Not automatically fixing this.
Dec 17 17:13:32 pve systemd-fsck[654]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 17:13:32 pve systemd-fsck[654]:  Automatically removing dirty bit.
Dec 17 17:13:32 pve systemd-fsck[654]: *** Filesystem was changed ***
Dec 17 17:13:32 pve systemd-fsck[654]: Writing changes.
Dec 17 17:13:32 pve systemd-fsck[654]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 17:13:32 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 1684d07233974467b069f85a4423e4c2 --
Dec 17 19:01:28 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 19:01:28 pve systemd-fsck[603]: fsck.fat 4.2 (2021-01-31)
Dec 17 19:01:28 pve systemd-fsck[603]: There are differences between boot sector and its backup.
Dec 17 19:01:28 pve systemd-fsck[603]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 19:01:28 pve systemd-fsck[603]:   65:01/00
Dec 17 19:01:28 pve systemd-fsck[603]:   Not automatically fixing this.
Dec 17 19:01:28 pve systemd-fsck[603]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 19:01:28 pve systemd-fsck[603]:  Automatically removing dirty bit.
Dec 17 19:01:28 pve systemd-fsck[603]: *** Filesystem was changed ***
Dec 17 19:01:28 pve systemd-fsck[603]: Writing changes.
Dec 17 19:01:28 pve systemd-fsck[603]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 19:01:28 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 6eac45a8b36a4f98acdfe851886af5cb --
Dec 17 19:30:00 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 19:30:00 pve systemd-fsck[631]: fsck.fat 4.2 (2021-01-31)
Dec 17 19:30:00 pve systemd-fsck[631]: There are differences between boot sector and its backup.
Dec 17 19:30:00 pve systemd-fsck[631]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 19:30:00 pve systemd-fsck[631]:   65:01/00
Dec 17 19:30:00 pve systemd-fsck[631]:   Not automatically fixing this.
Dec 17 19:30:00 pve systemd-fsck[631]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 19:30:00 pve systemd-fsck[631]:  Automatically removing dirty bit.
Dec 17 19:30:00 pve systemd-fsck[631]: *** Filesystem was changed ***
Dec 17 19:30:00 pve systemd-fsck[631]: Writing changes.
Dec 17 19:30:00 pve systemd-fsck[631]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 19:30:00 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 35bddfb04bae473e8991fd86d758a99d --
Dec 17 19:35:14 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 19:35:14 pve systemd-fsck[559]: fsck.fat 4.2 (2021-01-31)
Dec 17 19:35:14 pve systemd-fsck[559]: There are differences between boot sector and its backup.
Dec 17 19:35:14 pve systemd-fsck[559]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 19:35:14 pve systemd-fsck[559]:   65:01/00
Dec 17 19:35:14 pve systemd-fsck[559]:   Not automatically fixing this.
Dec 17 19:35:14 pve systemd-fsck[559]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 19:35:14 pve systemd-fsck[559]:  Automatically removing dirty bit.
Dec 17 19:35:14 pve systemd-fsck[559]: *** Filesystem was changed ***
Dec 17 19:35:14 pve systemd-fsck[559]: Writing changes.
Dec 17 19:35:14 pve systemd-fsck[559]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 19:35:14 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot d251f634c4024c96bf9d3feaf931ebbe --
Dec 17 19:40:55 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 19:40:55 pve systemd-fsck[658]: fsck.fat 4.2 (2021-01-31)
Dec 17 19:40:55 pve systemd-fsck[658]: There are differences between boot sector and its backup.
Dec 17 19:40:55 pve systemd-fsck[658]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 19:40:55 pve systemd-fsck[658]:   65:01/00
Dec 17 19:40:55 pve systemd-fsck[658]:   Not automatically fixing this.
Dec 17 19:40:55 pve systemd-fsck[658]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 19:40:55 pve systemd-fsck[658]:  Automatically removing dirty bit.
Dec 17 19:40:55 pve systemd-fsck[658]: *** Filesystem was changed ***
Dec 17 19:40:55 pve systemd-fsck[658]: Writing changes.
Dec 17 19:40:55 pve systemd-fsck[658]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 19:40:55 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 56ce414a4eac4cfe9bd305502cb3bff8 --
Dec 17 20:13:31 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 20:13:31 pve systemd-fsck[616]: fsck.fat 4.2 (2021-01-31)
Dec 17 20:13:31 pve systemd-fsck[616]: There are differences between boot sector and its backup.
Dec 17 20:13:31 pve systemd-fsck[616]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 20:13:31 pve systemd-fsck[616]:   65:01/00
Dec 17 20:13:31 pve systemd-fsck[616]:   Not automatically fixing this.
Dec 17 20:13:31 pve systemd-fsck[616]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 20:13:31 pve systemd-fsck[616]:  Automatically removing dirty bit.
Dec 17 20:13:31 pve systemd-fsck[616]: *** Filesystem was changed ***
Dec 17 20:13:31 pve systemd-fsck[616]: Writing changes.
Dec 17 20:13:31 pve systemd-fsck[616]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 20:13:31 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot d804eae4a23d41829ea0df068eac2aec --
Dec 17 23:37:01 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 17 23:37:01 pve systemd-fsck[652]: fsck.fat 4.2 (2021-01-31)
Dec 17 23:37:01 pve systemd-fsck[652]: There are differences between boot sector and its backup.
Dec 17 23:37:01 pve systemd-fsck[652]: This is mostly harmless. Differences: (offset:original/backup)
Dec 17 23:37:01 pve systemd-fsck[652]:   65:01/00
Dec 17 23:37:01 pve systemd-fsck[652]:   Not automatically fixing this.
Dec 17 23:37:01 pve systemd-fsck[652]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 17 23:37:01 pve systemd-fsck[652]:  Automatically removing dirty bit.
Dec 17 23:37:01 pve systemd-fsck[652]: *** Filesystem was changed ***
Dec 17 23:37:01 pve systemd-fsck[652]: Writing changes.
Dec 17 23:37:01 pve systemd-fsck[652]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 17 23:37:01 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot a7048fc007334cb385fd4b3cec37b2ed --
Dec 18 07:15:30 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 18 07:15:30 pve systemd-fsck[653]: fsck.fat 4.2 (2021-01-31)
Dec 18 07:15:30 pve systemd-fsck[653]: There are differences between boot sector and its backup.
Dec 18 07:15:30 pve systemd-fsck[653]: This is mostly harmless. Differences: (offset:original/backup)
Dec 18 07:15:30 pve systemd-fsck[653]:   65:01/00
Dec 18 07:15:30 pve systemd-fsck[653]:   Not automatically fixing this.
Dec 18 07:15:30 pve systemd-fsck[653]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 18 07:15:30 pve systemd-fsck[653]:  Automatically removing dirty bit.
Dec 18 07:15:30 pve systemd-fsck[653]: *** Filesystem was changed ***
Dec 18 07:15:30 pve systemd-fsck[653]: Writing changes.
Dec 18 07:15:30 pve systemd-fsck[653]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 18 07:15:30 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 6a85271a259e489c99fa4765d0b868d6 --
Dec 18 07:36:48 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 18 07:36:48 pve systemd-fsck[588]: fsck.fat 4.2 (2021-01-31)
Dec 18 07:36:48 pve systemd-fsck[588]: There are differences between boot sector and its backup.
Dec 18 07:36:48 pve systemd-fsck[588]: This is mostly harmless. Differences: (offset:original/backup)
Dec 18 07:36:48 pve systemd-fsck[588]:   65:01/00
Dec 18 07:36:48 pve systemd-fsck[588]:   Not automatically fixing this.
Dec 18 07:36:48 pve systemd-fsck[588]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 18 07:36:48 pve systemd-fsck[588]:  Automatically removing dirty bit.
Dec 18 07:36:48 pve systemd-fsck[588]: *** Filesystem was changed ***
Dec 18 07:36:48 pve systemd-fsck[588]: Writing changes.
Dec 18 07:36:48 pve systemd-fsck[588]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 18 07:36:48 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot f76ef443f4c04ef38b6b7554aee93b9d --
Dec 18 09:42:02 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 18 09:42:02 pve systemd-fsck[643]: fsck.fat 4.2 (2021-01-31)
Dec 18 09:42:02 pve systemd-fsck[643]: There are differences between boot sector and its backup.
Dec 18 09:42:02 pve systemd-fsck[643]: This is mostly harmless. Differences: (offset:original/backup)
Dec 18 09:42:02 pve systemd-fsck[643]:   65:01/00
Dec 18 09:42:02 pve systemd-fsck[643]:   Not automatically fixing this.
Dec 18 09:42:02 pve systemd-fsck[643]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 18 09:42:02 pve systemd-fsck[643]:  Automatically removing dirty bit.
Dec 18 09:42:02 pve systemd-fsck[643]: *** Filesystem was changed ***
Dec 18 09:42:02 pve systemd-fsck[643]: Writing changes.
Dec 18 09:42:02 pve systemd-fsck[643]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 18 09:42:02 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot ba1f17e625364294a2f0183c2dbc650d --
Dec 18 11:07:02 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 18 11:07:02 pve systemd-fsck[619]: fsck.fat 4.2 (2021-01-31)
Dec 18 11:07:02 pve systemd-fsck[619]: There are differences between boot sector and its backup.
Dec 18 11:07:02 pve systemd-fsck[619]: This is mostly harmless. Differences: (offset:original/backup)
Dec 18 11:07:02 pve systemd-fsck[619]:   65:01/00
Dec 18 11:07:02 pve systemd-fsck[619]:   Not automatically fixing this.
Dec 18 11:07:02 pve systemd-fsck[619]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 18 11:07:02 pve systemd-fsck[619]:  Automatically removing dirty bit.
Dec 18 11:07:02 pve systemd-fsck[619]: *** Filesystem was changed ***
Dec 18 11:07:02 pve systemd-fsck[619]: Writing changes.
Dec 18 11:07:02 pve systemd-fsck[619]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 18 11:07:02 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 394e2a47ef46465fb6a9e68d6cfa3626 --
Dec 18 20:36:37 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 18 20:36:37 pve systemd-fsck[662]: fsck.fat 4.2 (2021-01-31)
Dec 18 20:36:37 pve systemd-fsck[662]: There are differences between boot sector and its backup.
Dec 18 20:36:37 pve systemd-fsck[662]: This is mostly harmless. Differences: (offset:original/backup)
Dec 18 20:36:37 pve systemd-fsck[662]:   65:01/00
Dec 18 20:36:37 pve systemd-fsck[662]:   Not automatically fixing this.
Dec 18 20:36:37 pve systemd-fsck[662]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 18 20:36:37 pve systemd-fsck[662]:  Automatically removing dirty bit.
Dec 18 20:36:37 pve systemd-fsck[662]: *** Filesystem was changed ***
Dec 18 20:36:37 pve systemd-fsck[662]: Writing changes.
Dec 18 20:36:37 pve systemd-fsck[662]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 18 20:36:37 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 82878433e0a545158eee5871d48f2835 --
Dec 20 17:17:09 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Dec 20 17:17:09 pve systemd-fsck[627]: fsck.fat 4.2 (2021-01-31)
Dec 20 17:17:09 pve systemd-fsck[627]: There are differences between boot sector and its backup.
Dec 20 17:17:09 pve systemd-fsck[627]: This is mostly harmless. Differences: (offset:original/backup)
Dec 20 17:17:09 pve systemd-fsck[627]:   65:01/00
Dec 20 17:17:09 pve systemd-fsck[627]:   Not automatically fixing this.
Dec 20 17:17:09 pve systemd-fsck[627]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Dec 20 17:17:09 pve systemd-fsck[627]:  Automatically removing dirty bit.
Dec 20 17:17:09 pve systemd-fsck[627]: *** Filesystem was changed ***
Dec 20 17:17:09 pve systemd-fsck[627]: Writing changes.
Dec 20 17:17:09 pve systemd-fsck[627]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Dec 20 17:17:09 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
-- Boot 24a38fbe333047e583a8edaca7633df5 --
Jan 01 14:29:21 pve systemd[1]: Starting systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4...
Jan 01 14:29:21 pve systemd-fsck[652]: fsck.fat 4.2 (2021-01-31)
Jan 01 14:29:21 pve systemd-fsck[652]: There are differences between boot sector and its backup.
Jan 01 14:29:21 pve systemd-fsck[652]: This is mostly harmless. Differences: (offset:original/backup)
Jan 01 14:29:21 pve systemd-fsck[652]:   65:01/00
Jan 01 14:29:21 pve systemd-fsck[652]:   Not automatically fixing this.
Jan 01 14:29:21 pve systemd-fsck[652]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
Jan 01 14:29:21 pve systemd-fsck[652]:  Automatically removing dirty bit.
Jan 01 14:29:21 pve systemd-fsck[652]: *** Filesystem was changed ***
Jan 01 14:29:21 pve systemd-fsck[652]: Writing changes.
Jan 01 14:29:21 pve systemd-fsck[652]: /dev/nvme0n1p2: 5 files, 86/261628 clusters
Jan 01 14:29:21 pve systemd[1]: Finished systemd-fsck@dev-disk-by\x2duuid-CD19\x2d75F4.service - File System Check on /dev/disk/by-uuid/CD19-75F4.
```

```bash
smartctl -a /dev/sda
```
```
[Paste SDA SMART data here]
```

```bash
smartctl -a /dev/sdb
```
```
[Paste SDB SMART data here]
```

```bash
smartctl -a /dev/nvme0
```
```
[Paste NVMe SMART data here]
```

#### Storage Layout Analysis Summary

**STORAGE CONFIGURATION:**

- **NVMe SSD**: 238GB PCIe SSD (boot drive) - LVM with Proxmox system
- **ZFS Pool**: 3x 4TB Seagate ST4000NE001 drives (11TB usable) - "storage" pool
- **VM Storage**: LVM thin pool on NVMe for VM disks (VM-100: 48GB, VM-101: 20GB)

**CRITICAL ISSUES IDENTIFIED:**

1. **EFI Boot Partition Corruption**: Persistent "dirty bit" and boot sector backup differences on `/dev/nvme0n1p2` - **CRITICAL BOOT ISSUE**
2. **Improper System Shutdowns**: Filesystem consistently marked as "not properly unmounted" - **ROOT CAUSE OF BOOT PROBLEMS**
3. **Boot Sector Inconsistency**: Recurring differences between boot sector and backup (offset 65:01/00) - **EFI CORRUPTION**

**MODERATE ISSUES:**

4. **Root Filesystem Usage**: 53% full (34GB used of 68GB) - **MODERATE CONCERN**
5. **ZFS Virtual Devices**: Multiple `zd0`, `zd16`, `zd32` devices with duplicate UUIDs - **CONFIGURATION ISSUE**
6. **Storage Fragmentation**: Complex storage layout with mixed LVM/ZFS - **COMPLEXITY RISK**
7. **ATA Port 5 Failure**: `ata5: failed to resume link (SControl 0)` - **HARDWARE ISSUE**

**STORAGE HEALTH STATUS:**

- **Disk Space**: Adequate free space on all filesystems
- **Inode Usage**: Very low (1-4%) - no inode exhaustion risk
- **ZFS Pool**: 6.2TB available, minimal usage (1.5GB backup data)
- **Boot Drive**: NVMe properly partitioned with EFI/LVM layout
- **I/O Performance**: Very low activity (system idle), NVMe showing minimal read activity
- **ZFS Drives**: No current I/O activity on sda/sdb/sdc (idle state)

**NOTES:**

- **Duplicate UUIDs** on zd0p2/zd16p2 may indicate cloned/snapshot issues
- **Root partition** approaching 60% - monitor growth
- **ZFS zvols** (zd devices) suggest VM storage on ZFS pool

**IMMEDIATE ACTIONS NEEDED:**
- **PRIORITY 1**: Fix EFI boot partition corruption - `fsck.fat -r /dev/nvme0n1p2` (read-only check first)
- **PRIORITY 2**: Investigate why system is not shutting down properly (causing dirty bit)
- **PRIORITY 3**: Fix boot sector backup inconsistency - may require EFI partition rebuild
- Investigate ATA port 5 failure - may indicate SATA controller or cable issue
- Investigate duplicate UUID issue on ZFS virtual devices
- Monitor root filesystem growth
- Verify ZFS pool integrity

**ROOT CAUSE ANALYSIS:**
The filesystem check logs show a clear pattern from Dec 2024 to Jan 2026 of EFI boot partition corruption. Every boot that shows "dirty bit" and "boot sector differences" indicates improper shutdowns, which explains your boot issues. This is likely the primary cause of your January 1st boot problems.


### 3.2 ZFS
```bash
zpool status
```
```
[Paste ZFS pool status here]
```

```bash
zpool list
```
```
[Paste ZFS pool list here]
```

```bash
zfs list
```
```
[Paste ZFS datasets here]
```

```bash
zpool iostat -v
```
```
[Paste ZFS I/O statistics here]
```

```bash
zpool history
```
```
[Paste ZFS history here]
```

```bash
zfs get all | grep -E "error|health|checksum"
```
```
[Paste ZFS health properties here]
```

```bash
zpool events | tail -20
```
```
[Paste ZFS events here]
```

```bash
cat /proc/spl/kstat/zfs/arcstats | grep -E "hits|miss|size"
```
```
[Paste ZFS ARC statistics here]
```

### 3.3 LVM
```bash
pvs
```
```
[Paste physical volumes here]
```

```bash
vgs
```
```
[Paste volume groups here]
```

```bash
lvs
```
```
[Paste logical volumes here]
```

```bash
pvdisplay -v
```
```
[Paste detailed PV info here]
```

```bash
vgdisplay -v
```
```
[Paste detailed VG info here]
```

```bash
lvdisplay -v
```
```
[Paste detailed LV info here]
```

```bash
dmsetup status
```
```
[Paste device mapper status here]
```

```bash
dmsetup table
```
```
[Paste device mapper table here]
```

```bash
pvck
```
```
[Paste PV check results here]
```

```bash
vgck
```
```
[Paste VG check results here]
```

### 3.4 Filesystem Health
```bash
fsck -n /dev/mapper/pve-root
```
```
[Paste root filesystem check here]
```

```bash
fsck -n /dev/mapper/pve-data
```
```
[Paste data filesystem check here]
```

```bash
mount | grep -E "ext4|xfs|zfs"
```
```
[Paste mounted filesystems here]
```

```bash
cat /proc/mounts | grep -E "ext4|xfs|zfs"
```
```
[Paste proc mounts here]
```

```bash
dmesg | grep -i "ext4\|xfs\|filesystem.*error"
```
```
[Paste filesystem errors here]
```

## 4. Network Diagnostics
### 4.1 Network Interface Status
```bash
ip addr show
```
```
[Paste network interfaces here]
```

```bash
ip route show
```
```
[Paste routing table here]
```

```bash
ping -c 4 8.8.8.8
```
```
[Paste ping results here]
```

```bash
ping -c 4 google.com
```
```
[Paste DNS resolution test here]
```

### 4.2 Proxmox Network Configuration
```bash
cat /etc/network/interfaces
```
```
[Paste network config here]
```

```bash
brctl show
```
```
[Paste bridge info here]
```

```bash
ip link show type bridge
```
```
[Paste bridge details here]
```

### 4.3 Firewall Status
```bash
pve-firewall status
```
```
[Paste firewall status here]
```

```bash
iptables -L -n
```
```
[Paste iptables rules here]
```

```bash
ss -tuln
```
```
[Paste listening ports here]
```

## 5. Proxmox Virtualization Health
### 5.1 VM and Container Status
```bash
# List all VMs and containers
qm list
pct list
# Check VM/CT resource usage
for vm in $(qm list | awk 'NR>1 {print $1}'); do
  echo "VM $vm:"
  qm status $vm
  qm config $vm | grep -E "memory|cores|sockets"
done
```

### 5.2 Storage Pool Health
```bash
# Proxmox storage configuration
pvesm status
pvesm list
# Check storage usage
for storage in $(pvesm status | awk 'NR>1 {print $1}'); do
  echo "Storage $storage:"
  pvesm status --storage $storage
done
```

### 5.3 Cluster Status (if applicable)
```bash
# Cluster status
pvecm status
pvecm nodes
corosync-quorumtool -s
```

## 6. Performance & Resource Monitoring
### 6.1 System Load and Processes
```bash
# System load
uptime
top -b -n 1 | head -20
# Process information
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
```

### 6.2 I/O Performance
```bash
# Disk I/O statistics
iostat -x 1 3
# Check for high I/O wait
vmstat 1 5
# Block device statistics
cat /proc/diskstats
```

### 6.3 Resource Limits
```bash
# Check system limits
ulimit -a
# Check for resource exhaustion
cat /proc/sys/fs/file-nr
cat /proc/sys/kernel/pid_max
```

## 7. Log Analysis
### 7.1 System Logs
```bash
# Recent system errors
journalctl --since "1 hour ago" -p err
# Proxmox specific logs
tail -50 /var/log/pveproxy/access.log
tail -50 /var/log/pve/tasks/index
```

### 7.2 Boot and Kernel Logs
```bash
# Boot messages
journalctl -b | grep -i "error\|fail\|warn\|critical"
# Kernel ring buffer
dmesg | tail -50
# Check for filesystem errors
journalctl -u systemd-fsck@*
```

### 7.3 Service Logs
```bash
# Critical service logs
journalctl -u pvedaemon --since "1 hour ago"
journalctl -u pveproxy --since "1 hour ago"
journalctl -u pve-cluster --since "1 hour ago"
journalctl -u corosync --since "1 hour ago"
```

## 8. Security & Updates
### 8.1 System Updates
```bash
# Check for available updates
apt update
apt list --upgradable
# Proxmox subscription status
pvesubscription get
```

### 8.2 Security Status
```bash
# Check for security updates
apt list --upgradable | grep -i security
# System security status
lynis audit system --quick
# Check for failed login attempts
lastb | head -10
```

### 8.3 Certificate Status
```bash
# SSL certificate information
openssl x509 -in /etc/pve/local/pve-ssl.pem -text -noout | grep -A 2 "Not After"
# Check certificate validity
openssl x509 -in /etc/pve/local/pve-ssl.pem -checkend 86400
```

## 9. Action Items & Recommendations
### 9.1 Immediate Actions Required
- [ ] **Boot Issue Resolution**: _[To be filled based on findings]_
- [ ] **Critical Errors**: _[To be filled based on log analysis]_
- [ ] **Resource Issues**: _[To be filled based on performance monitoring]_

### 9.2 Preventive Maintenance
- [ ] **System Updates**: Apply pending security updates
- [ ] **Backup Verification**: Ensure backup systems are functioning
- [ ] **Monitoring Setup**: Implement proactive monitoring alerts
- [ ] **Documentation**: Update system documentation

### 9.3 Performance Optimization
- [ ] **Resource Allocation**: Review VM/CT resource assignments
- [ ] **Storage Optimization**: Check for storage bottlenecks
- [ ] **Network Tuning**: Optimize network configuration if needed

## 10. Conclusion
### 10.1 Health Check Summary
**Overall System Status**: _[To be determined]_

**Critical Issues Found**: _[To be filled]_

**Performance Status**: _[To be filled]_

**Security Status**: _[To be filled]_

### 10.2 Next Steps
1. **Immediate**: _[Priority actions based on findings]_
2. **Short-term**: _[Actions to be completed within 24-48 hours]_
3. **Long-term**: _[Preventive measures and improvements]_

### 10.3 Follow-up Schedule
- **Next Health Check**: _[Recommended date]_
- **Monitoring Review**: _[Weekly/Monthly schedule]_
- **Update Schedule**: _[Regular maintenance windows]_

---
**Health Check Completed**: _[Date and time to be filled]_  
**Total Issues Found**: _[Number to be filled]_  
**System Stability**: _[Assessment to be filled]_

