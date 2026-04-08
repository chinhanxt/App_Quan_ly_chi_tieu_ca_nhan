## Context

Màn AI hiện tại trong [`lib/screens/ai_input_screen.dart`](/c:/Users/admin/Documents/VS/app/lib/screens/ai_input_screen.dart) đã có các mảnh quan trọng cho luồng xác nhận giao dịch: chat timeline, AI draft cards, chỉnh sửa thủ công, xóa card nháp, và lưu hàng loạt sau khi người dùng xác nhận. Ở tầng xử lý, [`lib/services/ai_service.dart`](/c:/Users/admin/Documents/VS/app/lib/services/ai_service.dart) đã có contract rõ giữa `clarification`, `natural_reply`, và `transactions[]`, còn [`lib/services/transaction_segmenter.dart`](/c:/Users/admin/Documents/VS/app/lib/services/transaction_segmenter.dart) đã có logic tách nhiều ý theo từ nối.

Điểm còn thiếu là một luồng nhập bằng giọng nói cho màn AI. Luồng này không chỉ cần speech-to-text, mà còn phải xử lý đặc trưng của voice input: transcript thay đổi liên tục, từ nối có thể bị nuốt, nhiều giao dịch có thể bị đọc liền nhau, và có những câu nghe mơ hồ nhưng vẫn đủ cơ sở để gợi ý vài phương án hợp lý cho người dùng chọn nhanh.

Ràng buộc chính:
- Không phá vỡ contract draft card hiện có của màn AI.
- Không auto-save giao dịch chỉ vì speech recognition đã nghe ra một phần nội dung.
- Không tách riêng thành hai tính năng độc lập "câu đơn" và "câu nhiều ý" nếu vẫn có thể thống nhất trong một engine.
- Trường hợp mơ hồ phải ưu tiên an toàn nhưng không được bế tắc; hệ thống phải đưa ra recommendation hoặc editable draft khi có tín hiệu hữu ích.

## Goals / Non-Goals

**Goals:**
- Thêm voice input vào màn AI với transcript sống để người dùng quan sát nội dung đang được nhận diện.
- Dùng một voice interpretation pipeline thống nhất để xử lý cả single-intent lẫn multi-intent utterances.
- Chỉ dựng draft card khi hệ thống có đủ dữ liệu và đủ tự tin để không gây hiểu nhầm nghiêm trọng.
- Khi transcript chưa đủ chắc, đưa ra recommendation có cấu trúc, candidate interpretation, hoặc draft có thể chỉnh sửa thay vì chỉ yêu cầu nói lại chung chung.
- Giữ toàn bộ voice result trong AI draft layer hiện tại để tận dụng edit, delete, persist local history, và batch save.

**Non-Goals:**
- Không đưa ghi âm thô hoặc audio file lên backend riêng như một hệ thống voice note.
- Không xây một ASR model riêng; change này chỉ tích hợp speech capture phía client qua adapter.
- Không thay đổi schema Firestore của transaction đã lưu.
- Không cố giải mọi câu hội thoại rất dài hoặc quá tự do như một voice assistant tổng quát.

## Decisions

### 1. Voice đi vào màn AI như một input source mới, không phải một màn hay flow riêng

Quyết định:
- Thêm mic experience trực tiếp trên màn AI và đổ kết quả vào cùng message/draft contract đang dùng cho text.

Lý do:
- Màn AI đã có vùng chat, clarification, draft card review, manual edit, và save semantics phù hợp.
- Tạo flow riêng sẽ làm trùng logic hiển thị card, chỉnh sửa, và persist lịch sử.

Các lựa chọn đã cân nhắc:
- Tạo popup voice riêng rồi đẩy kết quả về AI screen: nhanh trước mắt nhưng tạo hai mental model và hai vùng review khác nhau.
- Tạo màn voice-only: không phù hợp với mục tiêu hợp nhất trải nghiệm AI.

### 2. Thiết kế một `voice interpretation` layer riêng đứng giữa speech capture và AI draft contract

Quyết định:
- Tách speech capture adapter khỏi lớp hiểu transcript.
- Tạo một voice interpretation layer có nhiệm vụ nhận transcript cuối hoặc transcript ổn định, đánh giá intent mode, tách segment, chấm độ chắc chắn, và trả về kết quả review-safe.

Lý do:
- Speech plugin và luật hiểu giao dịch là hai mối quan tâm khác nhau.
- Tách lớp giúp dễ test với transcript giả và giữ UI không phụ thuộc trực tiếp vào plugin speech.

Các lựa chọn đã cân nhắc:
- Cho UI gọi plugin rồi parse trực tiếp tại màn hình: nhanh nhưng khó test và dễ làm state UI phình to.
- Nhét mọi logic vào `AIService`: không sai nhưng làm service quá tải vì speech-state và card-state không cùng abstraction.

### 3. Single-intent và multi-intent dùng chung một engine với phân loại theo mức chắc chắn

Quyết định:
- Không tạo hai mode độc lập buộc người dùng phải chọn trước.
- Interpreter sẽ xếp transcript vào một trong ba trạng thái vận hành:
  - `single`: có tín hiệu mạnh là một giao dịch
  - `multi`: có tín hiệu mạnh là nhiều giao dịch
  - `uncertain`: chưa đủ chắc để chốt một cách tách duy nhất

Lý do:
- Người dùng nói tự nhiên, không nên phải chọn mode trước khi nói.
- Nhiều câu không có từ nối rõ nhưng vẫn có thể là nhiều ý, trong khi một số câu có từ nối lại chỉ là một tiêu đề dài.

Các lựa chọn đã cân nhắc:
- Chọn mode bằng tay trước khi nói: giảm ambiguity nhưng tăng ma sát và dễ dùng sai.
- Coi hễ có `và`, `rồi`, `với` là multi-intent tuyệt đối: quá cứng, dễ cắt sai các tiêu đề giao dịch.

### 4. Card chỉ được sinh tự động khi đủ dữ liệu bắt buộc và confidence vượt ngưỡng an toàn

Quyết định:
- Voice interpreter chỉ trả draft cards auto-ready khi mỗi giao dịch ứng viên đã có các trường cốt lõi và confidence đủ cao.
- Nếu thiếu amount, ranh giới segment chưa chắc, hoặc candidate category/title chưa ổn định, kết quả phải chuyển sang clarification hoặc recommendation.

Lý do:
- Voice input dễ sinh ảo giác chắc chắn do transcript trông “gần đúng”.
- Draft layer là safety boundary cuối, nhưng vẫn nên chặn auto-card quá sớm để tránh UI gây hiểu lầm.

Các lựa chọn đã cân nhắc:
- Hễ parse được gì thì tạo card hết rồi cho người dùng tự sửa: nhanh nhưng dễ làm chat tràn card sai.
- Luôn bắt người dùng xác nhận từng field trước khi lên card: an toàn nhưng quá chậm.

### 5. Trường hợp mơ hồ phải trả về recommendation có cấu trúc, không chỉ một câu hỏi chung

Quyết định:
- Interpreter sẽ hỗ trợ một output recommendation gồm:
  - transcript đã nghe
  - phân loại ambiguity
  - danh sách candidate interpretations hoặc candidate transactions
  - missing fields / points of conflict
  - editable draft seed nếu có dữ liệu đủ hữu ích

Lý do:
- Với voice input, bắt người dùng nói lại từ đầu liên tục là trải nghiệm rất tệ.
- Nhiều trường hợp tuy chưa đủ chắc để auto-add nhưng đủ để gợi ý 2-3 cách hiểu có ích.

Các lựa chọn đã cân nhắc:
- Chỉ trả `clarification` text: đơn giản nhưng làm người dùng phải làm lại toàn bộ.
- Luôn ép một best guess duy nhất: nhanh nhưng rủi ro ghi nhầm giao dịch.

### 6. Transcript sống và transcript dùng để phân tích phải được tách vai trò

Quyết định:
- UI hiển thị partial transcript theo thời gian thực để người dùng quan sát.
- Interpreter chỉ chốt parse trên transcript cuối hoặc transcript đã ổn định theo cửa sổ thời gian ngắn.

Lý do:
- Partial transcript hữu ích cho quan sát nhưng thường dao động mạnh.
- Nếu parse ngay mọi partial update, UI sẽ nhảy trạng thái liên tục và gây nhầm rằng app đã “chốt”.

Các lựa chọn đã cân nhắc:
- Chỉ hiển thị final transcript: ổn định hơn nhưng thiếu cảm giác đang nghe.
- Parse trên mọi partial chunk: phản hồi nhanh nhưng quá rung lắc.

### 7. Voice review metadata được lưu cùng local AI history nhưng không trở thành transaction persisted schema

Quyết định:
- Mọi metadata như raw transcript, normalized transcript, recommendation options, uncertainty reason, hay parse mode chỉ sống trong local AI message state.

Lý do:
- Đây là dữ liệu phục vụ review và giải thích tại thời điểm nhập liệu, không phải dữ liệu giao dịch chuẩn sau khi save.
- Giữ metadata ở draft layer tránh làm Firestore schema bị ô nhiễm bởi state tạm thời.

Các lựa chọn đã cân nhắc:
- Lưu metadata theo transaction document: không cần thiết và tăng độ phức tạp rollback.
- Không lưu metadata gì cả: khiến restore history sau restart mất ngữ cảnh review.

## Risks / Trade-offs

- [Speech recognition trên thiết bị nghe sai từ nối hoặc mất dấu phân cách] → Mitigation: kết hợp heuristic từ nối với quantity boundary, segment scoring, và trạng thái `uncertain` thay vì ép tách chắc chắn.
- [Transcript sống làm người dùng tưởng giao dịch đã được chốt] → Mitigation: phân biệt rõ UI giữa “đang nghe”, “đã hiểu nháp”, và “cần xác nhận”.
- [Recommendation quá nhiều lựa chọn làm trải nghiệm rối] → Mitigation: giới hạn số option hiển thị, ưu tiên top candidate, và luôn cho đường sửa tay nhanh.
- [Voice flow làm `AIInputScreen` phình state hơn nữa] → Mitigation: tách speech adapter, interpreter result model, và review widgets khỏi stateful screen chính.
- [Giữ metadata trong local history có thể làm cấu trúc message phức tạp] → Mitigation: giới hạn metadata vào draft-only fields có thể serialize đơn giản và bỏ qua khi message đã save xong.

## Migration Plan

1. Thêm speech capture adapter và contract cho voice interpretation result mà chưa bật UI cho người dùng cuối.
2. Tích hợp mic control và live transcript vào màn AI, nhưng vẫn chỉ dùng voice để đổ text vào composer trong giai đoạn đầu nếu cần rollout mềm.
3. Bật interpretation path để dựng clarification, recommendations, hoặc draft cards trực tiếp từ voice.
4. Mở rộng local message persistence để giữ voice review context qua app restart.
5. Rollback bằng cách ẩn mic action và vô hiệu hóa interpretation path, trong khi text/image AI flow hiện tại vẫn giữ nguyên.

## Open Questions

- Recommendation UI nên xuất hiện như một AI bubble riêng hay như một panel gắn với transcript bubble đang nghe?
- Có cần cho người dùng “khóa” một đoạn transcript rồi sửa tay trước khi parse lại, hay chỉ cần chọn recommendation và mở editor card?
- Trong lần đầu rollout, voice có nên chỉ hỗ trợ locale `vi_VN` hay cần cơ chế fallback locale rõ ràng?
