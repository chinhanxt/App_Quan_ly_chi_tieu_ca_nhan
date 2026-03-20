# ĐẶC TẢ YÊU CẦU: TÍNH NĂNG QUÉT HÓA ĐƠN BẰNG OCR (OFFLINE)
# Tệp này lưu trữ các yêu cầu chức năng và luồng triển khai cho việc tự động điền thông tin giao dịch từ ảnh.

## 1. Tóm tắt tính năng
Người dùng khi thêm mới một giao dịch (chi tiêu/thu nhập) có thể sử dụng tính năng "Quét Hóa Đơn". Tính năng này sẽ tự động đọc chữ trên bức ảnh (qua Camera hoặc Gallery) để trích xuất **Số Tiền**, **Ngày Tháng**, và **Tên Cửa Hàng/Dịch vụ**. Toàn bộ quá trình xử lý diễn ra offline trên điện thoại thông minh và **KHÔNG** lưu lại ảnh lên Server để đảm bảo bảo mật và tiết kiệm chi phí.

## 2. Thư viện & Công nghệ
- **Quản lý ảnh:** `image_picker` (Cho phép truy cập Camera/Gallery).
- **Nhận diện văn bản (OCR):** `google_mlkit_text_recognition` (Hoạt động offline, không cần API key, hỗ trợ ngôn ngữ Việt/Anh cực tốt).
- **Phân tích chuỗi (Parser):** Xây dựng các biểu thức chính quy (`Regex`) tùy chỉnh để nhận diện định dạng tiền tệ VNĐ, ngày tháng và suy luận tiêu đề.

## 3. Các bước triển khai chi tiết

### Bước 1: Cấu hình Quyền (Permissions)
1. **Android (`android/app/src/main/AndroidManifest.xml`):**
   - Thêm quyền Camera: `<uses-permission android:name="android.permission.CAMERA" />`
   - Thêm cấu hình hỗ trợ `image_picker`.
2. **iOS (`ios/Runner/Info.plist`):**
   - Thêm mô tả quyền Camera (`NSCameraUsageDescription`).
   - Thêm mô tả quyền Thư viện ảnh (`NSPhotoLibraryUsageDescription`).

### Bước 2: Tạo Khối Xử lý OCR (Core Logic)
1. **Tạo file `lib/utils/ocr_helper.dart`:**
   - Cấu hình `TextRecognizer` từ `google_ml_kit`.
   - Tạo luồng nhận `InputImage` và trả về danh sách các chuỗi văn bản.
   - Xây dựng lớp tĩnh (Static class/functions) chứa Regex để quét:
     - **Amount (Số tiền):** Trích xuất con số lớn nhất trong bill. (Xóa dấu chấm phẩy phân tách hàng nghìn).
     - **Date (Ngày tháng):** Quét định dạng `dd/mm/yyyy`, `dd-mm-yyyy`.
     - **Title (Tiêu đề):** Lấy dòng Text đầu tiên chứa ít nhất 3 chữ cái.

### Bước 3: Tích hợp vào UI (Màn hình AddTransactionsForm)
1. **Sửa file `lib/widgets/add_transactions_form.dart`:**
   - Thêm 2 IconButtons (hoặc 1 nút bấm sổ Menu) ở phía trên cùng của Form: `📸 Chụp Hóa Đơn` và `🖼️ Chọn Từ Thư Viện`.
   - Hiển thị Loading Dialog ("Đang phân tích...") trong lúc OCR chạy (khoảng 1-3 giây).
   - Gọi hàm từ `ocr_helper.dart`.
   - Bóc tách kết quả và gán đè vào `titleEditController.text`, `amountEditController.text`.
   - Cập nhật biến `date` và gọi `setState()` để UI hiển thị thông tin ngay lập tức.
   - Giải phóng bộ nhớ (hủy instance của TextRecognizer và File ảnh rác).

## 4. Ghi chú Kỹ thuật hiện tại
- Trong quá trình tải thư viện `google_ml_kit` xuống máy cục bộ (Windows), Flutter đang báo lỗi thiếu quyền Symlink: **"Building with plugins requires symlink support. Please enable Developer Mode in your system settings."**
- **Yêu cầu đối với người dùng (admin):** Cần mở Settings của Windows, tìm kiếm "Developer settings" (Cài đặt nhà phát triển) và bật "Developer Mode" (Chế độ nhà phát triển) trước khi tiến hành `flutter pub get` ở bước tiếp theo.

---
**Trạng thái:** Chờ xác nhận từ người dùng. File pubspec.yaml đã chứa các thư viện nhưng chưa được download thành công do lỗi hệ điều hành.