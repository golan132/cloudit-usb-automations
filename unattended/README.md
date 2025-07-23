# Unattended Installation Configuration

This directory contains all components needed to generate the Windows unattended installation file (`autounattend.xml`).

## Directory Structure

```
unattended/
├── passes/              # XML fragments for different Windows setup phases
│   ├── windowspe.xml       # Windows PE (Pre-installation) configuration
│   ├── specialize.xml      # System specialization settings
│   ├── oobesystem.xml      # Out-of-box experience configuration
│   ├── offlineservicing.xml # Offline servicing (drivers, updates)
│   ├── generalize.xml      # Sysprep generalize settings
│   ├── auditsystem.xml     # System audit mode settings
│   └── audituser.xml       # User audit mode settings
│
├── scripts/             # Post-installation PowerShell scripts
│   └── setup.ps1           # Main post-installation setup script
│
├── templates/           # XML template files
│   └── autounattend-template.xml  # Main template with placeholders
│
├── build/              # Generated output files
│   └── autounattend.xml    # Final generated unattended file
│
├── merge.js            # Node.js script to combine XML fragments
└── README.md           # This documentation
```

## Windows Setup Passes

Windows Setup processes the unattended file in several phases called "passes". Each pass serves a specific purpose:

### 1. windowsPE Pass (`windowspe.xml`)
- **Purpose**: Pre-installation environment configuration
- **Content**: 
  - Language and locale settings
  - Disk partitioning and formatting
  - Product key and user data
  - Image installation settings

### 2. offlineServicing Pass (`offlineservicing.xml`)
- **Purpose**: Add drivers, updates, or packages to the Windows image
- **Content**: Currently empty (placeholder for future use)
- **Use cases**: Driver injection, security updates, language packs

### 3. generalize Pass (`generalize.xml`)
- **Purpose**: Sysprep generalization settings
- **Content**: Currently empty (placeholder for future use)
- **Use cases**: Creating master images for deployment

### 4. specialize Pass (`specialize.xml`)
- **Purpose**: System-specific configuration
- **Content**:
  - Computer name settings
  - Time zone configuration
  - Regional settings

### 5. auditSystem Pass (`auditsystem.xml`)
- **Purpose**: System-level audit mode configuration
- **Content**: Currently empty (placeholder for future use)
- **Use cases**: System customization before user creation

### 6. auditUser Pass (`audituser.xml`)
- **Purpose**: User-level audit mode configuration  
- **Content**: Currently empty (placeholder for future use)
- **Use cases**: User profile customization

### 7. oobeSystem Pass (`oobesystem.xml`)
- **Purpose**: Out-of-box experience and user setup
- **Content**:
  - OOBE bypass settings
  - User account creation
  - Auto-login configuration
  - First logon commands

## Current Configuration

### Default User Account
- **Username**: `cloudit`
- **Password**: `CloudIT` (Base64 encoded: `Q2xvdWRJVA==`)
- **Type**: Local Administrator
- **Auto-login**: Enabled for first boot

### Disk Configuration
- **Partition 1**: 100 MB System Reserved (NTFS)
- **Partition 2**: Remaining space for Windows (NTFS, Drive C:)
- **Configuration**: Will wipe existing disk

### Language Settings
- **UI Language**: English (US)
- **Input Locale**: English (US)
- **System Locale**: English (US)
- **Time Zone**: UTC

### OOBE Settings
- All OOBE screens are bypassed for fully automated installation
- Network location set to "Work"
- Privacy settings configured automatically

## Post-Installation Scripts

### setup.ps1
Located in `scripts/setup.ps1`, this script runs automatically after Windows installation completes:

**Features:**
- Installs Chocolatey package manager
- Installs essential software (Chrome, Notepad++, 7-Zip, VLC)
- Configures Windows Defender settings
- Enables Remote Desktop
- Sets power management options
- Creates desktop shortcuts
- Logs all activities

**Execution:**
- Runs automatically on first logon via FirstLogonCommands
- Executes with administrator privileges
- Creates log file at `C:\Windows\Setup\Logs\cloudit-setup.log`

## Customization Guide

### Changing User Account Settings

Edit `passes/oobesystem.xml`:

```xml
<LocalAccount wcm:action="add">
    <Password>
        <Value>WW91ck5ld1Bhc3N3b3Jk</Value>  <!-- Base64 encoded password -->
        <PlainText>false</PlainText>
    </Password>
    <Description>Your Description</Description>
    <DisplayName>Your Display Name</DisplayName>
    <Group>Administrators</Group>
    <Name>yourusername</Name>
</LocalAccount>
```

**To encode a password in Base64:**
```powershell
[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("YourPassword"))
```

### Modifying Disk Partitioning

Edit `passes/windowspe.xml` to change disk layout:

```xml
<CreatePartition wcm:action="add">
    <Order>2</Order>
    <Type>Primary</Type>
    <Size>50000</Size>  <!-- Size in MB, or use <Extend>true</Extend> -->
</CreatePartition>
```

### Adding Software Installation

Edit `scripts/setup.ps1` to add more software packages:

```powershell
$packages = @('googlechrome', 'notepadplusplus', '7zip', 'vlc', 'your-package')
```

### Setting Computer Name

Edit `passes/specialize.xml`:

```xml
<ComputerName>YOUR-COMPUTER-NAME</ComputerName>
```

### Changing Time Zone

Edit `passes/specialize.xml`:

```xml
<TimeZone>Eastern Standard Time</TimeZone>
```

**Common time zones:**
- `UTC` - Coordinated Universal Time
- `Eastern Standard Time` - US Eastern
- `Pacific Standard Time` - US Pacific
- `Central European Standard Time` - Central Europe

## Building the Unattended File

The `merge.js` script combines all XML fragments into a single `autounattend.xml` file:

### Manual Build
```bash
cd unattended
node merge.js
```

### Automatic Build
The main `run.ps1` script automatically builds the unattended file as part of the ISO creation process.

## XML Validation

The merge script performs basic validation:
- Checks for XML declaration
- Verifies root `<unattend>` element
- Ensures proper closing tags

For more thorough validation, use Windows System Image Manager (SIM) from the Windows ADK.

## Troubleshooting

### Common Issues

**"XML is malformed"**
- Check syntax in individual pass files
- Ensure all tags are properly closed
- Validate XML structure using an XML editor

**"User account not created"**
- Verify password encoding (must be Base64)
- Check LocalAccount syntax in oobesystem.xml
- Ensure proper group assignment

**"Post-installation script doesn't run"**
- Verify FirstLogonCommands syntax
- Check script path in oobesystem.xml
- Ensure scripts are copied to ISO structure

**"Installation hangs at user creation"**
- Review OOBE bypass settings
- Check AutoLogon configuration
- Verify user account settings

### Testing XML Files

Test individual XML fragments by temporarily adding them to a minimal template and validating with Windows SIM.

## Security Notes

- Passwords are stored in Base64 encoding (not encryption)
- Auto-login poses security risks in production environments
- Post-installation scripts run with full administrator privileges
- Consider changing default passwords for production use

## References

- [Microsoft Unattended Installation Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
- [Windows Setup Configuration Passes](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-configuration-passes)
- [Unattended Windows Setup Reference](https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/)
