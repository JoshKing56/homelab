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
from datetime import datetime
from typing import Dict, List, Any, Tuple
from dataclasses import dataclass

@dataclass
class HealthIssue:
    severity: str  # critical, warning, info
    category: str
    message: str
    recommendation: str

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
                "analysis_timestamp": datetime.utcnow().isoformat() + "Z",
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
                    "recommendation": issue.recommendation
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
        boot_errors = self.count_non_header_lines('boot_errors')
        if boot_errors > 0:
            self.add_issue("warning", "system", 
                         f"Found {boot_errors} boot errors",
                         "Review boot logs and investigate error causes")
        
        # Check service status
        services = {}
        for service in ['pve_cluster', 'pvedaemon', 'pveproxy', 'pvestatd', 'pve_firewall']:
            status_output = self.outputs.get(service, '')
            if 'active (running)' in status_output:
                services[service] = "running"
            else:
                services[service] = "not_running"
                self.add_issue("critical", "services",
                             f"Service {service} is not running",
                             f"Investigate and restart {service} service")
        
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
            if mem_usage_percent > 95:
                self.add_issue("critical", "memory",
                             f"Memory usage at {mem_usage_percent:.1f}%",
                             "Investigate high memory usage and consider adding RAM")
            elif mem_usage_percent > 85:
                self.add_issue("warning", "memory",
                             f"Memory usage at {mem_usage_percent:.1f}%",
                             "Monitor memory usage trends")
        
        # Check for memory errors
        memory_errors = self.count_pattern_matches('memory_errors', r'error|corrupt|fail')
        if memory_errors > 0:
            self.add_issue("warning", "memory",
                         f"Found {memory_errors} memory-related errors",
                         "Check memory hardware and run memory tests")
        
        # Check memory pressure
        memory_pressure = self.outputs.get('memory_pressure', '')
        if 'some' in memory_pressure or 'full' in memory_pressure:
            self.add_issue("warning", "memory",
                         "Memory pressure detected",
                         "Monitor memory usage and consider optimization")
        
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
        for pattern in efi_corruption_patterns:
            efi_issues += len(re.findall(pattern, fsck_logs, re.IGNORECASE))
        
        if efi_issues > 0:
            self.add_issue("critical", "storage",
                         "EFI boot partition corruption detected",
                         "Investigate improper shutdowns and repair EFI partition")
        
        # Check storage errors
        storage_errors = self.count_non_header_lines('storage_errors')
        if storage_errors > 0:
            self.add_issue("warning", "storage",
                         f"Found {storage_errors} storage-related errors",
                         "Check SMART data and hardware connections")
        
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
                                         f"Free up space on {filesystem} immediately")
                        elif usage > 85:
                            high_usage_filesystems.append((filesystem, usage))
                            self.add_issue("warning", "storage",
                                         f"Filesystem {filesystem} at {usage}% capacity",
                                         f"Monitor and plan cleanup for {filesystem}")
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
            self.add_issue("warning", "network",
                         "Internet connectivity test failed",
                         "Check network configuration and routing")
        
        # Check DNS
        dns_output = self.outputs.get('dns_test', '')
        dns_success = 'Address:' in dns_output
        
        if not dns_success:
            self.add_issue("warning", "network",
                         "DNS resolution test failed",
                         "Check DNS configuration in /etc/resolv.conf")
        
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
                if load_1min > 8.0:
                    self.add_issue("critical", "performance",
                                 f"High system load: {load_1min}",
                                 "Investigate high CPU usage and resource contention")
                elif load_1min > 4.0:
                    self.add_issue("warning", "performance",
                                 f"Elevated system load: {load_1min}",
                                 "Monitor system load trends")
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
        
        recent_errors = self.count_non_header_lines('recent_errors')
        boot_issues = self.count_non_header_lines('boot_issues')
        kernel_issues = self.count_non_header_lines('kernel_issues')
        
        if recent_errors > 10:
            self.add_issue("warning", "logs",
                         f"High number of recent errors: {recent_errors}",
                         "Review system logs for recurring issues")
        
        return {
            "recent_errors_count": recent_errors,
            "boot_issues_count": boot_issues,
            "kernel_issues_count": kernel_issues
        }
    
    def analyze_security_updates(self) -> Dict[str, Any]:
        """Analyze security and updates data"""
        
        # Count available updates
        upgradable = self.count_non_header_lines('apt_upgradable')
        security_updates = self.count_non_header_lines('security_updates')
        
        if security_updates > 0:
            self.add_issue("warning", "security",
                         f"{security_updates} security updates available",
                         "Apply security updates as soon as possible")
        
        if upgradable > 20:
            self.add_issue("info", "maintenance",
                         f"{upgradable} packages can be upgraded",
                         "Schedule maintenance window for system updates")
        
        # Check certificate validity
        cert_check = self.outputs.get('cert_check', '')
        cert_valid = 'Certificate will not expire' in cert_check
        
        if not cert_valid:
            self.add_issue("warning", "security",
                         "SSL certificate may be expiring soon",
                         "Check certificate expiration and renew if needed")
        
        # Check failed logins
        failed_logins = self.count_non_header_lines('failed_logins')
        if failed_logins > 10:
            self.add_issue("warning", "security",
                         f"High number of failed logins: {failed_logins}",
                         "Review security logs and consider fail2ban")
        
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
    def add_issue(self, severity: str, category: str, message: str, recommendation: str):
        """Add an issue to the issues list"""
        self.issues.append(HealthIssue(severity, category, message, recommendation))
    
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

def main():
    parser = argparse.ArgumentParser(description='Analyze Proxmox health check data')
    parser.add_argument('input_file', help='JSON file from data collector')
    parser.add_argument('--output-file', help='Output file for analysis report')
    parser.add_argument('--format', choices=['json', 'summary'], default='json',
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
    else:
        # Output JSON
        output = json.dumps(report, indent=2)
        
        if args.output_file:
            with open(args.output_file, 'w') as f:
                f.write(output)
            print(f"Analysis report saved to: {args.output_file}", file=sys.stderr)
        else:
            print(output)

if __name__ == '__main__':
    main()
