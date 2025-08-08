# WebView2 Troubleshooting Guide

## Issue: `await webView.EnsureCoreWebView2Async(env);` never returns

This is a common issue with WebView2 initialization. Here are the most likely causes and solutions:

## Common Causes

### 1. Missing WebView2 Runtime
**Most Common Cause**: The Microsoft Edge WebView2 Runtime is not installed on the system.

**Solution**: 
- Download and install the WebView2 Runtime from: https://developer.microsoft.com/en-us/microsoft-edge/webview2/
- Or run the provided PowerShell script: `.\install-webview2-runtime.ps1`

### 2. Permission Issues
**Cause**: The application doesn't have sufficient permissions to create the user data folder or access the WebView2 runtime.

**Solutions**:
- Run the application as Administrator
- Check Windows Defender or antivirus settings
- Ensure the user has write permissions to `%LOCALAPPDATA%`

### 3. Corrupted WebView2 Installation
**Cause**: The WebView2 runtime installation is corrupted or incomplete.

**Solutions**:
- Uninstall WebView2 Runtime from Control Panel
- Restart the computer
- Reinstall WebView2 Runtime
- Clear the WebView2 user data folder: `%LOCALAPPDATA%\RevitInternalBrowser\WebView2Data`

### 4. Network/Firewall Issues
**Cause**: WebView2 needs internet access for initial setup and updates.

**Solutions**:
- Check firewall settings
- Ensure the application has internet access
- Try running on a different network

## Quick Fixes

### Method 1: Use the PowerShell Script
```powershell
# Run as Administrator
.\install-webview2-runtime.ps1
```

### Method 2: Manual Installation
1. Download WebView2 Runtime from Microsoft
2. Run the installer as Administrator
3. Restart your computer
4. Try the application again

### Method 3: Clear WebView2 Data
```powershell
# Remove WebView2 user data (this will reset browser settings)
Remove-Item "$env:LOCALAPPDATA\RevitInternalBrowser\WebView2Data" -Recurse -Force
```

## Debugging

### Check WebView2 Runtime Availability
The application now includes runtime detection. If you see an error message about missing WebView2 Runtime, follow the installation instructions.

### Enable Debug Logging
The application includes debug logging. Check the Output window in Visual Studio for messages like:
- "WebView2 environment created successfully"
- "WebView2 initialized successfully"
- "WebView2 user data folder: [path]"

### Timeout Handling
The application now includes 30-second timeouts for WebView2 initialization. If you see timeout errors, it indicates:
- Slow system performance
- Network connectivity issues
- Antivirus interference

## System Requirements

- Windows 10 version 1803 or later
- Windows Server 2019 or later
- .NET Framework 4.8 or later
- Microsoft Edge WebView2 Runtime

## Additional Resources

- [WebView2 Documentation](https://docs.microsoft.com/en-us/microsoft-edge/webview2/)
- [WebView2 Runtime Download](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
- [WebView2 Troubleshooting](https://docs.microsoft.com/en-us/microsoft-edge/webview2/concepts/troubleshooting)

## Code Changes Made

The following improvements have been implemented to prevent the "never return" issue:

1. **Timeout Handling**: Added 30-second timeouts for both environment creation and WebView2 initialization
2. **Runtime Detection**: Added checks to verify WebView2 runtime is available before attempting initialization
3. **Better Error Messages**: More descriptive error messages with installation instructions
4. **Graceful Degradation**: The application will show helpful error messages instead of hanging indefinitely

## Testing

To test if the fix works:

1. Build and run the application
2. If WebView2 Runtime is missing, you should see a clear error message
3. Install WebView2 Runtime using the provided script
4. Restart the application
5. The browser should now initialize properly

If you still experience issues, please check the debug output and system requirements. 