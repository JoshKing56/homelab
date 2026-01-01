# Proxmox Health Check Automation

Comprehensive automated health check system for Proxmox VE that runs all diagnostic commands from your manual health check process and outputs structured JSON data.

## Overview

This automation script transforms your 2,458-line manual health check into a fully automated system that:

- **Runs all diagnostic commands** from your original health check document
- **Outputs structured JSON** for easy parsing and integration
- **Detects critical issues** like EFI corruption, hardware failures, and service problems
- **Provides intelligent analysis** with severity classification and recommendations
- **Integrates with cron/systemd** for automated scheduling
- **Maintains historical data** with configurable retention

## Features

### Comprehensive Diagnostics
- **System Overview**: Boot analysis, service status, version information
- **Hardware Health**: CPU, memory, temperature monitoring, hardware errors
- **Storage & Filesystem**: Disk health, SMART data, ZFS/LVM status, fsck analysis
- **Network Diagnostics**: Interface status, connectivity tests, firewall status
- **Proxmox Virtualization**: VM/container status, storage pools, cluster health
- **Performance Monitoring**: Load averages, resource usage, I/O statistics
- **Log Analysis**: System errors, boot issues, service logs
- **Security & Updates**: Available updates, security patches, certificate status
- **Analysis & Recommendations**: Intelligent issue detection and remediation suggestions

### JSON Output Structure
```json
{
    "metadata": {
        "script_version": "1.0.0",
        "timestamp": "2026-01-01T21:51:00Z",
        "hostname": "pve",
        "execution_time_seconds": 45
    },
    "system_overview": {
        "pve_version": "pve-manager/8.3.3/f157a38b211595d6",
        "kernel_info": "Linux pve 6.8.12-8-pve",
        "services": {
            "pve_cluster": "running",
            "pvedaemon": "running"
        }
    },
    "analysis_recommendations": {
        "critical_issues": 1,
        "warning_issues": 2,
        "overall_health": "warning",
        "recommendations": [
            "EFI boot partition corruption detected - investigate improper shutdowns"
        ]
    }
}
```

## Installation

### Prerequisites
- Proxmox VE system
- Root access
- Internet connection for package installation

### Quick Install
```bash
# Copy scripts to Proxmox host
scp proxmox-healthcheck.sh install-healthcheck.sh root@your-proxmox-host:/tmp/

# SSH to Proxmox host
ssh root@your-proxmox-host

# Run installation
cd /tmp
chmod +x install-healthcheck.sh
./install-healthcheck.sh
```

### Manual Installation
```bash
# Install dependencies
apt update && apt install -y jq bc sysstat smartmontools

# Create directories
mkdir -p /opt/proxmox-healthcheck
mkdir -p /var/log/proxmox-healthcheck

# Copy and setup script
cp proxmox-healthcheck.sh /opt/proxmox-healthcheck/
chmod +x /opt/proxmox-healthcheck/proxmox-healthcheck.sh

# Create systemd service and timer (see install script for details)
```

## Usage

### Manual Execution
```bash
# Run health check and output to console
proxmox-healthcheck

# Save to specific file
/opt/proxmox-healthcheck/proxmox-healthcheck.sh --output-file /tmp/health-report.json

# View formatted output
proxmox-healthcheck | jq .
```

### Automated Scheduling

The installation creates a systemd timer that runs:
- **Daily at 6:00 AM**
- **5 minutes after system boot**
- **Persistent** (catches up if system was offline)

```bash
# Check timer status
systemctl status proxmox-healthcheck.timer

# View service logs
journalctl -u proxmox-healthcheck.service

# Manual timer trigger
systemctl start proxmox-healthcheck.service
```

### Cron Alternative
If you prefer cron over systemd timers:
```bash
# Add to root crontab
0 6 * * * /opt/proxmox-healthcheck/proxmox-healthcheck.sh --output-file /var/log/proxmox-healthcheck/daily-$(date +\%Y\%m\%d).json

# Weekly comprehensive check
0 2 * * 0 /opt/proxmox-healthcheck/proxmox-healthcheck.sh --output-file /var/log/proxmox-healthcheck/weekly-$(date +\%Y\%m\%d).json
```

## Configuration

### Main Configuration
Edit `/opt/proxmox-healthcheck/healthcheck.conf`:
```bash
# Report retention
REPORT_RETENTION_DAYS=30

# Alert thresholds
CRITICAL_LOAD_THRESHOLD=8.0
WARNING_LOAD_THRESHOLD=4.0
CRITICAL_MEMORY_THRESHOLD=95
WARNING_MEMORY_THRESHOLD=85

# Notifications
ENABLE_EMAIL_ALERTS=true
EMAIL_RECIPIENT="admin@yourdomain.com"
```

### Log Rotation
Reports are automatically rotated via `/etc/logrotate.d/proxmox-healthcheck`:
- Daily rotation
- 30 days retention
- Compression after 1 day

## Integration Examples

### Monitoring Systems

#### Grafana Dashboard
```bash
# Export metrics to InfluxDB
jq -r '.analysis_recommendations.critical_issues' /var/log/proxmox-healthcheck/latest.json
```

#### Prometheus Integration
```bash
# Create metrics endpoint
echo "proxmox_critical_issues $(jq '.analysis_recommendations.critical_issues' /path/to/report.json)" > /var/lib/node_exporter/textfile_collector/proxmox_health.prom
```

### Alerting

#### Email Alerts
```bash
#!/bin/bash
REPORT="/var/log/proxmox-healthcheck/latest.json"
CRITICAL=$(jq '.analysis_recommendations.critical_issues' "$REPORT")

if [[ $CRITICAL -gt 0 ]]; then
    jq '.analysis_recommendations.recommendations[]' "$REPORT" | \
    mail -s "Proxmox Critical Issues Detected" admin@yourdomain.com
fi
```

#### Slack/Discord Webhook
```bash
#!/bin/bash
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
REPORT="/var/log/proxmox-healthcheck/latest.json"
HEALTH=$(jq -r '.analysis_recommendations.overall_health' "$REPORT")

if [[ "$HEALTH" != "healthy" ]]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"Proxmox Health Status: $HEALTH\"}" \
        "$WEBHOOK_URL"
fi
```

### Log Forwarding

#### Rsyslog to Central Server
```bash
# Add to /etc/rsyslog.conf
$ModLoad imfile
$InputFileName /var/log/proxmox-healthcheck/*.json
$InputFileTag proxmox-health:
$InputFileStateFile stat-proxmox-health
$InputFileSeverity info
$InputFileFacility local0
$InputRunFileMonitor

# Forward to central server
local0.* @@logserver.yourdomain.com:514
```

#### ELK Stack Integration
```bash
# Filebeat configuration
- type: log
  paths:
    - /var/log/proxmox-healthcheck/*.json
  json.keys_under_root: true
  json.add_error_key: true
  fields:
    logtype: proxmox-healthcheck
```

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Ensure script runs as root
sudo /opt/proxmox-healthcheck/proxmox-healthcheck.sh

# Check file permissions
ls -la /opt/proxmox-healthcheck/
```

#### Missing Dependencies
```bash
# Install missing tools
apt install -y jq bc sysstat smartmontools

# Verify installation
jq --version
bc --version
iostat -V
smartctl --version
```

#### Service Not Running
```bash
# Check systemd status
systemctl status proxmox-healthcheck.timer
systemctl status proxmox-healthcheck.service

# View logs
journalctl -u proxmox-healthcheck.service -f

# Restart services
systemctl restart proxmox-healthcheck.timer
```

### Debug Mode
```bash
# Run with verbose output
bash -x /opt/proxmox-healthcheck/proxmox-healthcheck.sh

# Check temporary files (if script fails)
ls -la /tmp/tmp.*/
```

## Security Considerations

### File Permissions
- Scripts run as root for full system access
- Reports contain sensitive system information
- Secure the reports directory appropriately

### Network Security
- Health checks include network diagnostics
- Consider firewall rules for remote monitoring
- Use secure channels for log forwarding

### Data Retention
- Configure appropriate retention policies
- Consider encryption for stored reports
- Implement secure deletion for old reports

## Customization

### Adding Custom Checks
```bash
# Add to the script in run_custom_checks() function
run_custom_checks() {
    log_info "Running custom checks..."
    
    # Your custom diagnostic commands
    safe_exec "your-custom-command" "$TEMP_DIR/custom_check.out"
    
    # Process results and add to JSON
}
```

### Modifying Thresholds
Edit the analysis section in `proxmox-healthcheck.sh`:
```bash
# Customize alert thresholds
if (( $(echo "$load_avg > 10.0" | bc -l) )); then
    ((critical_issues++))
fi
```

### Custom Output Formats
```bash
# Add CSV output option
if [[ "$OUTPUT_FORMAT" == "csv" ]]; then
    generate_csv_report
fi
```

## Performance Impact

### Resource Usage
- **CPU**: Low impact, mostly I/O bound operations
- **Memory**: ~50MB peak usage during execution
- **Disk**: Minimal, mainly for temporary files and reports
- **Network**: Only for connectivity tests

### Execution Time
- **Typical runtime**: 30-60 seconds
- **Factors**: Number of VMs/containers, storage complexity, network tests
- **Optimization**: Skip non-essential checks if needed

## Maintenance

### Regular Tasks
```bash
# Update the script
cd /opt/proxmox-healthcheck
wget -O proxmox-healthcheck.sh.new https://your-repo/proxmox-healthcheck.sh
# Review changes and replace

# Clean old reports manually
find /var/log/proxmox-healthcheck -name "*.json" -mtime +60 -delete

# Review and update thresholds
vim /opt/proxmox-healthcheck/healthcheck.conf
```

### Monitoring the Monitor
```bash
# Check if health checks are running
ls -la /var/log/proxmox-healthcheck/ | tail -5

# Verify recent execution
systemctl list-timers | grep proxmox-healthcheck

# Monitor for script failures
journalctl -u proxmox-healthcheck.service --since "1 week ago" | grep -i error
```

## Support

### Log Locations
- **Service logs**: `journalctl -u proxmox-healthcheck.service`
- **Health reports**: `/var/log/proxmox-healthcheck/`
- **Configuration**: `/opt/proxmox-healthcheck/healthcheck.conf`
- **Installation logs**: `/var/log/syslog` (during installation)

### Useful Commands
```bash
# View latest report summary
jq '.analysis_recommendations' /var/log/proxmox-healthcheck/$(ls -t /var/log/proxmox-healthcheck/*.json | head -1)

# Check script version
grep "SCRIPT_VERSION=" /opt/proxmox-healthcheck/proxmox-healthcheck.sh

# Validate JSON output
jq empty /var/log/proxmox-healthcheck/latest.json && echo "Valid JSON" || echo "Invalid JSON"
```

This automation system provides the same comprehensive diagnostics as your manual process but with the benefits of automation, structured output, and integration capabilities. The JSON format makes it easy to build dashboards, alerts, and integrate with existing monitoring infrastructure.
