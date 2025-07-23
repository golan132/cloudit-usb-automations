# CloudIT USB Automations

This project automates the creation of a customized Windows installation ISO with an unattended setup file. The main goal is to structure the project modularly so that each part of the Windows unattended installation process is managed separately, and the entire workflow is automated by scripts.

## Project Structure

```
cloudit-usb-automations/
├── unattended/           # Unattended installation configuration
│   ├── passes/          # XML fragments for different setup phases
│   ├── scripts/         # Post-installation scripts
│   ├── templates/       # Main XML wrapper template
│   ├── build/          # Generated autounattend.xml output
│   ├── merge.js        # Script to assemble XML parts
│   └── README.md       # Unattended setup documentation
│
├── iso/                # Windows ISO management
│   ├── source/         # Original Windows ISO files
│   ├── extracted/      # Extracted ISO contents for modification
│   └── result/         # Final customized ISO files
│
├── scripts/            # PowerShell automation scripts
│   ├── extract-iso.ps1      # Extract ISO contents
│   ├── inject-autounattend.ps1  # Inject unattended file
│   └── build-iso.ps1        # Rebuild customized ISO
│
├── run.ps1             # Main orchestration script
└── README.md           # This file
```

## Prerequisites

- **Windows 10/11** with PowerShell 5.0 or higher
- **Administrator privileges** (required for ISO manipulation)
- **Node.js** (for running the XML merge script)
- **Windows ADK** (Assessment and Deployment Kit) - for building ISO files
  - Download from: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install

## Quick Start

### 1. Setup
1. Clone or download this project
2. Place your Windows ISO file in the `iso/source/` directory
3. Open PowerShell as Administrator
4. Navigate to the project directory

### 2. Run the Automation
```powershell
# Run the complete process
.\run.ps1

# Or specify a custom ISO path
.\run.ps1 -IsoPath "C:\path\to\your\windows.iso"

# Or specify a custom output path
.\run.ps1 -OutputPath "C:\output\CustomWindows.iso"
```

### 3. Advanced Usage
```powershell
# Clean working directories only
.\run.ps1 -CleanOnly

# Skip ISO extraction (use existing extracted files)
.\run.ps1 -SkipExtraction

# Skip ISO building (stop after injection)
.\run.ps1 -SkipBuild

# Show help
.\run.ps1 -Help
```

## How It Works

The automation process consists of several steps:

1. **XML Assembly** (`unattended/merge.js`)
   - Combines XML fragments from `unattended/passes/` 
   - Uses the template from `unattended/templates/`
   - Outputs complete `autounattend.xml` to `unattended/build/`

2. **ISO Extraction** (`scripts/extract-iso.ps1`)
   - Mounts the source Windows ISO
   - Copies all contents to `iso/extracted/`
   - Prepares for modification

3. **Unattended Injection** (`scripts/inject-autounattend.ps1`)
   - Copies `autounattend.xml` to the ISO root
   - Injects post-installation scripts into the ISO structure
   - Sets appropriate permissions

4. **ISO Building** (`scripts/build-iso.ps1`)
   - Uses `oscdimg.exe` from Windows ADK
   - Creates a bootable ISO with UEFI and BIOS support
   - Outputs the final customized ISO to `iso/result/`

## Customization

### Modifying Installation Passes
Edit the XML files in `unattended/passes/` to customize different phases:
- `windowspe.xml` - Pre-installation environment
- `specialize.xml` - System specialization 
- `oobesystem.xml` - Out-of-box experience and user setup

### Adding Post-Installation Scripts
Place PowerShell scripts in `unattended/scripts/` - they will be automatically copied to the ISO and can be executed during first logon.

### Changing User Account
The default setup creates a user account:
- **Username**: `cloudit`
- **Password**: `CloudIT` (Base64 encoded in XML)
- **Auto-login**: Enabled for first boot

Edit `unattended/passes/oobesystem.xml` to modify user account settings.

## Default Configuration

The project includes a pre-configured unattended setup that:

- **Disk Setup**: Automatically partitions and formats the disk
- **Language**: English (US) 
- **User Account**: Creates "cloudit" admin user with auto-login
- **OOBE**: Bypasses Windows out-of-box experience screens
- **Post-Install**: Runs setup script that installs essential software

## Testing

⚠️ **Always test the generated ISO in a virtual machine before using on physical hardware!**

Recommended testing workflow:
1. Create the customized ISO using this tool
2. Test in VMware, VirtualBox, or Hyper-V
3. Verify the automated installation works as expected
4. Create bootable USB using tools like Rufus
5. Deploy to physical hardware

## Troubleshooting

### Common Issues

**"oscdimg.exe not found"**
- Install Windows ADK (Assessment and Deployment Kit)
- Ensure the installation includes "Deployment Tools"

**"Node.js not found"**
- Install Node.js from https://nodejs.org/
- Or install via Chocolatey: `choco install nodejs`

**"Must be run as Administrator"**
- Right-click PowerShell and "Run as Administrator"
- ISO manipulation requires elevated privileges

**XML validation errors**
- Check syntax in `unattended/passes/*.xml` files
- Ensure all pass files have valid XML structure

### Log Files
- Build logs are displayed in the console
- Individual scripts may create temporary log files
- Post-installation logs are saved to `C:\Windows\Setup\Logs\cloudit-setup.log`

## Security Considerations

- The default user password is hardcoded and should be changed for production use
- Post-installation scripts run with administrator privileges
- Consider the security implications of auto-login and unattended installation
- Review and customize the included scripts for your security requirements

## Contributing

To contribute to this project:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is provided as-is for educational and automation purposes. Please ensure compliance with Microsoft licensing terms when using Windows installation media.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the logs for specific error messages
3. Ensure all prerequisites are properly installed
4. Test in a clean virtual machine environment 
