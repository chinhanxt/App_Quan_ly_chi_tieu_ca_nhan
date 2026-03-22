# Kế hoạch Phục hồi và Nâng cấp Ứng dụng (App Restoration Spec)

Tài liệu này mô tả chi tiết các yêu cầu kỹ thuật để phục hồi chức năng của ứng dụng, đảm bảo tính năng AI hoạt động mượt mà, quản lý danh mục theo logic cũ (Real-time), và sửa lỗi logic hiển thị số dư.

## 1. Mục tiêu Cốt lõi
1.  **AI Real-time:** Phản hồi tức thì, hiểu ngôn ngữ tự nhiên, cập nhật danh mục mới nhất ngay lập tức.
2.  **Danh mục (Category) Real-time:** Khôi phục logic cũ: Admin đẩy danh mục mặc định -> User thấy ngay. User thêm danh mục -> Dropdown cập nhật ngay lập tức.
3.  **Logic Admin & Dashboard:** Hiển thị số dư chính xác tuyệt đối. Mọi thao tác (User/Admin) thay đổi giao dịch phải cập nhật số dư User ngay lập tức.
4.  **Hiệu năng:** Loại bỏ độ trễ (lag), đảm bảo trải nghiệm mượt mà.

---

## 2. Chi tiết Kỹ thuật

### 2.1. Quản lý Danh mục (Category Management) - "Logic Cũ"
**Hiện trạng:** Đang có sự không đồng nhất giữa `Db.dart` (dùng Subcollection) và `CategoryService.dart` (dùng Array trong User Document).
**Giải pháp:** Chuẩn hóa về mô hình **Hybrid Stream** để đảm bảo Real-time và khả năng mở rộng.

#### Cấu trúc Dữ liệu (Firestore)
1.  **Global Categories (Mặc định từ Admin):**
    *   Path: `categories/{categoryId}`
    *   Quyền: Admin (Write), All Users (Read).
    *   Dữ liệu: `{ name, type, iconName, isDefault: true }`
2.  **User Categories (Danh mục riêng của User):**
    *   Path: `users/{userId}/categories/{categoryId}`
    *   Quyền: User (Read/Write).
    *   Dữ liệu: `{ name, type, iconName, isDefault: false }`

#### Logic `CategoryService`
*   **Phương thức:** `Stream<List<CategoryOption>> getCategoriesStream(String userId)`
*   **Cơ chế:**
    1.  Lắng nghe `Stream` từ collection `categories` (Global).
    2.  Lắng nghe `Stream` từ collection `users/{userId}/categories` (User).
    3.  Sử dụng `Rx.combineLatest2` (hoặc `StreamZip`/`StreamGroup` từ `rxdart` hoặc `async`) để gộp 2 luồng này thành một danh sách duy nhất.
    4.  Loại bỏ trùng lặp (nếu có) dựa trên `name` + `type`.
*   **Tác dụng:** Khi Admin thêm danh mục mới HOẶC User thêm danh mục mới -> Dropdown tự động cập nhật ngay lập tức không cần reload.

### 2.2. Chức năng AI (AI Service)
**Mục tiêu:** Nhanh, Chính xác, Real-time.

#### Cải tiến `AIService`
*   **Input:** Text hoặc Voice (chuyển thành Text).
*   **Processing:**
    *   Vẫn giữ logic `local_parse` để đảm bảo tốc độ (không phụ thuộc API bên thứ 3 trừ khi cần thiết).
    *   **QUAN TRỌNG:** Truyền danh sách Category *mới nhất* từ `CategoryService` vào hàm xử lý AI. Hiện tại `_getAvailableCategories` chỉ fetch 1 lần (Future). Cần đổi sang lấy giá trị mới nhất từ Stream hoặc cache được cập nhật liên tục.
*   **Flow:**
    1.  User nói: "Ăn sáng 30k" -> `AIInputScreen` nhận text.
    2.  `AIInputScreen` lấy danh sách Category hiện tại (từ Provider/Stream).
    3.  Gọi `AIService.processInput(text, currentCategories)`.
    4.  Trả về kết quả -> User xác nhận -> Ghi vào DB.

### 2.3. Logic Dashboard & Admin (Tính toán Số dư)
**Vấn đề:** Số dư bị sai lệch do logic cập nhật không đồng bộ hoặc thiếu sót (đặc biệt khi Admin xóa giao dịch).

#### Nguyên tắc "Single Source of Truth"
*   Số dư (`remainingAmount`), Thu (`totalCredit`), Chi (`totalDebit`) được lưu tại `users/{userId}`.
*   **MỌI** thao tác ghi/xóa/sửa giao dịch (Transaction) **BẮT BUỘC** phải dùng **Firestore Transaction** (hoặc Batch Write có tính toán) để cập nhật đồng thời các chỉ số này.

#### Các logic cần rà soát & sửa:
1.  **User Thêm Giao dịch:** `Db.addTransaction` -> Cộng/Trừ vào `users/{userId}`.
2.  **User Sửa Giao dịch:** `Db.updateTransaction` -> Hoàn tác số cũ, áp dụng số mới vào `users/{userId}`.
3.  **User Xóa Giao dịch:** `Db.deleteTransaction` -> Hoàn tác số cũ vào `users/{userId}`.
4.  **Admin Xóa Giao dịch (Bug Critical):**
    *   Hàm `deleteTransactionForUser` hiện tại chỉ xóa doc -> **SAI**.
    *   **Sửa:** Phải đọc transaction đó trước, lấy `amount` và `type`, sau đó tính toán ngược lại vào `users/{uid}` rồi mới xóa.

### 2.4. Real-time UI
*   **HeroCard (Số dư):** Đã dùng `StreamBuilder` (Tốt). Cần đảm bảo data `users/{uid}` luôn đúng.
*   **Transaction List:** Phải dùng `StreamBuilder` lắng nghe `users/{uid}/transactions`.
*   **Dropdown Danh mục:** Phải dùng `StreamBuilder` lắng nghe `CategoryService.stream`.

---

## 3. Kế hoạch Thực hiện (Action Plan)

### Bước 1: Sửa chữa Core Database Logic (`Db.dart`)
1.  Viết lại hàm `initializeUserCategories` để đảm bảo tạo subcollection `categories` nếu chưa có (migrating từ mảng `customCategories` nếu cần).
2.  Sửa lỗi `deleteTransactionForUser` (Admin function): Thêm logic cập nhật số dư User.
3.  Rà soát `addTransaction`, `updateTransaction` đảm bảo tính toán đúng.

### Bước 2: Nâng cấp `CategoryService`
1.  Chuyển `loadAvailableCategories` (Future) thành `categoriesStream` (Stream).
2.  Kết hợp Stream Global và Stream User.
3.  Cập nhật UI `AddTransactionScreen` và các màn hình chọn danh mục để dùng Stream này.

### Bước 3: Tối ưu AI Service
1.  Cập nhật `AIService` để nhận danh sách Category từ Stream (hoặc tham số truyền vào từ UI đã có data mới nhất).
2.  Đảm bảo `AIInputScreen` phản hồi tức thì.

### Bước 4: Kiểm thử (Testing)
1.  Test case 1: Admin thêm Category "Test Admin" -> User mở app thấy ngay trong Dropdown.
2.  Test case 2: User thêm Category "Test User" -> Dropdown cập nhật ngay.
3.  Test case 3: User thêm giao dịch 100k -> Số dư Dashboard giảm 100k ngay lập tức.
4.  Test case 4: Admin xóa giao dịch 100k của User -> Số dư Dashboard tăng lại 100k ngay lập tức.
