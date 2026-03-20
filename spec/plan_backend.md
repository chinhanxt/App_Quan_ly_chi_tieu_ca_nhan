# Kế hoạch Triển khai Backend AI (Google Gemini API)

## 1. Mục tiêu
Tích hợp mô hình ngôn ngữ lớn (LLM) Gemini của Google để tự động phân tích và bóc tách dữ liệu tài chính từ ngôn ngữ tự nhiên, sau đó đồng bộ hóa với hệ thống Firebase hiện tại của ứng dụng.

## 2. Giai đoạn 1: Thiết lập và Bảo mật API
- **Khởi tạo:** Sử dụng API Key từ Google AI Studio (tài khoản cá nhân).
- **Bảo mật:** 
    - Không lưu API Key trực tiếp trong mã nguồn.
    - Sử dụng biến môi trường hoặc tệp cấu hình riêng biệt được loại trừ khỏi hệ thống quản lý phiên bản (Git).
- **Thư viện:** Tích hợp gói `google_generative_ai` của Google để giao tiếp với mô hình.

## 3. Giai đoạn 2: Kỹ thuật Prompt Engineering (Thiết kế câu lệnh)
Đây là bước then chốt để đảm bảo AI trả về kết quả chính xác và ổn định.
- **Vai trò (System Instruction):** Thiết lập AI là chuyên gia bóc tách dữ liệu tài chính cá nhân.
- **Ngữ cảnh (Context):**
    - **Thời gian:** Cung cấp ngày/giờ hệ thống hiện tại để AI hiểu các mốc thời gian tương đối (hôm qua, tuần trước...).
    - **Danh mục (Categories):** Cung cấp danh sách các danh mục hiện có trong App (Ăn uống, Lương, Mua sắm...) để AI phân loại đồng bộ.
- **Định dạng đầu ra (Output Format):** Ép buộc AI chỉ trả về chuỗi JSON thuần túy chứa các trường: `title`, `amount`, `type` (credit/debit), `category`, `note`, `date`.

## 4. Bổ sung: Xử lý Ngôn ngữ Đời thường & Sai chính tả (Slang & Typo Logic)
Để AI có khả năng xử lý các tin nhắn "tự nhiên" nhất của người Việt, hệ thống sẽ cung cấp một bộ quy tắc JSON trong Prompt:

### 4.1 Quy đổi đơn vị tiền tệ (Currency Mapping)
Cung cấp cho AI quy tắc quy đổi các từ lóng sang con số thực tế:
- `"k"`, `"ngàn"`, `"ng"` -> `* 1.000` (Ví dụ: 50k = 50.000)
- `"lít"`, `"lốp"` -> `* 100.000` (Ví dụ: 2 lít = 200.000)
- `"củ"`, `"m"` -> `* 1.000.000` (Ví dụ: 1 củ = 1.000.000)
- `"vé"` -> `* 500.000` (Tùy ngữ cảnh, thường là tờ 500k)

### 4.2 Xử lý viết tắt & Sai chính tả (Abbreviations & Typos)
AI sẽ được huấn luyện với bộ dữ liệu mẫu (Few-shot prompting) bao gồm:
- **Viết tắt:**
    - `dt`, `đt` -> điện thoại
    - `shpe`, `shp` -> Shopee
    - `tđ`, `gym` -> Tập thể dục / Sức khỏe
    - `xăg`, `xăng` -> Di chuyển
- **Sai chính tả / Ngôn ngữ mạng:**
    - `ăn ság`, `ăn ság` -> ăn sáng
    - `tìn`, `xiền` -> tiền
    - `luơng`, `luong` -> lương
    - `cf`, `kafe` -> cà phê

### 4.3 Quy tắc ưu tiên bóc tách
1. **Ưu tiên ngữ cảnh:** Nếu người dùng nói "trả nợ", AI phải kiểm tra xem có tên người đi kèm không để đưa vào `note`.
2. **Tự động sửa lỗi:** AI thực hiện "Auto-correct" thầm lặng các từ sai chính tả trước khi đưa vào trường `title` và `note` để dữ liệu lưu trữ luôn sạch.

## 5. Giai đoạn 3: Xây dựng AI Service (Logic xử lý)
- **Tiền xử lý:** Chuẩn hóa chuỗi nhập liệu từ người dùng.
- **Giao tiếp API:** Hàm gửi yêu cầu đến mô hình Gemini (ưu tiên mô hình `gemini-1.5-flash` để tối ưu tốc độ).
- **Giải mã dữ liệu (Parsing):** Chuyển đổi phản hồi JSON từ AI thành các đối tượng dữ liệu (Models) trong ứng dụng.
- **Xử lý lỗi:** Thiết lập các kịch bản khi AI không hiểu nội dung, lỗi kết nối mạng hoặc lỗi định dạng dữ liệu.

## 5. Giai đoạn 4: Liên kết Dữ liệu và Xác nhận
- **Mapping:** 
    - Ánh xạ tên danh mục từ AI sang đúng danh mục trong hệ thống App.
    - Chuyển đổi định dạng ngày tháng sang `Timestamp` của Firestore.
- **Tích hợp UI:** Đổ dữ liệu đã bóc tách vào màn hình `Result Preview Card` (đã làm ở Frontend).
- **Lưu trữ:** Khi người dùng xác nhận, gọi hàm `Db().addTransaction` để thực hiện:
    - Lưu giao dịch vào bộ sưu tập `transactions`.
    - Cập nhật số dư ví (`remainingAmount`) của người dùng trên Firebase.

## 6. Giai đoạn 5: Tối ưu hóa Hiệu suất
- **Mô hình:** Sử dụng `Flash` để phản hồi nhanh nhất (thường dưới 2 giây).
- **Chi phí:** Kiểm soát số lượng token gửi đi để tối ưu hóa hạn mức miễn phí/trả phí của Google Cloud.

## 7. Luồng dữ liệu tổng quát (Summary Workflow)
1. **Input:** Câu nói/văn bản người dùng.
2. **Process:** App + Prompt + Gemini API -> JSON Data.
3. **Confirm:** Người dùng kiểm tra lại thông tin trên giao diện.
4. **Output:** Firebase lưu dữ liệu & Dashboard cập nhật số dư.
