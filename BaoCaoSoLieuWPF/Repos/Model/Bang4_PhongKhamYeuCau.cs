using CommunityToolkit.Mvvm.ComponentModel;
using System.ComponentModel;

namespace BaoCaoSoLieu.Repos.Model
{
    public partial class Bang4_PhongKhamYeuCau : ObservableObject
    {
        public static event Action? SoNgayHoatDongChangedGlobally; // trường này không cần in ra sheet

        [ObservableProperty]
        private int? stt;

        [ObservableProperty]
        private string? phongKham;

        [ObservableProperty]
        private static int? soNgayHoatDongGlobal = 25; // trường này không cần in ra sheet

        [ObservableProperty]
        private int? soNgayHoatDong; // trường này không cần in ra sheet

        [ObservableProperty]
        private int? chiTieuNgay;

        [ObservableProperty]
        private int? thang;

        public string? SoVoiKeHoach
        {
            get
            {
                return (chiTieuNgay == null || thang == null || chiTieuNgay == 0) ? null : $"{(int)Math.Ceiling((double)thang / ((double)soNgayHoatDong * (double)chiTieuNgay)   * 100)}%";
            }
        }

        [ObservableProperty]
        private int? soLuong;

        public string? TyLeNhapVien => (soLuong == null || thang == null || thang == 0) ? "0%" : $"{(int)Math.Ceiling((double)soLuong / (double)thang * 100)}%";

        [ObservableProperty]
        private int? kh_TbHs;

        [ObservableProperty]
        private int? th_TbHs;

        public string? TyLeTC => (kh_TbHs == null || th_TbHs == null || kh_TbHs == 0) ? null : $"{(int)Math.Ceiling((double)th_TbHs / (double)kh_TbHs * 100)}%";

        partial void OnSoNgayHoatDongChanged(int? oldValue, int? newValue)
        {
            if (soNgayHoatDongGlobal != newValue)
            {
                soNgayHoatDongGlobal = newValue;
                SoNgayHoatDongChangedGlobally?.Invoke(); // 🔥 Cập nhật cho tất cả instance
            }

            OnPropertyChanged(nameof(SoVoiKeHoach)); // đảm bảo cập nhật lại UI
        }

        partial void OnChiTieuNgayChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(SoVoiKeHoach));
        }

        partial void OnThangChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(SoVoiKeHoach));
            OnPropertyChanged(nameof(TyLeNhapVien));
        }

        partial void OnSoLuongChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(TyLeNhapVien));
        }

        partial void OnKh_TbHsChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(TyLeTC));

        partial void OnTh_TbHsChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(TyLeTC));



        public Bang4_PhongKhamYeuCau()
        {
            // Khởi tạo giá trị ban đầu từ global
            SoNgayHoatDong = soNgayHoatDongGlobal;

            SoNgayHoatDongChangedGlobally += () =>
            {
                // ⚠️ Tránh vòng lặp vô hạn bằng kiểm tra
                if (SoNgayHoatDong != soNgayHoatDongGlobal)
                {
                    SoNgayHoatDong = soNgayHoatDongGlobal;
                }

                // Đảm bảo cập nhật lại SoVoiKeHoach khi global thay đổi
                OnPropertyChanged(nameof(SoVoiKeHoach));
            };
        }
    }
}
