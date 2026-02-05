using BaoCaoSoLieu.Repos.Model;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BaoCaoSoLieu.Repos.Mappers.Interface
{
    public interface IReportMapper
    {
        Task<ObservableCollection<Bang1_KhamChuaBenhToanVien>> GetBang1(DateTime? tuNgay, DateTime? denNgay);
        Task<ObservableCollection<Bang2_KetQuaThucHienKhoaNoiTru>> GetBang2(DateTime? tuNgay, DateTime? denNgay);
        Task<ObservableCollection<Bang3_KetQuaThucHienDichVuYeuCau>> GetBang3(DateTime? tuNgay, DateTime? denNgay);
        Task<ObservableCollection<Bang4_SoLieuTungPhongKhamKhoaKhamBenh>> GetBang4(DateTime? tuNgay, DateTime? denNgay);
        Task<ObservableCollection<Bang4_KhoaNgoaiTru>> GetBang4KhoaNgoaiTru(DateTime? tuNgay, DateTime? denNgay);
        Task<ObservableCollection<Bang4_CacPhongCoNhieuCongVao>> GetBang4CacPhongCoNhieuCongVao(DateTime? tuNgay, DateTime? denNgay);
        Task<ObservableCollection<Bang4_PhongKhamYeuCau>> GetBang4PhongKhamYeuCau(DateTime? tuNgay, DateTime? denNgay);
    }
}
