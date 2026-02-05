using BaoCaoSoLieu.Message;
using BaoCaoSoLieu.Repos.Mappers.Interface;
using BaoCaoSoLieu.Repos.Model;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Messaging;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Windows;

namespace BaoCaoSoLieu.ViewModel.PageViewModel
{
    public partial class Bang4VM : ObservableObject, IRecipient<LoadDataMessage>, IRecipient<ClearDataMessage>
    {
        private readonly IReportMapper _reportMapper;

        [ObservableProperty]
        private ObservableCollection<Bang4_SoLieuTungPhongKhamKhoaKhamBenh>? bang4List;

        public Bang4_SoLieuTungPhongKhamKhoaKhamBenh Bang4Total { get; } = new();

        [ObservableProperty]
        private ObservableCollection<Bang4_KhoaNgoaiTru>? bang4KhoaNgoaiTruList;

        [ObservableProperty]
        private ObservableCollection<Bang4_CacPhongCoNhieuCongVao>? bang4CacPhongCoNhieuCongVaoList;
        public Bang4_CacPhongCoNhieuCongVao Bang4CacPhongCoNhieuCongVaoTotal { get; } = new();

        [ObservableProperty]
        private ObservableCollection<Bang4_PhongKhamYeuCau>? bang4PhongKhamYeuCauList;
        public Bang4_PhongKhamYeuCau Bang4PhongKhamYeuCauTotal { get; } = new();

        public Bang4VM(IReportMapper reportMapper)
        {
            _reportMapper = reportMapper;
            WeakReferenceMessenger.Default.Register<LoadDataMessage>(this);
            WeakReferenceMessenger.Default.Register<ClearDataMessage>(this);
        }

        // nhận tín hiệu từ tabcontrol để lấy ngày tháng
        public void Receive(LoadDataMessage message)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    await LoadDataBang4(message.tuNgay, message.denNgay);
                    WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang4", true));
                }
                catch (Exception ex)
                {
                    WeakReferenceMessenger.Default.Send(new ErrorMessage("Lỗi khi lấy dữ liệu từ bảng 4: " + ex.Message));
                    WeakReferenceMessenger.Default.Send(new DataLoadedMessage("Bang4", false, ex.Message));
                }
            });
        }

        // nhận tín hiệu xóa sạch dữ liệu bảng
        public void Receive(ClearDataMessage message)
        {
            Application.Current.Dispatcher.Invoke(() =>
            {
                ClearCollection(Bang4List);
                ClearCollection(Bang4KhoaNgoaiTruList);
                ClearCollection(Bang4CacPhongCoNhieuCongVaoList);
                ClearCollection(Bang4PhongKhamYeuCauList);
            });
        }

        private void ClearCollection<T>(ObservableCollection<T>? collection) where T : class
        {
            if (collection != null)
            {
                collection.Clear();
                collection = null;
            }
        }

        private async Task LoadDataBang4(DateTime? tuNgay, DateTime? denNgay)
        {
            try
            {
                // Chạy song song 4 cái Task
                var t1 = _reportMapper.GetBang4(tuNgay, denNgay);
                var t2 = _reportMapper.GetBang4KhoaNgoaiTru(tuNgay, denNgay);
                var t3 = _reportMapper.GetBang4CacPhongCoNhieuCongVao(tuNgay, denNgay);
                var t4 = _reportMapper.GetBang4PhongKhamYeuCau(tuNgay, denNgay);

                await Task.WhenAll(t1, t2, t3, t4);

                Application.Current.Dispatcher.Invoke(() =>
                {
                    // Setup Bang4List với event handlers
                    Bang4List = new ObservableCollection<Bang4_SoLieuTungPhongKhamKhoaKhamBenh>(t1.Result);
                    SetupCollectionWithPropertyChangeHandlers(Bang4List, RecalculateTotalsBang4);

                    // Setup các collection khác
                    Bang4KhoaNgoaiTruList = new ObservableCollection<Bang4_KhoaNgoaiTru>(t2.Result);

                    Bang4CacPhongCoNhieuCongVaoList = new ObservableCollection<Bang4_CacPhongCoNhieuCongVao>(t3.Result);
                    SetupCollectionWithPropertyChangeHandlers(Bang4CacPhongCoNhieuCongVaoList, RecalculateTotalsBang4CPCNCV);


                    // Setup Bang4PhongKhamYeuCauList với event handlers
                    Bang4PhongKhamYeuCauList = new ObservableCollection<Bang4_PhongKhamYeuCau>(t4.Result);
                    SetupCollectionWithPropertyChangeHandlers(Bang4PhongKhamYeuCauList, RecalculateTotalsBang4PKYC);

                    // Tính toán tổng ban đầu
                    RecalculateTotalsBang4();
                    RecalculateTotalsBang4PKYC();
                });
            }
            catch
            {
                throw;
            }
        }

        private void SetupCollectionWithPropertyChangeHandlers<T>(ObservableCollection<T> collection, Action recalculateAction) where T : class, INotifyPropertyChanged
        {
            collection.CollectionChanged += (sender, e) => HandleCollectionChanged<T>(e, recalculateAction);
            
            foreach (var item in collection)
            {
                item.PropertyChanged += (sender, e) => HandlePropertyChanged(e, recalculateAction);
            }
        }

        private void HandleCollectionChanged<T>(NotifyCollectionChangedEventArgs e, Action recalculateAction) where T : class, INotifyPropertyChanged
        {
            if (e.NewItems != null)
            {
                foreach (T item in e.NewItems)
                {
                    item.PropertyChanged += (sender, args) => HandlePropertyChanged(args, recalculateAction);
                }
            }
            if (e.OldItems != null)
            {
                foreach (T item in e.OldItems)
                {
                    item.PropertyChanged -= (sender, args) => HandlePropertyChanged(args, recalculateAction);
                }
            }
            recalculateAction();
        }

        private void HandlePropertyChanged(PropertyChangedEventArgs e, Action recalculateAction)
        {
            var relevantProperties = new[] { "ChiTieuNgay", "Thang", "SoLuong", "TongSo" };
            if (relevantProperties.Contains(e.PropertyName))
            {
                recalculateAction();
            }
        }

        private void RecalculateTotalsBang4()
        {
            if (Bang4List != null)
            {
                Bang4Total.ChiTieuNgay = Bang4List.Sum(i => i.ChiTieuNgay);
                Bang4Total.Thang = Bang4List.Sum(i => i.Thang);
                Bang4Total.SoLuong = Bang4List.Sum(i => i.SoLuong);
            }
        }

        private void RecalculateTotalsBang4PKYC()
        {
            if (Bang4PhongKhamYeuCauList != null)
            {
                Bang4PhongKhamYeuCauTotal.ChiTieuNgay = Bang4PhongKhamYeuCauList.Sum(i => i.ChiTieuNgay);
                Bang4PhongKhamYeuCauTotal.Thang = Bang4PhongKhamYeuCauList.Sum(i => i.Thang);
                Bang4PhongKhamYeuCauTotal.SoLuong = Bang4PhongKhamYeuCauList.Sum(i => i.SoLuong);
            }
        }

        private void RecalculateTotalsBang4CPCNCV()
        {
            if (Bang4CacPhongCoNhieuCongVaoList != null)
            {
                Bang4CacPhongCoNhieuCongVaoTotal.TongSo = Bang4CacPhongCoNhieuCongVaoList.Sum(i => i.TongSo);
                Bang4CacPhongCoNhieuCongVaoTotal.Thang = Bang4CacPhongCoNhieuCongVaoList.Sum(i => i.Thang);
             
            }
        }
    }
}

