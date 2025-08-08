using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using RevitInternalBrowserLib.Models;
using CefSharp;
using CefSharp.Wpf;
using Newtonsoft.Json ;

namespace RevitInternalBrowserLib
{
#if REVIT2024
    public class CustomContextMenuHandler : IContextMenuHandler
    {
        private readonly Action<string> _openLinkInNewTab;

        public CustomContextMenuHandler(Action<string> openLinkInNewTab)
        {
            _openLinkInNewTab = openLinkInNewTab;
        }

        public void OnBeforeContextMenu(IWebBrowser chromiumWebBrowser, IBrowser browser, IFrame frame, IContextMenuParams parameters, IMenuModel model)
        {
            // Clear the default context menu
            model.Clear();

            // Add link-specific menu items
            if (!string.IsNullOrEmpty(parameters.LinkUrl))
            {
                model.AddItem((CefMenuCommand)26500, "Open link in new tab");
                model.AddItem((CefMenuCommand)26501, "Copy link address");
                model.AddSeparator();
            }

            // Add text selection menu items
            if (!string.IsNullOrEmpty(parameters.SelectionText))
            {
                model.AddItem(CefMenuCommand.Copy, "Copy");
                model.AddItem((CefMenuCommand)26502, "Search for \"" + parameters.SelectionText + "\"");
                model.AddSeparator();
            }



            // Add standard navigation items
            if (browser.CanGoBack)
                model.AddItem(CefMenuCommand.Back, "Back");
            if (browser.CanGoForward)
                model.AddItem(CefMenuCommand.Forward, "Forward");
            
            model.AddSeparator();
            model.AddItem(CefMenuCommand.Reload, "Reload");
            model.AddItem(CefMenuCommand.ReloadNoCache, "Reload (no cache)");
            
            model.AddSeparator();
            model.AddItem(CefMenuCommand.Copy, "Copy");
            model.AddItem(CefMenuCommand.Cut, "Cut");
            model.AddItem(CefMenuCommand.Paste, "Paste");
            model.AddItem(CefMenuCommand.SelectAll, "Select All");
            
            model.AddSeparator();
            model.AddItem(CefMenuCommand.ViewSource, "View Page Source");
        }

        public bool OnContextMenuCommand(IWebBrowser chromiumWebBrowser, IBrowser browser, IFrame frame, IContextMenuParams parameters, CefMenuCommand commandId, CefEventFlags eventFlags)
        {
            // Handle custom menu commands
            switch (commandId)
            {
                case (CefMenuCommand)26500: // Open link in new tab
                    if (!string.IsNullOrEmpty(parameters.LinkUrl))
                    {
                        _openLinkInNewTab(parameters.LinkUrl);
                        return true;
                    }
                    break;
                    
                case (CefMenuCommand)26501: // Copy link address
                    if (!string.IsNullOrEmpty(parameters.LinkUrl))
                    {
                        // Use dispatcher to ensure clipboard operations happen on UI thread
                        Application.Current.Dispatcher.Invoke(() =>
                        {
                            Clipboard.SetText(parameters.LinkUrl);
                        });
                        return true;
                    }
                    break;
                    
                case (CefMenuCommand)26502: // Search for selected text
                    if (!string.IsNullOrEmpty(parameters.SelectionText))
                    {
                        var searchUrl = "https://www.google.com/search?q=" + Uri.EscapeDataString(parameters.SelectionText);
                        _openLinkInNewTab(searchUrl);
                        return true;
                    }
                    break;
            }

            // Let CefSharp handle standard commands
            return false;
        }

        public void OnContextMenuDismissed(IWebBrowser chromiumWebBrowser, IBrowser browser, IFrame frame)
        {
            // No action needed when context menu is dismissed
        }

#if REVIT2024
        public bool RunContextMenu(IWebBrowser chromiumWebBrowser, IBrowser browser, IFrame frame, IContextMenuParams parameters, IMenuModel model, IRunContextMenuCallback callback)
        {
            // Return false to use the default context menu implementation
            return false;
        }
#elif REVIT2026
        // In newer versions of CefSharp, this method might not be required or have a different signature
        // For now, we'll skip implementing it for Revit 2026
#endif
    }

#endif

#if REVIT2024 || REVIT2026
    public partial class BrowserWindow
    {
        private readonly List<BrowserTab> _tabs = new() ;
        private BrowserTab? _activeTab ;
        private readonly string _profilePath ;

        public BrowserWindow()
        {
            // Initialize CefSharp before creating the window
            CefSharpInitializer.Initialize() ;

            InitializeComponent() ;

            // Set up profile path for session persistence
            _profilePath = Path.Combine( Environment.GetFolderPath( Environment.SpecialFolder.LocalApplicationData ), "RevitInternalBrowser", "Profiles", "default.json" ) ;

            // Ensure profile directory exists
            Directory.CreateDirectory( Path.GetDirectoryName( _profilePath ) ?? string.Empty ) ;

            // Load saved session
            LoadSession() ;

            // Create initial tab if no tabs were loaded
            if ( _tabs.Count == 0 ) {
                CreateNewTab() ;
            }

            // Set up window closing event to save session
            Closing += BrowserWindow_Closing ;

            // Set up keyboard handling for the window
            SetupKeyboardHandling() ;
        }

        private void UpdateContextMenu( ChromiumWebBrowser browser )
        {
#if REVIT2024
            // Set up custom context menu handler
            var contextMenuHandler = new CustomContextMenuHandler( OpenLinkInNewTab ) ;
            browser.MenuHandler = contextMenuHandler ;

#elif REVIT2026
#endif
        }
        private void CreateNewTab( string url = "https://www.google.com", string title = "New Tab" )
        {
            var tab = new BrowserTab { Id = Guid.NewGuid(), Url = url, Title = title } ;

            // Create tab button
            var tabButton = new Button { Content = title, Style = (Style)FindResource( "TabButtonStyle" ), Tag = tab.Id } ;
            tabButton.Click += TabButton_Click ;

            // Set the DataContext for binding the loading state
            tabButton.DataContext = tab ;

            // Create browser control
            var browser = new ChromiumWebBrowser( url ) ;
            browser.Visibility = Visibility.Hidden ;
            UpdateContextMenu( browser ) ;

            // Set up keyboard handling for the browser
            browser.Focusable = true ;
            browser.IsTabStop = true ;

            // Handle browser events
            browser.TitleChanged += ( _, args ) =>
            {
                Dispatcher.Invoke( () =>
                {
                    if ( args.NewValue == null ) return ;
                    tab.Title = args.NewValue.ToString() ?? "New Tab" ;
                    tabButton.Content = tab.Title.Length > 20 ? tab.Title.Substring( 0, 20 ) + "..." : tab.Title ;
                } ) ;
            } ;

            browser.AddressChanged += ( _, args ) =>
            {
                Dispatcher.Invoke( () =>
                {
                    if ( args.NewValue == null ) return ;
                    tab.Url = args.NewValue.ToString() ?? "" ;
                    if ( tab != _activeTab ) return ;
                    AddressBar.Text = tab.Url ;
                    UpdateNavigationButtons() ;
                } ) ;
            } ;
#if REVIT2024
            browser.LoadingStateChanged += ( _, args ) =>
            {
                Dispatcher.Invoke( () =>
                {
                    // Update loading state
                    tab.IsLoading = args.IsLoading ;

                    if ( tab == _activeTab ) {
                        UpdateNavigationButtons() ;
                    }
                } ) ;
            } ;
#endif
            // Handle browser focus events
            browser.GotFocus += ( _, _ ) => { System.Diagnostics.Debug.WriteLine( "Browser got focus" ) ; } ;

            browser.LostFocus += ( _, _ ) => { System.Diagnostics.Debug.WriteLine( "Browser lost focus" ) ; } ;

            tab.TabButton = tabButton ;
            tab.Browser = browser ;

            // Add to collections
            _tabs.Add( tab ) ;
            TabContainer.Children.Add( tabButton ) ;
            BrowserContainer.Children.Add( browser ) ;

            // Activate this tab
            ActivateTab( tab ) ;
        }

        private void OpenLinkInNewTab( string url )
        {
            // Ensure UI operations happen on the UI thread
            Dispatcher.Invoke( () =>
            {
                // Create a new tab with the specified URL
                CreateNewTab( url ) ;
            } ) ;
        }

        private void ActivateTab( BrowserTab tab )
        {
            // Hide current active tab
            if ( _activeTab != null ) {
                _activeTab.Browser.Visibility = Visibility.Hidden ;
                _activeTab.TabButton.Background = System.Windows.Media.Brushes.LightGray ;
            }

            // Show new active tab
            _activeTab = tab ;
            tab.Browser.Visibility = Visibility.Visible ;
            tab.TabButton.Background = System.Windows.Media.Brushes.White ;

            // Update address bar and navigation buttons
            AddressBar.Text = tab.Url ;
            UpdateNavigationButtons() ;

            // Set focus to the browser for keyboard handling
            Dispatcher.BeginInvoke( new Action( () => { tab.Browser.Focus() ; } ) ) ;
        }

        private void CloseTab( BrowserTab tab )
        {
            if ( _tabs.Count <= 1 ) {
                // Don't close the last tab, just navigate to home page
                tab.Browser.Load( "https://www.google.com" ) ;
                return ;
            }

            // Remove from collections
            _tabs.Remove( tab ) ;
            TabContainer.Children.Remove( tab.TabButton ) ;
            BrowserContainer.Children.Remove( tab.Browser ) ;

            // Dispose browser
            tab.Browser.Dispose() ;

            // If this was the active tab, activate another tab
            if ( tab == _activeTab ) {
                var newActiveTab = _tabs.FirstOrDefault() ;
                if ( newActiveTab != null ) {
                    ActivateTab( newActiveTab ) ;
                }
            }
        }

        private void UpdateNavigationButtons()
        {
            if ( _activeTab?.Browser != null ) {
                BackButton.IsEnabled = _activeTab.Browser.CanGoBack ;
                ForwardButton.IsEnabled = _activeTab.Browser.CanGoForward ;
            }
        }

        private void SaveSession()
        {
            try {
                var sessionData = new SessionData { Tabs = _tabs.Select( tab => new TabData { Url = tab.Url, Title = tab.Title, IsActive = tab == _activeTab } ).ToList() } ;

                var json = JsonConvert.SerializeObject( sessionData, Formatting.Indented ) ;
                File.WriteAllText( _profilePath, json ) ;
            }
            catch ( Exception ex ) {
                // Log error but don't show to user during shutdown
                System.Diagnostics.Debug.WriteLine( $"Failed to save session: {ex.Message}" ) ;
            }
        }

        private void LoadSession()
        {
            try {
                if ( ! File.Exists( _profilePath ) ) return ;
                var json = File.ReadAllText( _profilePath ) ;
                var sessionData = JsonConvert.DeserializeObject<SessionData>( json ) ;

                if ( sessionData?.Tabs is not { Count: > 0 } ) return ;
                BrowserTab? activeTab = null ;

                foreach ( var tabData in sessionData.Tabs ) {
                    CreateNewTab( tabData.Url, tabData.Title ) ;

                    if ( tabData.IsActive ) {
                        activeTab = _tabs.Last() ;
                    }
                }

                // Activate the previously active tab
                if ( activeTab != null ) {
                    ActivateTab( activeTab ) ;
                }
            }
            catch ( Exception ex ) {
                // If loading fails, we'll just start fresh
                System.Diagnostics.Debug.WriteLine( $"Failed to load session: {ex.Message}" ) ;
            }
        }

        // Event Handlers
        private void NewTab_Click( object sender, RoutedEventArgs e )
        {
            CreateNewTab() ;
        }

        private void TabButton_Click( object sender, RoutedEventArgs e )
        {
            if ( sender is Button button && button.Tag is Guid tabId ) {
                var tab = _tabs.FirstOrDefault( t => t.Id == tabId ) ;
                if ( tab != null ) {
                    ActivateTab( tab ) ;
                }
            }
        }

        private void CloseTab_Click( object sender, RoutedEventArgs e )
        {
            if ( sender is not Button { Tag: Guid tabId } ) return ;
            var tab = _tabs.FirstOrDefault( t => t.Id == tabId ) ;
            if ( tab != null ) {
                CloseTab( tab ) ;
            }
        }

        private void Back_Click( object sender, RoutedEventArgs e )
        {
            if ( _activeTab?.Browser == null ) return ;
#if REVIT2024
                _activeTab.Browser.Back();
#elif REVIT2026
            if (_activeTab.Browser.CanGoBack) _activeTab.Browser.BackCommand.Execute( null );
#endif
        }

        private void Forward_Click( object sender, RoutedEventArgs e )
        {
            if ( _activeTab?.Browser == null ) return ;
#if REVIT2024
                _activeTab.Browser.Forward();
#elif REVIT2026
            if (_activeTab.Browser.CanGoForward) _activeTab.Browser.ForwardCommand.Execute( null );
#endif
        }

        private void Refresh_Click( object sender, RoutedEventArgs e )
        {
#if REVIT2024
                _activeTab.Browser.Reload();
#elif REVIT2026
            _activeTab?.Browser?.ReloadCommand.Execute( null );
#endif
        }

        private void AddressBar_KeyDown( object sender, KeyEventArgs e )
        {
            if ( e.Key != Key.Enter || _activeTab == null ) return ;
            var url = AddressBar.Text ;

            // Add protocol if missing
            if ( ! url.StartsWith( "http://" ) && ! url.StartsWith( "https://" ) ) {
                url = "https://" + url ;
            }

            _activeTab.Browser.Load( url ) ;
        }

        private void AddressBar_PreviewMouseLeftButtonDown( object sender, MouseButtonEventArgs e )
        {
            // Auto-select all text when clicking the address bar
            AddressBar.SelectAll() ;
        }

        private void Menu_Click( object sender, RoutedEventArgs e )
        {
            // Create context menu for browser options
            var contextMenu = new ContextMenu() ;

            var newTabItem = new MenuItem { Header = "New Tab" } ;
            newTabItem.Click += ( _, _ ) => CreateNewTab() ;
            contextMenu.Items.Add( newTabItem ) ;

            var separatorItem = new Separator() ;
            contextMenu.Items.Add( separatorItem ) ;

            var settingsItem = new MenuItem { Header = "Settings" } ;
            settingsItem.Click += ( _, _ ) => CreateNewTab( "chrome://settings/" ) ;
            contextMenu.Items.Add( settingsItem ) ;

            contextMenu.IsOpen = true ;
        }

        private void BrowserWindow_Closing( object? sender, System.ComponentModel.CancelEventArgs e )
        {
            try {
                // Save session before closing
                SaveSession() ;

                // Shutdown CefSharp
                CefSharpInitializer.Shutdown() ;
            }
            catch ( Exception ex ) {
                MessageBox.Show( $"Failed to save session: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Warning ) ;
            }
        }

        private void SetupKeyboardHandling()
        {
            // Set up keyboard event handling for the window
            KeyDown += ( _, e ) =>
            {
                // If the active browser has focus, let it handle the key
                if ( _activeTab?.Browser is { IsFocused: true } ) {
                    return ;
                }

                // Handle common keyboard shortcuts
                if ( e.KeyboardDevice.Modifiers != ModifierKeys.Control ) return ;
                switch ( e.Key ) {
                    case Key.C :
                        // Copy - focus browser and let it handle
                        if ( _activeTab?.Browser != null ) {
                            _activeTab.Browser.Focus() ;
                            // The browser will handle Ctrl+C automatically when focused
                        }

                        e.Handled = true ;
                        break ;
                    case Key.V :
                        // Paste - focus browser and let it handle
                        if ( _activeTab?.Browser != null ) {
                            _activeTab.Browser.Focus() ;
                            // The browser will handle Ctrl+V automatically when focused
                        }

                        e.Handled = true ;
                        break ;
                    case Key.X :
                        // Cut - focus browser and let it handle
                        if ( _activeTab?.Browser != null ) {
                            _activeTab.Browser.Focus() ;
                            // The browser will handle Ctrl+X automatically when focused
                        }

                        e.Handled = true ;
                        break ;
                    case Key.A :
                        // Select All - focus browser and let it handle
                        if ( _activeTab?.Browser != null ) {
                            _activeTab.Browser.Focus() ;
                            // The browser will handle Ctrl+A automatically when focused
                        }

                        e.Handled = true ;
                        break ;
                    case Key.Z :
                        // Undo - focus browser and let it handle
                        if ( _activeTab?.Browser != null ) {
                            _activeTab.Browser.Focus() ;
                            // The browser will handle Ctrl+Z automatically when focused
                        }

                        e.Handled = true ;
                        break ;
                    case Key.Y :
                        // Redo - focus browser and let it handle
                        if ( _activeTab?.Browser != null ) {
                            _activeTab.Browser.Focus() ;
                            // The browser will handle Ctrl+Y automatically when focused
                        }

                        e.Handled = true ;
                        break ;
                }
            } ;

            // Set up mouse click handling to focus the browser
            MouseLeftButtonDown += ( _, e ) =>
            {
                // If clicking on the browser area, focus the active browser
                if ( _activeTab?.Browser != null && e.OriginalSource is ChromiumWebBrowser ) {
                    _activeTab.Browser.Focus() ;
                }
            } ;

            // Set up focus handling for the browser container
            BrowserContainer.MouseLeftButtonDown += ( _, _ ) =>
            {
                // When clicking in the browser area, focus the active browser
                if ( _activeTab?.Browser != null ) {
                    _activeTab.Browser.Focus() ;
                }
            } ;
        }
    }
#endif
}