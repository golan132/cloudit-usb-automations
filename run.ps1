# run.ps1
# Main orchestration script for CloudIT Windows ISO automation
# This script coordinates the entire process of creating a customized Windows installation ISO

[CmdletBinding()]
param(
    [string]$IsoPath,
    [string]$OutputPath,
    [switch]$SkipExtraction,
    [switch]$SkipBuild,
    [switch]$CleanOnly
)

# Set error action preference
$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [string]$Message, 
        [string]$Level = "INFO",
        [switch]$NoNewline
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "HEADER" { "Cyan" }
        default { "White" }
    }
    
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($NoNewline) {
        Write-Host $logMessage -ForegroundColor $color -NoNewline
    } else {
        Write-Host $logMessage -ForegroundColor $color
    }
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

function Test-Prerequisites {
    Write-Log "Checking system prerequisites..." -Level "HEADER"
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Log "PowerShell version: $psVersion"
    
    if ($psVersion.Major -lt 5) {
        Write-Log "PowerShell 5.0 or higher is required" -Level "ERROR"
        return $false
    }
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator" -Level "ERROR"
        Write-Log "Please restart PowerShell as Administrator and try again" -Level "ERROR"
        return $false
    }
    Write-Log "Running as Administrator: OK" -Level "SUCCESS"
    
    # Check for Node.js (required for merge.ts compilation)
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Log "Node.js version: $nodeVersion" -Level "SUCCESS"
        } else {
            Write-Log "Node.js not found. Installing Node.js..." -Level "WARNING"
            # Try to install Node.js via Chocolatey if available
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                choco install nodejs -y
            } else {
                Write-Log "Please install Node.js from https://nodejs.org/" -Level "ERROR"
                return $false
            }
        }
    } catch {
        Write-Log "Error checking Node.js: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    
    # Check for TypeScript compiler
    try {
        $tscVersion = & tsc --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $tscVersion) {
            Write-Log "TypeScript version: $tscVersion" -Level "SUCCESS"
        } else {
            Write-Log "TypeScript not found. Installing TypeScript..." -Level "WARNING"
            $installResult = & npm install -g typescript 2>&1
            if ($LASTEXITCODE -eq 0) {
                $tscVersion = & tsc --version 2>$null
                if ($LASTEXITCODE -eq 0 -and $tscVersion) {
                    Write-Log "TypeScript installed: $tscVersion" -Level "SUCCESS"
                } else {
                    Write-Log "Failed to verify TypeScript installation" -Level "ERROR"
                    return $false
                }
            } else {
                Write-Log "Failed to install TypeScript: $installResult" -Level "ERROR"
                return $false
            }
        }
    } catch {
        Write-Log "Error checking TypeScript: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    
    # Check for Windows ADK (optional, with warning)
    $adkPaths = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "${env:ProgramFiles}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    )
    
    $adkFound = $false
    foreach ($path in $adkPaths) {
        if (Test-Path $path) {
            Write-Log "Windows ADK found: OK" -Level "SUCCESS"
            $adkFound = $true
            break
        }
    }
    
    if (-not $adkFound) {
        Write-Log "Windows ADK not found - ISO building may fail" -Level "WARNING"
        Write-Log "Install from: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install" -Level "WARNING"
    }
    
    return $true
}

function Initialize-Project {
    Write-Log "Initializing project structure..." -Level "HEADER"
    
    # Get script directory - handle different invocation methods
    if ($MyInvocation.MyCommand.Path) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } elseif ($PSScriptRoot) {
        $scriptDir = $PSScriptRoot
    } else {
        $scriptDir = Get-Location
    }
    
    $script:ProjectRoot = $scriptDir
    
    # Define project paths
    $script:Paths = @{
        Root = $scriptDir
        Unattended = Join-Path $scriptDir "unattended"
        UnattendedBuild = Join-Path $scriptDir "unattended\build"
        IsoSource = Join-Path $scriptDir "iso\source"
        IsoExtracted = Join-Path $scriptDir "iso\extracted"
        IsoResult = Join-Path $scriptDir "iso\result"
        Scripts = Join-Path $scriptDir "scripts"
        MergeScript = Join-Path $scriptDir "dist\unattended\merge.js"
        DistDir = Join-Path $scriptDir "dist"
    }
    
    # Create missing directories
    foreach ($path in $script:Paths.Values) {
        if (-not (Test-Path $path)) {
            Write-Log "Creating directory: $path"
            $null = New-Item -Path $path -ItemType Directory -Force
        }
    }
    
    Write-Log "Project structure initialized" -Level "SUCCESS"
    return $true
}

function Clear-WorkingDirectories {
    Write-Log "Cleaning working directories..." -Level "HEADER"
    
    $directoriesToClean = @(
        $script:Paths.UnattendedBuild,
        $script:Paths.IsoExtracted
    )
    
    foreach ($dir in $directoriesToClean) {
        if (Test-Path $dir) {
            Write-Log "Cleaning: $dir"
            Remove-Item -Path "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Log "Working directories cleaned" -Level "SUCCESS"
}

function Build-AutounattendFile {
    Write-Log "Building autounattend.xml file..." -Level "HEADER"
    
    # First, compile TypeScript
    Write-Log "Compiling TypeScript..."
    try {
        $compileResult = tsc 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "TypeScript compilation failed: $compileResult" -Level "ERROR"
            return $false
        }
        Write-Log "TypeScript compilation successful" -Level "SUCCESS"
    } catch {
        Write-Log "Error during TypeScript compilation: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
    
    $mergeScriptPath = $script:Paths.MergeScript
    
    if (-not (Test-Path $mergeScriptPath)) {
        Write-Log "Compiled merge script not found: $mergeScriptPath" -Level "ERROR"
        return $false
    }
    
    try {
        Write-Log "Executing merge script..."
        $originalLocation = Get-Location
        Set-Location $script:Paths.Root
        
        $result = node $mergeScriptPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "autounattend.xml built successfully" -Level "SUCCESS"
            
            # Verify the output file
            $outputFile = Join-Path $script:Paths.UnattendedBuild "autounattend.xml"
            if (Test-Path $outputFile) {
                $fileSize = (Get-Item $outputFile).Length
                Write-Log "Generated file size: $fileSize bytes" -Level "SUCCESS"
                return $true
            } else {
                Write-Log "Output file not found after build" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Merge script failed: $result" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error building autounattend.xml: $($_.Exception.Message)" -Level "ERROR"
        return $false
    } finally {
        Set-Location $originalLocation
    }
}

function Invoke-IsoExtraction {
    Write-Log "Extracting Windows ISO..." -Level "HEADER"
    
    $extractScript = Join-Path $script:Paths.Scripts "extract-iso.ps1"
    
    if (-not (Test-Path $extractScript)) {
        Write-Log "Extract script not found: $extractScript" -Level "ERROR"
        return $false
    }
    
    try {
        $scriptArgs = @{}
        if ($IsoPath) {
            $scriptArgs['IsoPath'] = $IsoPath
        }
        $scriptArgs['ExtractPath'] = $script:Paths.IsoExtracted
        
        Write-Log "Executing ISO extraction script..."
        & $extractScript @scriptArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "ISO extraction completed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "ISO extraction failed" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error during ISO extraction: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Invoke-AutounattendInjection {
    Write-Log "Injecting autounattend.xml into ISO..." -Level "HEADER"
    
    $injectScript = Join-Path $script:Paths.Scripts "inject-autounattend.ps1"
    
    if (-not (Test-Path $injectScript)) {
        Write-Log "Inject script not found: $injectScript" -Level "ERROR"
        return $false
    }
    
    try {
        $autounattendFile = Join-Path $script:Paths.UnattendedBuild "autounattend.xml"
        
        Write-Log "Executing autounattend injection script..."
        & $injectScript -ExtractedIsoPath $script:Paths.IsoExtracted -AutounattendPath $autounattendFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "autounattend.xml injection completed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "autounattend.xml injection failed" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error during autounattend injection: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Invoke-IsoBuild {
    Write-Log "Building customized ISO..." -Level "HEADER"
    
    $buildScript = Join-Path $script:Paths.Scripts "build-iso.ps1"
    
    if (-not (Test-Path $buildScript)) {
        Write-Log "Build script not found: $buildScript" -Level "ERROR"
        return $false
    }
    
    try {
        $scriptArgs = @{}
        $scriptArgs['ExtractedIsoPath'] = $script:Paths.IsoExtracted
        
        if ($OutputPath) {
            $scriptArgs['OutputIsoPath'] = $OutputPath
        } else {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $defaultOutput = Join-Path $script:Paths.IsoResult "CloudIT_Windows_$timestamp.iso"
            $scriptArgs['OutputIsoPath'] = $defaultOutput
        }
        
        Write-Log "Executing ISO build script..."
        & $buildScript @scriptArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "ISO build completed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "ISO build failed" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error during ISO build: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Show-Summary {
    Write-Header "CloudIT Windows ISO Automation - Summary"
    
    Write-Log "Process completed!" -Level "SUCCESS"
    Write-Log ""
    Write-Log "Project structure:" -Level "SUCCESS"
    Write-Log "  Source ISO: $($script:Paths.IsoSource)" -Level "SUCCESS"
    Write-Log "  Extracted: $($script:Paths.IsoExtracted)" -Level "SUCCESS"
    Write-Log "  Result: $($script:Paths.IsoResult)" -Level "SUCCESS"
    Write-Log ""
    
    # List result files
    if (Test-Path $script:Paths.IsoResult) {
        $resultFiles = Get-ChildItem -Path $script:Paths.IsoResult -Filter "*.iso"
        if ($resultFiles) {
            Write-Log "Generated ISO files:" -Level "SUCCESS"
            foreach ($file in $resultFiles) {
                $sizeMB = [math]::Round($file.Length / 1MB, 2)
                Write-Log "  $($file.Name) ($sizeMB MB)" -Level "SUCCESS"
            }
        }
    }
    
    Write-Log ""
    Write-Log "Next steps:" -Level "SUCCESS"
    Write-Log "1. Test the ISO in a virtual machine" -Level "SUCCESS"
    Write-Log "2. Create a bootable USB with tools like Rufus" -Level "SUCCESS"
    Write-Log "3. Boot from USB to start automated installation" -Level "SUCCESS"
}

function Show-Help {
    Write-Header "CloudIT Windows ISO Automation"
    
    Write-Host "Usage: .\run.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -IsoPath <path>      Path to source Windows ISO file"
    Write-Host "  -OutputPath <path>   Path for the generated customized ISO"
    Write-Host "  -SkipExtraction      Skip ISO extraction (use existing extracted files)"
    Write-Host "  -SkipBuild           Skip ISO building (stops after injection)"
    Write-Host "  -CleanOnly           Only clean working directories and exit"
    Write-Host "  -Verbose             Enable verbose output (use -Verbose switch)"
    Write-Host "  -Help                Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\run.ps1"
    Write-Host "  .\run.ps1 -IsoPath 'C:\ISOs\Windows11.iso'"
    Write-Host "  .\run.ps1 -OutputPath 'C:\Custom\MyWindows.iso'"
    Write-Host "  .\run.ps1 -CleanOnly"
    Write-Host ""
}

# Main execution
function Main {
    try {
        # Show header
        Write-Header "CloudIT Windows ISO Automation"
        
        if ($CleanOnly) {
            if (Initialize-Project) {
                Clear-WorkingDirectories
                Write-Log "Cleanup completed" -Level "SUCCESS"
            }
            return
        }
        
        # Check prerequisites
        if (-not (Test-Prerequisites)) {
            Write-Log "Prerequisites check failed" -Level "ERROR"
            exit 1
        }
        
        # Initialize project
        if (-not (Initialize-Project)) {
            Write-Log "Project initialization failed" -Level "ERROR"
            exit 1
        }
        
        # Clean working directories
        Clear-WorkingDirectories
        
        # Build autounattend.xml
        if (-not (Build-AutounattendFile)) {
            Write-Log "Autounattend build failed" -Level "ERROR"
            exit 1
        }
        
        # Extract ISO (unless skipped)
        if (-not $SkipExtraction) {
            if (-not (Invoke-IsoExtraction)) {
                Write-Log "ISO extraction failed" -Level "ERROR"
                exit 1
            }
        } else {
            Write-Log "Skipping ISO extraction (using existing files)" -Level "WARNING"
        }
        
        # Inject autounattend.xml
        if (-not (Invoke-AutounattendInjection)) {
            Write-Log "Autounattend injection failed" -Level "ERROR"
            exit 1
        }
        
        # Build new ISO (unless skipped)
        if (-not $SkipBuild) {
            if (-not (Invoke-IsoBuild)) {
                Write-Log "ISO build failed" -Level "ERROR"
                exit 1
            }
        } else {
            Write-Log "Skipping ISO build (stopping after injection)" -Level "WARNING"
        }
        
        # Show summary
        Show-Summary
        
    } catch {
        Write-Log "Unexpected error: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
        exit 1
    }
}

# Handle help parameter
if ($args -contains "-Help" -or $args -contains "--help" -or $args -contains "/?") {
    Show-Help
    exit 0
}

# Run main function
Main
