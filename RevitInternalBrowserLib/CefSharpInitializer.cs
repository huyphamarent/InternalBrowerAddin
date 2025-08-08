using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows;

#if REVIT2024
using CefSharp;
using CefSharp.Wpf;
#endif

#if REVIT2026
using CefSharp;
using CefSharp.Wpf;
#endif

namespace RevitInternalBrowserLib
{
#if REVIT2024 || REVIT2026
    public static class CefSharpInitializer
    {
        private static bool _isInitialized = false;
        private static readonly object _lockObject = new object();

        public static void Initialize()
        {
            lock (_lockObject)
            {
                if (_isInitialized) return;

                try
                {
                    // Check if CefSharp is already initialized (by Revit)
                    if (Cef.IsInitialized == true)
                    {
                        System.Diagnostics.Debug.WriteLine("CefSharp is already initialized by Revit. Skipping initialization.");
                        _isInitialized = true;
                        return;
                    }

                    // Get the directory where our assembly is loaded from
                    var assemblyDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                    
                    // Try to find the CefSharp.BrowserSubprocess.exe in multiple possible locations
//                     var browserSubprocessPath = "";
//                     var possiblePaths = new[]
//                     {
//                         Path.Combine(assemblyDirectory ?? "", "CefSharp.BrowserSubprocess.exe"),
//                         Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CefSharp.BrowserSubprocess.exe")
//                     };
//                     
//                     foreach (var path in possiblePaths)
//                     {
//                         if (!string.IsNullOrEmpty(path) && File.Exists(path))
//                         {
//                             browserSubprocessPath = path;
//                             break;
//                         }
//                     }
//                     
//                     if (string.IsNullOrEmpty(browserSubprocessPath))
//                     {
//                         var searchedPaths = string.Join("\n", possiblePaths.Where(p => !string.IsNullOrEmpty(p)));
//                         throw new FileNotFoundException($"CefSharp.BrowserSubprocess.exe not found in any of these locations:\n{searchedPaths}");
//                     }
//                     
//                     // Log the found path for debugging
//                     System.Diagnostics.Debug.WriteLine($"CefSharp.BrowserSubprocess.exe found at: {browserSubprocessPath}");
//                     
//                     // Verify other essential CefSharp files are present
//                     var browserSubprocessDir = Path.GetDirectoryName(browserSubprocessPath);
// #if REVIT2024
//                     var requiredFiles = new[] { "CefSharp.Core.dll", "CefSharp.Core.Runtime.dll", "libcef.dll" };
// #elif REVIT2026
//                     var requiredFiles = new[] { "CefSharp.Core.Runtime.dll", "libcef.dll" };
// #endif
//                     var missingFiles = new List<string>();
//                     
//                     foreach (var file in requiredFiles)
//                     {
//                         var filePath = Path.Combine(browserSubprocessDir ?? "", file);
//                         if (!File.Exists(filePath))
//                         {
//                             missingFiles.Add(file);
//                         }
//                     }
//                     
//                     if (missingFiles.Count > 0)
//                     {
//                         throw new FileNotFoundException($"Missing required CefSharp files in {browserSubprocessDir}: {string.Join(", ", missingFiles)}");
//                     }
                    var settings = new CefSettings()
                    {
                        CachePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RevitInternalBrowser", "Cache"),
                        LogSeverity = LogSeverity.Info,
                        LogFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RevitInternalBrowser", "Logs", "cef.log"),
                        //BrowserSubprocessPath = browserSubprocessPath
                    };

                    // Add command line arguments for better compatibility
                    settings.CefCommandLineArgs.Add("--no-sandbox", "1");
                    settings.CefCommandLineArgs.Add("--disable-web-security", "1");
                    settings.CefCommandLineArgs.Add("--disable-features", "VizDisplayCompositor");
                    
                    // Create cache directories if they don't exist
                    Directory.CreateDirectory(settings.CachePath);
                    Directory.CreateDirectory(Path.GetDirectoryName(settings.LogFile) ?? "");

                    // Initialize CefSharp
                    var success = Cef.Initialize(settings);
                    
                    if (!success)
                    {
                        throw new Exception("CefSharp initialization failed. Check that all CefSharp dependencies are present.");
                    }

                    _isInitialized = true;
                }
                catch (Exception ex)
                {
                    var assemblyDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                    var browserSubprocessPath = Path.Combine(assemblyDirectory ?? "", "CefSharp.BrowserSubprocess.exe");
                    
                    var errorMsg = $"Failed to initialize CefSharp: {ex.Message}\n\n" +
                                  "This usually means CefSharp dependencies are missing. Please ensure all CefSharp files are in the assembly directory.\n\n" +
                                  $"Assembly directory: {assemblyDirectory}\n" +
                                  $"Expected BrowserSubprocess path: {browserSubprocessPath}\n" +
                                  $"File exists: {File.Exists(browserSubprocessPath)}";
                    
                    MessageBox.Show(errorMsg, "CefSharp Initialization Error", MessageBoxButton.OK, MessageBoxImage.Error);
                    throw;
                }
            }
        }

        public static void Shutdown()
        {
            lock (_lockObject)
            {
                // Only shutdown if we initialized it (not if Revit initialized it)
                if (_isInitialized && Cef.IsInitialized == true)
                {
                    // Check if we should actually shutdown (Revit might still need it)
                    // For now, we'll be conservative and not shutdown to avoid conflicts with Revit
                    System.Diagnostics.Debug.WriteLine("CefSharp shutdown requested, but skipping to avoid conflicts with Revit.");
                    _isInitialized = false;
                }
            }
        }
    }
#endif
} 