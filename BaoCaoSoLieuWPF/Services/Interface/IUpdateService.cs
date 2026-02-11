namespace BaoCaoSoLieu.Services.Interface
{
    public interface IUpdateService
    {
        /// <summary>
        /// Kiểm tra có phiên bản mới không
        /// </summary>
        Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync();

        /// <summary>
        /// Download và cài đặt update.
        /// targetVersion: phiên bản đang cài (để lưu lại).
        /// Trả về (thành công, thông báo lỗi nếu thất bại).
        /// </summary>
        Task<(bool success, string errorMessage)> DownloadAndInstallAsync(string downloadUrl, string targetVersion, IProgress<int> progress);

        /// <summary>
        /// Lấy version hiện tại của app
        /// </summary>
        string GetCurrentVersion();
    }
}
