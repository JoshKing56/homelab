# Proxmox Health Check Automation

Comprehensive automated health check system for Proxmox VE with a split architecture: a server-side data collector and a local analyzer script.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Customization](#customization)
- [Maintenance](#maintenance)

## Overview

This split architecture transforms your 2,458-line manual health check into a fully automated system that:

- **Separates data collection from analysis** for better security and flexibility
- **Runs all diagnostic commands** from your original health check document
- **Outputs structured JSON** for easy parsing and integration
- **Detects critical issues** like EFI corruption, hardware failures, and service problems
- **Provides intelligent analysis** with severity classification and recommendations
- **Integrates with cron/systemd** for automated scheduling
- **Maintains historical data** with configurable retention

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

## Architecture

**Server-Side Data Collector** (`proxmox-data-collector.sh`)
- Runs on Proxmox host with minimal dependencies (only `jq`)
- Executes all diagnostic commands and outputs raw JSON data
- Designed for automated scheduling via systemd/cron

**Local Analyzer** (`proxmox-analyzer.py`)
- Runs on your local machine
- Performs intelligent analysis on collected JSON data
- Generates recommendations and reports in multiple formats (JSON, summary, markdown)

**Key Benefits:** Minimal server footprint for security, analyze multiple servers from one location, update analysis logic without touching production servers, historical data comparison

## Installation

### Prerequisites
- **Server**: Proxmox VE system with root access
- **Local**: Python 3.6+ and `uv` (optional but recommended)

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

The installer will:
- Install required dependencies (`jq`)
- Create `/opt/proxmox-datacollector/` directory
- Set up systemd timer (not started by default)
- Configure log rotation
- Create manual run script

### Local Machine Setup

```bash
# Copy analyzer files
scp root@proxmox:/path/to/proxmox-analyzer.py .
scp root@proxmox:/path/to/pyproject.toml .
scp root@proxmox:/path/to/requirements.txt .

# Create virtual environment (use uv for faster installs, or standard venv)
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -e .              # Or: uv pip install -e .
pip install -e ".[dev]"       # Optional: with development tools
```

## Usage

### Complete Workflow

```bash
# 1. On Proxmox server: Collect data
proxmox-datacollector
# Creates JSON file in /var/log/proxmox-datacollector/

# 2. Copy data to local machine
scp root@proxmox:/var/log/proxmox-datacollector/manual-data-*.json ./

# 3. On local machine: Analyze data
python3 proxmox-analyzer.py manual-data-20260101-123456.json --format summary

# 4. Generate different output formats
python3 proxmox-analyzer.py data.json --format json --output-file analysis.json
python3 proxmox-analyzer.py data.json --format markdown --output-file report.md
```

### Server-Side Scheduling

The installation creates a systemd timer (not enabled by default):

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

**Schedule:**
- Daily at 6:00 AM
- 5 minutes after system boot
- Persistent (catches up if system was offline)

**Cron Alternative:**
```bash
# Add to root crontab on Proxmox
0 6 * * * /opt/proxmox-datacollector/proxmox-data-collector.sh --output-file /var/log/proxmox-datacollector/daily-$(date +\%Y\%m\%d).json
```

### Output Formats

```bash
# JSON - structured data for machine processing
python3 proxmox-analyzer.py data.json --format json --output-file report.json

# Summary - concise text output for quick review
python3 proxmox-analyzer.py data.json --format summary

# Markdown - comprehensive formatted report with severity indicators
python3 proxmox-analyzer.py data.json --format markdown --output-file report.md
```

## Configuration

### Server-Side Configuration

Edit `/opt/proxmox-datacollector/datacollector.conf`:

```bash
# Report retention (days)
REPORT_RETENTION_DAYS=30

# Collection settings
COLLECTION_FREQUENCY="daily"

# Transfer settings (optional)
ENABLE_AUTO_TRANSFER=false
TRANSFER_DESTINATION="user@local-machine:/path/to/analysis/folder"
```

### Log Rotation

Reports are automatically rotated via `/etc/logrotate.d/proxmox-datacollector`:
- Daily rotation
- 30 days retention
- Compression after 1 day

## Troubleshooting

### Server Issues
```bash
# Ensure script runs as root
sudo /opt/proxmox-datacollector/proxmox-data-collector.sh

# Install missing dependencies
apt install -y jq

# Check systemd status and logs
systemctl status proxmox-datacollector.timer
journalctl -u proxmox-datacollector.service -f
```

### Analyzer Issues
```bash
# Validate JSON file
jq empty input.json && echo "Valid JSON" || echo "Invalid JSON"

# Debug mode
bash -x /opt/proxmox-datacollector/proxmox-data-collector.sh
```

## Security

- Data collector runs as root and reports contain sensitive system information
- Use secure methods (SCP/SFTP) for transferring data
- Consider encryption for stored reports and secure deletion for old reports
- Secure the reports directory with appropriate permissions

## Customization

**Custom Data Collection:** Add new `collect_*` functions to `proxmox-data-collector.sh` and call them from `main()`. Use `safe_exec` to run commands and store output.

**Custom Analysis:** Add analysis methods to `proxmox-analyzer.py` that read from `self.outputs` and call them from `analyze_all()`.

**Modify Thresholds:** Edit threshold values in the analyzer's issue detection logic (e.g., load averages, disk usage percentages).

## Maintenance

### Log Locations

**Server-Side:**
- Service logs: `journalctl -u proxmox-datacollector.service`
- Data files: `/var/log/proxmox-datacollector/`
- Configuration: `/opt/proxmox-datacollector/datacollector.conf`

**Local Machine:**
- Analysis reports: Wherever you save the analyzer output

---

This split architecture provides the same comprehensive diagnostics as your manual process but with the benefits of separation of concerns, better security, and more flexibility. The server-side component is lightweight while the local analyzer provides powerful insights without burdening your production systems.
