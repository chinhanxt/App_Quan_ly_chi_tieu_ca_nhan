# Tài liệu Đặc tả: Chi tiết Mục tiêu Tiết kiệm (Saving Goal Detail)

## 1. Mục tiêu
Nâng cấp trải nghiệm người dùng bằng cách cung cấp cái nhìn chi tiết về tiến độ tiết kiệm theo từng ngày thông qua giao diện lịch.

## 2. Cấu trúc dữ liệu mới
Thêm bộ sưu tập con (sub-collection) `contributions` vào mỗi tài liệu trong `saving_goals`.

### Thực thể: `Contribution`
- `id`: String (UUID)
- `amount`: int (Số tiền nạp)
- `date`: Timestamp (Ngày nạp tiền)
- `createdAt`: Timestamp (Thời điểm tạo bản ghi)

## 3. Các thay đổi chính

### 3.1. Cập nhật Luồng nạp tiền (SavingGoalsScreen)
- Khi người dùng nạp tiền thành công qua `_showAddMoneyDialog`:
    - Ngoài việc cập nhật `current_amount` và `status` của mục tiêu, hệ thống sẽ thêm một bản ghi mới vào sub-collection `contributions`.

### 3.2. Màn hình Chi tiết Mục tiêu (SavingGoalDetailScreen)
- **Thông tin tổng quan:** Hiển thị tên mục tiêu, icon, tiến độ (%) và số tiền đã tiết kiệm/mục tiêu.
- **Giao diện Lịch (TableCalendar):**
    - Hiển thị từ `startDate` đến `targetDate` của mục tiêu.
    - Đánh dấu các ngày có trong danh sách `contributions`.
    - Ngôn ngữ: Tiếng Việt.
- **Tương tác trên Lịch:**
    - Khi click vào một ngày:
        - Nếu có tiết kiệm: Hiển thị Dialog/SnackBar thông báo tổng số tiền nạp trong ngày đó.
        - Nếu không có: Thông báo "Không có khoản tiết kiệm nào trong ngày này".

### 3.3. Luồng điều hướng
- Tại `SavingGoalsScreen`, thay đổi sự kiện click vào thẻ mục tiêu:
    - Trước đây: Không có hoặc chỉ hiện nút.
    - Hiện tại: Click vào toàn bộ thẻ sẽ dẫn đến `SavingGoalDetailScreen`.

## 4. Công nghệ sử dụng
- Thư viện: `table_calendar` để hiển thị lịch.
- Firebase Firestore: Quản lý sub-collection.
