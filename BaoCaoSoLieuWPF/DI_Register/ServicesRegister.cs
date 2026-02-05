using BaoCaoSoLieu.Repos.Mappers.Implement;
using BaoCaoSoLieu.Repos.Mappers.Interface;
using BaoCaoSoLieu.Services.Implement;
using BaoCaoSoLieu.Services.Interface;
using Microsoft.Extensions.DependencyInjection;


namespace BaoCaoSoLieu.DI_Register
{
    public static class ServicesRegister
    {
        public static void Register(IServiceCollection services)
        {
            services.AddSingleton<IConfigServices, ConfigServices>();

            // đăng kí mapper
            services.AddTransient<IReportMapper, ReportMapper>();

            // đăng kí service xuất Excel
            services.AddTransient<IExcelExportService, ExcelExportService>();
            
            // đăng kí service thông báo
            services.AddSingleton<INotificationService, NotificationService>();

        }
    }
}
