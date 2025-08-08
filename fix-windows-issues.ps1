# Windows System Fix Script - Resolves common issues causing WebView2 installation failures
# This script addresses issues that can cause error 0x80040c01

param(
    [switch]$FixAll,
    [switch]$CheckOnly
)

Write-Host "Windows System Fix Script" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nChecking system health..." -ForegroundColor Yellow

# 1. Check Windows Update service
Write-Host "`n1. Checking Windows Update service..." -ForegroundColor Cyan
try {
    $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuService) {
        Write-Host "  Status: $($wuService.Status)" -ForegroundColor $(if ($wuService.Status -eq "Running") { "Green" } else { "Red" })
        Write-Host "  Startup Type: $($wuService.StartType)" -ForegroundColor Cyan
        
        if ($wuService.Status -ne "Running" -and $FixAll) {
            Write-Host "  Starting Windows Update service..." -ForegroundColor Yellow
            Start-Service -Name "wuauserv"
            Set-Service -Name "wuauserv" -StartupType Automatic
            Write-Host "  ? Windows Update service started" -ForegroundColor Green
        }
    } else {
        Write-Host "  ? Windows Update service not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  ? Error checking Windows Update service: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Check Windows Installer service
Write-Host "`n2. Checking Windows Installer service..." -ForegroundColor Cyan
try {
    $msiService = Get-Service -Name "msiserver" -ErrorAction SilentlyContinue
    if ($msiService) {
        Write-Host "  Status: $($msiService.Status)" -ForegroundColor $(if ($msiService.Status -eq "Running") { "Green" } else { "Red" })
        
        if ($msiService.Status -ne "Running" -and $FixAll) {
            Write-Host "  Starting Windows Installer service..." -ForegroundColor Yellow
            Start-Service -Name "msiserver"
            Write-Host "  ? Windows Installer service started" -ForegroundColor Green
        }
    } else {
        Write-Host "  ? Windows Installer service not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  ? Error checking Windows Installer service: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Check disk space
Write-Host "`n3. Checking disk space..." -ForegroundColor Cyan
try {
    $systemDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
    $totalSpaceGB = [math]::Round($systemDrive.Size / 1GB, 2)
    $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
    $usagePercent = [math]::Round(($usedSpaceGB / $totalSpaceGB) * 100, 1)
    
    Write-Host "  Total Space: $totalSpaceGB GB" -ForegroundColor Cyan
    Write-Host "  Used Space: $usedSpaceGB GB ($usagePercent%)" -ForegroundColor Cyan
    Write-Host "  Free Space: $freeSpaceGB GB" -ForegroundColor $(if ($freeSpaceGB -gt 5) { "Green" } else { "Red" })
    
    if ($freeSpaceGB -lt 5) {
        Write-Host "  ? Warning: Low disk space may cause installation issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ? Error checking disk space: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Check Windows version and updates
Write-Host "`n4. Checking Windows version..." -ForegroundColor Cyan
try {
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    Write-Host "  Version: $($osInfo.Caption)" -ForegroundColor Cyan
    Write-Host "  Build: $($osInfo.BuildNumber)" -ForegroundColor Cyan
    Write-Host "  Service Pack: $($osInfo.ServicePackMajorVersion)" -ForegroundColor Cyan
    
    # Check if Windows is up to date
    if ($FixAll) {
        Write-Host "  Checking for Windows updates..." -ForegroundColor Yellow
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0")
            
            if ($searchResult.Updates.Count -gt 0) {
                Write-Host "  Found $($searchResult.Updates.Count) pending updates" -ForegroundColor Yellow
                Write-Host "  Consider running Windows Update before installing WebView2" -ForegroundColor Yellow
            } else {
                Write-Host "  ? Windows appears to be up to date" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ? Could not check for Windows updates" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  ? Error checking Windows version: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Check for corrupted system files
Write-Host "`n5. Checking for corrupted system files..." -ForegroundColor Cyan
if ($FixAll) {
    Write-Host "  Running System File Checker..." -ForegroundColor Yellow
    try {
        $sfcResult = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
        if ($sfcResult.ExitCode -eq 0) {
            Write-Host "  ? System File Checker completed successfully" -ForegroundColor Green
        } else {
            Write-Host "  ? System File Checker found issues (Exit code: $($sfcResult.ExitCode))" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ? Error running System File Checker: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  Use -FixAll to run System File Checker" -ForegroundColor Yellow
}

# 6. Check DISM health
Write-Host "`n6. Checking DISM health..." -ForegroundColor Cyan
if ($FixAll) {
    Write-Host "  Running DISM health check..." -ForegroundColor Yellow
    try {
        $dismResult = Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/CheckHealth" -Wait -PassThru -NoNewWindow
        if ($dismResult.ExitCode -eq 0) {
            Write-Host "  ? DISM health check passed" -ForegroundColor Green
        } else {
            Write-Host "  ? DISM health check found issues (Exit code: $($dismResult.ExitCode))" -ForegroundColor Yellow
            Write-Host "  Running DISM restore health..." -ForegroundColor Yellow
            Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/RestoreHealth" -Wait -NoNewWindow
        }
    } catch {
        Write-Host "  ? Error running DISM: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  Use -FixAll to run DISM health check" -ForegroundColor Yellow
}

# 7. Check antivirus status
Write-Host "`n7. Checking antivirus status..." -ForegroundColor Cyan
try {
    $antivirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
    if ($antivirusProducts) {
        foreach ($av in $antivirusProducts) {
            Write-Host "  Product: $($av.displayName)" -ForegroundColor Cyan
            Write-Host "  Status: $($av.productState)" -ForegroundColor $(if ($av.productState -eq 262144) { "Green" } else { "Yellow" })
        }
        Write-Host "  ? Consider temporarily disabling antivirus during WebView2 installation" -ForegroundColor Yellow
    } else {
        Write-Host "  ? Could not detect antivirus products" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ? Could not check antivirus status" -ForegroundColor Yellow
}

# 8. Check registry permissions
Write-Host "`n8. Checking registry permissions..." -ForegroundColor Cyan
try {
    $testKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $acl = Get-Acl $testKey
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    
    $hasAccess = $false
    foreach ($rule in $acl.Access) {
        if ($rule.IdentityReference -eq $currentUser -and $rule.AccessControlType -eq "Allow") {
            $hasAccess = $true
            break
        }
    }
    
    if ($hasAccess) {
        Write-Host "  ? Registry access permissions OK" -ForegroundColor Green
    } else {
        Write-Host "  ? Registry access permissions may be restricted" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ? Error checking registry permissions: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary and recommendations
Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "SYSTEM HEALTH SUMMARY" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

Write-Host "`nRecommendations:" -ForegroundColor Cyan
Write-Host "1. If any services were not running, they have been started" -ForegroundColor White
Write-Host "2. If System File Checker found issues, restart your computer" -ForegroundColor White
Write-Host "3. If DISM found issues, restart your computer after it completes" -ForegroundColor White
Write-Host "4. Temporarily disable antivirus before installing WebView2" -ForegroundColor White
Write-Host "5. Ensure you have at least 5GB free disk space" -ForegroundColor White

if ($FixAll) {
    Write-Host "`nSystem fixes have been applied. Please restart your computer before" -ForegroundColor Green
    Write-Host "attempting to install WebView2 Runtime again." -ForegroundColor Green
} else {
    Write-Host "`nRun with -FixAll to apply automatic fixes to common issues." -ForegroundColor Yellow
}

Write-Host "`nAfter restarting, try installing WebView2 Runtime again:" -ForegroundColor Cyan
Write-Host "  .\install-webview2-runtime-fixed.ps1 -CleanInstall" -ForegroundColor White 