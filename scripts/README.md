# Proxmox Health Check Automation

Comprehensive automated health check system for Proxmox VE with a split architecture: a server-side data collector and a local analyzer script.

## Overview

This split architecture transforms your 2,458-line manual health check into a fully automated system that:

- **Separates data collection from analysis** for better security and flexibility
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

### Architecture

**1. Server-Side Data Collector** (`proxmox-data-collector.sh`)
- Runs on Proxmox host with minimal dependencies
- Executes all diagnostic commands
- Outputs raw JSON data without analysis
- Designed for automated scheduling via systemd/cron

**2. Local Analyzer** (`proxmox-analyzer.py`)
- Runs on your local machine
- Takes JSON input from data collector
- Performs intelligent analysis
- Generates recommendations and reports
- Multiple output formats (JSON, summary)

## Installation

### Prerequisites
- Proxmox VE system
- Root access for server-side installation
- Python 3.6+ for local analyzer

### Server-Side Installation
```bash
# Copy scripts to Proxmox host
scp proxmox-data-collector.sh install-healthcheck.sh root@your-proxmox-host:/tmp/

# SSH to Proxmox host
ssh root@your-proxmox-host

# Run installation
cd /tmp
chmod +x install-healthcheck.sh
./install-healthcheck.sh
```

### Local Machine Setup
```bash
# Ensure Python 3.6+ is installed
python3 --version

# Copy analyzer script to your local machine
# No additional dependencies required for the analyzer
```

## Usage

### Complete Workflow

```bash
# 1. On Proxmox server: Collect data
proxmox-datacollector
# This creates a JSON file in /var/log/proxmox-datacollector/

# 2. Copy data to local machine
scp root@your-proxmox:/var/log/proxmox-datacollector/manual-data-*.json ./

# 3. On local machine: Analyze data
python3 proxmox-analyzer.py manual-data-20260101-123456.json --format summary

# 4. For detailed JSON output
python3 proxmox-analyzer.py manual-data-20260101-123456.json --output-file analysis-report.json
```

### Server-Side Scheduling

The installation creates a systemd timer (but does not enable or start it):
- **When enabled**: Runs daily at 6:00 AM
- **When enabled**: Runs 5 minutes after system boot
- **Persistent**: Catches up if system was offline

```bash
# Enable and start the timer
systemctl enable --now proxmox-datacollector.timer

# Check timer status
systemctl status proxmox-datacollector.timer

# View service logs
journalctl -u proxmox-datacollector.service

# Manual data collection (always available)
proxmox-datacollector
```

### Cron Alternative
If you prefer cron over systemd timers:
```bash
# Add to root crontab on Proxmox
0 6 * * * /opt/proxmox-datacollector/proxmox-data-collector.sh --output-file /var/log/proxmox-datacollector/daily-$(date +\%Y\%m\%d).json
```

## Configuration

### Server-Side Configuration
Edit `/opt/proxmox-datacollector/datacollector.conf`:
```bash
# Report retention
REPORT_RETENTION_DAYS=30

# Collection settings
COLLECTION_FREQUENCY="daily"

# Transfer settings (optional)
ENABLE_AUTO_TRANSFER=false
TRANSFER_DESTINATION="user@local-machine:/path/to/analysis/folder"
```

### Analyzer Configuration
The analyzer script has command-line options:
```bash
python3 proxmox-analyzer.py --help

# Output formats
python3 proxmox-analyzer.py input.json --format json|summary

# Output file
python3 proxmox-analyzer.py input.json --output-file report.json
```

### Log Rotation
Reports are automatically rotated via `/etc/logrotate.d/proxmox-datacollector`:
- Daily rotation
- 30 days retention
- Compression after 1 day

## Integration Examples

### Automated Data Transfer

#### SCP Transfer Script
```bash
#!/bin/bash
# On Proxmox server
LATEST=$(ls -t /var/log/proxmox-datacollector/*.json | head -1)
DEST="user@local-machine:/path/to/analysis/folder/"

scp "$LATEST" "$DEST"
```

#### Automated Analysis
```bash
#!/bin/bash
# On local machine
DATA_DIR="/path/to/analysis/folder"
LATEST=$(ls -t $DATA_DIR/*.json | head -1)

# Run analysis
python3 proxmox-analyzer.py "$LATEST" --output-file "$DATA_DIR/analysis-$(basename $LATEST)"

# Check for critical issues
CRITICAL=$(jq '.summary.critical_issues' "$DATA_DIR/analysis-$(basename $LATEST)")
if [[ $CRITICAL -gt 0 ]]; then
    # Send alert
    mail -s "Proxmox Critical Issues Detected" admin@yourdomain.com < \
      <(jq -r '.summary.recommendations[]' "$DATA_DIR/analysis-$(basename $LATEST)")
fi
```

### Monitoring Integration

#### Grafana Dashboard
```bash
# Export metrics from analyzer output
jq -r '.summary.critical_issues' analysis-report.json
```

#### Slack/Discord Webhook
```bash
#!/bin/bash
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
REPORT="analysis-report.json"
HEALTH=$(jq -r '.summary.overall_health' "$REPORT")

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

### Server-Side Issues

#### Permission Errors
```bash
# Ensure script runs as root
sudo /opt/proxmox-datacollector/proxmox-data-collector.sh

# Check file permissions
ls -la /opt/proxmox-datacollector/
```

#### Missing Dependencies
```bash
# Install missing tools
apt install -y jq

# Verify installation
jq --version
```

#### Service Not Running
```bash
# Check systemd status
systemctl status proxmox-datacollector.timer
systemctl status proxmox-datacollector.service

# View logs
journalctl -u proxmox-datacollector.service -f

# Restart services
systemctl restart proxmox-datacollector.timer
```

### Analyzer Issues

#### Python Version
```bash
# Check Python version (requires 3.6+)
python3 --version
```

#### JSON Parsing Errors
```bash
# Validate JSON file
jq empty input.json && echo "Valid JSON" || echo "Invalid JSON"

# Check file permissions
ls -la input.json
```

#### Debug Mode
```bash
# Run data collector with verbose output
bash -x /opt/proxmox-datacollector/proxmox-data-collector.sh

# Run analyzer with verbose Python
python3 -v proxmox-analyzer.py input.json
```

## Security Considerations

### Split Architecture Benefits
- **Minimal server footprint** - only data collection on production
- **No complex analysis logic** on critical infrastructure
- **Sensitive data stays local** after collection

### File Permissions
- Data collector runs as root for full system access
- Reports contain sensitive system information
- Secure the reports directory appropriately

### Data Transfer
- Use secure methods (SCP/SFTP) for transferring data
- Consider encryption for stored reports
- Implement secure deletion for old reports

### Network Security
- Data collection includes network diagnostics
- Consider firewall rules for remote monitoring
- Use secure channels for data transfer

## Customization

### Adding Custom Data Collection
```bash
# Add to proxmox-data-collector.sh
collect_custom_data() {
    log_info "Collecting custom data..."
    
    # Your custom diagnostic commands
    safe_exec "your-custom-command" "$TEMP_DIR/custom_check.out"
}

# Add to main() function
main() {
    # Existing collection functions
    collect_custom_data  # Add your custom function
}
```

### Adding Custom Analysis
```python
# Add to proxmox-analyzer.py
def analyze_custom_data(self) -> Dict[str, Any]:
    """Analyze custom data"""
    
    custom_output = self.outputs.get('custom_check', '')
    # Your custom analysis logic
    
    return {
        "custom_metric": result
    }

# Add to analyze_all() method
def analyze_all(self):
    # Existing analysis
    custom_analysis = self.analyze_custom_data()
    # Add to final report
```

### Modifying Analysis Thresholds
```python
# In proxmox-analyzer.py
if load_1min > 10.0:  # Change threshold
    self.add_issue("critical", "performance",
                 f"High system load: {load_1min}",
                 "Investigate high CPU usage")
```

## Performance Impact

### Server-Side Resource Usage
- **CPU**: Low impact, mostly I/O bound operations
- **Memory**: ~30MB peak usage during execution
- **Disk**: Minimal, mainly for temporary files and reports
- **Network**: Only for connectivity tests

### Local Analyzer Resource Usage
- **CPU**: Moderate impact during analysis
- **Memory**: ~50MB peak usage during execution
- **Disk**: Minimal, only for report generation

### Execution Time
- **Data collection**: 30-60 seconds on Proxmox host
- **Analysis**: 1-5 seconds on local machine
- **Factors**: Number of VMs/containers, storage complexity, network tests

## Maintenance

### Regular Tasks
```bash
# Update the data collector
cd /opt/proxmox-datacollector
wget -O proxmox-data-collector.sh.new https://your-repo/proxmox-data-collector.sh
# Review changes and replace

# Update the analyzer
wget -O proxmox-analyzer.py.new https://your-repo/proxmox-analyzer.py
# Review changes and replace

# Clean old reports manually
find /var/log/proxmox-datacollector -name "*.json" -mtime +60 -delete
```

### Monitoring the Data Collection
```bash
# Check if data collection is running
ls -la /var/log/proxmox-datacollector/ | tail -5

# Verify recent execution
systemctl list-timers | grep proxmox-datacollector

# Monitor for script failures
journalctl -u proxmox-datacollector.service --since "1 week ago" | grep -i error
```

## Support

### Log Locations

**Server-Side:**
- **Service logs**: `journalctl -u proxmox-datacollector.service`
- **Data files**: `/var/log/proxmox-datacollector/`
- **Configuration**: `/opt/proxmox-datacollector/datacollector.conf`
- **Installation logs**: `/var/log/syslog` (during installation)

**Local Machine:**
- **Analysis reports**: Wherever you save the analyzer output

### Useful Commands

**Server-Side:**
```bash
# View latest data collection
ls -la /var/log/proxmox-datacollector/ | head -5

# Check data collector version
grep "SCRIPT_VERSION=" /opt/proxmox-datacollector/proxmox-data-collector.sh

# Validate JSON output
jq empty /var/log/proxmox-datacollector/latest.json && echo "Valid JSON" || echo "Invalid JSON"
```

**Local Machine:**
```bash
# View analyzer summary
python3 proxmox-analyzer.py data-file.json --format summary

# Extract specific metrics
python3 proxmox-analyzer.py data-file.json | jq '.summary.critical_issues'
```

This split architecture provides the same comprehensive diagnostics as your manual process but with the benefits of separation of concerns, better security, and more flexibility. The server-side component is lightweight while the local analyzer provides powerful insights without burdening your production systems.
