# Proxmox Health Check Report: pve 🔴

**Generated:** 2026-01-02T03:29:30.772498Z
**Analyzer Version:** 1.0.0
**Overall Health:** CRITICAL

## Executive Summary

| Category | Count |
| -------- | ----- |
| 🔴 Critical Issues | 1 |
| 🟠 Warning Issues | 5 |
| 🔵 Info Items | 0 |
| **Total** | **6** |

### Recommendations

1. CRITICAL: Address the following issues immediately:
2.   - Investigate improper shutdowns and repair EFI partition
3. WARNING: Address these issues during next maintenance:
4.   - Review boot logs and investigate error causes
5.   - Check memory hardware and run memory tests
6.   - Monitor memory usage and consider optimization
7.   - Check SMART data and hardware connections
8.   - Apply security updates as soon as possible

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

**1. Found 5 boot errors**
   - **Category:** system
   - **Recommendation:** Review boot logs and investigate error causes
   - **Source Command:** `journalctl -b -p err --no-pager`
   - **Evidence:**
     ```
     Jan 01 22:20:28 pve systemd-modules-load[465]: Failed to find module 'nvidia'
     ```
     ```
     Jan 01 22:20:28 pve systemd-modules-load[465]: Failed to find module 'nvidia_uvm'
     ```
     ```
     Jan 01 22:20:28 pve systemd-modules-load[465]: Failed to find module 'nvidia_drm'
     ```
     ```
     Jan 01 22:20:28 pve systemd-modules-load[465]: Failed to find module 'nvidia_modeset'
     ```
     ```
     Jan 01 22:20:39 pve smartd[1097]: Device: /dev/nvme0, number of Error Log entries increased from 283 to 285
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
     some avg10=0.00 avg60=0.00 avg300=0.00 total=10
     ```
     ```
     full avg10=0.00 avg60=0.00 avg300=0.00 total=9
     ```

**4. Found 2 storage-related errors**
   - **Category:** storage
   - **Recommendation:** Check SMART data and hardware connections
   - **Source Command:** `dmesg | grep -i 'error\|fail\|timeout' | grep -E 'sd[a-z]|nvme|ata'`
   - **Evidence:**
     ```
     [    3.844693] ata5: failed to resume link (SControl 0)
     ```
     ```
     [    5.025450] nvme nvme0: Shutdown timeout set to 10 seconds
     ```

**5. 1 security updates available**
   - **Category:** security
   - **Recommendation:** Apply security updates as soon as possible
   - **Source Command:** `apt list --upgradable | grep -i security`
   - **Evidence:**
     ```
     WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
     ```

## Detailed Analysis

### System Overview

- **Proxmox Version:** pve-manager/8.4.16/368e3c45c15b895c (running kernel: 6.8.12-17-pve)
- **Kernel:** Linux pve 6.8.12-17-pve #1 SMP PREEMPT_DYNAMIC PMX 6.8.12-17 (2025-11-21T11:16Z) x86_64 GNU/Linux

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
**Memory:** 60.63GB available of 62.74GB total (3.4% used)
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

**Available Updates:** 🔴 2 packages (1 security updates)
**SSL Certificate:** ✅ Valid
**Failed Logins:** 🟢 4

---
*Report generated by Proxmox Health Check Analyzer v1.0.0*