using System;
using System.Windows.Controls;

using CefSharp.Wpf;

namespace RevitInternalBrowserLib.Models
{
    public class BrowserTab
    {
        public Guid Id { get; set; }
        public string Url { get; set; } = string.Empty;
        public string Title { get; set; } = "New Tab";
        public Button TabButton { get; set; } = null!;
        public ChromiumWebBrowser Browser { get; set; } = null!;
        public bool IsLoading { get; set; } = false;
    }
}