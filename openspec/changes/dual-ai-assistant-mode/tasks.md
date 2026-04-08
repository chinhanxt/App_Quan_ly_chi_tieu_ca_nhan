## 1. App AI Modes

- [x] 1.1 Tách luồng service AI thành mode `transaction` và `assistant` với contract đầu ra riêng cho từng mode
- [x] 1.2 Mở rộng runtime config model trong app để đọc được cấu hình riêng của AI hỗ trợ và gate hiển thị mode từ published config
- [x] 1.3 Cập nhật màn AI trong app để cho phép chuyển giữa `AI thêm giao dịch` và `AI hỗ trợ` trong cùng một màn chat
- [x] 1.4 Xây dựng context builder cho AI hỗ trợ để lấy tóm tắt thu chi, ngân sách, tiết kiệm, và dữ liệu hướng dẫn tính năng app
- [x] 1.5 Hiển thị phản hồi AI hỗ trợ dưới dạng chat tự nhiên và action suggestion an toàn, không sinh card giao dịch ở mode hỗ trợ

## 2. Admin Runtime Configuration

- [ ] 2.1 Mở rộng schema runtime config và repository để lưu riêng cấu hình cho AI thêm giao dịch và AI hỗ trợ
- [ ] 2.2 Cập nhật trang AI config trên admin thành ba tab `AI thêm giao dịch`, `AI hỗ trợ`, và `AI parse`
- [ ] 2.3 Thêm form quản lý riêng cho bật/tắt, model, key, prompt, khôi phục mặc định, lưu draft, publish, và preview của AI hỗ trợ
- [ ] 2.4 Giữ tương thích ngược với runtime config cũ để môi trường hiện tại không bị vỡ khi chưa bật AI hỗ trợ

## 3. Validation

- [x] 3.1 Kiểm tra mode hỗ trợ bị ẩn hoàn toàn trong app khi admin tắt published config của AI hỗ trợ
- [x] 3.2 Kiểm tra AI hỗ trợ trả lời được câu hỏi về cách dùng app, thu chi tháng này, ngân sách, và tiết kiệm mà không ép tạo card
- [x] 3.3 Kiểm tra action suggestion chỉ điều hướng/gợi ý an toàn, không tự thực thi thay người dùng
- [x] 3.4 Kiểm tra AI thêm giao dịch hiện có không bị hồi quy khi thêm mode AI hỗ trợ và runtime config mới
