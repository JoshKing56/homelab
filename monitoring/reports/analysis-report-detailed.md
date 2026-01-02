# Proxmox Health Check Report: pve 🔴

**Generated:** 2026-01-01T23:59:35.605978Z
**Analyzer Version:** 1.0.0
**Overall Health:** CRITICAL

## Executive Summary

| Category | Count |
| -------- | ----- |
| 🔴 Critical Issues | 1 |
| 🟠 Warning Issues | 6 |
| 🔵 Info Items | 1 |
| **Total** | **8** |

### Recommendations

1. CRITICAL: Address the following issues immediately:
2.   - Investigate improper shutdowns and repair EFI partition
3. WARNING: Address these issues during next maintenance:
4.   - Review boot logs and investigate error causes
5.   - Check memory hardware and run memory tests
6.   - Monitor memory usage and consider optimization
7.   - Check SMART data and hardware connections
8.   - Review system logs for recurring issues

## Detected Issues

### 🔴 Critical Issues

**1. EFI boot partition corruption detected**
   - **Category:** storage
   - **Recommendation:** Investigate improper shutdowns and repair EFI partition
   - **Source Command:** `journalctl -u systemd-fsck@* --no-pager`
   - **Evidence:**
     ```
     Dec 27 11:34:03 pve systemd-fsck[645]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
     ```
     ```
     Jan 06 12:45:26 pve systemd-fsck[604]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
     ```
     ```
     Feb 07 07:40:31 pve systemd-fsck[617]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
     ```
     ```
     Feb 10 11:03:40 pve systemd-fsck[618]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
     ```
     ```
     Feb 14 15:00:36 pve systemd-fsck[638]: Dirty bit is set. Fs was not properly unmounted and some data may be corrupt.
     ```

### 🟠 Warning Issues

**1. Found 47 boot errors**
   - **Category:** system
   - **Recommendation:** Review boot logs and investigate error causes
   - **Source Command:** `journalctl -b -p err --no-pager`
   - **Evidence:**
     ```
     Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
     ```
     ```
     Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
     ```
     ```
     Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
     ```
     ```
     Jan 01 14:29:21 pve systemd-modules-load[463]: Failed to find module 'vfio_virqfd'
     ```
     ```
     Jan 01 14:29:26 pve smartd[1079]: Device: /dev/nvme0, number of Error Log entries increased from 273 to 275
     ```

**2. Found 1 memory-related errors**
   - **Category:** memory
   - **Recommendation:** Check memory hardware and run memory tests
   - **Source Command:** `dmesg | grep -i 'edac\|ecc\|memory.*error'`
   - **Evidence:**
     ```
     === Command: dmesg | grep -i 'edac\|ecc\|memory.*error' ===
     ```

**3. Memory pressure detected**
   - **Category:** memory
   - **Recommendation:** Monitor memory usage and consider optimization
   - **Source Command:** `cat /proc/pressure/memory`
   - **Evidence:**
     ```
     === Command: cat /proc/pressure/memory ===
     ```
     ```
     some avg10=0.00 avg60=0.00 avg300=0.00 total=803
     ```
     ```
     full avg10=0.00 avg60=0.00 avg300=0.00 total=803
     ```

**4. Found 2 storage-related errors**
   - **Category:** storage
   - **Recommendation:** Check SMART data and hardware connections
   - **Source Command:** `dmesg | grep -i 'error\|fail\|timeout' | grep -E 'sd[a-z]|nvme|ata'`
   - **Evidence:**
     ```
     [    3.535446] ata5: failed to resume link (SControl 0)
     ```
     ```
     [    4.727221] nvme nvme0: Shutdown timeout set to 10 seconds
     ```

**5. High number of recent errors: 20**
   - **Category:** logs
   - **Recommendation:** Review system logs for recurring issues
   - **Source Command:** `journalctl --since '1 hour ago' -p err --no-pager`
   - **Evidence:**
     ```
     Jan 01 16:26:22 pve pvedaemon[1564]: VM 103 qmp command failed - VM 103 qmp command 'guest-ping' failed - got timeout
     ```
     ```
     Jan 01 16:26:41 pve pvedaemon[1562]: VM 103 qmp command failed - VM 103 qmp command 'guest-ping' failed - got timeout
     ```
     ```
     Jan 01 16:27:00 pve pvedaemon[1562]: VM 103 qmp command failed - VM 103 qmp command 'guest-ping' failed - got timeout
     ```
     ```
     Jan 01 16:27:19 pve pvedaemon[1563]: VM 103 qmp command failed - VM 103 qmp command 'guest-ping' failed - got timeout
     ```
     ```
     Jan 01 16:27:38 pve pvedaemon[1562]: VM 103 qmp command failed - VM 103 qmp command 'guest-ping' failed - got timeout
     ```

**6. 30 security updates available**
   - **Category:** security
   - **Recommendation:** Apply security updates as soon as possible
   - **Source Command:** `apt list --upgradable | grep -i security`
   - **Evidence:**
     ```
     WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
     ```
     ```
     bind9-dnsutils/oldstable-security 1:9.18.41-1~deb12u1 amd64 [upgradable from: 1:9.18.33-1~deb12u2]
     ```
     ```
     bind9-host/oldstable-security 1:9.18.41-1~deb12u1 amd64 [upgradable from: 1:9.18.33-1~deb12u2]
     ```
     ```
     bind9-libs/oldstable-security 1:9.18.41-1~deb12u1 amd64 [upgradable from: 1:9.18.33-1~deb12u2]
     ```
     ```
     gnutls-bin/oldstable,oldstable-security,oldstable 3.7.9-2+deb12u5 amd64 [upgradable from: 3.7.9-2+deb12u3]
     ```

### 🔵 Information

**1. 302 packages can be upgraded**
   - **Category:** maintenance
   - **Recommendation:** Schedule maintenance window for system updates
   - **Source Command:** `apt list --upgradable`
   - **Evidence:**
     ```
     WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
     ```
     ```
     Listing...
     ```
     ```
     base-files/oldstable,oldstable 12.4+deb12u12 amd64 [upgradable from: 12.4+deb12u9]
     ```
     ```
     bash/oldstable,oldstable 5.2.15-2+b9 amd64 [upgradable from: 5.2.15-2+b7]
     ```
     ```
     bind9-dnsutils/oldstable-security 1:9.18.41-1~deb12u1 amd64 [upgradable from: 1:9.18.33-1~deb12u2]
     ```

## Detailed Analysis

### System Overview

- **Proxmox Version:** pve-manager/8.3.3/f157a38b211595d6 (running kernel: 6.8.12-8-pve)
- **Kernel:** Linux pve 6.8.12-8-pve #1 SMP PREEMPT_DYNAMIC PMX 6.8.12-8 (2025-01-24T12:32Z) x86_64 GNU/Linux

#### Services Status

| Service | Status |
| ------- | ------ |
| pve_cluster | ✅ running |
| pvedaemon | ✅ running |
| pveproxy | ✅ running |
| pvestatd | ✅ running |
| pve_firewall | ✅ running |

### Hardware Health

**CPU:** AMD Ryzen 5 3600 6-Core Processor (12 cores)
**Memory:** 40.82GB available of 62.74GB total (34.9% used)
⚠️ **Memory errors detected**

### Storage and Filesystem

⚠️ **EFI corruption detected**

**Storage Technologies:**
- ZFS: Available
- LVM: Available

### Network Diagnostics

| Test | Status |
| ---- | ------ |
| Internet Connectivity | ✅ Success |
| DNS Resolution | ✅ Success |

**Network Interfaces:** 3

### Virtualization

**Virtual Machines:** 3
**Containers:** 2
**Cluster:** Available

### Performance

**Load Average:** 🟢 0.0
**Uptime:** 0 days

### Security and Updates

**Available Updates:** 🔴 302 packages (30 security updates)
**SSL Certificate:** ✅ Valid
**Failed Logins:** 🟢 3

---
*Report generated by Proxmox Health Check Analyzer v1.0.0*