# example-usage.ps1
# Example script showing how to use the CloudIT USB Automation system

# This script demonstrates various ways to use the automation system
# Make sure you have:
# 1. A Windows ISO file in the iso/source/ directory
# 2. Node.js installed
# 3. Windows ADK installed (for building ISOs)
# 4. PowerShell running as Administrator

Write-Host "CloudIT USB Automation - Example Usage" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator and try again" -ForegroundColor Red
    exit 1
}

# Get the project directory
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Project directory: $projectDir" -ForegroundColor Green
Write-Host ""

# Example 1: Check if ISO exists in source directory
Write-Host "Example 1: Checking for source ISO files" -ForegroundColor Yellow
$sourceDir = Join-Path $projectDir "iso\source"
$isoFiles = Get-ChildItem -Path $sourceDir -Filter "*.iso" -ErrorAction SilentlyContinue

if ($isoFiles.Count -eq 0) {
    Write-Host "  ⚠️  No ISO files found in iso\source\" -ForegroundColor Yellow
    Write-Host "  Please place a Windows ISO file in: $sourceDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Example: Copy your Windows 11 ISO file:" -ForegroundColor Cyan
    Write-Host "  Copy-Item 'C:\Downloads\Windows11.iso' '$sourceDir\Windows11.iso'" -ForegroundColor Cyan
} else {
    Write-Host "  ✓ Found $($isoFiles.Count) ISO file(s):" -ForegroundColor Green
    foreach ($iso in $isoFiles) {
        $sizeMB = [math]::Round($iso.Length / 1MB, 2)
        Write-Host "    - $($iso.Name) ($sizeMB MB)" -ForegroundColor Green
    }
}

Write-Host ""

# Example 2: Basic usage - complete automation
Write-Host "Example 2: Basic complete automation" -ForegroundColor Yellow
Write-Host "  .\run.ps1" -ForegroundColor Cyan
Write-Host "  This will:" -ForegroundColor White
Write-Host "    1. Build autounattend.xml from XML fragments" -ForegroundColor White
Write-Host "    2. Extract the first ISO found in iso\source\" -ForegroundColor White
Write-Host "    3. Inject the autounattend.xml into the extracted ISO" -ForegroundColor White
Write-Host "    4. Build a new customized ISO in iso\result\" -ForegroundColor White
Write-Host ""

# Example 3: Using specific ISO path
Write-Host "Example 3: Using a specific ISO file" -ForegroundColor Yellow
Write-Host "  .\run.ps1 -IsoPath 'C:\ISOs\Windows11.iso'" -ForegroundColor Cyan
Write-Host "  Use this when your ISO is not in the default source directory" -ForegroundColor White
Write-Host ""

# Example 4: Custom output path
Write-Host "Example 4: Custom output location" -ForegroundColor Yellow
Write-Host "  .\run.ps1 -OutputPath 'C:\CustomISOs\MyWindows.iso'" -ForegroundColor Cyan
Write-Host "  Specify exactly where you want the final ISO saved" -ForegroundColor White
Write-Host ""

# Example 5: Step-by-step execution
Write-Host "Example 5: Step-by-step execution" -ForegroundColor Yellow
Write-Host "  # Step 1: Clean and build autounattend.xml only" -ForegroundColor Cyan
Write-Host "  .\run.ps1 -SkipExtraction -SkipBuild" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Step 2: Extract ISO (using existing autounattend.xml)" -ForegroundColor Cyan
Write-Host "  .\scripts\extract-iso.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Step 3: Inject autounattend (manual)" -ForegroundColor Cyan
Write-Host "  .\scripts\inject-autounattend.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Step 4: Build final ISO" -ForegroundColor Cyan
Write-Host "  .\scripts\build-iso.ps1" -ForegroundColor Cyan
Write-Host ""

# Example 6: Cleaning working directories
Write-Host "Example 6: Clean working directories" -ForegroundColor Yellow
Write-Host "  .\run.ps1 -CleanOnly" -ForegroundColor Cyan
Write-Host "  Removes temporary files from iso\extracted\ and unattended\build\" -ForegroundColor White
Write-Host ""

# Example 7: Customization examples
Write-Host "Example 7: Customization" -ForegroundColor Yellow
Write-Host "  # Change the default user password:" -ForegroundColor Cyan
Write-Host "  `$newPassword = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('YourNewPassword'))" -ForegroundColor Cyan
Write-Host "  # Then edit unattended\passes\oobesystem.xml and replace the <Value> in the Password section" -ForegroundColor Cyan
Write-Host ""
Write-Host "  # Add more software to post-installation:" -ForegroundColor Cyan
Write-Host "  # Edit unattended\scripts\setup.ps1 and add packages to the `$packages array" -ForegroundColor Cyan
Write-Host ""

# Example 8: Testing in VM
Write-Host "Example 8: Testing the generated ISO" -ForegroundColor Yellow
Write-Host "  ⚠️  Always test in a Virtual Machine first!" -ForegroundColor Red
Write-Host "  1. Create a new VM in VMware/VirtualBox/Hyper-V" -ForegroundColor White
Write-Host "  2. Mount the generated ISO as the boot drive" -ForegroundColor White
Write-Host "  3. Start the VM and verify the automated installation" -ForegroundColor White
Write-Host "  4. Check that the 'cloudit' user is created with auto-login" -ForegroundColor White
Write-Host "  5. Verify post-installation software is installed" -ForegroundColor White
Write-Host ""

# Example 9: Creating bootable USB
Write-Host "Example 9: Creating bootable USB" -ForegroundColor Yellow
Write-Host "  After testing in VM, create bootable USB with Rufus:" -ForegroundColor White
Write-Host "  1. Download Rufus from https://rufus.ie/" -ForegroundColor White
Write-Host "  2. Insert USB drive (8GB+ recommended)" -ForegroundColor White
Write-Host "  3. Select your generated ISO in Rufus" -ForegroundColor White
Write-Host "  4. Use GPT partition scheme for UEFI" -ForegroundColor White
Write-Host "  5. Click START to create bootable USB" -ForegroundColor White
Write-Host ""

Write-Host "Ready to start? Run one of the examples above!" -ForegroundColor Green
Write-Host ""

# Check prerequisites
Write-Host "Prerequisites Check:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# Check Node.js
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "✗ Node.js: Not installed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Node.js: Not found" -ForegroundColor Red
}

# Check Windows ADK
$adkPaths = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "${env:ProgramFiles}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
)

$adkFound = $false
foreach ($path in $adkPaths) {
    if (Test-Path $path) {
        Write-Host "✓ Windows ADK: Found" -ForegroundColor Green
        $adkFound = $true
        break
    }
}

if (-not $adkFound) {
    Write-Host "✗ Windows ADK: Not found (required for building ISOs)" -ForegroundColor Red
    Write-Host "  Download from: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "For help with any command, add -Help:" -ForegroundColor Cyan
Write-Host "  .\run.ps1 -Help" -ForegroundColor Cyan
