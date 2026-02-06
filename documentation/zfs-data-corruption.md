# ZFS Data Corruption Issue - VM 103

**Status**: Documented but not resolved - DO NOT TOUCH until VM 103 issues are resolved

**Date Identified**: February 5, 2026

## Issue Summary
ZFS pool `storage` has 4 data errors in the file `storage/backup/vm-103-disk-0:<0x1>`

## Details
```
Pool: storage
Status: ONLINE (functional)
Corrupted file: storage/backup/vm-103-disk-0 (762GB old disk image)
Location: /storage/backup/
Last scrub: January 11, 2026 - repaired 0B with 4 errors
```

## Context
- VM 103 ("dad-sandbox") is currently having issues
- The corrupted file is an OLD disk image stored in backup location (not the actual running VM disk)
- A recent proper backup exists: `vzdump-qemu-103-2026_01_02-21_26_18.vma.zst` (Jan 2, 2026, 262GB)
- The running VM disk (`storage/vm-102-disk-0`) is NOT corrupted

## Resolution Options (for later)
Once VM 103 issues are resolved, you can:

### Option 1: Delete the corrupted old disk (safest)
```bash
zfs destroy storage/backup/vm-103-disk-0
zpool clear storage
zpool status storage  # Verify errors cleared
```

### Option 2: Clear error flag but keep file
```bash
zpool clear storage
```
Note: This doesn't fix corruption, just acknowledges it.

## Impact
- No immediate impact on running VMs
- 762GB of space tied up in corrupted backup
- ZFS will continue reporting errors until resolved
- Pool remains functional and protected (RAIDZ1 redundancy intact)

## Monitoring
Check pool status periodically:
```bash
zpool status storage
```

**Action deferred**: Will address after VM 103 issues are resolved.
