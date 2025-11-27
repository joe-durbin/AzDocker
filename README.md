# AzDocker - Azure Pentesting Toolkit

A comprehensive Docker-based environment for Azure Active Directory (Azure AD) and Microsoft 365 security testing, enumeration, and attack simulation. This containerized toolkit provides a ready-to-use environment with all necessary tools for cloud security assessments.

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB RAM (8GB recommended)
- 10GB+ free disk space

### Installation

1. Clone or download this repository
2. Ensure `config_files/starship.toml` is present (it should be included in the repository)
3. Make the setup script executable:

```bash
chmod +x azpentest.sh
```

4. Run the setup script to install and start all services:

```bash
./azpentest.sh start
```

This script will:
- Check for and install BloodHound CLI if needed
- Install BloodHound Community Edition in a `bloodhound/` subdirectory 
- Start BloodHound services
- Build and start the cloud-tools container
- Display access credentials and usage instructions

**Note:** BloodHound is installed in the `bloodhound/` subdirectory to keep it separate from the main project files. All BloodHound CLI commands should be run from within that directory.

### Script Commands

The `azpentest.sh` script provides several commands for managing the environment:

```bash
./azpentest.sh start    # Install and start all services (BloodHound + cloud-tools)
./azpentest.sh stop     # Stop all services
./azpentest.sh purge    # Stop and remove all containers, images, volumes, and data
./azpentest.sh          # Show help screen
```

**Warning:** The `purge` command will remove all containers, images, volumes, networks, and the `bloodhound/` and `data/` directories. This action cannot be undone!

For manual BloodHound installation, see the [BloodHound Community Edition Quickstart](https://bloodhound.specterops.io/get-started/quickstart/community-edition-quickstart).

### Usage

After running `./azpentest.sh start`, you can access the cloud-tools container:

```bash
docker exec -it cloud-tools bash
```

The container runs as the non-root user `pentest` with all tools pre-configured and ready to use.

**Alternative:** If you prefer to manage containers manually, you can use docker-compose directly:

```bash
docker-compose up -d --build
```

## 📦 Available Tools

### Command-Line Tools (pipx)

These tools are installed via `pipx` and available globally in your PATH:

| Tool | Description |
|------|-------------|
| **azure-cli** | Official Microsoft Azure command-line interface for managing Azure resources |
| **graphspy** | Microsoft Graph API enumeration and reconnaissance tool |
| **ROADtools** | Azure AD reconnaissance and attack framework |
| **FindMeAccess** | Tool to find accessible resources in Azure AD |
| **impacket** | Collection of Python classes for working with network protocols |
| **seamlesspass** | Password spraying and credential testing tool |
| **roadtx** | ROADtools extension for token exchange and manipulation |
| **prowler** | Cloud security tool for AWS, Azure, and GCP security assessment |
| **scoutsuite** | Multi-cloud security auditing tool for AWS, Azure, and GCP |

### PowerShell Modules

Pre-installed PowerShell modules (import manually when needed):

| Module | Description |
|--------|-------------|
| **AADInternals** | PowerShell module for Azure AD and Microsoft 365 security testing |
| **Az** | Comprehensive Azure PowerShell module for resource management |
| **Microsoft.Graph** | PowerShell module for Microsoft Graph API interactions |

**Note**: All PowerShell modules are installed but not auto-loaded to improve PowerShell startup time. Import them manually when needed:

```powershell
Import-Module AADInternals
Import-Module Az
Import-Module Microsoft.Graph
```

### Python Tools

Located in `/opt/pentest-azure/`:

| Tool | Description |
|------|-------------|
| **AADInternals** | PowerShell-based toolkit for Azure AD and Microsoft 365 security testing |
| **GraphRunner** | Automated tool for running Microsoft Graph API queries |
| **TokenTacticsV2** | Token manipulation and abuse toolkit for Azure AD |
| **MFASweep** | Multi-factor authentication (MFA) bypass and testing tool |
| **username-anarchy** | Username enumeration and generation tool |
| **AzSubEnum** | Azure subscription enumeration tool |
| **basicblobfinder** | Tool for discovering publicly accessible Azure Blob Storage containers |
| **o365enum** | Office 365 user enumeration tool |
| **o365spray** | Office 365 password spraying tool |
| **Omnispray** | Multi-protocol password spraying tool |
| **Oh365UserFinder** | Office 365 user discovery and enumeration tool |
| **MSOLSpray** | Microsoft Online Services password spraying tool |
| **Graphpython** | Python library for Microsoft Graph API interactions |
| **exfil_exchange_mail.py** | Exchange Online mail exfiltration script |

### Ruby Tools

| Tool | Description |
|------|-------------|
| **evil-winrm** | Windows Remote Management (WinRM) shell for penetration testing |

## 🗂️ Project Structure

```
.
├── Dockerfile              # Main container definition
├── docker-compose.yml      # Multi-container orchestration
├── config_files/           # Configuration files directory
│   └── starship.toml      # Starship prompt configuration
├── azpentest.sh           # Setup and management script
├── README.md              # This file
├── data/                  # Persistent data directory (created on first run)
└── bloodhound/            # BloodHound CE installation directory (created by azpentest.sh)
```

## 🛠️ Tool Locations

- **pipx tools**: `/opt/pipx/bin/` (in PATH)
- **Python tools**: `/opt/pentest-azure/`
- **PowerShell modules**: Installed system-wide, import manually when needed
- **Ruby gems**: Available via `gem` command
- **User home**: `/home/pentest/`

## 💡 Features

- **Non-root execution**: Container runs as `pentest` user for security
- **Enhanced shell**: Starship prompt with git integration and helpful aliases
- **Bash completion**: Enabled for Azure CLI and other tools
- **Persistent storage**: Data directories mounted for tool outputs
- **Pre-configured**: All tools ready to use immediately
- **Integrated management**: Single script manages both BloodHound CE and cloud-tools container

## 📝 Usage Examples

### Azure CLI

```bash
az login
az account list
az ad user list
```

### PowerShell Modules

```bash
pwsh
# All modules must be imported manually when needed:
Import-Module AADInternals
Get-AADIntAccessToken

Import-Module Az
Get-AzContext

Import-Module Microsoft.Graph
Get-MgUser
```

### Python Tools

```bash
cd /opt/pentest-azure/TokenTacticsV2
python3 token_tactics.py --help
```

## 🔧 Customization

### Adding Tools

To add additional tools, modify the `Dockerfile`:

1. For pipx tools: Add to the pipx installation section
2. For Python tools: Add git clone commands to the repository section
3. For PowerShell modules: Add to the PowerShell module installation section

### Modifying Shell Configuration

- Bash: Edit the `.bashrc` section in the Dockerfile
- Starship: Edit `config_files/starship.toml` and rebuild the container

**Note:** PowerShell modules are not auto-loaded. Import them manually in your PowerShell sessions as needed.

## 🐛 Troubleshooting

### Container won't start

- Check Docker logs: `docker-compose logs cloud-tools`
- Verify Docker has sufficient resources allocated
- Ensure ports 8080, 7474, and 7687 are not in use (if using BloodHound)
- Try rebuilding: `docker-compose build cloud-tools`

### Script issues

- Ensure the script is executable: `chmod +x azpentest.sh`
- Check Docker is running: `docker info`
- Verify you're in the project root directory

### Tools not found

- Verify PATH: `echo $PATH`
- Check pipx installation: `pipx list`
- Ensure you're in the correct directory for Python tools
- Restart the container: `docker-compose restart cloud-tools`

### BloodHound access issues

- Check if services are running: `./bloodhound/bloodhound-cli status`
- Verify the password: `./bloodhound/bloodhound-cli config get default_password`
- Check container logs: `docker logs <container-name>`

## 📚 Additional Resources

- [Azure AD Security Best Practices](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/security-best-practices)
- [ROADtools Documentation](https://github.com/dirkjanm/ROADtools)

## ⚠️ Disclaimer

This toolkit is designed for authorized security testing and educational purposes only. Only use these tools on systems and networks you own or have explicit written permission to test. Unauthorized access to computer systems is illegal.

## 📄 License

This project includes tools from various sources, each with their own licenses. Please refer to individual tool repositories for licensing information.

## 🤝 Contributing

Contributions are welcome! Please ensure any added tools are:
- Relevant to Azure AD/Microsoft 365 security testing
- Actively maintained
- Compatible with the containerized environment

---

**Note**: This environment uses the latest versions of all tools. For production use, consider pinning specific versions to ensure stability and reproducibility.

