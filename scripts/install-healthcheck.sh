#!/bin/bash

# Proxmox Data Collector Installation Script
# Deploys the data collection script to Proxmox host

set -euo pipefail

INSTALL_DIR="/opt/proxmox-datacollector"
SCRIPT_NAME="proxmox-data-collector.sh"
REPORTS_DIR="/var/log/proxmox-datacollector"
SERVICE_NAME="proxmox-datacollector"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Check if we're on a Proxmox system
if ! command -v pveversion >/dev/null 2>&1; then
    log_error "This doesn't appear to be a Proxmox system (pveversion not found)"
    exit 1
fi

log_info "Installing Proxmox Data Collector"
log_info "Proxmox Version: $(pveversion | head -1)"

# Install required dependencies
log_info "Installing required packages..."
apt update
apt install -y jq

# Create installation directory
log_info "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$REPORTS_DIR"

# Copy the health check script (assuming it's in the same directory)
if [[ -f "$SCRIPT_NAME" ]]; then
    log_info "Installing health check script..."
    cp "$SCRIPT_NAME" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
else
    log_error "Health check script '$SCRIPT_NAME' not found in current directory"
    exit 1
fi

# Create systemd service file
log_info "Creating systemd service..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=Proxmox Data Collector
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/$SCRIPT_NAME --output-file $REPORTS_DIR/proxmox-data-\$(date +\%Y\%m\%d-\%H\%M\%S).json
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer file
log_info "Creating systemd timer..."
cat > "/etc/systemd/system/${SERVICE_NAME}.timer" << EOF
[Unit]
Description=Run Proxmox Data Collector
Requires=${SERVICE_NAME}.service

[Timer]
# Run daily at 6 AM
OnCalendar=*-*-* 06:00:00
# Run 5 minutes after boot
OnBootSec=5min
# If the system was off when the timer should have run, run it as soon as possible
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Create configuration file
log_info "Creating configuration file..."
cat > "$INSTALL_DIR/datacollector.conf" << EOF
# Proxmox Data Collector Configuration

# Report retention (days)
REPORT_RETENTION_DAYS=30

# Collection settings
COLLECTION_FREQUENCY="daily"
COLLECTION_RETENTION_DAYS=30

# Transfer settings (optional)
ENABLE_AUTO_TRANSFER=false
TRANSFER_DESTINATION="user@local-machine:/path/to/analysis/folder"
TRANSFER_METHOD="scp"
EOF

# Create log rotation configuration
log_info "Setting up log rotation..."
cat > "/etc/logrotate.d/proxmox-datacollector" << EOF
$REPORTS_DIR/*.json {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Create cleanup script for old reports
log_info "Creating cleanup script..."
cat > "$INSTALL_DIR/cleanup-reports.sh" << EOF
#!/bin/bash
# Clean up old data collection reports
find $REPORTS_DIR -name "*.json" -mtime +30 -delete
find $REPORTS_DIR -name "*.json.gz" -mtime +90 -delete
EOF
chmod +x "$INSTALL_DIR/cleanup-reports.sh"

# Add cleanup to daily cron
echo "0 2 * * * root $INSTALL_DIR/cleanup-reports.sh" > /etc/cron.d/proxmox-datacollector-cleanup

# Reload systemd but don't start services
log_info "Creating systemd services (not starting)..."
systemctl daemon-reload

# Services are created but not enabled or started
log_info "Services created but not started - you can enable them later with:"  
log_info "  systemctl enable --now ${SERVICE_NAME}.timer"

# Create manual run script
log_info "Creating manual run script..."
cat > "$INSTALL_DIR/run-datacollector.sh" << EOF
#!/bin/bash
# Manual data collection execution
TIMESTAMP=\$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$REPORTS_DIR/manual-data-\$TIMESTAMP.json"

echo "Running Proxmox Data Collector..."
echo "Output will be saved to: \$OUTPUT_FILE"

$INSTALL_DIR/$SCRIPT_NAME --output-file "\$OUTPUT_FILE"

echo "Data collection completed!"
echo "View results: jq . \$OUTPUT_FILE"
EOF
chmod +x "$INSTALL_DIR/run-datacollector.sh"

# Create symlink for easy access
ln -sf "$INSTALL_DIR/run-datacollector.sh" /usr/local/bin/proxmox-datacollector

# Skip initial data collection
log_info "Skipping initial data collection - you can run it manually later with:"  
log_info "  $INSTALL_DIR/run-datacollector.sh"

# Display installation summary
log_info "Installation completed successfully!"
echo
echo "=== Installation Summary ==="
echo "Installation Directory: $INSTALL_DIR"
echo "Reports Directory: $REPORTS_DIR"
echo "Service Name: $SERVICE_NAME"
echo "Timer Status: inactive (not started)"
echo
echo "=== Usage ==="
echo "Manual run: proxmox-datacollector"
echo "View timer status: systemctl status ${SERVICE_NAME}.timer"
echo "View service logs: journalctl -u ${SERVICE_NAME}.service"
echo "View latest report: ls -la $REPORTS_DIR/"
echo
echo "=== Schedule ==="
echo "Automatic runs: Not enabled - must be manually started"
echo "When enabled: Daily at 6:00 AM and 5 minutes after boot"
echo "Report retention: 30 days (configurable in $INSTALL_DIR/datacollector.conf)"
echo
echo "=== Next Steps ==="
echo "1. Review configuration: $INSTALL_DIR/datacollector.conf"
echo "2. Enable the service when ready: systemctl enable --now ${SERVICE_NAME}.timer"
echo "3. Or run manually: proxmox-datacollector"
echo "4. Copy JSON data to local machine for analysis"
echo "5. Run the analyzer script on your local machine"

log_warn "Note: The data collector runs as root and collects comprehensive system information."
log_warn "Ensure proper security measures are in place for the reports directory."
