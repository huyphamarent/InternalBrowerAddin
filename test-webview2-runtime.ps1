# Test script to check WebView2 Runtime availability
# This helps diagnose the "await webView.EnsureCoreWebView2Async(env); never return" issue

Write-Host "WebView2 Runtime Detection Test" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# Method 1: Check registry
Write-Host "`n1. Checking registry for WebView2 Runtime..." -ForegroundColor Yellow
try {
    $webView2Path = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
    if ($webView2Path) {
        Write-Host "? WebView2 Runtime found in registry" -ForegroundColor Green
        Write-Host "  Version: $($webView2Path.pv)" -ForegroundColor Cyan
    } else {
        Write-Host "? WebView2 Runtime not found in registry" -ForegroundColor Red
    }
} catch {
    Write-Host "? Error checking registry: $($_.Exception.Message)" -ForegroundColor Red
}

# Method 2: Check if WebView2 DLLs are available
Write-Host "`n2. Checking for WebView2 DLLs..." -ForegroundColor Yellow
$webView2Dlls = @(
    "Microsoft.Web.WebView2.Core.dll",
    "Microsoft.Web.WebView2.Wpf.dll",
    "WebView2Loader.dll"
)

foreach ($dll in $webView2Dlls) {
    $found = $false
    $paths = @(
        "$env:ProgramFiles\Microsoft\EdgeWebView\Application\*\*$dll",
        "$env:ProgramFiles(x86)\Microsoft\EdgeWebView\Application\*\*$dll",
        "$env:LOCALAPPDATA\Microsoft\EdgeWebView\Application\*\*$dll"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "? Found $dll" -ForegroundColor Green
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "? $dll not found" -ForegroundColor Red
    }
}

# Method 3: Check system architecture
Write-Host "`n3. System Information..." -ForegroundColor Yellow
$osArch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$procArch = if ([Environment]::Is64BitProcess) { "x64" } else { "x86" }
Write-Host "  OS Architecture: $osArch" -ForegroundColor Cyan
Write-Host "  Process Architecture: $procArch" -ForegroundColor Cyan
Write-Host "  OS Version: $([Environment]::OSVersion)" -ForegroundColor Cyan

# Method 4: Check .NET Framework
Write-Host "`n4. .NET Framework Information..." -ForegroundColor Yellow
try {
    $netVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    Write-Host "  Framework: $netVersion" -ForegroundColor Cyan
} catch {
    Write-Host "  Could not determine .NET Framework version" -ForegroundColor Yellow
}

# Method 5: Check user data folder permissions
Write-Host "`n5. Checking user data folder permissions..." -ForegroundColor Yellow
$userDataFolder = "$env:LOCALAPPDATA\RevitInternalBrowser\WebView2Data"
try {
    if (-not (Test-Path $userDataFolder)) {
        New-Item -ItemType Directory -Path $userDataFolder -Force | Out-Null
        Write-Host "? Created user data folder: $userDataFolder" -ForegroundColor Green
    } else {
        Write-Host "? User data folder exists: $userDataFolder" -ForegroundColor Green
    }
    
    # Test write permissions
    $testFile = Join-Path $userDataFolder "test.txt"
    "test" | Out-File -FilePath $testFile -Encoding UTF8
    Remove-Item $testFile -Force
    Write-Host "? Write permissions OK" -ForegroundColor Green
} catch {
    Write-Host "? Permission error: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n" + "="*50 -ForegroundColor Green
Write-Host "SUMMARY" -ForegroundColor Green
Write-Host "=======" -ForegroundColor Green

Write-Host "`nIf you see any '?' marks above, those indicate potential issues." -ForegroundColor Yellow
Write-Host "The most common cause of WebView2 hanging is missing runtime installation." -ForegroundColor Yellow

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. If WebView2 Runtime is missing, run: .\install-webview2-runtime.ps1" -ForegroundColor White
Write-Host "2. If permissions are an issue, run the application as Administrator" -ForegroundColor White
Write-Host "3. If DLLs are missing, reinstall WebView2 Runtime" -ForegroundColor White
Write-Host "4. Check the troubleshooting guide: WebView2-Troubleshooting.md" -ForegroundColor White 