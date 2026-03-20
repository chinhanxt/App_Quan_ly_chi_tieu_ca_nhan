# Đặc tả Logic và Phản hồi của Trợ lý AI

Tài liệu này tổng hợp các quy tắc logic mà AI phải tuân thủ dựa trên phiên hỏi đáp giữa nhà phát triển và người dùng.

## 1. Xử lý Giao dịch phức tạp
- **Giao dịch kép:** Nếu người dùng nhập một câu chứa nhiều khoản chi (Ví dụ: "Ăn phở 50k và uống cafe 30k"), AI phải tách thành **2 giao dịch riêng biệt**.
- **Giao diện hiển thị:** Thay vì hiển thị một thẻ đơn lẻ, ứng dụng sẽ hiển thị một **danh sách các thẻ giao dịch (List of Cards)** để người dùng có thể xác nhận hoặc xóa bớt từng khoản một cách linh hoạt.
- **Xử lý nợ:** AI sẽ mặc định hiểu theo ngữ cảnh tự nhiên của tiếng Việt hoặc yêu cầu người dùng xác nhận lại nếu nội dung quá mơ hồ.

## 2. Quản lý Danh mục (Categories)
- **Đọc dữ liệu hiện có:** AI được cung cấp danh sách `customCategories` từ Firestore của từng User để phân loại chính xác vào các mục người dùng đã tạo.
- **Tự động đề xuất danh mục mới:**
    - Nếu câu nói chứa nội dung chưa có trong danh mục hiện tại, AI sẽ tự nghĩ ra một tên danh mục phù hợp.
    - AI sẽ chọn một `iconName` phù hợp nhất từ danh sách 26 icon gợi ý trong hệ thống (`AppIcons`).
- **Quy trình xác nhận:** 
    - Ngay trong thẻ Preview Card, hệ thống sẽ hiển thị thêm một dòng trạng thái: *"Phát hiện mục chi mới: [Tên Danh Mục] - Icon: [Biểu tượng]. Bạn có muốn tạo danh mục này không?"*.
    - Nếu User đồng ý: Danh mục mới sẽ được thêm chính thức vào tài khoản và giao dịch sẽ được lưu vào mục đó.

## 3. Phạm vi chức năng (Scope)
- **Thu/Chi:** Chỉ tập trung bóc tách các giao dịch Thu nhập (Credit) và Chi tiêu (Debit).
- **Tiết kiệm:** Không tự động liên kết với các mục tiêu tiết kiệm (Saving Goals) thông qua AI để tránh phức tạp hóa dòng tiền.

## 4. Trải nghiệm người dùng (UX) và Phản hồi
- **Trường hợp không nhận diện được:** Nếu người dùng nói nội dung không liên quan đến tài chính, AI phải phản hồi một cách hóm hỉnh, thân thiện và yêu cầu người dùng nhập lại nội dung đúng.
    - *Ví dụ:* "Ôi, câu này khó quá, tôi chỉ giỏi tính tiền thôi. Bạn nói lại về khoản chi tiêu nào đó đi!"
- **Xác nhận dữ liệu:** Kết quả bóc tách sẽ được hiển thị qua Card xem trước (Preview Card) để người dùng kiểm tra lại toàn bộ thông tin trước khi nhấn lưu chính thức.

## 5. Kỹ thuật và Bảo mật
- **Quản lý API Key:** API Key sẽ được lưu trong một file cục bộ `lib/services/ai_config.dart`.
- **An toàn:** File này sẽ được thêm vào `.gitignore` để không bao giờ bị lộ lên các kho lưu trữ mã nguồn công khai.

---
**Xác nhận:** Tôi đã nắm bắt đầy đủ các yêu cầu trên và sẵn sàng triển khai phần Backend theo đúng đặc tả này.
