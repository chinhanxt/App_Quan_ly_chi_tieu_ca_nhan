# Tài liệu Đặc tả Chức năng Chế độ Admin (Admin Mode Specification)

## 1. Tổng quan
Tài liệu này mô tả các chức năng và luồng xử lý cho Chế độ Admin trong ứng dụng quản lý tài chính. Chế độ này dành riêng cho quản trị viên hệ thống để giám sát người dùng, dữ liệu và cấu hình ứng dụng.

## 2. Phân quyền Người dùng (Roles)
Hệ thống sử dụng hai vai trò chính:
- **User:** Người dùng thông thường, chỉ có quyền truy cập vào dữ liệu cá nhân của mình.
- **Admin:** Quản trị viên, có toàn quyền truy cập vào các chức năng quản lý hệ thống và xem dữ liệu tổng hợp.

## 3. Chức năng Đăng nhập & Điều hướng
- **Màn hình đăng nhập chung:** Admin và User sử dụng cùng một màn hình đăng nhập.
- **Xác thực vai trò:** Sau khi đăng nhập bằng Firebase Auth, hệ thống sẽ truy vấn thông tin user từ Firestore để lấy trường `role`.
- **Điều hướng:**
    - Nếu `role == 'admin'`, chuyển hướng đến `AdminDashboard`.
    - Nếu `role == 'user'`, chuyển hướng đến `Dashboard` (người dùng).
- **Trạng thái tài khoản:** Nếu tài khoản có `status == 'locked'`, hệ thống sẽ thông báo lỗi và không cho phép vào ứng dụng.

## 4. Các chức năng chi tiết của Admin

### 4.1 Quản lý Người dùng
- **Danh sách User:** Hiển thị tất cả người dùng trong hệ thống (Tên, Email, Vai trò, Trạng thái).
- **Tìm kiếm/Lọc:** Tìm kiếm người dùng theo email hoặc tên.
- **Chỉnh sửa:** Thay đổi vai trò (User <-> Admin).
- **Khóa tài khoản:** Có khả năng khóa hoặc mở khóa tài khoản người dùng.
- **Xóa tài khoản:** Xóa thông tin người dùng khỏi hệ thống (cần xác nhận kỹ).

### 4.2 Quản lý Danh mục (Categories)
- **Danh mục hệ thống:** Quản lý tập hợp các danh mục mặc định (Ăn uống, Di chuyển, Giải trí...) mà mọi người dùng mới sẽ nhận được.
- **CRUD:** Thêm, sửa, xóa các danh mục dùng chung.

### 4.3 Quản lý Giao dịch
- **Xem toàn bộ:** Admin có thể xem danh sách tất cả các khoản thu/chi của mọi người dùng trong hệ thống để kiểm soát nội dung.
- **Xóa/Sửa:** Có quyền can thiệp vào các giao dịch nếu phát hiện dữ liệu bất thường hoặc vi phạm quy định.

### 4.4 Thống kê Hệ thống (Statistics)
- **Tổng quan:** Tổng số lượng người dùng, tổng số giao dịch.
- **Tài chính:** Tổng số tiền thu vào và chi ra trên toàn hệ thống theo thời gian (tháng/năm).
- **Biểu đồ:** Hiển thị xu hướng tăng trưởng người dùng và hoạt động giao dịch.

### 4.5 Cấu hình Hệ thống
- **Thiết lập:** Cài đặt tiền tệ mặc định, quản lý danh sách các mẹo tài chính (Financial Tips) hiển thị trong app.
- **Backup:** Công cụ hỗ trợ xuất dữ liệu hệ thống để sao lưu.

## 5. Cấu trúc Database dự kiến (Firestore)

### Collection: `users`
- `id`: String (UID từ Firebase Auth)
- `email`: String
- `name`: String
- `role`: String ('admin' | 'user')
- `status`: String ('active' | 'locked')
- `createdAt`: Timestamp
- ... (các trường hiện có)

### Collection: `categories` (Global)
- `id`: String
- `name`: String
- `icon`: String
- `type`: String ('credit' | 'debit')
- `isDefault`: Boolean

### Collection: `system_config`
- Document `settings`:
    - `currency`: String
    - `tips`: Array<String>
    - `updatedAt`: Timestamp

## 6. Kế hoạch Triển khai
1. Cập nhật mã nguồn `AuthService` và `Db` để hỗ trợ `role` và `status`.
2. Tạo giao diện `AdminDashboard` cơ bản.
3. Triển khai lần lượt các màn hình quản lý (User, Category, Transaction).
4. Tích hợp thống kê và biểu đồ.
