## 1. Runtime Prompt Layer Model

- [x] 1.1 Mở rộng `AiRuntimeConfig` để AI giao dịch có đủ 6 tầng editable và AI hỗ trợ có đủ 8 tầng editable
- [x] 1.2 Thêm fallback tương thích ngược cho document runtime config cũ chưa có các field tầng mới
- [x] 1.3 Cập nhật các helper build thư viện prompt để phản ánh đúng 1:1 toàn bộ tầng editable

## 2. Prompt Assembly and Realtime Behavior

- [x] 2.1 Cập nhật `buildSystemPrompt()` để ghép đủ 6 tầng AI giao dịch
- [x] 2.2 Cập nhật `buildAssistantSystemPrompt()` để ghép đủ 8 tầng AI hỗ trợ
- [x] 2.3 Bảo đảm chỉnh sửa tầng ở admin làm thư viện prompt và prompt tổng hợp cập nhật ngay trên draft state
- [x] 2.4 Bảo đảm publish runtime config tiếp tục đẩy thay đổi về app theo realtime published config

## 3. Admin Web UX

- [x] 3.1 Mở rộng tab `AI thêm giao dịch` thành editor đủ 6 tầng
- [x] 3.2 Mở rộng tab `AI hỗ trợ` thành editor đủ 8 tầng
- [x] 3.3 Thêm panel read-only `Prompt tổng hợp cuối cùng` cho hai AI runtime
- [x] 3.4 Giữ tab `AI parse` tách biệt, không dùng mô hình prompt layer

## 4. Verification

- [x] 4.1 Kiểm tra thư viện prompt và editor không còn lệch số tầng
- [x] 4.2 Kiểm tra sửa từng tầng cập nhật ngay nội dung prompt tương ứng trên admin
- [x] 4.3 Kiểm tra publish thay đổi runtime config làm app nhận prompt mới qua realtime config stream
