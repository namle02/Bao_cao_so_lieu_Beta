using BaoCaoSoLieu.Repos.Mappers.Interface;
using BaoCaoSoLieu.Repos.Model;
using BaoCaoSoLieu.Services.Interface;
using Microsoft.Data.SqlClient;
using System.Collections.ObjectModel;
using System.IO;
using System.Reflection;
using System.Windows;

namespace BaoCaoSoLieu.Repos.Mappers.Implement
{
    public class ReportMapper : IReportMapper
    {
        private readonly IConfigServices _config;
        private readonly string _connectionString;
        public ReportMapper(IConfigServices config)
        {
            _config = config;
            _connectionString = _config.ConfigList["DB_string"];
        }

        //Chuẩn hóa lại thời gian 
        private static (DateTime tuNgay, DateTime denNgay) NormalizeDateRange(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            if (!tuNgayRaw.HasValue || !denNgayRaw.HasValue)
                throw new ArgumentNullException("Cần có đủ tuNgay và denNgay");

            var tuNgay = tuNgayRaw.Value.Date;
            var denNgay = denNgayRaw.Value.Date.AddDays(1).AddSeconds(-1);
            return (tuNgay, denNgay);
        }

        //Map bảng 1
        public async Task<ObservableCollection<Bang1_KhamChuaBenhToanVien>> GetBang1(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            var (tuNgay, denNgay) = NormalizeDateRange(tuNgayRaw, denNgayRaw);
            ObservableCollection<Bang1_KhamChuaBenhToanVien> Bang1 = new ObservableCollection<Bang1_KhamChuaBenhToanVien>();
            try
            {
                string resourceName = "BaoCaoSoLieu.SqlScripts.Bang1.sql";
                using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);

                if (stream == null)
                {
                    throw new FileNotFoundException($"Không tìm thấy resource: {resourceName}");
                }

                using StreamReader strReader = new StreamReader(stream);
                string query = strReader.ReadToEnd();

                // Thay thế tham số ngày tháng
                query = query.Replace("@TuNgayParams", $"{tuNgay:yyyy-MM-dd HH:mm:ss}")
                            .Replace("@DenNgayParams", $"{denNgay:yyyy-MM-dd HH:mm:ss}");

                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    SqlCommand cmd = new SqlCommand(query, connection) { CommandTimeout = 180 };
                    await connection.OpenAsync();
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            if (reader["HoatDong"].ToString() == "Công suất giường điều trị" || reader["HoatDong"].ToString() == "Công suất giường điều trị (+1)")
                            {
                                Bang1.Add(new Bang1_KhamChuaBenhToanVien()
                                {
                                    HoatDong = reader["HoatDong"].ToString(),
                                    DonVi = reader["DonVi"].ToString(),
                                    KeHoach = null,
                                    ThucHien = reader["ChiSo"] + "%"
                                });
                            }
                            else
                            {
                                Bang1.Add(new Bang1_KhamChuaBenhToanVien()
                                {
                                    HoatDong = reader["HoatDong"].ToString(),
                                    DonVi = reader["DonVi"].ToString(),
                                    KeHoach = 1000,
                                    ThucHien = reader["ChiSo"] == DBNull.Value ? null : Convert.ToInt32(reader["ChiSo"])
                                });
                            }


                        }
                    }
                }


                return Bang1;
            }
            catch
            {
                throw;
            }

        }

        // Map bảng 2
        public async Task<ObservableCollection<Bang2_KetQuaThucHienKhoaNoiTru>> GetBang2(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            var (tuNgay, denNgay) = NormalizeDateRange(tuNgayRaw, denNgayRaw);
            ObservableCollection<Bang2_KetQuaThucHienKhoaNoiTru> Bang2 = new ObservableCollection<Bang2_KetQuaThucHienKhoaNoiTru>();
            try
            {
                string resourceName = "BaoCaoSoLieu.SqlScripts.Bang2.sql";
                using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);

                if (stream == null)
                {
                    throw new FileNotFoundException($"Không tìm thấy resource: {resourceName}");
                }

                using StreamReader strReader = new StreamReader(stream);
                string query = strReader.ReadToEnd();

                // Thay thế tham số ngày tháng
                query = query.Replace("@TuNgayParams", $"{tuNgay:yyyy-MM-dd HH:mm:ss}")
                            .Replace("@DenNgayParams", $"{denNgay:yyyy-MM-dd HH:mm:ss}");

                int STT = 2;
                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    SqlCommand cmd = new SqlCommand(query, connection) { CommandTimeout = 180 };

                    await connection.OpenAsync();
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            Bang2.Add(new Bang2_KetQuaThucHienKhoaNoiTru()
                            {
                                Stt = STT,
                                TenKhoa = reader["TenPhongBan"].ToString(),
                                ThucHien_LuotNB = reader["LuotKham"] == DBNull.Value ? null : Convert.ToInt32(reader["LuotKham"]),
                                ThucHien_CongSuatGiuong = reader["NgayDieuTri"] == DBNull.Value ? null : Convert.ToInt32(reader["NgayDieuTri"]),
                                ThucHien_HSBA = reader["TBhsba"] == DBNull.Value ? null : Convert.ToInt32(reader["TBhsba"]),
                            });
                            STT++;
                        }
                    }
                }

                return Bang2;
            }
            catch
            {
                throw;
            }
        }

        // Map bảng 3
        public async Task<ObservableCollection<Bang3_KetQuaThucHienDichVuYeuCau>> GetBang3(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            var (tuNgay, denNgay) = NormalizeDateRange(tuNgayRaw, denNgayRaw);

            ObservableCollection<Bang3_KetQuaThucHienDichVuYeuCau> Bang3 = new ObservableCollection<Bang3_KetQuaThucHienDichVuYeuCau>();
            try
            {
                string resourceName = "BaoCaoSoLieu.SqlScripts.Bang3.sql";
                using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);
                if (stream == null)
                {
                    throw new FileNotFoundException($"Không tìm thấy resource: {resourceName}");
                }

                using StreamReader strReader = new StreamReader(stream);
                string query = strReader.ReadToEnd();

                // Thay thế tham số ngày tháng
                query = query.Replace("@TuNgayParams", $"{tuNgay:yyyy-MM-dd HH:mm:ss}")
                            .Replace("@DenNgayParams", $"{denNgay:yyyy-MM-dd HH:mm:ss}");

                int STT = 1;
                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    SqlCommand cmd = new SqlCommand(query, connection) { CommandTimeout = 180 };

                    await connection.OpenAsync();
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            Bang3.Add(new Bang3_KetQuaThucHienDichVuYeuCau()
                            {
                                Stt = STT,
                                TenKhoa = reader["TenPhongBan"].ToString(),
                                KeHoach = 0,
                                ThucHien = reader["LuotPT"] == DBNull.Value ? null : Convert.ToInt32(reader["LuotPT"]),
                                Tong = reader["LuotPTYC"] == DBNull.Value ? null : Convert.ToInt32(reader["LuotPTYC"]),
                            });
                            STT++;
                        }
                    }
                }
                return Bang3;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                throw;
            }
        }

        //Map bảng 4
        public async Task<ObservableCollection<Bang4_SoLieuTungPhongKhamKhoaKhamBenh>> GetBang4(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            var (tuNgay, denNgay) = NormalizeDateRange(tuNgayRaw, denNgayRaw);

            ObservableCollection<Bang4_SoLieuTungPhongKhamKhoaKhamBenh> Bang4 = new ObservableCollection<Bang4_SoLieuTungPhongKhamKhoaKhamBenh>();
            try
            {
                string resourceName = "BaoCaoSoLieu.SqlScripts.Bang4.sql";
                using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);
                if (stream == null)
                {
                    throw new FileNotFoundException($"Không tìm thấy resource: {resourceName}");
                }

                using StreamReader strReader = new StreamReader(stream);
                string query = strReader.ReadToEnd();

                // Thay thế tham số ngày tháng nếu có
                if (query.Contains("@TuNgay") && query.Contains("@DenNgay"))
                {
                    query = query.Replace("@TuNgayParams", $"{tuNgay:yyyy-MM-dd HH:mm:ss}")
                            .Replace("@DenNgayParams", $"{denNgay:yyyy-MM-dd HH:mm:ss}");
                }

                int STT = 1;
                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    SqlCommand cmd = new SqlCommand(query, connection) { CommandTimeout = 180 };

                    await connection.OpenAsync();
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            Bang4.Add(new Bang4_SoLieuTungPhongKhamKhoaKhamBenh()
                            {
                                Stt = STT,
                                PhongKham = reader["KhoaPhong"].ToString(),
                                Thang = reader["LuotKham"] == DBNull.Value ? null : Convert.ToInt32(reader["LuotKham"]),
                                SoLuong = reader["NhapVien"] == DBNull.Value ? null : Convert.ToInt32(reader["NhapVien"]),
                                Th_BHYT = reader["tbhsbhyt"] == DBNull.Value ? null : Convert.ToInt32(reader["tbhsbhyt"]),
                                Th_VP = reader["tbhsvp"] == DBNull.Value ? null : Convert.ToInt32(reader["tbhsvp"])
                            });
                            STT++;
                        }
                    }
                }
                return Bang4;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                throw; 
            }
        }

        //Map bảng 4 Khoa ngoại trú
        public async Task<ObservableCollection<Bang4_KhoaNgoaiTru>> GetBang4KhoaNgoaiTru(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            var (tuNgay, denNgay) = NormalizeDateRange(tuNgayRaw, denNgayRaw);

            ObservableCollection<Bang4_KhoaNgoaiTru> Bang4KhoaNgoaiTru = new ObservableCollection<Bang4_KhoaNgoaiTru>();
            try
            {
                string resourceName = "BaoCaoSoLieu.SqlScripts.Bang4KhoaNgoaiTru.sql";
                using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);
                if (stream == null)
                {
                    throw new FileNotFoundException($"Không tìm thấy resource: {resourceName}");
                }

                using StreamReader strReader = new StreamReader(stream);
                string query = strReader.ReadToEnd();

                // Thay thế tham số ngày tháng nếu có
                if (query.Contains("@TuNgay") && query.Contains("@DenNgay"))
                {
                    query = query.Replace("@TuNgayParams", $"{tuNgay:yyyy-MM-dd HH:mm:ss}")
                            .Replace("@DenNgayParams", $"{denNgay:yyyy-MM-dd HH:mm:ss}");
                }

                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    SqlCommand cmd = new SqlCommand(query, connection) { CommandTimeout = 180 };

                    await connection.OpenAsync();
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            Bang4KhoaNgoaiTru.Add(new Bang4_KhoaNgoaiTru()
                            {
                                TenKhoa = reader["KhoaPhong"].ToString(),
                                KeHoach_TBHS = 1000000,
                                TBHS_BHYT = reader["tb"] == DBNull.Value ? null : Convert.ToInt32(reader["tb"])
                            });
                        }
                    }
                }
                return Bang4KhoaNgoaiTru;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                throw;
            }
        }

        //Map bảng 4 Các phòng có nhiều cổng vào
        public async Task<ObservableCollection<Bang4_CacPhongCoNhieuCongVao>> GetBang4CacPhongCoNhieuCongVao(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            var (tuNgay, denNgay) = NormalizeDateRange(tuNgayRaw, denNgayRaw);
            ObservableCollection<Bang4_CacPhongCoNhieuCongVao> Bang4CacPhongCoNhieuCongVao = new ObservableCollection<Bang4_CacPhongCoNhieuCongVao>();

            try
            {
                string resourceName = "BaoCaoSoLieu.SqlScripts.Bang4CacPhongCoNhieuCongVao.sql";
                using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);
                if (stream == null)
                {
                    throw new FileNotFoundException($"Không tìm thấy resource: {resourceName}");
                }

                using StreamReader strReader = new StreamReader(stream);
                string query = strReader.ReadToEnd();

                // Thay thế tham số ngày tháng nếu có
                if (query.Contains("@TuNgay") && query.Contains("@DenNgay"))
                {
                    query = query.Replace("@TuNgayParams", $"{tuNgay:yyyy-MM-dd HH:mm:ss}")
                            .Replace("@DenNgayParams", $"{denNgay:yyyy-MM-dd HH:mm:ss}");
                }

                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    SqlCommand cmd = new SqlCommand(query, connection) { CommandTimeout = 180 };

                    await connection.OpenAsync();
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            Bang4CacPhongCoNhieuCongVao.Add(new Bang4_CacPhongCoNhieuCongVao()
                            {
                                KhoaPhong = reader["TenPhongBan"].ToString(),
                                TongSo = reader["LuotKham"] == DBNull.Value ? null : Convert.ToInt32(reader["LuotKham"]),
                                Thang = reader["NhapVien"] == DBNull.Value ? null : Convert.ToInt32(reader["NhapVien"])
                            });
                        }
                    }
                }
                return Bang4CacPhongCoNhieuCongVao;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                throw;
            }

        }

        //Map bảng 4 Phòng khám yêu cầu
        public async Task<ObservableCollection<Bang4_PhongKhamYeuCau>> GetBang4PhongKhamYeuCau(DateTime? tuNgayRaw, DateTime? denNgayRaw)
        {
            var (tuNgay, denNgay) = NormalizeDateRange(tuNgayRaw, denNgayRaw);

            ObservableCollection<Bang4_PhongKhamYeuCau> Bang4PhongKhamYeuCau = new ObservableCollection<Bang4_PhongKhamYeuCau>();
            try
            {
                string resourceName = "BaoCaoSoLieu.SqlScripts.Bang4PhongKhamYeuCau.sql";
                using Stream? stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName);
                if (stream == null)
                {
                    throw new FileNotFoundException($"Không tìm thấy resource: {resourceName}");
                }

                using StreamReader strReader = new StreamReader(stream);
                string query = strReader.ReadToEnd();

                // Thay thế tham số ngày tháng
                query = query.Replace("@TuNgayParams", $"{tuNgay:yyyy-MM-dd HH:mm:ss}")
                            .Replace("@DenNgayParams", $"{denNgay:yyyy-MM-dd HH:mm:ss}");

                int STT = 1;
                using (SqlConnection connection = new SqlConnection(_connectionString))
                {
                    SqlCommand cmd = new SqlCommand(query, connection) { CommandTimeout = 180 };

                    await connection.OpenAsync();
                    using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var phongKhamYeuCau = new Bang4_PhongKhamYeuCau()
                            {
                                Stt = STT,
                                PhongKham = reader["TenPhongBan"].ToString(),
                                ChiTieuNgay = 0,
                                Thang = reader["LuotKham"] == DBNull.Value ? null : Convert.ToInt32(reader["LuotKham"]),
                                SoLuong = reader["NhapVien"] == DBNull.Value ? null : Convert.ToInt32(reader["NhapVien"]),
                                Kh_TbHs = 100000,
                                Th_TbHs = reader["TBHS"] == DBNull.Value ? null : Convert.ToInt32(reader["TBHS"]),
                            };
                            Bang4PhongKhamYeuCau.Add(phongKhamYeuCau);
                            STT++;
                        }
                    }
                }
                return Bang4PhongKhamYeuCau;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                throw;
            }
        }

    }
}
