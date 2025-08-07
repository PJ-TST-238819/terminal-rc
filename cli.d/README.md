# SSH Config Management CLI Tool

A comprehensive, interactive command-line tool for managing SSH configurations, EC2 instances, and AWS security groups. This tool consolidates the functionality of multiple bash scripts into a single, user-friendly interface with arrow key navigation, comprehensive logging, and safety features.

## 🚀 Overview

This CLI tool replaces and enhances several bash scripts that were used for:
- Listing EC2 instances
- Updating SSH configurations with dynamic EC2 IPs
- Managing AWS security group rules
- Creating SSH tunnels
- Managing remote access configurations

## ✨ Key Features

### Interactive Interface
- **Arrow Key Navigation**: Navigate menus using arrow keys and Enter to select
- **Rich Terminal Output**: Beautiful formatted tables, colored output, and progress indicators
- **Intuitive Workflow**: Step-by-step guided process for all operations

### AWS Integration
- **EC2 Instance Management**: List and select from running EC2 instances
- **Security Group Updates**: Safely update specific security group rules with current public IP
- **Dynamic IP Resolution**: Automatically detects and uses your current public IP address

### SSH Configuration Management
- **SSH Host Discovery**: Automatically reads and displays SSH hosts from `~/.ssh/config`
- **Configuration Updates**: Update SSH host entries with EC2 instance public IPs
- **Automatic Backups**: Creates timestamped backups before any SSH config changes

### SSH Tunneling
- **Interactive Tunnel Setup**: Create SSH tunnels with customizable local and remote ports
- **Integrated Security Updates**: Automatically updates security groups before creating tunnels
- **Flexible Port Configuration**: Configure any local/remote port combination

### Safety & Logging
- **Comprehensive Logging**: All actions, commands, and errors logged to `~/.ssh/cli_logs/`
- **Confirmation Prompts**: Required confirmation for any AWS resource modifications
- **Limited Scope**: Only modifies specific, predefined security group rules
- **Read-Only EC2**: Never modifies EC2 instances, only reads information

## 📋 Prerequisites

### Required Software
- **Python 3.11+**: The application runtime
- **AWS CLI**: Must be installed and configured with appropriate credentials
- **devbox**: For development environment management
- **SSH**: Standard SSH client for tunnel creation

### Required Configuration
- **AWS Credentials**: Properly configured AWS CLI with permissions for:
  - `ec2:DescribeInstances`
  - `ec2:DescribeSecurityGroupRules`
  - `ec2:ModifySecurityGroupRules`
- **SSH Config**: Existing SSH configuration file at `~/.ssh/config`
- **Internet Access**: Required for public IP detection and AWS API calls

## 🛠️ Installation & Setup

### 1. Clone and Setup Repository
```bash
# Clone the repository
git clone <repository-url>
cd cli.d

# Initialize devbox environment
devbox shell
```

### 2. Verify Prerequisites
```bash
# Verify AWS CLI is configured
aws sts get-caller-identity

# Verify SSH config exists
ls -la ~/.ssh/config

# Test internet connectivity
curl -s http://checkip.amazonaws.com
```

### 3. Install Dependencies
```bash
# Inside devbox shell
devbox run install
```

### 4. Configure Security Group Rules (Optional)
By default, the tool is configured with specific security group rule IDs. To customize:

```python
# Edit src/cli_d/main.py
self.security_group_rules = [
    "sgr-your-rule-id-1", 
    "sgr-your-rule-id-2"
]
```

## 🎯 Usage Guide

### Running the Application

#### Using the Shell Script (Recommended)
```bash
# Interactive mode
./ssh-cli

# With debug logging to console
./ssh-cli --debug

# Headless mode examples
./ssh-cli --list-instances
./ssh-cli --update-security-groups --force
./ssh-cli --show-ssh-hosts --json-output
```

#### Direct Python Execution
```bash
# Standard run
devbox run run "python src/cli_d/main.py"

# With debug logging to console
SSH_CLI_DEBUG=1 devbox run run "python src/cli_d/main.py"
```

#### User Installation (Recommended)
```bash
# Install to ~/.local/bin for user access
./install.sh

# Now you can run from anywhere (if ~/.local/bin is in PATH)
ssh-cli --help
ssh-cli --list-instances

# Uninstall when no longer needed
./install.sh --uninstall
```

### Main Menu Options

The application presents an interactive menu with the following options:

#### 1. 📊 List EC2 Instances
**Purpose**: View all EC2 instances in your AWS account

**Output**:
- Formatted table with Instance ID, Name, Public IP, and State
- Color-coded status indicators (green=running, red=stopped)
- Includes instances from all regions configured in AWS CLI

**Use Cases**:
- Check instance status before SSH configuration updates
- Identify running instances for tunnel creation
- Monitor infrastructure state

#### 2. 🔧 Update SSH Config with EC2 IP
**Purpose**: Update SSH host configurations with current EC2 instance public IPs

**Workflow**:
1. Fetches all EC2 instances
2. Filters to show only running instances with public IPs
3. Prompts for instance selection
4. Shows available SSH hosts from `~/.ssh/config`
5. Creates backup of SSH config
6. Updates selected host with new IP address

**Safety Features**:
- Automatic backup creation with timestamp
- Validation of instance state and IP availability
- Verification of SSH host existence

**Example**:
```
[Before] Host myserver
         HostName 1.2.3.4

[After]  Host myserver
         HostName 5.6.7.8  # Updated with current EC2 IP
```

#### 3. 🛡️ Update Security Groups with Current IP
**Purpose**: Update AWS security group rules to allow access from your current public IP

**Workflow**:
1. Detects current public IP via http://checkip.amazonaws.com
2. Shows security group rules that will be updated
3. Requires explicit user confirmation
4. Updates each configured security group rule
5. Reports success/failure for each rule

**Security Features**:
- Only updates predefined security group rules
- Requires explicit confirmation before any changes
- Comprehensive logging of all changes
- Clear indication of which rules will be modified

**Configuration**:
- Updates specific rule IDs: `sgr-029111b2b23cd6114`, `sgr-0a6a82e6a59e3f1c2`
- Sets CIDR to `<your-ip>/32` for precise access control
- Adds description: "Jaak-Remote"

#### 4. 🔗 Create SSH Tunnel
**Purpose**: Establish SSH tunnels for secure access to remote services

**Workflow**:
1. Shows available SSH hosts from configuration
2. Prompts for host selection
3. Configures local and remote ports (defaults: 24180 → 80)
4. Automatically updates security groups first
5. Creates SSH tunnel using standard SSH client

**Features**:
- Customizable port forwarding
- Integrated security group updates
- Real-time tunnel status
- Clean shutdown with Ctrl+C

**Example Usage**:
```bash
# Creates tunnel: localhost:24180 -> remote_host:80
# Accessible via http://localhost:24180
```

#### 5. 📋 Show SSH Hosts
**Purpose**: Display all SSH hosts configured in `~/.ssh/config`

**Output**:
- Clean table listing all configured SSH hosts
- Excludes wildcard entries (Host *)
- Quick reference for available connection targets

## 📊 Logging & Monitoring

### Log File Location
Logs are stored in: `~/.ssh/cli_logs/ssh_cli_YYYYMMDD.log`

### Log Content
- **Application Startup**: Python version, user, working directory
- **AWS Commands**: All AWS CLI commands executed and their responses
- **SSH Operations**: Config file reads, backups, and modifications
- **Security Group Changes**: All security group rule updates
- **Network Requests**: Public IP detection and HTTP requests
- **User Actions**: Menu selections and user input
- **Errors & Exceptions**: Detailed error information with stack traces

### Debug Mode
Enable verbose console output:
```bash
export SSH_CLI_DEBUG=1
python src/cli_d/main.py
```

### Log Rotation
Logs are automatically rotated daily. Each day creates a new log file.

## 🏗️ Development

### Architecture

```
├── SSH Config Management CLI
│   ├── SSHConfigManager Class
│   │   ├── EC2 Instance Management
│   │   ├── SSH Configuration Handling
│   │   ├── Security Group Management
│   │   └── SSH Tunnel Creation
│   ├── Logging System
│   ├── Interactive CLI (inquirer)
│   └── Rich Terminal Output
```

### Technology Stack

- **Runtime**: Python 3.11+
- **Environment**: devbox for reproducible development
- **Package Manager**: UV for fast dependency management
- **CLI Framework**: inquirer for interactive prompts
- **Output Formatting**: rich for beautiful terminal output
- **HTTP Requests**: requests for public IP detection
- **AWS Integration**: AWS CLI via subprocess
- **Logging**: Python standard logging module

### Project Structure
```
cli.d/
├── src/cli_d/
│   ├── __init__.py              # Package initialization
│   └── main.py                  # Main application logic
├── devbox.json                  # Devbox configuration
├── pyproject.toml               # Python package configuration
├── ssh-cli                      # Executable shell script launcher
├── install.sh                   # System-wide installation script
├── README.md                    # This documentation
└── .venv/                       # Virtual environment (auto-created)
```

### Shell Scripts

#### `ssh-cli` - Main Launcher Script
A convenient executable wrapper that:
- Handles devbox environment setup automatically
- Provides colored output and status messages
- Supports all CLI flags and options
- Includes built-in help and version information
- Enables debug mode with `--debug` flag

**Features**:
- Auto-detects if running in devbox environment
- Automatically enters devbox if needed
- Passes all arguments to the Python CLI
- Provides clear error messages and status updates

#### `install.sh` - User Installation Script
Automated installation script that:
- Sets up the project in the current directory
- Creates user bin directory symlinks for easy access
- Supports custom installation directories  
- Provides uninstallation capability
- Validates prerequisites and manages dependencies
- Tests installation after completion
- Helps configure PATH if needed

**Features**:
- Installs to `~/.local/bin` by default (user-specific)
- Automatically sets up devbox environment and dependencies
- Provides PATH configuration guidance
- No sudo required for default installation
- Creates symlinks pointing to the current directory

**Usage Examples**:
```bash
# Install to ~/.local/bin (default)
./install.sh

# Install to custom directory
./install.sh --install-dir ~/bin

# Install with custom command name
./install.sh --name my-ssh-tool

# Uninstall
./install.sh --uninstall
```

### Development Commands

```bash
# Environment setup
devbox shell                     # Enter development environment
devbox run install               # Install/sync dependencies

# Running the application
devbox run run "python src/cli_d/main.py"  # Standard execution
SSH_CLI_DEBUG=1 devbox run run "python src/cli_d/main.py"  # Debug mode

# Code quality
devbox run lint                  # Run linting (ruff)
devbox run format                # Format code (ruff)
devbox run test                  # Run tests (when available)

# Package management
devbox run add <package>         # Add new dependency
uv sync                          # Sync dependencies
uv build                         # Build package
```

### Adding New Features

1. **New Menu Option**: Add to main menu choices and implement handler
2. **New SSH Operation**: Add method to SSHConfigManager class
3. **New AWS Integration**: Extend run_aws_command usage
4. **Logging**: Use self.logger for all new operations

## 🔒 Security Considerations

### AWS Permissions
The application requires minimal AWS permissions:
- `ec2:DescribeInstances` - Read EC2 instance information
- `ec2:DescribeSecurityGroupRules` - Read security group configurations
- `ec2:ModifySecurityGroupRules` - Update specific security group rules

### Security Group Updates
- **Limited Scope**: Only updates predefined security group rule IDs
- **Explicit Confirmation**: Always requires user confirmation
- **Audit Trail**: All changes logged with timestamps
- **Precise CIDR**: Uses /32 CIDR for single IP access

### SSH Configuration
- **Automatic Backups**: SSH config backed up before any changes
- **Read-Only Discovery**: SSH hosts discovered by reading config file
- **No Key Modification**: Never modifies SSH keys or key-related settings

### Data Handling
- **No Persistent Storage**: No sensitive data stored permanently
- **Local Logging**: All logs stored locally in user directory
- **No Network Transmission**: Sensitive data never transmitted except via AWS API

## 🐛 Troubleshooting

### Common Issues

#### AWS CLI Not Configured
```bash
# Error: Unable to locate credentials
# Solution:
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_DEFAULT_REGION=us-east-1
```

#### SSH Config Not Found
```bash
# Error: SSH config file not found
# Solution:
mkdir -p ~/.ssh
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

#### Security Group Access Denied
```bash
# Error: User is not authorized to perform: ec2:ModifySecurityGroupRules
# Solution: Add required IAM permissions or update security group rule IDs
```

#### Public IP Detection Failure
```bash
# Error: Error getting public IP
# Solution: Check internet connectivity or use manual IP:
ping checkip.amazonaws.com
```

### Debug Mode
Enable debug mode for detailed troubleshooting:
```bash
SSH_CLI_DEBUG=1 python src/cli_d/main.py
```

### Log Analysis
Check logs for detailed error information:
```bash
tail -f ~/.ssh/cli_logs/ssh_cli_$(date +%Y%m%d).log
```

## 📈 Migration from Bash Scripts

This CLI tool replaces the following bash scripts:

| Bash Script | CLI Function | Enhancement |
|-------------|-------------|-------------|
| `update-ssh-config.sh` | Update SSH Config with EC2 IP | Interactive selection, automatic backups |
| `list-ec2-instances.sh` | List EC2 Instances | Formatted table, color-coded status |
| `osg.sh` | Update Security Groups | Confirmation prompts, better error handling |
| `open-manticore-tunnels.sh` | Create SSH Tunnel | Integrated security updates, custom ports |

### Migration Benefits
- **Single Interface**: All functionality in one tool
- **Better UX**: Interactive prompts vs command-line arguments
- **Safety Features**: Confirmations and backups
- **Comprehensive Logging**: Full audit trail
- **Error Handling**: Graceful error recovery and reporting

## 🤝 Contributing

This tool was created to consolidate and enhance multiple bash scripts used for SSH and AWS management. It provides a safer, more user-friendly interface while maintaining all original functionality.

### Contribution Guidelines
1. Maintain backward compatibility with existing workflows
2. Add comprehensive logging for all new features
3. Include safety confirmations for destructive operations
4. Follow existing code style and patterns
5. Update documentation for any new features

### Future Enhancements
- Configuration file support for custom security group rules
- Support for multiple AWS profiles
- SSH key management features
- Batch operations for multiple instances
- Integration with other cloud providers
