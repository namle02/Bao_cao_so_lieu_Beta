using CommunityToolkit.Mvvm.ComponentModel;
using System.ComponentModel;


namespace BaoCaoSoLieu.Repos.Model
{
    public partial class Bang3_KetQuaThucHienDichVuYeuCau : ObservableObject
    {
        [ObservableProperty]
        private int? stt;

        [ObservableProperty]
        private string? tenKhoa;

        [ObservableProperty]
        private int? keHoach;

        [ObservableProperty]
        private int? thucHien;

        public string? TyLeTH_KH => (keHoach == null || thucHien == null || keHoach == 0) ? null : $"{(int)Math.Ceiling(((double)thucHien / (double)keHoach) * 100)}%";

        [ObservableProperty]
        private int? tong;

        public string? TyLeDVYC_PT => (tong == null || thucHien == null || thucHien == 0) ? null : $"{(int)Math.Ceiling(((double)tong / (double)thucHien) * 100)}%";

        partial void OnKeHoachChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(TyLeTH_KH));

        partial void OnThucHienChanged(int? oldValue, int? newValue)
        {
            OnPropertyChanged(nameof(TyLeTH_KH));
            OnPropertyChanged(nameof(TyLeDVYC_PT));
        }

        partial void OnTongChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(TyLeDVYC_PT));

    }


}
