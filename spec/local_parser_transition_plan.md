# Roadmap: Transition from AI to Local Rule-Based Parser

Tài liệu này đặc tả kế hoạch 7 giai đoạn để thay thế dần hệ thống phân tích giao dịch bằng AI sang một Local Parser (Rule-based) tối ưu, đảm bảo tính an toàn, tốc độ và độ chính xác cao.

## 1. Mục tiêu (Objective)
Thay thế AI trong luồng phân tích ngôn ngữ tự nhiên (NLP) bằng một Local Parser có khả năng:
*   **Multi-parsing:** Bắt 1 hoặc nhiều giao dịch trong một chuỗi input duy nhất.
*   **Entity Extraction:** Trích xuất chính xác: Type (Thu/Chi), Amount (Số tiền), Date/Time (Thời gian), Title (Tiêu đề), Category (Danh mục).
*   **Smart Categorization:** Đề xuất hoặc tự động tạo danh mục mới dựa trên ngữ cảnh.
*   **Confidence System:** Cơ chế chấm điểm tin cậy để yêu cầu xác nhận từ người dùng khi cần thiết.

---

## 2. Các giai đoạn triển khai (Implementation Stages)

### Giai đoạn 1: Chuẩn hóa Parser Core
*   **Mục tiêu:** Xây dựng khung xương cho Parser mà không làm hỏng UI hiện tại.
*   **Cấu trúc 5 lớp:**
    1.  **Normalizer:** Chuẩn hóa văn bản (xử lý viết hoa, dấu câu, khoảng trắng).
    2.  **Segmenter:** Tách câu thành các phân đoạn giao dịch độc lập (dựa trên từ nối: "và", "rồi", ","...).
    3.  **Entity Extractor:** Trích xuất số tiền, thời gian và từ khóa hành động.
    4.  **Category Resolver:** Khớp danh mục dựa trên từ điển và lịch sử user.
    5.  **Confidence Scorer:** Chấm điểm dựa trên mức độ khớp từ khóa và cấu trúc câu.
*   **Contract:** Giữ nguyên interface trong `ai_service.dart`, thêm cờ `source: local_parse`.

### Giai đoạn 2: Thiết kế & Tối ưu Bộ từ điển (Lexicon)
*   **Transaction Types:** Bắt các cues như "được cho", "hoàn tiền" (Thu) vs "mua", "đóng", "nạp" (Chi).
*   **Amount Slang:** Xử lý `k`, `xị`, `củ`, `chai`, `lít`, `quả`, `m`.
*   **Temporal Phrases:** "hôm qua", "trưa nay", "15p trước", "thứ 2 tuần tới".
*   **Category & Synonyms:** Hệ thống từ đồng nghĩa, từ lóng theo từng nhóm ngành (Ăn uống, Di chuyển...).
*   **Separators:** Các từ khóa tách giao dịch ("xong", "sau đó", ";").

### Giai đoạn 3: Thay thế AI theo cấp độ (Incremental Replacement)
*   **Level 1:** Chỉ parse 1 giao dịch đơn lẻ có cấu trúc chắc chắn.
*   **Level 2:** Thêm khả năng tách đa giao dịch (Segmentation).
*   **Level 3:** Tích hợp hệ thống Confidence:
    - **Cao:** Tự động tạo giao dịch.
    - **Trung bình:** Hiển thị card xác nhận để user sửa.
    - **Thấp:** Hiển thị form trống hoặc hỏi lại ngắn gọn.

### Giai đoạn 4: Cơ chế Tự tạo Danh mục (Auto-Category)
*   **Rule 1:** Ưu tiên khớp danh mục hiện có của người dùng.
*   **Rule 2:** Khớp theo Taxonomy chuẩn của ứng dụng (System categories).
*   **Rule 3:** Nếu không khớp, sinh danh mục mới từ cụm danh từ (Noun phrase) hoặc cụm từ khóa.
*   **Rule 4:** Map icon tự động theo nhóm từ khóa cha.
*   **Rule 5:** Chỉ lưu vào `customCategories` khi người dùng nhấn "Lưu".

### Giai đoạn 5: Xử lý Đa giao dịch (Multi-transaction)
*   **Logic:** Tách input thành các segment độc lập -> Parse từng segment -> Tổng hợp kết quả.
*   **Phức tạp hóa:** Xử lý trường hợp 1 số tiền áp dụng cho nhiều item (ví dụ: "Bún và cafe hết 50k").
*   **Ambiguity:** Nếu một segment mơ hồ, gán confidence thấp để chờ xác nhận.

### Giai đoạn 6: Kiểm thử & Benchmark
*   **Test Sets:** Tạo bộ dữ liệu kiểm thử theo Intent (Chi đơn, Thu đơn, Đa giao dịch, Slang...).
*   **Metrics:** 
    - Type Accuracy (Độ chính xác loại giao dịch).
    - Amount Accuracy (Độ chính xác số tiền).
    - Segmentation Accuracy (Độ chính xác tách câu).
*   **Ngưỡng:** Chỉ tắt AI khi Local Parser đạt độ chính xác > 95% trên bộ test case phổ thông.

### Giai đoạn 7: Rollout & Shadow Testing
*   **Shadow Mode:** Chạy Local Parser song song với AI, log kết quả so sánh nhưng vẫn hiển thị kết quả AI cho user.
*   **Analysis:** Phân tích các case Local Parser sai để bổ sung từ điển.
*   **Full Switch:** Chuyển hẳn sang Local Parser khi dữ liệu thực tế chứng minh tính ổn định.

---

## 3. Phân tích Kỹ thuật bổ sung (Technical Analysis)

### 3.1. Xử lý Ngữ cảnh Thực thể (Amount Context)
Parser cần phân biệt được "Số lượng" và "Tổng tiền". 
*   *Ví dụ:* "Mua 5 cái bánh hết 50k" -> `5` là lượng, `50k` là tiền. 
*   *Giải pháp:* Sử dụng các từ khóa bổ trợ như "hết", "tổng", "mất", "giá" để xác định trọng tâm con số.

### 3.2. Xử lý Sự mơ hồ (Ambiguity Handling)
Nhiều từ khóa nằm trong nhiều nhóm (ví dụ: "Grab" có thể là di chuyển hoặc ăn uống).
*   *Giải pháp:* Sử dụng trọng số (Weight) và từ khóa đi kèm (Co-occurrence keywords). 
    - `Grab` + `Bún` = Ăn uống.
    - `Grab` + `Sân bay` = Di chuyển.

### 3.3. Thứ tự Thực thể (SVO & Directional Logic)
Xác định hướng dòng tiền dựa trên vị trí của chủ thể và động từ.
*   "Mẹ cho 100k" (Thu) vs "Cho mẹ 100k" (Chi).
*   Parser cần xác định được giới từ hướng (`cho`, `từ`, `đến`) để đảo ngược Type nếu cần.

### 3.4. Cấu trúc Code dự kiến
*   **Refactor:** `lib/services/ai_service.dart`.
*   **New Components:**
    - `transaction_segmenter.dart` (Tách chuỗi).
    - `transaction_amount_parser.dart` (Xử lý số và đơn vị lóng).
    - `transaction_category_resolver.dart` (Khớp danh mục & taxonomy).
    - `transaction_confidence.dart` (Tính toán độ tin cậy).

---

## 4. Các yếu tố cần xác nhận (Pending Decisions)
1.  **Taxonomy chuẩn:** Danh sách danh mục gốc cố định của hệ thống.
2.  **Mức độ Auto-create:** Có cho phép tự tạo danh mục mới hoàn toàn mà không qua xác nhận không? (Khuyến nghị: Luôn qua xác nhận ở mức Trung bình).
3.  **Mẫu câu thực tế:** Thu thập thêm dữ liệu từ user để làm giàu bộ test case.
