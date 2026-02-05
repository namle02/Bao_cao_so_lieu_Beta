using CommunityToolkit.Mvvm.ComponentModel;
using System.Collections.ObjectModel;
using Microsoft.Extensions.DependencyInjection;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using BaoCaoSoLieu.ViewModel.PageViewModel;
using BaoCaoSoLieu.Message;
using BaoCaoSoLieu.Services.Interface;
using BaoCaoSoLieu.Repos.Model;
using System.Windows.Input;

namespace BaoCaoSoLieu.ViewModel.ControlViewModel
{
    public partial class TabControlVM : ObservableObject, IRecipient<DataLoadedMessage>, IRecipient<ExcelExportMessage>
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IExcelExportService _excelExportService;
        private readonly INotificationService _notificationService;
        private TaskCompletionSource<bool>? _dataLoadCompletionSource;
        private readonly HashSet<string> _expectedTables = new();

        [ObservableProperty]
        private string? selectedTable;

        [ObservableProperty]
        private DateTime? tuNgay;

        [ObservableProperty]
        private DateTime? denNgay;

        [ObservableProperty]
        private bool isLoading = false;

        [ObservableProperty]
        private string loadingText = "Đang tải dữ liệu...";

        public ObservableCollection<string> TableOptions { get; }

        // Tạo command thủ công
        public ICommand TimKiemCommand { get; }
        
        // Command xuất Excel
        public ICommand XuatBaoCaoCommand { get; }

        public ObservableObject? CurrentTableVM
        {
            get
            {
                switch (SelectedTable)
                {
                    case "Kết quả toàn viện":
                        return _serviceProvider.GetRequiredService<Bang1VM>();
                    case "Kết quả thực hiện kế hoạch của các khoa nội trú tuần":
                        return _serviceProvider.GetRequiredService<Bang2VM>();
                    case "Thực hiện các dịch vụ phẫu theo yêu cầu của các khoa nội trú tuần":
                        return _serviceProvider.GetRequiredService<Bang3VM>();
                    case "Số liệu của từng phòng khám khoa Khám bệnh tuần":
                        return _serviceProvider.GetRequiredService<Bang4VM>();
                    case "Cập nhật":
                        return _serviceProvider.GetRequiredService<CapNhatVM>();
                    default:
                        return _serviceProvider.GetRequiredService<Bang1VM>();
                }
            }
        }

        public TabControlVM(IServiceProvider serviceProvider, IExcelExportService excelExportService, INotificationService notificationService)
        {
            _serviceProvider = serviceProvider;
            _excelExportService = excelExportService;
            _notificationService = notificationService;
            TableOptions = new ObservableCollection<string>
            {
                "Kết quả toàn viện",
                "Kết quả thực hiện kế hoạch của các khoa nội trú tuần",
                "Thực hiện các dịch vụ phẫu theo yêu cầu của các khoa nội trú tuần",
                "Số liệu của từng phòng khám khoa Khám bệnh tuần",
                "Cập nhật"
            };
            SelectedTable = TableOptions.First();
            TuNgay = DateTime.Now;
            DenNgay = DateTime.Now;
            
            // Tạo command thủ công
            TimKiemCommand = new AsyncRelayCommand(TimKiemAsync, CanTimKiem);
            XuatBaoCaoCommand = new AsyncRelayCommand(XuatBaoCaoAsync, CanXuatBaoCao);
            
            // Đăng ký nhận messages
            WeakReferenceMessenger.Default.Register<DataLoadedMessage>(this);
            WeakReferenceMessenger.Default.Register<ExcelExportMessage>(this);
            
            PropertyChanged += (s, e) =>
            {
                if (e.PropertyName == nameof(SelectedTable))
                    OnPropertyChanged(nameof(CurrentTableVM));
                if (e.PropertyName == nameof(IsLoading))
                {
                    (TimKiemCommand as AsyncRelayCommand)?.NotifyCanExecuteChanged();
                    (XuatBaoCaoCommand as AsyncRelayCommand)?.NotifyCanExecuteChanged();
                }
            };
        }

        public void Receive(DataLoadedMessage message)
        {
            if (_dataLoadCompletionSource != null && _expectedTables.Contains(message.TableName))
            {
                _expectedTables.Remove(message.TableName);
                
                if (!message.Success)
                {
                    WeakReferenceMessenger.Default.Send(new ErrorMessage($"Lỗi khi tải dữ liệu {message.TableName}: {message.ErrorMessage}"));
                }
                
                // Nếu tất cả tables đã load xong
                if (_expectedTables.Count == 0)
                {
                    _dataLoadCompletionSource.TrySetResult(true);
                }
            }
        }
        
        public void Receive(ExcelExportMessage message)
        {
            if (message.Success)
            {
                _notificationService.ShowSuccess($"{message.Message}\nFile được lưu tại: {message.FilePath}");
            }
            else
            {
                _notificationService.ShowError(message.Message);
            }
        }

        private async Task TimKiemAsync()
        {
            try
            {
                IsLoading = true;
                LoadingText = "Đang xóa dữ liệu cũ...";
                
                // Clear data từ tất cả các ViewModel
                await ClearAllDataAsync();
                
                LoadingText = "Đang tải dữ liệu mới...";
                
                // Gửi tín hiệu load data và đợi tất cả hoàn thành
                await LoadAllDataAsync();
                
                LoadingText = "Hoàn thành!";
                await Task.Delay(500); // Hiển thị thông báo hoàn thành trong 0.5 giây
            }
            catch (Exception ex)
            {
                WeakReferenceMessenger.Default.Send(new ErrorMessage("Lỗi khi tải dữ liệu: " + ex.Message));
            }
            finally
            {
                IsLoading = false;
                LoadingText = "Đang tải dữ liệu...";
            }
        }

        private async Task LoadAllDataAsync()
        {
            // Reset completion source
            _dataLoadCompletionSource = new TaskCompletionSource<bool>();
            _expectedTables.Clear();

            _expectedTables.Add("Bang1");
            _expectedTables.Add("Bang2");
            _expectedTables.Add("Bang3");
            _expectedTables.Add("Bang4");
            
            // Gửi tín hiệu load data
            WeakReferenceMessenger.Default.Send(new LoadDataMessage("Đây là tín hiệu gửi đến các bảng", TuNgay, DenNgay));
            
            // Đợi tất cả data load xong hoặc timeout
            var timeoutTask = Task.Delay(1000000); // 100 giây timeout
            var completedTask = await Task.WhenAny(_dataLoadCompletionSource.Task, timeoutTask);
            
            if (completedTask == timeoutTask)
            {
                WeakReferenceMessenger.Default.Send(new ErrorMessage("Timeout khi tải dữ liệu. Vui lòng thử lại."));
            }
        }

        private bool CanTimKiem() => !IsLoading;
        
        private bool CanXuatBaoCao() => !IsLoading && HasData();

        private async Task ClearAllDataAsync()
        {
            try
            {
                // Clear data từ tất cả các ViewModel
                var bang1VM = _serviceProvider.GetRequiredService<Bang1VM>();
                var bang2VM = _serviceProvider.GetRequiredService<Bang2VM>();
                var bang3VM = _serviceProvider.GetRequiredService<Bang3VM>();
                var bang4VM = _serviceProvider.GetRequiredService<Bang4VM>();

                // Gửi tín hiệu clear data
                WeakReferenceMessenger.Default.Send(new ClearDataMessage());
                
                // Đợi một chút để đảm bảo data được clear
                await Task.Delay(50);
            }
            catch (Exception ex)
            {
                // Log lỗi nhưng không throw để không ảnh hưởng đến quá trình load data
                System.Diagnostics.Debug.WriteLine($"Lỗi khi clear data: {ex.Message}");
            }
        }
        
        private async Task XuatBaoCaoAsync()
        {
            try
            {
                IsLoading = true;
                LoadingText = "Đang xuất báo cáo Excel...";
                
                // Lấy dữ liệu từ các ViewModel
                var bang1VM = _serviceProvider.GetRequiredService<Bang1VM>();
                var bang2VM = _serviceProvider.GetRequiredService<Bang2VM>();
                var bang3VM = _serviceProvider.GetRequiredService<Bang3VM>();
                var bang4VM = _serviceProvider.GetRequiredService<Bang4VM>();
                
                var filePath = await _excelExportService.ExportToExcelAsync(
                    bang1VM.Bang1List,
                    bang2VM.Bang2List,
                    bang3VM.Bang3List,
                    bang4VM.Bang4List,
                    bang4VM.Bang4KhoaNgoaiTruList,
                    bang4VM.Bang4CacPhongCoNhieuCongVaoList,
                    bang4VM.Bang4PhongKhamYeuCauList,
                    TuNgay,
                    DenNgay);
                
                _notificationService.ShowSuccess($"Xuất báo cáo thành công!\nFile được lưu tại: {filePath}");
                
                LoadingText = "Hoàn thành!";
                await Task.Delay(500);
            }
            catch (Exception ex)
            {
                _notificationService.ShowError("Lỗi khi xuất báo cáo: " + ex.Message);
            }
            finally
            {
                IsLoading = false;
                LoadingText = "Đang tải dữ liệu...";
            }
        }
        
        private bool HasData()
        {
            try
            {
                var bang1VM = _serviceProvider.GetRequiredService<Bang1VM>();
                var bang2VM = _serviceProvider.GetRequiredService<Bang2VM>();
                var bang3VM = _serviceProvider.GetRequiredService<Bang3VM>();
                var bang4VM = _serviceProvider.GetRequiredService<Bang4VM>();
                
                return (bang1VM.Bang1List?.Any() == true) ||
                       (bang2VM.Bang2List?.Any() == true) ||
                       (bang3VM.Bang3List?.Any() == true) ||
                       (bang4VM.Bang4List?.Any() == true) ||
                       (bang4VM.Bang4KhoaNgoaiTruList?.Any() == true) ||
                       (bang4VM.Bang4CacPhongCoNhieuCongVaoList?.Any() == true) ||
                       (bang4VM.Bang4PhongKhamYeuCauList?.Any() == true);
            }
            catch
            {
                return false;
            }
        }
        
    }
}

