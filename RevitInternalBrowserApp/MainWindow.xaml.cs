using System.Windows;
using RevitInternalBrowserLib;

namespace RevitInternalBrowserApp
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void OpenBrowser_Click(object sender, RoutedEventArgs e)
        {
            var browserWindow = new BrowserWindow();
            browserWindow.Show();
        }
    }
}