# CloudIT Post-Installation Setup Script
# This script runs after Windows installation completes

Write-Host "Starting CloudIT post-installation setup..." -ForegroundColor Green

# Create log file
$LogPath = "C:\Windows\Setup\Logs\cloudit-setup.log"
$null = New-Item -Path (Split-Path $LogPath) -ItemType Directory -Force -ErrorAction SilentlyContinue

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

try {
    Write-Log "CloudIT post-installation setup started"
    
    # Disable Windows Defender (optional - remove if not desired)
    Write-Log "Configuring Windows Defender..."
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    
    # Configure Windows Updates to manual
    Write-Log "Configuring Windows Update service..."
    Set-Service -Name "wuauserv" -StartupType Manual -ErrorAction SilentlyContinue
    
    # Enable Remote Desktop
    Write-Log "Enabling Remote Desktop..."
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -ErrorAction SilentlyContinue
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    
    # Install Chocolatey package manager
    Write-Log "Installing Chocolatey package manager..."
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) -ErrorAction SilentlyContinue
    
    # Install essential software via Chocolatey
    Write-Log "Installing essential software packages..."
    $packages = @('googlechrome', 'notepadplusplus', '7zip', 'vlc')
    foreach ($package in $packages) {
        Write-Log "Installing $package..."
        Start-Process -FilePath "choco" -ArgumentList "install", $package, "-y" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
    
    # Create desktop shortcuts
    Write-Log "Creating desktop shortcuts..."
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    
    # Create CloudIT Info shortcut
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\CloudIT System Info.lnk")
    $Shortcut.TargetPath = "msinfo32.exe"
    $Shortcut.IconLocation = "msinfo32.exe"
    $Shortcut.Save()
    
    # Configure power settings
    Write-Log "Configuring power settings..."
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    powercfg /change hibernate-timeout-ac 0
    powercfg /change hibernate-timeout-dc 0
    
    # Disable unnecessary startup programs
    Write-Log "Configuring startup programs..."
    # Add your startup configuration here
    
    Write-Log "CloudIT post-installation setup completed successfully"
    
    # Schedule cleanup and reboot
    Write-Log "Scheduling system cleanup and reboot..."
    schtasks /create /tn "CloudIT Cleanup" /tr "powershell.exe -Command \"Remove-Item -Path 'C:\Windows\Setup\Scripts' -Recurse -Force; Restart-Computer -Force\"" /sc once /st 23:59 /f
    
} catch {
    Write-Log "Error during setup: $($_.Exception.Message)"
    Write-Host "Setup completed with errors. Check log at $LogPath" -ForegroundColor Yellow
}

Write-Host "CloudIT setup script completed. System will reboot shortly." -ForegroundColor Green
