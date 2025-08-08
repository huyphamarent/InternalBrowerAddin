@echo off
echo Fixing CefSharp file dependencies for RevitInternalBrowser...
echo.

set SOURCE_DIR=bin\Debug\None Auth\2024
set DEST_DIR=C:\ProgramData\Autodesk\Revit\Addins\2024

echo Checking if Revit is running...
tasklist /FI "IMAGENAME eq Revit.exe" 2>NUL | find /I /N "Revit.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo WARNING: Revit is currently running! Please close Revit before running this script.
    pause
    exit /b 1
)

echo Copying essential CefSharp files...

:: Copy main DLL
copy "%SOURCE_DIR%\RevitInternalBrowser.dll" "%DEST_DIR%\" /Y

:: Copy CefSharp DLLs
copy "%SOURCE_DIR%\CefSharp.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\CefSharp.Core.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\CefSharp.Core.Runtime.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\CefSharp.Wpf.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\CefSharp.BrowserSubprocess.exe" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\CefSharp.BrowserSubprocess.Core.dll" "%DEST_DIR%\" /Y

:: Copy CEF native libraries
copy "%SOURCE_DIR%\libcef.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\chrome_elf.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\libEGL.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\libGLESv2.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\d3dcompiler_47.dll" "%DEST_DIR%\" /Y

:: Copy essential data files
copy "%SOURCE_DIR%\icudtl.dat" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\v8_context_snapshot.bin" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\snapshot_blob.bin" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\resources.pak" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\chrome_100_percent.pak" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\chrome_200_percent.pak" "%DEST_DIR%\" /Y

:: Copy locales folder
if exist "%SOURCE_DIR%\locales" (
    echo Copying locales folder...
    xcopy "%SOURCE_DIR%\locales" "%DEST_DIR%\locales\" /E /I /Y
)

:: Copy other managed dependencies
copy "%SOURCE_DIR%\Newtonsoft.Json.dll" "%DEST_DIR%\" /Y
copy "%SOURCE_DIR%\Microsoft.Xaml.Behaviors.dll" "%DEST_DIR%\" /Y

echo.
echo ? CefSharp files have been copied successfully!
echo.
echo You can now start Revit and test the browser add-in.
echo If you still get errors, check the CefSharp log at:
echo %LOCALAPPDATA%\RevitInternalBrowser\Logs\cef.log
echo.
pause 