#!/usr/bin/env python3
"""
SSH Config Management CLI Tool
Manages SSH configurations, EC2 instances, and security groups
"""

import inquirer
from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.table import Table
from rich import print as rprint
import subprocess
import json
import os
import re
import logging
import sys
from pathlib import Path
from datetime import datetime
import requests

console = Console()

# Setup logging
def setup_logging():
    """Setup comprehensive logging for the application."""
    # Create logs directory if it doesn't exist
    logs_dir = Path.home() / '.ssh' / 'cli_logs'
    logs_dir.mkdir(exist_ok=True)
    
    # Setup log file with timestamp
    timestamp = datetime.now().strftime('%Y%m%d')
    log_file = logs_dir / f'ssh_cli_{timestamp}.log'
    
    # Configure logging
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler(sys.stdout) if os.getenv('SSH_CLI_DEBUG') else logging.NullHandler()
        ]
    )
    
    logger = logging.getLogger(__name__)
    logger.info(f"SSH CLI started - Log file: {log_file}")
    logger.info(f"Python version: {sys.version}")
    logger.info(f"Working directory: {os.getcwd()}")
    logger.info(f"User: {os.getenv('USER', 'unknown')}")
    
    return logger

class SSHConfigManager:
    def __init__(self):
        self.ssh_config_path = Path.home() / '.ssh' / 'config'
        self.security_group_rules = ["sgr-029111b2b23cd6114", "sgr-0a6a82e6a59e3f1c2"]
        self.logger = logging.getLogger(__name__)
        self.logger.info(f"SSHConfigManager initialized with SSH config path: {self.ssh_config_path}")
        self.logger.info(f"Security group rules: {self.security_group_rules}")
        
    def get_public_ip(self):
        """Get the current public IP address."""
        self.logger.info("Requesting public IP from checkip.amazonaws.com")
        try:
            response = requests.get('http://checkip.amazonaws.com', timeout=10)
            ip = response.text.strip()
            self.logger.info(f"Successfully retrieved public IP: {ip}")
            return ip
        except Exception as e:
            self.logger.error(f"Error getting public IP: {e}")
            console.print(f"[red]Error getting public IP: {e}[/red]")
            return None
    
    def run_aws_command(self, command):
        """Run an AWS CLI command and return the result."""
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True,
                timeout=30
            )
            if result.returncode != 0:
                console.print(f"[red]AWS command failed: {result.stderr}[/red]")
                return None
            return result.stdout
        except Exception as e:
            console.print(f"[red]Error running AWS command: {e}[/red]")
            return None
    
    def list_ec2_instances(self):
        """List all EC2 instances with their details."""
        console.print("[yellow]Fetching EC2 instances...[/yellow]")
        
        command = (
            "aws ec2 describe-instances "
            "--query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name,Tags[?Key==\`Name\`].Value|[0]]' "
            "--output json"
        )
        
        result = self.run_aws_command(command)
        if not result:
            return []
        
        try:
            instances = json.loads(result)
            # Flatten the nested structure
            flat_instances = []
            for reservation in instances:
                for instance in reservation:
                    flat_instances.append({
                        'id': instance[0],
                        'public_ip': instance[1] if instance[1] else 'N/A',
                        'state': instance[2],
                        'name': instance[3] if instance[3] else 'N/A'
                    })
            return flat_instances
        except json.JSONDecodeError:
            console.print("[red]Failed to parse EC2 instance data[/red]")
            return []
    
    def display_instances_table(self, instances):
        """Display EC2 instances in a formatted table."""
        if not instances:
            console.print("[yellow]No EC2 instances found.[/yellow]")
            return
        
        table = Table(title="EC2 Instances")
        table.add_column("Instance ID", style="cyan")
        table.add_column("Name", style="green")
        table.add_column("Public IP", style="yellow")
        table.add_column("State", style="blue")
        
        for instance in instances:
            state_color = "green" if instance['state'] == 'running' else "red"
            table.add_row(
                instance['id'],
                instance['name'],
                instance['public_ip'],
                f"[{state_color}]{instance['state']}[/{state_color}]"
            )
        
        console.print(table)
    
    def get_ssh_hosts(self):
        """Get all SSH hosts from the config file."""
        if not self.ssh_config_path.exists():
            console.print(f"[red]SSH config file not found at {self.ssh_config_path}[/red]")
            return []
        
        hosts = []
        try:
            with open(self.ssh_config_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('Host ') and not line.startswith('Host *'):
                        host = line.replace('Host ', '').strip()
                        hosts.append(host)
        except Exception as e:
            console.print(f"[red]Error reading SSH config: {e}[/red]")
        
        return hosts
    
    def backup_ssh_config(self):
        """Create a backup of the SSH config file."""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_path = f"{self.ssh_config_path}.backup.{timestamp}"
        
        try:
            import shutil
            shutil.copy2(self.ssh_config_path, backup_path)
            console.print(f"[green]Backup created: {backup_path}[/green]")
            return backup_path
        except Exception as e:
            console.print(f"[red]Failed to create backup: {e}[/red]")
            return None
    
    def update_ssh_host(self, host, new_ip):
        """Update the HostName for a specific SSH host."""
        if not self.ssh_config_path.exists():
            console.print(f"[red]SSH config file not found[/red]")
            return False
        
        # Create backup first
        backup_path = self.backup_ssh_config()
        if not backup_path:
            return False
        
        try:
            # Read the config file
            with open(self.ssh_config_path, 'r') as f:
                lines = f.readlines()
            
            # Find and update the host entry
            in_host_block = False
            updated = False
            
            for i, line in enumerate(lines):
                stripped = line.strip()
                
                if stripped.startswith('Host '):
                    current_host = stripped.replace('Host ', '').strip()
                    in_host_block = (current_host == host)
                elif in_host_block and stripped.startswith('HostName '):
                    # Update the HostName line
                    lines[i] = f"    HostName {new_ip}\n"
                    updated = True
                    in_host_block = False
                elif stripped.startswith('Host ') and in_host_block:
                    # We've moved to a new host block
                    in_host_block = False
            
            if updated:
                # Write back to file
                with open(self.ssh_config_path, 'w') as f:
                    f.writelines(lines)
                console.print(f"[green]Successfully updated SSH host '{host}' to IP {new_ip}[/green]")
                return True
            else:
                console.print(f"[red]Could not find HostName entry for host '{host}'[/red]")
                return False
                
        except Exception as e:
            console.print(f"[red]Failed to update SSH config: {e}[/red]")
            return False
    
    def update_security_groups(self, ip_address=None):
        """Update AWS security groups with the current IP."""
        if not ip_address:
            ip_address = self.get_public_ip()
            if not ip_address:
                return False
        
        console.print(f"[yellow]This will update the following security group rules:[/yellow]")
        for rule_id in self.security_group_rules:
            console.print(f"  - {rule_id}")
        console.print(f"[yellow]With IP: {ip_address}/32[/yellow]")
        
        # Safety confirmation
        confirm = inquirer.confirm(
            "Are you sure you want to update these security group rules?",
            default=False
        )
        
        if not confirm:
            console.print("[yellow]Security group update cancelled.[/yellow]")
            return False
        
        console.print(f"[blue]Updating security groups with IP: {ip_address}[/blue]")
        
        for rule_id in self.security_group_rules:
            # Get the security group ID for this rule
            get_group_cmd = f"aws ec2 describe-security-group-rules --filter 'Name=security-group-rule-id,Values={rule_id}' --query 'SecurityGroupRules[0].GroupId' --output text"
            group_id = self.run_aws_command(get_group_cmd)
            
            if not group_id or group_id.strip() == 'None':
                console.print(f"[red]Failed to get group ID for rule {rule_id}[/red]")
                continue
            
            group_id = group_id.strip()
            
            # Update the security group rule
            json_rule = {
                "SecurityGroupRuleId": rule_id,
                "SecurityGroupRule": {
                    "CidrIpv4": f"{ip_address}/32",
                    "IpProtocol": "-1",
                    "Description": "Jaak-Remote"
                }
            }
            
            update_cmd = f"aws ec2 modify-security-group-rules --group-id {group_id} --security-group-rules '{json.dumps([json_rule])}'"
            
            result = self.run_aws_command(update_cmd)
            if result is not None:
                console.print(f"[green]✓ Updated security group rule {rule_id}[/green]")
            else:
                console.print(f"[red]✗ Failed to update security group rule {rule_id}[/red]")
        
        return True
    
    def create_ssh_tunnel(self, ssh_host, local_port=24180, remote_port=80):
        """Create an SSH tunnel to the specified host."""
        console.print(f"[blue]Creating SSH tunnel: localhost:{local_port} -> {ssh_host}:{remote_port}[/blue]")
        
        # Check if SSH host exists in config
        hosts = self.get_ssh_hosts()
        if ssh_host not in hosts:
            console.print(f"[red]SSH host '{ssh_host}' not found in SSH config[/red]")
            return False
        
        try:
            # Build SSH command
            ssh_cmd = f"ssh -L {local_port}:localhost:{remote_port} {ssh_host}"
            console.print(f"[yellow]Running: {ssh_cmd}[/yellow]")
            console.print("[blue]Press Ctrl+C to close the tunnel[/blue]")
            
            # Execute SSH tunnel (this will block until user interrupts)
            subprocess.run(ssh_cmd, shell=True)
            
        except KeyboardInterrupt:
            console.print("\n[green]SSH tunnel closed[/green]")
        except Exception as e:
            console.print(f"[red]Failed to create SSH tunnel: {e}[/red]")
            return False
        
        return True

def welcome_message():
    """Display welcome message."""
    welcome_text = Text("SSH Config Management Tool", style="bold blue")
    console.print(Panel(welcome_text, expand=False, border_style="blue"))
    console.print("\nManage SSH configurations, EC2 instances, and security groups.\n")

def main():
    """Main CLI function."""
    # Initialize logging
    logger = setup_logging()
    logger.info("Starting SSH Config Management CLI")
    
    ssh_manager = SSHConfigManager()
    
    try:
        welcome_message()
        
        # Main menu
        main_menu = [
            inquirer.List(
                'action',
                message="What would you like to do?",
                choices=[
                    'List EC2 Instances',
                    'Update SSH Config with EC2 IP',
                    'Update Security Groups with Current IP',
                    'Create SSH Tunnel',
                    'Show SSH Hosts',
                    'Exit'
                ],
            ),
        ]
        
        while True:
            answers = inquirer.prompt(main_menu)
            if not answers or answers['action'] == 'Exit':
                break
            
            action = answers['action']
            
            if action == 'List EC2 Instances':
                instances = ssh_manager.list_ec2_instances()
                ssh_manager.display_instances_table(instances)
                
            elif action == 'Update SSH Config with EC2 IP':
                # Get EC2 instances
                instances = ssh_manager.list_ec2_instances()
                if not instances:
                    continue
                
                # Let user select an instance
                running_instances = [inst for inst in instances if inst['state'] == 'running' and inst['public_ip'] != 'N/A']
                if not running_instances:
                    console.print("[yellow]No running instances with public IPs found[/yellow]")
                    continue
                
                instance_choices = [f"{inst['id']} ({inst['name']}) - {inst['public_ip']}" for inst in running_instances]
                
                instance_q = inquirer.List(
                    'instance',
                    message="Select an EC2 instance:",
                    choices=instance_choices
                )
                
                instance_answer = inquirer.prompt([instance_q])
                if not instance_answer:
                    continue
                
                # Extract instance ID and IP
                selected = instance_answer['instance']
                instance_id = selected.split(' ')[0]
                selected_instance = next(inst for inst in running_instances if inst['id'] == instance_id)
                
                # Get SSH hosts
                ssh_hosts = ssh_manager.get_ssh_hosts()
                if not ssh_hosts:
                    console.print("[yellow]No SSH hosts found in config[/yellow]")
                    continue
                
                # Let user select SSH host to update
                host_q = inquirer.List(
                    'ssh_host',
                    message="Select SSH host to update:",
                    choices=ssh_hosts
                )
                
                host_answer = inquirer.prompt([host_q])
                if not host_answer:
                    continue
                
                # Update the SSH config
                ssh_manager.update_ssh_host(host_answer['ssh_host'], selected_instance['public_ip'])
                
            elif action == 'Update Security Groups with Current IP':
                ssh_manager.update_security_groups()
                
            elif action == 'Create SSH Tunnel':
                ssh_hosts = ssh_manager.get_ssh_hosts()
                if not ssh_hosts:
                    console.print("[yellow]No SSH hosts found in config[/yellow]")
                    continue
                
                # Select SSH host
                host_q = inquirer.List(
                    'ssh_host',
                    message="Select SSH host for tunnel:",
                    choices=ssh_hosts
                )
                
                # Get port configuration
                port_questions = [
                    host_q,
                    inquirer.Text('local_port', message="Local port", default="24180"),
                    inquirer.Text('remote_port', message="Remote port", default="80"),
                ]
                
                tunnel_answers = inquirer.prompt(port_questions)
                if not tunnel_answers:
                    continue
                
                # First update security groups
                console.print("[blue]Updating security groups first...[/blue]")
                ssh_manager.update_security_groups()
                
                # Create tunnel
                ssh_manager.create_ssh_tunnel(
                    tunnel_answers['ssh_host'],
                    int(tunnel_answers['local_port']),
                    int(tunnel_answers['remote_port'])
                )
                
            elif action == 'Show SSH Hosts':
                hosts = ssh_manager.get_ssh_hosts()
                if hosts:
                    table = Table(title="SSH Hosts")
                    table.add_column("Host Name", style="cyan")
                    for host in hosts:
                        table.add_row(host)
                    console.print(table)
                else:
                    console.print("[yellow]No SSH hosts found[/yellow]")
            
            console.print()  # Add spacing
        
        console.print("[bold cyan]Thank you for using the SSH Config Management Tool![/bold cyan]")
        
    except KeyboardInterrupt:
        console.print("\n\n[red]Operation cancelled by user.[/red]")
    except Exception as e:
        console.print(f"\n[red]An error occurred: {e}[/red]")

if __name__ == "__main__":
    main()
