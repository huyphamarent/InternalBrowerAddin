@echo off
echo RevitInternalBrowser Quick Build Script
echo.

:: Set default configuration
set CONFIG=Debug
set REVIT_VERSION=2024

:: Parse command line arguments
if "%1"=="release" set CONFIG=Release
if "%1"=="Release" set CONFIG=Release
if "%2"=="2026" set REVIT_VERSION=2026

echo Building %CONFIG% configuration for Revit %REVIT_VERSION%...
echo.

:: Run PowerShell build script
powershell -ExecutionPolicy Bypass -File "build.ps1" -Configuration %CONFIG% -RevitVersion %REVIT_VERSION% -Register

if errorlevel 1 (
    echo.
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Build completed! Check Revit %REVIT_VERSION% for the Browser add-in.
pause 