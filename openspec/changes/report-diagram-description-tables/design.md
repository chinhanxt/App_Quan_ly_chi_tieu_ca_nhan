## Context

Bộ tài liệu báo cáo trong thư mục `baocao` đang có ba nguồn nội dung liên quan trực tiếp tới thay đổi này: `sơ đồ.docx` chứa các hình sơ đồ đã cập nhật, `bang_erd_quy_doi_thuc_the.docx` đang biểu diễn mô tả dữ liệu theo từng thực thể, và `baocao.docx` là tài liệu báo cáo tổng hợp cần chèn các bảng mô tả tương ứng.

Vấn đề hiện tại không nằm ở mã nguồn ứng dụng mà ở tính nhất quán tài liệu. Nếu không có một thiết kế chung cho bảng mô tả, nhóm rất dễ:
- dùng cùng một mẫu cho mọi loại sơ đồ dù bản chất khác nhau,
- lặp nội dung giữa class diagram và ERD,
- hoặc cập nhật bảng trong `baocao.docx` không còn khớp với sơ đồ mới trong `sơ đồ.docx`.

Thay đổi này vì vậy cần một thiết kế tài liệu rõ ràng để định nghĩa:
- loại sơ đồ nào dùng mẫu bảng nào,
- cách ánh xạ từ hình sơ đồ sang bảng mô tả,
- và cách kiểm tra tính khớp giữa tài liệu trung gian và báo cáo chính.

## Goals / Non-Goals

**Goals:**
- Xác định một mô hình mô tả nhất quán cho sơ đồ use case, trong đó mỗi sơ đồ có một bảng mô tả riêng.
- Xác định một mô hình mô tả nhất quán cho class diagram và ERD, trong đó mỗi lớp hoặc thực thể có một bảng mô tả riêng.
- Tách rõ mẫu bảng mô tả sơ đồ chức năng với mẫu bảng mô tả dữ liệu để tránh dùng sai biểu mẫu.
- Thiết kế luồng cập nhật tài liệu sao cho nội dung trong `sơ đồ.docx`, tài liệu mô tả trung gian, và `baocao.docx` có thể đối chiếu được theo cùng danh mục.

**Non-Goals:**
- Không thay đổi nội dung ảnh sơ đồ gốc trong `sơ đồ.docx`.
- Không thay đổi logic hay hành vi của ứng dụng Flutter, Firebase, AI, hoặc admin web.
- Không cố hợp nhất class diagram và ERD thành một mô tả duy nhất nếu điều đó làm mất ý nghĩa phân tích.
- Không tự động hóa bằng script trong phạm vi design này; trọng tâm là xác định cấu trúc tài liệu và trình tự cập nhật.

## Decisions

### 1. Chia bảng mô tả thành hai họ mẫu thay vì một mẫu chung cho mọi sơ đồ

Quyết định:
- Dùng mẫu `Thuộc tính | Nội dung` cho các sơ đồ thiên về chức năng hoặc luồng như use case.
- Dùng mẫu `STT | Thuộc tính | Mô tả ngắn` cho class diagram và ERD ở mức lớp/thực thể.

Lý do:
- Sơ đồ hành vi cần diễn giải mục đích, luồng và ý nghĩa tổng quát.
- Sơ đồ dữ liệu cần tập trung vào từng thuộc tính của lớp hoặc thực thể.
- Một mẫu duy nhất cho mọi loại sơ đồ sẽ làm nội dung hoặc quá chung, hoặc quá gượng khi áp dụng cho dữ liệu.

Các lựa chọn đã cân nhắc:
- Dùng duy nhất một mẫu 6 dòng cho tất cả sơ đồ: dễ thống nhất hình thức nhưng không phù hợp cho class diagram và ERD.
- Dùng bảng thuộc tính chi tiết cho cả use case: làm mất phần giải thích mục đích và bối cảnh của sơ đồ chức năng.

### 2. Use case được quản lý theo đơn vị sơ đồ

Quyết định:
- Mỗi sơ đồ use case trong `sơ đồ.docx` tương ứng đúng một bảng mô tả riêng.

Lý do:
- Use case biểu diễn một bối cảnh chức năng hoàn chỉnh, nên người đọc cần được mô tả ở mức toàn sơ đồ.
- Cách này phù hợp với mẫu đang được nhóm định hướng: tên sơ đồ, loại sơ đồ, mục đích, thành phần chính, luồng mô tả, ý nghĩa hệ thống.

Các lựa chọn đã cân nhắc:
- Tách theo từng use case nhỏ trong cùng sơ đồ: chi tiết hơn nhưng làm nổ số lượng bảng và khó chèn vào báo cáo môn học.

### 3. Class diagram và ERD được quản lý theo đơn vị lớp/thực thể

Quyết định:
- Với class diagram và ERD, mỗi lớp hoặc thực thể có một bảng mô tả riêng.

Lý do:
- Đây là mức chi tiết phù hợp với nội dung dữ liệu mà giảng viên thường yêu cầu trong báo cáo.
- Cách này bám được cấu trúc đã có trong `bang_erd_quy_doi_thuc_the.docx` và giảm rủi ro mô tả quá chung cho cả sơ đồ dữ liệu.

Các lựa chọn đã cân nhắc:
- Mỗi sơ đồ class/ERD chỉ có một bảng tổng quát: nhanh hơn nhưng không đủ chi tiết để diễn giải từng đối tượng dữ liệu.

### 4. Giữ class diagram và ERD là hai lớp diễn giải gần nhau nhưng không đồng nhất hoàn toàn

Quyết định:
- Nếu cùng một đối tượng xuất hiện ở cả class diagram và ERD, nội dung mô tả phải được viết theo góc nhìn phù hợp với từng loại sơ đồ thay vì sao chép nguyên xi.

Lý do:
- Class diagram nghiêng về cấu trúc lớp và quan hệ trong thiết kế phần mềm.
- ERD nghiêng về thực thể lưu trữ và dữ liệu trong cơ sở dữ liệu.
- Giữ khác biệt nhẹ về trọng tâm giúp báo cáo tránh cảm giác lặp lại máy móc.

Các lựa chọn đã cân nhắc:
- Dùng cùng một bảng cho cả class diagram và ERD của cùng thực thể: tiết kiệm công nhưng làm mờ khác biệt giữa thiết kế lớp và thiết kế dữ liệu.

### 5. Cập nhật theo luồng tài liệu trung gian trước khi chèn vào báo cáo chính

Quyết định:
- Xem `sơ đồ.docx` là nguồn hình gốc.
- Xem tài liệu bảng mô tả trung gian là nơi chuẩn hóa nội dung mô tả.
- Chỉ sau khi danh mục và nội dung mô tả đã ổn định mới cập nhật sang `baocao.docx`.

Lý do:
- `baocao.docx` là tài liệu tổng hợp lớn, chỉnh trực tiếp ngay từ đầu sẽ khó kiểm soát.
- Có lớp trung gian giúp đối chiếu, rà soát và tránh thiếu bảng khi chèn vào báo cáo.

Các lựa chọn đã cân nhắc:
- Cập nhật thẳng từ `sơ đồ.docx` vào `baocao.docx`: nhanh hơn nhưng khó kiểm tra tính nhất quán.

## Risks / Trade-offs

- [Tên hoặc thứ tự sơ đồ trong `sơ đồ.docx` không được gắn caption rõ ràng] → Mitigation: lập danh mục đối chiếu thủ công giữa từng hình và từng bảng mô tả trước khi cập nhật báo cáo chính.
- [Class diagram và ERD có thể chứa cùng tập đối tượng dẫn tới trùng nội dung] → Mitigation: quy định rõ class diagram mô tả theo góc nhìn lớp, ERD mô tả theo góc nhìn thực thể dữ liệu.
- [Báo cáo tổng hợp có thể thiếu hoặc dư bảng so với sơ đồ thực tế] → Mitigation: đối chiếu theo checklist nguồn hình, bảng mô tả trung gian, và danh mục trong `baocao.docx`.
- [Người biên soạn dễ dùng nhầm mẫu bảng] → Mitigation: chuẩn hóa mỗi loại sơ đồ với một mẫu cố định và nhóm chúng theo mục riêng trong tài liệu.

## Migration Plan

1. Lập danh mục các sơ đồ hiện có trong `sơ đồ.docx` và phân loại chúng thành use case, class diagram, hoặc ERD.
2. Tạo danh mục các bảng mô tả cần có tương ứng với từng sơ đồ use case và từng lớp/thực thể trong class diagram hoặc ERD.
3. Soạn nội dung bảng mô tả theo đúng mẫu của từng loại.
4. Đối chiếu các bảng mô tả với `bang_erd_quy_doi_thuc_the.docx` và các ghi chú phân tích hiện có để bảo đảm không sai lệch ý nghĩa dữ liệu.
5. Chèn hoặc cập nhật các bảng mô tả vào `baocao.docx` theo đúng vị trí chương mục.
6. Rà soát cuối cùng để bảo đảm số lượng bảng, tên bảng, và nội dung mô tả khớp với sơ đồ nguồn.

## Open Questions

- Danh mục cuối cùng trong `sơ đồ.docx` hiện có chính xác bao nhiêu sơ đồ use case và bao nhiêu sơ đồ dữ liệu cần mô tả?
- Class diagram và ERD trong bộ tài liệu hiện có dùng cùng một tập tên đối tượng hay có khác biệt cần tách riêng?
- `baocao.docx` đang cần thay toàn bộ bảng mô tả cũ hay chỉ cập nhật các phần đã bị lệch so với sơ đồ mới?
