# Conventional Commit Message for Release-Please

## Short Version (for immediate commit):
```
feat: complete Windows ISO automation system with unattended installation

- Modular XML configuration for Windows setup phases  
- Automated ISO extraction, modification, and rebuilding
- PowerShell scripts with admin privilege handling
- Post-installation automation with software deployment
- Comprehensive documentation and troubleshooting guides
- Support for Windows 10/11 with UEFI/BIOS compatibility

BREAKING CHANGE: Initial release establishes new automation framework
```

## Detailed Version (for release notes):
This commit introduces a complete automation system for creating customized Windows installation ISOs. The system provides:

**Core Features:**
- Modular XML system for Windows unattended installation configuration
- Automated ISO processing (mount, extract, modify, rebuild)
- PowerShell-based automation with comprehensive error handling
- Built-in administrator privilege management
- Post-installation script injection for software deployment

**Technical Implementation:**
- Cross-platform PowerShell compatibility (5.0+ and Core)
- Robust path detection for various execution contexts
- XML validation and merge capabilities
- ISO integrity preservation for bootability
- Node.js integration for configuration processing

**User Experience:**
- One-command operation with `.\run.ps1`
- Multiple execution methods (batch, PowerShell, command-line)
- Comprehensive documentation and troubleshooting
- Example scripts and validation tools
- Clear prerequisite installation guidance

**Default Configuration:**
- Creates 'cloudit' admin user with auto-login
- Installs essential software via Chocolatey
- Configures Windows settings and services
- Supports both Windows 10 and 11 installations

This establishes the foundation for enterprise Windows deployment automation.
