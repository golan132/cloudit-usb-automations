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

### System Requirements
- **Windows 10/11** with PowerShell 5.0 or higher
- **Administrator privileges** (required for ISO manipulation)
- **At least 10GB free disk space** (for ISO extraction and building)

### Required Software

#### 1. Node.js (Required)
**Purpose**: Used for merging XML configuration fragments into the final autounattend.xml

**Installation Options:**

**Option A - Direct Download:**
1. Go to https://nodejs.org/
2. Download the LTS version (recommended)
3. Run the installer as Administrator
4. Accept all default settings
5. Verify installation: Open Command Prompt and run `node --version`

**Option B - Using Chocolatey (if available):**
```powershell
# Run as Administrator
choco install nodejs -y
```

**Option C - Using Winget:**
```powershell
# Run as Administrator  
winget install OpenJS.NodeJS
```

#### 2. Windows ADK (Required for ISO Building)
**Purpose**: Provides `oscdimg.exe` tool needed to create bootable ISO files

**Installation:**
1. **Download**: Go to https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install
2. **Download the Windows ADK for Windows 11** (or latest version)
3. **Run installer as Administrator**
4. **Select components**: Make sure to check **"Deployment Tools"** - this includes oscdimg.exe
5. **Complete installation** (requires ~1GB space)
6. **Verify**: Look for oscdimg.exe in:
   - `C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\`

> **Note**: You can run the script without Windows ADK, but it will stop after injecting the unattended file. You can manually create bootable media from the `iso\extracted\` folder.

#### 3. Windows ISO File
**Purpose**: Source Windows installation media to customize

**Requirements:**
- Windows 10 or Windows 11 ISO file
- Minimum 4GB file size
- Downloaded from official Microsoft sources (recommended)

**Where to get:**
- **Windows 11**: https://www.microsoft.com/software-download/windows11
- **Windows 10**: https://www.microsoft.com/software-download/windows10
- **Volume Licensing**: Microsoft Volume Licensing Service Center (for business)

## Quick Start

### 1. Prerequisites Installation

**Before starting, install the required software:**

#### Install Node.js
```powershell
# Option 1: Download from https://nodejs.org/ and run installer as Admin
# Option 2: Using Chocolatey (if available)
choco install nodejs -y
# Option 3: Using Winget
winget install OpenJS.NodeJS
```

#### Install Windows ADK
1. Download from: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install
2. Run installer as **Administrator**
3. Select **"Deployment Tools"** component
4. Complete installation

#### Verify Prerequisites
Run this command to check if everything is installed:
```powershell
# Check Node.js
node --version

# Check Windows ADK
Test-Path "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
```

**Or use the built-in checker:**
```powershell
# Run the example script to check all prerequisites
.\example-usage.ps1
```

### 2. Project Setup
1. **Clone or download** this project to your computer
2. **Place your Windows ISO file** in the `iso/source/` directory
   ```powershell
   # Example: Copy your Windows ISO
   Copy-Item "C:\Downloads\Windows11.iso" "C:\path\to\cloudit-usb-automations\iso\source\"
   ```

### 3. Running the Script

#### Method 1: Using Batch File (Easiest)
1. **Double-click** `run-admin.bat` in the project folder
2. The script will automatically request Administrator privileges
3. Follow the on-screen prompts

#### Method 2: PowerShell (Recommended)
1. **Right-click** on **PowerShell** in Start Menu
2. Select **"Run as administrator"**
3. Navigate to project directory:
   ```powershell
   cd "C:\path\to\cloudit-usb-automations"
   ```
4. Run the main script:
   ```powershell
   .\run.ps1
   ```

#### Method 3: Command Prompt
1. **Right-click** on **Command Prompt** in Start Menu  
2. Select **"Run as administrator"**
3. Navigate and run:
   ```cmd
   cd "C:\path\to\cloudit-usb-automations"
   powershell -ExecutionPolicy Bypass -File ".\run.ps1"
   ```

### 4. Script Options
```powershell
# Run the complete process
.\run.ps1

# Or specify a custom ISO path
.\run.ps1 -IsoPath "C:\path\to\your\windows.iso"

# Or specify a custom output path
.\run.ps1 -OutputPath "C:\output\CustomWindows.iso"
```

### 4. Script Options

**Basic Usage:**
```powershell
# Run the complete automation process
.\run.ps1

# Use a specific ISO file (if not in iso/source/)
.\run.ps1 -IsoPath "C:\path\to\your\windows.iso"

# Specify custom output location
.\run.ps1 -OutputPath "C:\CustomISOs\MyWindows.iso"
```

**Advanced Options:**
**Advanced Options:**
```powershell
# Clean working directories only
.\run.ps1 -CleanOnly

# Skip ISO extraction (use existing extracted files)
.\run.ps1 -SkipExtraction

# Skip ISO building (stop after injection)
.\run.ps1 -SkipBuild

# Show help and all available options
.\run.ps1 -Help

# Enable verbose output for troubleshooting
.\run.ps1 -Verbose
```

### 5. What Happens During Execution

The script will automatically:

1. **✅ Check Prerequisites**: Verify Node.js, Windows ADK, and admin privileges
2. **✅ Build Configuration**: Merge XML fragments into `autounattend.xml`
3. **✅ Extract ISO**: Mount and copy your Windows ISO contents
4. **✅ Inject Automation**: Add unattended file and post-install scripts
5. **✅ Build New ISO**: Create your customized Windows ISO (if ADK is installed)

**Expected Output:**
```
= CloudIT Windows ISO Automation =
[2025-07-23 17:22:26] [SUCCESS] Running as Administrator: OK
[2025-07-23 17:22:26] [SUCCESS] Node.js version: v20.19.0
[2025-07-23 17:22:26] [SUCCESS] Found ISO file: Win11_24H2_English_x64.iso
[2025-07-23 17:22:32] [SUCCESS] ISO mounted successfully at: F:\
[2025-07-23 17:22:40] [SUCCESS] ISO extraction completed successfully!
[2025-07-23 17:22:40] [SUCCESS] autounattend.xml injection completed successfully!
[2025-07-23 17:22:45] [SUCCESS] ISO built successfully!
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

### Prerequisites Issues

**❌ "This script must be run as Administrator"**
- **Solution**: Right-click PowerShell and select "Run as administrator"
- **Alternative**: Use the `run-admin.bat` file which automatically requests admin privileges

**❌ "Node.js not found"**
- **Solution 1**: Install from https://nodejs.org/ (run installer as Admin)
- **Solution 2**: Using Chocolatey: `choco install nodejs -y`
- **Solution 3**: Using Winget: `winget install OpenJS.NodeJS`
- **Verify**: Run `node --version` in Command Prompt

**❌ "oscdimg.exe not found" / "Windows ADK not found"**
- **Solution**: Install Windows ADK from Microsoft
  1. Download: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install
  2. Run installer as Administrator
  3. **Important**: Select "Deployment Tools" component during installation
  4. Complete installation (requires ~1GB space)
- **Alternative**: Run script with `-SkipBuild` to create bootable USB manually

### Execution Issues

**❌ "Cannot bind argument to parameter 'Path' because it is null"**
- **Cause**: PowerShell execution policy or path detection issue
- **Solution**: Run with explicit execution policy:
  ```powershell
  powershell -ExecutionPolicy Bypass -File ".\run.ps1"
  ```

**❌ "No ISO files found in iso\source"**
- **Solution**: Place a Windows ISO file in the `iso\source\` directory
- **Example**: 
  ```powershell
  Copy-Item "C:\Downloads\Windows11.iso" ".\iso\source\"
  ```

**❌ "ISO file not found"**
- **Check**: Verify the ISO file exists and is not corrupted
- **Check**: Ensure the file has `.iso` extension
- **Solution**: Use `-IsoPath` parameter to specify exact location:
  ```powershell
  .\run.ps1 -IsoPath "C:\full\path\to\windows.iso"
  ```

**❌ "Error mounting ISO"**
- **Cause**: ISO file is corrupted or in use
- **Solution 1**: Close any programs that might be using the ISO
- **Solution 2**: Restart computer and try again
- **Solution 3**: Re-download the ISO file from Microsoft

**❌ "Robocopy completed with exit code"**
- **Cause**: Usually not an error - Robocopy exit codes 0-1 are success
- **Action**: Check if files were copied to `iso\extracted\` directory
- **If files missing**: Run script again or check disk space

### XML Configuration Issues

**❌ "XML validation errors"**
- **Check**: Syntax in `unattended\passes\*.xml` files
- **Solution**: Ensure all XML files have proper opening/closing tags
- **Reset**: Restore original XML files from repository

**❌ "Merge script failed"**
- **Check**: Node.js is properly installed
- **Solution**: Navigate to unattended folder and test manually:
  ```powershell
  cd unattended
  node merge.js
  ```

### Permission Issues

**❌ "Access denied" errors**
- **Cause**: Insufficient permissions or antivirus interference
- **Solution 1**: Run PowerShell as Administrator
- **Solution 2**: Temporarily disable real-time antivirus scanning
- **Solution 3**: Add project folder to antivirus exclusions

**❌ "ISO building fails with permissions"**
- **Cause**: Files in extracted folder are read-only
- **Solution**: Script should handle this automatically, but you can manually run:
  ```powershell
  Get-ChildItem ".\iso\extracted" -Recurse | ForEach-Object { $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly) }
  ```

### Performance Issues

**❌ "Script runs very slowly"**
- **Cause**: Large ISO files or slow disk
- **Normal**: Extracting 5GB+ ISO files takes 5-15 minutes
- **Tip**: Use SSD storage for better performance
- **Tip**: Close other programs to free up system resources

### Getting Help

**📋 Enable Verbose Logging:**
```powershell
.\run.ps1 -Verbose
```

**📋 Check Individual Components:**
```powershell
# Test XML merge only
cd unattended
node merge.js

# Test ISO extraction only  
.\scripts\extract-iso.ps1

# Test prerequisites
.\example-usage.ps1
```

**📋 Reset and Clean:**
```powershell
# Clean all working directories
.\run.ps1 -CleanOnly

# Or manually delete:
Remove-Item ".\iso\extracted\*" -Recurse -Force
Remove-Item ".\unattended\build\*" -Recurse -Force
```

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
