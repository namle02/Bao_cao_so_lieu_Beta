using BaoCaoSoLieu.Repos.Model;

namespace BaoCaoSoLieu.Services.Interface
{
    public interface IExcelExportService
    {
        Task<string> ExportToExcelAsync(
            IEnumerable<Bang1_KhamChuaBenhToanVien>? bang1Data,
            IEnumerable<Bang2_KetQuaThucHienKhoaNoiTru>? bang2Data,
            IEnumerable<Bang3_KetQuaThucHienDichVuYeuCau>? bang3Data,
            IEnumerable<Bang4_SoLieuTungPhongKhamKhoaKhamBenh>? bang4Data,
            IEnumerable<Bang4_KhoaNgoaiTru>? bang4KhoaNgoaiTruData,
            IEnumerable<Bang4_CacPhongCoNhieuCongVao>? bang4CacPhongCoNhieuCongVaoData,
            IEnumerable<Bang4_PhongKhamYeuCau>? bang4PhongKhamYeuCauData,
            DateTime? tuNgay,
            DateTime? denNgay);
    }
} 