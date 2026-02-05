using BaoCaoSoLieu.Message;
using BaoCaoSoLieu.Repos.Mappers.Interface;
using BaoCaoSoLieu.Repos.Model;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Messaging;
using System.Collections.ObjectModel;
using System.Windows;

namespace BaoCaoSoLieu.ViewModel.PageViewModel
{
    public partial class Bang1VM : ObservableObject, IRecipient<LoadDataMessage>, IRecipient<ClearDataMessage>
    {
        private readonly IReportMapper _reportMapper;

        [ObservableProperty]
        private ObservableCollection<Bang1_KhamChuaBenhToanVien>? bang1List;

        public Bang1VM(IReportMapper reportMapper)
        {
            _reportMapper = reportMapper;
            WeakReferenceMessenger.Default.Register<LoadDataMessage>(this);
            WeakReferenceMessenger.Default.Register<ClearDataMessage>(this);
        }

        public void Receive(LoadDataMessage message)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    if (message.tuNgay == null || message.denNgay == null)
                    {
                        WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang1", false, "Ngày tháng không hợp lệ"));
                        return;
                    }
                    await LoadDataBang1(message.tuNgay, message.denNgay);
                    WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang1", true));
                }
                catch (Exception ex)
                {
                    WeakReferenceMessenger.Default.Send(new ErrorMessage("Lỗi khi lấy dữ liệu từ bảng 1: " + ex.Message));
                    WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang1", false, ex.Message));
                }
            });
        }

        public void Receive(ClearDataMessage message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                Bang1List?.Clear();
                Bang1List = null;
            });
        }

        private async Task LoadDataBang1(DateTime? tuNgay, DateTime? denNgay)
        {
            try
            {
                // Lấy data mới với tham số ngày tháng
                var data = await _reportMapper.GetBang1(tuNgay, denNgay);
                // Gán vào property --> View sẽ tự update
                    Bang1List = new ObservableCollection<Bang1_KhamChuaBenhToanVien>(data);      

            }
            catch
            {
                throw;
            }
        }
    }
}
