using Microsoft.Extensions.DependencyInjection;
using System.Windows;
using BaoCaoSoLieu.DI_Register;
using BaoCaoSoLieu.Services.Interface;
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

            base.OnStartup(e);
        }
        catch (Exception ex)
        {
            MessageBox.Show("Lỗi: " + ex);
        }

    }
}

