using BaoCaoSoLieu.View.ControlView;
using BaoCaoSoLieu.View.PageView;
using Microsoft.Extensions.DependencyInjection;


namespace BaoCaoSoLieu.DI_Register
{
    public static class WindowRegister
    {
        public static void Register(IServiceCollection services)
        {
            // đăng kí các view chính
            services.AddSingleton<MainWindow>();

            // đăng kí các control
            services.AddSingleton<TabControl>();

            // đăng kí các page
            //services.AddSingleton<Bang1>();
            //services.AddSingleton<Bang2>();
            //services.AddSingleton<Bang3>();
            //services.AddSingleton<Bang4>();
        }
    }
}
