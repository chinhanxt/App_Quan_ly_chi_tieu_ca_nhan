## Why

Tài liệu báo cáo hiện có bộ sơ đồ đã được cập nhật, nhưng phần bảng mô tả đi kèm chưa thống nhất theo từng loại sơ đồ. Việc thiếu một quy tắc đặc tả rõ ràng khiến nội dung giữa `sơ đồ.docx`, `bang_erd_quy_doi_thuc_the.docx` và `baocao.docx` dễ lệch nhau, khó đồng bộ khi chèn vào báo cáo chính.

## What Changes

- Xác định quy tắc mô tả cho sơ đồ use case theo hướng mỗi sơ đồ có một bảng mô tả riêng.
- Xác định quy tắc mô tả cho class diagram và ERD theo hướng mỗi lớp hoặc thực thể có một bảng mô tả riêng.
- Chuẩn hóa mẫu bảng mô tả cho sơ đồ hành vi/chức năng và mẫu bảng mô tả cho sơ đồ dữ liệu để tránh trùng lặp hoặc dùng sai biểu mẫu.
- Quy định cách ánh xạ nội dung từ `sơ đồ.docx` sang các bảng mô tả trung gian trước khi cập nhật vào `baocao.docx`.
- Đặt tiêu chí nhất quán về tên sơ đồ, loại sơ đồ, mục đích, thành phần chính, luồng mô tả và ý nghĩa hệ thống đối với các bảng mô tả use case.

## Capabilities

### New Capabilities
- `report-diagram-description-tables`: Chuẩn hóa cách tạo và tổ chức các bảng mô tả cho sơ đồ use case, class diagram và ERD trong bộ tài liệu báo cáo.

### Modified Capabilities

None.

## Impact

- Ảnh hưởng trực tiếp tới các tài liệu trong thư mục [`baocao`](/c:/Users/admin/Documents/VS/app/baocao), đặc biệt là [`sơ đồ.docx`](/c:/Users/admin/Documents/VS/app/baocao/sơ đồ.docx), [`bang_erd_quy_doi_thuc_the.docx`](/c:/Users/admin/Documents/VS/app/baocao/bang_erd_quy_doi_thuc_the.docx), [`so_do_va_bang_dac_ta.md`](/c:/Users/admin/Documents/VS/app/baocao/so_do_va_bang_dac_ta.md), và [`baocao.docx`](/c:/Users/admin/Documents/VS/app/baocao/baocao.docx).
- Tác động chủ yếu ở mức tài liệu và quy chuẩn trình bày, không thay đổi hành vi ứng dụng hay mã nguồn runtime.
- Tạo nền cho việc cập nhật nội dung báo cáo sau này theo một mẫu thống nhất, giảm rủi ro mô tả sai loại sơ đồ hoặc lặp nội dung giữa class diagram và ERD.
