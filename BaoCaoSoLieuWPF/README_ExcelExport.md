# Tính năng Xuất Báo cáo Excel

## Mô tả
Tính năng xuất báo cáo Excel cho phép người dùng xuất tất cả dữ liệu từ các bảng báo cáo ra file Excel với định dạng chuyên nghiệp.

## Cách sử dụng

### 1. Chuẩn bị dữ liệu
- Chọn bảng báo cáo cần xem từ dropdown
- Chọn khoảng thời gian (từ ngày - đến ngày)
- Nhấn nút "Lọc dữ liệu" để tải dữ liệu

### 2. Xuất báo cáo
- Sau khi dữ liệu được tải thành công, nút "Xuất báo cáo" sẽ được kích hoạt
- Nhấn nút "Xuất báo cáo" để bắt đầu quá trình xuất Excel
- Chờ thông báo hoàn thành

### 3. Kết quả
- File Excel sẽ được lưu trên Desktop với tên: `BaoCaoSoLieu_YYYYMMDD_YYYYMMDD_HHMMSS.xlsx`
- Mỗi bảng dữ liệu sẽ được xuất vào một sheet riêng biệt
- Định dạng Excel bao gồm:
  - Header với tên cột tiếng Việt
  - Border cho tất cả các ô
  - Định dạng số cho các cột số liệu
  - Auto-fit cột để hiển thị đầy đủ nội dung

## Cấu trúc file Excel

### Sheet 1: Bảng 1 - Kết quả toàn viện
- Dữ liệu từ Bang1VM

### Sheet 2: Bảng 2 - Kết quả thực hiện khoa nội trú
- Dữ liệu từ Bang2VM

### Sheet 3: Bảng 3 - Thực hiện dịch vụ yêu cầu
- Dữ liệu từ Bang3VM

### Sheet 4: Bảng 4.1 - Số liệu phòng khám
- Dữ liệu từ Bang4VM.Bang4List

### Sheet 5: Bảng 4.2 - Khoa ngoại trú
- Dữ liệu từ Bang4VM.Bang4KhoaNgoaiTruList

### Sheet 6: Bảng 4.3 - Các phòng có nhiều công vào
- Dữ liệu từ Bang4VM.Bang4CacPhongCoNhieuCongVaoList

### Sheet 7: Bảng 4.4 - Phòng khám yêu cầu
- Dữ liệu từ Bang4VM.Bang4PhongKhamYeuCauList

## Yêu cầu hệ thống
- .NET 8.0 hoặc cao hơn
- Package EPPlus 7.0.9
- Quyền ghi file trên Desktop

## Xử lý lỗi
- Nếu không có dữ liệu: Nút "Xuất báo cáo" sẽ bị vô hiệu hóa
- Nếu có lỗi trong quá trình xuất: Hiển thị thông báo lỗi chi tiết
- Nếu file đã tồn tại: Tạo file mới với timestamp khác

## Lưu ý kỹ thuật
- Sử dụng EPPlus với license NonCommercial
- Dữ liệu được xuất theo thứ tự các bảng
- Chỉ xuất các bảng có dữ liệu
- Định dạng số tự động dựa trên kiểu dữ liệu
- Tên cột được dịch sang tiếng Việt 