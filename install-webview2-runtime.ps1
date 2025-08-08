# PowerShell script to install Microsoft Edge WebView2 Runtime
# This script helps resolve the "await webView.EnsureCoreWebView2Async(env); never return" issue

param(
    [switch]$Silent,
    [switch]$Force
)

Write-Host "Microsoft Edge WebView2 Runtime Installer" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Check if WebView2 runtime is already installed
Write-Host "Checking if WebView2 Runtime is already installed..." -ForegroundColor Yellow

try {
    $webView2Path = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
    if ($webView2Path) {
        Write-Host "WebView2 Runtime is already installed!" -ForegroundColor Green
        if (-not $Force) {
            Write-Host "Use -Force to reinstall anyway." -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Host "WebView2 Runtime not found in registry." -ForegroundColor Red
}

# Download URLs for different architectures
$downloadUrls = @{
    "x64" = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"
    "x86" = "https://go.microsoft.com/fwlink/p/?LinkId=2124704"
    "ARM64" = "https://go.microsoft.com/fwlink/p/?LinkId=2124705"
}

# Determine architecture
$architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
Write-Host "Detected architecture: $architecture" -ForegroundColor Cyan

$downloadUrl = $downloadUrls[$architecture]
$tempFile = Join-Path $env:TEMP "MicrosoftEdgeWebview2Setup.exe"

Write-Host "Downloading WebView2 Runtime for $architecture..." -ForegroundColor Yellow

try {
    # Download the installer
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
    
    if (Test-Path $tempFile) {
        Write-Host "Download completed successfully!" -ForegroundColor Green
        Write-Host "Installing WebView2 Runtime..." -ForegroundColor Yellow
        
        # Install with appropriate parameters
        $installArgs = "/silent"
        if ($Silent) {
            $installArgs = "/silent /install"
        }
        
        Start-Process -FilePath $tempFile -ArgumentList $installArgs -Wait -PassThru
        
        Write-Host "Installation completed!" -ForegroundColor Green
        Write-Host "Please restart your application to use WebView2." -ForegroundColor Cyan
        
        # Clean up
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Failed to download WebView2 Runtime installer." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error during download/installation: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please download manually from: https://developer.microsoft.com/en-us/microsoft-edge/webview2/" -ForegroundColor Yellow
    exit 1
}

Write-Host "`nTroubleshooting tips:" -ForegroundColor Cyan
Write-Host "1. If you still have issues, try running as Administrator" -ForegroundColor White
Write-Host "2. Make sure Windows is up to date" -ForegroundColor White
Write-Host "3. Check Windows Defender or antivirus isn't blocking the installation" -ForegroundColor White
Write-Host "4. For more help, visit: https://docs.microsoft.com/en-us/microsoft-edge/webview2/" -ForegroundColor White 