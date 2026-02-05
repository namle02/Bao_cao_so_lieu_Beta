using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Windows;
using BaoCaoSoLieu.Message;
using BaoCaoSoLieu.Repos.Mappers.Interface;
using BaoCaoSoLieu.Repos.Model;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Messaging;


namespace BaoCaoSoLieu.ViewModel.PageViewModel
{
    public partial class Bang3VM
        : ObservableObject,
            IRecipient<LoadDataMessage>,
            IRecipient<ClearDataMessage>
    {
        private readonly IReportMapper _reportMapper;

        [ObservableProperty]
        private ObservableCollection<Bang3_KetQuaThucHienDichVuYeuCau>? bang3List;

        public Bang3_KetQuaThucHienDichVuYeuCau DongTongCong { get; } = new();

        public Bang3VM(IReportMapper reportMapper)
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
                    await LoadDataBang3(message.tuNgay, message.denNgay);
                    WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang3", true));
                }
                catch (Exception ex)
                {
                    WeakReferenceMessenger.Default.Send(
                        new ErrorMessage("Lỗi khi lấy dữ liệu từ bảng 3: " + ex.Message)
                    );
                    WeakReferenceMessenger.Default.Send(
                        new DataLoadedMessage("Bang3", false, ex.Message)
                    );
                }
            });
        }

        public void Receive(ClearDataMessage message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                Bang3List?.Clear();
                Bang3List = null;
            });
        }

        private async Task LoadDataBang3(DateTime? tuNgay, DateTime? denNgay)
        {
            try
            {
                // Lấy data mới với tham số ngày tháng
                var data = await _reportMapper.GetBang3(tuNgay, denNgay);
                // Gán vào property --> View sẽ tự update
                Application.Current.Dispatcher.Invoke(() =>
                {
                    Bang3List = new ObservableCollection<Bang3_KetQuaThucHienDichVuYeuCau>(data);
                    Bang3List.CollectionChanged += Item_CollectionChanged;

                    foreach (var item in Bang3List)
                    {
                        item.PropertyChanged += Item_PropertyChanged;
                    }

                    RecalculateTotals();
                });
            }
            catch
            {
                throw;
            }
        }

        private void Item_CollectionChanged(object? sender, NotifyCollectionChangedEventArgs e)
        {
            if (e.NewItems != null)
            {
                foreach (Bang3_KetQuaThucHienDichVuYeuCau item in e.NewItems)
                {
                    item.PropertyChanged += Item_PropertyChanged;
                }
            }
            if (e.OldItems != null)
            {
                foreach (Bang3_KetQuaThucHienDichVuYeuCau item in e.OldItems)
                {
                    item.PropertyChanged -= Item_PropertyChanged;
                }
            }
            RecalculateTotals();
        }

        private void Item_PropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(Bang3_KetQuaThucHienDichVuYeuCau.KeHoach) ||
                e.PropertyName == nameof(Bang3_KetQuaThucHienDichVuYeuCau.ThucHien) || e.PropertyName == nameof(Bang3_KetQuaThucHienDichVuYeuCau.Tong))
            {
                RecalculateTotals();
            }
        }

        private void RecalculateTotals()
        {
            DongTongCong.ThucHien = Bang3List?.Sum(i => i.ThucHien);
            DongTongCong.KeHoach = Bang3List?.Sum(i => i.KeHoach);
            DongTongCong.Tong = Bang3List?.Sum(i => i.Tong);
        }
    }
}
