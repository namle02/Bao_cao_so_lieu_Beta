using System.Diagnostics;
using System.IO.Compression;
using System.Reflection;
using System.Text.Json;
using System.Windows;
using BaoCaoSoLieu.Repos.Model;
using BaoCaoSoLieu.Services.Interface;

namespace BaoCaoSoLieu.Services.Implement
{
    public class UpdateService : IUpdateService
    {
        private readonly HttpClient _httpClient;

        /// <summary>
        /// Repo GitHub: thay YOUR_USER/YOUR_REPO nếu khác (vd: namle02/Bao_cao_so_lieu).
        /// Release cần có ít nhất một file .zip (nội dung bản cài) để nút Cập nhật hoạt động.
        /// </summary>
        private const string GITHUB_REPO = "namle02/Bao_cao_so_lieu";
        private static string GITHUB_API_URL => $"https://api.github.com/repos/{GITHUB_REPO}/releases/latest";

        private const string EXE_NAME = "BaoCaoSoLieu.exe";
        private const string APP_FOLDER_NAME = "BaoCaoSoLieu";

        private static string GetInstalledVersionFilePath()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var dir = Path.Combine(appData, APP_FOLDER_NAME);
            return Path.Combine(dir, "installed_version.txt");
        }

        private static string GetAppDirectory()
        {
            try
            {
                var exePath = Process.GetCurrentProcess().MainModule?.FileName;
                if (string.IsNullOrEmpty(exePath))
                    exePath = Assembly.GetExecutingAssembly().Location;
                if (string.IsNullOrEmpty(exePath))
                    return AppDomain.CurrentDomain.BaseDirectory ?? "";
                var dir = Path.GetDirectoryName(exePath);
                return dir ?? AppDomain.CurrentDomain.BaseDirectory ?? "";
            }
            catch
            {
                return AppDomain.CurrentDomain.BaseDirectory ?? "";
            }
        }

        public UpdateService()
        {
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.Add("User-Agent", APP_FOLDER_NAME);
        }

        public string GetCurrentVersion()
        {
            try
            {
                var candidates = new List<string>();

                var installedFile = GetInstalledVersionFilePath();
                if (File.Exists(installedFile))
                {
                    var savedVersion = File.ReadAllText(installedFile)?.Trim();
                    if (!string.IsNullOrEmpty(savedVersion) && IsValidVersionString(savedVersion))
                        candidates.Add(savedVersion);
                }

                var appDir = GetAppDirectory();
                if (!string.IsNullOrEmpty(appDir))
                {
                    var versionTxtPath = Path.Combine(appDir, "version.txt");
                    if (File.Exists(versionTxtPath))
                    {
                        var versionFromFile = File.ReadAllText(versionTxtPath)?.Trim();
                        if (!string.IsNullOrEmpty(versionFromFile) && IsValidVersionString(versionFromFile))
                            candidates.Add(versionFromFile);
                    }
                }

                var exePath = Assembly.GetExecutingAssembly().Location;
                if (string.IsNullOrEmpty(exePath))
                    exePath = Process.GetCurrentProcess().MainModule?.FileName;
                if (!string.IsNullOrEmpty(exePath) && File.Exists(exePath))
                {
                    var fileVersionInfo = FileVersionInfo.GetVersionInfo(exePath);
                    if (!string.IsNullOrEmpty(fileVersionInfo.FileVersion))
                    {
                        var v = NormalizeVersionString(fileVersionInfo.FileVersion);
                        if (!string.IsNullOrEmpty(v))
                            candidates.Add(v);
                    }
                }

                var assemblyVersion = Assembly.GetExecutingAssembly().GetName().Version;
                if (assemblyVersion != null)
                {
                    var v = $"{assemblyVersion.Major}.{assemblyVersion.Minor}.{assemblyVersion.Build}";
                    if (assemblyVersion.Revision > 0)
                        v += $".{assemblyVersion.Revision}";
                    if (IsValidVersionString(v))
                        candidates.Add(v);
                }

                if (candidates.Count > 0)
                {
                    var latest = candidates
                        .OrderByDescending(c => { try { return new Version(c); } catch { return new Version(0, 0); } })
                        .FirstOrDefault();
                    if (!string.IsNullOrEmpty(latest))
                        return latest;
                }

                return "1.0.0";
            }
            catch
            {
                return "1.0.0";
            }
        }

        public async Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync()
        {
            try
            {
                var response = await _httpClient.GetStringAsync(GITHUB_API_URL);
                var release = JsonSerializer.Deserialize<GitHubRelease>(response);

                if (release == null)
                    return (false, "", "", "");

                var latestVersion = release.tag_name?.TrimStart('v') ?? "";
                var currentVersion = GetCurrentVersion();
                var hasUpdate = IsNewerVersion(currentVersion, latestVersion);

                var zipAsset = release.assets?.FirstOrDefault(a => a.name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase));
                var downloadUrl = zipAsset?.browser_download_url ?? "";
                var releaseNotes = release.body ?? "";

                return (hasUpdate, latestVersion, downloadUrl, releaseNotes);
            }
            catch
            {
                return (false, "", "", "");
            }
        }

        public async Task<bool> DownloadAndInstallAsync(string downloadUrl, string targetVersion, IProgress<int>? progress)
        {
            try
            {
                var tempPath = Path.GetTempPath();
                var zipPath = Path.Combine(tempPath, "BaoCaoSoLieu_update.zip");
                var extractPath = Path.Combine(tempPath, "BaoCaoSoLieu_update_extracted");

                if (!string.IsNullOrEmpty(targetVersion) && IsValidVersionString(targetVersion))
                {
                    try
                    {
                        var versionFile = GetInstalledVersionFilePath();
                        var dir = Path.GetDirectoryName(versionFile);
                        if (!string.IsNullOrEmpty(dir))
                        {
                            Directory.CreateDirectory(dir);
                            File.WriteAllText(versionFile, targetVersion);
                        }
                    }
                    catch { }
                }

                using (var response = await _httpClient.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead))
                {
                    response.EnsureSuccessStatusCode();
                    var totalBytes = response.Content.Headers.ContentLength ?? -1L;

                    await using (var contentStream = await response.Content.ReadAsStreamAsync())
                    await using (var fileStream = new FileStream(zipPath, FileMode.Create))
                    {
                        var buffer = new byte[8192];
                        var totalRead = 0L;
                        int bytesRead;

                        while ((bytesRead = await contentStream.ReadAsync(buffer)) != 0)
                        {
                            await fileStream.WriteAsync(buffer.AsMemory(0, bytesRead));
                            totalRead += bytesRead;
                            if (totalBytes != -1)
                                progress?.Report((int)((totalRead * 100) / totalBytes));
                        }
                    }
                }

                if (Directory.Exists(extractPath))
                    Directory.Delete(extractPath, true);

                ZipFile.ExtractToDirectory(zipPath, extractPath);
                await ReplaceApplicationFiles(extractPath);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static bool IsValidVersionString(string version)
        {
            try
            {
                _ = new Version(version);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static string NormalizeVersionString(string version)
        {
            if (string.IsNullOrWhiteSpace(version)) return "";
            try
            {
                var v = new Version(version);
                if (v.Revision > 0)
                    return $"{v.Major}.{v.Minor}.{v.Build}.{v.Revision}";
                if (v.Build > 0)
                    return $"{v.Major}.{v.Minor}.{v.Build}";
                return $"{v.Major}.{v.Minor}";
            }
            catch
            {
                return "";
            }
        }

        private bool IsNewerVersion(string current, string latest)
        {
            try
            {
                return new Version(latest) > new Version(current);
            }
            catch
            {
                return false;
            }
        }

        private bool RequiresAdmin(string appPath)
        {
            try
            {
                var programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
                var programFilesX86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
                return appPath.StartsWith(programFiles, StringComparison.OrdinalIgnoreCase) ||
                       appPath.StartsWith(programFilesX86, StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        private bool CanWriteToDirectory(string directoryPath)
        {
            try
            {
                var testFile = Path.Combine(directoryPath, $"test_write_{Guid.NewGuid():N}.tmp");
                File.WriteAllText(testFile, "test");
                File.Delete(testFile);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private async Task ReplaceApplicationFiles(string sourcePath)
        {
            var currentExePath = Process.GetCurrentProcess().MainModule?.FileName;
            if (string.IsNullOrEmpty(currentExePath))
                currentExePath = Assembly.GetExecutingAssembly().Location;

            var appPath = Path.GetDirectoryName(currentExePath);

            if (appPath != null && appPath.Contains(@"\AppData\Local\Temp\.net\", StringComparison.OrdinalIgnoreCase))
            {
                var possiblePaths = new[]
                {
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), APP_FOLDER_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), APP_FOLDER_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), APP_FOLDER_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), APP_FOLDER_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), APP_FOLDER_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Admin", "App Installer"),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Admin", "App Installer")
                };

                foreach (var possiblePath in possiblePaths)
                {
                    if (Directory.Exists(possiblePath))
                    {
                        var possibleExePath = Path.Combine(possiblePath, EXE_NAME);
                        if (File.Exists(possibleExePath))
                        {
                            appPath = possiblePath;
                            break;
                        }
                    }
                }

                if (appPath != null && appPath.Contains(@"\AppData\Local\Temp\.net\", StringComparison.OrdinalIgnoreCase))
                {
                    appPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), APP_FOLDER_NAME);
                    Directory.CreateDirectory(appPath);
                }
            }

            if (string.IsNullOrEmpty(appPath))
                appPath = AppDomain.CurrentDomain.BaseDirectory;

            var exePath = Path.Combine(appPath!, EXE_NAME);
            appPath = appPath.TrimEnd('\\', '/');
            sourcePath = sourcePath.TrimEnd('\\', '/');

            var extractedExePath = Path.Combine(sourcePath, EXE_NAME);
            if (!File.Exists(extractedExePath))
            {
                var allExes = Directory.GetFiles(sourcePath, EXE_NAME, SearchOption.AllDirectories);
                if (allExes.Length > 0)
                {
                    var exeDir = Path.GetDirectoryName(allExes[0]);
                    sourcePath = (exeDir ?? sourcePath).TrimEnd('\\', '/');
                }
            }

            var batchFile = Path.Combine(Path.GetTempPath(), $"BaoCaoSoLieu_update_{Guid.NewGuid():N}.bat");
            var tempPath = Path.GetTempPath();
            var zipPath = Path.Combine(tempPath, "BaoCaoSoLieu_update.zip");
            var extractPath = Path.Combine(tempPath, "BaoCaoSoLieu_update_extracted");

            var needsAdmin = RequiresAdmin(appPath);
            var hasWriteAccess = CanWriteToDirectory(appPath);

            var escapedAppPath = appPath.Replace("\"", "\"\"");
            var escapedSourcePath = sourcePath.Replace("\"", "\"\"");
            var escapedExePath = exePath.Replace("\"", "\"\"");

            var batchContent = $@"@echo off
title Cập nhật - {EXE_NAME}
color 0A
echo Đang chờ ứng dụng đóng...
:wait
tasklist /FI ""IMAGENAME eq {EXE_NAME}"" 2>NUL | find /I /N ""{EXE_NAME}"">NUL
if ""%ERRORLEVEL%""==""0"" (
    timeout /t 2 /nobreak > nul
    goto wait
)
timeout /t 2 /nobreak > nul
taskkill /F /IM ""{EXE_NAME}"" 2>NUL
timeout /t 2 /nobreak > nul

if not exist ""{escapedSourcePath}"" (
    echo ERROR: Khong tim thay thu muc giai nen.
    pause
    exit /b 1
)

if exist ""{escapedExePath}"" (
    del /F /Q ""{escapedExePath}"" 2>NUL
    timeout /t 1 /nobreak > nul
)

robocopy ""{escapedSourcePath}"" ""{escapedAppPath}"" /E /IS /IT /R:3 /W:2 /NP /NFL /NDL
set copyResult=%ERRORLEVEL%
if %copyResult% GEQ 8 (
    echo Loi copy. Thu chay lai voi quyen Admin.
    pause
    exit /b 1
)

timeout /t 1 /nobreak > nul
if not exist ""{escapedExePath}"" (
    echo Loi: Khong tim thay file exe sau khi copy.
    pause
    exit /b 1
)

if exist ""{zipPath}"" del /F /Q ""{zipPath}""
if exist ""{extractPath}"" rmdir /S /Q ""{extractPath}""

start """" /D ""{escapedAppPath}"" ""{escapedExePath}""
timeout /t 2 /nobreak > nul
del ""%~f0""
";
            await File.WriteAllTextAsync(batchFile, batchContent);

            ProcessStartInfo processInfo;
            if (needsAdmin && !hasWriteAccess)
            {
                var psScript = Path.Combine(Path.GetTempPath(), $"BaoCaoSoLieu_update_{Guid.NewGuid():N}.ps1");
                var psContent = $@"Start-Process -FilePath '{batchFile}' -Verb RunAs -Wait";
                await File.WriteAllTextAsync(psScript, psContent);
                processInfo = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-ExecutionPolicy Bypass -File \"{psScript}\"",
                    CreateNoWindow = false,
                    UseShellExecute = true,
                    WindowStyle = ProcessWindowStyle.Normal
                };
            }
            else
            {
                processInfo = new ProcessStartInfo
                {
                    FileName = batchFile,
                    CreateNoWindow = false,
                    UseShellExecute = true,
                    WindowStyle = ProcessWindowStyle.Normal
                };
            }

            Process.Start(processInfo);
            await Task.Delay(500);

            _httpClient?.Dispose();
            Application.Current?.Dispatcher.Invoke(() => Application.Current.Shutdown());
        }
    }
}
