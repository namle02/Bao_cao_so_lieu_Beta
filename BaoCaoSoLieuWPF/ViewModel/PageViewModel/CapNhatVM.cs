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
        [ObservableProperty] private string statusMessage = "Nhấn 'Kiểm tra cập nhật' để bắt đầu";

        public CapNhatVM(IUpdateService updateService)
        {
            _updateService = updateService;
            CurrentVersion = _updateService.GetCurrentVersion();
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
            ReleaseNotes = notes ?? "";
            StatusMessage = HasUpdate ? $"Đã có phiên bản mới v{LatestVersion}!" : "Bạn đang sử dụng phiên bản mới nhất.";
            IsChecking = false;
        }

        [RelayCommand]
        public async Task DownloadAndInstall()
        {
            if (string.IsNullOrEmpty(DownloadUrl))
                return;

            IsDownloading = true;
            StatusMessage = "Đang tải xuống cập nhật...";

            var progress = new Progress<int>(p =>
            {
                DownloadProgress = p;
                StatusMessage = $"Đang tải xuống... {p}%";
            });

            var success = await _updateService.DownloadAndInstallAsync(DownloadUrl, LatestVersion ?? "", progress);

            if (!success)
            {
                StatusMessage = "Có lỗi khi cập nhật. Vui lòng thử lại.";
                IsDownloading = false;
            }
        }
    }
}
