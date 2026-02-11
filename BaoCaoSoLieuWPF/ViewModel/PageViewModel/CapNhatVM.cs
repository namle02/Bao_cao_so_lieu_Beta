using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using BaoCaoSoLieu.Services.Interface;

namespace BaoCaoSoLieu.ViewModel.PageViewModel
{
    public partial class CapNhatVM : ObservableObject
    {
        private readonly IUpdateService _updateService;

        [ObservableProperty] private string currentVersion = "";
        [ObservableProperty] private string latestVersion = "";
        [ObservableProperty] private string releaseNotes = "";
        [ObservableProperty] private string downloadUrl = "";
        [ObservableProperty] private bool hasUpdate;
        [ObservableProperty] private bool isChecking;
        [ObservableProperty] private bool isDownloading;
        [ObservableProperty] private int downloadProgress;
        [ObservableProperty] private string statusMessage = "";

        public CapNhatVM(IUpdateService updateService)
        {
            _updateService = updateService;
            CurrentVersion = _updateService.GetCurrentVersion();
            StatusMessage = "Nhấn 'Kiểm tra cập nhật' để bắt đầu";
        }

        [RelayCommand]
        public async Task CheckForUpdates()
        {
            IsChecking = true;
            StatusMessage = "Đang kiểm tra phiên bản mới...";
            CurrentVersion = _updateService.GetCurrentVersion();

            var (hasUpdateResult, latestVer, url, notes) = await _updateService.CheckForUpdatesAsync();

            HasUpdate = hasUpdateResult;
            LatestVersion = latestVer;
            DownloadUrl = url;
            ReleaseNotes = notes;

            if (hasUpdateResult)
                StatusMessage = $"Đã có phiên bản mới v{latestVer}!";
            else
                StatusMessage = "Bạn đang sử dụng phiên bản mới nhất";

            IsChecking = false;
        }

        [RelayCommand]
        public async Task DownloadAndInstall()
        {
            if (string.IsNullOrEmpty(DownloadUrl))
            {
                StatusMessage = HasUpdate
                    ? "Phiên bản mới có sẵn nhưng Release trên GitHub chưa đính kèm file cài đặt (.msi, .zip hoặc .rar). Hãy đăng file lên https://github.com/namle02/Bao_cao_so_lieu_Beta/releases rồi thử lại."
                    : "Không có link tải. Hãy nhấn 'Kiểm tra cập nhật' trước.";
                return;
            }

            IsDownloading = true;
            DownloadProgress = 0;
            StatusMessage = "Đang tải xuống cập nhật...";

            try
            {
                var progress = new Progress<int>(percent =>
                {
                    DownloadProgress = percent;
                    StatusMessage = $"Đang tải xuống... {percent}%";
                });

                var (success, errorMessage) = await _updateService.DownloadAndInstallAsync(DownloadUrl, LatestVersion ?? "", progress);

                if (!success)
                    StatusMessage = string.IsNullOrEmpty(errorMessage) ? "Có lỗi khi cập nhật. Vui lòng thử lại." : errorMessage;
            }
            catch (Exception ex)
            {
                StatusMessage = "Lỗi: " + ex.Message;
            }
            finally
            {
                IsDownloading = false;
            }
        }
    }
}
