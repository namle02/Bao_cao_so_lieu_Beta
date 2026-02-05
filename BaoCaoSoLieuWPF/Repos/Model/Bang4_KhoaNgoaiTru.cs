
using CommunityToolkit.Mvvm.ComponentModel;

namespace BaoCaoSoLieu.Repos.Model
{
    public partial class Bang4_KhoaNgoaiTru : ObservableObject
    {
        [ObservableProperty]
        private string? tenKhoa;

        [ObservableProperty]
        private int? keHoach_TBHS;

        [ObservableProperty]
        private int? tBHS_BHYT;

        public string? SoSanhVoiChiTieu
        {
            get
            {
                if (keHoach_TBHS == null || keHoach_TBHS == 0 || tBHS_BHYT == null)
                    return null;
                return $"{(int)Math.Ceiling((double)tBHS_BHYT.Value / keHoach_TBHS.Value * 100)}%";
            }
        }

        partial void OnKeHoach_TBHSChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoSanhVoiChiTieu));
        partial void OnTBHS_BHYTChanged(int? oldValue, int? newValue) => OnPropertyChanged(nameof(SoSanhVoiChiTieu));
        
    }
}
