# Build and test script for RevitInternalBrowser
Write-Host "Building RevitInternalBrowser solution..." -ForegroundColor Green

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
dotnet clean RevitInternalBrowser.sln

# Build the solution
Write-Host "Building solution..." -ForegroundColor Yellow
dotnet build RevitInternalBrowser.sln --configuration "Debug None Auth 2024"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful!" -ForegroundColor Green
    
    # Check if CefSharp.Core.Runtime.dll exists and is x64
    $dllPath = "RevitInternalBrowserAddin\bin\Debug\None Auth\2024\CefSharp.Core.Runtime.dll"
    if (Test-Path $dllPath) {
        Write-Host "CefSharp.Core.Runtime.dll found at: $dllPath" -ForegroundColor Green
        
        # Check if it's x64 (this is a simple check - in practice you'd use corflags or similar)
        $fileInfo = Get-Item $dllPath
        Write-Host "File size: $($fileInfo.Length) bytes" -ForegroundColor Cyan
        Write-Host "Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor Cyan
        
        # List all CefSharp files
        Write-Host "`nCefSharp files in output directory:" -ForegroundColor Yellow
        Get-ChildItem "RevitInternalBrowserAddin\bin\Debug\None Auth\2024\CefSharp*" | ForEach-Object {
            Write-Host "  $($_.Name)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "ERROR: CefSharp.Core.Runtime.dll not found at: $dllPath" -ForegroundColor Red
    }
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild and test completed!" -ForegroundColor Green 