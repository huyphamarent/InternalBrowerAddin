using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Autodesk.Revit.UI;

namespace RevitInternalBrowser
{
    // ReSharper disable once ClassNeverInstantiated.Global
    public class Application : IExternalApplication
    {
        public static IntPtr? MainWindowHandle ;
        public Result OnStartup(UIControlledApplication application)
        {
            try
            {
                MainWindowHandle = application.MainWindowHandle ;
                // Set up assembly resolution to find DLLs in the same folder as the add-in
                SetupAssemblyResolution();



                // Create ribbon tab and panel
                CreateRibbonUi(application);

                return Result.Succeeded;
            }
            catch (Exception ex)
            {
                TaskDialog.Show("Error", $"Failed to initialize browser add-in: {ex.Message}");
                return Result.Failed;
            }
        }

        public Result OnShutdown(UIControlledApplication application)
        {
            try
            {
                return Result.Succeeded;
            }
            catch (Exception ex)
            {
                TaskDialog.Show("Error", $"Failed to shutdown browser add-in: {ex.Message}");
                return Result.Failed;
            }
        }

        private static void SetupAssemblyResolution()
        {
            // Get the directory where the add-in DLL is located
            var addinLocation = Assembly.GetExecutingAssembly().Location;
            var addinDirectory = Path.GetDirectoryName(addinLocation);

            if (string.IsNullOrEmpty(addinDirectory))
                return;

            // Add the assembly resolve event handler
            AppDomain.CurrentDomain.AssemblyResolve += (_, args) =>
            {
                try
                {
                    // Get the assembly name that failed to load
                    var assemblyName = new AssemblyName(args.Name);
                    var assemblyFileName = assemblyName.Name + ".dll";
                    var assemblyPath = Path.Combine(addinDirectory, assemblyFileName);

                    // Check if the DLL exists in the add-in directory
                    if (File.Exists(assemblyPath))
                    {
                        return Assembly.LoadFrom(assemblyPath);
                    }

                    // Also check for .exe files
                    var exeFileName = assemblyName.Name + ".exe";
                    var exePath = Path.Combine(addinDirectory, exeFileName);
                    if (File.Exists(exePath))
                    {
                        return Assembly.LoadFrom(exePath);
                    }
                }
                catch (Exception )
                {
                    // Ignore any errors during assembly resolution
                }

                return null;
            };
        }

        private static void CreateRibbonUi(UIControlledApplication application)
        {
            // Use the built-in Add-Ins tab which is language-independent
            var panel = application.CreateRibbonPanel("Internal Browser");

            // Create push button
            var buttonData = new PushButtonData(
                "InternalBrowser",
                "Chrome",
                Assembly.GetExecutingAssembly().Location,
                "RevitInternalBrowser.Commands.OpenBrowserCommand") { ToolTip = "Open Internal Web Browser", LongDescription = "Opens a multi-tab web browser window inside Revit with session persistence." };
            
            // Load and set the icon
            buttonData.LargeImage = LoadImage("Resources/chrome-icon-32.png");;
            buttonData.Image = LoadImage("Resources/chrome-icon-16.png");;

            if ( panel.AddItem(buttonData) is PushButton button ) button.Enabled = true ;
        }

        private static BitmapImage LoadImage(string resourcePath)
        {
            return new BitmapImage( new Uri( "pack://application:,,,/" + Assembly.GetExecutingAssembly().GetName().Name + ";component/" + resourcePath ) ) ;
        }

        private static BitmapSource? CreateFallbackIcon()
        {
            try
            {
                // Create a simple 16x16 browser icon using WPF drawing
                var renderTarget = new RenderTargetBitmap(16, 16, 96, 96, PixelFormats.Pbgra32);
                var visual = new DrawingVisual();
                
                using (var context = visual.RenderOpen())
                {
                    // Draw a simple browser icon (blue circle with "W" for web)
                    var brush = new SolidColorBrush(Colors.DodgerBlue);
                    var pen = new Pen(new SolidColorBrush(Colors.White), 1);
                    
                    // Draw background circle
                    context.DrawEllipse(brush, pen, new Point(8, 8), 7, 7);
                    
                    // Draw "W" for web
                    var textBrush = new SolidColorBrush(Colors.White);
                    var typeface = new Typeface("Arial");
                    var formattedText = new FormattedText(
                        "W", 
                        CultureInfo.CurrentCulture,
                        FlowDirection.LeftToRight,
                        typeface,
                        8,
                        textBrush,
                        VisualTreeHelper.GetDpi(visual).PixelsPerDip);
                    
                    context.DrawText(formattedText, new Point(5, 4));
                }
                
                renderTarget.Render(visual);
                renderTarget.Freeze();
                
                return renderTarget;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to create fallback icon: {ex.Message}");
                return null;
            }
        }
    }
} 