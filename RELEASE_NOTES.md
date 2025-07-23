feat: Initial release of CloudIT USB Automations

This release provides a complete automation system for creating customized Windows installation ISOs with unattended setup files.

## Features

### Core Automation
- **Modular XML System**: Separate configuration files for each Windows setup phase
- **Automated ISO Processing**: Mount, extract, modify, and rebuild Windows ISOs
- **Unattended Installation**: Complete hands-off Windows installation with custom settings
- **Post-Installation Scripts**: Automatic software installation and system configuration

### User Experience
- **One-Command Operation**: `.\run.ps1` handles the entire process
- **Administrator Privilege Handling**: Built-in elevation requests and validation
- **Comprehensive Error Handling**: Detailed logging and troubleshooting guidance
- **Multiple Execution Options**: Batch files, PowerShell, and command-line interfaces

### Technical Implementation
- **Cross-Platform PowerShell**: Compatible with PowerShell 5.0+ and PowerShell Core
- **Robust Path Detection**: Handles various script invocation methods
- **XML Validation**: Ensures configuration integrity before processing
- **ISO Integrity**: Maintains bootability for both UEFI and BIOS systems

### Documentation
- **Comprehensive README**: Complete installation and usage instructions
- **Prerequisites Guide**: Detailed software requirements and installation steps
- **Troubleshooting Section**: Solutions for common issues and errors
- **Example Scripts**: Practical usage demonstrations and validation tools

## Default Configuration
- Creates 'cloudit' administrator account with auto-login
- Installs essential software (Chrome, Notepad++, 7-Zip, VLC) via Chocolatey
- Configures Windows settings (disables OOBE, enables RDP, sets power options)
- Supports both Windows 10 and Windows 11 installations

## Requirements
- Windows 10/11 with PowerShell 5.0+
- Node.js (for XML processing)
- Windows ADK (for ISO building)
- Administrator privileges

This release establishes the foundation for automated Windows deployment workflows in enterprise and development environments.
