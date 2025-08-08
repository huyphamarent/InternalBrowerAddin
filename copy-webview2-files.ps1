# PowerShell script to copy WebView2 runtime files
# This helps resolve missing WebView2Loader.dll and other runtime files

param(
    [string]$OutputPath = ".\RevitInternalBrowserLib\bin\Debug None Auth 2024"
)

Write-Host "WebView2 Runtime Files Copier" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# Check if output path exists
if (-not (Test-Path $OutputPath)) {
    Write-Host "Creating output directory: $OutputPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Define WebView2 runtime locations to check
$webView2Locations = @(
    "$env:ProgramFiles\Microsoft\EdgeWebView\Application\*\*",
    "$env:ProgramFiles(x86)\Microsoft\EdgeWebView\Application\*\*",
    "$env:LOCALAPPDATA\Microsoft\EdgeWebView\Application\*\*",
    "$env:ProgramFiles\Microsoft\Edge\Application\*\*",
    "$env:ProgramFiles(x86)\Microsoft\Edge\Application\*\*"
)

# Files we need to copy
$requiredFiles = @(
    "WebView2Loader.dll",
    "Microsoft.Web.WebView2.Core.dll",
    "Microsoft.Web.WebView2.Wpf.dll"
)

Write-Host "`nSearching for WebView2 runtime files..." -ForegroundColor Yellow

$foundFiles = @()
$missingFiles = @()

foreach ($file in $requiredFiles) {
    $found = $false
    foreach ($location in $webView2Locations) {
        $filePath = Get-ChildItem -Path $location -Name $file -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($filePath) {
            $fullPath = Join-Path $location $filePath
            $foundFiles += @{
                Name = $file
                Source = $fullPath
            }
            $found = $true
            Write-Host "? Found $file at: $fullPath" -ForegroundColor Green
            break
        }
    }
    
    if (-not $found) {
        $missingFiles += $file
        Write-Host "? $file not found" -ForegroundColor Red
    }
}

# Copy found files
if ($foundFiles.Count -gt 0) {
    Write-Host "`nCopying WebView2 runtime files..." -ForegroundColor Yellow
    
    foreach ($file in $foundFiles) {
        $destination = Join-Path $OutputPath $file.Name
        try {
            Copy-Item -Path $file.Source -Destination $destination -Force
            Write-Host "? Copied $($file.Name) to output directory" -ForegroundColor Green
        } catch {
            Write-Host "? Failed to copy $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nNo WebView2 runtime files found to copy!" -ForegroundColor Red
}

# Check for missing files
if ($missingFiles.Count -gt 0) {
    Write-Host "`nMissing files:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Red
    }
    
    Write-Host "`nTo resolve missing files:" -ForegroundColor Yellow
    Write-Host "1. Install WebView2 Runtime: .\install-webview2-runtime.ps1" -ForegroundColor White
    Write-Host "2. Or download manually from: https://developer.microsoft.com/en-us/microsoft-edge/webview2/" -ForegroundColor White
}

# Check if we need to copy runtime folders
$runtimeFolders = @(
    "runtimes",
    "locales"
)

Write-Host "`nChecking for runtime folders..." -ForegroundColor Yellow

foreach ($folder in $runtimeFolders) {
    foreach ($location in $webView2Locations) {
        $folderPath = Get-ChildItem -Path $location -Directory -Name $folder -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($folderPath) {
            $sourceFolder = Join-Path $location $folderPath
            $destFolder = Join-Path $OutputPath $folder
            
            try {
                if (Test-Path $destFolder) {
                    Remove-Item $destFolder -Recurse -Force
                }
                Copy-Item -Path $sourceFolder -Destination $destFolder -Recurse -Force
                Write-Host "? Copied $folder folder" -ForegroundColor Green
                break
            } catch {
                Write-Host "? Failed to copy $folder folder: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`nWebView2 runtime files copy operation completed!" -ForegroundColor Green
Write-Host "Output directory: $OutputPath" -ForegroundColor Cyan 