## Why

Trang cấu hình AI trên admin web hiện đã có hai lớp thể hiện prompt cho `AI thêm giao dịch` và `AI hỗ trợ`: phần editor theo tầng và phần thư viện prompt xổ xuống. Tuy nhiên hai lớp này đang lệch nhau:

- `AI thêm giao dịch` hiển thị 6 prompt trong thư viện nhưng chỉ có 5 tầng chỉnh sửa.
- `AI hỗ trợ` hiển thị 8 prompt trong thư viện nhưng chỉ có 5 tầng chỉnh sửa.
- Một phần prompt đang là hardcoded block, nên admin nhìn thấy prompt nhưng không biết tầng nào đang điều khiển chúng.

Điều này tạo ra ba vấn đề vận hành:

1. Người vận hành không biết prompt nào thực sự chỉnh được.
2. Rất khó tin tưởng rằng thay đổi ở editor đã phản ánh đúng vào prompt cuối cùng app đang gửi cho model.
3. Realtime config đang có nhưng mô hình editor chưa “parity” với cấu trúc prompt thật, nên việc audit/publish dễ gây hiểu nhầm.

Đây là thay đổi quan trọng vì nó ảnh hưởng trực tiếp tới khả năng vận hành an toàn và minh bạch cho hai AI runtime đang chạy thật trong app.

## What Changes

- Chuẩn hóa mô hình prompt layer cho `AI thêm giao dịch` thành 6 tầng chỉnh sửa được, tương ứng đầy đủ với 6 prompt đang hiển thị.
- Chuẩn hóa mô hình prompt layer cho `AI hỗ trợ` thành 8 tầng chỉnh sửa được, tương ứng đầy đủ với 8 prompt đang hiển thị.
- Tách rõ trong admin web giữa:
  - `Tầng chỉnh sửa`
  - `Thư viện prompt`
  - `Prompt tổng hợp cuối cùng gửi tới model`
- Khi operator sửa bất kỳ tầng nào, thư viện prompt và prompt tổng hợp phải cập nhật ngay trong bản nháp trên UI, không đợi publish.
- Khi lưu/publish runtime config, app phải tiếp tục nhận cấu hình published theo realtime stream như hiện tại, không làm mất hành vi realtime đang có.
- Giữ `AI parse` là khu từ điển/rule riêng, không ép dùng chung mô hình prompt layer như hai AI runtime.

## Capabilities

### Modified Capabilities

- `admin-ai-runtime-config`: Chuẩn hóa quản trị prompt layer cho hai AI runtime theo mô hình parity giữa editor, prompt library, và effective system prompt.
- `ai-chat-runtime-extraction`: Bảo đảm app-side prompt assembly phản ánh đầy đủ các tầng runtime config mới cho AI giao dịch và AI hỗ trợ.

### Non-Goals

- Không biến `AI parse` thành một hệ prompt layer giống hai AI runtime.
- Không thay đổi contract response của AI giao dịch hay AI hỗ trợ ngoài phạm vi prompt assembly và admin UX.
- Không thay secret management strategy cho API key trong change này.

## Impact

- Ảnh hưởng tới [`lib/models/ai_runtime_config.dart`](/c:/Users/admin/Documents/VS/app/lib/models/ai_runtime_config.dart)
- Ảnh hưởng tới [`lib/admin_web/pages/ai_config_page.dart`](/c:/Users/admin/Documents/VS/app/lib/admin_web/pages/ai_config_page.dart)
- Ảnh hưởng tới logic build prompt trong app-side AI service và mọi chỗ dùng `buildSystemPrompt` / `buildAssistantSystemPrompt`
- Có thể cần migration tương thích ngược cho document runtime config cũ chưa có đủ các tầng mới
