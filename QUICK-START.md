# 🚀 Quick Start Example

This guide shows you how to use the enhanced CloudIT USB Automations in under 5 minutes.

## Prerequisites

### Required Software
1. **Node.js** (v16 or higher)
   - Download: [nodejs.org](https://nodejs.org/)
   - Verify: `node --version` and `npm --version`

2. **PowerShell** (Windows built-in)
   - Required for automation scripts
   - Run as Administrator for ISO operations

3. **Windows ADK** (for ISO building) - Optional but recommended
   - Download: [Microsoft Windows ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)
   - Required for: `oscdimg.exe` (ISO creation)

### Required Files
- **Windows ISO file** (Windows 10/11)
  - Place in: `iso/source/`
  - Supported: Any Windows 10/11 x64 ISO

### System Requirements
- **Windows 10/11** (Host system)
- **Administrator privileges** (for ISO operations)
- **4GB+ free disk space** (for ISO extraction/creation)

### What Each Program Does
- **Node.js**: Runs the TypeScript/JavaScript automation scripts
- **PowerShell**: Executes Windows-specific operations (ISO extraction, file operations)
- **Windows ADK**: Provides `oscdimg.exe` for creating bootable ISO files
- **TypeScript Compiler**: Converts TypeScript source to JavaScript (included with Node.js)

## Step 1: Verify Setup

```powershell
# Check if everything is working
npm run verify
```

**Expected Output:**
```
🚀 CloudIT USB Automations - Testing Enhanced Features
✓ AutoUnattendBuilder imports successfully
✓ Build completed successfully
✓ Validation: PASSED
✓ Build duration: 6ms
✓ Passes processed: 7
🎉 Enhancement verification completed!
```

## Step 2: Build Your First XML

```powershell
# Generate the unattended installation XML
npm run build
```

**You'll see enhanced logging like:**
```
[2025-07-24T18:39:04.269Z] INFO  [AutoUnattendBuilder] Starting autounattend.xml build process
[2025-07-24T18:39:04.275Z] INFO  [AutoUnattendBuilder] 
=== Build Summary ===
[2025-07-24T18:39:04.276Z] INFO  [AutoUnattendBuilder] Validation: PASSED
[2025-07-24T18:39:04.276Z] INFO  [AutoUnattendBuilder] Duration: 6ms
[2025-07-24T18:39:04.277Z] INFO  [AutoUnattendBuilder] File size: 4,776 bytes

=== XML Validation Report ===
Status: ✅ VALID
⚠️  WARNINGS:
  • Recommended component missing: Microsoft-Windows-Setup
💡 SUGGESTIONS:
  • Consider adding Windows Update configuration
```

## Step 3: Customize (Optional)

### Change the Default User
Edit `unattended/passes/oobesystem.xml`:
```xml
<UserAccounts>
    <LocalAccounts>
        <LocalAccount>
            <Name>MyUser</Name>
            <Password>MyPassword123</Password>
        </LocalAccount>
    </LocalAccounts>
</UserAccounts>
```

### Add a Post-Installation Script
Create `unattended/scripts/my-setup.ps1`:
```powershell
# Install your favorite software
Write-Host "Installing custom software..."
# Your installation commands here
```

## Step 4: Full ISO Automation (With ISO File)

```powershell
# 1. Place your Windows ISO in iso/source/
# 2. Run the full automation
.\run.ps1
```

**This will:**
1. Extract your ISO
2. Build the enhanced autounattend.xml with validation
3. Inject the unattended file
4. Create a new customized ISO in `iso/result/`

## Step 5: Advanced Features

### Run Tests
```powershell
npm run test
# See all 6 tests passing with enhanced features
```

### Monitor Performance
```powershell
npm run build
# Get detailed build statistics:
# - Duration: 3-12ms
# - Passes processed: 7
# - File size: 4,776 bytes
# - Memory usage tracking
```

### Development Mode
```powershell
npm run dev
# Watch mode - auto-compile on file changes
```

## 🎯 What You Get

✅ **Enhanced XML Generation** with validation and security checks  
✅ **Real-time Performance Monitoring** with build statistics  
✅ **Comprehensive Error Handling** with actionable messages  
✅ **Advanced Logging** with timestamps and context  
✅ **Automatic Configuration** with sensible defaults  
✅ **Complete Testing Suite** ensuring reliability  

## 🔧 Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| `Template not found` | Run `npm run compile` |
| `Permission denied` | Run PowerShell as Administrator |
| `Node.js not found` | Install from [nodejs.org](https://nodejs.org/) |
| `npm command not found` | Restart terminal after Node.js install |
| `oscdimg.exe not found` | Install Windows ADK |
| `ISO extraction fails` | Check file permissions & disk space |
| `Build fails` | Check `npm run verify` output |
| `PowerShell execution policy` | Run: `Set-ExecutionPolicy RemoteSigned` |

### Quick System Check
```powershell
# Verify all prerequisites
node --version          # Should show v16+ 
npm --version           # Should show npm version
Get-ExecutionPolicy     # Should allow script execution
Test-Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"  # Should be True if ADK installed
```

## 🎉 You're Ready!

Your enhanced CloudIT USB Automations is now set up with:
- Professional-grade logging and monitoring
- Advanced XML validation and security checks  
- Real-time performance tracking
- Comprehensive error handling

**Next step**: Place your Windows ISO in `iso/source/` and run `.\run.ps1` to create your first automated Windows installation! 🚀
