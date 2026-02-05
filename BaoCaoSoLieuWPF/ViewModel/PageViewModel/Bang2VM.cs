using BaoCaoSoLieu.Message;
using BaoCaoSoLieu.Repos.Mappers.Interface;
using BaoCaoSoLieu.Repos.Model;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Messaging;
using System.Collections.ObjectModel;
using System.Windows;

namespace BaoCaoSoLieu.ViewModel.PageViewModel
{
    public partial class Bang2VM : ObservableObject, IRecipient<LoadDataMessage>, IRecipient<ClearDataMessage>
    {
        private readonly IReportMapper _reportMapper;

        [ObservableProperty]
        private ObservableCollection<Bang2_KetQuaThucHienKhoaNoiTru>? bang2List;

        public Bang2VM(IReportMapper reportMapper)
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
                        WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang2", false, "Ngày tháng không hợp lệ"));
                        return;
                    }
                    await LoadDataBang2(message.tuNgay, message.denNgay);
                    WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang2", true));
                }
                catch (Exception ex)
                {
                    WeakReferenceMessenger.Default.Send(new ErrorMessage("Lỗi khi lấy dữ liệu từ bảng 2: " + ex.Message));
                    WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang2", false, ex.Message));
                }
            });
        }

        public void Receive(ClearDataMessage message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                Bang2List?.Clear();
                Bang2List = null;
            });
        }

        private async Task LoadDataBang2(DateTime? tuNgay, DateTime? denNgay)
        {
            try
            {
                // Lấy data mới với tham số ngày tháng
                var data = await _reportMapper.GetBang2(tuNgay, denNgay);
                // Gán vào property --> View sẽ tự update
                Application.Current.Dispatcher.Invoke(() =>
                {
                    Bang2List = new ObservableCollection<Bang2_KetQuaThucHienKhoaNoiTru>(data);
                });
               
            }
            catch
            {
                throw;
            }
        }
    }
}
