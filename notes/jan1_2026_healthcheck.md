# Jan 1, 2026 Health Check
**Date:** January 1, 2026  
**Time Started:** 2:46 PM UTC-05:00  
**Issue:** Boot issues requiring full system diagnostics  
**Proxmox Version:** Proxmox VE 8.3.0 (running kernel: 6.8.12-8-pve)  
**Hardware:** AMD Ryzen 5 3600 6-Core, 62.74GB RAM, 67.73GB SSD, 1.82TB HDD  

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

#### **Boot Analysis Summary**

**🔴 Critical Issues:**
1. **VFIO Module Loading Failures** - `Failed to find module 'vfio_virqfd'` (from journalctl - GPU passthrough may not work)
2. **NVMe Drive Errors** - `/dev/nvme0` error count increased from 273 to 275 (from journalctl - storage reliability concern)
3. **LXC Container 101 Security Issues** - Extensive AppArmor denials blocking mount operations for `/dev/shm/`, `/dev/`, and namespace operations

**🟡 Warning Issues:**
4. **Network Connectivity** - Tailscale DNS resolution failures, Postfix email delivery issues to `kinghome.com`
5. **Hardware/Boot Warnings** - PCIe ACS overrides enabled (security risk), TSC calibration failed, SATA port 5 link resume failure
6. **Filesystem Warning** - EXT4 MMP interval higher than expected on device dm-7

**🟢 Minor Issues:**
7. **ACPI/Power Management** - _OSC evaluation for CPUs failed, using _PDC fallback
8. **RAS Initialization** - Correctable Errors collector initialized (normal but indicates error monitoring active)

**Immediate Actions:**
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

#### **System Services Summary**

**🟡 Warning Issues Found:**
1. **PVE-Cluster RRDC Errors** - Storage monitoring failing for all pools (`storagezfs`, `local-lvm`, `local`, `backup-storage`, `backups`)
2. **PVEProxy Worker Restart** - Worker process 1572 crashed and was replaced with worker 9527 at 15:04:34
3. **PVEStatd Performance** - Status update taking 37.208 seconds (should be much faster)
4. **PVEStatd Auth Key Rotation** - "auth key pair too old, rotating" indicates security key maintenance

**✅ Services Running Normally:**
- **pve-cluster**: Active and running (despite RRDC errors)
- **pvedaemon**: Active with successful authentications and VNC shell sessions
- **pveproxy**: Active (despite worker restart)
- **pvestatd**: Active and running (despite performance issues)
- **pve-firewall**: Active and running normally

**ℹ️ Notes:**
- **LXC Container 101** CPU set modified to cores 0-1 (resource management active)

**Immediate Actions:**
- Check RRD cache daemon: `systemctl status rrdcached`
- Investigate storage monitoring failures (likely causing pvestatd slowness)
- Monitor pveproxy stability for additional worker crashes

## 2. Hardware Health Check
### 2.1 CPU Information
```bash
lscpu
```
```
[Paste lscpu output here]
```

```bash
cat /proc/cpuinfo | grep "model name" | head -1
```
```
[Paste CPU model here]
```

```bash
sensors | grep -i temp
```
```
[Paste temperature readings here]
```

### 2.2 Memory Information
```bash
free -h
```
```
[Paste memory usage here]
```

```bash
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached"
```
```
[Paste memory info here]
```

```bash
dmesg | grep -i "memory\|oom"
```
```
[Paste memory errors here]
```

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
df -h
```
```
[Paste disk usage here]
```

```bash
df -i
```
```
[Paste inode usage here]
```

```bash
du -sh /* 2>/dev/null | sort -hr | head -10
```
```
[Paste large directories here]
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
zpool events | tail -20
```
```
[Paste ZFS events here]
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

