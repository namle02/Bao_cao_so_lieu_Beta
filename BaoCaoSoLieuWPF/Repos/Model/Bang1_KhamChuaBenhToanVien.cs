using CommunityToolkit.Mvvm.ComponentModel;

namespace BaoCaoSoLieu.Repos.Model
{
    public partial class Bang1_KhamChuaBenhToanVien : ObservableObject
    {
        [ObservableProperty]
        private string? hoatDong;

        [ObservableProperty]
        private string? donVi;

        [ObservableProperty]
        private int? keHoach;

        [ObservableProperty]
        private object? thucHien;

        public string? TyLeThucHien
        {
            get
            {
                if (keHoach == null || keHoach == 0 || thucHien == null)
                    return null;

                double thucHienValue;

                switch (thucHien)
                {
                    case int i:
                        thucHienValue = i;
                        break;
                    case double d:
                        thucHienValue = d;
                        break;
                    case float f:
                        thucHienValue = f;
                        break;
                    case string s when double.TryParse(s, out var parsed):
                        thucHienValue = parsed;
                        break;
                    default:
                        return null;
                }

                return $"{(int)Math.Ceiling(thucHienValue * 100 / (double)keHoach)}%";
            }
        }

        partial void OnKeHoachChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(TyLeThucHien));

        partial void OnThucHienChanged(object? oldValue, object? newValue) => OnPropertyChanged(nameof(TyLeThucHien));
       
    }
}
