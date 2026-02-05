namespace BaoCaoSoLieu.Services.Interface
{
    public interface INotificationService
    {
        void ShowSuccess(string message);
        void ShowError(string message);
        void ShowInfo(string message);
    }
} 