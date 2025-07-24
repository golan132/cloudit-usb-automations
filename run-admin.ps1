# run-admin.ps1
# Administrative launcher for the CloudIT USB Automation

Write-Host "CloudIT USB Automations - Administrative Launcher" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Write-Host ""
    
    # Get the directory of this script
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $mainScript = Join-Path $scriptDir "run.ps1"
    
    # Launch as administrator
    try {
        Start-Process PowerShell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$mainScript`"" -Verb RunAs -Wait
        Write-Host "Script execution completed." -ForegroundColor Green
    } catch {
        Write-Host "Failed to launch as administrator: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual steps:" -ForegroundColor Yellow
        Write-Host "1. Right-click PowerShell icon and select 'Run as administrator'" -ForegroundColor Yellow
        Write-Host "2. Navigate to: $scriptDir" -ForegroundColor Yellow
        Write-Host "3. Run: .\run.ps1" -ForegroundColor Yellow
    }
} else {
    Write-Host "Already running as Administrator. Executing main script..." -ForegroundColor Green
    Write-Host ""
    
    # Change to script directory and run main script
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $scriptDir
    & ".\run.ps1"
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
