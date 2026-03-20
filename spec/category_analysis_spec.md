# Đặc tả Chức năng: Phân tích Chuyên sâu theo Danh mục (Category Insight Analysis)

## 1. Mục tiêu
Cung cấp cho người dùng cái nhìn chi tiết và chuyên sâu về hoạt động tài chính (thu hoặc chi) của một danh mục cụ thể trong một khoảng thời gian tùy chọn. Giúp người dùng nắm bắt xu hướng và kiểm soát thói quen tài chính tốt hơn.

## 2. Luồng người dùng (User Flow)
1. Người dùng truy cập vào màn hình **Báo cáo (Report)**.
2. Tại danh sách các danh mục (ví dụ: Ăn uống, Di chuyển...), người dùng nhấn vào biểu tượng **"Phân tích"** (biểu tượng biểu đồ đường) bên cạnh tên danh mục.
3. Ứng dụng chuyển hướng đến màn hình **Phân tích Chuyên sâu Danh mục**.
4. Người dùng chọn khoảng thời gian cần xem (Từ ngày - Đến ngày).
5. Hệ thống hiển thị các số liệu và biểu đồ tương ứng.

## 3. Các thành phần giao diện & Chức năng chi tiết

### 3.1 Bộ lọc thời gian (Time Filter)
- Sử dụng `DateRangePicker` tiếng Việt.
- Mặc định khi mở: Từ ngày đầu tháng hiện tại đến ngày hiện tại.
- Cho phép chọn bất kỳ khoảng thời gian nào trong quá khứ.

### 3.2 Thống kê tổng quan (Quick Stats)
- **Tổng số tiền:** Tổng giá trị giao dịch của danh mục này trong khoảng thời gian đã chọn.
- **Số giao dịch:** Đếm tổng số lần phát sinh giao dịch.
- **Trung bình chi tiêu:** (Tổng tiền) / (Số ngày trong khoảng thời gian đã chọn).
- **Ngày chi nhiều nhất:** Ngày có tổng tiền giao dịch lớn nhất cho danh mục này.

### 3.3 Biểu đồ xu hướng (Trend Chart)
- Loại biểu đồ: **Biểu đồ đường (Line Chart)** sử dụng thư viện `fl_chart`.
- Trục X: Các mốc ngày trong khoảng thời gian đã lọc.
- Trục Y: Số tiền.
- Giúp người dùng thấy được sự biến động (tăng/giảm) của danh mục qua thời gian.

### 3.4 Lịch sử giao dịch chi tiết
- Danh sách tất cả các giao dịch thuộc danh mục này trong khoảng thời gian lọc.
- Mỗi item hiển thị: Tiêu đề, Số tiền, Ngày tháng, Ghi chú (nếu có).

## 4. Đặc tả kỹ thuật (Technical Specs)
- **Màn hình mới:** `CategoryAnalysisScreen` (`lib/screens/category_analysis_screen.dart`).
- **Truy vấn Firestore:**
    - Collection: `users/{uid}/transactions`
    - Filter: `category == [selected_category]`
    - Filter: `timestamp >= [start_date]` và `timestamp <= [end_date]`
    - OrderBy: `timestamp` giảm dần.
- **Đồng bộ hóa:** Dữ liệu cập nhật real-time qua `StreamBuilder`.

## 5. Giai đoạn triển khai dự kiến
1. **Giai đoạn 1:** Xây dựng khung màn hình và bộ lọc thời gian.
2. **Giai đoạn 2:** Tích hợp logic truy vấn dữ liệu và hiển thị các số liệu thống kê.
3. **Giai đoạn 3:** Xây dựng biểu đồ đường (Line Chart).
4. **Giai đoạn 4:** Hiển thị danh sách giao dịch chi tiết và hoàn thiện giao diện (UI).
