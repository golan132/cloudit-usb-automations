# inject-autounattend.ps1
# Injects the generated autounattend.xml file into the extracted ISO structure

param(
    [string]$ExtractedIsoPath,
    [string]$AutounattendPath
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
    
    Write-Log "Extracted ISO structure validation passed" -Level "SUCCESS"
    return $true
}

function Copy-AutounattendFile {
    param(
        [string]$SourcePath,
        [string]$DestinationDir
    )
    
    Write-Log "Copying autounattend.xml to extracted ISO..."
    
    try {
        $destPath = Join-Path $DestinationDir "autounattend.xml"
        
        # Remove existing autounattend.xml if present
        if (Test-Path $destPath) {
            Write-Log "Removing existing autounattend.xml"
            Remove-Item -Path $destPath -Force
        }
        
        Copy-Item -Path $SourcePath -Destination $destPath -Force
        Write-Log "autounattend.xml copied successfully to: $destPath" -Level "SUCCESS"
        
        # Verify the file was copied correctly
        if (Test-Path $destPath) {
            $fileSize = (Get-Item $destPath).Length
            Write-Log "File size: $fileSize bytes" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to verify copied file" -Level "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Error copying autounattend.xml: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Copy-PostInstallScripts {
    param(
        [string]$ScriptsSourceDir,
        [string]$IsoPath
    )
    
    Write-Log "Copying post-installation scripts..."
    
    try {
        # Create the Scripts directory in the extracted ISO
        $scriptsDestDir = Join-Path $IsoPath "sources\`$OEM`$\`$1\Windows\Setup\Scripts"
        
        if (-not (Test-Path $scriptsDestDir)) {
            Write-Log "Creating scripts directory: $scriptsDestDir"
            $null = New-Item -Path $scriptsDestDir -ItemType Directory -Force
        }
        
        # Copy all scripts from the unattended\scripts directory
        if (Test-Path $ScriptsSourceDir) {
            $scriptFiles = Get-ChildItem -Path $ScriptsSourceDir -File
            foreach ($scriptFile in $scriptFiles) {
                $destPath = Join-Path $scriptsDestDir $scriptFile.Name
                Copy-Item -Path $scriptFile.FullName -Destination $destPath -Force
                Write-Log "Copied script: $($scriptFile.Name)"
            }
            Write-Log "Post-installation scripts copied successfully" -Level "SUCCESS"
        } else {
            Write-Log "Scripts source directory not found: $ScriptsSourceDir" -Level "WARNING"
        }
        
        return $true
    } catch {
        Write-Log "Error copying post-installation scripts: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Validate-AutounattendXml {
    param([string]$FilePath)
    
    Write-Log "Validating autounattend.xml file..."
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Log "autounattend.xml file not found: $FilePath" -Level "ERROR"
            return $false
        }
        
        # Load and basic validation
        $content = Get-Content -Path $FilePath -Raw
        
        # Check for basic XML structure
        if ($content -match '<?xml.*?>' -and 
            $content -match '<unattend.*?>' -and 
            $content -match '</unattend>') {
            
            Write-Log "autounattend.xml validation passed" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "autounattend.xml appears to be malformed" -Level "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Error validating autounattend.xml: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Set-IsoPermissions {
    param([string]$IsoPath)
    
    Write-Log "Setting appropriate permissions on extracted ISO..."
    
    try {
        # Remove read-only attributes that might interfere with building
        Get-ChildItem -Path $IsoPath -Recurse | ForEach-Object {
            if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            }
        }
        Write-Log "Permissions updated successfully" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Error setting permissions: $($_.Exception.Message)" -Level "WARNING"
        return $false
    }
}

# Main execution
function Main {
    Write-Log "Starting autounattend injection process..." -Level "SUCCESS"
    
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Determine paths
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Split-Path -Parent $scriptDir
    
    if (-not $ExtractedIsoPath) {
        $ExtractedIsoPath = Join-Path $projectRoot "iso\extracted"
    }
    
    if (-not $AutounattendPath) {
        $AutounattendPath = Join-Path $projectRoot "unattended\build\autounattend.xml"
    }
    
    # Validate inputs
    if (-not (Test-ExtractedIso -Path $ExtractedIsoPath)) {
        Write-Log "Extracted ISO validation failed" -Level "ERROR"
        exit 1
    }
    
    if (-not (Validate-AutounattendXml -FilePath $AutounattendPath)) {
        Write-Log "autounattend.xml validation failed" -Level "ERROR"
        exit 1
    }
    
    # Inject autounattend.xml
    $copySuccess = Copy-AutounattendFile -SourcePath $AutounattendPath -DestinationDir $ExtractedIsoPath
    if (-not $copySuccess) {
        Write-Log "Failed to inject autounattend.xml" -Level "ERROR"
        exit 1
    }
    
    # Copy post-installation scripts
    $scriptsSourceDir = Join-Path $projectRoot "unattended\scripts"
    $scriptsSuccess = Copy-PostInstallScripts -ScriptsSourceDir $scriptsSourceDir -IsoPath $ExtractedIsoPath
    
    # Set appropriate permissions
    Set-IsoPermissions -IsoPath $ExtractedIsoPath
    
    Write-Log "autounattend.xml injection completed successfully!" -Level "SUCCESS"
    Write-Log "The extracted ISO is now ready for building" -Level "SUCCESS"
}

# Run main function if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
