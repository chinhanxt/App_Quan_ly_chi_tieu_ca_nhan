# Thiết kế Giao diện: Trợ lý AI Nhập liệu (Frontend Design)

## 1. Biểu tượng AI nổi (Floating AI Button - FAB)
Đây là điểm chạm chính để kích hoạt tính năng AI, được thiết kế để luôn sẵn sàng nhưng không gây vướng víu.

- **Vị trí:** Góc dưới cùng bên phải màn hình chính (Floating position).
- **Hình dáng:** Hình tròn, kích thước tiêu chuẩn của Floating Action Button (FAB).
- **Icon:** Biểu tượng ngôi sao lấp lánh (Sparkles) hoặc hình sóng âm thanh cách điệu.
- **Hiệu ứng thị giác:**
    - Sử dụng dải màu Gradient hiện đại (Xanh tím hoặc Tím hồng).
    - Hiệu ứng phát sáng nhẹ (Glow) hoặc nhịp thở (Pulse) để thu hút sự chú ý.
- **Hành động:** Khi nhấn vào, thực hiện hiệu ứng Hero Animation mở rộng toàn màn hình để chuyển sang trang nhập liệu AI.

## 2. Trang nhập liệu bằng ngôn ngữ tự nhiên (AI Input Page)
Trang chuyên biệt tập trung vào việc giao tiếp giữa người dùng và AI.

### 2.1 Bố cục trang (Layout)
- **Header:** Nút quay lại (Back) và tiêu đề "Trợ lý Tài chính AI".
- **Interaction Zone (Khu vực trung tâm):**
    - Hiệu ứng sóng âm chuyển động (Visualizer) khi lắng nghe giọng nói.
    - Câu chào thân thiện: *"Hôm nay bạn đã chi tiêu gì thế?"*
- **Input Field (Ô nhập liệu):**
    - Ô văn bản lớn, không đường viền (Borderless) tạo cảm giác tự nhiên.
    - Nút Microphone lớn đặt bên cạnh ô nhập liệu để ưu tiên Voice-to-Text.
- **Suggestions Chips (Gợi ý nhanh):**
    - Các nhãn trượt ngang (Horizontal Scroll) chứa các câu mẫu: *"Ăn sáng 30k"*, *"Lương về 10tr"*, *"Đổ xăng 50k"*.

## 3. Thẻ xác nhận kết quả (Result Preview Card)
Xuất hiện ngay sau khi AI xử lý xong văn bản/giọng nói của người dùng.

- **Vị trí:** Hiển thị nổi trên lớp trang nhập liệu.
- **Thông tin hiển thị:**
    - **Số tiền:** Font chữ lớn, in đậm (Ví dụ: **50.000 VND**).
    - **Danh mục:** Icon kèm tên danh mục (Ví dụ: 🍴 Ăn uống).
    - **Ngày tháng:** Mặc định ngày hiện tại (Cho phép chỉnh sửa).
    - **Ghi chú:** Nội dung mô tả chi tiết từ câu nói.
- **Nút hành động:**
    - Nút **"Xác nhận và Lưu"**: Màu sắc nổi bật (Primary Color).
    - Nút **"Chỉnh sửa"**: Dạng Outlined hoặc Text button để thay đổi thông tin nếu AI nhận diện sai.

## 4. Hiệu ứng và Chuyển cảnh (Animations)
- **Kích hoạt:** Hiệu ứng "Hero Expand" từ nút nổi ban đầu ra toàn màn hình.
- **Xử lý (Processing):** Hiệu ứng dải màu chạy (Loading Bar) hoặc vòng quay tinh tế trong lúc đợi AI phản hồi.
- **Hoàn tất:** Hiệu ứng "Checkmark" xanh lục và thẻ thông tin biến mất (Fade out) sau khi lưu thành công.

## 5. Phong cách thiết kế (Style)
- **Glassmorphism:** Sử dụng độ mờ và hiệu ứng Blur cho nền trang AI để tạo cảm giác hiện đại, tách biệt với các chức năng truyền thống.
- **Đồng bộ:** Giữ nguyên các tông màu chủ đạo của ứng dụng (Blue/Dark) nhưng thêm các điểm nhấn Gradient cho phần AI.
