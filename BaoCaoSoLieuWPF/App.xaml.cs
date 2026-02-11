using Microsoft.Extensions.DependencyInjection;
using System.Windows;
using BaoCaoSoLieu.DI_Register;
using BaoCaoSoLieu.Services.Interface;
using BaoCaoSoLieu.ViewModel.ControlViewModel;
using BaoCaoSoLieu.ViewModel.PageViewModel;


namespace BaoCaoSoLieu;

/// <summary>
/// Interaction logic for App.xaml
/// </summary>
public partial class App : Application
{
    private readonly IServiceProvider serviceProvider;
    private readonly IConfigServices _config;
    public App()
    {
        var services = new ServiceCollection();
        ConfigureServices(services);
        serviceProvider = services.BuildServiceProvider();

        _config = serviceProvider.GetRequiredService<IConfigServices>();
    }

    private void ConfigureServices(IServiceCollection services)
    {
        WindowRegister.Register(services);
        ServicesRegister.Register(services);
        ViewModelRegister.Register(services);
    }

    protected override async void OnStartup(StartupEventArgs e)
    {
        try
        {

            await _config.GetConfig();
            var mainwindow = serviceProvider.GetRequiredService<MainWindow>();
            mainwindow.Show();

            serviceProvider.GetRequiredService<Bang1VM>();
            serviceProvider.GetRequiredService<Bang2VM>();
            serviceProvider.GetRequiredService<Bang3VM>();
            serviceProvider.GetRequiredService<Bang4VM>();

            // Kiểm tra cập nhật một lần khi mở ứng dụng; nếu có bản mới thì popup hỏi có muốn cập nhật không
            var updateService = serviceProvider.GetRequiredService<IUpdateService>();
            _ = Task.Run(async () =>
            {
                try
                {
                    var (hasUpdate, latestVer, _, _) = await updateService.CheckForUpdatesAsync();
                    if (!hasUpdate || string.IsNullOrWhiteSpace(latestVer))
                        return;

                    var ver = latestVer.Trim();

                    Application.Current?.Dispatcher.Invoke(() =>
                    {
                        var result = MessageBox.Show(
                            Application.Current.MainWindow,
                            $"Có phiên bản mới v{ver}. Bạn có muốn cập nhật ngay?",
                            "Cập nhật phần mềm",
                            MessageBoxButton.YesNo,
                            MessageBoxImage.Question);

                        if (result != MessageBoxResult.Yes)
                            return;

                        // Chuyển sang tab Cập nhật để người dùng tải/cài từ đó
                        var tabVm = serviceProvider.GetRequiredService<TabControlVM>();
                        tabVm.SelectedTable = "Cập nhật";
                    });
                }
                catch
                {
                    // Bỏ qua lỗi khi kiểm tra cập nhật lúc khởi động (mạng, API, ...)
                }
            });

            base.OnStartup(e);
        }
        catch (Exception ex)
        {
            MessageBox.Show("Lỗi: " + ex);
        }

    }
}

