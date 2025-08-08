# Copy all CefSharp files to Revit Add-ins folder
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

if ($Verbose) {
    Write-Host "Copying CefSharp files from $SourcePath to $DestinationPath" -ForegroundColor Yellow
}

# Ensure destination directory exists
if (!(Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
}

# List of essential CefSharp files
$CefSharpFiles = @(
    "CefSharp.dll",
    "CefSharp.Core.dll", 
    "CefSharp.Core.Runtime.dll",
    "CefSharp.Wpf.dll",
    "CefSharp.BrowserSubprocess.exe",
    "CefSharp.BrowserSubprocess.Core.dll",
    "libcef.dll",
    "chrome_elf.dll",
    "libEGL.dll",
    "libGLESv2.dll",
    "d3dcompiler_47.dll",
    "icudtl.dat",
    "v8_context_snapshot.bin",
    "snapshot_blob.bin",
    "resources.pak",
    "chrome_100_percent.pak",
    "chrome_200_percent.pak",
    "vulkan-1.dll",
    "vk_swiftshader.dll",
    "vk_swiftshader_icd.json",
    "dxcompiler.dll",
    "dxil.dll"
)

# Copy essential files
foreach ($file in $CefSharpFiles) {
    $sourcefile = Join-Path $SourcePath $file
    if (Test-Path $sourcefile) {
        Copy-Item $sourcefile $DestinationPath -Force
        if ($Verbose) {
            Write-Host "? Copied: $file" -ForegroundColor Green
        }
    } else {
        if ($Verbose) {
            Write-Host "? Missing: $file" -ForegroundColor Yellow
        }
    }
}

# Copy locales folder
$LocalesSource = Join-Path $SourcePath "locales"
if (Test-Path $LocalesSource) {
    $LocalesDest = Join-Path $DestinationPath "locales"
    if (Test-Path $LocalesDest) {
        Remove-Item $LocalesDest -Recurse -Force
    }
    Copy-Item $LocalesSource $DestinationPath -Recurse -Force
    if ($Verbose) {
        Write-Host "? Copied: locales folder" -ForegroundColor Green
    }
}

Write-Host "CefSharp files copy completed!" -ForegroundColor Cyan 