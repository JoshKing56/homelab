#!/usr/bin/env python3

"""
Proxmox Health Check Analyzer
Analyzes raw data collected from Proxmox servers and generates health reports
Runs locally - takes JSON input from data collector script
"""

import json
import sys
import argparse
import re
from datetime import datetime, UTC
from typing import Dict, List, Any, Tuple
from dataclasses import dataclass
import textwrap

@dataclass
class HealthIssue:
    severity: str  # critical, warning, info
    category: str
    message: str
    recommendation: str
    source_command: str = "unknown"
    evidence: List[str] = None
    
    def __post_init__(self):
        if self.evidence is None:
            self.evidence = []

class ProxmoxAnalyzer:
    def __init__(self, raw_data: Dict[str, Any]):
        self.raw_data = raw_data
        self.metadata = raw_data.get('metadata', {})
        self.outputs = raw_data.get('raw_outputs', {})
        self.issues: List[HealthIssue] = []
        
    def analyze_all(self) -> Dict[str, Any]:
        """Run all analysis modules and return comprehensive report"""
        
        # Run analysis modules
        system_analysis = self.analyze_system_overview()
        hardware_analysis = self.analyze_hardware_health()
        storage_analysis = self.analyze_storage_filesystem()
        network_analysis = self.analyze_network_diagnostics()
        virtualization_analysis = self.analyze_proxmox_virtualization()
        performance_analysis = self.analyze_performance_monitoring()
        log_analysis = self.analyze_log_analysis()
        security_analysis = self.analyze_security_updates()
        
        # Generate recommendations
        recommendations = self.generate_recommendations()
        
        # Create final report
        report = {
            "metadata": {
                "analyzer_version": "1.0.0",
                "analysis_timestamp": datetime.now(UTC).isoformat().replace('+00:00', 'Z'),
                "source_hostname": self.metadata.get('hostname', 'unknown'),
                "source_timestamp": self.metadata.get('timestamp', 'unknown')
            },
            "analysis": {
                "system_overview": system_analysis,
                "hardware_health": hardware_analysis,
                "storage_filesystem": storage_analysis,
                "network_diagnostics": network_analysis,
                "proxmox_virtualization": virtualization_analysis,
                "performance_monitoring": performance_analysis,
                "log_analysis": log_analysis,
                "security_updates": security_analysis
            },
            "summary": {
                "total_issues": len(self.issues),
                "critical_issues": len([i for i in self.issues if i.severity == "critical"]),
                "warning_issues": len([i for i in self.issues if i.severity == "warning"]),
                "info_issues": len([i for i in self.issues if i.severity == "info"]),
                "overall_health": self.calculate_overall_health(),
                "recommendations": recommendations
            },
            "issues": [
                {
                    "severity": issue.severity,
                    "category": issue.category,
                    "message": issue.message,
                    "recommendation": issue.recommendation,
                    "source_command": issue.source_command,
                    "evidence": issue.evidence
                }
                for issue in self.issues
            ]
        }
        
        return report
    
    def analyze_system_overview(self) -> Dict[str, Any]:
        """Analyze system overview data"""
        
        pve_version = self.extract_first_line('pveversion')
        kernel_info = self.extract_first_line('uname')
        
        # Check boot errors
        boot_errors_output = self.outputs.get('boot_errors', '')
        boot_errors = self.count_non_header_lines('boot_errors')
        if boot_errors > 0:
            evidence = [line.strip() for line in boot_errors_output.split('\n') 
                       if line.strip() and not line.startswith('===')][:5]  # First 5 lines
            self.add_issue("warning", "system", 
                         f"Found {boot_errors} boot errors",
                         "Review boot logs and investigate error causes",
                         source_command=self.extract_command('boot_errors'),
                         evidence=evidence)
        
        # Check service status
        services = {}
        for service in ['pve_cluster', 'pvedaemon', 'pveproxy', 'pvestatd', 'pve_firewall']:
            status_output = self.outputs.get(service, '')
            if 'active (running)' in status_output:
                services[service] = "running"
            else:
                services[service] = "not_running"
                evidence = [line.strip() for line in status_output.split('\n') if line.strip()][:3]
                self.add_issue("critical", "services",
                             f"Service {service} is not running",
                             f"Investigate and restart {service} service",
                             source_command=self.extract_command(service),
                             evidence=evidence)
        
        return {
            "pve_version": pve_version,
            "kernel_info": kernel_info,
            "boot_errors_count": boot_errors,
            "services": services
        }
    
    def analyze_hardware_health(self) -> Dict[str, Any]:
        """Analyze hardware health data"""
        
        # CPU analysis
        cpu_model = self.extract_value_after_colon('lscpu', 'Model name')
        cpu_cores = self.extract_value_after_colon('lscpu', 'CPU(s)')
        
        # Memory analysis
        mem_total = self.extract_meminfo_value('MemTotal')
        mem_available = self.extract_meminfo_value('MemAvailable')
        
        if mem_total and mem_available:
            mem_usage_percent = ((mem_total - mem_available) / mem_total) * 100
            meminfo_output = self.outputs.get('meminfo', '')
            mem_evidence = [line.strip() for line in meminfo_output.split('\n') if 'Mem' in line][:5]
            if mem_usage_percent > 95:
                self.add_issue("critical", "memory",
                             f"Memory usage at {mem_usage_percent:.1f}%",
                             "Investigate high memory usage and consider adding RAM",
                             source_command=self.extract_command('meminfo'),
                             evidence=mem_evidence)
            elif mem_usage_percent > 85:
                self.add_issue("warning", "memory",
                             f"Memory usage at {mem_usage_percent:.1f}%",
                             "Monitor memory usage trends",
                             source_command=self.extract_command('meminfo'),
                             evidence=mem_evidence)
        
        # Check for memory errors
        memory_errors_output = self.outputs.get('memory_errors', '')
        memory_errors = self.count_pattern_matches('memory_errors', r'error|corrupt|fail')
        if memory_errors > 0:
            error_lines = [line.strip() for line in memory_errors_output.split('\n') 
                          if re.search(r'error|corrupt|fail', line, re.IGNORECASE) and line.strip()][:5]
            self.add_issue("warning", "memory",
                         f"Found {memory_errors} memory-related errors",
                         "Check memory hardware and run memory tests",
                         source_command=self.extract_command('memory_errors'),
                         evidence=error_lines)
        
        # Check memory pressure
        memory_pressure = self.outputs.get('memory_pressure', '')
        if 'some' in memory_pressure or 'full' in memory_pressure:
            pressure_lines = [line.strip() for line in memory_pressure.split('\n') if line.strip()][:3]
            self.add_issue("warning", "memory",
                         "Memory pressure detected",
                         "Monitor memory usage and consider optimization",
                         source_command=self.extract_command('memory_pressure'),
                         evidence=pressure_lines)
        
        return {
            "cpu": {
                "model": cpu_model,
                "cores": cpu_cores
            },
            "memory": {
                "total_kb": mem_total,
                "available_kb": mem_available,
                "usage_percent": round(mem_usage_percent, 1) if mem_total and mem_available else 0,
                "errors_detected": memory_errors > 0
            }
        }
    
    def analyze_storage_filesystem(self) -> Dict[str, Any]:
        """Analyze storage and filesystem data"""
        
        # Check for EFI corruption (critical issue from original report)
        fsck_logs = self.outputs.get('fsck_logs', '')
        efi_corruption_patterns = [
            r'dirty.*corrupt',
            r'boot.*sector.*backup',
            r'Filesystem was changed',
            r'not properly unmounted'
        ]
        
        efi_issues = 0
        efi_evidence_lines = []
        for pattern in efi_corruption_patterns:
            matches = re.findall(f".*{pattern}.*", fsck_logs, re.IGNORECASE)
            efi_issues += len(matches)
            efi_evidence_lines.extend([m.strip() for m in matches])
        
        if efi_issues > 0:
            self.add_issue("critical", "storage",
                         "EFI boot partition corruption detected",
                         "Investigate improper shutdowns and repair EFI partition",
                         source_command=self.extract_command('fsck_logs'),
                         evidence=efi_evidence_lines[:5])
        
        # Check storage errors
        storage_errors_output = self.outputs.get('storage_errors', '')
        storage_errors = self.count_non_header_lines('storage_errors')
        if storage_errors > 0:
            error_evidence = [line.strip() for line in storage_errors_output.split('\n') 
                             if line.strip() and not line.startswith('===')][:5]
            self.add_issue("warning", "storage",
                         f"Found {storage_errors} storage-related errors",
                         "Check SMART data and hardware connections",
                         source_command=self.extract_command('storage_errors'),
                         evidence=error_evidence)
        
        # Check disk usage
        df_output = self.outputs.get('df_h', '')
        high_usage_filesystems = []
        for line in df_output.split('\n'):
            if '%' in line and not line.startswith('==='):
                parts = line.split()
                if len(parts) >= 5:
                    try:
                        usage_str = parts[4].rstrip('%')
                        usage = int(usage_str)
                        filesystem = parts[5] if len(parts) > 5 else parts[0]
                        
                        if usage > 95:
                            high_usage_filesystems.append((filesystem, usage))
                            self.add_issue("critical", "storage",
                                         f"Filesystem {filesystem} at {usage}% capacity",
                                         f"Free up space on {filesystem} immediately",
                                         source_command=self.extract_command('df_h'),
                                         evidence=[line.strip()])
                        elif usage > 85:
                            high_usage_filesystems.append((filesystem, usage))
                            self.add_issue("warning", "storage",
                                         f"Filesystem {filesystem} at {usage}% capacity",
                                         f"Monitor and plan cleanup for {filesystem}",
                                         source_command=self.extract_command('df_h'),
                                         evidence=[line.strip()])
                    except (ValueError, IndexError):
                        continue
        
        return {
            "efi_corruption_detected": efi_issues > 0,
            "storage_errors_count": storage_errors,
            "high_usage_filesystems": high_usage_filesystems,
            "zfs_available": 'zpool_status' in self.outputs,
            "lvm_available": 'pvs' in self.outputs
        }
    
    def analyze_network_diagnostics(self) -> Dict[str, Any]:
        """Analyze network diagnostics data"""
        
        # Check connectivity
        ping_output = self.outputs.get('ping_test', '')
        ping_success = '0% packet loss' in ping_output
        
        if not ping_success:
            ping_evidence = [line.strip() for line in ping_output.split('\n') if line.strip()][-3:]
            self.add_issue("warning", "network",
                         "Internet connectivity test failed",
                         "Check network configuration and routing",
                         source_command=self.extract_command('ping_test'),
                         evidence=ping_evidence)
        
        # Check DNS
        dns_output = self.outputs.get('dns_test', '')
        dns_success = 'Address:' in dns_output
        
        if not dns_success:
            dns_evidence = [line.strip() for line in dns_output.split('\n') if line.strip()]
            self.add_issue("warning", "network",
                         "DNS resolution test failed",
                         "Check DNS configuration in /etc/resolv.conf",
                         source_command=self.extract_command('dns_test'),
                         evidence=dns_evidence)
        
        # Count network interfaces
        ip_addr = self.outputs.get('ip_addr', '')
        interface_count = len(re.findall(r'inet \d+\.\d+\.\d+\.\d+', ip_addr))
        
        return {
            "ping_test_success": ping_success,
            "dns_test_success": dns_success,
            "interface_count": interface_count
        }
    
    def analyze_proxmox_virtualization(self) -> Dict[str, Any]:
        """Analyze Proxmox virtualization data"""
        
        # Count VMs and containers
        vm_count = 0
        container_count = 0
        
        qm_list = self.outputs.get('qm_list', '')
        if qm_list:
            vm_count = len([line for line in qm_list.split('\n') 
                           if 'running' in line or 'stopped' in line])
        
        pct_list = self.outputs.get('pct_list', '')
        if pct_list:
            container_count = len([line for line in pct_list.split('\n') 
                                 if 'running' in line or 'stopped' in line])
        
        return {
            "vm_count": vm_count,
            "container_count": container_count,
            "cluster_available": 'pvecm_status' in self.outputs
        }
    
    def analyze_performance_monitoring(self) -> Dict[str, Any]:
        """Analyze performance monitoring data"""
        
        # Load average analysis
        loadavg = self.outputs.get('loadavg', '')
        load_1min = 0.0
        
        if loadavg:
            try:
                load_1min = float(loadavg.split()[0])
                load_evidence = [loadavg.strip()]
                if load_1min > 8.0:
                    self.add_issue("critical", "performance",
                                 f"High system load: {load_1min}",
                                 "Investigate high CPU usage and resource contention",
                                 source_command=self.extract_command('loadavg'),
                                 evidence=load_evidence)
                elif load_1min > 4.0:
                    self.add_issue("warning", "performance",
                                 f"Elevated system load: {load_1min}",
                                 "Monitor system load trends",
                                 source_command=self.extract_command('loadavg'),
                                 evidence=load_evidence)
            except (ValueError, IndexError):
                pass
        
        # Uptime analysis
        uptime_output = self.outputs.get('uptime', '')
        uptime_days = 0
        if 'days' in uptime_output:
            try:
                uptime_days = int(re.search(r'(\d+) days', uptime_output).group(1))
            except (AttributeError, ValueError):
                pass
        
        return {
            "load_average_1min": load_1min,
            "uptime_days": uptime_days
        }
    
    def analyze_log_analysis(self) -> Dict[str, Any]:
        """Analyze log data"""
        
        recent_errors_output = self.outputs.get('recent_errors', '')
        recent_errors = self.count_non_header_lines('recent_errors')
        boot_issues = self.count_non_header_lines('boot_issues')
        kernel_issues = self.count_non_header_lines('kernel_issues')
        
        if recent_errors > 10:
            error_evidence = [line.strip() for line in recent_errors_output.split('\n') 
                             if line.strip() and not line.startswith('===')][:5]
            self.add_issue("warning", "logs",
                         f"High number of recent errors: {recent_errors}",
                         "Review system logs for recurring issues",
                         source_command=self.extract_command('recent_errors'),
                         evidence=error_evidence)
        
        return {
            "recent_errors_count": recent_errors,
            "boot_issues_count": boot_issues,
            "kernel_issues_count": kernel_issues
        }
    
    def analyze_security_updates(self) -> Dict[str, Any]:
        """Analyze security and updates data"""
        
        # Count available updates
        upgradable = self.count_non_header_lines('apt_upgradable')
        security_updates_output = self.outputs.get('security_updates', '')
        security_updates = self.count_non_header_lines('security_updates')
        
        if security_updates > 0:
            sec_evidence = [line.strip() for line in security_updates_output.split('\n') 
                           if line.strip() and not line.startswith('===')][:5]
            self.add_issue("warning", "security",
                         f"{security_updates} security updates available",
                         "Apply security updates as soon as possible",
                         source_command=self.extract_command('security_updates'),
                         evidence=sec_evidence)
        
        if upgradable > 20:
            upgradable_output = self.outputs.get('apt_upgradable', '')
            upgrade_evidence = [line.strip() for line in upgradable_output.split('\n') 
                               if line.strip() and not line.startswith('===')][:5]
            self.add_issue("info", "maintenance",
                         f"{upgradable} packages can be upgraded",
                         "Schedule maintenance window for system updates",
                         source_command=self.extract_command('apt_upgradable'),
                         evidence=upgrade_evidence)
        
        # Check certificate validity
        cert_check = self.outputs.get('cert_check', '')
        cert_valid = 'Certificate will not expire' in cert_check
        
        if not cert_valid:
            cert_evidence = [line.strip() for line in cert_check.split('\n') if line.strip()][:3]
            self.add_issue("warning", "security",
                         "SSL certificate may be expiring soon",
                         "Check certificate expiration and renew if needed",
                         source_command=self.extract_command('cert_check'),
                         evidence=cert_evidence)
        
        # Check failed logins
        failed_logins_output = self.outputs.get('failed_logins', '')
        failed_logins = self.count_non_header_lines('failed_logins')
        if failed_logins > 10:
            login_evidence = [line.strip() for line in failed_logins_output.split('\n') 
                             if line.strip() and not line.startswith('===')][:5]
            self.add_issue("warning", "security",
                         f"High number of failed logins: {failed_logins}",
                         "Review security logs and consider fail2ban",
                         source_command=self.extract_command('failed_logins'),
                         evidence=login_evidence)
        
        return {
            "upgradable_packages": upgradable,
            "security_updates": security_updates,
            "certificate_valid": cert_valid,
            "failed_logins_count": failed_logins
        }
    
    def generate_recommendations(self) -> List[str]:
        """Generate prioritized recommendations based on issues found"""
        
        recommendations = []
        
        # Critical issues first
        critical_issues = [i for i in self.issues if i.severity == "critical"]
        if critical_issues:
            recommendations.append("CRITICAL: Address the following issues immediately:")
            for issue in critical_issues[:5]:  # Top 5 critical
                recommendations.append(f"  - {issue.recommendation}")
        
        # Warning issues
        warning_issues = [i for i in self.issues if i.severity == "warning"]
        if warning_issues:
            recommendations.append("WARNING: Address these issues during next maintenance:")
            for issue in warning_issues[:5]:  # Top 5 warnings
                recommendations.append(f"  - {issue.recommendation}")
        
        # General recommendations
        if not critical_issues and not warning_issues:
            recommendations.append("System appears healthy - continue regular monitoring")
        
        return recommendations
    
    def calculate_overall_health(self) -> str:
        """Calculate overall system health status"""
        
        critical_count = len([i for i in self.issues if i.severity == "critical"])
        warning_count = len([i for i in self.issues if i.severity == "warning"])
        
        if critical_count > 0:
            return "critical"
        elif warning_count > 3:
            return "degraded"
        elif warning_count > 0:
            return "warning"
        else:
            return "healthy"
    
    # Utility methods
    def add_issue(self, severity: str, category: str, message: str, recommendation: str, 
                  source_command: str = "unknown", evidence: List[str] = None):
        """Add an issue to the issues list"""
        self.issues.append(HealthIssue(severity, category, message, recommendation, source_command, evidence or []))
    
    def extract_first_line(self, output_key: str) -> str:
        """Extract first non-header line from output"""
        output = self.outputs.get(output_key, '')
        for line in output.split('\n'):
            if not line.startswith('===') and line.strip():
                return line.strip()
        return "unknown"
    
    def extract_value_after_colon(self, output_key: str, search_term: str) -> str:
        """Extract value after colon for a given search term"""
        output = self.outputs.get(output_key, '')
        for line in output.split('\n'):
            if search_term in line and ':' in line:
                return line.split(':', 1)[1].strip()
        return "unknown"
    
    def extract_meminfo_value(self, key: str) -> int:
        """Extract memory value from meminfo output"""
        meminfo = self.outputs.get('meminfo', '')
        for line in meminfo.split('\n'):
            if line.startswith(key):
                try:
                    return int(line.split()[1])
                except (IndexError, ValueError):
                    pass
        return 0
    
    def count_non_header_lines(self, output_key: str) -> int:
        """Count non-header lines in output"""
        output = self.outputs.get(output_key, '')
        return len([line for line in output.split('\n') 
                   if line.strip() and not line.startswith('===')])
    
    def count_pattern_matches(self, output_key: str, pattern: str) -> int:
        """Count regex pattern matches in output"""
        output = self.outputs.get(output_key, '')
        return len(re.findall(pattern, output, re.IGNORECASE))
    
    def extract_command(self, output_key: str) -> str:
        """Extract the actual command from the output header"""
        output = self.outputs.get(output_key, '')
        match = re.search(r'=== Command: (.+?) ===', output)
        if match:
            return match.group(1)
        return output_key  # Fallback to the key name

def main():
    parser = argparse.ArgumentParser(description='Analyze Proxmox health check data')
    parser.add_argument('input_file', help='JSON file from data collector')
    parser.add_argument('--output-file', help='Output file for analysis report')
    parser.add_argument('--format', choices=['json', 'summary', 'markdown'], default='json',
                       help='Output format (default: json)')
    
    args = parser.parse_args()
    
    try:
        with open(args.input_file, 'r') as f:
            raw_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: Input file '{args.input_file}' not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in input file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Run analysis
    analyzer = ProxmoxAnalyzer(raw_data)
    report = analyzer.analyze_all()
    
    # Output results
    if args.format == 'summary':
        # Print human-readable summary
        print(f"Proxmox Health Analysis Report")
        print(f"Source: {report['metadata']['source_hostname']}")
        print(f"Analysis Time: {report['metadata']['analysis_timestamp']}")
        print(f"Overall Health: {report['summary']['overall_health'].upper()}")
        print(f"\nIssue Summary:")
        print(f"  Critical: {report['summary']['critical_issues']}")
        print(f"  Warning:  {report['summary']['warning_issues']}")
        print(f"  Info:     {report['summary']['info_issues']}")
        
        if report['summary']['recommendations']:
            print(f"\nRecommendations:")
            for rec in report['summary']['recommendations']:
                print(f"  {rec}")
    elif args.format == 'markdown':
        # Generate markdown report
        output = generate_markdown_report(report)
        
        if args.output_file:
            with open(args.output_file, 'w') as f:
                f.write(output)
            print(f"Markdown report saved to: {args.output_file}", file=sys.stderr)
        else:
            print(output)
    else:
        # Output JSON
        output = json.dumps(report, indent=2)
        
        if args.output_file:
            with open(args.output_file, 'w') as f:
                f.write(output)
            print(f"Analysis report saved to: {args.output_file}", file=sys.stderr)
        else:
            print(output)

def generate_markdown_report(report: Dict[str, Any]) -> str:
    """Generate a comprehensive markdown report from the analysis results"""
    
    # Extract metadata
    hostname = report['metadata']['source_hostname']
    timestamp = report['metadata']['analysis_timestamp']
    analyzer_version = report['metadata']['analyzer_version']
    
    # Extract summary data
    overall_health = report['summary']['overall_health'].upper()
    critical_issues = report['summary']['critical_issues']
    warning_issues = report['summary']['warning_issues']
    info_issues = report['summary']['info_issues']
    total_issues = critical_issues + warning_issues + info_issues
    
    # Health status emoji
    health_emoji = "🔴" if overall_health == "CRITICAL" else "🟠" if overall_health == "WARNING" else "🟢"
    
    # Start building markdown
    md = []
    
    # Title and metadata
    md.append(f"# Proxmox Health Check Report: {hostname} {health_emoji}")
    md.append(f"")
    md.append(f"**Generated:** {timestamp}")
    md.append(f"**Analyzer Version:** {analyzer_version}")
    md.append(f"**Overall Health:** {overall_health}")
    md.append(f"")
    
    # Executive summary
    md.append(f"## Executive Summary")
    md.append(f"")
    md.append(f"| Category | Count |")
    md.append(f"| -------- | ----- |")
    md.append(f"| 🔴 Critical Issues | {critical_issues} |")
    md.append(f"| 🟠 Warning Issues | {warning_issues} |")
    md.append(f"| 🔵 Info Items | {info_issues} |")
    md.append(f"| **Total** | **{total_issues}** |")
    md.append(f"")
    
    # Recommendations
    if report['summary']['recommendations']:
        md.append(f"### Recommendations")
        md.append(f"")
        for i, rec in enumerate(report['summary']['recommendations'], 1):
            md.append(f"{i}. {rec}")
        md.append(f"")
    
    # Issues list
    if report['issues']:
        md.append(f"## Detected Issues")
        md.append(f"")
        
        # Group issues by severity
        critical = [i for i in report['issues'] if i['severity'] == 'critical']
        warning = [i for i in report['issues'] if i['severity'] == 'warning']
        info = [i for i in report['issues'] if i['severity'] == 'info']
        
        # Critical issues
        if critical:
            md.append(f"### 🔴 Critical Issues")
            md.append(f"")
            for i, issue in enumerate(critical, 1):
                md.append(f"**{i}. {issue['message']}**")
                md.append(f"   - **Category:** {issue['category']}")
                md.append(f"   - **Recommendation:** {issue['recommendation']}")
                md.append(f"   - **Source Command:** `{issue['source_command']}`")
                if issue.get('evidence'):
                    md.append(f"   - **Evidence:**")
                    for evidence_line in issue['evidence']:
                        md.append(f"     ```")
                        md.append(f"     {evidence_line}")
                        md.append(f"     ```")
                md.append(f"")
        
        # Warning issues
        if warning:
            md.append(f"### 🟠 Warning Issues")
            md.append(f"")
            for i, issue in enumerate(warning, 1):
                md.append(f"**{i}. {issue['message']}**")
                md.append(f"   - **Category:** {issue['category']}")
                md.append(f"   - **Recommendation:** {issue['recommendation']}")
                md.append(f"   - **Source Command:** `{issue['source_command']}`")
                if issue.get('evidence'):
                    md.append(f"   - **Evidence:**")
                    for evidence_line in issue['evidence']:
                        md.append(f"     ```")
                        md.append(f"     {evidence_line}")
                        md.append(f"     ```")
                md.append(f"")
        
        # Info issues
        if info:
            md.append(f"### 🔵 Information")
            md.append(f"")
            for i, issue in enumerate(info, 1):
                md.append(f"**{i}. {issue['message']}**")
                md.append(f"   - **Category:** {issue['category']}")
                md.append(f"   - **Recommendation:** {issue['recommendation']}")
                md.append(f"   - **Source Command:** `{issue['source_command']}`")
                if issue.get('evidence'):
                    md.append(f"   - **Evidence:**")
                    for evidence_line in issue['evidence']:
                        md.append(f"     ```")
                        md.append(f"     {evidence_line}")
                        md.append(f"     ```")
                md.append(f"")
    
    # Detailed Analysis Sections
    md.append(f"## Detailed Analysis")
    md.append(f"")
    
    # System Overview
    if 'system_overview' in report['analysis']:
        md.append(f"### System Overview")
        md.append(f"")
        sys_data = report['analysis']['system_overview']
        md.append(f"- **Proxmox Version:** {sys_data.get('pve_version', 'Unknown')}")
        md.append(f"- **Kernel:** {sys_data.get('kernel_info', 'Unknown')}")
        
        # Services status
        if 'services' in sys_data:
            md.append(f"")
            md.append(f"#### Services Status")
            md.append(f"")
            md.append(f"| Service | Status |")
            md.append(f"| ------- | ------ |")
            for service, status in sys_data['services'].items():
                status_emoji = "✅" if status == "running" else "❌"
                md.append(f"| {service} | {status_emoji} {status} |")
        md.append(f"")
    
    # Hardware Health
    if 'hardware_health' in report['analysis']:
        md.append(f"### Hardware Health")
        md.append(f"")
        hw_data = report['analysis']['hardware_health']
        
        if 'cpu' in hw_data:
            md.append(f"**CPU:** {hw_data['cpu'].get('model', 'Unknown')} ({hw_data['cpu'].get('cores', 'Unknown')} cores)")
        
        if 'memory' in hw_data:
            mem = hw_data['memory']
            total_gb = round(mem.get('total_kb', 0) / 1024 / 1024, 2)
            avail_gb = round(mem.get('available_kb', 0) / 1024 / 1024, 2)
            usage_pct = mem.get('usage_percent', 0)
            md.append(f"**Memory:** {avail_gb}GB available of {total_gb}GB total ({usage_pct}% used)")
            
            if mem.get('errors_detected', False):
                md.append(f"⚠️ **Memory errors detected**")
        md.append(f"")
    
    # Storage and Filesystem
    if 'storage_filesystem' in report['analysis']:
        md.append(f"### Storage and Filesystem")
        md.append(f"")
        storage_data = report['analysis']['storage_filesystem']
        
        if storage_data.get('efi_corruption_detected', False):
            md.append(f"⚠️ **EFI corruption detected**")
        
        if storage_data.get('high_usage_filesystems'):
            md.append(f"")
            md.append(f"#### High Usage Filesystems")
            md.append(f"")
            md.append(f"| Filesystem | Usage |")
            md.append(f"| ---------- | ----- |")
            for fs, usage in storage_data['high_usage_filesystems']:
                usage_emoji = "🔴" if usage > 95 else "🟠"
                md.append(f"| {fs} | {usage_emoji} {usage}% |")
        
        md.append(f"")
        md.append(f"**Storage Technologies:**")
        md.append(f"- ZFS: {'Available' if storage_data.get('zfs_available', False) else 'Not available'}")
        md.append(f"- LVM: {'Available' if storage_data.get('lvm_available', False) else 'Not available'}")
        md.append(f"")
    
    # Network Diagnostics
    if 'network_diagnostics' in report['analysis']:
        md.append(f"### Network Diagnostics")
        md.append(f"")
        net_data = report['analysis']['network_diagnostics']
        
        md.append(f"| Test | Status |")
        md.append(f"| ---- | ------ |")
        ping_status = "✅ Success" if net_data.get('ping_test_success', False) else "❌ Failed"
        dns_status = "✅ Success" if net_data.get('dns_test_success', False) else "❌ Failed"
        md.append(f"| Internet Connectivity | {ping_status} |")
        md.append(f"| DNS Resolution | {dns_status} |")
        md.append(f"")
        md.append(f"**Network Interfaces:** {net_data.get('interface_count', 0)}")
        md.append(f"")
    
    # Virtualization
    if 'proxmox_virtualization' in report['analysis']:
        md.append(f"### Virtualization")
        md.append(f"")
        virt_data = report['analysis']['proxmox_virtualization']
        
        md.append(f"**Virtual Machines:** {virt_data.get('vm_count', 0)}")
        md.append(f"**Containers:** {virt_data.get('container_count', 0)}")
        md.append(f"**Cluster:** {'Available' if virt_data.get('cluster_available', False) else 'Not available'}")
        md.append(f"")
    
    # Performance
    if 'performance_monitoring' in report['analysis']:
        md.append(f"### Performance")
        md.append(f"")
        perf_data = report['analysis']['performance_monitoring']
        
        load = perf_data.get('load_average_1min', 0)
        load_emoji = "🔴" if load > 8.0 else "🟠" if load > 4.0 else "🟢"
        md.append(f"**Load Average:** {load_emoji} {load}")
        md.append(f"**Uptime:** {perf_data.get('uptime_days', 0)} days")
        md.append(f"")
    
    # Security and Updates
    if 'security_updates' in report['analysis']:
        md.append(f"### Security and Updates")
        md.append(f"")
        sec_data = report['analysis']['security_updates']
        
        updates = sec_data.get('upgradable_packages', 0)
        security = sec_data.get('security_updates', 0)
        
        updates_emoji = "🔴" if security > 0 else "🟠" if updates > 20 else "🟢"
        md.append(f"**Available Updates:** {updates_emoji} {updates} packages ({security} security updates)")
        
        cert_status = "✅ Valid" if sec_data.get('certificate_valid', True) else "❌ Expiring or invalid"
        md.append(f"**SSL Certificate:** {cert_status}")
        
        logins = sec_data.get('failed_logins_count', 0)
        login_emoji = "🟠" if logins > 10 else "🟢"
        md.append(f"**Failed Logins:** {login_emoji} {logins}")
        md.append(f"")
    
    # Footer
    md.append(f"---")
    md.append(f"*Report generated by Proxmox Health Check Analyzer v{analyzer_version}*")
    
    return "\n".join(md)

if __name__ == '__main__':
    main()
