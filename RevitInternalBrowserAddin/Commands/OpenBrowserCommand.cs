using System;
using System.Windows.Interop ;
using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using RevitInternalBrowserLib;

namespace RevitInternalBrowser.Commands
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]
    public class OpenBrowserCommand : IExternalCommand
    {
        private static BrowserWindow? _browserWindow;

        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            try
            {
                // Check if browser window is already open
                if (_browserWindow is not { IsLoaded: true })
                {
                    _browserWindow = new BrowserWindow();
                    if (Application.MainWindowHandle != null) new WindowInteropHelper( _browserWindow ).Owner = Application.MainWindowHandle.Value ;
                    _browserWindow.Closed += (_, _) => _browserWindow = null;
                }

                // Show the browser window
                _browserWindow.Show();
                _browserWindow.Activate();

                return Result.Succeeded;
            }
            catch (Exception ex)
            {
                message = $"Failed to open browser window: {ex.Message}";
                TaskDialog.Show("Error", message);
                return Result.Failed;
            }
        }
    }
} 