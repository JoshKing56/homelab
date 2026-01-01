#!/bin/bash

# Proxmox Data Collection Script
# Runs diagnostic commands and outputs raw JSON data
# No analysis - just data collection for remote processing

set -euo pipefail

SCRIPT_VERSION="1.0.0"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname)
OUTPUT_FILE=""
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-file) OUTPUT_FILE="$2"; shift 2 ;;
        --help|-h) echo "Usage: $0 [--output-file /path/to/output.json]"; exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

log_info() { echo "[INFO] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

safe_exec() {
    local cmd="$1"
    local output_file="$2"
    {
        echo "=== Command: $cmd ==="
        if timeout 30 bash -c "$cmd" 2>&1; then
            echo "=== Exit Code: 0 ==="
        else
            echo "=== Exit Code: $? ==="
        fi
    } > "$output_file" 2>&1
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

# System Overview Data Collection
collect_system_overview() {
    log_info "Collecting system overview data..."
    
    safe_exec "pveversion" "$TEMP_DIR/pveversion.out"
    safe_exec "uname -a" "$TEMP_DIR/uname.out"
    safe_exec "journalctl -b -p err --no-pager" "$TEMP_DIR/boot_errors.out"
    safe_exec "journalctl -b | grep -i 'error\|fail\|warn' | head -50" "$TEMP_DIR/boot_warnings.out"
    safe_exec "dmesg | grep -i 'error\|fail\|warn' | head -50" "$TEMP_DIR/dmesg_issues.out"
    safe_exec "systemctl status pve-cluster --no-pager" "$TEMP_DIR/pve_cluster.out"
    safe_exec "systemctl status pvedaemon --no-pager" "$TEMP_DIR/pvedaemon.out"
    safe_exec "systemctl status pveproxy --no-pager" "$TEMP_DIR/pveproxy.out"
    safe_exec "systemctl status pvestatd --no-pager" "$TEMP_DIR/pvestatd.out"
    safe_exec "systemctl status pve-firewall --no-pager" "$TEMP_DIR/pve_firewall.out"
}

# Hardware Health Data Collection
collect_hardware_health() {
    log_info "Collecting hardware health data..."
    
    safe_exec "lscpu" "$TEMP_DIR/lscpu.out"
    command_exists sensors && safe_exec "sensors" "$TEMP_DIR/sensors.out"
    safe_exec "free -h" "$TEMP_DIR/free.out"
    safe_exec "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Buffers|Cached'" "$TEMP_DIR/meminfo.out"
    safe_exec "dmesg | grep -i 'memory\|oom'" "$TEMP_DIR/memory_issues.out"
    safe_exec "cat /proc/buddyinfo" "$TEMP_DIR/buddyinfo.out"
    safe_exec "dmesg | grep -i 'edac\|ecc\|memory.*error'" "$TEMP_DIR/memory_errors.out"
    safe_exec "cat /proc/pressure/memory" "$TEMP_DIR/memory_pressure.out"
    safe_exec "dmesg | grep -i 'hardware\|acpi\|thermal'" "$TEMP_DIR/hardware_issues.out"
    safe_exec "lspci | grep -E 'VGA|Audio|Network|SATA|USB'" "$TEMP_DIR/pci_devices.out"
}

# Storage and Filesystem Data Collection
collect_storage_filesystem() {
    log_info "Collecting storage and filesystem data..."
    
    safe_exec "lsblk -f" "$TEMP_DIR/lsblk.out"
    safe_exec "fdisk -l" "$TEMP_DIR/fdisk.out"
    safe_exec "blkid" "$TEMP_DIR/blkid.out"
    safe_exec "df -h" "$TEMP_DIR/df_h.out"
    safe_exec "df -i" "$TEMP_DIR/df_i.out"
    safe_exec "du -sh /* 2>/dev/null | sort -hr | head -10" "$TEMP_DIR/disk_usage.out"
    command_exists iostat && safe_exec "iostat -x 1 3" "$TEMP_DIR/iostat.out"
    safe_exec "cat /proc/diskstats" "$TEMP_DIR/diskstats.out"
    safe_exec "dmesg | grep -i 'error\|fail\|timeout' | grep -E 'sd[a-z]|nvme|ata'" "$TEMP_DIR/storage_errors.out"
    safe_exec "journalctl -u systemd-fsck@* --no-pager" "$TEMP_DIR/fsck_logs.out"
    
    # SMART data
    for drive in /dev/sda /dev/sdb /dev/nvme0; do
        [[ -e "$drive" ]] && command_exists smartctl && safe_exec "smartctl -a $drive" "$TEMP_DIR/smart_$(basename $drive).out"
    done
    
    # ZFS
    if command_exists zpool; then
        safe_exec "zpool status" "$TEMP_DIR/zpool_status.out"
        safe_exec "zpool list" "$TEMP_DIR/zpool_list.out"
        safe_exec "zfs list" "$TEMP_DIR/zfs_list.out"
        safe_exec "zpool iostat -v" "$TEMP_DIR/zpool_iostat.out"
        safe_exec "zpool history | tail -20" "$TEMP_DIR/zpool_history.out"
        safe_exec "zfs get all | grep -E 'error|health|checksum'" "$TEMP_DIR/zfs_health.out"
        safe_exec "zpool events | tail -20" "$TEMP_DIR/zpool_events.out"
        safe_exec "cat /proc/spl/kstat/zfs/arcstats | grep -E 'hits|miss|size'" "$TEMP_DIR/zfs_arcstats.out"
    fi
    
    # LVM
    if command_exists pvs; then
        safe_exec "pvs" "$TEMP_DIR/pvs.out"
        safe_exec "vgs" "$TEMP_DIR/vgs.out"
        safe_exec "lvs" "$TEMP_DIR/lvs.out"
        safe_exec "pvdisplay -v" "$TEMP_DIR/pvdisplay.out"
        safe_exec "vgdisplay -v" "$TEMP_DIR/vgdisplay.out"
        safe_exec "lvdisplay -v" "$TEMP_DIR/lvdisplay.out"
        safe_exec "pvck /dev/sda3" "$TEMP_DIR/pvck.out"
        safe_exec "vgck pve" "$TEMP_DIR/vgck.out"
    fi
    
    safe_exec "fsck -n /dev/mapper/pve-root 2>&1 | head -20" "$TEMP_DIR/fsck_root.out"
}

# Network Diagnostics Data Collection
collect_network_diagnostics() {
    log_info "Collecting network diagnostics data..."
    
    safe_exec "ip addr show" "$TEMP_DIR/ip_addr.out"
    safe_exec "ip route show" "$TEMP_DIR/ip_route.out"
    safe_exec "ping -c 3 8.8.8.8" "$TEMP_DIR/ping_test.out"
    safe_exec "nslookup google.com" "$TEMP_DIR/dns_test.out"
    safe_exec "cat /etc/network/interfaces" "$TEMP_DIR/network_interfaces.out"
    safe_exec "brctl show" "$TEMP_DIR/bridge_show.out"
    command_exists pve-firewall && safe_exec "pve-firewall status" "$TEMP_DIR/firewall_status.out"
    safe_exec "ss -tuln" "$TEMP_DIR/listening_ports.out"
}

# Proxmox Virtualization Data Collection
collect_proxmox_virtualization() {
    log_info "Collecting Proxmox virtualization data..."
    
    command_exists qm && safe_exec "qm list" "$TEMP_DIR/qm_list.out"
    command_exists pct && safe_exec "pct list" "$TEMP_DIR/pct_list.out"
    command_exists pvesm && safe_exec "pvesm status" "$TEMP_DIR/pvesm_status.out"
    if command_exists pvecm; then
        safe_exec "pvecm status" "$TEMP_DIR/pvecm_status.out"
        safe_exec "corosync-quorumtool -s" "$TEMP_DIR/corosync_quorum.out"
    fi
}

# Performance Monitoring Data Collection
collect_performance_monitoring() {
    log_info "Collecting performance monitoring data..."
    
    safe_exec "uptime" "$TEMP_DIR/uptime.out"
    safe_exec "top -bn1 | head -20" "$TEMP_DIR/top.out"
    safe_exec "ps aux --sort=-%cpu | head -10" "$TEMP_DIR/top_cpu.out"
    safe_exec "ps aux --sort=-%mem | head -10" "$TEMP_DIR/top_mem.out"
    command_exists iostat && safe_exec "iostat -x 1 3" "$TEMP_DIR/iostat_perf.out"
    safe_exec "cat /proc/loadavg" "$TEMP_DIR/loadavg.out"
    safe_exec "cat /proc/diskstats" "$TEMP_DIR/diskstats_perf.out"
    safe_exec "ulimit -a" "$TEMP_DIR/ulimits.out"
    safe_exec "cat /proc/sys/fs/file-max" "$TEMP_DIR/file_max.out"
    safe_exec "cat /proc/sys/kernel/pid_max" "$TEMP_DIR/pid_max.out"
}

# Log Analysis Data Collection
collect_log_analysis() {
    log_info "Collecting log analysis data..."
    
    safe_exec "journalctl --since '1 hour ago' -p err --no-pager" "$TEMP_DIR/recent_errors.out"
    safe_exec "tail -50 /var/log/pve/tasks/index" "$TEMP_DIR/pve_tasks.out"
    safe_exec "journalctl -b | grep -i 'error\|fail\|warn\|critical' | tail -50" "$TEMP_DIR/boot_issues.out"
    safe_exec "dmesg | grep -i 'error\|fail\|warn' | tail -50" "$TEMP_DIR/kernel_issues.out"
    safe_exec "journalctl -u systemd-fsck@* --no-pager | tail -50" "$TEMP_DIR/fsck_recent.out"
    safe_exec "journalctl -u pvedaemon --since '1 hour ago' --no-pager" "$TEMP_DIR/pvedaemon_recent.out"
    safe_exec "journalctl -u pveproxy --since '1 hour ago' --no-pager" "$TEMP_DIR/pveproxy_recent.out"
    safe_exec "journalctl -u corosync --since '1 hour ago' --no-pager" "$TEMP_DIR/corosync_recent.out"
}

# Security and Updates Data Collection
collect_security_updates() {
    log_info "Collecting security and updates data..."
    
    safe_exec "apt update" "$TEMP_DIR/apt_update.out"
    safe_exec "apt list --upgradable" "$TEMP_DIR/apt_upgradable.out"
    command_exists pvesubscription && safe_exec "pvesubscription get" "$TEMP_DIR/pve_subscription.out"
    safe_exec "apt list --upgradable | grep -i security" "$TEMP_DIR/security_updates.out"
    safe_exec "last | head -10" "$TEMP_DIR/last_logins.out"
    safe_exec "lastb | head -10" "$TEMP_DIR/failed_logins.out"
    safe_exec "openssl x509 -in /etc/pve/local/pve-ssl.pem -text -noout | grep -A 2 'Not After'" "$TEMP_DIR/cert_expiry.out"
    safe_exec "openssl x509 -in /etc/pve/local/pve-ssl.pem -checkend 86400" "$TEMP_DIR/cert_check.out"
}

# Generate raw data JSON
generate_raw_data_json() {
    log_info "Generating raw data JSON..."
    
    local final_json="$TEMP_DIR/raw_data.json"
    
    # Create base structure
    cat > "$final_json" << EOF
{
    "metadata": {
        "script_version": "$SCRIPT_VERSION",
        "timestamp": "$TIMESTAMP",
        "hostname": "$HOSTNAME",
        "collection_type": "raw_data"
    },
    "raw_outputs": {}
}
EOF
    
    # Add all output files to JSON
    for file in "$TEMP_DIR"/*.out; do
        [[ -f "$file" ]] || continue
        local basename=$(basename "$file" .out)
        local content=$(cat "$file" | jq -Rs . 2>/dev/null || echo '""')
        jq --arg key "$basename" --argjson content "$content" '.raw_outputs[$key] = $content' "$final_json" > "$TEMP_DIR/temp.json"
        mv "$TEMP_DIR/temp.json" "$final_json"
    done
    
    # Output final JSON
    if [[ -n "$OUTPUT_FILE" ]]; then
        cp "$final_json" "$OUTPUT_FILE"
        log_info "Raw data saved to: $OUTPUT_FILE"
    else
        cat "$final_json"
    fi
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    log_info "Starting Proxmox Data Collection v$SCRIPT_VERSION"
    log_info "Timestamp: $TIMESTAMP"
    log_info "Hostname: $HOSTNAME"
    
    # Run all data collection
    collect_system_overview
    collect_hardware_health
    collect_storage_filesystem
    collect_network_diagnostics
    collect_proxmox_virtualization
    collect_performance_monitoring
    collect_log_analysis
    collect_security_updates
    
    # Generate raw data JSON
    generate_raw_data_json
    
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    log_info "Data collection completed in ${total_time} seconds"
}

# Check dependencies
missing_tools=()
for tool in jq timeout; do
    command_exists "$tool" || missing_tools+=("$tool")
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_error "Please install: apt update && apt install -y ${missing_tools[*]}"
    exit 1
fi

# Run main function
main "$@"
