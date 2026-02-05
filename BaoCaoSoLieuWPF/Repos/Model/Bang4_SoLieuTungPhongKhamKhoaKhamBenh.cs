using CommunityToolkit.Mvvm.ComponentModel;


namespace BaoCaoSoLieu.Repos.Model
{
    public partial class Bang4_SoLieuTungPhongKhamKhoaKhamBenh : ObservableObject
    {
        public static event Action? SoNgayHoatDongChangedGlobally;

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

        public string SoVoiKeHoach => (thang == null || chiTieuNgay == null || soNgayHoatDong == null || chiTieuNgay == 0) ? null : $"{(int)Math.Ceiling(((double)thang / ((double)chiTieuNgay * (double)soNgayHoatDong)) * 100)}%";

        [ObservableProperty]
        private int? soLuong;

        public string? TyLeNhapVien => (soLuong == null || thang == null || thang == 0) ? null : $"{(int)Math.Ceiling((double)soLuong / (double)thang * 100)}%";

        [ObservableProperty]
        private int? kh_BHYT;

        [ObservableProperty]
        private int? th_BHYT;

        public string? TyLeBHYT => (kh_BHYT == null || th_BHYT == null || kh_BHYT == 0) ? null : $"{(int)Math.Ceiling((double)th_BHYT / (double)kh_BHYT * 100)}%";

        [ObservableProperty]
        private int? kh_VP;

        [ObservableProperty]
        private int? th_VP;

        public string? TyLeVP => (kh_VP == null || th_VP == null || kh_VP == 0) ? null : $"{(int)Math.Ceiling((double)th_VP / (double)kh_VP * 100)}%";

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

        partial void OnKh_BHYTChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(TyLeBHYT));
        }

        partial void OnTh_BHYTChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(TyLeBHYT));
        }

        partial void OnKh_VPChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(TyLeVP));
        }
        partial void OnTh_VPChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(TyLeVP));
        }

        public Bang4_SoLieuTungPhongKhamKhoaKhamBenh()
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
