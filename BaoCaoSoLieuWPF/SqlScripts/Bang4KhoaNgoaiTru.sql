SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRAN;

DECLARE 
@TuNgay 	DateTime = '@TuNgayParams',
@DenNgay 	DateTime = '@DenNgayParams'


select bb.KhoaPhong, tb = (bb.tong + cc.t_TongChi)/cc.luotkham
from (
SELECT   KhoaPhong
	, Tong= SUM(DichVu)+sum(DichVu1)+SUM(VienPhi)+sum(VienPhi1)
FROM	
(VALUES 
	(N'Khoa Nhi (Ngoại trú)'),
	(N'Khoa Nội Thận - Tiết niệu - Hô hấp (Ngoại trú)'),
	(N'Khoa Phục hồi chức năng'),
	(N'Khoa Y học cổ truyền (Ngoại trú)')
) AS d(khoa) 
left join 
(
	 SELECT 
	 KhoaPhong =isnull( (SELECT TOP 1 pb.TenPhongBan FROM KhamBenh kb 
							JOIN DM_PHONGBAN pb on kb.PhongBan_Id=pb.PhongBan_Id
					WHERE kb.TiepNhan_Id = vp.TiepNhan_Id ORDER BY kb.KhamBenh_Id Desc),pb1.TenPhongBan)

	  , DichVu1  = Sum(case when vpct.LoaiGia_Id in( 35 ,36)then vpct.giatrithucthu else 0 end)
	  , DichVu=0
	 ,  VienPhi1 = Sum((case when vpct.LoaiGia_Id = 4 or (vpct.LoaiGia_Id not in( 35 ,36) and vpct.DonGiaHoTroChiTra=0) then vpct.GiaTriThucThu else 0 end)
					)
	 ,  Vienphi=0
	From	 HoaDon vp (nolock)
	 LEFT JOIN HoaDonChiTiet vpct (nolock)ON vp.HoaDon_Id=vpct.HoaDon_Id
	 left join CLSYeuCauChiTiet ct (nolock)on  vpct.YeuCauChiTiet_Id=ct.YeuCauChiTiet_Id and vpct.Loai_IDRef='A'
	 JOIN DM_BENHNHAN dmbn(nolock) on dmbn.BenhNhan_Id = vp.BenhNhan_Id
	 LEFT JOIN DM_DoiTuong dt(nolock) ON vp.DoiTuong_Id=dt.DoiTuong_Id
	 LEFT JOIN vw_NhanVien nv(nolock) ON vp.NguoiThuTien_Id=nv.NhanVien_Id
	left  join dm_phongban pb(nolock) on vp.NoiPhatSinh_Id=pb.PhongBan_Id
	left join TiepNhan tn(nolock) on vp.TiepNhan_Id=tn.TiepNhan_Id
	left join DM_PhongBan pb1 (nolock)on tn.NoiTiepNhan_Id=pb1.PhongBan_Id
	left join DM_PhongBan pb2 (nolock) on vp.NoiPhatSinh_Id=pb2.PhongBan_Id
	LEFT JOIN ThanhToan_Online (nolock)  QR ON QR.ID_Ref = VP.ID_SAVE AND QR.Type_Ref IN ('TU_NG','BK_CP')
	 WHERE  vp.DaThanhToan=1 and vp.HuyHoaDon=0-- and vp.HoanTra = 0
			AND vp.ThoiGianHoaDon BETWEEN @TuNgay AND @DenNgay
			and (vp.LoaiHoaDon = 'T')
			and (( QR.ThanhToan_Id IS NULL AND  ( NoiPhatSinh_Id in (1,3,2,46,563, 564, 566) or   pb2.CapTren_Id=1) )
						OR 
					(QR.ThanhToan_Id IS NOT NULL))
	 GROUP BY vp.SoHoaDonVAT
		 ,vp.SoHoaDon
		 , VP.ID_SAVE, SoSerieVAT
		 ,dmbn.SoVaoVien
		 ,dmbn.TenBenhNhan
		 ,vp.TiepNhan_Id
		 ,vp.LoaiHoaDon
		 ,dt.NhomDoiTuong_Id, pb1.TenPhongBan
		 ,dt.TyLe_2
		 ,nv.TenNhanVien, NgayHoaDon

	union all
	SELECT KhoaPhong = isnull( (SELECT TOP 1 pb.TenPhongBan FROM KhamBenh kb 
							JOIN DM_PHONGBAN pb on kb.PhongBan_Id=pb.PhongBan_Id
					WHERE kb.TiepNhan_Id = vp.TiepNhan_Id ORDER BY kb.KhamBenh_Id Desc),pb1.TenPhongBan)
	  , DichVu1  = -Sum(case when vpct.LoaiGia_Id in( 35 ,36)then vpct.giatrithucthu else 0 end)
	  , DichVu=0
	 ,  VienPhi1 = -Sum((case when vpct.LoaiGia_Id = 4 or (vpct.LoaiGia_Id not in( 35 ,36) and vpct.DonGiaHoTroChiTra=0) then vpct.GiaTriThucThu else 0 end)
					)
	 ,  Vienphi=0
	From	 HoaDon vp (nolock)
		 LEFT JOIN HoaDonChiTiet vpct (nolock)ON vp.HoaDon_Id=vpct.HoaDon_Id
		 JOIN DM_BENHNHAN dmbn (nolock)on dmbn.BenhNhan_Id = vp.BenhNhan_Id
		 LEFT JOIN DM_DoiTuong dt (nolock)ON vp.DoiTuong_Id=dt.DoiTuong_Id
		 LEFT JOIN vw_NhanVien nv (nolock)ON vp.NguoiTra_Id=nv.NhanVien_Id
		left  join dm_phongban pb (nolock)on vp.NoiPhatSinh_Id=pb.PhongBan_Id
		left join TiepNhan tn (nolock)on vp.TiepNhan_Id=tn.TiepNhan_Id
		left join DM_PhongBan pb1 (nolock)on tn.NoiTiepNhan_Id=pb1.PhongBan_Id
		left join DM_PhongBan pb2 (nolock)on vp.NoiPhatSinh_Id=pb2.PhongBan_Id
		LEFT JOIN ThanhToan_Online (nolock)  QR ON QR.ID_Ref = VP.ID_SAVE AND QR.Type_Ref IN ('TU_NG','BK_CP')
	 WHERE   vp.DaThanhToan = 1 and vp.HoanTra=1
			AND vp.ThoiGianTra BETWEEN @TuNgay AND @DenNgay
			and (vp.LoaiHoaDon = 'T' )
			and (( QR.ThanhToan_Id IS NULL AND  ( NoiPhatSinh_Id in (1,3,2,46,563, 564, 566) or   pb2.CapTren_Id=1) )
						OR 
					(QR.ThanhToan_Id IS NOT NULL))
	 GROUP BY vp.SoHoaDonVAT
		 ,vp.SoHoaDon
		 , VP.ID_SAVE, SoSerieVAT
		 ,dmbn.SoVaoVien
		 ,dmbn.TenBenhNhan
		 ,vp.TiepNhan_Id
		 ,vp.LoaiHoaDon
		 ,dt.NhomDoiTuong_Id,pb1.TenPhongBan
		 ,dt.TyLe_2
		 ,nv.TenNhanVien, NgayTra


	
	UNION ALL
	 SELECT
		 TenPhongBan = (SELECT TOP 1 pb.TenPhongBan FROM NoiTru_LuuTru lt 
								JOIN DM_PHONGBAN pb on lt.PhongBan_Id=pb.PhongBan_Id
						  WHERE lt.BenhAn_Id = vp.BenhAn_Id ORDER BY lt.LuuTru_Id Desc)
		 , DichVu1  = 0
		 , DichVu  = Sum(case when isnull(ycct.LoaiGia_Id,1) = 35 then vpct.GiaTriHoaDon else 0 end)
		 , Vienphi1=0
		 , VienPhi = Sum(case when isnull(LoaiGia_Id,1) <> 35 and (isnull(vpct.DonGiaHoTroChiTra,0) =0 ) then vpct.GiaTriHoaDon else 0 end)
	 FROM VienPhiNoiTru vp (nolock)
		 LEFT JOIN VienPhiNoiTruChiTiet vpct(nolock) ON vp.VienPhiNoiTru_Id=vpct.VienPhiNoiTru_Id
		 left join CLSYeuCAuChiTiet ycct(nolock) on vpct.Loai_IDRef = 'A' and vpct.IDRef = ycct.YeuCauChiTiet_Id
		 JOIN BenhAn ba (nolock)on ba.BenhAn_Id = vp.BenhAn_Id
		 JOIN DM_BENHNHAN dmbn (nolock)on dmbn.BenhNhan_Id = ba.BenhNhan_Id
		 LEFT JOIN DM_DoiTuong dt (nolock)ON vp.DoiTuong_Id=dt.DoiTuong_Id
		 LEFT JOIN vw_NhanVien nv (nolock)ON vp.PhatSinh_Nguoi_Id=nv.NhanVien_Id
		left  join dm_phongban pb (nolock)on vp.PhatSinh_Noi_Id=pb.PhongBan_Id
		LEFT JOIN ThanhToan_Online (nolock)  QR ON QR.ID_Ref = ISNULL(VP.ID_SAVE,VP.ID_Save_NgTru) AND QR.Type_Ref IN ('TU_NG','TU_NT','BK_CP_NT')
	 WHERE vp.DaThanhToan = 1  AND vp.HuyHoaDon=0
			AND vp.ThuTien_ThoiGian BETWEEN @TuNgay AND @DenNgay
			and (vp.LoaiChungTu = 'BL'  )		
			and (( QR.ThanhToan_Id IS NULL AND isnull(PhatSinh_Noi_Id,46)<>565 )
						OR 
					(QR.ThanhToan_Id IS NOT NULL))
	GROUP BY 
		  vp.ID_SAVE, SoHoaDonVAT, SoChungTu
		 ,dmbn.SoVaoVien, SoSerieVAT
		 ,dmbn.TenBenhNhan
		 ,vp.BenhAn_Id
		 ,vp.LoaiChungTu
		 ,dt.NhomDoiTuong_Id
		 ,nv.TenNhanVien, BA.TiepNhan_Id, ThuTien_Ngay


	union all
	SELECT TenPhongBan = (SELECT TOP 1 pb.TenPhongBan FROM NoiTru_LuuTru lt 
								JOIN DM_PHONGBAN pb on lt.PhongBan_Id=pb.PhongBan_Id
						  WHERE lt.BenhAn_Id = vp.BenhAn_Id ORDER BY lt.LuuTru_Id Desc)
		 , DichVu1  = 0
		 , DichVu  = -Sum(case when ycct.LoaiGia_Id = 35 then vpct.GiaTriHoaDon else 0 end)
		 , Vienphi1=0
		 , VienPhi = -Sum(case when isnull(LoaiGia_Id,1) <> 35 and (vpct.DonGiaHoTroChiTra =0  or vpct.DonGiaHoTroChiTra is null ) then vpct.GiaTriHoaDon else 0 end)
	 FROM VienPhiNoiTru vp (nolock)
		 LEFT JOIN VienPhiNoiTruChiTiet vpct(nolock) ON vp.VienPhiNoiTru_Id=vpct.VienPhiNoiTru_Id
		 left join CLSYeuCAuChiTiet ycct (nolock)on vpct.Loai_IDRef = 'A' and vpct.IDRef = ycct.YeuCauChiTiet_Id
		 JOIN BenhAn ba(nolock) on ba.BenhAn_Id = vp.BenhAn_Id
		 JOIN DM_BENHNHAN dmbn (nolock)on dmbn.BenhNhan_Id = ba.BenhNhan_Id
		 LEFT JOIN DM_DoiTuong dt (nolock)ON vp.DoiTuong_Id=dt.DoiTuong_Id
		 LEFT JOIN vw_NhanVien nv (nolock)ON vp.Tra_Nguoi_Id=nv.NhanVien_Id
	 left  join dm_phongban pb (nolock)on vp.PhatSinh_Noi_Id=pb.PhongBan_Id
	 LEFT JOIN ThanhToan_Online (nolock)  QR ON QR.ID_Ref = ISNULL(VP.ID_SAVE,VP.ID_Save_NgTru) AND QR.Type_Ref IN ('TU_NG','TU_NT','BK_CP_NT')
	 WHERE vp.DaThanhToan = 1  AND vp.HoanTra=1 
			AND vp.Tra_ThoiGian BETWEEN @TuNgay AND @DenNgay
			and (vp.LoaiChungTu = 'BL' )		
			and (( QR.ThanhToan_Id IS NULL AND isnull(PhatSinh_Noi_Id,46)<>565 )
						OR 
					(QR.ThanhToan_Id IS NOT NULL))
	GROUP BY 
		  vp.ID_SAVE, SoHoaDonVAT, SoChungTu
		 ,dmbn.SoVaoVien, SoSerieVAT
		 ,dmbn.TenBenhNhan
		 ,vp.BenhAn_Id
		 ,vp.LoaiChungTu
		 ,dt.NhomDoiTuong_Id, BA.TiepNhan_Id
		 ,nv.TenNhanVien, Tra_Ngay

	) aa on aa.KhoaPhong = d.khoa
GROUP BY KhoaPhong
)bb
left join (	
	Select 
		d.khoa,
		ISNULL(SUM(AA.t_TongChi), 0) AS t_TongChi,
		ISNULL(COUNT(*), 0) AS luotkham

	from 
	    (VALUES 
			(N'Khoa Nhi (Ngoại trú)'),
			(N'Khoa Nội Thận - Tiết niệu - Hô hấp (Ngoại trú)'),
			(N'Khoa Phục hồi chức năng'),
			(N'Khoa Y học cổ truyền (Ngoại trú)')
		) AS d(khoa)
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
	) AA on d.khoa = aa.khoa
	group by d.khoa
)cc on bb.KhoaPhong = cc.khoa
order by KhoaPhong


OPTION (FORCE ORDER);
