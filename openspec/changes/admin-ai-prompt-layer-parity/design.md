## Context

Hiện tại mô hình prompt của hai AI runtime được triển khai theo kiểu “nửa cấu trúc, nửa hardcoded”.

### AI thêm giao dịch

- Có 5 trường editable rõ ràng:
  - `rolePrompt`
  - `taskPrompt`
  - `cardRulesPrompt`
  - `conversationRulesPrompt`
  - `abbreviationRulesPrompt`
- Nhưng thư viện prompt lại hiển thị thêm `Prompt 6` là contract/rule hệ thống giao dịch.

### AI hỗ trợ

- Có 5 trường editable rõ ràng:
  - `assistantRolePrompt`
  - `assistantTaskPrompt`
  - `assistantConversationRulesPrompt`
  - `assistantAbbreviationRulesPrompt`
  - `assistantAdvancedReasoningPrompt`
- Nhưng thư viện prompt lại hiển thị thêm:
  - `Prompt 6` master prompt toàn app
  - `Prompt 7` action guide
  - `Prompt 8` contract/rule hệ thống AI hỗ trợ

Điều này làm editor không parity với thư viện prompt. Admin nhìn thấy 6/8 prompt nhưng chỉ chỉnh được 5 tầng, gây mất minh bạch vận hành.

## Goals / Non-Goals

**Goals**

- Tạo parity 1:1 giữa tầng editable và thư viện prompt cho hai AI runtime.
- Giữ khả năng realtime publish hiện có của runtime config.
- Cho phép operator thấy ngay “sửa tầng nào -> prompt nào đổi -> prompt cuối cùng đổi”.
- Không kéo `AI parse` vào cùng mô hình này.

**Non-Goals**

- Không đổi bản chất lexicon/rule engine của local parse.
- Không thay đổi Firestore topology lớn ngoài những field cần thêm cho runtime config.
- Không redesign toàn bộ admin AI page ngoài phần cần thiết để làm rõ governance prompt.

## Decisions

### 1. AI giao dịch sẽ có 6 tầng editable

Quyết định:
- Giữ 5 tầng hiện có.
- Thêm tầng 6 editable cho `contract/rule hệ thống giao dịch`.

Lý do:
- Thư viện prompt đã coi đây là một prompt độc lập.
- Prompt cuối cùng `buildSystemPrompt()` đang phụ thuộc vào khối hardcoded này.
- Nếu admin nhìn thấy prompt 6 mà không chỉnh được thì parity bị vỡ.

Tác động data model:
- Thêm field runtime config mới, ví dụ `systemContractPrompt`.
- Có fallback về block mặc định nếu document cũ chưa có field này.

### 2. AI hỗ trợ sẽ có 8 tầng editable

Quyết định:
- Giữ 5 tầng hiện có.
- Thêm 3 tầng editable:
  - `assistantMasterKnowledgePrompt`
  - `assistantActionGuidePrompt`
  - `assistantSystemContractPrompt`

Lý do:
- Ba block này hiện là prompt thật đang tham gia `buildAssistantSystemPrompt()`.
- Chúng cần hiện diện như tầng editor đúng nghĩa nếu admin được quyền vận hành prompt đầy đủ.

Tác động data model:
- Thêm 3 field runtime config mới.
- Dùng giá trị mặc định hiện tại để tương thích ngược.

### 3. Prompt library trở thành “projection” của editor state

Quyết định:
- Thư viện prompt không còn là danh sách hardcoded độc lập.
- Nó luôn build từ state editor hiện tại của draft runtime config.

Lý do:
- Đảm bảo operator thấy ngay thay đổi vừa gõ.
- Tránh lệch giữa “editor” và “thư viện”.

### 4. Thêm khối “Prompt cuối cùng gửi tới model”

Quyết định:
- Mỗi tab AI runtime có thêm một khu read-only:
  - `Prompt tổng hợp cuối cùng`

Lý do:
- Giải thích rõ toàn bộ các tầng được ghép thế nào.
- Giúp debug khi operator hỏi “app thực sự đang gửi gì lên model”.

### 5. Realtime app sync tiếp tục dựa trên published config

Quyết định:
- UI admin được cập nhật tức thời trên draft state khi chỉnh sửa.
- App user chỉ nhận thay đổi khi published config thay đổi, thông qua realtime Firestore như hiện tại.

Lý do:
- Đúng mental model an toàn vận hành: draft có thể thay đổi liên tục, published mới tác động realtime tới app.

### 6. AI parse giữ mô hình riêng

Quyết định:
- Không thêm prompt layer cho AI parse.
- Tab parse tiếp tục là:
  - lexicon/rule editor
  - preview
  - system file

Lý do:
- Đây là rule dictionary engine, không phải assistant/runtime prompt stack.
- Giữ ranh giới nghiệp vụ rõ ràng.

## UX Shape

### AI thêm giao dịch

```text
AI thêm giao dịch
├── Thư viện prompt (Prompt 1..6)
├── Tầng chỉnh sửa (Tầng 1..6)
├── Prompt tổng hợp cuối cùng
└── Preview / Publish
```

### AI hỗ trợ

```text
AI hỗ trợ
├── Thư viện prompt (Prompt 1..8)
├── Tầng chỉnh sửa (Tầng 1..8)
├── Prompt tổng hợp cuối cùng
└── Preview / Publish
```

### AI parse

```text
AI parse
├── Từ điển local parse
├── Preview parse
└── Tệp hệ thống
```

## Risks / Trade-offs

- Thêm nhiều tầng editable hơn sẽ làm admin page dài hơn
  - Mitigation: tiếp tục dùng accordion, chia rõ `thư viện`, `tầng chỉnh sửa`, `prompt cuối cùng`
- Nhiều field config hơn làm migration phức tạp hơn
  - Mitigation: mọi field mới đều có default fallback từ block hiện tại
- Operator có nhiều quyền hơn trên prompt hệ thống
  - Mitigation: vẫn giữ draft/publish, preview, khôi phục mặc định

## Migration Plan

1. Mở rộng `AiRuntimeConfig` với các field mới cho tầng 6 của AI giao dịch và tầng 6-8 của AI hỗ trợ.
2. Dùng default blocks hiện tại làm fallback nếu Firestore document cũ chưa có field mới.
3. Cập nhật admin web editor để hiển thị đủ tầng.
4. Cập nhật `buildTransactionPromptEntries`, `buildAssistantPromptEntries`, `buildSystemPrompt`, `buildAssistantSystemPrompt`.
5. Bổ sung panel `Prompt tổng hợp cuối cùng`.
6. Kiểm tra draft update trên admin và publish realtime tới app.
