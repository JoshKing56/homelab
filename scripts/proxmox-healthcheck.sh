#!/bin/bash

# Proxmox Health Check Automation Script
# Runs comprehensive system diagnostics and outputs structured JSON
# Based on manual health check from Jan 1, 2026
# Usage: ./proxmox-healthcheck.sh [--output-file /path/to/output.json]

set -euo pipefail

# Configuration
SCRIPT_VERSION="1.0.0"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname)
OUTPUT_FILE=""
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--output-file /path/to/output.json]"
            echo "Runs comprehensive Proxmox health check and outputs JSON"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Utility functions
log_info() {
    echo "[INFO] $1" >&2
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Execute command safely and capture output
safe_exec() {
    local cmd="$1"
    local output_file="$2"
    
    {
        echo "=== Command: $cmd ==="
        if timeout 30 bash -c "$cmd" 2>&1; then
            echo "=== Exit Code: 0 ==="
        else
            local exit_code=$?
            echo "=== Exit Code: $exit_code ==="
        fi
    } > "$output_file" 2>&1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Initialize JSON structure
init_json() {
    cat > "$TEMP_DIR/report.json" << EOF
{
    "metadata": {
        "script_version": "$SCRIPT_VERSION",
        "timestamp": "$TIMESTAMP",
        "hostname": "$HOSTNAME",
        "execution_time_seconds": 0
    },
    "system_overview": {},
    "hardware_health": {},
    "storage_filesystem": {},
    "network_diagnostics": {},
    "proxmox_virtualization": {},
    "performance_monitoring": {},
    "log_analysis": {},
    "security_updates": {},
    "analysis_recommendations": {}
}
EOF
}

# System Overview Section
run_system_overview() {
    log_info "Running system overview checks..."
    
    local section_data="$TEMP_DIR/system_overview.json"
    
    # Basic system information
    safe_exec "pveversion" "$TEMP_DIR/pveversion.out"
    safe_exec "uname -a" "$TEMP_DIR/uname.out"
    
    # Boot analysis
    safe_exec "journalctl -b -p err --no-pager" "$TEMP_DIR/boot_errors.out"
    safe_exec "journalctl -b | grep -i 'error\|fail\|warn' | head -50" "$TEMP_DIR/boot_warnings.out"
    safe_exec "dmesg | grep -i 'error\|fail\|warn' | head -50" "$TEMP_DIR/dmesg_issues.out"
    
    # System services
    safe_exec "systemctl status pve-cluster --no-pager" "$TEMP_DIR/pve_cluster.out"
    safe_exec "systemctl status pvedaemon --no-pager" "$TEMP_DIR/pvedaemon.out"
    safe_exec "systemctl status pveproxy --no-pager" "$TEMP_DIR/pveproxy.out"
    safe_exec "systemctl status pvestatd --no-pager" "$TEMP_DIR/pvestatd.out"
    safe_exec "systemctl status pve-firewall --no-pager" "$TEMP_DIR/pve_firewall.out"
    
    # Create JSON for this section
    cat > "$section_data" << EOF
{
    "pve_version": "$(cat "$TEMP_DIR/pveversion.out" | grep -v "===" | head -1 || echo "unknown")",
    "kernel_info": "$(cat "$TEMP_DIR/uname.out" | grep -v "===" | head -1 || echo "unknown")",
    "boot_errors_count": $(cat "$TEMP_DIR/boot_errors.out" | grep -v "===" | wc -l),
    "boot_warnings_count": $(cat "$TEMP_DIR/boot_warnings.out" | grep -v "===" | wc -l),
    "dmesg_issues_count": $(cat "$TEMP_DIR/dmesg_issues.out" | grep -v "===" | wc -l),
    "services": {
        "pve_cluster": "$(grep -q "active (running)" "$TEMP_DIR/pve_cluster.out" && echo "running" || echo "not_running")",
        "pvedaemon": "$(grep -q "active (running)" "$TEMP_DIR/pvedaemon.out" && echo "running" || echo "not_running")",
        "pveproxy": "$(grep -q "active (running)" "$TEMP_DIR/pveproxy.out" && echo "running" || echo "not_running")",
        "pvestatd": "$(grep -q "active (running)" "$TEMP_DIR/pvestatd.out" && echo "running" || echo "not_running")",
        "pve_firewall": "$(grep -q "active (running)" "$TEMP_DIR/pve_firewall.out" && echo "running" || echo "not_running")"
    }
}
EOF
}

# Hardware Health Section
run_hardware_health() {
    log_info "Running hardware health checks..."
    
    local section_data="$TEMP_DIR/hardware_health.json"
    
    # CPU information
    safe_exec "lscpu" "$TEMP_DIR/lscpu.out"
    if command_exists sensors; then
        safe_exec "sensors" "$TEMP_DIR/sensors.out"
    fi
    
    # Memory information
    safe_exec "free -h" "$TEMP_DIR/free.out"
    safe_exec "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Buffers|Cached'" "$TEMP_DIR/meminfo.out"
    safe_exec "dmesg | grep -i 'memory\|oom'" "$TEMP_DIR/memory_issues.out"
    safe_exec "cat /proc/buddyinfo" "$TEMP_DIR/buddyinfo.out"
    safe_exec "dmesg | grep -i 'edac\|ecc\|memory.*error'" "$TEMP_DIR/memory_errors.out"
    safe_exec "cat /proc/pressure/memory" "$TEMP_DIR/memory_pressure.out"
    
    # Hardware monitoring
    safe_exec "dmesg | grep -i 'hardware\|acpi\|thermal'" "$TEMP_DIR/hardware_issues.out"
    safe_exec "lspci | grep -E 'VGA|Audio|Network|SATA|USB'" "$TEMP_DIR/pci_devices.out"
    
    # Extract key metrics
    local cpu_model=$(grep "Model name:" "$TEMP_DIR/lscpu.out" | cut -d: -f2 | xargs || echo "unknown")
    local cpu_cores=$(grep "CPU(s):" "$TEMP_DIR/lscpu.out" | head -1 | cut -d: -f2 | xargs || echo "unknown")
    local mem_total=$(grep "MemTotal:" "$TEMP_DIR/meminfo.out" | awk '{print $2}' || echo "0")
    local mem_available=$(grep "MemAvailable:" "$TEMP_DIR/meminfo.out" | awk '{print $2}' || echo "0")
    
    cat > "$section_data" << EOF
{
    "cpu": {
        "model": "$cpu_model",
        "cores": "$cpu_cores",
        "temperature_available": $(command_exists sensors && echo "true" || echo "false")
    },
    "memory": {
        "total_kb": $mem_total,
        "available_kb": $mem_available,
        "usage_percent": $(( mem_total > 0 ? (mem_total - mem_available) * 100 / mem_total : 0 )),
        "oom_events": $(cat "$TEMP_DIR/memory_issues.out" | grep -c "oom" || echo "0"),
        "ecc_errors": $(cat "$TEMP_DIR/memory_errors.out" | grep -c "error" || echo "0")
    },
    "hardware_issues_count": $(cat "$TEMP_DIR/hardware_issues.out" | grep -v "===" | wc -l)
}
EOF
}

# Storage and Filesystem Section
run_storage_filesystem() {
    log_info "Running storage and filesystem checks..."
    
    local section_data="$TEMP_DIR/storage_filesystem.json"
    
    # Disk analysis
    safe_exec "lsblk -f" "$TEMP_DIR/lsblk.out"
    safe_exec "fdisk -l" "$TEMP_DIR/fdisk.out"
    safe_exec "blkid" "$TEMP_DIR/blkid.out"
    safe_exec "df -h" "$TEMP_DIR/df_h.out"
    safe_exec "df -i" "$TEMP_DIR/df_i.out"
    safe_exec "du -sh /* 2>/dev/null | sort -hr | head -10" "$TEMP_DIR/disk_usage.out"
    
    # I/O statistics
    if command_exists iostat; then
        safe_exec "iostat -x 1 3" "$TEMP_DIR/iostat.out"
    fi
    safe_exec "cat /proc/diskstats" "$TEMP_DIR/diskstats.out"
    
    # Storage errors
    safe_exec "dmesg | grep -i 'error\|fail\|timeout' | grep -E 'sd[a-z]|nvme|ata'" "$TEMP_DIR/storage_errors.out"
    safe_exec "journalctl -u systemd-fsck@* --no-pager" "$TEMP_DIR/fsck_logs.out"
    
    # SMART data for common drives
    for drive in /dev/sda /dev/sdb /dev/nvme0; do
        if [[ -e "$drive" ]] && command_exists smartctl; then
            safe_exec "smartctl -a $drive" "$TEMP_DIR/smart_$(basename $drive).out"
        fi
    done
    
    # ZFS (if available)
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
    
    # LVM (if available)
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
    
    # Filesystem health
    safe_exec "fsck -n /dev/mapper/pve-root 2>&1 | head -20" "$TEMP_DIR/fsck_root.out"
    
    # Extract key metrics
    local storage_errors=$(cat "$TEMP_DIR/storage_errors.out" | grep -v "===" | wc -l)
    local fsck_issues=$(grep -c "dirty\|corrupt\|error" "$TEMP_DIR/fsck_logs.out" || echo "0")
    local zfs_available=$(command_exists zpool && echo "true" || echo "false")
    local lvm_available=$(command_exists pvs && echo "true" || echo "false")
    
    cat > "$section_data" << EOF
{
    "storage_errors_count": $storage_errors,
    "fsck_issues_count": $fsck_issues,
    "zfs_available": $zfs_available,
    "lvm_available": $lvm_available,
    "smart_data_available": $(command_exists smartctl && echo "true" || echo "false"),
    "iostat_available": $(command_exists iostat && echo "true" || echo "false")
}
EOF
}

# Network Diagnostics Section
run_network_diagnostics() {
    log_info "Running network diagnostics..."
    
    local section_data="$TEMP_DIR/network_diagnostics.json"
    
    # Network interfaces
    safe_exec "ip addr show" "$TEMP_DIR/ip_addr.out"
    safe_exec "ip route show" "$TEMP_DIR/ip_route.out"
    safe_exec "ping -c 3 8.8.8.8" "$TEMP_DIR/ping_test.out"
    safe_exec "nslookup google.com" "$TEMP_DIR/dns_test.out"
    
    # Proxmox network config
    safe_exec "cat /etc/network/interfaces" "$TEMP_DIR/network_interfaces.out"
    safe_exec "brctl show" "$TEMP_DIR/bridge_show.out"
    
    # Firewall and ports
    if command_exists pve-firewall; then
        safe_exec "pve-firewall status" "$TEMP_DIR/firewall_status.out"
    fi
    safe_exec "ss -tuln" "$TEMP_DIR/listening_ports.out"
    
    # Extract key metrics
    local interfaces_count=$(grep -c "inet " "$TEMP_DIR/ip_addr.out" || echo "0")
    local ping_success=$(grep -q "0% packet loss" "$TEMP_DIR/ping_test.out" && echo "true" || echo "false")
    local dns_success=$(grep -q "Address:" "$TEMP_DIR/dns_test.out" && echo "true" || echo "false")
    
    cat > "$section_data" << EOF
{
    "interfaces_count": $interfaces_count,
    "ping_test_success": $ping_success,
    "dns_test_success": $dns_success,
    "firewall_available": $(command_exists pve-firewall && echo "true" || echo "false")
}
EOF
}

# Proxmox Virtualization Section
run_proxmox_virtualization() {
    log_info "Running Proxmox virtualization checks..."
    
    local section_data="$TEMP_DIR/proxmox_virtualization.json"
    
    # VMs and containers
    if command_exists qm; then
        safe_exec "qm list" "$TEMP_DIR/qm_list.out"
    fi
    if command_exists pct; then
        safe_exec "pct list" "$TEMP_DIR/pct_list.out"
    fi
    
    # Storage pools
    if command_exists pvesm; then
        safe_exec "pvesm status" "$TEMP_DIR/pvesm_status.out"
    fi
    
    # Cluster status
    if command_exists pvecm; then
        safe_exec "pvecm status" "$TEMP_DIR/pvecm_status.out"
        safe_exec "corosync-quorumtool -s" "$TEMP_DIR/corosync_quorum.out"
    fi
    
    # Extract key metrics
    local vm_count=$(command_exists qm && grep -c "running\|stopped" "$TEMP_DIR/qm_list.out" 2>/dev/null || echo "0")
    local container_count=$(command_exists pct && grep -c "running\|stopped" "$TEMP_DIR/pct_list.out" 2>/dev/null || echo "0")
    
    cat > "$section_data" << EOF
{
    "vm_count": $vm_count,
    "container_count": $container_count,
    "storage_pools_available": $(command_exists pvesm && echo "true" || echo "false"),
    "cluster_available": $(command_exists pvecm && echo "true" || echo "false")
}
EOF
}

# Performance Monitoring Section
run_performance_monitoring() {
    log_info "Running performance monitoring..."
    
    local section_data="$TEMP_DIR/performance_monitoring.json"
    
    # System load
    safe_exec "uptime" "$TEMP_DIR/uptime.out"
    safe_exec "top -bn1 | head -20" "$TEMP_DIR/top.out"
    safe_exec "ps aux --sort=-%cpu | head -10" "$TEMP_DIR/top_cpu.out"
    safe_exec "ps aux --sort=-%mem | head -10" "$TEMP_DIR/top_mem.out"
    
    # I/O performance
    if command_exists iostat; then
        safe_exec "iostat -x 1 3" "$TEMP_DIR/iostat_perf.out"
    fi
    safe_exec "cat /proc/loadavg" "$TEMP_DIR/loadavg.out"
    safe_exec "cat /proc/diskstats" "$TEMP_DIR/diskstats_perf.out"
    
    # Resource limits
    safe_exec "ulimit -a" "$TEMP_DIR/ulimits.out"
    safe_exec "cat /proc/sys/fs/file-max" "$TEMP_DIR/file_max.out"
    safe_exec "cat /proc/sys/kernel/pid_max" "$TEMP_DIR/pid_max.out"
    
    # Extract key metrics
    local load_avg=$(cat "$TEMP_DIR/loadavg.out" | cut -d' ' -f1 || echo "0")
    local uptime_days=$(cat "$TEMP_DIR/uptime.out" | grep -o "[0-9]* days" | cut -d' ' -f1 || echo "0")
    
    cat > "$section_data" << EOF
{
    "load_average_1min": "$load_avg",
    "uptime_days": "$uptime_days",
    "iostat_available": $(command_exists iostat && echo "true" || echo "false")
}
EOF
}

# Log Analysis Section
run_log_analysis() {
    log_info "Running log analysis..."
    
    local section_data="$TEMP_DIR/log_analysis.json"
    
    # System logs
    safe_exec "journalctl --since '1 hour ago' -p err --no-pager" "$TEMP_DIR/recent_errors.out"
    safe_exec "tail -50 /var/log/pve/tasks/index" "$TEMP_DIR/pve_tasks.out"
    
    # Boot and kernel logs
    safe_exec "journalctl -b | grep -i 'error\|fail\|warn\|critical' | tail -50" "$TEMP_DIR/boot_issues.out"
    safe_exec "dmesg | grep -i 'error\|fail\|warn' | tail -50" "$TEMP_DIR/kernel_issues.out"
    safe_exec "journalctl -u systemd-fsck@* --no-pager | tail -50" "$TEMP_DIR/fsck_recent.out"
    
    # Service logs
    safe_exec "journalctl -u pvedaemon --since '1 hour ago' --no-pager" "$TEMP_DIR/pvedaemon_recent.out"
    safe_exec "journalctl -u pveproxy --since '1 hour ago' --no-pager" "$TEMP_DIR/pveproxy_recent.out"
    safe_exec "journalctl -u corosync --since '1 hour ago' --no-pager" "$TEMP_DIR/corosync_recent.out"
    
    # Extract key metrics
    local recent_errors=$(cat "$TEMP_DIR/recent_errors.out" | grep -v "===" | wc -l)
    local boot_issues=$(cat "$TEMP_DIR/boot_issues.out" | grep -v "===" | wc -l)
    local kernel_issues=$(cat "$TEMP_DIR/kernel_issues.out" | grep -v "===" | wc -l)
    
    cat > "$section_data" << EOF
{
    "recent_errors_count": $recent_errors,
    "boot_issues_count": $boot_issues,
    "kernel_issues_count": $kernel_issues,
    "fsck_logs_available": true
}
EOF
}

# Security and Updates Section
run_security_updates() {
    log_info "Running security and updates check..."
    
    local section_data="$TEMP_DIR/security_updates.json"
    
    # System updates
    safe_exec "apt update" "$TEMP_DIR/apt_update.out"
    safe_exec "apt list --upgradable" "$TEMP_DIR/apt_upgradable.out"
    if command_exists pvesubscription; then
        safe_exec "pvesubscription get" "$TEMP_DIR/pve_subscription.out"
    fi
    
    # Security status
    safe_exec "apt list --upgradable | grep -i security" "$TEMP_DIR/security_updates.out"
    safe_exec "last | head -10" "$TEMP_DIR/last_logins.out"
    safe_exec "lastb | head -10" "$TEMP_DIR/failed_logins.out"
    
    # Certificate status
    safe_exec "openssl x509 -in /etc/pve/local/pve-ssl.pem -text -noout | grep -A 2 'Not After'" "$TEMP_DIR/cert_expiry.out"
    safe_exec "openssl x509 -in /etc/pve/local/pve-ssl.pem -checkend 86400" "$TEMP_DIR/cert_check.out"
    
    # Extract key metrics
    local upgradable_count=$(grep -c "upgradable" "$TEMP_DIR/apt_upgradable.out" || echo "0")
    local security_updates=$(cat "$TEMP_DIR/security_updates.out" | grep -v "===" | wc -l)
    local failed_logins=$(cat "$TEMP_DIR/failed_logins.out" | grep -v "===" | wc -l)
    
    cat > "$section_data" << EOF
{
    "upgradable_packages": $upgradable_count,
    "security_updates": $security_updates,
    "failed_logins_count": $failed_logins,
    "certificate_valid": $(grep -q "Certificate will not expire" "$TEMP_DIR/cert_check.out" && echo "true" || echo "false")
}
EOF
}

# Analysis and Recommendations Section
run_analysis_recommendations() {
    log_info "Running analysis and generating recommendations..."
    
    local section_data="$TEMP_DIR/analysis_recommendations.json"
    
    # Collect all metrics for analysis
    local critical_issues=0
    local warning_issues=0
    local recommendations=()
    
    # Check for EFI corruption pattern (critical issue from original report)
    if grep -q "dirty.*corrupt\|boot.*sector" "$TEMP_DIR/fsck_logs.out" 2>/dev/null; then
        ((critical_issues++))
        recommendations+=("EFI boot partition corruption detected - investigate improper shutdowns")
    fi
    
    # Check storage errors
    if [[ -f "$TEMP_DIR/storage_errors.out" ]] && [[ $(cat "$TEMP_DIR/storage_errors.out" | grep -v "===" | wc -l) -gt 0 ]]; then
        ((warning_issues++))
        recommendations+=("Storage errors detected - check SMART data and hardware")
    fi
    
    # Check memory pressure
    if [[ -f "$TEMP_DIR/memory_pressure.out" ]] && grep -q "some\|full" "$TEMP_DIR/memory_pressure.out"; then
        ((warning_issues++))
        recommendations+=("Memory pressure detected - monitor memory usage")
    fi
    
    # Check failed services
    if grep -q "not_running" "$TEMP_DIR/system_overview.json" 2>/dev/null; then
        ((critical_issues++))
        recommendations+=("Critical Proxmox services not running - investigate service failures")
    fi
    
    # Check high load
    local load_avg=$(cat "$TEMP_DIR/loadavg.out" | cut -d' ' -f1 2>/dev/null || echo "0")
    if (( $(echo "$load_avg > 5.0" | bc -l 2>/dev/null || echo "0") )); then
        ((warning_issues++))
        recommendations+=("High system load detected - investigate resource usage")
    fi
    
    # Create recommendations JSON array
    local rec_json="["
    for i in "${!recommendations[@]}"; do
        [[ $i -gt 0 ]] && rec_json+=","
        rec_json+="\"${recommendations[$i]}\""
    done
    rec_json+="]"
    
    cat > "$section_data" << EOF
{
    "critical_issues": $critical_issues,
    "warning_issues": $warning_issues,
    "total_issues": $((critical_issues + warning_issues)),
    "recommendations": $rec_json,
    "overall_health": "$(
        if [[ $critical_issues -gt 0 ]]; then
            echo "critical"
        elif [[ $warning_issues -gt 0 ]]; then
            echo "warning"
        else
            echo "healthy"
        fi
    )"
}
EOF
}

# Combine all sections into final JSON report
generate_final_report() {
    log_info "Generating final JSON report..."
    
    local end_time=$(date +%s)
    local start_time=$((end_time - SECONDS))
    local execution_time=$((end_time - start_time))
    
    # Update metadata with execution time
    jq --arg exec_time "$execution_time" '.metadata.execution_time_seconds = ($exec_time | tonumber)' "$TEMP_DIR/report.json" > "$TEMP_DIR/report_updated.json"
    
    # Merge all section data
    local final_report="$TEMP_DIR/final_report.json"
    cp "$TEMP_DIR/report_updated.json" "$final_report"
    
    # Add each section if the data file exists
    for section in system_overview hardware_health storage_filesystem network_diagnostics proxmox_virtualization performance_monitoring log_analysis security_updates analysis_recommendations; do
        if [[ -f "$TEMP_DIR/${section}.json" ]]; then
            jq --slurpfile section_data "$TEMP_DIR/${section}.json" ".${section} = \$section_data[0]" "$final_report" > "$TEMP_DIR/temp.json"
            mv "$TEMP_DIR/temp.json" "$final_report"
        fi
    done
    
    # Output final report
    if [[ -n "$OUTPUT_FILE" ]]; then
        cp "$final_report" "$OUTPUT_FILE"
        log_info "Report saved to: $OUTPUT_FILE"
    else
        cat "$final_report"
    fi
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    log_info "Starting Proxmox Health Check v$SCRIPT_VERSION"
    log_info "Timestamp: $TIMESTAMP"
    log_info "Hostname: $HOSTNAME"
    
    # Initialize JSON structure
    init_json
    
    # Run all diagnostic sections
    run_system_overview
    run_hardware_health
    run_storage_filesystem
    run_network_diagnostics
    run_proxmox_virtualization
    run_performance_monitoring
    run_log_analysis
    run_security_updates
    run_analysis_recommendations
    
    # Generate final report
    generate_final_report
    
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    log_info "Health check completed in ${total_time} seconds"
}

# Check if running as root (recommended for full access)
if [[ $EUID -ne 0 ]]; then
    log_error "Warning: Not running as root. Some checks may fail due to insufficient permissions."
fi

# Check for required tools
missing_tools=()
for tool in jq bc timeout; do
    if ! command_exists "$tool"; then
        missing_tools+=("$tool")
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_error "Please install: apt update && apt install -y ${missing_tools[*]}"
    exit 1
fi

# Run main function
main "$@"
