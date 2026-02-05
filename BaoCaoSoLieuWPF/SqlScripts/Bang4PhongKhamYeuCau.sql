SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRAN;


DECLARE 
@TuNgay 	DateTime = '@TuNgayParams',
@DenNgay 	DateTime = '@DenNgayParams'

select 
	TenPhongBan = yy.TenPhongBan,
	NhapVien = ISNULL(yy.NhapVien,0),
	LuotKham = ISNULL(yy.LuotKham,0),
	TBHS = ISNULL(xx.tong/yy.LuotKham,0)
FROM(
	SELECT
		TenPhongBan = pb.TenPhongBan,
		NhapVien = COUNT(CASE WHEN kb.HuongGiaiQuyet_Id = 457 THEN 1 END),
		LuotKham = COUNT(*),
		PhongBan_Id = pb.PhongBan_Id
	FROM TiepNhan tn
	LEFT JOIN khambenh kb ON kb.TiepNhan_Id = tn.TiepNhan_Id
	LEFT JOIN DM_PhongBan pb on kb.PhongBan_Id = pb.PhongBan_Id

	WHERE kb.PhongBan_Id in (671, 14, 553, 15, 16, 18, 21, 850, 843) AND 
	kb.ThoiGianKham  BETWEEN @TuNgay AND @DenNgay
	group by pb.TenPhongBan, pb.PhongBan_Id
) yy

LEFT JOIN (
--nhi yêu cầu
	SELECT
		PhongBan_Id = 553,
		tong = SUM(Num6)
	FROM (
		SELECT 
			SUM(a.SoLuong * a.DonGiaThanhToan) AS Num6,
			pb.TenPhongBan AS Str2
		FROM (
			SELECT *,
				   CASE WHEN DATENAME(WEEKDAY, NgayHoaDon) <> 'Saturday' THEN 1 ELSE 0 END AS cuoituan
			FROM HoaDon 
			WHERE ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		) b
		JOIN HoaDonChiTiet a ON a.HoaDon_Id = b.HoaDon_Id
		LEFT JOIN vw_NhanVien NV ON NV.NhanVien_Id = b.NguoiThuTien_Id
		LEFT JOIN CLSYeuCauChiTiet ct ON ct.YeuCauChiTiet_Id = a.YeuCauChiTiet_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu DV ON ct.DichVu_Id = DV.DichVu_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu_DonGia dg ON dv.DichVu_Id = dg.DichVu_Id AND dg.LoaiGia_Id = 4
		LEFT JOIN DM_NhomDichVu NDV ON NDV.NhomDichVu_Id = DV.NhomDichVu_Id
		LEFT JOIN CLSYeuCau y ON ct.CLSYeuCau_Id = y.CLSYeuCau_Id
		LEFT JOIN DM_PhongBan pb ON y.NoiYeuCau_Id = pb.PhongBan_Id
		LEFT JOIN DM_PhongBan pb1 ON b.NoiPhatSinh_Id = pb1.PhongBan_Id
		WHERE DaThanhToan = 1 
			  AND HoanTra = 0 
			  AND HuyHoaDon = 0
			  AND (a.LoaiGia_Id = 35 OR a.LoaiGia_Id = 36)
			  AND b.LoaiHoaDon = 'T'
			  AND ((pb.PhongBan_Id = 2 AND dv.DichVu_Id = 19215) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 19215) 
				   OR pb.PhongBan_Id = 553) 
			  AND (NoiPhatSinh_Id IN (1, 3, 2, 46, 563) OR pb1.CapTren_Id = 1)
		GROUP BY pb.TenPhongBan
	) x 

	union all

	--Nội yêu cầu 1
	SELECT
		PhongBan_Id = 15,
		tong = SUM(Num6)
	FROM (
		SELECT 
			SUM(a.SoLuong * a.DonGiaThanhToan) AS Num6,
			pb.TenPhongBan AS Str2
		FROM (
			SELECT *,
				   CASE WHEN DATENAME(WEEKDAY, NgayHoaDon) <> 'Saturday' THEN 1 ELSE 0 END AS cuoituan
			FROM HoaDon 
			WHERE ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		) b
		JOIN HoaDonChiTiet a ON a.HoaDon_Id = b.HoaDon_Id
		LEFT JOIN vw_NhanVien NV ON NV.NhanVien_Id = b.NguoiThuTien_Id
		LEFT JOIN CLSYeuCauChiTiet ct ON ct.YeuCauChiTiet_Id = a.YeuCauChiTiet_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu DV ON ct.DichVu_Id = DV.DichVu_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu_DonGia dg ON dv.DichVu_Id = dg.DichVu_Id AND dg.LoaiGia_Id = 4
		LEFT JOIN DM_NhomDichVu NDV ON NDV.NhomDichVu_Id = DV.NhomDichVu_Id
		LEFT JOIN CLSYeuCau y ON ct.CLSYeuCau_Id = y.CLSYeuCau_Id
		LEFT JOIN DM_PhongBan pb ON y.NoiYeuCau_Id = pb.PhongBan_Id
		LEFT JOIN DM_PhongBan pb1 ON b.NoiPhatSinh_Id = pb1.PhongBan_Id
		WHERE DaThanhToan = 1 
			  AND HoanTra = 0 
			  AND HuyHoaDon = 0
			  AND (a.LoaiGia_Id = 35 OR a.LoaiGia_Id = 36)
			  AND b.LoaiHoaDon = 'T'
			  AND ((pb.PhongBan_Id = 2 AND dv.DichVu_Id = 24468) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 24468) 
				   OR pb.PhongBan_Id = 15) 
			  AND (NoiPhatSinh_Id IN (1, 3, 2, 46, 563) OR pb1.CapTren_Id = 1)
		GROUP BY pb.TenPhongBan
	) x  

	union all

	-- Nội yêu cầu 2
	SELECT
		PhongBan_Id = 16,
		tong = SUM(Num6)
	FROM (
		SELECT 
			SUM(a.SoLuong * a.DonGiaThanhToan) AS Num6,
			pb.TenPhongBan AS Str2
		FROM (
			SELECT *,
				   CASE WHEN DATENAME(WEEKDAY, NgayHoaDon) <> 'Saturday' THEN 1 ELSE 0 END AS cuoituan
			FROM HoaDon 
			WHERE ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		) b
		JOIN HoaDonChiTiet a ON a.HoaDon_Id = b.HoaDon_Id
		LEFT JOIN vw_NhanVien NV ON NV.NhanVien_Id = b.NguoiThuTien_Id
		LEFT JOIN CLSYeuCauChiTiet ct ON ct.YeuCauChiTiet_Id = a.YeuCauChiTiet_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu DV ON ct.DichVu_Id = DV.DichVu_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu_DonGia dg ON dv.DichVu_Id = dg.DichVu_Id AND dg.LoaiGia_Id = 4
		LEFT JOIN DM_NhomDichVu NDV ON NDV.NhomDichVu_Id = DV.NhomDichVu_Id
		LEFT JOIN CLSYeuCau y ON ct.CLSYeuCau_Id = y.CLSYeuCau_Id
		LEFT JOIN DM_PhongBan pb ON y.NoiYeuCau_Id = pb.PhongBan_Id
		LEFT JOIN DM_PhongBan pb1 ON b.NoiPhatSinh_Id = pb1.PhongBan_Id
		WHERE DaThanhToan = 1 
			  AND HoanTra = 0 
			  AND HuyHoaDon = 0
			  AND (a.LoaiGia_Id = 35 OR a.LoaiGia_Id = 36)
			  AND b.LoaiHoaDon = 'T'
			  AND ((pb.PhongBan_Id = 2 AND dv.DichVu_Id = 24469) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 24469) 
				   OR pb.PhongBan_Id = 16) 
			  AND (NoiPhatSinh_Id IN (1, 3, 2, 46, 563) OR pb1.CapTren_Id = 1)
		GROUP BY pb.TenPhongBan
	) x  

	union all

	--Sản phụ yêu cầu

	SELECT
		PhongBan_Id = 18,
		tong = SUM(Num6)
	FROM (
		SELECT 
			SUM(a.SoLuong * a.DonGiaThanhToan) AS Num6,
			pb.TenPhongBan AS Str2
		FROM (
			SELECT *,
				   CASE WHEN DATENAME(WEEKDAY, NgayHoaDon) <> 'Saturday' THEN 1 ELSE 0 END AS cuoituan
			FROM HoaDon 
			WHERE ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		) b
		JOIN HoaDonChiTiet a ON a.HoaDon_Id = b.HoaDon_Id
		LEFT JOIN vw_NhanVien NV ON NV.NhanVien_Id = b.NguoiThuTien_Id
		LEFT JOIN CLSYeuCauChiTiet ct ON ct.YeuCauChiTiet_Id = a.YeuCauChiTiet_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu DV ON ct.DichVu_Id = DV.DichVu_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu_DonGia dg ON dv.DichVu_Id = dg.DichVu_Id AND dg.LoaiGia_Id = 4
		LEFT JOIN DM_NhomDichVu NDV ON NDV.NhomDichVu_Id = DV.NhomDichVu_Id
		LEFT JOIN CLSYeuCau y ON ct.CLSYeuCau_Id = y.CLSYeuCau_Id
		LEFT JOIN DM_PhongBan pb ON y.NoiYeuCau_Id = pb.PhongBan_Id
		LEFT JOIN DM_PhongBan pb1 ON b.NoiPhatSinh_Id = pb1.PhongBan_Id
		WHERE DaThanhToan = 1 
			  AND HoanTra = 0 
			  AND HuyHoaDon = 0
			  AND (a.LoaiGia_Id = 35 OR a.LoaiGia_Id = 36)
			  AND b.LoaiHoaDon = 'T'
			  AND ((pb.PhongBan_Id = 2 AND dv.DichVu_Id = 24471) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 24471) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 19246) 
				   OR pb.PhongBan_Id = 18) 
			  AND (NoiPhatSinh_Id IN (1, 3, 2, 46, 563) OR pb1.CapTren_Id = 1)
		GROUP BY pb.TenPhongBan
	) x  

	union all 

	--TMH yêu cầu

	SELECT
		PhongBan_Id = 21,
		tong = SUM(Num6)
	FROM (
		SELECT 
			SUM(a.SoLuong * a.DonGiaThanhToan) AS Num6,
			pb.TenPhongBan AS Str2
		FROM (
			SELECT *,
				   CASE WHEN DATENAME(WEEKDAY, NgayHoaDon) <> 'Saturday' THEN 1 ELSE 0 END AS cuoituan
			FROM HoaDon 
			WHERE ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		) b
		JOIN HoaDonChiTiet a ON a.HoaDon_Id = b.HoaDon_Id
		LEFT JOIN vw_NhanVien NV ON NV.NhanVien_Id = b.NguoiThuTien_Id
		LEFT JOIN CLSYeuCauChiTiet ct ON ct.YeuCauChiTiet_Id = a.YeuCauChiTiet_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu DV ON ct.DichVu_Id = DV.DichVu_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu_DonGia dg ON dv.DichVu_Id = dg.DichVu_Id AND dg.LoaiGia_Id = 4
		LEFT JOIN DM_NhomDichVu NDV ON NDV.NhomDichVu_Id = DV.NhomDichVu_Id
		LEFT JOIN CLSYeuCau y ON ct.CLSYeuCau_Id = y.CLSYeuCau_Id
		LEFT JOIN DM_PhongBan pb ON y.NoiYeuCau_Id = pb.PhongBan_Id
		LEFT JOIN DM_PhongBan pb1 ON b.NoiPhatSinh_Id = pb1.PhongBan_Id
		WHERE DaThanhToan = 1 
			  AND HoanTra = 0 
			  AND HuyHoaDon = 0
			  AND (a.LoaiGia_Id = 35 OR a.LoaiGia_Id = 36)
			  AND b.LoaiHoaDon = 'T'
			  AND ((pb.PhongBan_Id = 2 AND dv.DichVu_Id = 24472) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 24472) 
				   OR (pb.PhongBan_Id = 2 AND dv.DichVu_Id = 33754) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 33754) 
				   OR pb.PhongBan_Id = 21) 
			  AND (NoiPhatSinh_Id IN (1, 3, 2, 46, 563) OR pb1.CapTren_Id = 1)
		GROUP BY pb.TenPhongBan
	) x  

	union all

	--Ngoại yêu cầu

	SELECT
		PhongBan_Id = 850,
		tong = SUM(Num6)
	FROM (
		SELECT 
			SUM(a.SoLuong * a.DonGiaThanhToan) AS Num6,
			pb.TenPhongBan AS Str2
		FROM (
			SELECT *,
				   CASE WHEN DATENAME(WEEKDAY, NgayHoaDon) <> 'Saturday' THEN 1 ELSE 0 END AS cuoituan
			FROM HoaDon 
			WHERE ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		) b
		JOIN HoaDonChiTiet a ON a.HoaDon_Id = b.HoaDon_Id
		LEFT JOIN vw_NhanVien NV ON NV.NhanVien_Id = b.NguoiThuTien_Id
		LEFT JOIN CLSYeuCauChiTiet ct ON ct.YeuCauChiTiet_Id = a.YeuCauChiTiet_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu DV ON ct.DichVu_Id = DV.DichVu_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu_DonGia dg ON dv.DichVu_Id = dg.DichVu_Id AND dg.LoaiGia_Id = 4
		LEFT JOIN DM_NhomDichVu NDV ON NDV.NhomDichVu_Id = DV.NhomDichVu_Id
		LEFT JOIN CLSYeuCau y ON ct.CLSYeuCau_Id = y.CLSYeuCau_Id
		LEFT JOIN DM_PhongBan pb ON y.NoiYeuCau_Id = pb.PhongBan_Id
		LEFT JOIN DM_PhongBan pb1 ON b.NoiPhatSinh_Id = pb1.PhongBan_Id
		WHERE DaThanhToan = 1 
			  AND HoanTra = 0 
			  AND HuyHoaDon = 0
			  AND (a.LoaiGia_Id = 35 OR a.LoaiGia_Id = 36)
			  AND b.LoaiHoaDon = 'T'
			  AND ((pb.PhongBan_Id = 2 AND dv.DichVu_Id = 19242) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 19242) 
				   OR pb.PhongBan_Id = 850) 
			  AND (NoiPhatSinh_Id IN (1, 3, 2, 46, 563) OR pb1.CapTren_Id = 1)
		GROUP BY pb.TenPhongBan
	) x  
		union all

	--Mắt yêu cầu

	SELECT
		PhongBan_Id = 14,
		tong = SUM(Num6)
	FROM (
		SELECT 
			SUM(a.SoLuong * a.DonGiaThanhToan) AS Num6,
			pb.TenPhongBan AS Str2
		FROM (
			SELECT *,
				   CASE WHEN DATENAME(WEEKDAY, NgayHoaDon) <> 'Saturday' THEN 1 ELSE 0 END AS cuoituan
			FROM HoaDon 
			WHERE ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		) b
		JOIN HoaDonChiTiet a ON a.HoaDon_Id = b.HoaDon_Id
		LEFT JOIN vw_NhanVien NV ON NV.NhanVien_Id = b.NguoiThuTien_Id
		LEFT JOIN CLSYeuCauChiTiet ct ON ct.YeuCauChiTiet_Id = a.YeuCauChiTiet_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu DV ON ct.DichVu_Id = DV.DichVu_Id AND a.LoaiNoiDung = 'DV'
		LEFT JOIN DM_DichVu_DonGia dg ON dv.DichVu_Id = dg.DichVu_Id AND dg.LoaiGia_Id = 4
		LEFT JOIN DM_NhomDichVu NDV ON NDV.NhomDichVu_Id = DV.NhomDichVu_Id
		LEFT JOIN CLSYeuCau y ON ct.CLSYeuCau_Id = y.CLSYeuCau_Id
		LEFT JOIN DM_PhongBan pb ON y.NoiYeuCau_Id = pb.PhongBan_Id
		LEFT JOIN DM_PhongBan pb1 ON b.NoiPhatSinh_Id = pb1.PhongBan_Id
		WHERE DaThanhToan = 1 
			  AND HoanTra = 0 
			  AND HuyHoaDon = 0
			  AND (a.LoaiGia_Id = 35 OR a.LoaiGia_Id = 36)
			  AND b.LoaiHoaDon = 'T'
			  AND ((pb.PhongBan_Id = 2 AND dv.DichVu_Id = 19248) 
				   OR (pb.PhongBan_Id = 3 AND dv.DichVu_Id = 19248) 
				   OR pb.PhongBan_Id = 14) 
			  AND (NoiPhatSinh_Id IN (1, 3, 2, 46, 563) OR pb1.CapTren_Id = 1)
		GROUP BY pb.TenPhongBan
	) x  


)xx on xx.PhongBan_Id = yy.PhongBan_Id
order by TenPhongBan



OPTION (FORCE ORDER);