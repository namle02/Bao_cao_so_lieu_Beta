using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using System.Reflection;
using System.Text.Json;
using System.Windows;
using BaoCaoSoLieu.Repos.Model;
using BaoCaoSoLieu.Services.Interface;
using SharpCompress.Archives;
using SharpCompress.Common;

namespace BaoCaoSoLieu.Services.Implement
{
    /// <summary>
    /// Service cập nhật phần mềm. Hỗ trợ 2 cách deploy:
    /// - Release có file .msi: tải MSI và chạy cài đặt (ứng dụng cài qua App Installer / MSI).
    /// - Release có file .zip: tải zip, giải nén và thay thế file (giống GiamDinhBaoHiemYTe).
    /// </summary>
    public class UpdateService : IUpdateService
    {
        private readonly HttpClient _httpClient;

        // Repo GitHub chứa releases (có thể đổi theo repo thực tế)
        private const string GITHUB_API_URL = "https://api.github.com/repos/namle02/Bao_cao_so_lieu_Beta/releases/latest";

        private const string APP_NAME = "BaoCaoSoLieu";
        private const string EXE_NAME = "BaoCaoSoLieu.exe";

        private static string GetInstalledVersionFilePath()
        {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var dir = Path.Combine(appData, APP_NAME);
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
            _httpClient.DefaultRequestHeaders.Add("User-Agent", APP_NAME);
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

                // InformationalVersion có thể chứa hậu tố (vd: 1.0.0+abc) - chỉ lấy phần số
                var infoVersion = Assembly.GetExecutingAssembly().GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion;
                if (!string.IsNullOrWhiteSpace(infoVersion))
                {
                    var v = NormalizeVersionString(infoVersion);
                    if (!string.IsNullOrEmpty(v))
                        candidates.Add(v);
                }

                if (candidates.Count > 0)
                {
                    var best = candidates
                        .OrderByDescending(c => { try { return new Version(StripToVersionOnly(c)); } catch { return new Version(0, 0); } })
                        .FirstOrDefault();
                    if (!string.IsNullOrEmpty(best))
                    {
                        var normalized = NormalizeVersionString(best);
                        return !string.IsNullOrEmpty(normalized) ? normalized : StripToVersionOnly(best);
                    }
                }

                return "1.0.0";
            }
            catch
            {
                return "1.0.0";
            }
        }

        // GitHub API trả về snake_case (tag_name, browser_download_url) - chỉ cần case-insensitive
        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public async Task<(bool hasUpdate, string latestVersion, string downloadUrl, string releaseNotes)> CheckForUpdatesAsync()
        {
            try
            {
                var response = await _httpClient.GetStringAsync(GITHUB_API_URL);
                var release = JsonSerializer.Deserialize<GitHubRelease>(response, JsonOptions);

                if (release == null)
                    return (false, "", "", "");

                var rawTag = (release.tag_name ?? "").Trim().TrimStart('v', 'V');
                var latestVersion = StripToVersionOnly(rawTag);
                if (string.IsNullOrEmpty(latestVersion))
                    latestVersion = rawTag;
                if (string.IsNullOrEmpty(latestVersion))
                    return (false, "", "", "");

                var currentVersion = GetCurrentVersion();
                var hasUpdate = IsNewerVersion(currentVersion, latestVersion);

                // Ưu tiên .msi, rồi .zip, rồi .rar (tên asset có thể chứa khoảng trắng)
                var msiAsset = release.assets?.FirstOrDefault(a => (a.name ?? "").TrimEnd().EndsWith(".msi", StringComparison.OrdinalIgnoreCase));
                var zipAsset = release.assets?.FirstOrDefault(a => (a.name ?? "").TrimEnd().EndsWith(".zip", StringComparison.OrdinalIgnoreCase));
                var rarAsset = release.assets?.FirstOrDefault(a => (a.name ?? "").TrimEnd().EndsWith(".rar", StringComparison.OrdinalIgnoreCase));
                var downloadUrl = (msiAsset?.browser_download_url ?? zipAsset?.browser_download_url ?? rarAsset?.browser_download_url ?? "").Trim();
                var releaseNotes = release.body ?? "";

                return (hasUpdate, latestVersion, downloadUrl, releaseNotes);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"CheckForUpdates: {ex.Message}");
                return (false, "", "", "");
            }
        }

        public async Task<(bool success, string errorMessage)> DownloadAndInstallAsync(string downloadUrl, string targetVersion, IProgress<int> progress)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(downloadUrl))
                    return (false, "Không có đường dẫn tải. Release trên GitHub có đính kèm file .msi, .zip hoặc .rar chưa?");

                downloadUrl = downloadUrl.Trim();
                var isMsi = downloadUrl.EndsWith(".msi", StringComparison.OrdinalIgnoreCase);
                var isRar = downloadUrl.EndsWith(".rar", StringComparison.OrdinalIgnoreCase);

                if (isMsi)
                    return await DownloadAndRunMsiAsync(downloadUrl, targetVersion, progress);
                if (isRar)
                    return await DownloadAndInstallRarAsync(downloadUrl, targetVersion, progress);

                return await DownloadAndInstallZipAsync(downloadUrl, targetVersion, progress);
            }
            catch (Exception ex)
            {
                return (false, ex.Message);
            }
        }

        private async Task<(bool success, string errorMessage)> DownloadAndRunMsiAsync(string downloadUrl, string targetVersion, IProgress<int> progress)
        {
            var tempPath = Path.GetTempPath();
            var msiPath = Path.Combine(tempPath, "BaoCaoSoLieu_Update.msi");

            try
            {
                // Lưu phiên bản đích ngay để app sau khi cài xong đọc được
                if (!string.IsNullOrEmpty(targetVersion) && IsValidVersionString(targetVersion))
                {
                    try
                    {
                        var versionFile = GetInstalledVersionFilePath();
                        var dir = Path.GetDirectoryName(versionFile);
                        if (!string.IsNullOrEmpty(dir))
                        {
                            Directory.CreateDirectory(dir);
                            File.WriteAllText(versionFile, targetVersion.Trim());
                        }
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine($"Save version file: {ex.Message}");
                    }
                }

                progress?.Report(0);
                using (var response = await _httpClient.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead))
                {
                    response.EnsureSuccessStatusCode();
                    var totalBytes = response.Content.Headers.ContentLength ?? -1L;
                    await using (var contentStream = await response.Content.ReadAsStreamAsync())
                    await using (var fileStream = new FileStream(msiPath, FileMode.Create, FileAccess.Write, FileShare.None))
                    {
                        var buffer = new byte[81920];
                        var totalRead = 0L;
                        int bytesRead;
                        while ((bytesRead = await contentStream.ReadAsync(buffer)) != 0)
                        {
                            await fileStream.WriteAsync(buffer.AsMemory(0, bytesRead));
                            totalRead += bytesRead;
                            if (totalBytes > 0)
                                progress?.Report((int)((totalRead * 100) / totalBytes));
                        }
                    }
                }

                if (!File.Exists(msiPath) || new FileInfo(msiPath).Length == 0)
                    return (false, "File tải về trống hoặc không tồn tại.");

                progress?.Report(100);

                var startInfo = new ProcessStartInfo
                {
                    FileName = "msiexec.exe",
                    Arguments = $"/i \"{msiPath}\"",
                    UseShellExecute = true
                };
                Process.Start(startInfo);

                _httpClient?.Dispose();
                Application.Current?.Dispatcher.Invoke(() => Application.Current.Shutdown());
                return (true, "");
            }
            catch (HttpRequestException ex)
            {
                return (false, $"Không tải được file: {ex.Message}");
            }
            catch (Exception ex)
            {
                return (false, $"Lỗi: {ex.Message}");
            }
        }

        private async Task<(bool success, string errorMessage)> DownloadAndInstallZipAsync(string downloadUrl, string targetVersion, IProgress<int> progress)
        {
            var tempPath = Path.GetTempPath();
            var zipPath = Path.Combine(tempPath, "update.zip");
            var extractPath = Path.Combine(tempPath, "update_extracted");

            try
            {
                if (!string.IsNullOrEmpty(targetVersion) && IsValidVersionString(targetVersion))
                {
                    try
                    {
                        var versionFile = GetInstalledVersionFilePath();
                        var dir = Path.GetDirectoryName(versionFile);
                        if (!string.IsNullOrEmpty(dir))
                        {
                            Directory.CreateDirectory(dir);
                            File.WriteAllText(versionFile, targetVersion.Trim());
                        }
                    }
                    catch { }
                }

                progress?.Report(0);

                using (var response = await _httpClient.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead))
                {
                    response.EnsureSuccessStatusCode();
                    var totalBytes = response.Content.Headers.ContentLength ?? -1L;
                    using (var contentStream = await response.Content.ReadAsStreamAsync())
                    using (var fileStream = new FileStream(zipPath, FileMode.Create))
                    {
                        var buffer = new byte[8192];
                        var totalRead = 0L;
                        int bytesRead;
                        while ((bytesRead = await contentStream.ReadAsync(buffer, 0, buffer.Length)) != 0)
                        {
                            await fileStream.WriteAsync(buffer, 0, bytesRead);
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
                return (true, "");
            }
            catch (HttpRequestException ex)
            {
                return (false, $"Không tải được file: {ex.Message}");
            }
            catch (Exception ex)
            {
                return (false, $"Lỗi: {ex.Message}");
            }
        }

        private async Task<(bool success, string errorMessage)> DownloadAndInstallRarAsync(string downloadUrl, string targetVersion, IProgress<int> progress)
        {
            var tempPath = Path.GetTempPath();
            var rarPath = Path.Combine(tempPath, "update.rar");
            var extractPath = Path.Combine(tempPath, "update_extracted");

            try
            {
                if (!string.IsNullOrEmpty(targetVersion) && IsValidVersionString(targetVersion))
                {
                    try
                    {
                        var versionFile = GetInstalledVersionFilePath();
                        var dir = Path.GetDirectoryName(versionFile);
                        if (!string.IsNullOrEmpty(dir))
                        {
                            Directory.CreateDirectory(dir);
                            File.WriteAllText(versionFile, targetVersion.Trim());
                        }
                    }
                    catch { }
                }

                progress?.Report(0);

                using (var response = await _httpClient.GetAsync(downloadUrl, HttpCompletionOption.ResponseHeadersRead))
                {
                    response.EnsureSuccessStatusCode();
                    var totalBytes = response.Content.Headers.ContentLength ?? -1L;
                    await using (var contentStream = await response.Content.ReadAsStreamAsync())
                    await using (var fileStream = new FileStream(rarPath, FileMode.Create, FileAccess.Write, FileShare.None))
                    {
                        var buffer = new byte[81920];
                        var totalRead = 0L;
                        int bytesRead;
                        while ((bytesRead = await contentStream.ReadAsync(buffer)) != 0)
                        {
                            await fileStream.WriteAsync(buffer.AsMemory(0, bytesRead));
                            totalRead += bytesRead;
                            if (totalBytes > 0)
                                progress?.Report((int)((totalRead * 100) / totalBytes));
                        }
                    }
                }

                if (!File.Exists(rarPath) || new FileInfo(rarPath).Length == 0)
                    return (false, "File .rar tải về trống hoặc không tồn tại.");

                progress?.Report(90);

                if (Directory.Exists(extractPath))
                    Directory.Delete(extractPath, true);
                Directory.CreateDirectory(extractPath);

                using (var archive = ArchiveFactory.Open(rarPath))
                {
                    archive.WriteToDirectory(extractPath, new ExtractionOptions { ExtractFullPath = true, Overwrite = true });
                }

                progress?.Report(100);

                await ReplaceApplicationFiles(extractPath);
                return (true, "");
            }
            catch (HttpRequestException ex)
            {
                return (false, $"Không tải được file: {ex.Message}");
            }
            catch (Exception ex)
            {
                return (false, $"Lỗi giải nén .rar: {ex.Message}");
            }
        }

        /// <summary>Chỉ lấy phần số của version (bỏ hậu tố +sha, -beta, v.v.).</summary>
        private static string StripToVersionOnly(string? version)
        {
            if (string.IsNullOrWhiteSpace(version)) return "";
            var s = version.Trim().TrimStart('v', 'V');
            var firstNonDigitOrDot = -1;
            for (var i = 0; i < s.Length; i++)
            {
                var c = s[i];
                if (c != '.' && !char.IsDigit(c))
                {
                    firstNonDigitOrDot = i;
                    break;
                }
            }
            if (firstNonDigitOrDot >= 0)
                s = s.Substring(0, firstNonDigitOrDot);
            return s.TrimEnd('.');
        }

        private static bool IsValidVersionString(string version)
        {
            if (string.IsNullOrWhiteSpace(version)) return false;
            try
            {
                var s = StripToVersionOnly(version);
                if (string.IsNullOrEmpty(s)) return false;
                _ = new Version(s);
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
            var s = StripToVersionOnly(version);
            if (string.IsNullOrEmpty(s)) return "";
            try
            {
                var v = new Version(s);
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
                var c = StripToVersionOnly(current);
                var l = StripToVersionOnly(latest);
                if (string.IsNullOrEmpty(c)) return true;
                if (string.IsNullOrEmpty(l)) return false;
                return new Version(l) > new Version(c);
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

            if (appPath != null && appPath.Contains(@"\AppData\Local\Temp\.net\"))
            {
                var possiblePaths = new[]
                {
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), APP_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), APP_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), APP_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), APP_NAME),
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), APP_NAME)
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
                if (appPath != null && appPath.Contains(@"\AppData\Local\Temp\.net\"))
                {
                    appPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), APP_NAME);
                    Directory.CreateDirectory(appPath);
                }
            }

            if (string.IsNullOrEmpty(appPath))
                appPath = AppDomain.CurrentDomain.BaseDirectory;

            var exePath = Path.Combine(appPath, EXE_NAME);
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

            var batchFile = Path.Combine(Path.GetTempPath(), $"update_{Guid.NewGuid():N}.bat");
            var zipPath = Path.Combine(Path.GetTempPath(), "update.zip");
            var extractPath = Path.Combine(Path.GetTempPath(), "update_extracted");

            var needsAdmin = RequiresAdmin(appPath);
            var hasWriteAccess = CanWriteToDirectory(appPath);
            var escapedAppPath = appPath.Replace("\"", "\"\"");
            var escapedSourcePath = sourcePath.Replace("\"", "\"\"");
            var escapedExePath = exePath.Replace("\"", "\"\"");

            var batchContent = $@"@echo off
title Update - {EXE_NAME}
color 0A
echo Waiting for application to close...
:wait
tasklist /FI ""IMAGENAME eq {EXE_NAME}"" 2>NUL | find /I /N ""{EXE_NAME}"">NUL
if ""%ERRORLEVEL%""==""0"" (
    timeout /t 2 /nobreak > nul
    goto wait
)
timeout /t 2 /nobreak > nul
taskkill /F /IM ""{EXE_NAME}"" 2>NUL
timeout /t 2 /nobreak > nul
if not exist ""{escapedSourcePath}"" ( echo ERROR: Source not found. & pause & exit /b 1 )
if exist ""{escapedExePath}"" ( del /F /Q ""{escapedExePath}"" 2>NUL & timeout /t 1 /nobreak > nul )
robocopy ""{escapedSourcePath}"" ""{escapedAppPath}"" /E /IS /IT /R:3 /W:2 /NP /NFL /NDL
if %ERRORLEVEL% GEQ 8 ( echo Copy failed. & pause & exit /b 1 )
timeout /t 1 /nobreak > nul
if not exist ""{escapedExePath}"" ( echo Exe not copied. & pause & exit /b 1 )
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
                var psScript = Path.Combine(Path.GetTempPath(), $"update_{Guid.NewGuid():N}.ps1");
                await File.WriteAllTextAsync(psScript, $"Start-Process -FilePath '{batchFile}' -Verb RunAs -Wait");
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
            await Task.Delay(1000);
            _httpClient?.Dispose();
            Application.Current?.Dispatcher.Invoke(() => Application.Current.Shutdown());
        }
    }
}
