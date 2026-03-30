# Hướng dẫn vẽ bằng StarUML

## 1. Ghi chú nhanh

Trong môi trường hiện tại chưa có `StarUML`, nên mình không thể mở phần mềm để vẽ và xuất ảnh trực tiếp. Tuy nhiên, bạn có thể làm rất nhanh trong StarUML theo đúng cấu trúc bên dưới.

## 2. Sơ đồ Use Case tổng quát

### 2.1. Tạo sơ đồ

1. Mở `StarUML`.
2. Chọn `File` -> `New`.
3. Ở khung `Model Explorer`, bấm chuột phải vào `Model`.
4. Chọn `Add Diagram` -> `Use Case Diagram`.
5. Đổi tên diagram thành: `Use Case Tong Quat`.

### 2.2. Thêm actor

Thêm 2 actor:

- `User`
- `Admin`

### 2.3. Thêm các use case

Thêm các use case sau vào bên trong system:

- `Quản lý tài khoản`
- `Quản lý giao dịch`
- `Quản lý ngân sách`
- `Chat AI / nhập liệu thông minh`
- `Xem báo cáo thống kê`
- `Quản lý người dùng`
- `Quản lý danh mục hệ thống`
- `Xem dashboard tổng quan`

### 2.4. Cách nối actor với use case

Nối `User` với:

- `Quản lý tài khoản`
- `Quản lý giao dịch`
- `Quản lý ngân sách`
- `Chat AI / nhập liệu thông minh`
- `Xem báo cáo thống kê`

Nối `Admin` với:

- `Quản lý tài khoản`
- `Quản lý người dùng`
- `Quản lý danh mục hệ thống`
- `Xem dashboard tổng quan`

### 2.5. Bố cục nên đặt

- `User` đặt bên trái.
- `Admin` đặt bên phải.
- 8 use case đặt ở giữa, chia thành 2 cụm:
  - Cụm trên cho `User`
  - Cụm dưới hoặc bên phải cho `Admin`
- Có thể thêm `Subject/System Boundary` và đặt tên:
  - `Hệ thống quản lý tài chính cá nhân`

### 2.6. Bố cục gợi ý để bạn sắp trong StarUML

```text
User                                  Admin
 |                                      |
 |---- Quản lý tài khoản ---------------|
 |---- Quản lý giao dịch
 |---- Quản lý ngân sách
 |---- Chat AI / nhập liệu thông minh
 |---- Xem báo cáo thống kê
                                        |---- Quản lý người dùng
                                        |---- Quản lý danh mục hệ thống
                                        |---- Xem dashboard tổng quan
```

## 3. Sơ đồ Activity nghiệp vụ tổng quát

### 3.1. Tạo sơ đồ

1. Trong `Model Explorer`, bấm chuột phải vào `Model`.
2. Chọn `Add Diagram` -> `Activity Diagram`.
3. Đổi tên thành: `Activity Nghiep Vu Tong Quat`.

### 3.2. Các phần tử cần thêm

Bạn thêm các node theo thứ tự sau:

1. `Initial Node`
2. `Action`: `Người dùng phát sinh giao dịch`
3. `Decision`: `Chọn cách nhập`
4. Nhánh 1:
   - `Action`: `Nhập số tiền, danh mục, ghi chú, thời gian`
5. Nhánh 2:
   - `Action`: `Nhập câu lệnh tự nhiên / giọng nói`
   - `Action`: `Gửi nội dung tới AI Parser`
   - `Action`: `AI phân tích và chuẩn hóa dữ liệu`
   - `Action`: `Trả về giao dịch nháp`
   - `Decision`: `Người dùng đồng ý?`
6. `Action`: `Kiểm tra dữ liệu đầu vào`
7. `Decision`: `Dữ liệu hợp lệ?`
8. `Action`: `Lưu giao dịch vào Firestore`
9. `Action`: `Cập nhật dữ liệu giao dịch`
10. `Action`: `Tính lại số dư, ngân sách, tổng thu chi`
11. `Action`: `Đồng bộ realtime tới Dashboard và Báo cáo`
12. `Action`: `Dữ liệu xuất hiện trên báo cáo`
13. `Final Node`

### 3.3. Luồng nối chi tiết

Nối theo đúng thứ tự:

1. `Initial Node` -> `Người dùng phát sinh giao dịch`
2. `Người dùng phát sinh giao dịch` -> `Chọn cách nhập`

Từ `Chọn cách nhập` tách 2 nhánh:

- Nhánh `Thủ công` -> `Nhập số tiền, danh mục, ghi chú, thời gian` -> `Kiểm tra dữ liệu đầu vào`
- Nhánh `AI / giọng nói` -> `Nhập câu lệnh tự nhiên / giọng nói` -> `Gửi nội dung tới AI Parser` -> `AI phân tích và chuẩn hóa dữ liệu` -> `Trả về giao dịch nháp` -> `Người dùng đồng ý?`

Từ `Người dùng đồng ý?`:

- `Có` -> `Kiểm tra dữ liệu đầu vào`
- `Không` -> `Kết thúc / hủy thao tác`

Từ `Kiểm tra dữ liệu đầu vào` -> `Dữ liệu hợp lệ?`

Từ `Dữ liệu hợp lệ?`:

- `Hợp lệ` -> `Lưu giao dịch vào Firestore`
- `Không hợp lệ` -> `Nhập lại thông tin`

Sau đó nối tiếp:

- `Lưu giao dịch vào Firestore`
- `Cập nhật dữ liệu giao dịch`
- `Tính lại số dư, ngân sách, tổng thu chi`
- `Đồng bộ realtime tới Dashboard và Báo cáo`
- `Dữ liệu xuất hiện trên báo cáo`
- `Final Node`

### 3.4. Bố cục nên đặt

- Đặt luồng chính theo chiều dọc từ trên xuống dưới.
- Nhánh `Thủ công` ở bên trái.
- Nhánh `AI / giọng nói` ở bên phải.
- Sau phần kiểm tra xác nhận thì gộp 2 nhánh lại ở bước `Kiểm tra dữ liệu đầu vào`.

### 3.5. Khung bố cục text để bạn dễ kéo thả

```text
Start
  |
Người dùng phát sinh giao dịch
  |
[Chọn cách nhập]
  |----------------------|
  |                      |
Thủ công              AI / giọng nói
  |                      |
Nhập thông tin        Nhập câu lệnh
  |                      |
                     Gửi AI Parser
                         |
                     AI phân tích
                         |
                     Trả về giao dịch nháp
                         |
                    [Người dùng đồng ý?]
                         |
  |----------------------|
  |
Kiểm tra dữ liệu đầu vào
  |
[Dữ liệu hợp lệ?]
  |
Lưu Firestore
  |
Cập nhật giao dịch
  |
Tính lại số dư / ngân sách / tổng thu chi
  |
Đồng bộ realtime
  |
Dữ liệu xuất hiện trên báo cáo
  |
End
```

## 4. Mẹo trình bày để giống bài báo cáo

1. Use Case Diagram:
   - Dùng `Subject` bao ngoài toàn bộ use case.
   - Tên hệ thống để ở mép trên: `Hệ thống quản lý tài chính cá nhân`.
   - Các use case nên đặt cùng kích thước.

2. Activity Diagram:
   - Dùng nhãn guard cho decision như:
   - `[Thủ công]`, `[AI/Giọng nói]`
   - `[Có]`, `[Không]`
   - `[Hợp lệ]`, `[Không hợp lệ]`

3. Khi xuất hình:
   - Chọn nền trắng
   - Font đồng nhất
   - Độ rộng vừa trang A4

## 5. Nếu bạn muốn làm nhanh hơn

Mình có thể làm tiếp cho bạn một trong 2 cách:

1. Soạn luôn nội dung theo kiểu `đúng từng cú click` trong StarUML, rất chi tiết để bạn dựng trong 5 phút.
2. Tạo cho bạn một file `đặc tả từng phần tử` theo danh sách actor, use case, action, decision, guard để bạn chỉ việc copy tên vào StarUML.
