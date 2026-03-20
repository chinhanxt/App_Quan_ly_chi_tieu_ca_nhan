# ĐẶC TẢ YÊU CẦU: TRIỂN KHAI CHẾ ĐỘ SÁNG TỐI (DARK MODE) TOÀN CỤC
# Tệp này lưu trữ kế hoạch và yêu cầu để tích hợp tính năng đổi giao diện.
# (Ghi chú: Chức năng Đa ngôn ngữ đã bị loại bỏ khỏi dự án theo yêu cầu).

## 1. Mục tiêu
- **Chế độ Sáng/Tối (Dark Mode):** Hoạt động mượt mà, áp dụng toàn bộ app khi bật/tắt công tắc trong màn hình Cài đặt (`SettingsScreen`) mà không cần khởi động lại. Tự động ghi nhớ lại lựa chọn của người dùng.

## 2. Kiến trúc & Công nghệ
- **Quản lý trạng thái:** Sử dụng gói `provider` của Flutter để tạo một `SettingsProvider` nhằm quản lý trạng thái Sáng/Tối tại tầng Root (`main.dart`).
- **Lưu trữ cục bộ:** Sử dụng `SharedPreferences` để lưu lại giá trị `isDarkMode`, giúp giữ nguyên chế độ đã chọn cho những lần mở ứng dụng tiếp theo.

## 3. Các bước triển khai chi tiết (Todo List)

### Giai đoạn 1: Thiết lập Quản lý Trạng thái (State Management)
1. **Dọn dẹp tệp cấu hình:**
   - Xóa bỏ các cấu hình liên quan đến `flutter_localizations` và `generate: true` trong `pubspec.yaml` (nếu còn sót).
   - Đảm bảo `provider` được khai báo trong `pubspec.yaml`.
2. **Tạo `SettingsProvider`:**
   - Tạo file `lib/providers/settings_provider.dart`.
   - Lớp này kế thừa `ChangeNotifier` chứa biến `ThemeMode themeMode`.
   - Có hàm khởi tạo (để load từ `SharedPreferences`) và hàm `toggleTheme` để đảo đổi trạng thái và lưu lại.

### Giai đoạn 2: Tích hợp vào UI (Giao diện)
1. **Sửa đổi `main.dart`:**
   - Bao bọc toàn bộ `MyApp` bằng `ChangeNotifierProvider` (gọi `SettingsProvider`).
   - Sửa `MaterialApp` để lắng nghe `themeMode` từ `SettingsProvider`.
   - Bổ sung cấu hình `darkTheme` (ví dụ: `ThemeData.dark()`) và `theme` (ví dụ: `ThemeData.light()`) một cách đồng bộ.
2. **Sửa đổi `SettingsScreen` (`lib/screens/settings_screen.dart`):**
   - Loại bỏ biến `isDarkMode` và hàm `_saveSettings` cục bộ.
   - Kết nối `SwitchListTile` tới trạng thái toàn cục bằng cách gọi `Provider.of<SettingsProvider>(context, listen: false).toggleTheme()`.

## 4. Xác nhận tiến trình
- Khi hoàn tất Giai đoạn 1 và 2, người dùng chỉ cần gạt nút trong Cài đặt là ứng dụng sẽ ngay lập tức đổi màu Sáng <-> Tối.
- Dữ liệu sẽ tự động được lưu và tải lên vào lần chạy kế tiếp.

---
**Trạng thái hiện tại:** Đã cập nhật file đặc tả (Xóa Đa ngôn ngữ, giữ Dark mode). Đang dọn dẹp các file rác sinh ra từ quy trình trước và thiết lập `SettingsProvider` cho Dark Mode.