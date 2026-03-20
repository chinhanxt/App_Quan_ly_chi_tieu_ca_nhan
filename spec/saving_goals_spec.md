# Đặc tả Chức năng: Kế hoạch Mục tiêu Tiết kiệm (Saving Goals Planning)

## 1. Tổng quan
Cung cấp công cụ giúp người dùng lập kế hoạch và thực hiện tiết kiệm tiền cho các mục đích cụ thể (ví dụ: mua sắm, du lịch). Hệ thống sử dụng cơ chế "Giao dịch ảo" để tách biệt tiền tiết kiệm khỏi số dư khả dụng.

## 2. Cơ chế Tài chính (Virtual Transaction Logic)
- **Hành động Góp tiền:** 
    - `Số dư khả dụng` (users/{uid}/remainingAmount) **GIẢM**.
    - `Số tiền mục tiêu hiện có` (current_amount) **TĂNG**.
- **Hành động Rút tiền (Khi hoàn thành hoặc hủy):**
    - `Số dư khả dụng` **TĂNG**.
    - `Số tiền mục tiêu hiện có` **GIẢM**.

## 3. Cấu trúc Dữ liệu (Firestore)
### Collection: `users/{uid}/saving_goals`
- `goal_id`: String (Mã duy nhất)
- `goal_name`: String (Tên mục tiêu)
- `target_amount`: Number (Số tiền cần đạt được)
- `current_amount`: Number (Số tiền đã góp)
- `start_date`: Timestamp (Ngày bắt đầu)
- `target_date`: Timestamp (Ngày dự kiến hoàn thành)
- `icon`: String (Mã icon đại diện)
- `color`: String (Mã màu HEX)
- `status`: String ('active' | 'completed' | 'withdrawn')
- `created_at`: Timestamp

## 4. Công thức Tính toán Thông minh
- **Tiền còn thiếu:** `remaining_to_save = target_amount - current_amount`
- **Thời gian còn lại:** `days_left = target_date - today` (số ngày)
- **Gợi ý tiết kiệm hàng ngày:** `daily_saving_required = remaining_to_save / days_left`
- **Tiến độ:** `progress_percent = (current_amount / target_amount) * 100`

## 5. Luồng Người dùng & Giao diện

### 5.1 Trang chủ (Home Screen Widget)
- Hiển thị danh sách ngang **Top 3 Mục tiêu** quan trọng nhất.
- Mỗi thẻ hiển thị: Tên, Icon, % Progress Bar, Số tiền còn thiếu (VND).

### 5.2 Màn hình Quản lý Mục tiêu (Saving Goals Screen)
- Danh sách tất cả các mục tiêu (Đang thực hiện & Đã hoàn thành).
- Nút **"Tạo Mục tiêu mới"**: Form nhập tên, số tiền, chọn ngày đích và icon.
- Xem chi tiết: Biểu đồ lịch sử góp tiền và lời khuyên thông minh dựa trên `daily_saving_required`.

### 5.3 Xử lý khi Đạt mục tiêu
Khi `current_amount >= target_amount`:
- Thông báo chúc mừng người dùng.
- **Option 1 (Rút tiền):** Cộng tiền ngược lại vào `remainingAmount`, đổi trạng thái thành `withdrawn`.
- **Option 2 (Giữ tiền):** Đổi trạng thái thành `completed`, tiền vẫn nằm trong quỹ tiết kiệm.

## 6. Thống kê dành cho Admin (Admin Dashboard Update)
Admin xem báo cáo tổng quát (không xem chi tiết cá nhân):
- **Users with goals:** Tổng số người dùng có ít nhất 1 mục tiêu.
- **Total system saving:** Tổng số tiền hiện đang nằm trong tất cả các mục tiêu toàn hệ thống.
- **Goal completion rate:** Tỷ lệ (%) mục tiêu đã hoàn thành trên tổng số mục tiêu đã tạo.

## 7. Kế hoạch Triển khai
1. Cập nhật Model và tạo sub-collection `saving_goals`.
2. Xây dựng màn hình danh sách và Form tạo mục tiêu.
3. Triển khai logic "Góp tiền" (Cập nhật đồng thời Goal và User Balance).
4. Tích hợp Widget vào Trang chủ.
5. Cập nhật thống kê cho Admin.
