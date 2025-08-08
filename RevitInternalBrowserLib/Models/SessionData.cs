using System.Collections.Generic;

namespace RevitInternalBrowserLib.Models
{
    public class SessionData
    {
        public List<TabData> Tabs { get; set; } = new List<TabData>();
    }

    public class TabData
    {
        public string Url { get; set; } = string.Empty;
        public string Title { get; set; } = "New Tab";
        public bool IsActive { get; set; }
    }
} 