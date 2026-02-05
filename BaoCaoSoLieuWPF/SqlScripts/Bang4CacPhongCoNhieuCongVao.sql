SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRAN;

DECLARE 
@TuNgay 	DateTime = '@TuNgayParams',
@DenNgay 	DateTime = '@DenNgayParams'


SELECT
	TenPhongBan = pb.TenPhongBan, 
	LuotKham = COUNT(*),
	NhapVien = 
	CASE 
		WHEN lt.PhongBan_Id in (64,105) THEN COUNT(*)
		ELSE SUM(CASE WHEN lt.LyDoRa_Code = 'CK' THEN 1 ELSE 0 END)
	END
FROM NoiTru_LuuTru lt
LEFT JOIN DM_PhongBan pb on lt.PhongBan_Id = pb.PhongBan_Id
WHERE  lt.PhongBan_Id IN (40, 621, 64, 105)
AND LyDoVao_Code='NM' AND lt.thoigianvao  BETWEEN @TuNgay AND @DenNgay
group by pb.TenPhongBan, lt.PhongBan_Id


OPTION (FORCE ORDER);



