# RevitInternalBrowser Build Script
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("2024", "2026")]
    [string]$RevitVersion = "2024",
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean,
    
    [Parameter(Mandatory=$false)]
    [switch]$Register
)

$ErrorActionPreference = "Stop"

# Set build configuration
$BuildConfig = "$Configuration None Auth $RevitVersion"

Write-Host "Building RevitInternalBrowser for $BuildConfig..." -ForegroundColor Green

try {
    # Clean if requested
    if ($Clean) {
        Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
        dotnet clean --configuration "$BuildConfig" --verbosity minimal
        if ($LASTEXITCODE -ne 0) { throw "Clean failed" }
    }

    # Build the project
    Write-Host "Building project..." -ForegroundColor Yellow
    dotnet build --configuration "$BuildConfig" --verbosity minimal
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }

    # Get output directory
    $OutputDir = "bin\$Configuration\None Auth\$RevitVersion"
    $AddinFile = "$OutputDir\RevitInternalBrowser.addin"
    $DllFile = "$OutputDir\RevitInternalBrowser.dll"

    if (Test-Path $AddinFile) {
        Write-Host "Build successful! Output in: $OutputDir" -ForegroundColor Green
        
        # Register add-in if requested or if running in Release mode
        if ($Register -or $Configuration -eq "Release") {
            Write-Host "Registering add-in with Revit $RevitVersion..." -ForegroundColor Yellow
            
            $RevitAddinsPath = "$env:ProgramData\Autodesk\Revit\Addins\$RevitVersion"
            
            # Create directory if it doesn't exist
            if (!(Test-Path $RevitAddinsPath)) {
                New-Item -ItemType Directory -Path $RevitAddinsPath -Force | Out-Null
            }
            
            # Copy main add-in files
            Copy-Item $AddinFile $RevitAddinsPath -Force
            Copy-Item $DllFile $RevitAddinsPath -Force
            
            # Copy other managed dependencies
            Get-ChildItem "$OutputDir\*.dll" | Where-Object { 
                $_.Name -ne "RevitInternalBrowser.dll" -and 
                !$_.Name.StartsWith("CefSharp") -and
                !$_.Name.StartsWith("libcef") -and
                !$_.Name.StartsWith("lib") -and
                !$_.Name.StartsWith("chrome") -and
                !$_.Name.StartsWith("d3d") -and
                !$_.Name.StartsWith("dx") -and
                !$_.Name.StartsWith("vk") -and
                !$_.Name.StartsWith("vulkan")
            } | ForEach-Object {
                Copy-Item $_.FullName $RevitAddinsPath -Force
                Write-Host "Copied: $($_.Name)" -ForegroundColor Gray
            }
            
            # Copy all CefSharp files using dedicated script
            Write-Host "Copying CefSharp dependencies..." -ForegroundColor Yellow
            & "$PSScriptRoot\copy-cef-files.ps1" -SourcePath $OutputDir -DestinationPath $RevitAddinsPath -Verbose
            
            Write-Host "Add-in registered successfully!" -ForegroundColor Green
            Write-Host "Add-in files copied to: $RevitAddinsPath" -ForegroundColor Cyan
        }
    } else {
        throw "Build completed but add-in file not found: $AddinFile"
    }
    
} catch {
    Write-Host "Build failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild completed successfully!" -ForegroundColor Green
Write-Host "To run in Revit $RevitVersion, start Revit and look for the 'Browser' tab." -ForegroundColor Cyan 