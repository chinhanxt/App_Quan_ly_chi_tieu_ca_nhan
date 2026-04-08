## Why

Màn AI hiện tại đang gộp chung hai nhu cầu rất khác nhau: tạo giao dịch và trò chuyện hỗ trợ. Điều này làm prompt, contract đầu ra, và vận hành runtime AI bị pha trộn, khiến trải nghiệm người dùng khó rõ ràng và đội admin khó quản lý riêng model/key/prompt cho từng vai trò.

## What Changes

- Tách AI trong app thành hai vai trò độc lập: `AI thêm giao dịch` và `AI hỗ trợ`.
- Bổ sung chế độ chuyển đổi ngay trong màn AI của app để người dùng có thể vào luồng hỗ trợ chỉ bằng giao diện chat message input đơn giản.
- Cho phép `AI hỗ trợ` trả lời câu hỏi về cách dùng app, tình hình thu chi, ngân sách, tiết kiệm, và đề xuất hành động điều hướng an toàn trong app.
- Mở rộng runtime config trên admin để quản lý riêng từng AI, bao gồm bật/tắt, model, key, prompt, và preview.
- Tổ chức lại khu vực AI config ở admin theo hướng tách rõ `AI thêm giao dịch`, `AI hỗ trợ`, và `AI parse` để vận hành gọn hơn.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ai-chat-runtime-extraction`: Mở rộng màn AI app thành hai AI riêng biệt, thêm luồng AI hỗ trợ có thể trả lời dữ liệu người dùng và đề xuất hành động điều hướng an toàn mà không ép tạo card giao dịch.
- `admin-ai-runtime-config`: Mở rộng admin runtime config để quản lý riêng cấu hình của AI thêm giao dịch và AI hỗ trợ, kèm cơ chế bật/tắt, prompt, key/model, và bố cục tab rõ ràng hơn.

## Impact

- Ảnh hưởng tới [`lib/screens/ai_input_screen.dart`](/c:/Users/admin/Documents/VS/app/lib/screens/ai_input_screen.dart), [`lib/services/ai_service.dart`](/c:/Users/admin/Documents/VS/app/lib/services/ai_service.dart), và [`lib/models/ai_runtime_config.dart`](/c:/Users/admin/Documents/VS/app/lib/models/ai_runtime_config.dart).
- Ảnh hưởng tới các nguồn dữ liệu người dùng mà AI hỗ trợ cần đọc tóm tắt, như giao dịch, ngân sách, và mục tiêu tiết kiệm.
- Ảnh hưởng tới [`lib/admin_web/pages/ai_config_page.dart`](/c:/Users/admin/Documents/VS/app/lib/admin_web/pages/ai_config_page.dart) và [`lib/admin_web/admin_web_repository.dart`](/c:/Users/admin/Documents/VS/app/lib/admin_web/admin_web_repository.dart).
- Tăng độ phức tạp vận hành runtime AI nhưng đổi lại giảm nhiễu giữa hai nhiệm vụ khác bản chất và mở đường cho việc dùng model/key khác nhau cho từng AI.
