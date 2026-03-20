# Danh sách Thông tin Cần cung cấp để Triển khai AI

Vui lòng cập nhật các thông tin dưới đây để tôi có cơ sở lập trình phần Backend AI.

## 1. Google Gemini API Key
- **Hướng dẫn:** Lấy tại [Google AI Studio](https://aistudio.google.com/).
- **API Key của bạn:** [ĐIỀN_MÃ_API_VÀO_ĐÂY]
- *Lưu ý: Tôi sẽ cấu hình code để đọc mã này một cách an toàn.*

## 2. Lựa chọn Mô hình (Model)
Chọn một trong hai lựa chọn sau (Xóa lựa chọn không dùng):
- **Lựa chọn A (Khuyên dùng):** `gemini-1.5-flash` (Tốc độ cực nhanh, phản hồi < 2 giây, tiết kiệm chi phí).
- **Lựa chọn B:** `gemini-1.5-pro` (Thông minh hơn, hiểu ngữ cảnh phức tạp tốt hơn nhưng phản hồi chậm hơn).

## 3. Cấp quyền cập nhật Thư viện
- Bạn có cho phép tôi tự động thêm `google_generative_ai` vào `pubspec.yaml` và chạy `flutter pub get` không?
- **Trả lời (Có/Không):** [ĐIỀN_CÂU_TRẢ_LỜI]

## 4. Quy tắc phân loại Danh mục (Categories)
Chọn cách bạn muốn AI xử lý khi gặp một khoản chi lạ:
- **Lựa chọn 1 (Chặt chẽ):** Ép buộc AI phải đưa về một trong các danh mục có sẵn: `Lương`, `Mua sắm`, `Ăn uống`, `Di chuyển`, `Tiết kiệm`. Nếu không khớp, đưa vào `Khác`.
- **Lựa chọn 2 (Linh hoạt):** Cho phép AI tự đề xuất tên danh mục mới dựa trên nội dung câu nói.
- **Trả lời (1 hoặc 2):** [ĐIỀN_LỰA_CHỌN]

---
*Sau khi bạn điền xong, hãy thông báo cho tôi để tôi bắt đầu viết mã nguồn.*
