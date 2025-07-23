# extract-iso.ps1
# Extracts Windows ISO contents for modification

param(
    [string]$IsoPath,
    [string]$ExtractPath
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
    
    return $true
}

function Find-IsoFile {
    param([string]$SearchPath)
    
    Write-Log "Searching for ISO files in: $SearchPath"
    $isoFiles = Get-ChildItem -Path $SearchPath -Filter "*.iso" -ErrorAction SilentlyContinue
    
    if ($isoFiles.Count -eq 0) {
        Write-Log "No ISO files found in $SearchPath" -Level "ERROR"
        return $null
    } elseif ($isoFiles.Count -eq 1) {
        Write-Log "Found ISO file: $($isoFiles[0].FullName)" -Level "SUCCESS"
        return $isoFiles[0].FullName
    } else {
        Write-Log "Multiple ISO files found. Using the first one: $($isoFiles[0].FullName)" -Level "WARNING"
        foreach ($iso in $isoFiles) {
            Write-Log "  - $($iso.Name)"
        }
        return $isoFiles[0].FullName
    }
}

function Mount-IsoFile {
    param([string]$IsoPath)
    
    Write-Log "Mounting ISO file: $IsoPath"
    try {
        $mountResult = Mount-DiskImage -ImagePath $IsoPath -PassThru
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        if ($driveLetter) {
            $mountPath = "${driveLetter}:\"
            Write-Log "ISO mounted successfully at: $mountPath" -Level "SUCCESS"
            return $mountPath
        } else {
            Write-Log "Failed to get drive letter for mounted ISO" -Level "ERROR"
            return $null
        }
    } catch {
        Write-Log "Error mounting ISO: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Copy-IsoContents {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    Write-Log "Copying ISO contents from $SourcePath to $DestinationPath"
    
    # Create destination directory if it doesn't exist
    if (-not (Test-Path $DestinationPath)) {
        Write-Log "Creating destination directory: $DestinationPath"
        $null = New-Item -Path $DestinationPath -ItemType Directory -Force
    } else {
        Write-Log "Cleaning existing destination directory: $DestinationPath"
        Remove-Item -Path "$DestinationPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    try {
        # Copy all files and directories
        $totalFiles = (Get-ChildItem -Path $SourcePath -Recurse -File).Count
        Write-Log "Copying $totalFiles files..."
        
        robocopy $SourcePath $DestinationPath /E /R:3 /W:1 /MT:8 /NP /NFL /NDL | Out-Null
        
        if ($LASTEXITCODE -le 1) {
            Write-Log "ISO contents copied successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Robocopy completed with exit code: $LASTEXITCODE" -Level "WARNING"
            return $true
        }
    } catch {
        Write-Log "Error copying ISO contents: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Dismount-IsoFile {
    param([string]$IsoPath)
    
    Write-Log "Dismounting ISO file: $IsoPath"
    try {
        Dismount-DiskImage -ImagePath $IsoPath -Confirm:$false
        Write-Log "ISO dismounted successfully" -Level "SUCCESS"
    } catch {
        Write-Log "Error dismounting ISO: $($_.Exception.Message)" -Level "WARNING"
    }
}

# Main execution
function Main {
    Write-Log "Starting ISO extraction process..." -Level "SUCCESS"
    
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Determine paths
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    
    if (-not $IsoPath) {
        $sourceDir = Join-Path $projectRoot "iso\source"
        $IsoPath = Find-IsoFile -SearchPath $sourceDir
        if (-not $IsoPath) {
            Write-Log "Please place a Windows ISO file in the iso\source directory" -Level "ERROR"
            exit 1
        }
    }
    
    if (-not $ExtractPath) {
        $ExtractPath = Join-Path $projectRoot "iso\extracted"
    }
    
    # Validate ISO file exists
    if (-not (Test-Path $IsoPath)) {
        Write-Log "ISO file not found: $IsoPath" -Level "ERROR"
        exit 1
    }
    
    # Mount and extract ISO
    $mountPath = Mount-IsoFile -IsoPath $IsoPath
    if (-not $mountPath) {
        exit 1
    }
    
    try {
        $copySuccess = Copy-IsoContents -SourcePath $mountPath -DestinationPath $ExtractPath
        if ($copySuccess) {
            Write-Log "ISO extraction completed successfully!" -Level "SUCCESS"
            Write-Log "Extracted contents location: $ExtractPath" -Level "SUCCESS"
        } else {
            Write-Log "ISO extraction failed" -Level "ERROR"
            exit 1
        }
    } finally {
        Dismount-IsoFile -IsoPath $IsoPath
    }
}

# Run main function if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
