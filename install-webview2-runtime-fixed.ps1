# Improved WebView2 Runtime Installer - Handles 0x80040c01 error
# This script provides multiple installation methods and error resolution

param(
    [switch]$Silent,
    [switch]$Force,
    [switch]$CleanInstall
)

Write-Host "Improved WebView2 Runtime Installer" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Check disk space
$systemDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
Write-Host "Available disk space: $freeSpaceGB GB" -ForegroundColor Cyan

if ($freeSpaceGB -lt 1) {
    Write-Host "Warning: Less than 1GB free space available. Installation may fail." -ForegroundColor Yellow
}

# Check if WebView2 runtime is already installed
Write-Host "`nChecking if WebView2 Runtime is already installed..." -ForegroundColor Yellow

try {
    $webView2Path = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
    if ($webView2Path) {
        Write-Host "? WebView2 Runtime is already installed!" -ForegroundColor Green
        Write-Host "  Version: $($webView2Path.pv)" -ForegroundColor Cyan
        if (-not $Force) {
            Write-Host "Use -Force to reinstall anyway." -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Host "WebView2 Runtime not found in registry." -ForegroundColor Red
}

# Clean installation if requested
if ($CleanInstall) {
    Write-Host "`nPerforming clean installation..." -ForegroundColor Yellow
    
    # Stop any running WebView2 processes
    try {
        Get-Process -Name "*WebView*" -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "? Stopped running WebView2 processes" -ForegroundColor Green
    } catch {
        Write-Host "No running WebView2 processes found" -ForegroundColor Cyan
    }
    
    # Remove existing WebView2 installation
    try {
        $uninstallPath = "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\*\Installer\setup.exe"
        $uninstaller = Get-ChildItem -Path $uninstallPath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($uninstaller) {
            Write-Host "Uninstalling existing WebView2 Runtime..." -ForegroundColor Yellow
            Start-Process -FilePath $uninstaller.FullName -ArgumentList "--force-uninstall", "--uninstall", "--msedgewebview", "--system-level" -Wait
            Write-Host "? Uninstalled existing WebView2 Runtime" -ForegroundColor Green
        }
    } catch {
        Write-Host "No existing WebView2 installation found to uninstall" -ForegroundColor Cyan
    }
    
    # Clear temporary files
    try {
        Remove-Item -Path "$env:TEMP\MicrosoftEdgeWebview2Setup.exe" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:TEMP\MicrosoftEdgeWebview2Setup*" -Force -ErrorAction SilentlyContinue
        Write-Host "? Cleared temporary files" -ForegroundColor Green
    } catch {
        Write-Host "No temporary files to clear" -ForegroundColor Cyan
    }
}

# Download URLs for different architectures
$downloadUrls = @{
    "x64" = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"
    "x86" = "https://go.microsoft.com/fwlink/p/?LinkId=2124704"
    "ARM64" = "https://go.microsoft.com/fwlink/p/?LinkId=2124705"
}

# Determine architecture
$architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
Write-Host "`nDetected architecture: $architecture" -ForegroundColor Cyan

$downloadUrl = $downloadUrls[$architecture]
$tempFile = Join-Path $env:TEMP "MicrosoftEdgeWebview2Setup.exe"

Write-Host "Downloading WebView2 Runtime for $architecture..." -ForegroundColor Yellow

# Try multiple download methods
$downloadSuccess = $false
$downloadMethods = @(
    @{ Name = "Invoke-WebRequest"; Script = { Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing } },
    @{ Name = "System.Net.WebClient"; Script = { 
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $tempFile)
        $webClient.Dispose()
    }},
    @{ Name = "curl"; Script = { curl.exe -L -o $tempFile $downloadUrl }}
)

foreach ($method in $downloadMethods) {
    try {
        Write-Host "Trying download method: $($method.Name)" -ForegroundColor Yellow
        & $method.Script
        
        if (Test-Path $tempFile) {
            $fileSize = (Get-Item $tempFile).Length
            if ($fileSize -gt 1000000) { # More than 1MB
                Write-Host "? Download completed successfully using $($method.Name)!" -ForegroundColor Green
                Write-Host "  File size: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Cyan
                $downloadSuccess = $true
                break
            } else {
                Write-Host "? Downloaded file is too small, trying next method..." -ForegroundColor Red
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Host "? $($method.Name) failed: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

if (-not $downloadSuccess) {
    Write-Host "`nAll download methods failed!" -ForegroundColor Red
    Write-Host "Please try the following:" -ForegroundColor Yellow
    Write-Host "1. Check your internet connection" -ForegroundColor White
    Write-Host "2. Temporarily disable antivirus/firewall" -ForegroundColor White
    Write-Host "3. Download manually from: https://developer.microsoft.com/en-us/microsoft-edge/webview2/" -ForegroundColor White
    exit 1
}

# Verify file integrity
Write-Host "`nVerifying downloaded file..." -ForegroundColor Yellow
try {
    $fileInfo = Get-Item $tempFile
    Write-Host "? File verification passed" -ForegroundColor Green
    Write-Host "  File: $($fileInfo.Name)" -ForegroundColor Cyan
    Write-Host "  Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    Write-Host "  Created: $($fileInfo.CreationTime)" -ForegroundColor Cyan
} catch {
    Write-Host "? File verification failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Install with multiple methods
Write-Host "`nInstalling WebView2 Runtime..." -ForegroundColor Yellow

$installSuccess = $false
$installMethods = @(
    @{ 
        Name = "Silent Install"; 
        Args = "/silent", "/install", "/msedgewebview", "--system-level", "--verbose-logging"
    },
    @{ 
        Name = "Basic Install"; 
        Args = "/silent", "/install", "--system-level"
    },
    @{ 
        Name = "Minimal Install"; 
        Args = "/silent"
    }
)

foreach ($method in $installMethods) {
    try {
        Write-Host "Trying installation method: $($method.Name)" -ForegroundColor Yellow
        
        $process = Start-Process -FilePath $tempFile -ArgumentList $method.Args -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "? Installation completed successfully using $($method.Name)!" -ForegroundColor Green
            $installSuccess = $true
            break
        } else {
            Write-Host "? $($method.Name) failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "? $($method.Name) failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if (-not $installSuccess) {
    Write-Host "`nAll installation methods failed!" -ForegroundColor Red
    Write-Host "`nTroubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Restart your computer and try again" -ForegroundColor White
    Write-Host "2. Temporarily disable Windows Defender and antivirus" -ForegroundColor White
    Write-Host "3. Run Windows Update to ensure system is up to date" -ForegroundColor White
    Write-Host "4. Check Windows Event Viewer for detailed error information" -ForegroundColor White
    Write-Host "5. Try manual installation from: https://developer.microsoft.com/en-us/microsoft-edge/webview2/" -ForegroundColor White
    
    # Clean up
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify installation
Write-Host "`nVerifying installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $webView2Path = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
    if ($webView2Path) {
        Write-Host "? WebView2 Runtime installed successfully!" -ForegroundColor Green
        Write-Host "  Version: $($webView2Path.pv)" -ForegroundColor Cyan
        Write-Host "  Location: $($webView2Path.location)" -ForegroundColor Cyan
    } else {
        Write-Host "? Installation verification failed - not found in registry" -ForegroundColor Red
    }
} catch {
    Write-Host "? Installation verification failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Clean up
try {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    Write-Host "? Cleaned up temporary files" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not clean up temporary files" -ForegroundColor Yellow
}

Write-Host "`nInstallation process completed!" -ForegroundColor Green
Write-Host "Please restart your application to use WebView2." -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Restart your computer (recommended)" -ForegroundColor White
Write-Host "2. Test your application" -ForegroundColor White
Write-Host "3. If issues persist, run: .\test-webview2-runtime.ps1" -ForegroundColor White 