# Financial Parser Lexicon Specification (Vietnamese)

Tài liệu này định nghĩa bộ từ điển (lexicon) đa tầng để tối ưu hóa việc phân tích ngôn ngữ tự nhiên (NLP) trong lĩnh vực quản lý tài chính cá nhân.

## 1. Phân loại Giao dịch (Transaction Type Inference)

### 1.1. Nhóm CHI (Debit/Expenses)
*   **Động từ chính:** mua, trả, đóng, thanh toán, chuyển, tiêu, xài, chi, hết, âm, trừ, quẹt, bấm, nạp (điện thoại/game).
*   **Danh từ chỉ hóa đơn:** hóa đơn, bill, cước, phí, tiền (điện/nước/mạng), lãi (vay), nợ (trả nợ).
*   **Tiếng lóng/Viết tắt:** pay, ck (chuyển khoản - tùy ngữ cảnh), out, bay, mất.
*   **Cấu trúc đặc trưng:**
    - `[Động từ chi] + [Số tiền] + [Mục đích]` (Ví dụ: "Trả 50k tiền cơm")
    - `[Mục đích] + [Số tiền]` (Ví dụ: "Bún bò 35k")

### 1.2. Nhóm THU (Credit/Income)
*   **Động từ chính:** nhận, thưởng, cộng, về, lấy, thu, lời, lãi (tiết kiệm), hoàn, hoàn tiền, nạp (vào ví).
*   **Danh từ nguồn thu:** lương, quà, doanh thu, bán, tip, lộc, tiền (thừa/hoàn).
*   **Tiếng lóng/Viết tắt:** + (ví dụ: +500k), về túi, ting ting, lúa về, thóc về.
*   **Cấu trúc đặc trưng:**
    - `[Động từ thu] + [Số tiền] + [Từ đâu/Lý do]` (Ví dụ: "Nhận lương 10 triệu")
    - `[Số tiền] + [Về/Cộng]` (Ví dụ: "500k về ví")

---

## 2. Hệ thống Tiền tệ & Đơn vị (Currency & Units)

### 2.1. Đơn vị chuẩn & Viết tắt
*   **Đồng:** đ, vnđ, d, vnd.
*   **Nghìn:** k, ngàn, kđ, nghìn.
*   **Triệu:** m, tr, triệu.

### 2.2. Tiếng lóng (Slang)
*   **Hàng nghìn:** lít (100k - miền Bắc), xị (100k - miền Nam), chục (10k).
*   **Hàng triệu:** củ, quả, gậy, lúa, tờ (tùy ngữ cảnh), mét (m).
*   **Khác:** nửa củ (500k), một lít (100k), hai lít (200k).

---

## 3. Từ khóa Thời gian (Temporal Expressions)

*   **Tương đối (Relative):**
    - Quá khứ: hôm qua, tối qua, sáng nay, nãy, hồi nãy, vừa xong, vừa mới, tuần trước, tháng trước.
    - Hiện tại: bây giờ, lúc này, hôm nay.
*   **Tuyệt đối (Absolute):**
    - Ngày: ngày 1, ngày 15, mùng 1, mùng 2.
    - Tháng: tháng 1, thg 3, t12.
*   **Định kỳ (Periodic):** mỗi tháng, hàng tuần, hàng ngày, định kỳ, tới kỳ.

---

## 4. Danh mục & Ngữ cảnh (Categories & Context)

### 4.1. Ăn uống (Food & Dining)
*   **Từ khóa:** ăn, uống, cafe, cà phê, cơm, bún, phở, bánh mì, trà sữa, lẩu, buffet, nhậu, quán, grabfood, shopeefood.

### 4.2. Di chuyển (Transport)
*   **Từ khóa:** xăng, grab, xanh sm, taxi, xe ôm, bus, vé máy bay, bảo trì xe, sửa xe, gửi xe, phí đường bộ.

### 4.3. Mua sắm (Shopping)
*   **Từ khóa:** shopee, lazada, tiktok shop, quần áo, mỹ phẩm, siêu thị, winmart, bách hóa xanh, đồ dùng, mua đồ.

### 4.4. Nhà cửa & Tiện ích (Home & Utilities)
*   **Từ khóa:** tiền điện, tiền nước, internet, wifi, rác, chung cư, thuê nhà, sửa nhà, đồ gia dụng.

### 4.5. Sức khỏe (Health)
*   **Từ khóa:** thuốc, bệnh viện, khám, nhà thuốc, vitamin, gym, yoga, bảo hiểm.

---

## 5. Từ bổ trợ & Quan hệ từ (Modifiers & Connectors)

*   **Chỉ hướng:** từ (nguồn), cho (đích), tới, sang, qua, vào, vô.
*   **Xác nhận:** đã, xong, rồi, thành công.
*   **Phủ định (Loại bỏ):** không, chưa, hủy, đừng, không phải (Dùng để tránh parse nhầm các câu nhắc nhở).
*   **Ước lượng:** tầm, khoảng, cỡ, chừng.

---

## 6. Mẫu câu (Sample Patterns)

### 6.1. Câu khẳng định (Normal)
- "Ăn sáng 25k" -> CHI, Ăn uống, 25000.
- "Mới nhận lương 15tr" -> THU, Lương, 15000000.

### 6.2. Câu chứa từ lóng (Slang)
- "Mất 2 củ sửa xe" -> CHI, Di chuyển, 2000000.
- "Làm thêm được 5 xị" -> THU, Khác, 500000.

### 6.3. Câu có giới từ (Directional)
- "Chuyển cho Mẹ 1 triệu" -> CHI, Người thân, 1000000.
- "Nhận từ sếp 2 lít" -> THU, Thưởng, 200000.
