## Context

Ứng dụng hiện có hai phần liên quan trực tiếp đến thay đổi này. Thứ nhất, màn AI người dùng tại `lib/screens/ai_input_screen.dart` đã có luồng chat, hiển thị card xác nhận, và lưu giao dịch hoàn chỉnh. Thứ hai, admin web đã có khu vực `AiConfigPage` và repository `AdminWebRepository` để quản lý local parse lexicon theo mô hình draft/publish trong `system_configs`.

Điểm mạnh của trạng thái hiện tại là UI xác nhận giao dịch đã có contract rõ: miễn là service trả về `transactions[]` đúng schema thì app có thể render card và cho lưu. Điểm yếu là local parse/OCR hiện tại chưa đủ linh hoạt cho hội thoại nhiều lượt, ngữ cảnh mơ hồ, và phản hồi rộng ngoài trường hợp câu lệnh giao dịch đơn giản.

Change này cố ý đi theo hướng vận hành trực tiếp từ client và web admin, không dùng Cloud Functions hoặc backend secret management. Điều này giảm độ phức tạp triển khai nhưng đồng thời chấp nhận trade-off bảo mật: API key do admin quản lý sẽ trở thành runtime config mà client có thể sử dụng.

Các ràng buộc chính:
- Không phá vỡ bất kỳ khu vực admin web đang ổn định nào ngoài phạm vi AI config.
- Không làm local parse hiện tại ngừng hoạt động.
- Giữ UI xác nhận và lưu giao dịch hiện tại làm contract cuối.
- Tách local lexicon parse khỏi AI runtime config để debug và rollback rõ ràng.

## Goals / Non-Goals

**Goals:**
- Bổ sung một lớp runtime AI config riêng trong web admin, theo mô hình draft/publish tương tự lexicon hiện tại.
- Cho phép operator quản lý AI mode mặc định, provider/model, fallback policy, image handling strategy, API key, và prompt 4 tầng.
- Chuẩn hóa prompt thành bốn khối riêng: role, task, card rules, conversation rules.
- Định nghĩa contract hành vi cho AI mode thật: phân loại ý định, hỏi lại khi thiếu dữ liệu, chỉ ra card khi đủ dữ liệu, và trả lời tự nhiên khi không nên tạo card.
- Tận dụng UI AI và flow xác nhận/lưu giao dịch hiện có thay vì thiết kế lại từ đầu.

**Non-Goals:**
- Không cố biến việc lưu key trong runtime config thành một cơ chế bảo mật mạnh.
- Không thay toàn bộ local parser hoặc OCR hiện tại trong change này.
- Không thiết kế một hệ memory/hội thoại đa phiên rất phức tạp vượt ngoài nhu cầu hỏi lại ngắn hạn.
- Không di chuyển cấu hình AI sang `SystemConfigsPage` tổng quát nếu `AiConfigPage` hiện tại đã đủ ngữ cảnh và an toàn hơn để mở rộng.

## Decisions

### 1. Tách `ai_runtime_config` khỏi `ai_lexicon`

Quyết định:
- Tạo một runtime config riêng trong `system_configs`, song song với `ai_lexicon` và `ai_lexicon_draft`.
- Dùng cặp tài liệu theo mô hình tương tự: `ai_runtime_config` và `ai_runtime_config_draft`.

Lý do:
- Local parse lexicon và real AI runtime config là hai loại cấu hình khác nhau về bản chất, tốc độ thay đổi, và cách debug.
- Tách riêng giúp preview, publish, rollback, và audit dễ hiểu hơn.

Các lựa chọn đã cân nhắc:
- Nhét toàn bộ vào `ai_lexicon`: đơn giản hơn trước mắt nhưng khó kiểm soát ranh giới giữa parse rule và prompt AI.
- Đưa vào `SystemConfigsPage`: phù hợp về mặt “config”, nhưng xa ngữ cảnh AI và dễ làm lan thay đổi vào khu admin rộng hơn.

### 2. Mở rộng `AiConfigPage` thay vì tạo trang admin mới

Quyết định:
- Giữ nguyên menu `Cấu hình AI` và mở rộng ngay trong `AiConfigPage`.

Lý do:
- Đây là điểm chạm vận hành AI đã tồn tại, nên thêm runtime config ở đây ít làm thay đổi mental model của admin.
- Hạn chế rủi ro phá vỡ các khu vực admin web không liên quan.

Các lựa chọn đã cân nhắc:
- Tạo trang admin mới chỉ cho runtime config: rõ ràng hơn nhưng tăng điều hướng và phạm vi thay đổi UI.
- Nhét một phần vào `SystemConfigsPage`: dễ gây lẫn giữa config hệ thống chung và config AI chuyên biệt.

### 3. Prompt được lưu thành bốn lớp cấu trúc thay vì một blob duy nhất

Quyết định:
- Lưu prompt dưới dạng bốn trường logic:
  - `rolePrompt`
  - `taskPrompt`
  - `cardRulesPrompt`
  - `conversationRulesPrompt`
- Ứng dụng sẽ ghép lại theo thứ tự cố định để tạo effective prompt.

Lý do:
- Operator có thể chỉnh một lớp mà không phá các lớp còn lại.
- Review và diff bản nháp/bản chạy dễ hơn rất nhiều so với một ô prompt dài duy nhất.
- Bám đúng yêu cầu “prompt 4 tầng”.

Các lựa chọn đã cân nhắc:
- Một trường `systemPrompt` duy nhất: linh hoạt tối đa nhưng dễ vô tình làm hỏng contract.
- Prompt builder quá cứng bằng các câu hardcode: an toàn hơn nhưng mất khả năng vận hành từ admin.

### 4. Runtime AI dùng contract phân loại ý định trước khi tạo card

Quyết định:
- AI mode thật được thiết kế quanh ba kiểu output:
  - `clarification`: hỏi lại do thiếu dữ liệu hoặc dữ liệu chưa chắc
  - `card-ready`: trả về `transactions[]` để UI hiện card xác nhận
  - `natural-reply`: trả lời ngữ cảnh tự nhiên khi user chưa thực sự ghi giao dịch

Lý do:
- Người dùng muốn AI “hiểu mọi ngữ cảnh” nhưng không ép mọi câu nói thành giao dịch.
- Contract này giữ được chatbot feel mà vẫn bảo toàn UI card/lưu hiện tại.

Các lựa chọn đã cân nhắc:
- Buộc mọi phản hồi đi qua transaction schema: quá cứng và dễ tạo card sai.
- Để AI tự do hoàn toàn: linh hoạt nhưng khó kiểm soát lúc nào nên hiện card.

### 5. Ảnh đi theo cùng một confirmation contract với text

Quyết định:
- Dù ảnh được xử lý bằng OCR trước hay bởi model hiểu ảnh, kết quả cuối vẫn phải đi qua cùng contract clarification-or-card như text.

Lý do:
- Người dùng không nên thấy hai trải nghiệm AI khác nhau trên cùng một màn.
- Giữ ổn định cho bước render card và lưu.

Các lựa chọn đã cân nhắc:
- Giữ ảnh là luồng cục bộ riêng biệt: ít thay đổi hơn nhưng trái với mục tiêu “AI thật vào cuộc”.

### 6. Chấp nhận trade-off bảo mật của hướng 2 và biểu diễn nó thành quyết định vận hành, không phải bảo mật

Quyết định:
- Thiết kế rõ rằng API key trong runtime config là lựa chọn vì tính tiện vận hành, không phải secure secret management.
- UI admin cần biểu đạt key theo dạng masked/replaced để tránh lộ trực quan không cần thiết, nhưng không hứa hẹn tính bí mật tuyệt đối.

Lý do:
- Điều này trung thực với hệ thống: nếu client đọc được config để gọi provider trực tiếp thì key không thể coi là secret mạnh.

Các lựa chọn đã cân nhắc:
- Giả vờ key “an toàn” chỉ vì không hiển thị plaintext trên UI: dễ gây hiểu sai và quyết định vận hành sai.

## Risks / Trade-offs

- [API key có thể bị lộ từ client runtime] → Mitigation: biểu đạt rõ trong design và admin UI đây là trade-off đã chấp nhận; hỗ trợ thay key nhanh từ admin và ưu tiên masked display.
- [Mở rộng `AiConfigPage` có thể làm trang AI config trở nên rối] → Mitigation: chia khu rõ giữa Local Parse Config và Real AI Runtime Config; giữ draft/publish độc lập cho từng loại config.
- [Prompt chỉnh tự do dễ làm AI trả lời lan man hoặc phá contract tạo card] → Mitigation: ép cấu trúc bốn lớp, giữ thứ tự ghép prompt cố định, và bổ sung preview trước publish.
- [Ảnh và text có thể cho trải nghiệm không đồng nhất] → Mitigation: ép mọi input sau bước hiểu dữ liệu phải đi qua cùng contract clarification-or-card.
- [Fallback mơ hồ có thể khiến operator không hiểu khi nào app dùng parse cũ hay AI thật] → Mitigation: runtime config phải có fallback policy tường minh và preview phải hiển thị rõ đang đánh giá theo mode nào.
- [Thêm natural reply có thể làm app bớt tính quyết đoán trong việc ghi giao dịch] → Mitigation: rules tạo card phải ưu tiên hỏi ngắn gọn và chốt card nhanh khi đủ dữ liệu.

## Migration Plan

1. Tạo tài liệu `system_configs/ai_runtime_config` và `system_configs/ai_runtime_config_draft` với giá trị mặc định an toàn, ban đầu có thể để AI mode tắt.
2. Mở rộng admin repository để load, save draft, publish, và preview runtime config mà không ảnh hưởng tới `ai_lexicon`.
3. Mở rộng `AiConfigPage` để hiển thị riêng khu runtime AI config, prompt 4 tầng, và preview.
4. Cập nhật application-side AI service để đọc published runtime config và quyết định giữa local parse và runtime AI path.
5. Giữ local parse làm đường ổn định ban đầu cho đến khi runtime config được publish và bật AI mode.
6. Nếu rollout gặp vấn đề, rollback bằng cách tắt AI mode trong published runtime config hoặc quay về bản publish trước.

## Open Questions

- Key sẽ được app đọc trực tiếp từ Firestore mỗi phiên, cache cục bộ, hay đồng bộ vào session state khi mở màn AI?
- Preview trên admin web sẽ là preview cấu trúc prompt và expected contract hay sẽ gọi trực tiếp provider thật khi có key trong draft?
- Khi AI mode trả `natural-reply`, có cần mở rộng model message hiện tại để phân biệt loại phản hồi này với `clarification` không?
- Ảnh ở giai đoạn đầu sẽ dùng OCR hiện tại rồi gửi text cho AI, hay sẽ thiết kế mở để sau này thay bằng image-capable model mà không đổi contract?
