# AI Logic Behavior Specification - Finance App

## 1. Mục tiêu
Xác định cách thức xử lý ngôn ngữ tự nhiên (NLP) của AI khi người dùng nhập liệu qua text hoặc giọng nói, đảm bảo tính chính xác về tài chính và sự thân thiện trong giao tiếp.

## 2. Các quy tắc xử lý (Handling Rules)

### R1: Xử lý đầu vào phi giao dịch (Nonsense/Social)
- **Dấu hiệu:** Không chứa số tiền hoặc hành động tài chính rõ ràng.
- **Phản hồi:** Hóm hỉnh, dẫn dắt người dùng quay lại mục đích chính (quản lý tiền).
- **Ví dụ:** "Bạn là ai?" -> "Tôi là trợ lý ví tiền của bạn. Hãy kể tôi nghe bạn vừa tiêu gì, tôi sẽ ghi lại giúp!"

### R2: Chia tách đa giao dịch (Multi-transaction Splitting)
- **Dấu hiệu:** Chứa nhiều cụm danh từ + số tiền nối nhau bởi dấu phẩy, từ nối (với, rồi, sau đó) hoặc xuống dòng.
- **Logic:** Tách thành mảng các object giao dịch.
- **Phản hồi:** Liệt kê tóm tắt các giao dịch đã tách để người dùng xác nhận nhanh.

### R3: Tự động điền và gợi ý (Auto-fill & Suggestion)
- **Số tiền:** Nhận diện các đơn vị (k, tr, triệu, củ, lốp). Ví dụ: "50k" -> 50,000.
- **Loại (Type):** 
    - Từ khóa: "Lương", "Thưởng", "Được cho", "Thu" -> `credit` (Thu nhập).
    - Từ khóa: "Ăn", "Mua", "Trình", "Mất", "Trả" -> `debit` (Chi tiêu).
- **Danh mục (Category):** Map từ khóa vào icon/category có sẵn (Ví dụ: "Phở" -> Ăn uống).

### R4: Kiểm tra tính hợp lệ (Validation & Sanity Check)
- **Giá trị âm:** Chuyển về số dương và dựa vào ngữ nghĩa để chọn `type`.
- **Giá trị bất thường:** Nếu số tiền > 100,000,000 (100 triệu) cho một giao dịch đơn lẻ, yêu cầu xác nhận lại bằng giọng điệu hài hước.

### R5: Ngữ cảnh thời gian (Temporal Context)
- "Hôm qua", "Hôm kia", "Thứ 2 vừa rồi" -> Tự động tính toán lại `timestamp`.

## 3. Danh sách phản hồi mẫu (Sample Persona Responses)

| Input | AI Response Tone |
| :--- | :--- |
| "Ăn gì ngon?" | "Em chỉ biết 'ăn' dữ liệu thôi, bác đi ăn gì ngon thì nhớ ghi lại để em quản lý ví tiền giúp nhé! 😉" |
| "Ck cho bồ 200k" | "Đã ghi nhận 'đầu tư' 200k cho bồ. Hy vọng khoản đầu tư này có lãi (tình cảm) nhé bác!" |
| "500.000.000.000" | "Con số này làm em 'lác mắt' luôn! Bác kiểm tra lại xem có bấm thừa số 0 nào không, hay bác vừa trúng Vietlott thật?" |

## 4. Cấu trúc dữ liệu đầu ra (Output Schema)
AI Service phải trả về định dạng JSON:
```json
{
  "status": "success | error | clarification",
  "message": "Lời nhắn của AI",
  "data": [
    {
      "title": "String",
      "amount": number,
      "type": "credit | debit",
      "category": "String",
      "note": "String",
      "date": "ISO String"
    }
  ]
}
```
