## Context

Hệ thống hiện có một màn AI thống nhất trong app và một runtime config thống nhất trong admin. Ở tầng service, `AIService.processInput(...)` phải đồng thời xử lý yêu cầu tạo giao dịch và câu hỏi tư vấn tự nhiên. Ở tầng vận hành, `AiRuntimeConfig` chỉ có một bộ key/model/prompt, nên không thể tối ưu riêng cho bài toán bóc tách giao dịch và bài toán trợ lý hỗ trợ.

Change này tách thành hai AI logic riêng nhưng vẫn giữ một màn AI thống nhất trong app để không làm phân mảnh trải nghiệm. App là ưu tiên trước; admin sẽ được mở rộng để vận hành song song hai AI và một khu parse/local hiện có.

## Goals / Non-Goals

**Goals:**
- Tách rõ `AI thêm giao dịch` và `AI hỗ trợ` ở tầng contract, runtime config, và UI mode.
- Cho phép AI hỗ trợ trả lời câu hỏi về app và dữ liệu tài chính cá nhân mà không bị ép sinh transaction card.
- Cho phép AI hỗ trợ đề xuất hành động an toàn như mở ngân sách, mở tiết kiệm, hoặc chuyển sang tab thêm giao dịch.
- Giữ một màn AI chung trong app, chỉ thêm mode/tab chuyển đổi thay vì tạo màn mới.
- Cho phép admin bật/tắt riêng từng AI và quản lý key/model/prompt riêng cho từng luồng.

**Non-Goals:**
- Không cho AI tự thực thi hành động thay người dùng; chỉ được đề xuất hoặc deep-link điều hướng.
- Không thay thế local parse hiện tại bằng AI hỗ trợ.
- Không mở rộng sang voice assistant mode trong pha đầu; voice vẫn thuộc luồng tạo giao dịch.
- Không thiết kế lại toàn bộ admin web ngoài khu AI config.

## Decisions

### 1. Tách hai AI ở tầng contract thay vì chỉ tách prompt

`AI thêm giao dịch` và `AI hỗ trợ` sẽ có hai đường xử lý khác nhau trong service, không dùng chung một `processInput(...)` rồi cố phân nhánh sâu trong prompt. Cách này giúp contract đầu ra ổn định hơn:
- AI thêm giao dịch giữ contract card/clarification hiện có
- AI hỗ trợ dùng contract reply/action suggestion riêng

Giải pháp thay thế là chỉ thêm prompt mới vào runtime config hiện tại. Cách đó rẻ hơn lúc đầu nhưng vẫn giữ coupling mạnh và làm UI/service khó kiểm soát khi hai bài toán phát triển lệch nhau.

### 2. Giữ một màn AI chung trong app nhưng thêm mode chuyển đổi

App sẽ không tạo màn riêng cho AI hỗ trợ. Thay vào đó, màn AI hiện có sẽ có vùng chuyển mode đơn giản:
- Thêm giao dịch
- Hỗ trợ

Quyết định này giúp tái sử dụng timeline chat, composer, và lịch sử, đồng thời tránh tăng tải nhận thức cho người dùng.

### 3. AI hỗ trợ được phép đề xuất hành động nhưng không tự thực thi

AI hỗ trợ có thể trả về các gợi ý điều hướng an toàn như:
- Mở màn ngân sách
- Mở màn tiết kiệm
- Chuyển sang tab thêm giao dịch
- Xem tóm tắt tháng này

Lý do: đây là kiểu trợ giúp có ích thực sự nhưng vẫn giữ ranh giới an toàn. Nếu cho tự thực thi ngay, hệ thống sẽ cần thêm lớp xác nhận, audit, và rollback phức tạp hơn nhiều.

### 4. AI hỗ trợ phải đọc context dữ liệu người dùng thật

Pha app-first vẫn cần một context builder để AI hỗ trợ trả lời dựa trên:
- tổng thu/chi tháng hiện tại
- ngân sách đang hoạt động
- mục tiêu tiết kiệm
- giao dịch gần đây
- hướng dẫn tính năng app

Không chỉ dựa vào prompt tĩnh. Nếu không có context dữ liệu thật, trợ lý sẽ trả lời chung chung và làm giảm giá trị tính năng.

### 5. Admin config tách làm ba tab vận hành

Khu AI config ở admin nên được chia thành:
- AI thêm giao dịch
- AI hỗ trợ
- AI parse

Tab AI thêm giao dịch và AI hỗ trợ đều có draft/publish, key/model/prompt/preview riêng. Tab AI parse giữ cấu hình parse/local hiện có. Quyết định này phản ánh đúng ba mối quan tâm vận hành khác nhau.

## Risks / Trade-offs

- [Rủi ro] Hai AI làm runtime config và service phức tạp hơn → Mitigation: giữ contract riêng, đặt tên mode rõ ràng, và giới hạn AI hỗ trợ chỉ trả text + action suggestion trong pha đầu.
- [Rủi ro] AI hỗ trợ có thể trả lời sai nếu context dữ liệu không đồng bộ → Mitigation: build context theo snapshot rõ ràng, ưu tiên dữ liệu tóm tắt tháng hiện tại và nói rõ phạm vi thời gian trong prompt/context.
- [Rủi ro] Người dùng nhầm tab và gửi câu tạo giao dịch ở tab hỗ trợ → Mitigation: AI hỗ trợ được phép đề xuất chuyển sang tab thêm giao dịch thay vì cố tự xử lý thành card.
- [Rủi ro] Admin phải quản lý nhiều prompt/key hơn → Mitigation: dùng bố cục tab rõ, nhãn chức năng cụ thể, preview riêng từng AI, và hỗ trợ khôi phục mặc định theo từng tab.
- [Rủi ro] Dùng model/key khác nhau làm tăng chi phí vận hành → Mitigation: cho phép cấu hình độc lập nhưng không bắt buộc; cùng key/model vẫn là cấu hình hợp lệ.

## Migration Plan

- Thêm cấu trúc runtime config mới theo hướng tương thích ngược: nếu chưa có cấu hình AI hỗ trợ thì mặc định là tắt.
- App đọc published config mới; nếu chưa có assistant config thì ẩn tab AI hỗ trợ.
- Admin web hiển thị bố cục tab mới nhưng vẫn giữ khả năng đọc cấu hình runtime cũ để không làm vỡ môi trường đang chạy.
- Rollback bằng cách tắt AI hỗ trợ trong published config mà không ảnh hưởng đến AI thêm giao dịch.

## Open Questions

- Lịch sử chat có nên tách theo từng mode hay giữ chung một timeline với nhãn mode?
- AI hỗ trợ có cần action `mở báo cáo tháng` ngay pha đầu hay chỉ cần `mở ngân sách` và `mở tiết kiệm`?
- Có cần một model mặc định nhẹ hơn cho AI hỗ trợ để tối ưu chi phí, hay để admin tự chọn hoàn toàn?
