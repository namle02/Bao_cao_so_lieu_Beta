using CommunityToolkit.Mvvm.ComponentModel;

namespace BaoCaoSoLieu.Repos.Model
{
    public partial class Bang2_KetQuaThucHienKhoaNoiTru : ObservableObject
    {
        [ObservableProperty]
        private int? stt;

        [ObservableProperty]
        private string? tenKhoa;

        [ObservableProperty]
        private int? keHoach_LuotNB;

        [ObservableProperty]
        private int? thucHien_LuotNB;
        public string? SoVoiKeHoach_NB => (keHoach_LuotNB == null || thucHien_LuotNB == null || keHoach_LuotNB == 0)
            ? null
            : $"{(int)Math.Ceiling((double)thucHien_LuotNB / (double)keHoach_LuotNB * 100)}%";

        [ObservableProperty]
        private int? keHoach_CongSuatGiuong;

        [ObservableProperty]
        private int? thucHien_CongSuatGiuong;

        public string? SoVoiKeHoach_CongSuatGiuong => (keHoach_CongSuatGiuong == null || thucHien_CongSuatGiuong == null || keHoach_CongSuatGiuong == 0)
            ? null
            : $"{(int)Math.Ceiling((double)thucHien_CongSuatGiuong / (double)keHoach_CongSuatGiuong * 100)}%";

        [ObservableProperty]
        private int? keHoach_HSBA;

        [ObservableProperty]
        private int? thucHien_HSBA;

        public string? SoVoiKeHoach_HSBA => (keHoach_HSBA == null || thucHien_HSBA == null || keHoach_HSBA == 0) 
            ? null 
            : $"{(int)Math.Ceiling((double)thucHien_HSBA / (double)keHoach_HSBA * 100)}%";

        partial void OnKeHoach_LuotNBChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoVoiKeHoach_NB));
        partial void OnThucHien_LuotNBChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoVoiKeHoach_NB));
        partial void OnKeHoach_CongSuatGiuongChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoVoiKeHoach_CongSuatGiuong));
        partial void OnThucHien_CongSuatGiuongChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoVoiKeHoach_CongSuatGiuong));
        partial void OnKeHoach_HSBAChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoVoiKeHoach_HSBA));
        partial void OnThucHien_HSBAChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoVoiKeHoach_HSBA));

    }

}
