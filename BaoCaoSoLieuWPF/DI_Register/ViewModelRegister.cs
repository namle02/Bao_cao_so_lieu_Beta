using Microsoft.Extensions.DependencyInjection;
using BaoCaoSoLieu.ViewModel;
using BaoCaoSoLieu.ViewModel.ControlViewModel;
using BaoCaoSoLieu.ViewModel.PageViewModel;

namespace BaoCaoSoLieu.DI_Register
{
    public static class ViewModelRegister
    {
        public static void Register(IServiceCollection services)
        {
            // đăng kí các view model chính
            services.AddSingleton<MainViewModel>();

            // đăng kí các control viewmodel 
            services.AddSingleton<TabControlVM>();



            // đăng kí các page viewmodel
            services.AddSingleton<Bang1VM>();
            services.AddSingleton<Bang2VM>();
            services.AddSingleton<Bang3VM>();
            services.AddSingleton<Bang4VM>();
            services.AddSingleton<CapNhatVM>();
        }
    }
}
