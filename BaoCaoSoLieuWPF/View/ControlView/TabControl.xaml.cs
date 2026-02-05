using BaoCaoSoLieu.Message;
using CommunityToolkit.Mvvm.Messaging;
using System.Windows;
using System.Windows.Controls;

namespace BaoCaoSoLieu.View.ControlView
{
    /// <summary>
    /// Interaction logic for TabControl.xaml
    /// </summary>
    public partial class TabControl : UserControl
    {
        public TabControl()
        {
            InitializeComponent();
            WeakReferenceMessenger.Default.Register<ErrorMessage>(this, (r, m) =>
            {
                Application.Current.Dispatcher.Invoke(() =>
                {
                    MessageBox.Show(m.message, "Thông báo lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
                });
            });
        }
    }
}
