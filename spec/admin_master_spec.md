# MASTER SPECIFICATION: IN-APP ADMIN SYSTEM (LEAN VERSION)

**Project:** Personal Finance App  
**Strategy:** In-App Integration (No separate web portal)  
**Status:** Optimized for Speed  

---

## 1. KIẾN TRÚC TỐI ƯU (OPTIMIZED ARCHITECTURE)

### 1.1 Nguyên lý "Admin nằm trong App"
*   Hệ thống Admin là một tính năng ẩn bên trong ứng dụng chính.
*   **Entry Point:** Tại màn hình `Settings`, nếu phát hiện `user.role == 'admin'`, hiển thị thêm một nút "Admin Console" ở dưới cùng.
*   **Lợi ích:** Tái sử dụng 100% code `auth_service`, `db`, và theme của app.

### 1.2 Cấu trúc dữ liệu (Firestore)

#### A. Collection `users` (Hiện có)
*   Thêm field: `role: 'user' | 'admin'` (Mặc định là 'user').

#### B. Collection `system_configs` (Mới)
Dùng để chứa toàn bộ cấu hình động của App.
*   **Doc `ai_lexicon`:**
    ```json
    {
      "synonyms": { "cf": "coffee", "an sang": "breakfast" },
      "last_updated": 1715000000
    }
    ```
*   **Doc `global_templates`:** Danh sách các template chi tiêu mẫu.

#### C. Collection `notifications` (Mới - Thay cho Broadcast Hub phức tạp)
*   Dùng để gửi thông báo. App client sẽ lắng nghe collection này.
*   Fields: `title`, `body`, `target` ('all', 'android', 'ios'), `createdAt`.

---

## 2. TÍNH NĂNG CHI TIẾT (FEATURE SPECS)

### 2.1 📊 Admin Dashboard (Bento Grid Lite)
*Mục tiêu: Hiển thị chỉ số quan trọng, không cần vẽ biểu đồ quá phức tạp nếu tốn thời gian.*

*   **Layout:** Sử dụng `flutter_staggered_grid_view` hoặc `Column` kết hợp `Row`.
*   **Các thẻ (Cards):**
    1.  **Total Users:** Đếm số docs trong collection `users` (Chạy Cloud Function trigger counter hoặc đếm client nếu ít user).
    2.  **System Health:** Trạng thái kết nối Firebase.
    3.  **Quick Actions:** Các nút bấm to để vào các tính năng con (Config AI, Gửi tin).

### 2.2 🧠 AI Configuration Manager
*Thay thế cho "Training Center" phức tạp.*

*   **Chức năng:** Là một JSON Editor đơn giản hoặc Key-Value List Editor.
*   **Luồng:**
    1.  Admin mở màn hình.
    2.  App load `system_configs/ai_lexicon`.
    3.  Admin thêm cặp từ khóa: "trà đá" -> "cafe".
    4.  Bấm Save -> Update Firestore.
*   **Client Side:** Khi user thường mở app, app check `last_updated` của config. Nếu mới hơn local -> Tải về và update logic nhận diện chi tiêu.

### 2.3 📢 Simple Broadcast
*Gửi thông báo nội bộ ứng dụng (In-app Notification).*

*   **Giao diện:** Form nhập Title, Body.
*   **Hành động:** Khi bấm Gửi -> Ghi một document mới vào collection `notifications`.
*   **Client Side:**
    *   Lắng nghe stream `notifications` (limit 1, order by desc).
    *   Nếu có thông báo mới (so sánh ID đã đọc) -> Hiển thị Dialog hoặc Banner.

### 2.4 👥 User Management (Basic)
*   **Giao diện:** List view danh sách user.
*   **Chức năng:**
    *   Xem thông tin cơ bản (Email, Ngày tham gia).
    *   **Ban User:** Đổi `status` thành `banned`. (Cần update `AuthService` để chặn login nếu status là banned).

---

## 3. KẾ HOẠCH THỰC HIỆN (TODO LIST)

### Phase 1: Core & Dashboard (1-2 ngày)
1.  [Firestore] Add field `role: 'admin'` thủ công cho tài khoản của bạn.
2.  [Code] Update `UserModel` để parse field `role`.
3.  [Code] Tạo `AdminRouteGuard` (Check role trước khi navigate).
4.  [UI] Tạo màn hình `AdminDashboardScreen` với layout cơ bản.
5.  [UI] Thêm entry point vào `SettingsScreen`.

### Phase 2: AI Config (1 ngày)
1.  [Firestore] Tạo doc `system_configs/ai_lexicon`.
2.  [UI] Tạo màn hình `LexiconEditorScreen` (CRUD List String).
3.  [Logic] Update `AIService` để đọc config từ Firestore thay vì hard-code.

### Phase 3: User Manager (Optional)
1.  [UI] Màn hình list users.
2.  [Logic] Hàm `getAllUsers()` (Lưu ý: Chỉ admin mới gọi được hàm này, cần set Firestore Rules).
