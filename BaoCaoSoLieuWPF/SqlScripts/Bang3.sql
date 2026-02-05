SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRAN;

DECLARE 
@TuNgay 	DateTime = '@TuNgayParams',
@DenNgay 	DateTime = '@DenNgayParams'



select
	y.TenPhongBan,
	LuotPT = isnull(LuotPT,0),
	LuotPTYC = isnull(LuotPTYC,0)
from
	(
	select 
		pb.TenPhongBan,
		LuotPT = sum(SoLuong)
	from 
		(
		select 
				PhongBanChiDinh_id =
					case 
						when cc.KhoaCD = 901 then 105
						else cc.KhoaCD
					end,
				cc.SoLuong
		from 	(
			select
				 SoBenhAn = bn.sovaovien
				, PPPT = dv.DichVu_Id
				, KhoaCD=pbcd.PhongBan_Id
				, clsct.SoLuong
				, pb1.PhongBan_Id
				, nhom.NhomDichVu_Id
			from CLSYeuCau CLS (nolock)
				left join CLSYeuCauChiTiet clsct (nolock) on clsct.CLSYeuCau_Id=cls.CLSYeuCau_Id
				left join BenhAnPhauThuat PT (nolock) on PT.CLSYeuCau_Id = CLS.CLSYeuCau_Id
				join DM_BenhNhan bn (nolock) on (CLS.BenhNhan_Id = bn.BenhNhan_Id)
				left join BenhAnPhauThuat_YeuCau yc (nolock) on yc.BenhAnPhauThuat_Id=pt.BenhAnPhauThuat_Id
				left join DM_PhanLoaiPhauThuat lpt (nolock) on lpt.DichVu_Id = yc.DichVu_Id
				left join DM_LoaiPhauThuat Laynhom (nolock) on Laynhom.LoaiPhauThuat = lpt.LoaiPhauThuat
				left join DM_DichVu dv (nolock) on yc.DichVu_Id=dv.DichVu_Id
				left join DM_NhomDichVu nhom (nolock) on yc.NhomDichVu_Id = nhom.NhomDichVu_Id
				left join DM_PhongBan pbcd (nolock) on pbcd.PhongBan_Id=cls.NoiYeuCau_Id
				left join DM_PhongBan pb1 (nolock) on pb1.PhongBan_Id=pt.PhongBanThucHien_Id
			where	
				cls.ThoiGianYeuCau between @TuNgay and @DenNgay
	 			and (Laynhom.LoaiTuongTrinh = 'PT') 
				and LoaiDichVu_Id in (3,8)
 
			union all
 
  
			select	
				SoBenhAn =  bn.sovaovien
				, PPPT = dv.DichVu_Id
				, KhoaCD=pbcd.PhongBan_Id
				, ct.SoLuong
				, tenphongban = pb1.PhongBan_Id
				, nhom.NhomDichVu_Id
			from	clsyeucau yc
				left join clsyeucauchitiet ct (nolock) on yc.CLSYeuCau_Id=ct.clsyeucau_id
				left join CLSKetQua kq (nolock) on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
				left join dm_dichvu dv (nolock) on ct.dichvu_id=dv.dichvu_id
				left join dm_nhomdichvu nhom (nolock) on dv.NhomDichVu_Id=nhom.nhomdichvu_id
				left join DM_PhongBan pbcd (nolock) on pbcd.PhongBan_Id=yc.NoiYeuCau_Id
				left join DM_PhongBan pb1 (nolock) on pb1.PhongBan_Id=kq.NoiThucHien_Id
				left  join DM_PhanLoaiPhauThuat lpt (nolock) on lpt.DichVu_Id = dv.DichVu_Id
				join DM_BenhNhan bn (nolock) on (yc.BenhNhan_Id = bn.BenhNhan_Id)
				left join DM_LoaiPhauThuat Laynhom (nolock) on Laynhom.LoaiPhauThuat = lpt.LoaiPhauThuat
	

			where 	yc.ThoiGianYeuCau between @TuNgay and @DenNgay
				and (Laynhom.LoaiTuongTrinh = 'PT') 
				and LoaiDichVu_Id not in  (3,8)		
			) cc
		)x
		left join DM_PhongBan pb (nolock) on x.PhongBanChiDinh_id = pb.PhongBan_Id
		group by pb.TenPhongBan
	)y
	left join (
		select 
			pb.TenPhongBan,
			LuotPTYC = sum(SoLuong)
		from 
			(
			select NoiYeuCau_id =
						case 
							when yc.NoiYeuCau_Id = 901 then 105
							else yc.NoiYeuCau_Id
						end,
					ycct.SoLuong
			from CLSYeuCauChiTiet ycct 
				left join CLSYeuCau yc (nolock) on ycct.CLSYeuCau_Id = yc.CLSYeuCau_Id 
				left join DM_DichVu dv (nolock) on dv.DichVu_Id = ycct.DichVu_Id
				left join DM_NhomDichVu ndv (nolock) on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
			where yc.NgayYeuCau between @TuNgay and @DenNgay
				and ycct.Huy = 0
				and dv.NhomDichVu_Id in (53677)
				and ycct.DichVu_Id in (25132,26574,30239,30240,30241,30242,23649,23650,23651,24202,24211,24212,24213,24214,30154,30155,30156,24184,24185,24186,24187,25132,25133,33670)			
			)x
			left join DM_PhongBan pb (nolock) on x.NoiYeuCau_Id = pb.PhongBan_Id
		group by pb.TenPhongBan
	)z on z.TenPhongBan = y.TenPhongBan
order by y.TenPhongBan


OPTION (FORCE ORDER);