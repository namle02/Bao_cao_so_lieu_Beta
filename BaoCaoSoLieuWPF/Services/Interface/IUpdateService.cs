namespace BaoCaoSoLieu.Services.Interface
{
    public interface IUpdateService
    {
        Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync();
        Task<bool> DownloadAndInstallAsync(string downloadUrl, string targetVersion, IProgress<int>? progress);
        string GetCurrentVersion();
    }
}
