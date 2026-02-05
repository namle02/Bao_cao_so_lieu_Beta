using CommunityToolkit.Mvvm.ComponentModel;

namespace BaoCaoSoLieu.Repos.Model
{
    public partial class Bang4_CacPhongCoNhieuCongVao : ObservableObject
    {
        [ObservableProperty]
        private string? khoaPhong;

        [ObservableProperty]
        private int? tongSo;

        [ObservableProperty]
        private int? thang;

        public string? TyLeNhapVien
        {
            get
            {
                if (tongSo == null || tongSo == 0 || thang == null)
                    return null;
                return $"{(int)Math.Ceiling((double)thang.Value / tongSo.Value * 100)}%";
            }
        }

        partial void OnTongSoChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(TyLeNhapVien));
        partial void OnThangChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(TyLeNhapVien));

    }
}
