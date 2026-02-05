using BaoCaoSoLieu.Repos.Model;
using BaoCaoSoLieu.Services.Interface;
using OfficeOpenXml;
using System.Reflection;
using System.IO;

namespace BaoCaoSoLieu.Services.Implement
{
    public class ExcelExportService : IExcelExportService
    {
        public async Task<string> ExportToExcelAsync(
            IEnumerable<Bang1_KhamChuaBenhToanVien>? bang1Data,
            IEnumerable<Bang2_KetQuaThucHienKhoaNoiTru>? bang2Data,
            IEnumerable<Bang3_KetQuaThucHienDichVuYeuCau>? bang3Data,
            IEnumerable<Bang4_SoLieuTungPhongKhamKhoaKhamBenh>? bang4Data,
            IEnumerable<Bang4_KhoaNgoaiTru>? bang4KhoaNgoaiTruData,
            IEnumerable<Bang4_CacPhongCoNhieuCongVao>? bang4CacPhongCoNhieuCongVaoData,
            IEnumerable<Bang4_PhongKhamYeuCau>? bang4PhongKhamYeuCauData,
            DateTime? tuNgay,
            DateTime? denNgay)
        {
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

            var fileName = $"BaoCaoSoLieu_{tuNgay:yyyyMMdd}_{denNgay:yyyyMMdd}_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
            var filePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), fileName);

            using var package = new ExcelPackage();
            
            // Tạo sheet cho từng bảng
            if (bang1Data?.Any() == true)
                CreateSheet(package, "Bảng 1 - Kết quả toàn viện", bang1Data);
                
            if (bang2Data?.Any() == true)
                CreateSheet(package, "Bảng 2 - Kết quả thực hiện khoa nội trú", bang2Data);
                
            if (bang3Data?.Any() == true)
                CreateSheet(package, "Bảng 3 - Thực hiện dịch vụ yêu cầu", bang3Data);
                
            if (bang4Data?.Any() == true)
                CreateSheet(package, "Bảng 4.1 - Số liệu phòng khám", bang4Data);
                
            if (bang4KhoaNgoaiTruData?.Any() == true)
                CreateSheet(package, "Bảng 4.2 - Khoa ngoại trú", bang4KhoaNgoaiTruData);
                
            if (bang4CacPhongCoNhieuCongVaoData?.Any() == true)
                CreateSheet(package, "Bảng 4.3 - Các phòng có nhiều công vào", bang4CacPhongCoNhieuCongVaoData);
                
            if (bang4PhongKhamYeuCauData?.Any() == true)
                CreateSheet(package, "Bảng 4.4 - Phòng khám yêu cầu", bang4PhongKhamYeuCauData);

            // Lưu file
            await package.SaveAsAsync(new FileInfo(filePath));
            
            return filePath;
        }

        private void CreateSheet<T>(ExcelPackage package, string sheetName, IEnumerable<T> data)
        {
            var worksheet = package.Workbook.Worksheets.Add(sheetName);
            
            // Lấy tất cả properties (bao gồm cả computed properties)
            var allProperties = typeof(T).GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
                .Where(p => p.CanRead)
                .ToList();
            
            // Lọc bỏ các properties không muốn xuất
            var properties = allProperties
                .Where(p => !ShouldExcludeProperty(p))
                .OrderBy(p => GetPropertyOrder(p)) // Sắp xếp theo thứ tự mong muốn
                .ToArray();
            
            // Tạo header
            for (int i = 0; i < properties.Length; i++)
            {
                var cell = worksheet.Cells[1, i + 1];
                cell.Value = GetDisplayName(properties[i].Name);
                cell.Style.Font.Bold = true;
                cell.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                cell.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGray);
                cell.Style.Border.BorderAround(OfficeOpenXml.Style.ExcelBorderStyle.Thin);
            }
            
            // Thêm dữ liệu
            var row = 2;
            foreach (var item in data)
            {
                for (int i = 0; i < properties.Length; i++)
                {
                    var cell = worksheet.Cells[row, i + 1];
                    var value = properties[i].GetValue(item);
                    
                    // Xử lý các kiểu dữ liệu khác nhau
                    if (value is DateTime dateTime)
                    {
                        cell.Value = dateTime;
                        cell.Style.Numberformat.Format = "dd/MM/yyyy";
                    }
                    else if (value is decimal || value is double || value is float)
                    {
                        cell.Value = Convert.ToDouble(value);
                        cell.Style.Numberformat.Format = "#,##0.00";
                    }
                    else if (value is int || value is long)
                    {
                        cell.Value = Convert.ToInt64(value);
                        cell.Style.Numberformat.Format = "#,##0";
                    }
                    else
                    {
                        cell.Value = value?.ToString() ?? "";
                    }
                    
                    cell.Style.Border.BorderAround(OfficeOpenXml.Style.ExcelBorderStyle.Thin);
                }
                row++;
            }
            
            // Auto-fit columns
            worksheet.Cells.AutoFitColumns();
            
            // Thêm border cho toàn bộ range
            var dataRange = worksheet.Cells[1, 1, row - 1, properties.Length];
            dataRange.Style.Border.BorderAround(OfficeOpenXml.Style.ExcelBorderStyle.Medium);
        }
        
        private bool ShouldExcludeProperty(PropertyInfo property)
        {
            // Loại bỏ các properties không muốn xuất
            var excludeNames = new[] { 
                "SoNgayHoatDongGlobal", 
                "SoNgayHoatDong",
                "SoNgayHoatDongChangedGlobally" // Event không cần xuất
            };
            return excludeNames.Contains(property.Name);
        }
        
        private int GetPropertyOrder(PropertyInfo property)
        {
            // Định nghĩa thứ tự cho từng model
            var typeName = property.DeclaringType?.Name;
            
            switch (typeName)
            {
                case nameof(Bang1_KhamChuaBenhToanVien):
                    return GetBang1Order(property.Name);
                case nameof(Bang2_KetQuaThucHienKhoaNoiTru):
                    return GetBang2Order(property.Name);
                case nameof(Bang3_KetQuaThucHienDichVuYeuCau):
                    return GetBang3Order(property.Name);
                case nameof(Bang4_SoLieuTungPhongKhamKhoaKhamBenh):
                    return GetBang4Order(property.Name);
                case nameof(Bang4_KhoaNgoaiTru):
                    return GetBang4KhoaNgoaiTruOrder(property.Name);
                case nameof(Bang4_CacPhongCoNhieuCongVao):
                    return GetBang4CacPhongOrder(property.Name);
                case nameof(Bang4_PhongKhamYeuCau):
                    return GetBang4PhongKhamOrder(property.Name);
                default:
                    return int.MaxValue;
            }
        }
        
        private int GetBang1Order(string propertyName)
        {
            return propertyName switch
            {
                "HoatDong" => 1,
                "DonVi" => 2,
                "KeHoach" => 3,
                "ThucHien" => 4,
                "TyLeThucHien" => 5,
                _ => int.MaxValue
            };
        }
        
        private int GetBang2Order(string propertyName)
        {
            return propertyName switch
            {
                "Stt" => 1,
                "TenKhoa" => 2,
                "KeHoach_LuotNB" => 3,
                "ThucHien_LuotNB" => 4,
                "SoVoiKeHoach_NB" => 5,
                "KeHoach_CongSuatGiuong" => 6,
                "ThucHien_CongSuatGiuong" => 7,
                "SoVoiKeHoach_CongSuatGiuong" => 8,
                "KeHoach_HSBA" => 9,
                "ThucHien_HSBA" => 10,
                "SoVoiKeHoach_HSBA" => 11,
                _ => int.MaxValue
            };
        }
        
        private int GetBang3Order(string propertyName)
        {
            return propertyName switch
            {
                "Stt" => 1,
                "TenKhoa" => 2,
                "KeHoach" => 3,
                "ThucHien" => 4,
                "TyLeTH_KH" => 5,
                "Tong" => 6,
                "TyLeDVYC_PT" => 7,
                _ => int.MaxValue
            };
        }
        
        private int GetBang4Order(string propertyName)
        {
            return propertyName switch
            {
                "Stt" => 1,
                "PhongKham" => 2,
                "ChiTieuNgay" => 3,
                "Thang" => 4,
                "SoVoiKeHoach" => 5,
                "SoLuong" => 6,
                "TyLeNhapVien" => 7,
                "Kh_BHYT" => 8,
                "Th_BHYT" => 9,
                "TyLeBHYT" => 10,
                "Kh_VP" => 11,
                "Th_VP" => 12,
                "TyLeVP" => 13,
                _ => int.MaxValue
            };
        }
        
        private int GetBang4KhoaNgoaiTruOrder(string propertyName)
        {
            return propertyName switch
            {
                "TenKhoa" => 1,
                "KeHoach_TBHS" => 2,
                "TBHS_BHYT" => 3,
                "SoSanhVoiChiTieu" => 4,
                _ => int.MaxValue
            };
        }
        
        private int GetBang4CacPhongOrder(string propertyName)
        {
            return propertyName switch
            {
                "KhoaPhong" => 1,
                "TongSo" => 2,
                "Thang" => 3,
                "TyLeNhapVien" => 4,
                _ => int.MaxValue
            };
        }
        
        private int GetBang4PhongKhamOrder(string propertyName)
        {
            return propertyName switch
            {
                "Stt" => 1,
                "PhongKham" => 2,
                "ChiTieuNgay" => 3,
                "Thang" => 4,
                "SoVoiKeHoach" => 5,
                "SoLuong" => 6,
                "TyLeNhapVien" => 7,
                "Kh_TbHs" => 8,
                "Th_TbHs" => 9,
                "TyLeTC" => 10,
                _ => int.MaxValue
            };
        }

        private string GetDisplayName(string propertyName)
        {
            return propertyName switch
            {
                "TenKhoa" => "Tên khoa",
                "SoLuong" => "Số lượng",
                "TyLe" => "Tỷ lệ (%)",
                "GhiChu" => "Ghi chú",
                "TenPhongKham" => "Tên phòng khám",
                "TenDichVu" => "Tên dịch vụ",
                "SoCa" => "Số ca",
                "SoLuongBenhNhan" => "Số lượng bệnh nhân",
                "NgayThang" => "Ngày tháng",
                "KeHoach" => "Kế hoạch",
                "ThucHien" => "Thực hiện",
                "Tong" => "Tổng",
                "ChiTieuNgay" => "Chỉ tiêu ngày",
                "Thang" => "Tháng",
                "TongSo" => "Tổng số",
                "TenDichVuPhauThuat" => "Tên dịch vụ phẫu thuật",
                "SoLuongCa" => "Số lượng ca",
                "SoLuongBenhNhanPhauThuat" => "Số lượng bệnh nhân phẫu thuật",
                "HoatDong" => "Hoạt động",
                "DonVi" => "Đơn vị",
                "TyLeThucHien" => "Tỷ lệ thực hiện",
                "KeHoach_LuotNB" => "Kế hoạch",
                "ThucHien_LuotNB" => "Thực hiện",
                "KeHoach_CongSuatGiuong" => "Kế hoạch",
                "ThucHien_CongSuatGiuong" => "Thực hiện",
                "KeHoach_HSBA" => "Kế hoạch",
                "ThucHien_HSBA" => "Thực hiện",
                "SoVoiKeHoach_NB" => "So với kế hoạch",
                "SoVoiKeHoach_CongSuatGiuong" => "So với kế hoạch",
                "SoVoiKeHoach_HSBA" => "So với kế hoạch",
                "TyLeTH_KH" => "Tỷ lệ",
                "TyLeDVYC_PT" => "Tỷ lệ DVYC PT",
                "KhoaPhong" => "Khoa phòng",
                "TyLeNhapVien" => "Tỷ lệ nhập viện",
                "keHoach_TBHS" => "KH TB/HS",
                "tBHS_BHYT" => "TB/HS BHYT",
                "SoSanhVoiChiTieu" => "So sánh với chỉ tiêu",
                _ => propertyName
            };
        }
    }
} 