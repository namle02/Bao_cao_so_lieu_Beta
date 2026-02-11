# Hướng dẫn phát hành bản mới (giữ nguyên cài đặt MSI + nút Cập nhật)

App vẫn dùng **App Installer** (MSI/setup.exe) như hiện tại. Để **nút Cập nhật** trong app hoạt động, mỗi lần phát hành bạn cần đưa bản mới lên **GitHub Release** và đính kèm file **.zip**.

---

## Tạo Release trên GitHub (từng bước)

1. Mở repo: **https://github.com/namle02/Bao_cao_so_lieu_Beta**
2. Bên phải trang, bấm **Releases** (hoặc vào **Code** → cột bên phải có **Releases**).
3. Bấm **Create a new release** (nút xanh).
4. **Choose a tag:** chọn tag có sẵn (vd: `v1.0.0`) hoặc gõ tên tag mới (vd: `v1.0.0`) rồi chọn **Create new tag: v1.0.0 on publish**.
5. **Release title:** gõ tiêu đề, vd: `Release v1.0.0`.
6. **Describe this release:** gõ mô tả (tùy chọn), vd: "Báo cáo số liệu – phiên bản 1.0.0, có tính năng Cập nhật."
7. **Attach binaries:** kéo thả hoặc bấm **Attach binaries by dropping them here or selecting them** để chọn file:
   - **Bắt buộc:** file **.zip** chứa app (để nút Cập nhật trong app tải được). Tên file ví dụ: `BaoCaoSoLieu-v1.0.0.zip`.
   - **Tùy chọn:** `setup.exe` hoặc `App Installer.msi` cho người cài mới.
8. Bấm **Publish release**.

Sau khi publish, app sẽ gọi API `releases/latest`, thấy tag (vd: `v1.0.0`) và file .zip, và nút **Cập nhật** sẽ hoạt động nếu user đang dùng phiên bản cũ hơn.

---

## Cách làm chi tiết

### 1. Build bản cài như bình thường

- Build solution, tạo **App Installer** (MSI + setup.exe) trong `App Installer\Release\`.
- Cài đặt mới vẫn dùng **setup.exe** hoặc **App Installer.msi** — không đổi.

### 2. Tạo bản zip cho nút “Cập nhật”

Nút **Cập nhật** trong app tải file **.zip** từ GitHub Release, giải nén và ghi đè vào thư mục app (kể cả khi user đã cài bằng MSI). Nội dung zip cần giống nội dung bên trong bản cài (có `BaoCaoSoLieu.exe` và các file kèm theo).

**Cách 1 – Thủ công**

- Publish hoặc build Release của project **BaoCaoSoLieuWPF** ra một thư mục (vd: `publish`).
- (Tùy chọn) Tạo file `version.txt` trong thư mục đó, ghi đúng phiên bản (vd: `1.0.1`) để app hiển thị đúng sau khi cập nhật.
- Nén toàn bộ thư mục đó thành **một file .zip** (vd: `BaoCaoSoLieu-1.0.1.zip`). Trong zip, khi giải nén phải có `BaoCaoSoLieu.exe` (ở root hoặc trong một thư mục duy nhất).

**Cách 2 – Dùng GitHub Actions**

- Có thể thêm workflow (giống app Giám định) để khi push tag `v*.*.*` tự build và tạo file zip, rồi tạo Release và đính kèm zip. Khi đó bạn chỉ cần upload thêm **setup.exe** (hoặc MSI) vào đúng Release đó nếu muốn cho người cài mới.

### 3. Tạo GitHub Release và đính kèm file

1. Trên repo GitHub, vào **Releases** → **Create a new release**.
2. **Tag:** chọn hoặc tạo tag theo phiên bản (vd: `v1.0.1`). App sẽ dùng tag này làm “phiên bản mới nhất”.
3. **Release title / description:** tùy bạn (vd: “Release 1.0.1”).
4. **Attach files:**
   - **Bắt buộc cho nút Cập nhật:** đính kèm file **.zip** (vd: `BaoCaoSoLieu-1.0.1.zip`) đã tạo ở bước 2.
   - **Tùy chọn:** đính kèm **setup.exe** và/hoặc **App Installer.msi** để người dùng cài mới hoặc cài đè bằng installer.
5. Publish release.

### 4. Repo GitHub trong code

- App gọi API: `https://api.github.com/repos/{owner}/{repo}/releases/latest`.
- Đang dùng: **namle02/Bao_cao_so_lieu_Beta** (trong `UpdateService.cs`, constant `GITHUB_REPO`).

## Tóm tắt

- **Giữ nguyên:** Cài đặt bằng **App Installer** (MSI/setup) — không thay đổi cách cài.
- **Thêm:** Mỗi bản phát hành tạo **GitHub Release** với tag phiên bản (vd: `v1.0.1`) và đính kèm **.zip** chứa nội dung app.
- **Nút Cập nhật:** Kiểm tra `releases/latest`, tải file .zip, giải nén và ghi đè vào thư mục app (kể cả khi đã cài bằng MSI), sau đó thoát và chạy lại app.
