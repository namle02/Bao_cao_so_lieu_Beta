SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRAN;


DECLARE 
@TuNgay 	DateTime = '@TuNgayParams',
@DenNgay 	DateTime = '@DenNgayParams'

IF OBJECT_ID('tempdb..#THONGKECLS') IS NOT NULL DROP TABLE #THONGKECLS;

select * into #THONGKECLS
from 
(
	select distinct
		Str1 = b.TenBenhNhan
		, str2 = case when b.GioiTinh = 'T' then 'Nam' else N'Nữ' end
		, str3 = tn.SoBHYT
        , dv.DichVu_Id
		, dv.TenDichVu_Ru
		, str5 = isnull(c.PhongBan_Id,'')
		, str6 = isnull(cd.tennhanvien,'') 
		, str7 = isnull(bskl.tennhanvien,'')
		, nhomdv.NhomDichVu_Id
		, str9 =  b.SoVaoVien
		, str10 =  ba.SoBenhAn
		, str11 =  convert (nvarchar(max), CLSKetQua.KetLuan)
		, str12 =  kt1.tennhanvien
		, str13 = ISNULL(dt.TenDoiTuong, dt1.TenDoiTuong)
		, str14 = b.DiaChi
		, str15 = CLS.ChanDoan
		, LoaiPTTT = pl.LoaiPhauThuat
		, num1 = isnull(CONVERT(VARCHAR, b.NgaySinh, 103),b.NamSinh)
		, num2 = 
			CASE 
				WHEN dv.NhomDichVu_Id = 53600 THEN ctCLS.SoLuong * (
					SELECT COUNT(*) FROM DM_dichvu WHERE captren_id = dv.dichvu_id
				)
				ELSE ctCLS.SoLuong
			END
		, num3 = ctCLS.DonGiaDoanhThu
		, Date1 = CLS.ThoiGianYeuCau
		, Date2 = CLSKetQua.ThoiGianThucHien
		, Date5 = ba.ThoiGianVaoVien
		, Date6 = ba.ThoiGianRaVien
		, MYT = b.SoVaoVien
		, Str18=lm.Dictionary_Name
		, Str19= convert (nvarchar(1000), MoTa_Text)
		, Str20 = 
			case
				when ba.NgayRaVien is not null then kr.TenPhongBan
			end
		, PBTH = pbth.PhongBan_Id
		, MienGiam = LydoMienGiam
		, NgheNghiep_Id = Nghe.Dictionary_Name
		, SDT = b.SoDienThoai
		, NoiLamViec = tn.NoiLamViec
		, NgaySinh = isnull(day(b.NgaySinh),'1')
		, ThangSinh = isnull(month(b.NgaySinh),'1')
		, NamSinh = isnull(year(b.NgaySinh),b.NamSinh)
		, TinhThanh = tinh.MaDonVi
		, QuanHuyen = quan.MaDonVi
		, PhuongXa = phuong.MaDonVi
		, ThonKhu = isnull(b.SoNha,'.')
		, TestNhanh = kqct.KetQua
		, NgayThucHien = CONVERT(nvarchar, CLSKetQua.ThoiGianThucHien, 108) + ' ' + CONVERT(nvarchar, CLSKetQua.ThoiGianThucHien, 103)
		, TienMienGiam = ctCLS.GiaTriMienGiam
		, DoiTuongDV = case when ctCLS.DonGiaHoTroChiTra != 0 then N'BHYT' else N'Viện phí, Yêu Cầu' end
		, NoiLamViecBS = bskl.PhongBan_Id
		, TenPBTH = pbth.TenPhongBan
		, TenPBCD = c.TenPhongBan
	FROM 	CLSKetQua  
 		join CLSYeuCau   CLS on CLSKetQua.CLSYeuCau_Id = CLS.CLSYeuCau_Id
 		join CLSYeuCauChiTiet   ctCLS on (ctCLS.CLSYeuCau_Id = CLS.CLSYeuCau_Id )
		LEFT join tiepnhan tn   on tn.tiepnhan_id = CLS.tiepnhan_id
		LEFT join BenhAn ba   on ba.BenhAn_Id = CLS.BenhAn_Id
		left join DM_DoiTuong dt   on dt.DoiTuong_Id = tn.DoiTuong_Id
		left join DM_DoiTuong dt1   on dt1.DoiTuong_Id = ba.DoiTuong_Id
		left join DM_PhongBan c   on c.PhongBan_Id = CLS.NoiYeuCau_Id
		left join DM_PhongBan pbth   on pbth.PhongBan_Id = CLS.NoiThucHien_Id
		left join DM_BenhNhan   B on CLS.BenhNhan_Id = B.BenhNhan_Id
		left join vw_NhanVien   bskl on CLSKetQua.BacSiKetLuan_Id = bskl.NhanVien_Id
		join DM_DichVu dv   on ctCLS.DichVu_Id = dv.DichVu_Id
		left join DM_NhomDichVu Nhomdv   on dv.NhomDichVu_Id = NHomdv.NhomDichVu_Id
		left join vw_NhanVien cd   on cd.nhanvien_id = cls.bacsichidinh_id	
		left join vw_NhanVien kt1   on kt1.nhanvien_id = CLSKetQua.KyThuatVien01_id	
		left join Lst_Dictionary lm   on cls.LoaiBenhPham_Id=lm.Dictionary_Id
		left join DM_PhongBan kr   on kr.PhongBan_Id = ba.KhoaRa_Id
		left JOIN NoiTru_LuuTru ntlt   ON ba.BenhAn_Id = ntlt.BenhAn_Id
		left join DM_PhanLoaiPhauThuat   pl on pl.DichVu_Id = dv.DichVu_Id
		left join Lst_Dictionary Nghe   on Nghe.Dictionary_Id = b.NgheNghiep_Id
		left join DM_DonViHanhChinh tinh   on tinh.DonViHanhChinh_Id = b.TinhThanh_Id
		left join DM_DonViHanhChinh quan   on quan.DonViHanhChinh_Id = b.QuanHuyen_Id
		left join DM_DonViHanhChinh phuong   on phuong.DonViHanhChinh_Id = b.XaPhuong_Id
		left join CLSKetQuaChiTiet kqct   on CLSKetQua.CLSKetQua_Id = kqct.CLSKetQua_Id and kqct.DichVu_Id in (32797, 32798, 32801, 32806, 32837, 32838, 32840,32842,32843, 32844, 32849, 32850, 32851, 32852, 32853, 32854, 32875, 32876, 32877)
		left join 
		(
			SELECT DISTINCT C2.BenhAn_Id,
			(   SELECT MGdic.Dictionary_Name +'; ' AS [text()]
			FROM MienGiamNoiTru C1
			left join Lst_Dictionary MGdic on MGdic.Dictionary_Id = C1.LyDo_ID
			WHERE C1.BenhAn_Id = C2.BenhAn_Id
			FOR XML PATH(''))[LydoMienGiam]
			FROM MienGiamNoiTru C2
			) lydoMG on lydoMG.BenhAn_Id = cls.BenhAn_Id
		WHERE
		 CLSKetQua.ThoiGianThucHien BETWEEN @TuNgay and @DenNgay
and huy = 0
	union all
-- PTTT CO KET QUA
	select distinct
		Str1 = b.TenBenhNhan
		, str2 = case when b.GioiTinh = 'T' then 'Nam' else N'Nữ' end
		, str3 = tn.SoBHYT
        , dv.DichVu_Id
		, dv.TenDichVu_Ru
		, str5 = isnull(c.PhongBan_Id,'')
		, str6 = isnull(cd.tennhanvien,'') 
		, str7 = isnull(bskl.tennhanvien,'')
		, nhomdv.NhomDichVu_Id
		, str9 =  b.SoVaoVien
		, str10 =  ba.SoBenhAn
		, str11 =  null
		, str12 =  kt1.tennhanvien
		, str13 = ISNULL(dt.TenDoiTuong, dt1.TenDoiTuong)
		, str14 = b.DiaChi
		, str15 = CLS.ChanDoan
		, LoaiPTTT = pl.LoaiPhauThuat
		, num1 =isnull(CONVERT(VARCHAR, b.NgaySinh, 103),b.NamSinh)
		, num2 = 
			CASE 
				WHEN dv.NhomDichVu_Id = 53600 THEN ctCLS.SoLuong * (
					SELECT COUNT(*) FROM DM_dichvu WHERE captren_id = dv.dichvu_id
				)
				ELSE ctCLS.SoLuong
			END
		, num3 = ctCLS.DonGiaDoanhThu
		, Date1 = CLS.ThoiGianYeuCau
		, Date2 = pt.ThoiGianBatDau
		, Date5 = ba.ThoiGianVaoVien
		, Date6 = ba.ThoiGianRaVien
		, MYT = b.SoVaoVien
		, Str18=lm.Dictionary_Name
		, Str19=null
		, Str20 = 
			case
				when ba.NgayRaVien is not null then kr.TenPhongBan
			end
		, PBTH = pbth.PhongBan_Id
		, MienGiam = LydoMienGiam
		, NgheNghiep_Id = Nghe.Dictionary_Name
		, SDT = b.SoDienThoai
		, NoiLamViec = tn.NoiLamViec
		, NgaySinh = isnull(day(b.NgaySinh),'1')
		, ThangSinh = isnull(month(b.NgaySinh),'1')
		, NamSinh = isnull(year(b.NgaySinh),b.NamSinh)
		, TinhThanh = tinh.MaDonVi
		, QuanHuyen = quan.MaDonVi
		, PhuongXa = phuong.MaDonVi
		, ThonKhu = isnull(b.SoNha,'.')
		, TestNhanh = ''
		, NgayThucHien = ''
		, TienMienGiam = ctCLS.GiaTriMienGiam
		, DoiTuongDV = case when ctCLS.DonGiaHoTroChiTra != 0 then N'BHYT' else N'Viện phí, Yêu Cầu' end
		, NoiLamViecBS = bskl.PhongBan_Id
		, TenPBTH = pbth.TenPhongBan
		, TenPBCD = c.TenPhongBan
	FROM 	benhanphauthuat pt  
		left join BenhAnPhauThuat_YeuCau ptyc   on pt.BenhAnPhauThuat_Id=ptyc.BenhAnPhauThuat_Id
		left join BenhAnPhauThuat_EKip vn   on pt.BenhAnPhauThuat_Id=vn.BenhAnPhauThuat_Id and vn.VaiTro_Id=748
	 	join CLSYeuCau   CLS on ptyc.CLSYeuCau_Id = CLS.CLSYeuCau_Id
	    join CLSYeuCauChiTiet   ctCLS on (ctCLS.CLSYeuCau_Id = CLS.CLSYeuCau_Id )
		LEFT join tiepnhan tn   on tn.tiepnhan_id = CLS.tiepnhan_id
		LEFT join BenhAn ba   on ba.BenhAn_Id = CLS.BenhAn_Id
		left join DM_DoiTuong dt   on dt.DoiTuong_Id = tn.DoiTuong_Id
		left join DM_DoiTuong dt1   on dt1.DoiTuong_Id = ba.DoiTuong_Id
		left join DM_PhongBan c   on c.PhongBan_Id = CLS.NoiYeuCau_Id
		left join DM_PhongBan pbth   on pbth.PhongBan_Id = CLS.NoiThucHien_Id
		left join DM_BenhNhan   B on CLS.BenhNhan_Id = B.BenhNhan_Id
		left join vw_NhanVien   bskl on vn.NhanVien_Id = bskl.NhanVien_Id --and vn.VaiTro_Id=748
		join DM_DichVu dv   on ctCLS.DichVu_Id = dv.DichVu_Id
		left join DM_NhomDichVu Nhomdv   on dv.NhomDichVu_Id = NHomdv.NhomDichVu_Id
		left join vw_NhanVien cd   on cd.nhanvien_id = cls.bacsichidinh_id	
		left join vw_NhanVien kt1   on vn.NhanVien_Id = kt1.NhanVien_Id and vn.VaiTro_Id=749	
		left join Lst_Dictionary lm   on cls.LoaiBenhPham_Id=lm.Dictionary_Id
		left join DM_PhongBan kr   on kr.PhongBan_Id = ba.KhoaRa_Id
		left join DM_PhanLoaiPhauThuat pl   on pl.DichVu_Id = dv.DichVu_Id
		left join Lst_Dictionary Nghe   on Nghe.Dictionary_Id = b.NgheNghiep_Id
		left join DM_DonViHanhChinh tinh on tinh.DonViHanhChinh_Id = b.TinhThanh_Id
		left join DM_DonViHanhChinh quan   on quan.DonViHanhChinh_Id = b.QuanHuyen_Id
		left join DM_DonViHanhChinh phuong   on phuong.DonViHanhChinh_Id = b.XaPhuong_Id
		left join 
		(
			SELECT DISTINCT C2.BenhAn_Id,
			(   SELECT MGdic.Dictionary_Name +'; ' AS [text()]
			FROM MienGiamNoiTru C1
			left join Lst_Dictionary MGdic on MGdic.Dictionary_Id = C1.LyDo_ID
			WHERE C1.BenhAn_Id = C2.BenhAn_Id
			FOR XML PATH(''))[LydoMienGiam]
			FROM MienGiamNoiTru C2
			) lydoMG on lydoMG.BenhAn_Id = cls.BenhAn_Id
		WHERE 
		 pt.ThoiGianBatDau BETWEEN @TuNgay and @DenNgay 
		 and huy = 0

) as x;


IF OBJECT_ID('tempdb..#CHUYENTUYEN') IS NOT NULL DROP TABLE #CHUYENTUYEN;

select * into #CHUYENTUYEN
from (
	
		select
			 So = A.SoPhieu
			, Ngay = NgayChuyen
			, DuDK = CASE WHEN A.LyDoChuyenVien_Id=1021 THEN 'X' else '' end
			 from 
			 ChuyenVien a
			 left  join DM_BenhVien b on a.BenhVien_Id = b.BenhVien_Id
			 join TiepNhan tn on tn.TiepNhan_Id = a.TiepNhan_Id
			 left join KhamBenh kb on a.khambenh_id = kb.khambenh_id 
			 where NgayChuyen between @TuNgay and @DenNgay
				 and kb.HuongGiaiQuyet_Id = 458 -- chi lay cach giai quyet chuyen tuyen
		union all
		select
			So = b.SoBenhAn
			, Ngay = b.NgayLap
			, DuDK = case when a.Field_11 = 1021 then 'X' ELSE '' END
			 from 
			 BenhAnTongQuat_GCV a
			 join BenhAnTongQuat b on a.BenhAnTongQuat_Id = b.BenhAnTongQuat_Id
			 join BenhAn c on c.BenhAn_Id = b.BenhAn_Id
			 join TiepNhan tn on tn.TiepNhan_Id = c.TiepNhan_Id
			 where CONVERT( date, b.NgayLap, 103) between @TuNgay and @DenNgay
			 and b.LoaiBenhAn_Id = 41 and  b.SoBenhAn like '%GCT'	
) as y;


IF OBJECT_ID('tempdb..#DICHVU') IS NOT NULL DROP TABLE #DICHVU;

select 
	NoiYeuCau_id,
	ycct.YeuCauChiTiet_Id,
	ycct.SoLuong,
	ycct.DichVu_Id,
	dv.NhomDichVu_Id
into #DICHVU
from CLSYeuCauChiTiet ycct 
	left join CLSYeuCau yc   on ycct.CLSYeuCau_Id = yc.CLSYeuCau_Id 
	left join DM_DichVu dv   on dv.DichVu_Id = ycct.DichVu_Id
	left join DM_NhomDichVu ndv   on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
where yc.NgayYeuCau between @TuNgay and @DenNgay
	and ycct.Huy = 0 ;


-- Truy vấn chính
	SELECT 
		HoatDong = N'Khám bệnh (toàn viện)',
		DonVi = N'Lượt',
		(SELECT COUNT(*) 
		FROM NoiTru_LuuTru lt
		WHERE  (lt.PhongBan_Id IN (40) OR lt.PhongBan_Id IN (621) OR lt.PhongBan_Id IN (64) OR lt.PhongBan_Id IN (105))
		AND LyDoVao_Code='NM' AND lt.thoigianvao  BETWEEN @tungay AND @denngay) 
			+
		(SELECT COUNT(*) 
			FROM KhamBenh kb 
			WHERE kb.ThoiGiankham  BETWEEN @tungay AND @denngay) 
			+
		(SELECT COUNT(*)
		FROM KSK_HopDong hd
		LEFT JOIN KSK_HopDong_BenhNhan bn ON hd.HopDong_ID=bn.HopDong_id
		WHERE hd.ThoiGiankham BETWEEN @tungay AND @denngay) 
		AS ChiSo

UNION ALL

	select  HoatDong = N'Khám bệnh (khoa khám bệnh)',
			DonVi = N'Lượt',
			ChiSo = sum(LuotKham)
	from (
			SELECT
				d.TenPhongBan,
				CASE 
					WHEN d.TenPhongBan = N'PK Phục hồi chức năng' THEN 
						ISNULL(SUM(d.LuotKham), 0) +
						ISNULL((
							SELECT SUM(ct.SoLuong)
							FROM CLSYeuCauChiTiet ct  
							JOIN CLSYeuCau cls   ON ct.CLSYeuCau_Id = cls.CLSYeuCau_Id
							WHERE cls.ThoiGianYeuCau BETWEEN @TuNgay AND @DenNgay
								AND ct.TrangThai = 'DaThucHien'
								AND ct.DichVu_Id = 25024
						), 0)
					ELSE ISNULL(SUM(d.LuotKham), 0)
				END AS LuotKham
			FROM (
				SELECT pb.TenPhongBan, COUNT(*) AS LuotKham
				FROM KhamBenh kb  
				JOIN DM_PhongBan pb   ON kb.PhongBan_Id = pb.PhongBan_Id
				WHERE kb.ThoiGianKham BETWEEN @TuNgay AND @DenNgay
					AND pb.PhongBan_Id IN (467,33,471,24,32,11,6,27,619,5,4,618,596,12,30,9,469,25,29,7,468)
				GROUP BY pb.TenPhongBan
			)d 
			GROUP BY d.TenPhongBan
	)a

UNION ALL

	select 
		HoatDong = N'Khám yêu cầu (khoa khám bệnh)',
		DonVi = N'Lượt',
		ChiSo = sum(LuotKham)
	FROM(
		SELECT
			TenPhongBan = pb.TenPhongBan,
			LuotKham = COUNT(*)
		FROM TiepNhan tn
			LEFT JOIN khambenh kb ON kb.TiepNhan_Id = tn.TiepNhan_Id
			LEFT JOIN DM_PhongBan pb on kb.PhongBan_Id = pb.PhongBan_Id
		WHERE kb.PhongBan_Id in (671, 14, 553, 15, 16, 18, 21, 850, 843) AND 
			kb.ThoiGianKham  BETWEEN @TuNgay AND @DenNgay
		group by pb.TenPhongBan, pb.PhongBan_Id
	) yy

UNION ALL

	select HoatDong = N'Khám cấp cứu (bao gồm CC Nhi)',
			DonVi = N'Lượt',
			ChiSo = SUM(LuotKham)
	from (
		SELECT
			TenPhongBan = pb.TenPhongBan, 
			LuotKham = COUNT(*)
		FROM NoiTru_LuuTru lt
		LEFT JOIN DM_PhongBan pb on lt.PhongBan_Id = pb.PhongBan_Id
		WHERE  lt.PhongBan_Id IN (40, 621)
		AND LyDoVao_Code='NM' AND lt.thoigianvao  BETWEEN @TuNgay AND @DenNgay
		group by pb.TenPhongBan
	) x

UNION ALL

	select 
		HoatDong = N'Số NB vào nội trú',
		DonVi = N'NB',
		ChiSo = SUM(CS)
	from (
		-- so moi vao khoa
		select
		C.PhongBan_Id as phongban_id,
		CS=COUNT(LuuTru_Id)
		from (
		select 
		lt.PhongBan_Id,
		lt.LuuTru_Id
		from NoiTru_LuuTru lt
		left join benhan ba on ba.BenhAn_Id=lt.BenhAn_Id
		where ThoiGianVao between @TuNgay and @DenNgay
		and LyDoVao_Code='NM'
		and lt.PhongBan_Id not in (40,1,76,559, 62, 235, 593, 74, 75, 621, 629)
		and ba.BenhAn_Id is not null
		) C
		group by c.PhongBan_Id

		union all

		-- nhap tu cap cuu
		select
		B.PhongBan_Id as phongban_id,
		CS=COUNT(LuuTru_Id)
		from(
		select 
		lt.PhongBan_Id,
		lt.LuuTru_Id
		from NoiTru_LuuTru lt
		left join benhan ba on ba.BenhAn_Id=lt.BenhAn_Id
		where 
		 (lt.LyDoChuyenKhoa_Id not in (1963,7014)) 
		and lt.ThoiGianVao between @TuNgay and @DenNgay
		and lt.PhongBanChuyenDen_Id in (40, 621, 629)
		and lt.LyDoVao_Code='CK'
		and lt.PhongBan_Id not in (40,1,76,559, 62, 235, 593, 74, 75, 621, 629)

		) B
		group by B.PhongBan_Id

		union all
		-- nhap moi tu cap cuu -> hoi tinh, phong mo chuyen ve khong qua khoa khac
		select
		B.PhongBan_Id  as phongban_id,
		count (LuuTru_Id) CS
		from (
		select 
		lt.PhongBan_Id ,
		lt.LuuTru_Id
		from NoiTru_LuuTru lt
		left join benhan ba on ba.BenhAn_Id=lt.BenhAn_Id
		-- benh nhan vao moi tu cap cuu hay khong
		OUTER APPLY 
		( select top 1 * from NoiTru_LuuTru ntlt
			where ntlt.BenhAn_Id = lt.BenhAn_Id and ntlt.LuuTru_Id < lt.LuuTru_Id and ntlt.PhongBan_Id in (40, 621, 629) and ntlt.LyDoVao_Code = 'NM'
		) lt2
		-- co di qua khoa khac ngoai phong mo, hoi tinh, cap cuu
		OUTER APPLY 
		( select top 1 * from NoiTru_LuuTru ntlt2
			where ntlt2.BenhAn_Id = lt.BenhAn_Id and ntlt2.LuuTru_Id < lt.LuuTru_Id and ntlt2.PhongBan_Id not in (40,62,235, 621, 629)
		) lt3
		where 
		lt2.LuuTru_Id is not null
		and lt3.LuuTru_Id is null
		and lt.PhongBanChuyenDen_Id in (235,62)
		and lt.PhongBan_Id not in (40,1,76,559, 62, 235, 593, 74, 75, 621, 629)
		and lt.ThoiGianVao between @TuNgay and @DenNgay
		and lt.LyDoVao_Code='CK'
		and (lt.LyDoChuyenKhoa_Id not in (1963,7014)) 
		)B
		group by B.PhongBan_Id	

	)x where phongban_id not in (570, 73, 577)

UNION ALL

	select 
		HoatDong = N'Tổng số ngày điều trị nội trú (+1)',
		DonVi = N'Ngày',
		ChiSo = SUM(SoNgDT)
	from (
		select SoNgDT = DATEDIFF(day, ba.ngayvaovien, ba.ngayravien) + 1 
		from BenhAn ba
			left join DM_PhongBan pb on pb.PhongBan_Id = ba.KhoaRa_Id
		where ba.ThoiGianRaVien between @TuNgay and @DenNgay
			and ba.KhoaRa_Id not in (40,1,76,559, 62, 235, 593, 74, 75, 621, 629)
			and phongban_id not in (570, 73, 577)
	)x

UNION ALL

	select
		HoatDong = N'Tổng số ngày điều trị nội trú',
		DonVi = N'Ngày',
		ChiSo = SUM(SoLuong)
	from (
		select pb.TenPhongBan,dv.TenDichVu, ct.SoLuong, yc.NoiYeuCau_Id from CLSYeuCau yc 
			left join CLSYeuCauChiTiet ct on ct.CLSYeuCau_Id =yc.CLSYeuCau_Id
			left join DM_DichVu dv on dv.DichVu_Id=ct.DichVu_Id
			left join DM_NhomDichVu ndv on ndv.NhomDichVu_Id=dv.NhomDichVu_Id
			left join DM_PhongBan pb on pb.PhongBan_Id=yc.NoiYeuCau_Id
			left join BenhAn ba on ba.BenhAn_Id=yc.BenhAn_Id
			left join Lst_Dictionary lba on lba.Dictionary_Id=ba.LoaiBenhAn_Id
		where ndv.NhomDichVu_Id in (45,53622,53665,53680)
			and yc.BenhAn_Id is not null
			and yc.NgayGioYeuCau between @TuNgay and @DenNgay
			and yc.NoiYeuCau_Id not in (40,1,76,559, 62, 235, 593, 74, 75, 621, 629)
	) D

UNION ALL

	select 
		HoatDong = N'Số NB chuyển viện',
		DonVi = N'Ca',
		ChiSo = count(*)
	from #CHUYENTUYEN

UNION ALL

	select 
		HoatDong = N'- Đúng tuyến',
		DonVi = N'Ca',
		ChiSo = count(*)
	from #CHUYENTUYEN
	where DuDK = 'X'

UNION ALL

	select 
		HoatDong = N'- Trái tuyến',
		DonVi = N'Ca',
		ChiSo = count(*)
	from #CHUYENTUYEN
	where DuDK = ''

UNION ALL

	select 
		HoatDong = N'Tổng số ca phẫu thuật',
		DonVi = N'Ca',
		ChiSo = SUM(soluong)
	from (

		select
			 SoBenhAn = bn.sovaovien
			, PPPT = dv.DichVu_Id
			, KhoaCD=pbcd.TenPhongBan
			, clsct.SoLuong
			, pb1.TenPhongBan
			, nhom.NhomDichVu_Id
		from CLSYeuCau CLS  
			left join CLSYeuCauChiTiet clsct   on clsct.CLSYeuCau_Id=cls.CLSYeuCau_Id
			left join BenhAnPhauThuat PT   on PT.CLSYeuCau_Id = CLS.CLSYeuCau_Id
			join DM_BenhNhan bn   on (CLS.BenhNhan_Id = bn.BenhNhan_Id)
			left join BenhAnPhauThuat_YeuCau yc   on yc.BenhAnPhauThuat_Id=pt.BenhAnPhauThuat_Id
			left join DM_PhanLoaiPhauThuat lpt   on lpt.DichVu_Id = yc.DichVu_Id
			left join DM_LoaiPhauThuat Laynhom   on Laynhom.LoaiPhauThuat = lpt.LoaiPhauThuat
			left join DM_DichVu dv   on yc.DichVu_Id=dv.DichVu_Id
			left join DM_NhomDichVu nhom   on yc.NhomDichVu_Id = nhom.NhomDichVu_Id
			left join DM_PhongBan pbcd   on pbcd.PhongBan_Id=cls.NoiYeuCau_Id
			left join DM_PhongBan pb1   on pb1.PhongBan_Id=pt.PhongBanThucHien_Id
		where	
			cls.ThoiGianYeuCau between @TuNgay and @DenNgay
	 		and (Laynhom.LoaiTuongTrinh = 'PT') 
			and LoaiDichVu_Id in (3,8)
 
		union all

		select	
			SoBenhAn =  bn.sovaovien
			, PPPT = dv.DichVu_Id
			, KhoaCD=pbcd.TenPhongBan
			, ct.SoLuong
			, tenphongban = pb1.TenPhongBan
			, nhom.NhomDichVu_Id
		from	clsyeucau yc
			left join clsyeucauchitiet ct   on yc.CLSYeuCau_Id=ct.clsyeucau_id
			left join CLSKetQua kq   on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
			left join dm_dichvu dv   on ct.dichvu_id=dv.dichvu_id
			left join dm_nhomdichvu nhom   on dv.NhomDichVu_Id=nhom.nhomdichvu_id
			left join DM_PhongBan pbcd   on pbcd.PhongBan_Id=yc.NoiYeuCau_Id
			left join DM_PhongBan pb1   on pb1.PhongBan_Id=kq.NoiThucHien_Id
			left  join DM_PhanLoaiPhauThuat lpt   on lpt.DichVu_Id = dv.DichVu_Id
			join DM_BenhNhan bn   on (yc.BenhNhan_Id = bn.BenhNhan_Id)
			left join DM_LoaiPhauThuat Laynhom   on Laynhom.LoaiPhauThuat = lpt.LoaiPhauThuat
	

		where 	yc.ThoiGianYeuCau between @TuNgay and @DenNgay
			and (Laynhom.LoaiTuongTrinh = 'PT') 
			and LoaiDichVu_Id not in  (3,8)		
		) cc

UNION ALL

	SELECT 
		HoatDong = N'Số ca đẻ',
		DonVi = N'Ca',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.TenDichVu_Ru IN ('Chiso53_1','Chiso53_2') 
		AND cls.DichVu_Id != 22021
		AND cls.str5 in (64, 105)

UNION ALL

	SELECT 
		HoatDong = N'Chụp CT các loại',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.DichVu_Id NOT IN (21998)
		AND cls.NhomDichVu_Id IN (15)	

UNION ALL

	SELECT 
		HoatDong = N'- CT <32 dãy',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.DichVu_Id NOT IN (21998)
		AND cls.NhomDichVu_Id IN (15)	
		AND cls.TenDichVu_Ru = 'ct32'

UNION ALL

	SELECT 
		HoatDong = N'- CT 128 dãy (Máy CT 256)',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.DichVu_Id NOT IN (21998)
		AND cls.NhomDichVu_Id IN (15)	
		AND cls.TenDichVu_Ru = 'ct128'

UNION ALL

	SELECT 
		HoatDong = N'- CT 256 dãy (Máy CT 256)',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.DichVu_Id NOT IN (21998)
		AND cls.NhomDichVu_Id IN (15)	
		AND cls.TenDichVu_Ru = 'ct256'

UNION ALL

	SELECT 
		HoatDong = N'- MRI',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.NhomDichVu_Id IN (17)

UNION ALL

	SELECT 
		HoatDong = N'- Xquang',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.DichVu_Id NOT IN (29151,29152,22295)
		AND cls.NhomDichVu_Id IN (14)

UNION ALL

	select 
		HoatDong = N'Siêu âm toàn viện',
		DonVi = N'Lần',
		ChiSo = count(*)
	FROM #THONGKECLS cls  
	WHERE 	--siêu âm tim Khoa nội tim mạch
			((cls.NhomDichVu_Id = 53611 and cls.DichVu_Id not in (20394,24623) and cls.PBTH = 100)) or 
			(cls.NhomDichVu_Id = 13 and cls.DichVu_Id in (19273,19498,19503,19722,22718,22732) and cls.PBTH = 100) or
			--siêu âm tim Khoa khám bệnh
			(cls.DichVu_Id in (19498,19499,19502,19273,22718,22732,22733,24616,19272,24622,22738) and cls.PBTH in (487,488)) or
			--siêu âm sản thường đã ổn
			(cls.PBTH = 479 and cls.NhomDichVu_Id = 13) or
			--siêu âm sản yêu cầu 
			(cls.PBTH = 22 and cls.NhomDichVu_Id = 13) or
			--siêu âm D32 đã ổn
			(cls.PBTH = 65 and cls.str5 = 65 and cls.NhomDichVu_Id = 13) or
			--siêu âm mắt 
			(cls.PBTH = 627 and cls.DichVu_Id = 22294) or
			--siêu âm x-quang đã ổn
			(cls.NoiLamViecBS = 77 and cls.TenPBTH not like N'%PK%yêu cầu%' and cls.PBTH != 17 and cls.NhomDichVu_Id = 13 and (cls.TenPBCD not like N'%PK%yêu cầu%' or (cls.str5 in (843, 15,16) and cls.DichVu_Id in (26583,26585)))) or
			--siêu âm ổ bụng yêu cầu 
			(cls.DichVu_Id in (19597,19647,19648,22697,22698,22699,22700,22702,22705,22706,22707,22709,22710,22715,22716,22717,22718,22730,22731,22740,22741,22742,22743,22744,32497) and cls.PBTH = 17) or
			--siêu âm sản (D2 + D21)
			(cls.PBTH in (105, 901) and cls.NhomDichVu_Id in(13)) or
			--siêu âm sản (D12) đã ổn
			(cls.PBTH = 64 and cls.str5 = 64 and cls.DichVu_Id in (22714,22722,22726,22727,22728))

UNION ALL

	SELECT 
		HoatDong = N'Nội soi dạ dày (Bao gồm cả soi chẩn đoán và can thiệp)',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.DichVu_Id in (23102,19572,19591,23108,19592,19399)

UNION ALL

	SELECT 
		HoatDong = N'Nội soi đại, trực tràng (bao gồm cả can thiệp)',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.DichVu_Id in (19587,19588,19583,19560,19595,19563,19564,19562)

UNION ALL

	select 
		HoatDong = N'Can thiệp tim mạch',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2) 
	from #THONGKECLS cls  
	where cls.TenDichVu_Ru = ('cttm') 

UNION ALL

	select 
		HoatDong = N'Xét nghiệm huyết học',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	from #THONGKECLS cls  
	where
		cls.NhomDichVu_Id in (2,53631, 53649, 53682)
		and cls.DichVu_Id not in (32806,32837,32838,32840,32842,32843,32844,32849,32850,32851,32852,32853,32854,32875,32876,32877,32881,32914)

UNION ALL

	SELECT 
		HoatDong = N'Xét nghiệm hoá sinh',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.NhomDichVu_Id in (53670,71,73,53664,3,6,53600) and cls.DichVu_Id not in (19413,29455,29654,23308)

UNION ALL

	SELECT 
		HoatDong = N'Giải phẫu bệnh',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.NhomDichVu_Id in (53595)

UNION ALL

	SELECT 
		HoatDong = N'Xét nghiệm vi sinh',
		DonVi = N'Lần',
		ChiSo = SUM(cls.num2)
	FROM #THONGKECLS cls  
	WHERE 
		cls.NhomDichVu_Id in (53669,4,53632,53674)

UNION ALL

	select 
		HoatDong = N'Điều trị bằng Oxy cao áp',
		DonVi = N'Lần',
		ChiSo = count(*)
	FROM 	
		CLSYeuCauChiTiet   ctCLS 
		join CLSYeuCau   CLS on ctCLS.CLSYeuCau_Id = CLS.CLSYeuCau_Id
		join DM_DichVu dv    on ctCLS.DichVu_Id = dv.DichVu_Id
		left join DM_NhomDichVu   Nhomdv on dv.NhomDichVu_Id = NHomdv.NhomDichVu_Id
		left join DM_PhongBan   pb on pb.PhongBan_Id = cls.NoiThucHien_Id 
		left join DM_PhongBan nth on cls.NoiThucHien_Id = nth.PhongBan_Id
	WHERE 
		cls.ThoiGianYeuCau BETWEEN @TuNgay and @DenNgay
		and huy = 0
		and dv.DichVu_Id in (28813,29091,29096,29242)

UNION ALL

	SELECT 
		HoatDong = N'Giường yêu cầu',
		DonVi = N'Ngày',
		ChiSo = SUM(
			CASE 
				WHEN TenDichVu LIKE '%VIP%' OR TenDichVu LIKE '%1%' OR TenDichVu LIKE N'%giường%' OR TenDichVu LIKE '%5%' THEN 1
				WHEN TenDichVu LIKE N'%2%cả phòng%' THEN 2
				WHEN TenDichVu LIKE N'%3%cả phòng%' THEN 3
				WHEN TenDichVu LIKE N'%4%cả phòng%' THEN 4
				ELSE 0
			END
		)
	FROM CLSYeuCauChiTiet ctCLS
	JOIN CLSYeuCau CLS ON ctCLS.CLSYeuCau_Id = CLS.CLSYeuCau_Id
	JOIN DM_DichVu dv ON ctCLS.DichVu_Id = dv.DichVu_Id
	WHERE CLS.ThoiGianYeuCau BETWEEN @TuNgay AND @DenNgay
		AND ctCLS.Huy = 0
		AND TenDichVu like N'Dịch vụ của phòng yêu cầu%'

UNION ALL

	select 
		HoatDong = N'Dịch vụ mổ yêu cầu',
		DonVi = N'Ca',
		ChiSo = SUM(SoLuong)
	from #DICHVU
	where DichVu_Id in (24211,24212,24213,24214,30154,30155,30156,30239,30240,30241,30242,33670)

UNION ALL

	select 
		HoatDong = N'Chọn phẫu thuật viên',
		DonVi = N'Ca',
		ChiSo = SUM(SoLuong)
	from #DICHVU
	where DichVu_Id in (24212,24213,24214)			


UNION ALL

	select 
		HoatDong = N'Phẫu thuật mổ trong ngày/chọn ngày',
		DonVi = N'Ca',
		ChiSo = SUM(SoLuong)
	from #DICHVU
	where DichVu_Id in (24211)		


UNION ALL

	select 
		HoatDong = N'Các dịch vụ mổ yêu cầu khác',
		DonVi = N'Ca',
		ChiSo = SUM(SoLuong)
	from #DICHVU
	where DichVu_Id in (30154,30155,30156,30239,30240,30241,30242,33670)	


OPTION (FORCE ORDER);