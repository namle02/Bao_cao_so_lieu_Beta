SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;



DECLARE 
@TuNgay 	DateTime = '@TuNgayParams',
@DenNgay 	DateTime = '@DenNgayParams'


IF OBJECT_ID('tempdb..#KhoaNoiTru') IS NOT NULL DROP TABLE #KhoaNoiTru
;with BenhAnRaVien as (
    Select
      Ct.*,
      vp.BenhAn_Id,
      vp.PhatSinh_Noi_Id
    From
      VienPhiNoiTru vp (nolock)
      join VienPhiNoiTruChiTiet ct (nolock) on vp.VienPhiNoiTru_Id = ct.VienPhiNoiTru_Id
      left join CLSYeuCauChiTiet y (nolock) on ct.CLSYeuCauChiTiet_Id = y.YeuCauChiTiet_Id and ct.Loai_IDRef = 'A'
    Where
      (
        vp.ThuTien_Ngay between @tungay
        and @denngay
      )
      and Loai_IDRef = 'A'
      and isnull(PhatSinh_Noi_Id, 46) <> 565
      and vp.DaThanhToan = 1
      AND vp.HoanTra = 0
      AND vp.HuyHoaDon = 0
      and (
        vp.LoaiChungTu <> 'BL'
        or ct.GiaTriHoaDon <> 0
        or ct.GiaTriHoaDon = 0
      )
      and (
        y.LoaiGia_Id = 35
        or (
          isnull(y.LoaiGia_Id, 1) <> 35
          and (
            ct.DonGiaHoTroChiTra = 0
            or ct.DonGiaHoTroChiTra is null
          )
        )
      )
  ),
  ChungTuXBN as (
    Select
      ct.*,
      vp.BenhAn_Id,
      vp.PhatSinh_Noi_Id
    from
      VienPhiNoiTru vp (nolock)
      join VienPhiNoiTruChiTiet ct (nolock) on vp.VienPhiNoiTru_Id = ct.VienPhiNoiTru_Id
    Where
      (
        vp.ThuTien_Ngay between @TuNgay
        and @DenNgay
      )
      and Loai_IDRef = 'I'
      and isnull(PhatSinh_Noi_Id, 46) <> 565
      and vp.DaThanhToan = 1
      AND (
        vp.HoanTra = 0
        AND vp.HuyHoaDon = 0
      )
      and (
        vp.LoaiChungTu <> 'BL'
        or ct.GiaTriHoaDon <> 0
        or ct.GiaTriHoaDon = 0
      )
      and (
        ct.DonGiaHoTroChiTra = 0
        or ct.DonGiaHoTroChiTra is null
      )
  ),
  HoaDonThanhToan as (
    Select
      ct.HoaDon_Id,
      HoaDonChiTiet_ID,
      IDRef,
      Loai_IDRef,
      NoiDung_Id,
      LoaiNoiDung,
      ct.GiaTriThucThu,
      DonGiaChenhLech,
      DonGiaHoTroChenhLech,
      GiaTriThatThu,
      GiaTriMienGiam_ChenhLech,
      GiaTriMienGiam_HoTroChenhLech,
      GiaTriMienGiam_CoPhan,
      ct.SoLuong,
      ct.DonGiaDoanhThu,
      ct.DonGiaThanhToan,
      ct.DonGiaHoTro,
      ct.DonGiaHoTroChiTra,
      NoiPhatSinh_Id
    From
      HoaDonChiTiet ct (nolock)
      join HoaDon hd (nolock) on hd.HoaDon_ID = ct.HoaDon_ID
    Where
      hd.NgayHoaDon between @TuNgay
      and @DenNgay
      and(
        NoiPhatSinh_Id not in (1, 3, 2, 46, 563, 565)
        and NoiPhatSinh_Id is not null
      )
      and hd.DaThanhToan = 1
      and(
        hd.HoanTra = 0
        AND hd.HuyHoaDon = 0
      )
      and (
        ct.DonGiaHoTroChiTra = 0
        or ct.DonGiaHoTroChiTra is null
      )
  )




--lv1
select * into #KhoaNoiTru
from 
	(
	--lv2
	select
	  Ngay_Vao,
	  Ngay_Ra,
	  TenPhongBan1,
	  TongCong = sum(TongCong),
	  SoBHYT
	from
	  (
	  --mẫu 80
	  --lv3
		Select
		  bn.SoVaoVien,
		  Ngay_Vao = ba.NgayVaoVien,
		  Ngay_Ra = ba.NgayRaVien,
		  TenPhongBan1 = (TenPhongBan),
		  TongCong = Sum(chiphi.GiaTriHoaDon),
		  tn.SoBHYT
		from
		  (
		  --lv4
			Select
			  Loai_IDRef = 'A',
			  NoiDung_Id = dv.DichVu_Id,
			  b.BenhAn_ID,
			  GiaTriHoaDon,
			  PhatSinh_Noi_Id
			from
			  BenhAnRaVien b (nolock)
			  left join CLSYeuCauChiTiet a (nolock) on a.YeuCauChiTiet_Id = b.IDRef
			  left join DM_DichVu dv (nolock) on a.DichVu_Id = dv.DichVu_Id
			  left join CLSYeuCau y (nolock) on a.CLSYeuCau_Id = y.CLSYeuCau_Id
			  left JOIN DM_NhomDichVu ndv (nolock) ON dv.NhomDichVu_Id = ndv.NhomDichVu_Id

			--end lv4
			union All
			  -- Tiền thuốc trong Y LỆNH --------------------------------------
			--lv4
			select
			  Loai_IDRef = 'I',
			  NoiDung_Id = x.duoc_ID,
			  a.BenhAn_ID,
			  GiaTriHoaDon,
			  PhatSinh_Noi_Id
			from
			  ChungTuXBN a (nolock)
			  left join ChungTuXuatBenhNhan x (nolock) on a.idref = x.ChungTuXuatBN_Id
			  left join DM_Duoc D (nolock) on D.Duoc_Id = x.Duoc_Id
			  left join DM_LoaiDuoc ld (nolock) on ld.LoaiDuoc_Id = D.LoaiDuoc_Id
		  ) ChiPhi

		  --end lv4

		  left join BenhAn (nolock) ba on ba.BenhAn_Id = ChiPhi.BenhAn_Id and Ba.TrangThai in ('DaXuatVien', 'DaThanhToan')
		  left join DM_BenhNhan bn (nolock) on bn.BenhNhan_Id = ba.BenhNhan_Id
		  left join DM_PhongBan (nolock) pb on pb.PhongBan_Id = ba.KhoaRa_Id
		  left join TiepNhan tn  on ba.TiepNhan_Id=tn.tiepnhan_id
		group by
		  bn.SoVaoVien,
		  ba.NgayVaoVien,
		  ba.NgayRaVien,
		  pb.TenPhongBan,
		  tn.SoBHYT
		-- end lv3
		union all

		--lv3
		Select
		  bn.SoVaoVien,
		  Ngay_Vao = NgayTiepNhan,
		  Ngay_Ra = NgayTiepNhan,
		  TenPhongBan1 = pb.TenPhongBan,
		  TongCong = Sum(chiphi.GiaTriHoaDon),
		  tn.SoBHYT
		from
		  (
			--lv4
			SELECT
			  Loai_IDRef = HD.Loai_IDRef,
			  NoiDung_Id = HD.NoiDung_Id,
			  NoiYeuCau_Id = case when ndv.NhomDichVu_Id = 27 then isnull(CLS_YC.noithuchien_id, CLS_YC.noiyeucau_id) else CLS_YC.NoiYeuCau_ID end,
			  GiaTriHoaDon = HD.GiaTriThucThu,
			  CLS_YC.TiepNhan_ID,
			  NoiPhatSinh_Id
			From
			  HoaDonThanhToan hd (nolock)
			  join CLSYeuCauChiTiet CLS_CT (nolock) on HD.IDRef = CLS_CT.YeuCauChiTiet_Id
			  and hd.Loai_IDRef = 'A'
			  join CLSYEUCAU CLS_YC (nolock) on CLS_CT.CLSYeuCau_Id = CLS_YC.CLSYeuCau_Id
			  join DM_DichVu DV (nolock) on CLS_CT.DichVu_Id = dv.DichVu_Id
			  join DM_NhomDichVu ndv (nolock) on ndv.NhomDichVu_ID = dv.NhomDichVu_ID
			  left join DM_PhanLoaiPhauThuat p (nolock) on dv.dichvu_id = p.dichvu_id
			  left join DM_LoaiPhauThuat l on p.LoaiPhauThuat = l.LoaiPhauThuat
			  -- end lv 4
			union All
			--lv4
			SELECT
			  Loai_IDRef = HD.Loai_IDRef,
			  NoiDung_Id = HD.NoiDung_Id,
			  NoiYeuCau_Id = KB.PhongBan_Id,
			  GiaTriHoaDon = HD.GiaTriThucThu,
			  tt.TiepNhan_ID,
			  NoiPhatSinh_Id
			From
			  HoaDonThanhToan hd (nolock) 
			  join ChungTuXuatBenhNhan TT (nolock) on HD.IDRef = TT.ChungTuXuatBN_ID
			  and hd.Loai_IDRef = 'I'
			  join ToaThuoc A (nolock) on TT.ToaThuocNgoaiTru_Id = A.ToaThuoc_Id
			  join DM_Duoc D (nolock) on HD.NoiDung_Id = D.Duoc_Id
			  join KhamBenh_ToaThuoc KB_TT (nolock) on KB_TT.KhamBenh_ToaThuoc_ID = A.KhamBenh_ToaThuoc_ID
			  join KhamBenh KB (nolock) on KB_TT.KhamBenh_Id = KB.KhamBenh_Id
			--end lv4
			union All

			--lv4
			SELECT
			  Loai_IDRef = HD.Loai_IDRef,
			  NoiDung_Id = HD.NoiDung_Id,
			  NoiYeuCau_Id = KB.PhongBan_Id,
			  GiaTriHoaDon = HD.GiaTriThucThu,
			  tt.TiepNhan_ID,
			  NoiPhatSinh_Id
			From
			  HoaDonThanhToan hd (nolock) 
			  join ChungTuXuatBenhNhan TT (nolock) on HD.IDRef = TT.ChungTuXuatBN_ID
			  and hd.Loai_IDRef = 'I'
			  join KhamBenh_VTYT KB_TT (nolock) on tt.IDRef = KB_TT.KhamBenh_VTYT_Id
			  join DM_Duoc D (nolock) on HD.NoiDung_Id = D.Duoc_Id
			  join KhamBenh KB (nolock) on KB_TT.KhamBenh_Id = KB.KhamBenh_Id

			  -- end lv4
			union All
				--lv4
			SELECT
			  Loai_IDRef = HD.Loai_IDRef,
			  NoiDung_Id = HD.NoiDung_Id,
			  NoiYeuCau_Id = BAPT.PhongBanChiDinh_id,
			  GiaTriHoaDon = HD.GiaTriThucThu,
			  bapt.TiepNhan_ID,
			  NoiPhatSinh_Id
			From
			  HoaDonThanhToan hd (nolock) 
			  join ChungTuXuatBenhNhan x (nolock) on hd.IDRef = x.ChungTuXuatBN_Id
			  join BenhAnPhauThuat_VTYT VTYT (nolock) on x.BenhAnPhauThuat_VTYT_ID = VTYT.BenhAnPhauThuat_VTYT_ID
			  and hd.Loai_IDRef = 'C'
			  join DM_Duoc D (nolock) on VTYT.Duoc_Id = D.Duoc_Id
			  join BenhAnPhauThuat BAPT (nolock) on BAPT.BenhAnPhauThuat_ID = VTYT.BenhAnPhauThuat_ID

			  --end lv4
		  ) chiphi
		  join TiepNhan tn (nolock) on tn.TiepNhan_Id = chiphi.TiepNhan_Id
		  join DM_BenhNhan bn (nolock) on bn.BenhNhan_Id = tn.BenhNhan_Id
		  join DM_DoiTuong dt (nolock) on dt.DoiTuong_Id = tn.DoiTuong_Id
		  left join DM_PhongBan pb (nolock) on chiphi.NoiYeuCau_Id = pb.PhongBan_Id
		group by
		  bn.SoVaoVien,
		  tn.NgayTiepNhan,
		  pb.TenPhongBan,
		  tn.SoBHYT

		--end lv3
		union All

		--lv3
		Select
		  bn.SoVaoVien,
		  Ngay_Vao = chiphi.NgayVaoVien,
		  Ngay_Ra = chiphi.NgayRaVien,
		  TenPhongBan1 = pb.TenPhongBan,
		  TongCong = Sum(chiphi.DonGiaDoanhThu * chiphi.SoLuong),
		  tn.SoBHYT
		from
		  (
			--lv4
			select
			  XN.Loai,
			  XN.TiepNhan_Id,
			  XN.BenhNhan_Id,
			  TN.SoBHYT,
			  XNCT.Loai_IDRef,
			  XNCT.NoiDung_ID,
			  Soluong = CASE WHEN clsyc.PT50 = 1 THEN CAST(XNCT.SoLuong as Decimal(18, 2)) * 0.5 WHEN clsyc.PT80 = 1 THEN CAST(XNCT.SoLuong as Decimal(18, 2)) * 0.8 ELSE CAST(XNCT.SoLuong as Decimal(18, 3)) END,
			  XNCT.DonGiaDoanhThu,
			  ba.KhoaRa_Id,
			  NgayRaVien,
			  NgayVaoVien,
			  NoiXacNhan_ID,
			  ba.BenhAn_Id
			from
			  XacNhanChiPhi xn (nolock)
			  left join XacNhanChiPhiChiTiet XNCT (nolock) on XNCT.XacNhanChiPhi_Id = XN.XacNhanChiPhi_Id
			  left join TiepNhan TN (nolock) on TN.TiepNhan_Id = XN.TiepNhan_Id
			  LEFT JOIN benhan (nolock) ba on ba.BenhAn_Id = xn.BenhAn_Id
			  left join Lst_Dictionary (nolock) lba on ba.LoaiBenhAn_Id = lba.Dictionary_Id
			  left join CLSYeuCauChiTiet clsyc (nolock) on xnct.IDRef = clsyc.YeuCauChiTiet_Id
			  and XNCT.Loai_IDRef = 'A'
			  left join CLSYeuCau yc (nolock) on clsyc.CLSYeuCau_Id = yc.CLSYeuCau_Id
			Where
			  xn.NgayXacNhan between @TuNgay and @DenNgay
			  and xn.Loai = 'NoiTru'
			  and isnull(lba.Dictionary_Name_Ru, '') <> '01/BV'
			  and XNCT.DonGiaHoTroChiTra > 0

			--end lv4
		  ) CHIPHI
		  join BenhAn (nolock)  ba on ba.BenhAn_Id = ChiPhi.BenhAn_Id  
		  left join VienPhiNoiTru_Loai_IDRef ref (nolock) on chiphi.Loai_IdRef = ref.Loai_IdRef
		  left join DM_Duoc duoc (NOLOCK) on chiphi.NoiDung_Id = duoc.Duoc_Id
		  and ref.PhanNhom = 'DU'
		  left join DM_LoaiDuoc ld (nolock) on duoc.LoaiDuoc_Id = ld.LoaiDuoc_Id
		  left join DM_BenhNhan bn (nolock) ON ChiPhi.BenhNhan_Id = bn.BenhNhan_Id
		  left join DM_PhongBan pb (nolock) on pb.PhongBan_Id = CHIPHI.KhoaRa_Id
		  left join TiepNhan tn  on ba.TiepNhan_Id=tn.tiepnhan_id
		where
		  isnull(duoc.BHYT, 1) = 1
		group by
		  bn.SoVaoVien,
		  chiphi.NgayVaoVien,
		  pb.TenPhongBan,
		  chiphi.NgayRaVien,
		  tn.SoBHYT

		  --end lv3
	  ) AAA 
	GROUP BY
	  SoVaoVien,
	  Ngay_Vao,
	  Ngay_Ra,
	  TenPhongBan1,
	  SoBHYT
)xx
--end lv2
left join 
(
    select
      D.NoiYeuCau_Id,
      TenPhongBan as phongban,
      sum(SoLuong) NDT
    from
      (
        select
          pb.TenPhongBan,
          dv.TenDichVu,
          ct.SoLuong,
          yc.NoiYeuCau_Id
        from
          CLSYeuCau yc (nolock) 
          left join CLSYeuCauChiTiet ct (nolock) on ct.CLSYeuCau_Id = yc.CLSYeuCau_Id
          left join DM_DichVu dv (nolock) on dv.DichVu_Id = ct.DichVu_Id
          left join DM_NhomDichVu ndv (nolock) on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
          left join DM_PhongBan pb (nolock) on pb.PhongBan_Id = yc.NoiYeuCau_Id
          left join BenhAn ba (nolock) on ba.BenhAn_Id = yc.BenhAn_Id
          left join Lst_Dictionary lba on lba.Dictionary_Id = ba.LoaiBenhAn_Id
        where
          ndv.NhomDichVu_Id in (45, 53622, 53665, 53680)
          and yc.BenhAn_Id is not null 
          and yc.NgayGioYeuCau between @TuNgay and @DenNgay
          and yc.NoiYeuCau_Id not in ( 1, 76, 559, 62, 593, 74, 75, 629, 570, 577, 461, 73)
      ) D
    group by
      tenphongban,
      D.NoiYeuCau_Id 
) zz on xx.TenPhongBan1 = zz.phongban
left join DM_PhongBan pb on pb.TenPhongBan = xx.TenPhongBan1
left join (
	Select  
		khoa
		, LuotBNBHYT = count(*)

	from 
	(
		select 
			MaThe		= Upper(substring(chiphi.SoBHYT,0,16))
			, Ngay_Vao	= ChiPhi.NgayVao
			, Ngay_Ra	= isnull(ChiPhi.NgayRa, ba.NgayRaVien)
			, t_TongChi	= isnull(sum(
						case when chiphi.tt04 = 1 then chiphi.DonGiaDoanhThu * isnull(chiphi.SoLuong,1)
						else 
						chiphi.DonGiaHoTro * isnull(chiphi.SoLuong,1)
						end						
						) ,0)
			, khoa	= isnull(pb.TenPhongBan,chiphi.TenPhongKham)
							
			, Str3	= bn.SoVaoVien
			, Str4 = SoXacNhan
			, ba.BenhAn_Id
			, Str5= ba.SoBenhAn
			 
		from 
		(
			select	XN.SoXacNhan
					, XN.TiepNhan_Id
					, XN.BenhNhan_Id
					, XN.Benhan_Id
					, TN.SoBHYT
					, XN.NgayVao
					, XN.NgayRa
					, XNCT.Loai_IDRef
					, XNCT.NoiDung_ID
					, Soluong=CASE WHEN clsyc.PT50 = 1 THEN CAST(XNCT.SoLuong as Decimal(18, 2))  * 0.5 
					              WHEN clsyc.PT80 = 1 THEN CAST(XNCT.SoLuong as Decimal(18, 2))  * 0.8 
					ELSE
					CAST(XNCT.SoLuong as Decimal(18, 3))  END 

					, XNCT.DonGiaDoanhThu
					, DonGiaHoTro= 
					case when (isnull(x.DuocDieuKien_Id,0) =0 )  then  XNCT.DonGiaHoTro * (case when yc.NhomDichVu_Id <> 27 and (isnull(clsyc.Ghep2,0)=1 or isnull(clsyc.Ghep3,0)=1) then isnull(clsyc.TyLeThanhToan,1) else 1 end)
										else xnct.DonGiaDoanhThu end		
					, xn.TenPhongKham	
					, tt04 = case when tt04.VATTU_TT04_ID is not null then 1 else 0 end
			from	XacNhanChiPhi xn (nolock)
					left join XacNhanChiPhiChiTiet XNCT (nolock) on XNCT.XacNhanChiPhi_Id= XN.XacNhanChiPhi_Id
					left join TiepNhan TN (nolock) on TN.TiepNhan_Id = XN.TiepNhan_Id
					LEFT JOIN benhan (nolock) ba on ba.BenhAn_Id = xn.BenhAn_Id
					left join Lst_Dictionary (nolock) lba on ba.LoaiBenhAn_Id=lba.Dictionary_Id
					left join CLSYeuCauChiTiet clsyc (nolock) on xnct.IDRef= clsyc.YeuCauChiTiet_Id and XNCT.Loai_IDRef='A'
					left join CLSYeuCau yc (nolock) on clsyc.CLSYeuCau_Id=yc.CLSYeuCau_Id
					left join DM_VATTU_TT04 tt04 (nolock) on xnct.NoiDung_Id=tt04.Duoc_ID and xnct.Loai_IDRef='I'
					left join ChungTuXuatBenhNhan x on XNCT.IDRef=x.ChungTuXuatBN_Id and XNCT.Loai_IDRef='I'
			Where xn.ThoiGianXacNhan between @TuNgay and @DenNgay   
				and xn.Loai = 'NoiTru'
				and isnull(lba.Dictionary_Name_Ru,'')<>'01/BV' 
				and XNCT.DonGiaHoTroChiTra > 0
				and xn.SoXacNhan is not null

		) CHIPHI
			left join VienPhiNoiTru_Loai_IDRef ref on chiphi.Loai_IdRef = ref.Loai_IdRef
			left join DM_DichVu dv (nolock) on  dv.DichVu_Id = chiphi.NoiDung_Id And ref.PhanNhom = 'DV'
			left join DM_Duoc  duoc (NOLOCK) on chiphi.NoiDung_Id = duoc.Duoc_Id and ref.PhanNhom = 'DU' 
			left join DM_BenhNhan bn (nolock) ON ChiPhi.BenhNhan_Id = bn.BenhNhan_Id	
			left join BenhAn ba (nolock) on ba.BenhAn_Id = ChiPhi.BenhAn_Id
			left join DM_PhongBan pb (nolock) on pb.PhongBan_Id = ba.KhoaRa_Id

			where  isnull(duoc.BHYT,1)=1	 
	 
			
		group by 
			CHIPHI.TiepNhan_ID 
			, BN.TenBenhNhan
			, BN.GioiTinh
			, BN.NamSinh
			, CHIPHI.SoBHYT
			, BN.SoVaoVien
			, ba.SoBenhAn
			, bn.DiaChi
			, CHIPHI.SoXacNhan
			, CHIPHI.TenPhongKham
			, chiphi.ngayvao
			, chiphi.ngayra
			, ba.NgayRaVien,ngayvaovien,ba.benhan_id
			, pb.TenPhongBan, ChanDoanPhuRaVien
	) AA
	Where	isnull(AA.t_TongChi,0) <> 0 
	Group by AA.khoa
)mau80 on pb.TenPhongBan = mau80.khoa
where pb.phongban_id in (40,51,53,54,55,56,58,59,60,61,63,64,65,67,68,69,70,71,72,99,100,101,102,105,235,621,813);


select * from 
(
	select 
		TenPhongBan = N'Toàn bệnh viện',
		LuotKham = sum(LuotKham),
		NgayDieuTri = sum(NgayDieuTri),
		TBhsba = Sum(Tong)/sum(LuotKham),
		TongCong = Sum(x.Tong)
	from (
		select
			knt.TenPhongBan,
			LuotKham = SUM(CASE WHEN knt.SoBHYT IS NULL THEN 1 ELSE 0 END) +  knt.LuotBNBHYT,
			NgayDieuTri = knt.NDT,
			Tong = sum(knt.TongCong)
		from #KhoaNoiTru knt
		group by knt.TenPhongBan, knt.NDT, knt.PhongBan_Id, knt.LuotBNBHYT
	) x 

	union all

	select
		knt.TenPhongBan,
		LuotKham = 
		case 
			when knt.PhongBan_Id = 40 then (SELECT COUNT(*) FROM BenhAn ba WHERE (ba.KhoaVao_Id = '40' ) AND ba.ThoiGianVaoKhoa between @tungay and @denngay)
			when knt.PhongBan_Id in (51,235) then SUM(CASE WHEN knt.SoBHYT IS NULL THEN 1 ELSE 0 END) +  knt.LuotBNBHYT +
				(
					select
					x=count(lt.LuuTru_Id)
					from NoiTru_LuuTru lt (nolock) 
						left join benhan ba on ba.BenhAn_Id=lt.BenhAn_Id
						left join DM_PhongBan pb on pb.PhongBan_Id=lt.PhongBan_Id
						left join Lst_Dictionary lba on lba.Dictionary_Id=ba.LoaiBenhAn_Id
						left join DM_BenhNhan bn on bn.BenhNhan_Id=ba.BenhNhan_Id
						left join NoiTru_LuuTru lt2 on lt2.LuuTru_Prev = lt.LuuTru_Id
					where 
						lt.PhongBan_Id not in (40,1,76,559, 62, 593, 74, 75, 621, 629)
						and lt.PhongBanChuyenDi_Id not in (40,1,76,559, 62, 593, 74, 75, 621, 629)
						and lt.ThoiGianRa between @TuNgay and @DenNgay
						and (lt2.LyDoChuyenKhoa_Id not in (1963,7014))
						and pb.PhongBan_Id = knt.PhongBan_Id
					group by lt.PhongBan_Id, pb.TenPhongBan
				)
			else SUM(CASE WHEN knt.SoBHYT IS NULL THEN 1 ELSE 0 END) +  knt.LuotBNBHYT
		end,
		NgayDieuTri = knt.NDT,
		TBhsba = sum(knt.TongCong)/(SUM(CASE WHEN knt.SoBHYT IS NULL THEN 1 ELSE 0 END) +  knt.LuotBNBHYT),
		Sum(knt.TongCong)
	from #KhoaNoiTru knt
	group by knt.TenPhongBan, knt.NDT, knt.PhongBan_Id, knt.LuotBNBHYT

	union all
		select
			TenPhongBan = 
			case
				when knt.PhongBan_Id = 40 then N'Khoa cấp cứu(chưa cộng thêm)'
				when knt.PhongBan_Id = 51 then N'Khoa Hồi sức tích cực Nội(chưa cộng thêm)'
				when knt.PhongBan_Id = 235 then N'Khoa Hồi sức tích cực Ngoại(chưa cộng thêm)'
			end,
			LuotKham = SUM(CASE WHEN knt.SoBHYT IS NULL THEN 1 ELSE 0 END) +  knt.LuotBNBHYT,
			NgayDieuTri = knt.NDT,
			TBhsba = sum(knt.TongCong)/(SUM(CASE WHEN knt.SoBHYT IS NULL THEN 1 ELSE 0 END) +  knt.LuotBNBHYT),
			Sum(knt.TongCong)
		from #KhoaNoiTru knt
		where knt.PhongBan_Id in (51,235,40)
		group by knt.TenPhongBan, knt.NDT, knt.PhongBan_Id, knt.LuotBNBHYT
) as T
ORDER BY
  CASE 
	WHEN T.TenPhongBan = N'Toàn bệnh viện' THEN 0
	WHEN T.TenPhongBan = N'Phòng cấp cứu nhi' THEN 1
	WHEN T.TenPhongBan = N'Khoa cấp cứu' THEN 2
	WHEN T.TenPhongBan = N'Khoa cấp cứu(chưa cộng thêm)' THEN 3
	ELSE 4
  END,
  T.TenPhongBan

OPTION (FORCE ORDER);

