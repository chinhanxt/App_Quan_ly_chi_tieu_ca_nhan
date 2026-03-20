# Đặc tả Chức năng: Nhập liệu bằng Ngôn ngữ Tự nhiên (AI Natural Language Input)

## 1. Giới thiệu
Chức năng này cho phép người dùng nhập các giao dịch tài chính (thu nhập, chi tiêu) thông qua các câu nói hoặc dòng văn bản bình thường. Hệ thống sẽ sử dụng Trí tuệ nhân tạo (AI) để phân tích và bóc tách dữ liệu tự động, giúp giảm bớt các thao tác thủ công rườm rà.

## 2. Mục tiêu
- Tăng tốc độ nhập liệu giao dịch (dưới 5 giây).
- Giảm rào cản "ngại nhập liệu" của người dùng.
- Mang lại trải nghiệm trợ lý tài chính thông minh và hiện đại.

## 3. Luồng hoạt động (Workflow)
1. **Người dùng:** Nhập văn bản (Ví dụ: "Sáng nay ăn phở 50k") hoặc sử dụng Voice-to-Text.
2. **Hệ thống (App):** Gửi nội dung văn bản kèm theo ngữ cảnh (Ngày hiện tại, danh sách Danh mục của App) lên AI API.
3. **Trí tuệ nhân tạo (AI):** Phân tích ngữ pháp, bóc tách các thực thể (Entity Extraction) và trả về định dạng dữ liệu chuẩn (JSON).
4. **Hệ thống (App):** Hiển thị một Popup/Form xác nhận với các thông tin đã được AI điền sẵn.
5. **Người dùng:** Kiểm tra, chỉnh sửa (nếu AI nhận diện sai) và bấm "Xác nhận".
6. **Hệ thống (App):** Lưu giao dịch vào cơ sở dữ liệu và cập nhật số dư ví.

## 4. Các thông tin cần bóc tách (Entities)
- **Số tiền (Amount):** Quy đổi các từ lóng (k, củ, lít...) về số nguyên VND.
- **Loại giao dịch (Type):** Thu nhập (Credit) hoặc Chi tiêu (Debit).
- **Danh mục (Category):** Phân loại vào các nhóm có sẵn trong App (Ăn uống, Di chuyển, Lương...).
- **Ngày tháng (Date):** Tính toán ngày cụ thể từ các từ tương đối (Hôm qua, sáng nay, thứ 2...).
- **Ghi chú (Note):** Mô tả chi tiết về giao dịch.

## 5. Các giai đoạn thực hiện (Phân tích Logic)

### Giai đoạn 1: Thiết kế API và Cấu trúc dữ liệu
- Lựa chọn mô hình AI (Gemini Pro / GPT-4).
- Quy định Schema trả về (JSON) để đảm bảo App đọc được dữ liệu.

### Giai đoạn 2: Kỹ thuật Prompt Engineering
- Thiết lập System Prompt để AI đóng vai trợ lý tài chính.
- Cung cấp danh sách danh mục (Categories) để AI không tự ý tạo danh mục mới.
- Xử lý các biến thể ngôn ngữ đời thường của Việt Nam.

### Giai đoạn 3: Tích hợp Giao diện (UI/UX)
- Thêm ô nhập liệu nhanh tại trang Dashboard hoặc trang Thêm giao dịch.
- Xây dựng hiệu ứng chờ (Loading) chuyên nghiệp.

### Giai đoạn 4: Xác nhận và Chỉnh sửa (Verification)
- Xây dựng Popup hiển thị kết quả AI bóc tách được.
- Đảm bảo tính chính xác: Luôn cho người dùng sửa lại trước khi lưu chính thức.

### Giai đoạn 5: Tối ưu và Bảo mật
- Lưu Log các câu lệnh để cải thiện Prompt.
- Đảm bảo không gửi các thông tin nhạy cảm của người dùng lên AI.

## 6. Rủi ro và Giải pháp
- **AI hiểu sai:** Luôn có bước xác nhận từ con người.
- **Chi phí API:** Tối ưu số lượng ký tự gửi đi và giới hạn số lượt dùng mỗi ngày của người dùng.
- **Lỗi mạng:** Có thông báo rõ ràng khi không kết nối được với Server AI.
