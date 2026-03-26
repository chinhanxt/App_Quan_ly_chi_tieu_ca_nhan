## Why

Màn AI hiện tại trong ứng dụng dựa chủ yếu vào parse/OCR cục bộ, nên xử lý tốt các câu ngắn quen thuộc nhưng còn hạn chế khi người dùng nói vòng, trả lời theo ngữ cảnh nhiều lượt, hoặc gửi nội dung ảnh cần suy luận mềm hơn. Đồng thời, đội vận hành chưa có nơi tập trung trên web admin để bật/tắt AI thật, cập nhật runtime config, và điều chỉnh prompt mà không chạm vào code parse hiện có.

## What Changes

- Thêm cấu hình runtime AI trên web admin để quản lý trạng thái bật/tắt AI thật, provider/model, chiến lược fallback, xử lý ảnh, và API key theo hướng vận hành trực tiếp từ admin.
- Mở rộng khu vực cấu hình AI hiện có để tách riêng local lexicon parse với runtime config cho AI thật, theo mô hình draft/publish nhằm giảm rủi ro phá vỡ cấu hình đang chạy.
- Định nghĩa prompt 4 tầng cho AI thật, bao phủ vai trò, nhiệm vụ, luật tạo card xác nhận, và luật phản hồi ngữ cảnh rộng để AI có thể vừa bóc tách giao dịch vừa trả lời tự nhiên khi chưa nên tạo card.
- Chuẩn hóa contract hành vi cho AI mode thật: chỉ tạo card xác nhận khi đủ dữ liệu quan trọng; nếu thiếu thì hỏi lại đúng phần thiếu; nếu là câu hỏi không phải giao dịch thì trả lời tự nhiên mà không ép tạo card.
- Bổ sung khả năng preview và kiểm tra cấu hình AI thật từ admin trước khi publish, với ưu tiên không làm thay đổi hay phá vỡ các chức năng admin web và parse hiện tại.

## Capabilities

### New Capabilities
- `admin-ai-runtime-config`: Quản lý runtime config cho AI thật từ web admin, bao gồm draft/publish, API key, prompt 4 tầng, model, chế độ ảnh, và chính sách fallback.
- `ai-chat-runtime-extraction`: Xác định contract hành vi cho AI mode thật trong ứng dụng, bao gồm phân loại ý định, hỏi lại khi thiếu dữ liệu, tạo card xác nhận khi đủ dữ liệu, và phản hồi tự nhiên cho ngữ cảnh ngoài giao dịch.

### Modified Capabilities

None.

## Impact

- Ảnh hưởng tới [`lib/admin_web/pages/ai_config_page.dart`](/c:/Users/admin/Documents/VS/app/lib/admin_web/pages/ai_config_page.dart), [`lib/admin_web/admin_web_repository.dart`](/c:/Users/admin/Documents/VS/app/lib/admin_web/admin_web_repository.dart), và mô hình `system_configs` trong Firestore.
- Ảnh hưởng tới màn AI người dùng tại [`lib/screens/ai_input_screen.dart`](/c:/Users/admin/Documents/VS/app/lib/screens/ai_input_screen.dart) và service AI tại [`lib/services/ai_service.dart`](/c:/Users/admin/Documents/VS/app/lib/services/ai_service.dart).
- Tăng phạm vi vận hành của web admin nhưng phải giữ nguyên hành vi ổn định hiện có của local parse và các khu vực admin web không liên quan.
- Đưa API key vào runtime config do admin quản lý, chấp nhận trade-off vận hành thuận tiện cao hơn nhưng bảo mật thấp hơn so với backend secret management.
