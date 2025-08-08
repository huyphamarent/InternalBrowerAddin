# RevitInternalBrowser

A powerful internal web browser add-in for Autodesk Revit with Chrome-like features including multi-tab browsing, session persistence, and full web functionality.

## Features

### ? Multi-Tab Browsing
- Multiple tabs with Chrome-like interface
- Tab management (open, close, switch between tabs)
- Tab titles update dynamically based on page content

### ? Chrome-Like Navigation
- Back, forward, and refresh buttons
- Address bar with URL auto-completion
- Chrome-style UI with rounded buttons and modern design

### ? Session Persistence
- Automatically saves and restores browser sessions
- Login sessions persist between browser window closures
- Profile data stored in user's local application data

### ? Powered by CefSharp
- Full Chromium web engine integration
- Modern web standards support (HTML5, CSS3, JavaScript)
- GPU acceleration for smooth performance

## Requirements

- **Autodesk Revit**: 2024 or 2026
- **.NET Framework**: 4.8
- **Windows**: 10 or 11 (x64)
- **Visual Studio** or **JetBrains Rider** (for development)

## Installation

### Option 1: Quick Build (Recommended)
1. Clone or download this repository
2. Run `build.cmd` for default settings (Debug, Revit 2024)
3. Or run `build.cmd release 2026` for Release build with Revit 2026
4. The add-in will be automatically registered with Revit

### Option 2: Manual Build
1. Open `RevitInternalBrowser.sln` in Visual Studio or Rider
2. Select your target configuration:
   - `Debug None Auth 2024` or `Release None Auth 2024` for Revit 2024
   - `Debug None Auth 2026` or `Release None Auth 2026` for Revit 2026
3. Build the solution
4. The post-build script will automatically copy files to Revit's add-ins folder

### Option 3: PowerShell Build Script
```powershell
# Debug build for Revit 2024
.\build.ps1 -Configuration Debug -RevitVersion 2024 -Register

# Release build for Revit 2026
.\build.ps1 -Configuration Release -RevitVersion 2026 -Register
```

## Usage

1. Start Autodesk Revit (2024 or 2026)
2. Look for the **"Browser"** tab in the Revit ribbon
3. Click the **"Open Browser"** button (Chrome icon)
4. The browser window will open with a default Google homepage

### Browser Controls

- **New Tab**: Click the `+` button in the tab bar
- **Close Tab**: Click the `~` button on any tab
- **Navigate**: Use back (`?`), forward (`?`), and refresh (`?`) buttons
- **Address Bar**: Type URLs and press Enter to navigate
- **Menu**: Click the menu button (`?`) for additional options

### Session Management

- Browser automatically saves your session when you close the window
- When you reopen the browser, all previous tabs and their URLs will be restored
- Login sessions are preserved between browser window closures

## Development

### Project Structure
```
RevitInternalBrowser/
„¥„Ÿ„Ÿ Application.cs              # Main Revit add-in application
„¥„Ÿ„Ÿ Commands/
„�?   „¤„Ÿ„Ÿ OpenBrowserCommand.cs   # Command to open browser window
„¥„Ÿ„Ÿ Views/
„�?   „¥„Ÿ„Ÿ BrowserWindow.xaml      # Main browser window UI
„�?   „¤„Ÿ„Ÿ BrowserWindow.xaml.cs   # Browser window code-behind
„¥„Ÿ„Ÿ Models/
„�?   „¥„Ÿ„Ÿ BrowserTab.cs           # Browser tab data model
„�?   „¤„Ÿ„Ÿ SessionData.cs          # Session persistence models
„¥„Ÿ„Ÿ Resources/                  # Icon files (placeholder)
„¥„Ÿ„Ÿ RevitInternalBrowser.csproj # Project file
„¥„Ÿ„Ÿ RevitInternalBrowser.sln    # Solution file
„¥„Ÿ„Ÿ build.ps1                   # PowerShell build script
„¥„Ÿ„Ÿ build.cmd                   # Windows batch build script
„¤„Ÿ„Ÿ README.md                   # This file
```

### Building for Different Revit Versions

The project supports multiple Revit versions through configuration-based builds:

- **Revit 2024**: Uses `Debug None Auth 2024` or `Release None Auth 2024`
- **Revit 2026**: Uses `Debug None Auth 2026` or `Release None Auth 2026`

### Adding Icons

Replace the placeholder files in the `Resources/` folder with actual PNG icons:

- `chrome-icon-16.png` - 16x16 Chrome icon for ribbon button
- `chrome-icon-32.png` - 32x32 Chrome icon for ribbon button
- `back-icon.png` - Back navigation icon
- `forward-icon.png` - Forward navigation icon
- `refresh-icon.png` - Refresh/reload icon
- `close-tab-icon.png` - Close tab icon
- `new-tab-icon.png` - New tab icon

You can download Chrome icons from [icon-icons.com](https://icon-icons.com/search/icons/chrome).

### IDE Compatibility

This project is fully compatible with:
- **JetBrains Rider** (recommended)
- **Visual Studio 2022**
- **Visual Studio Code** (with C# extension)

## Configuration

### Cache and User Data

Browser data is stored in:
```
%LOCALAPPDATA%\RevitInternalBrowser\
„¥„Ÿ„Ÿ Cache/           # Browser cache files
„¥„Ÿ„Ÿ UserData/        # User profile data
„¥„Ÿ„Ÿ Profiles/        # Session data
„�?   „¤„Ÿ„Ÿ default.json # Default session file
„¤„Ÿ„Ÿ Logs/            # CefSharp logs
    „¤„Ÿ„Ÿ cef.log      # CEF debug log
```

### Profile Management

Session data includes:
- Open tabs and their URLs
- Active tab selection
- Tab titles

To reset the browser to default state, delete the `Profiles` folder.

## Troubleshooting

### Common Issues

1. **Add-in not appearing in Revit**
   - Check that the correct Revit version is targeted
   - Verify files are copied to `%ProgramData%\Autodesk\Revit\Addins\{version}\`
   - Restart Revit completely

2. **CefSharp could not be loaded error**
   - **This is the most common issue!** CefSharp has many native dependencies
   - Close Revit completely
   - Run `fix-cefsharp-files.cmd` to copy all required files
   - Ensure all these files are in `%ProgramData%\Autodesk\Revit\Addins\{version}\`:
     - All `CefSharp*.dll` files
     - `libcef.dll`, `chrome_elf.dll`, `libEGL.dll`, `libGLESv2.dll`
     - `icudtl.dat`, `v8_context_snapshot.bin`, `snapshot_blob.bin`
     - `resources.pak`, `chrome_100_percent.pak`, `chrome_200_percent.pak`
     - `locales` folder with locale files

3. **Browser window not opening**
   - Check Windows Event Viewer for .NET application errors
   - Ensure CefSharp dependencies are properly installed
   - Verify .NET Framework 4.8 is installed
   - Check CefSharp log: `%LOCALAPPDATA%\RevitInternalBrowser\Logs\cef.log`

4. **CefSharp initialization errors**
   - Clear the cache folder: `%LOCALAPPDATA%\RevitInternalBrowser\Cache\`
   - Check antivirus software isn't blocking CefSharp
   - Ensure sufficient disk space for cache
   - Verify all CefSharp files are present (see issue #2 above)

### Debug Mode

For debugging, use the Debug configuration which includes:
- Extended logging
- Debug symbols
- CefSharp debug console access

### Build Errors

If build fails:
1. Clean the solution: `dotnet clean`
2. Restore NuGet packages: `dotnet restore`
3. Rebuild: `dotnet build`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is provided as-is for educational and development purposes. 

## Acknowledgments

- **CefSharp** - Chromium browser integration
- **Nice3point** - Revit API NuGet packages
- **Autodesk** - Revit API and platform 