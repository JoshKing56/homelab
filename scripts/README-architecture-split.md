# Proxmox Health Check - Split Architecture

This document explains the split architecture approach for the Proxmox health check system.

## Overview

The health check system has been split into two separate components:

1. **Server-Side Data Collector** (`proxmox-data-collector.sh`)
   - Runs on the Proxmox host
   - Collects raw diagnostic data
   - Outputs structured JSON without analysis
   - Minimal dependencies (only `jq`)

2. **Local Analyzer** (`proxmox-analyzer.py`)
   - Runs on your local machine
   - Takes JSON data from the collector
   - Performs intelligent analysis
   - Generates reports and recommendations

## Benefits of Split Architecture

### Security
- **Minimal server footprint** - Only data collection runs on production
- **No complex analysis logic** on critical infrastructure
- **Sensitive data stays local** after collection

### Flexibility
- **Analyze multiple servers** from a single local machine
- **Historical analysis** - Compare data over time
- **Custom analysis** - Modify Python script without touching servers
- **Offline analysis** - No need for server connectivity during analysis

### Maintenance
- **Update analysis logic** without server changes
- **Test new analysis** on historical data
- **Centralized intelligence** - One analyzer for multiple Proxmox hosts

## Workflow

```
┌─────────────────┐                  ┌─────────────────┐
│  Proxmox Host   │                  │  Local Machine  │
│                 │                  │                 │
│  ┌───────────┐  │     Transfer     │  ┌───────────┐  │
│  │ Collector │──┼──────JSON────────┼─▶│ Analyzer  │  │
│  └───────────┘  │                  │  └───────────┘  │
└─────────────────┘                  └─────────────────┘
```

### Step 1: Collect Data (on Proxmox)
```bash
proxmox-datacollector
# Creates JSON file in /var/log/proxmox-datacollector/
```

### Step 2: Transfer Data
```bash
# From your local machine
scp root@proxmox:/var/log/proxmox-datacollector/latest.json ./
```

### Step 3: Analyze Data (on local machine)
```bash
# Generate summary
python3 proxmox-analyzer.py latest.json --format summary

# Or detailed JSON report
python3 proxmox-analyzer.py latest.json --output-file analysis-report.json
```

## Installation

### Server-Side (Proxmox Host)
```bash
# Copy scripts to Proxmox
scp proxmox-data-collector.sh install-healthcheck.sh root@proxmox:/tmp/

# Install
ssh root@proxmox
cd /tmp
chmod +x install-healthcheck.sh
./install-healthcheck.sh
```

### Local Machine
```bash
# Ensure Python 3.6+ is installed
python3 --version

# Copy analyzer script to your local machine
# No additional dependencies required
```

## Automation Options

### Scheduled Data Collection
The installer creates a systemd timer (but does not enable or start it).

```bash
# Enable and start when ready
systemctl enable --now proxmox-datacollector.timer
```

### Automated Transfer
Create a script on your local machine:
```bash
#!/bin/bash
# Pull latest data from Proxmox
SERVER="root@proxmox"
REMOTE_DIR="/var/log/proxmox-datacollector"
LOCAL_DIR="/path/to/analysis/folder"

# Get latest file
LATEST=$(ssh $SERVER "ls -t $REMOTE_DIR/*.json | head -1")
FILENAME=$(basename $LATEST)

# Transfer
scp "$SERVER:$LATEST" "$LOCAL_DIR/$FILENAME"

# Run analysis
python3 proxmox-analyzer.py "$LOCAL_DIR/$FILENAME" --output-file "$LOCAL_DIR/analysis-$FILENAME"
```

## Customization

### Adding Custom Data Collection
Edit `proxmox-data-collector.sh` to add new commands.

### Adding Custom Analysis
Edit `proxmox-analyzer.py` to add new analysis logic.

## Troubleshooting

### Server-Side
- Check if data collector is running: `systemctl status proxmox-datacollector.timer`
- View logs: `journalctl -u proxmox-datacollector.service`
- Validate JSON: `jq empty /var/log/proxmox-datacollector/latest.json`

### Local Analysis
- Validate JSON file: `jq empty input.json`
- Check Python version: `python3 --version` (requires 3.6+)
- Run with verbose output: `python3 -v proxmox-analyzer.py input.json`
