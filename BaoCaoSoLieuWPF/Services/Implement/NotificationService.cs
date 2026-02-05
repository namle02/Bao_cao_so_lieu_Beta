using BaoCaoSoLieu.Services.Interface;
using System.Windows;

namespace BaoCaoSoLieu.Services.Implement
{
    public class NotificationService : INotificationService
    {
        public void ShowSuccess(string message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                MessageBox.Show(message, "Thành công", MessageBoxButton.OK, MessageBoxImage.Information);
            });
        }

        public void ShowError(string message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                MessageBox.Show(message, "Lỗi", MessageBoxButton.OK, MessageBoxImage.Error);
            });
        }

        public void ShowInfo(string message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                MessageBox.Show(message, "Thông tin", MessageBoxButton.OK, MessageBoxImage.Information);
            });
        }
    }
} 