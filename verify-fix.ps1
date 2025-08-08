# Verification script for RevitInternalBrowser fix
Write-Host "Verifying RevitInternalBrowser fix..." -ForegroundColor Green

$outputDir = "RevitInternalBrowserAddin\bin\Debug\None Auth\2024"

# Check if output directory exists
if (-not (Test-Path $outputDir)) {
    Write-Host "ERROR: Output directory not found: $outputDir" -ForegroundColor Red
    exit 1
}

Write-Host "Checking required files in: $outputDir" -ForegroundColor Yellow

# Check for RevitInternalBrowserLib.dll
$libDll = "$outputDir\RevitInternalBrowserLib.dll"
if (Test-Path $libDll) {
    $fileInfo = Get-Item $libDll
    Write-Host "? RevitInternalBrowserLib.dll found: $($fileInfo.Length) bytes" -ForegroundColor Green
} else {
    Write-Host "? RevitInternalBrowserLib.dll NOT FOUND" -ForegroundColor Red
}

# Check for CefSharp.Core.Runtime.dll
$cefDll = "$outputDir\CefSharp.Core.Runtime.dll"
if (Test-Path $cefDll) {
    $fileInfo = Get-Item $cefDll
    Write-Host "? CefSharp.Core.Runtime.dll found: $($fileInfo.Length) bytes" -ForegroundColor Green
    
    # Check if it's the correct size (should be ~2MB for x64)
    if ($fileInfo.Length -gt 1500000) {
        Write-Host "? CefSharp.Core.Runtime.dll appears to be x64 version" -ForegroundColor Green
    } else {
        Write-Host "??  CefSharp.Core.Runtime.dll size seems small, may be x86 version" -ForegroundColor Yellow
    }
} else {
    Write-Host "? CefSharp.Core.Runtime.dll NOT FOUND" -ForegroundColor Red
}

# Check for main add-in DLL
$mainDll = "$outputDir\RevitInternalBrowser.dll"
if (Test-Path $mainDll) {
    $fileInfo = Get-Item $mainDll
    Write-Host "? RevitInternalBrowser.dll found: $($fileInfo.Length) bytes" -ForegroundColor Green
} else {
    Write-Host "? RevitInternalBrowser.dll NOT FOUND" -ForegroundColor Red
}

# Check for .addin file
$addinFile = "$outputDir\RevitInternalBrowser.addin"
if (Test-Path $addinFile) {
    Write-Host "? RevitInternalBrowser.addin found" -ForegroundColor Green
} else {
    Write-Host "? RevitInternalBrowser.addin NOT FOUND" -ForegroundColor Red
}

# List all CefSharp files
Write-Host "`nCefSharp files present:" -ForegroundColor Yellow
Get-ChildItem "$outputDir\CefSharp*" | ForEach-Object {
    Write-Host "  $($_.Name)" -ForegroundColor Cyan
}

Write-Host "`nVerification completed!" -ForegroundColor Green 