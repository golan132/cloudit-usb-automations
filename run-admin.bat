@echo off
echo CloudIT USB Automations - Admin Launcher
echo =====================================
echo.
echo This will launch PowerShell as Administrator to run the automation script.
echo Make sure you have:
echo - Windows ISO file in iso\source\ directory
echo - Node.js installed
echo - Windows ADK installed (for building ISOs)
echo.
pause
echo.
echo Launching PowerShell as Administrator...
echo.

REM Change to the script directory
cd /d "%~dp0"

REM Launch PowerShell as Administrator with the script
PowerShell -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0run.ps1""' -Verb RunAs}"

echo.
echo Admin PowerShell window should have opened.
echo If nothing happened, try running PowerShell as Administrator manually.
echo.
pause
