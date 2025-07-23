# build-iso.ps1
# Builds a new ISO file from the modified extracted contents

param(
    [string]$ExtractedIsoPath,
    [string]$OutputIsoPath,
    [string]$IsoLabel = "CloudIT_Windows"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator" -Level "ERROR"
        return $false
    }
    
    # Check for oscdimg.exe (Windows ADK)
    $oscdimgPaths = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "${env:ProgramFiles}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    )
    
    $oscdimgPath = $null
    foreach ($path in $oscdimgPaths) {
        if (Test-Path $path) {
            $oscdimgPath = $path
            break
        }
    }
    
    if (-not $oscdimgPath) {
        Write-Log "oscdimg.exe not found. Please install Windows ADK (Assessment and Deployment Kit)" -Level "ERROR"
        Write-Log "Download from: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install" -Level "ERROR"
        return $false
    }
    
    Write-Log "Found oscdimg.exe at: $oscdimgPath" -Level "SUCCESS"
    $script:OscdimgPath = $oscdimgPath
    return $true
}

function Test-ExtractedIso {
    param([string]$Path)
    
    Write-Log "Validating extracted ISO structure at: $Path"
    
    if (-not (Test-Path $Path)) {
        Write-Log "Extracted ISO path does not exist: $Path" -Level "ERROR"
        return $false
    }
    
    # Check for essential Windows ISO files/folders
    $requiredItems = @(
        "sources",
        "boot",
        "bootmgr"
    )
    
    foreach ($item in $requiredItems) {
        $itemPath = Join-Path $Path $item
        if (-not (Test-Path $itemPath)) {
            Write-Log "Required item not found: $item" -Level "ERROR"
            return $false
        }
    }
    
    # Check for autounattend.xml
    $autounattendPath = Join-Path $Path "autounattend.xml"
    if (Test-Path $autounattendPath) {
        Write-Log "Found autounattend.xml in ISO root" -Level "SUCCESS"
    } else {
        Write-Log "autounattend.xml not found in ISO root" -Level "WARNING"
    }
    
    Write-Log "Extracted ISO structure validation passed" -Level "SUCCESS"
    return $true
}

function Get-BootSector {
    param([string]$ExtractedPath)
    
    # Look for boot sector files
    $bootFiles = @(
        "boot\etfsboot.com",
        "efi\microsoft\boot\efisys.bin"
    )
    
    $bootSectors = @()
    foreach ($bootFile in $bootFiles) {
        $fullPath = Join-Path $ExtractedPath $bootFile
        if (Test-Path $fullPath) {
            $bootSectors += $fullPath
            Write-Log "Found boot file: $bootFile"
        }
    }
    
    return $bootSectors
}

function Build-IsoFile {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$Label
    )
    
    Write-Log "Building ISO file..."
    Write-Log "Source: $SourcePath"
    Write-Log "Destination: $DestinationPath"
    Write-Log "Label: $Label"
    
    try {
        # Ensure destination directory exists
        $destDir = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $destDir)) {
            $null = New-Item -Path $destDir -ItemType Directory -Force
        }
        
        # Remove existing ISO if present
        if (Test-Path $DestinationPath) {
            Write-Log "Removing existing ISO file"
            Remove-Item -Path $DestinationPath -Force
        }
        
        # Get boot sector information
        $etfsbootPath = Join-Path $SourcePath "boot\etfsboot.com"
        $efisysPath = Join-Path $SourcePath "efi\microsoft\boot\efisys.bin"
        
        # Build oscdimg command arguments
        $oscdimgArgs = @()
        
        # Basic options
        $oscdimgArgs += "-m"  # Ignore maximum image size limit
        $oscdimgArgs += "-o"  # Optimize storage by encoding duplicate files only once
        $oscdimgArgs += "-u2" # Produce an image that has both Joliet and UDF file systems
        $oscdimgArgs += "-udfver102" # UDF file system version
        
        # Boot options
        if (Test-Path $etfsbootPath) {
            $oscdimgArgs += "-b$etfsbootPath"
            Write-Log "Using BIOS boot sector: $etfsbootPath"
        }
        
        if (Test-Path $efisysPath) {
            $oscdimgArgs += "-pEF"
            $oscdimgArgs += "-e$efisysPath"
            Write-Log "Using UEFI boot sector: $efisysPath"
        }
        
        # Label
        $oscdimgArgs += "-l$Label"
        
        # Source and destination
        $oscdimgArgs += "`"$SourcePath`""
        $oscdimgArgs += "`"$DestinationPath`""
        
        # Log the full command
        $commandLine = "`"$script:OscdimgPath`" " + ($oscdimgArgs -join " ")
        Write-Log "Executing: $commandLine"
        
        # Execute oscdimg
        $startTime = Get-Date
        $process = Start-Process -FilePath $script:OscdimgPath -ArgumentList $oscdimgArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "oscdimg_output.txt" -RedirectStandardError "oscdimg_error.txt"
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Check results
        if ($process.ExitCode -eq 0) {
            if (Test-Path $DestinationPath) {
                $isoSize = (Get-Item $DestinationPath).Length
                $isoSizeMB = [math]::Round($isoSize / 1MB, 2)
                Write-Log "ISO built successfully!" -Level "SUCCESS"
                Write-Log "File: $DestinationPath" -Level "SUCCESS"
                Write-Log "Size: $isoSizeMB MB" -Level "SUCCESS"
                Write-Log "Build time: $($duration.ToString('hh\:mm\:ss'))" -Level "SUCCESS"
                return $true
            } else {
                Write-Log "oscdimg reported success but ISO file not found" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "oscdimg failed with exit code: $($process.ExitCode)" -Level "ERROR"
            
            # Show error output if available
            if (Test-Path "oscdimg_error.txt") {
                $errorContent = Get-Content "oscdimg_error.txt" -Raw
                if ($errorContent.Trim()) {
                    Write-Log "Error output: $errorContent" -Level "ERROR"
                }
            }
            return $false
        }
        
    } catch {
        Write-Log "Error building ISO: $($_.Exception.Message)" -Level "ERROR"
        return $false
    } finally {
        # Clean up temporary files
        Remove-Item "oscdimg_output.txt", "oscdimg_error.txt" -ErrorAction SilentlyContinue
    }
}

# Main execution
function Main {
    Write-Log "Starting ISO build process..." -Level "SUCCESS"
    
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Determine paths
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    
    if (-not $ExtractedIsoPath) {
        $ExtractedIsoPath = Join-Path $projectRoot "iso\extracted"
    }
    
    if (-not $OutputIsoPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputIsoPath = Join-Path $projectRoot "iso\result\CloudIT_Windows_$timestamp.iso"
    }
    
    # Validate extracted ISO
    if (-not (Test-ExtractedIso -Path $ExtractedIsoPath)) {
        Write-Log "Extracted ISO validation failed" -Level "ERROR"
        exit 1
    }
    
    # Build the ISO
    $buildSuccess = Build-IsoFile -SourcePath $ExtractedIsoPath -DestinationPath $OutputIsoPath -Label $IsoLabel
    
    if ($buildSuccess) {
        Write-Log "ISO build completed successfully!" -Level "SUCCESS"
        Write-Log "Your customized Windows ISO is ready: $OutputIsoPath" -Level "SUCCESS"
        
        # Provide next steps
        Write-Log ""
        Write-Log "Next steps:" -Level "SUCCESS"
        Write-Log "1. Test the ISO in a virtual machine first" -Level "SUCCESS"
        Write-Log "2. Create a bootable USB drive using tools like Rufus" -Level "SUCCESS"
        Write-Log "3. Boot from the USB to start the automated installation" -Level "SUCCESS"
        
    } else {
        Write-Log "ISO build failed" -Level "ERROR"
        exit 1
    }
}

# Run main function if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
