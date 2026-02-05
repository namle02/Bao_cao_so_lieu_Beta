SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRAN;

DECLARE 
@TuNgay 	DateTime = '@TuNgayParams',
@DenNgay 	DateTime = '@DenNgayParams'

-- Danh sách khoa phòng theo thứ tự mong muốn
;WITH KhoaPhongOrder AS (
    SELECT *
    FROM (VALUES 
        (1, N'PK Bệnh Nhiệt Đới - Da liễu'),
        (2, N'PK Mắt'),
        (3, N'PK Ngoại 01'),
        (4, N'PK Ngoại 02'),
        (5, N'PK Nhi'),
        (6, N'PK Nội hô hấp, Thận tiết niệu'),
        (7, N'PK Nội thần kinh, cơ xương khớp'),
        (8, N'PK Nội tiết 01'),
        (9, N'PK Nội tiết 02'),
        (10, N'PK Nội Tiêu hóa'),
        (11, N'PK Nội tim mạch 01'),
        (12, N'PK Nội tim mạch 02'),
        (13, N'PK Phục hồi chức năng'),
        (14, N'PK Răng hàm mặt'),
        (15, N'PK Sản phụ khoa'),
        (16, N'PK Tai mũi họng'),
        (17, N'PK Tâm Bệnh'),
        (18, N'PK Ung bướu'),
        (19, N'PK Y học cổ truyền'),
        (20, N'PK Can thiệp Tim mạch - Lồng ngực'),
        (21, N'PK hiếm muộn')
    ) AS KhoaPhong(STT, TenPhongBan)
),

-- CTE cc: tổng lượt khám
cc AS (
    SELECT 
        d.TenPhongBan,
        CASE 
            WHEN d.TenPhongBan = N'PK Phục hồi chức năng' THEN 
                ISNULL(SUM(x.LuotKham), 0) +
                ISNULL((
                    SELECT SUM(ct.SoLuong)
                    FROM CLSYeuCauChiTiet ct WITH (NOLOCK)
                    JOIN CLSYeuCau cls WITH (NOLOCK) ON ct.CLSYeuCau_Id = cls.CLSYeuCau_Id
                    WHERE cls.ThoiGianYeuCau BETWEEN @TuNgay AND @DenNgay
                      AND ct.TrangThai = 'DaThucHien'
                      AND ct.DichVu_Id = 25024
                ), 0)
            ELSE ISNULL(SUM(x.LuotKham), 0)
        END AS LuotKham
    FROM KhoaPhongOrder d
    LEFT JOIN (
        SELECT pb.TenPhongBan, COUNT(*) AS LuotKham
        FROM KhamBenh kb WITH (NOLOCK)
        JOIN DM_PhongBan pb WITH (NOLOCK) ON kb.PhongBan_Id = pb.PhongBan_Id
        WHERE kb.ThoiGianKham BETWEEN @TuNgay AND @DenNgay
          AND pb.PhongBan_Id IN (467,33,471,24,32,11,6,27,619,5,4,618,596,12,30,9,469,25,29,7,468)
        GROUP BY pb.TenPhongBan
    ) x ON d.TenPhongBan = x.TenPhongBan
    GROUP BY d.TenPhongBan
),

-- CTE bb: tổng nhập viện
bb AS (
    SELECT pbden.TenPhongBan AS PhongBan, COUNT(*) AS NhapVien
    FROM BenhAn ba
    JOIN NoiTru_LuuTru ntlt ON ntlt.BenhAn_Id = ba.BenhAn_Id
    JOIN DM_BenhNhan bn ON bn.BenhNhan_Id = ba.BenhNhan_Id
    JOIN TiepNhan tn ON tn.TiepNhan_ID = ba.TIEPNHAN_ID
    JOIN DM_PhongBan pbden ON ntlt.PhongBanChuyenDen_Id = pbden.PhongBan_Id
    JOIN NoiTru_LuuTruChiTiet ntct ON ntct.LuuTru_Id = ntlt.LuuTru_Id AND ntct.LuuTruChiTiet_Id = (
        SELECT MAX(ct.LuuTruChiTiet_Id) FROM NoiTru_LuuTruChiTiet ct WHERE ct.LuuTru_Id = ntlt.LuuTru_Id
    )
    WHERE ntlt.ThoiGianVao BETWEEN @TuNgay AND @DenNgay
      AND pbden.PhongBan_Id IN (467,33,471,24,32,11,6,27,619,5,4,618,596,12,30,9,469,25,29,7,596,468)
    GROUP BY pbden.TenPhongBan
),

-- CTE dd: tổng TPYC
dd AS (
	SELECT 
		kp.TenPhongBan,
		Tong = ISNULL(SUM(x.tongtien), 0) -- Lấp đầy giá trị 0 nếu không có dữ liệu
	FROM KhoaPhongOrder kp
	LEFT JOIN (
		SELECT 
			pb.TenPhongBan,
			ct.GiaTriDaThanhToan AS tongtien 
		FROM 
			CLSYeuCauChiTiet ct WITH (NOLOCK)
		LEFT JOIN 
			CLSYeuCau cls WITH (NOLOCK) ON cls.CLSYeuCau_Id = ct.CLSYeuCau_Id
		LEFT JOIN 
			DM_DoiTuong dt WITH (NOLOCK) ON dt.DoiTuong_Id = ct.DoiTuong_Id
		LEFT JOIN 
			DM_PhongBan pb WITH (NOLOCK) ON pb.PhongBan_Id = cls.NoiYeuCau_Id
		LEFT JOIN 
			KhamBenh kb WITH (NOLOCK) ON kb.KhamBenh_Id = cls.KhamBenh_Id
		WHERE 
			cls.ThoiGianYeuCau BETWEEN @TuNgay AND @DenNgay
			AND kb.DoiTuong_Id IN (1043,1044,1045,1054,1070,1071,1072,1073,1074)
			AND ct.huy = 0 
			AND ct.LoaiGia_Id IN (4,35) 
			AND ct.DaThanhToan_HoanTat = 1
			AND cls.BenhAn_Id IS NULL
	) x 
	ON kp.TenPhongBan = x.TenPhongBan 
	GROUP BY kp.TenPhongBan
),

-- CTE ee: tổng chi BHYT
ee AS (
	Select 
		kp.TenPhongBan,
		ISNULL(SUM(AA.t_TongChi), 0) AS t_TongChi,
		ISNULL(COUNT(*), 0) AS luotkham
	from KhoaPhongOrder kp
	left join
	(
		select 
			t_TongChi	= Sum(case when DuocDieuKien_Id is not null then CHIPHI.DonGiaDoanhThu*chiphi.Soluong else chiphi.DonGiaHoTro*chiphi.SoLuong end)
			, khoa	= chiphi.TenPhongKham
		from 
		(
			select	ID = XNCT.XacNhanChiPhiChiTiet_Id
					, XN.SoXacNhan
					, SoTiepNhan
					, XN.Loai
					, XN.NgayXacNhan
					, ba.NgayRaVien
					, TN.NgayTiepNhan
					, XN.TiepNhan_Id
					, XN.BenhNhan_Id
					, isnull(TN.SoBHYT,XN.SoBHYT)  SoBHYT
					, TN.BHYTTuNgay
					, TN.BHYTDenNgay
					, BV.TenBenhVien
					, MaBenhVien = BV.TenBenhVien_EN
					, TuyenKB = isnull(TuyenKB.Dictionary_Name,xn.TuyenKhamBenh)
					, Lydo= lst.Dictionary_Name
					, LyDoMa = lst.Dictionary_Name_En
					, XN.NgayKham
					, MaBenh	=	MaBenh 
					, BenhKhac	=	BenhKhac  
					, tn.LyDoTiepNhan_Id
					, XNCT.Loai_IDRef
					, XNCT.IDRef
					, XNCT.NoiDung_ID
					, XNCT.NoiDung
					, Soluong=CASE WHEN clsyc.PT50 = 1 THEN CAST(XNCT.SoLuong as Decimal(18,3))  * 0.5 
					WHEN clsyc.PT80 = 1 THEN CAST(XNCT.SoLuong as Decimal(18,3))  * 0.8 
					ELSE
					CAST(XNCT.SoLuong as Decimal(18,3))  END 
					,CAST( XNCT.SoLuong  as Decimal(18,3)) Soluong1
					,DonGiaDoanhThu=CAST( XNCT.DonGiaDoanhThu as Decimal(18,2)) 
					, DonGiaHoTro= case when xbn.DuocDieuKien_Id is  null then CAST(   XNCT.DonGiaHoTro * (case when yc.NhomDichVu_Id <> 27 and (isnull(clsyc.Ghep2,0)=1 or isnull(clsyc.Ghep3,0)=1) then isnull(clsyc.TyLeThanhToan,1) else 1 end)as Decimal(18,2))
										else CAST(  xnct.DonGiaHoTro as Decimal(18,2)) end
					,DonGiaHoTroChiTra=CAST( XNCT.DonGiaHoTroChiTra as Decimal(18,2)) 
					,DonGiaThanhToan=CAST( XNCT.DonGiaThanhToan as Decimal(18,2))	
					, xn.TenPhongKham	
					, ba.ICD_BenhChinh
					, Muc_Huong
					, DuocDieuKien_Id
					, ba.BacSiDieuTri_Id
					, isnull(CtyHopDong,0) as CtyHopDong
					, Chenhlech=case when (isnull(xbn.DuocDieuKien_Id,0) <>0 ) then XNCT.DonGiaDoanhThu-XNCT.DonGiaHoTro else 0 end
					, xbn.GiaTriMienGiam
					, ba.BenhAn_Id
			from	XacNhanChiPhi xn (nolock)
					left join XacNhanChiPhiChiTiet XNCT (nolock) on XNCT.XacNhanChiPhi_Id= XN.XacNhanChiPhi_Id
					left join TiepNhan TN (nolock) on TN.TiepNhan_Id = XN.TiepNhan_Id
					left join DM_Benhvien BV (nolock) on isnull(TN.BenhVien_KCB_Id,xn.BenhVien_id) = BV.BenhVien_Id
					left join Lst_Dictionary LST (nolock) on LST.Dictionary_Id = TN.LyDoTiepNhan_Id
					Left join Lst_Dictionary TuyenKB (nolock) on TuyenKB.Dictionary_Id = TN.TuyenKhamBenh_ID
					left join BenhAn (nolock) ba on xn.BenhAn_Id= ba.BenhAn_Id
					left join Lst_Dictionary (nolock) lba on ba.LoaiBenhAn_Id=lba.Dictionary_Id
					left join CLSYeuCauChiTiet clsyc (nolock) on xnct.IDRef= clsyc.YeuCauChiTiet_Id and XNCT.Loai_IDRef='A'
					left join CLSYeuCau yc on clsyc.CLSYeuCau_Id=yc.CLSYeuCau_Id
					left join ChungTuXuatBenhNhan xbn (nolock) on xnct.IDRef=xbn.ChungTuXuatBN_Id and XNCT.Loai_IDRef='I'

			Where 
			 (  
					(xn.Loai = 'NgoaiTru' 
					and isnull(xn.ThoiGianDuyetKiemTra, xn.ThoiGianXacNhan) between @TuNgay and @DenNgay   
					)

				or 
					(xn.Loai = 'NoiTru'	
						AND isnull(lba.Dictionary_Name_Ru,'') = '01/BV'
						and xn.thoigianxacnhan between @TuNgay and @DenNgay
					)
				)
			
			and XNCT.DonGiaHoTroChiTra > 0
			and SoXacNhan is not null
		) CHIPHI
			left join VienPhiNoiTru_Loai_IDRef ref on chiphi.Loai_IdRef = ref.Loai_IdRef
			left join	(	
							select	mbc.TenField
									, dn.DichVu_Id
							from	DM_MauBaoCao mbc
									join DM_DinhNghiaDichVu dn on dn.NhomBaoCao_Id = mbc.ID
							where	MauBC= 'BCVP_097' 
						) c on c.DichVu_Id = chiphi.NoiDung_Id And ref.PhanNhom = 'DV'
			left join DM_DichVu dv (nolock) on  dv.DichVu_Id = chiphi.NoiDung_Id And ref.PhanNhom = 'DV'
			left join DM_Duoc  duoc (NOLOCK) on chiphi.NoiDung_Id = duoc.Duoc_Id and ref.PhanNhom = 'DU'
			left join DM_LoaiDuoc ld (nolock)on duoc.LoaiDuoc_Id = ld.LoaiDuoc_Id
			left join DM_BenhNhan bn (nolock) ON ChiPhi.BenhNhan_Id = bn.BenhNhan_Id	
			left join KhamBenh kb(nolock) on CHIPHI.TiepNhan_Id = kb.TiepNhan_Id and khambenh_id=(select max(k.KhamBenh_Id) from khambenh k where k.TiepNhan_Id=chiphi.TiepNhan_Id)
			left join vw_NhanVien nv on isnull(kb.BacSiKham_Id,CHIPHI.BacSiDieuTri_Id)=nv.NhanVien_Id
			left join dm_ICD I on kb.chandoanICD_id=i.Icd_id
			left join dm_icd icd on CHIPHI.ICD_BenhChinh=icd.icd_id
			where  isnull(duoc.BHYT,1)=1
						
		group by 
			CHIPHI.TiepNhan_ID 
			, CHIPHI.MaBenhVien
			, CHIPHI.TuyenKB
			, CHIPHI.NgayKham
			, BN.TenBenhNhan
			, BN.GioiTinh
			, BN.NamSinh
			, CHIPHI.SoBHYT
			, CHIPHI.MaBenh
			, BN.SoVaoVien
			, CHIPHI.TenBenhVien
			, CHIPHI.BHYTTuNgay
			, CHIPHI.BHYTDenNgay
			, CHIPHI.BenhKhac
			, bn.DiaChi
			, CHIPHI.LyDoTiepNhan_Id
			, CHIPHI.SoXacNhan
			, CHIPHI.TenPhongKham
			, chiphi.lydo, chiphi.LyDoMa
			,CHIPHI.NgayXacNhan,   SoTiepNhan 
			, i.MaICD, icd.MaICD
			,CHIPHI.ngayravien, BacSiDieuTri_Id
			, NgayTiepNhan, nv.TenNhanVien
			, CHIPHI.BenhAn_Id
	) AA on kp.TenPhongBan = aa.khoa
	group by kp.TenPhongBan
),

-- CTE xx: viện phí ngoại trú
xx AS (
	SELECT  kp.TenPhongBan as KhoaPhong,
    tbhsvp = ISNULL(SUM(aa.VienPhi) / NULLIF(SUM(aa.soluot), 0), NULL),
	tongthu = ISNULL(SUM(aa.VienPhi), 0),
    luotkham = ISNULL(SUM(aa.soluot), 0)
	FROM KhoaPhongOrder kp
	left join(
	SELECT  SoHoaDon, MaSoThu, MaBN, TenBenhNhan, KhoaPhong, TenDichVu
		, DichVu = SUM(DichVu)
		, VienPhi = SUM(VienPhi)
		, BaoHiem = SUM(BaoHiem)
		, huy= sum(huy)
		, Tong= SUM(Tong)
		, TamUng, HoanUng, Loai_Id, str1
		, Tongtien=(sum(tong)+TamUng)-HoanUng
		, SoLuot=sum(soluot)
	FROM (
 
		 SELECT SoHoaDon = (vp.SoHoaDonVAT)
		 , MaSoThu = (vp.SoHoaDon)
		 , MaBN = dmbn.SoVaoVien
		 , TenBenhNhan = dmbn.TenBenhNhan
		 , KhoaPhong = (SELECT TOP 1 pb.TenPhongBan FROM KhamBenh kb 
								JOIN DM_PHONGBAN pb on kb.PhongBan_Id=pb.PhongBan_Id
						WHERE kb.TiepNhan_Id = vp.TiepNhan_Id ORDER BY kb.KhamBenh_Id Desc)
		 , TenDichvu = N'Viện phí ngoại Trú'
		 , DichVu  = 0
		 , VienPhi = Sum((case when vpct.LoaiGia_Id = 4 or (vpct.LoaiGia_Id not in( 35 ,36) and vpct.DonGiaHoTroChiTra=0) then vpct.GiaTriThucThu else 0 end)
						)
	
		 , BaoHiem = Sum(case when vpct.LoaiGia_Id<>35 and isnull(vpct.DonGiaHoTroChiTra, 0) <> 0 then vpct.GiaTriThucThu_HoTroChenhLech else 0 end) 
		 , Huy=0
		 , Tong = Sum(vpct.giatrithucthu) 
		 , TamUng = sum(CASE WHEN vp.LoaiHoaDon = 'A' THEN vp.GiaTriHoaDon ELSE 0 END)
		 , HoanUng = Sum(CASE WHEN vp.LoaiHoaDon = 'H' THEN vp.GiaTriHoaDon ELSE 0 END)
		 , 1 Loai_Id
		 , str1 = nv.TenNhanVien
		  , SoSerieVAT soquyen
		  , soluot=0
	From	 HoaDon vp 
		 LEFT JOIN HoaDonChiTiet vpct ON vp.HoaDon_Id=vpct.HoaDon_Id
		 JOIN DM_BENHNHAN dmbn on dmbn.BenhNhan_Id = vp.BenhNhan_Id
		 LEFT JOIN DM_DoiTuong dt ON vp.DoiTuong_Id=dt.DoiTuong_Id
		 LEFT JOIN vw_NhanVien nv ON vp.NguoiThuTien_Id=nv.NhanVien_Id
		left  join dm_phongban pb on vp.NoiPhatSinh_Id=pb.PhongBan_Id
	 WHERE  vp.DaThanhToan=1 and( vp.HuyHoaDon=0)
			AND vp.ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
			and( NoiPhatSinh_Id in (1,3,2,46,563) or   pb.CapTren_Id=1)

	 GROUP BY vp.SoHoaDonVAT
		 ,vp.SoHoaDon
		 , VP.ID_SAVE, SoSerieVAT
		 ,dmbn.SoVaoVien
		 ,dmbn.TenBenhNhan
		 ,vp.TiepNhan_Id
		 ,vp.LoaiHoaDon
		 ,dt.NhomDoiTuong_Id
		 ,dt.TyLe_2
		 ,nv.TenNhanVien

		union all
		SELECT SoHoaDon = (vp.SoHoaDonVAT)
			, MaSoThu = (vp.SoHoaDon)
			, MaBN = dmbn.SoVaoVien
			, TenBenhNhan = dmbn.TenBenhNhan
			, KhoaPhong = (SELECT TOP 1 pb.TenPhongBan FROM KhamBenh kb 
								JOIN DM_PHONGBAN pb on kb.PhongBan_Id=pb.PhongBan_Id
						WHERE kb.TiepNhan_Id = vp.TiepNhan_Id ORDER BY kb.KhamBenh_Id Desc)
			, TenDichvu = N'Viện phí ngoại Trú'
			, DichVu  = 0
			, VienPhi = -Sum((case when vpct.LoaiGia_Id = 4 or (vpct.LoaiGia_Id not in( 35 ,36) and vpct.DonGiaHoTroChiTra=0) then vpct.GiaTriThucThu else 0 end)
						)
	
			, BaoHiem = -Sum(case when vpct.LoaiGia_Id<>35 and isnull(vpct.DonGiaHoTroChiTra, 0) <> 0 then vpct.GiaTriThucThu_HoTroChenhLech else 0 end) 
			, Huy=0
			, Tong = -Sum(vpct.giatrithucthu) 
			, TamUng = 0
			, HoanUng = 0
			, 1 Loai_Id
			, str1 = nv.TenNhanVien
			, SoSerieVAT soquyen
			, soluot=0
		From HoaDon vp 
			LEFT JOIN HoaDonChiTiet vpct ON vp.HoaDon_Id=vpct.HoaDon_Id
			JOIN DM_BENHNHAN dmbn on dmbn.BenhNhan_Id = vp.BenhNhan_Id
			LEFT JOIN DM_DoiTuong dt ON vp.DoiTuong_Id=dt.DoiTuong_Id
			LEFT JOIN vw_NhanVien nv ON vp.NguoiThuTien_Id=nv.NhanVien_Id
			left join dm_phongban pb on vp.NoiPhatSinh_Id=pb.PhongBan_Id
		WHERE vp.DaThanhToan=1 and( vp.HoanTra=1)
			AND vp.ThoiGianTra BETWEEN @TuNgay AND @DenNgay
			and( NoiPhatSinh_Id in (1,3,2,46,563) or   pb.CapTren_Id=1)
		GROUP BY vp.SoHoaDonVAT
			,vp.SoHoaDon
			, VP.ID_SAVE, SoSerieVAT
			,dmbn.SoVaoVien
			,dmbn.TenBenhNhan
			,vp.TiepNhan_Id
			,vp.LoaiHoaDon
			,dt.NhomDoiTuong_ID
			,dt.TyLe_2
			,nv.TenNhanVien

		union all


		SELECT SoHoaDon = (vp.SoHoaDonVAT)
			, MaSoThu = (vp.SoHoaDon)
			, MaBN = dmbn.SoVaoVien
			, TenBenhNhan = dmbn.TenBenhNhan
			, KhoaPhong = (SELECT TOP 1 pb.TenPhongBan FROM KhamBenh kb 
								JOIN DM_PHONGBAN pb on kb.PhongBan_Id=pb.PhongBan_Id
						WHERE kb.TiepNhan_Id = vp.TiepNhan_Id ORDER BY kb.KhamBenh_Id Desc)
			, TenDichvu = N'Viện phí ngoại Trú'
			, DichVu  = 0
			, VienPhi = 0
			, BaoHiem = 0
			, Huy=0
			, Tong = 0
			, TamUng = 0
			, HoanUng = 0
			, 1 Loai_Id
			, str1 = nv.TenNhanVien
			, SoSerieVAT soquyen
			, soluot=1
	From	 HoaDon vp 
		LEFT JOIN HoaDonChiTiet vpct ON vp.HoaDon_Id=vpct.HoaDon_Id
		LEFT JOIN vw_NhanVien nv ON vp.NguoiThuTien_Id=nv.NhanVien_Id
		left  JOIN DM_BENHNHAN dmbn on dmbn.BenhNhan_Id = vp.BenhNhan_Id
		left  join dm_phongban pb on vp.NoiPhatSinh_Id=pb.PhongBan_Id
		WHERE  vp.DaThanhToan=1 and( vp.HoanTra=0 AND vp.HuyHoaDon=0)
		AND vp.ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
		and( NoiPhatSinh_Id in (46) or CapTren_Id =46 )
		and LoaiHoaDon <> 'H'
		and NoiPhatSinh_Id <> 565
		group by SoHoaDonVAT,SoHoaDon,SoVaoVien,TenBenhNhan,TenNhanVien,SoSerieVAT,TiepNhan_Id

	) aa
 
	GROUP BY SoHoaDon
		, MaSoThu
		, MaBN
		, TenBenhNhan
		, KhoaPhong
		, TenDichVu
		, TamUng
		, HoanUng, aa.soquyen
		, Loai_Id
		, str1
	) aa on kp.TenPhongBan = aa.KhoaPhong
	where aa.VienPhi <> 0
	GROUP BY kp.TenPhongBan
)

-- Truy vấn chính
SELECT 
    KhoaPhong = kp.TenPhongBan,
    LuotKham = cc.LuotKham,
    NhapVien = ISNULL(bb.NhapVien, 0),
    tbhsbhyt = (dd.Tong + ee.t_TongChi) / NULLIF(ee.LuotKham, 0),
    tbhsvp = xx.tbhsvp
FROM KhoaPhongOrder kp
LEFT JOIN xx ON kp.TenPhongBan = xx.KhoaPhong
LEFT JOIN bb ON kp.TenPhongBan = bb.PhongBan
LEFT JOIN cc ON kp.TenPhongBan = cc.TenPhongBan
LEFT JOIN dd ON kp.TenPhongBan = dd.TenPhongBan
LEFT JOIN ee ON kp.TenPhongBan = ee.TenPhongBan
ORDER BY kp.STT



OPTION (FORCE ORDER);