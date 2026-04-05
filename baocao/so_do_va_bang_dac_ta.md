# Sơ đồ và bảng mô tả theo `sơ đồ.docx`

## 1. Danh mục sơ đồ đã rà soát

| STT | Tên sơ đồ | Loại | Quy tắc mô tả |
|---|---|---|---|
| 1 | Tổng Quát | Use case | 1 sơ đồ = 1 bảng mô tả |
| 2 | User_Phân Rã | Use case | 1 sơ đồ = 1 bảng mô tả |
| 3 | Admin_Phân Rã | Use case | 1 sơ đồ = 1 bảng mô tả |
| 4 | User_Quản Lý Tài Khoản | Use case | 1 sơ đồ = 1 bảng mô tả |
| 5 | User_Quản Lý Giao Dịch | Use case | 1 sơ đồ = 1 bảng mô tả |
| 6 | User_Quản Lý Danh Mục | Use case | 1 sơ đồ = 1 bảng mô tả |
| 7 | User_Quản Lý Ngân Sách | Use case | 1 sơ đồ = 1 bảng mô tả |
| 8 | User_Quản Lý Mục Tiêu Tiết Kiệm | Use case | 1 sơ đồ = 1 bảng mô tả |
| 9 | User_Báo Cáo Và Cài Đặt | Use case | 1 sơ đồ = 1 bảng mô tả |
| 10 | Admin_Truy Cập Hệ Thống | Use case | 1 sơ đồ = 1 bảng mô tả |
| 11 | Admin_Quản Lý Người Dùng | Use case | 1 sơ đồ = 1 bảng mô tả |
| 12 | Admin_Quản Lý Dữ Liệu Hệ Thống | Use case | 1 sơ đồ = 1 bảng mô tả |
| 13 | Admin_Quản Lý AI | Use case | 1 sơ đồ = 1 bảng mô tả |
| 14 | Admin_Giám Sát Và Báo Cáo | Use case | 1 sơ đồ = 1 bảng mô tả |
| 15 | Class Diagram nghiệp vụ | Class diagram | 1 lớp/thực thể = 1 bảng mô tả |
| 16 | ERD logic Firestore | ERD | 1 thực thể = 1 bảng mô tả |
| 17 | Cấu trúc Cloud Firestore | Sơ đồ dữ liệu | 1 sơ đồ = 1 bảng mô tả |

## 2. Mẫu bảng chuẩn

### 2.1. Mẫu cho sơ đồ use case và sơ đồ cấu trúc

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | ... |
| Loại sơ đồ | Use case / Firestore structure |
| Mục đích | ... |
| Thành phần chính | ... |
| Luồng mô tả | ... |
| Ý nghĩa trong hệ thống | ... |

### 2.2. Mẫu cho class diagram và ERD

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | id | ... |
| 2 | name | ... |
| 3 | ... | ... |

## 3. Bảng mô tả các sơ đồ use case

### 3.1. Bảng mô tả sơ đồ Tổng Quát

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Tổng Quát |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả phạm vi chức năng chung của toàn hệ thống cho hai actor User và Admin. |
| Thành phần chính | Actor User, actor Admin, các use case đăng nhập chung, quản lý tài khoản, giao dịch, danh mục, ngân sách, mục tiêu tiết kiệm, báo cáo, quản trị dữ liệu, AI runtime và giám sát. |
| Luồng mô tả | User truy cập các chức năng nghiệp vụ cá nhân; Admin truy cập các chức năng quản trị; nhiều nhánh đều bao gồm bước đăng nhập chung trước khi đi vào chức năng chi tiết. |
| Ý nghĩa trong hệ thống | Là sơ đồ bao quát nhất, giúp người đọc nhìn được ranh giới giữa phân hệ người dùng và phân hệ quản trị. |

### 3.2. Bảng mô tả sơ đồ User_Phân Rã

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | User_Phân Rã |
| Loại sơ đồ | Use case |
| Mục đích | Phân rã toàn bộ nhóm chức năng phía người dùng thành các mảng nghiệp vụ nhỏ hơn. |
| Thành phần chính | Actor User, các nhóm use case quản lý tài khoản, giao dịch, danh mục, ngân sách, mục tiêu tiết kiệm, báo cáo và cài đặt. |
| Luồng mô tả | User đi từ các nhóm chức năng lớn đến các nhánh bao gồm như quản lý hồ sơ, ghi nhận dòng tiền, thiết lập hạn mức vi mô, lập kế hoạch tiết kiệm, giám sát biểu đồ và tùy biến ứng dụng. |
| Ý nghĩa trong hệ thống | Làm rõ phạm vi nghiệp vụ của mobile app và là cầu nối từ sơ đồ tổng quát sang các sơ đồ user chi tiết. |

### 3.3. Bảng mô tả sơ đồ Admin_Phân Rã

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Admin_Phân Rã |
| Loại sơ đồ | Use case |
| Mục đích | Phân rã nhóm chức năng quản trị thành các khối truy cập, quản lý dữ liệu, AI runtime và giám sát tổng. |
| Thành phần chính | Actor Admin, các use case truy cập hệ thống, quản lý người dùng, quản lý CSDL, quản lý AI runtime và giám sát tổng. |
| Luồng mô tả | Admin đăng nhập và từ đó thực hiện xác thực đa tầng, quản lý tài khoản, thiết lập phân quyền, bảo trì hệ thống, xem log AI, vận hành cấu hình AI và theo dõi số lượng toàn cục. |
| Ý nghĩa trong hệ thống | Cho thấy phân hệ admin không chỉ xem dữ liệu mà còn có vai trò vận hành, giám sát và can thiệp hệ thống. |

### 3.4. Bảng mô tả sơ đồ User_Quản Lý Tài Khoản

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | User_Quản Lý Tài Khoản |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các thao tác liên quan đến vòng đời tài khoản người dùng. |
| Thành phần chính | Actor User, use case quản lý tài khoản, đăng ký, đăng nhập, quên mật khẩu, đăng xuất, cập nhật hồ sơ. |
| Luồng mô tả | User đi vào use case quản lý tài khoản và từ đó thực hiện các thao tác xác thực hoặc cập nhật hồ sơ cá nhân. |
| Ý nghĩa trong hệ thống | Xác định điểm vào của người dùng vào ứng dụng và nhóm chức năng bảo trì hồ sơ cơ bản. |

### 3.5. Bảng mô tả sơ đồ User_Quản Lý Giao Dịch

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | User_Quản Lý Giao Dịch |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các cách người dùng tạo và quản lý giao dịch thu chi. |
| Thành phần chính | Actor User, use case quản lý giao dịch, thêm giao dịch thủ công, thêm bằng AI, thêm bằng OCR, sửa, xóa, xem lịch sử, tìm kiếm và lọc. |
| Luồng mô tả | Từ use case trung tâm quản lý giao dịch, User có thể tạo mới theo nhiều cách hoặc xem, lọc, chỉnh sửa và xóa giao dịch đã có. |
| Ý nghĩa trong hệ thống | Đây là sơ đồ lõi của sản phẩm vì giao dịch là dữ liệu trung tâm chi phối báo cáo, ngân sách và số dư. |

### 3.6. Bảng mô tả sơ đồ User_Quản Lý Danh Mục

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | User_Quản Lý Danh Mục |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả cách người dùng tự quản lý danh mục cá nhân phục vụ nhập liệu giao dịch. |
| Thành phần chính | Actor User, use case quản lý danh mục, tạo, sửa, xóa danh mục cá nhân và chọn danh mục khi tạo giao dịch. |
| Luồng mô tả | User thao tác với danh mục riêng để điều chỉnh cấu trúc phân loại thu chi và sử dụng lại khi ghi nhận giao dịch. |
| Ý nghĩa trong hệ thống | Bảo đảm ứng dụng linh hoạt theo từng người dùng thay vì chỉ phụ thuộc vào danh mục mặc định toàn hệ thống. |

### 3.7. Bảng mô tả sơ đồ User_Quản Lý Ngân Sách

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | User_Quản Lý Ngân Sách |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các thao tác thiết lập và theo dõi ngân sách chi tiêu theo danh mục. |
| Thành phần chính | Actor User, use case quản lý ngân sách, tạo ngân sách tháng, theo dõi mức chi, nhận cảnh báo vượt ngưỡng, xóa ngân sách. |
| Luồng mô tả | User thiết lập hạn mức, hệ thống đối chiếu mức chi theo danh mục và phát cảnh báo khi gần chạm hoặc vượt ngưỡng. |
| Ý nghĩa trong hệ thống | Liên kết trực tiếp giữa giao dịch phát sinh và khả năng kiểm soát chi tiêu của người dùng. |

### 3.8. Bảng mô tả sơ đồ User_Quản Lý Mục Tiêu Tiết Kiệm

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | User_Quản Lý Mục Tiêu Tiết Kiệm |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các thao tác tạo, nạp tiền, rút tiền và theo dõi tiến độ mục tiêu tiết kiệm. |
| Thành phần chính | Actor User, use case quản lý mục tiêu tiết kiệm, tạo mục tiêu, nạp tiền vào mục tiêu, rút tiền, đóng mục tiêu, theo dõi tiến độ. |
| Luồng mô tả | User thiết lập mục tiêu, cập nhật dòng tiền đóng góp và quan sát mức hoàn thành cho từng mục tiêu tiết kiệm. |
| Ý nghĩa trong hệ thống | Tăng chiều sâu cho sản phẩm, mở rộng từ quản lý chi tiêu sang quản lý tích lũy tài chính cá nhân. |

### 3.9. Bảng mô tả sơ đồ User_Báo Cáo Và Cài Đặt

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | User_Báo Cáo Và Cài Đặt |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các chức năng xem báo cáo và điều chỉnh thiết lập phía người dùng. |
| Thành phần chính | Actor User, use case báo cáo và cài đặt, xem thông báo hệ thống, xem phân tích theo danh mục, xem báo cáo tháng, xem giao dịch lớn nhất hoặc nhỏ nhất, xuất PDF, cài đặt giao diện. |
| Luồng mô tả | User đi vào khu báo cáo và cài đặt để đọc số liệu, xem các phân tích tài chính và điều chỉnh trải nghiệm giao diện của ứng dụng. |
| Ý nghĩa trong hệ thống | Là đầu ra trực quan của dữ liệu giao dịch và ngân sách, giúp người dùng chuyển từ ghi nhận sang phân tích. |

### 3.10. Bảng mô tả sơ đồ Admin_Truy Cập Hệ Thống

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Admin_Truy Cập Hệ Thống |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả luồng truy cập cơ bản của quản trị viên vào cổng quản trị. |
| Thành phần chính | Actor Admin, use case truy cập hệ thống, đăng nhập admin, kiểm tra role, kiểm tra permission, đăng xuất. |
| Luồng mô tả | Admin đăng nhập, hệ thống kiểm tra vai trò và quyền, sau đó mới cho phép vào khu quản trị và hỗ trợ đăng xuất an toàn. |
| Ý nghĩa trong hệ thống | Thiết lập lớp kiểm soát đầu vào cho toàn bộ chức năng quản trị. |

### 3.11. Bảng mô tả sơ đồ Admin_Quản Lý Người Dùng

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Admin_Quản Lý Người Dùng |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các tác vụ quản trị tài khoản người dùng trên web admin. |
| Thành phần chính | Actor Admin, use case quản lý người dùng, xem danh sách user, tìm kiếm user, khóa tài khoản, mở khóa tài khoản, xem trạng thái tài khoản, gán role admin, phân quyền chi tiết. |
| Luồng mô tả | Admin truy cập module người dùng để tra cứu, đánh giá trạng thái và thay đổi quyền hoặc khả năng truy cập của từng tài khoản. |
| Ý nghĩa trong hệ thống | Là trung tâm cho chức năng kiểm soát vận hành và an toàn tài khoản ở phía quản trị. |

### 3.12. Bảng mô tả sơ đồ Admin_Quản Lý Dữ Liệu Hệ Thống

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Admin_Quản Lý Dữ Liệu Hệ Thống |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các nhóm dữ liệu vận hành mà admin có quyền quản lý. |
| Thành phần chính | Actor Admin, use case quản lý dữ liệu hệ thống, quản lý thông tin hỗ trợ liên hệ, quản lý danh mục hệ thống, quản lý thông báo hệ thống, quản lý cấu hình hệ thống. |
| Luồng mô tả | Admin làm việc với các dữ liệu dùng chung để điều chỉnh cách hệ thống hoạt động và những gì người dùng cuối nhìn thấy. |
| Ý nghĩa trong hệ thống | Thể hiện chiều sâu vận hành của cổng admin chứ không chỉ dừng ở xem dashboard. |

### 3.13. Bảng mô tả sơ đồ Admin_Quản Lý AI

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Admin_Quản Lý AI |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các thao tác quản trị cấu hình AI runtime và lexicon trên web admin. |
| Thành phần chính | Actor Admin, use case quản lý AI runtime, publish AI runtime config, xem runtime config hiện hành, lưu draft runtime config, quản lý lexicon AI, ghi log thao tác admin. |
| Luồng mô tả | Admin điều chỉnh cấu hình AI, lưu nháp, xem cấu hình hiện hành, publish bản chạy và theo dõi log liên quan đến AI. |
| Ý nghĩa trong hệ thống | Cho thấy AI trong hệ thống được vận hành chủ động, có quy trình draft/publish và giám sát thay vì là khối logic cố định. |

### 3.14. Bảng mô tả sơ đồ Admin_Giám Sát Và Báo Cáo

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Admin_Giám Sát Và Báo Cáo |
| Loại sơ đồ | Use case |
| Mục đích | Mô tả các thao tác theo dõi dữ liệu tổng quan và báo cáo toàn hệ thống của quản trị viên. |
| Thành phần chính | Actor Admin, use case giám sát và báo cáo, xem dashboard tổng quan, xem giao dịch toàn hệ thống, xóa giao dịch mức quản trị, xem báo cáo tổng hợp tháng. |
| Luồng mô tả | Admin quan sát dữ liệu vận hành, truy vết giao dịch toàn cục và xem báo cáo để đưa ra can thiệp quản trị phù hợp. |
| Ý nghĩa trong hệ thống | Là sơ đồ thể hiện vai trò giám sát hệ thống ở mức toàn cục của admin. |

## 4. Bảng mô tả sơ đồ cấu trúc Cloud Firestore

### 4.1. Bảng mô tả sơ đồ Cấu trúc Cloud Firestore

| Thuộc tính | Nội dung |
|---|---|
| Tên sơ đồ | Cấu trúc Cloud Firestore |
| Loại sơ đồ | Firestore structure |
| Mục đích | Mô tả cách tổ chức collection, document và subcollection trong cơ sở dữ liệu Firestore của hệ thống. |
| Thành phần chính | Collection `users`, document `{uid}`, các subcollection `budgets`, `transactions`, `saving_goals`, `contributions`, và các collection dùng chung `system_configs`, `categories`, `system_broadcasts`, `admin_logs`. |
| Luồng mô tả | Dữ liệu cá nhân được neo dưới document người dùng, còn dữ liệu vận hành toàn hệ thống được tách thành các collection dùng chung để admin và ứng dụng cùng khai thác. |
| Ý nghĩa trong hệ thống | Giúp người đọc hiểu cách chuyển từ tư duy NoSQL Firestore sang ERD logic và class diagram ở các phần sau. |

## 5. Bảng mô tả class diagram

### 5.1. Lớp User

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | uid | Mã định danh của đối tượng người dùng trong tầng ứng dụng |
| 2 | name | Tên hiển thị của người dùng |
| 3 | email | Email dùng để xác thực và liên hệ |
| 4 | phone | Số điện thoại hỗ trợ nhận diện hoặc liên hệ |
| 5 | role | Vai trò nghiệp vụ như user hoặc admin |
| 6 | status | Trạng thái tài khoản như active hoặc locked |
| 7 | totalCredit | Tổng thu tích lũy được lớp User quản lý |
| 8 | totalDebit | Tổng chi tích lũy được lớp User quản lý |
| 9 | remainingAmount | Số dư hiện tại của người dùng |
| 10 | createdAt | Thời điểm khởi tạo đối tượng người dùng |

### 5.2. Lớp Transaction

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | transactionId | Mã giao dịch trong tầng nghiệp vụ |
| 2 | title | Tiêu đề ngắn của giao dịch |
| 3 | amount | Giá trị tiền của giao dịch |
| 4 | type | Loại dòng tiền như credit hoặc debit |
| 5 | note | Ghi chú nghiệp vụ đi kèm giao dịch |
| 6 | timestamp | Mốc thời gian của giao dịch |
| 7 | monthyear | Nhãn tháng năm hỗ trợ gom nhóm báo cáo |

### 5.3. Lớp Budget

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | budgetId | Mã nhận diện ngân sách |
| 2 | categoryName | Danh mục được áp dụng hạn mức |
| 3 | limitAmount | Mức chi tối đa được phép trong kỳ |
| 4 | monthyear | Kỳ tháng năm mà ngân sách có hiệu lực |
| 5 | createdAt | Thời điểm tạo ngân sách |

### 5.4. Lớp SavingGoal

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | goalId | Mã nhận diện mục tiêu tiết kiệm |
| 2 | goalName | Tên mục tiêu do người dùng đặt |
| 3 | targetAmount | Số tiền mục tiêu cần đạt |
| 4 | currentAmount | Số tiền đã tích lũy hiện tại |
| 5 | startDate | Ngày bắt đầu mục tiêu |
| 6 | targetDate | Ngày đích dự kiến hoàn thành |
| 7 | status | Trạng thái mục tiêu như active hoặc closed |
| 8 | icon | Biểu tượng hiển thị cho mục tiêu |
| 9 | color | Màu đại diện dùng trên giao diện |

### 5.5. Lớp Contribution

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | contributionId | Mã của một lần đóng góp vào mục tiêu |
| 2 | amount | Số tiền đóng góp |
| 3 | type | Kiểu nghiệp vụ như nạp thêm hoặc rút bớt |
| 4 | note | Ghi chú giải thích giao dịch đóng góp |
| 5 | createdAt | Thời điểm ghi nhận đóng góp |

### 5.6. Lớp QuickTemplate

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | templateId | Mã mẫu giao dịch nhanh |
| 2 | label | Nhãn hiển thị ngắn trên giao diện |
| 3 | title | Tiêu đề giao dịch mặc định |
| 4 | amount | Giá trị tiền gợi ý của mẫu |
| 5 | type | Loại thu hoặc chi của mẫu |
| 6 | category | Danh mục gắn với mẫu |
| 7 | note | Ghi chú mặc định khi áp dụng mẫu |

### 5.7. Lớp UserCategory

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | categoryId | Mã định danh danh mục cá nhân |
| 2 | name | Tên danh mục |
| 3 | type | Loại danh mục như thu hoặc chi |
| 4 | iconName | Tên icon dùng để hiển thị |
| 5 | isDefault | Cho biết danh mục có phải mặc định hay không |

### 5.8. Lớp SystemBroadcast

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | broadcastId | Mã thông báo hệ thống |
| 2 | title | Tiêu đề thông báo |
| 3 | content | Nội dung chi tiết được phát ra |
| 4 | type | Loại thông báo như info hoặc warning |
| 5 | status | Trạng thái hiển thị hay lưu nháp |
| 6 | createdByEmail | Email admin phát thông báo |

### 5.9. Lớp SystemConfig

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | configId | Mã cấu hình hệ thống |
| 2 | configData | Dữ liệu cấu hình tổng hợp của một module |

### 5.10. Lớp GlobalCategory

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | globalCategoryId | Mã danh mục dùng chung toàn hệ thống |
| 2 | name | Tên danh mục toàn cục |
| 3 | type | Loại danh mục thu hoặc chi |
| 4 | iconName | Icon hiển thị cho danh mục mặc định |

### 5.11. Lớp AdminLog

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | logId | Mã nhật ký quản trị |
| 2 | action | Hành động mà admin đã thực hiện |
| 3 | target | Đối tượng bị tác động bởi hành động |
| 4 | adminUid | Mã admin thực hiện thao tác |
| 5 | adminEmail | Email admin thực hiện thao tác |
| 6 | createdAt | Thời điểm tạo bản ghi log |

## 6. Bảng mô tả ERD logic

### 6.1. Thực thể User

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | user_id | Khóa chính định danh duy nhất người dùng |
| 2 | name | Tên hiển thị của người dùng |
| 3 | email | Email đăng nhập và liên hệ |
| 4 | phone | Số điện thoại của người dùng |
| 5 | role | Vai trò như user hoặc admin |
| 6 | status | Trạng thái tài khoản như active hoặc locked |
| 7 | totalCredit | Tổng thu được tổng hợp cho người dùng |
| 8 | totalDebit | Tổng chi được tổng hợp cho người dùng |
| 9 | remainingAmount | Số dư hiện tại của người dùng |
| 10 | createdAt | Thời điểm tạo tài khoản |

### 6.2. Thực thể Transaction

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | transaction_id | Khóa chính của giao dịch |
| 2 | user_id | Khóa ngoại tham chiếu người dùng sở hữu giao dịch |
| 3 | title | Tên giao dịch |
| 4 | amount | Số tiền của giao dịch |
| 5 | type | Loại giao dịch credit hoặc debit |
| 6 | category | Danh mục giao dịch |
| 7 | note | Ghi chú chi tiết |
| 8 | timestamp | Thời điểm phát sinh giao dịch |
| 9 | monthyear | Kỳ tháng năm để tổng hợp báo cáo |

### 6.3. Thực thể Budget

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | budget_id | Khóa chính của ngân sách |
| 2 | user_id | Khóa ngoại tham chiếu chủ sở hữu ngân sách |
| 3 | categoryName | Danh mục áp dụng hạn mức |
| 4 | limitAmount | Mức chi tối đa trong kỳ |
| 5 | monthyear | Tháng năm áp dụng |
| 6 | createdAt | Thời điểm tạo bản ghi ngân sách |

### 6.4. Thực thể SavingGoal

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | goal_id | Khóa chính của mục tiêu tiết kiệm |
| 2 | user_id | Khóa ngoại tham chiếu người dùng tạo mục tiêu |
| 3 | goal_name | Tên mục tiêu tiết kiệm |
| 4 | target_amount | Số tiền mục tiêu cần đạt |
| 5 | current_amount | Số tiền hiện đã tích lũy |
| 6 | start_date | Ngày bắt đầu mục tiêu |
| 7 | target_date | Ngày đích dự kiến |
| 8 | status | Trạng thái mục tiêu |
| 9 | icon | Biểu tượng đại diện |
| 10 | color | Màu nhận diện trên giao diện |
| 11 | created_at | Thời điểm tạo mục tiêu |

### 6.5. Thực thể Contribution

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | contribution_id | Khóa chính của lần đóng góp |
| 2 | goal_id | Khóa ngoại tham chiếu mục tiêu tiết kiệm |
| 3 | user_id | Khóa ngoại tham chiếu người dùng thực hiện đóng góp |
| 4 | amount | Số tiền đóng góp hoặc rút |
| 5 | type | Loại nghiệp vụ của đóng góp |
| 6 | note | Ghi chú cho lần đóng góp |
| 7 | createdAt | Thời điểm tạo bản ghi đóng góp |

### 6.6. Thực thể QuickTemplate

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | template_id | Khóa chính của mẫu giao dịch nhanh |
| 2 | user_id | Khóa ngoại tham chiếu người dùng sở hữu mẫu |
| 3 | label | Nhãn ngắn của mẫu |
| 4 | title | Tiêu đề giao dịch mặc định |
| 5 | amount | Số tiền gợi ý |
| 6 | type | Loại giao dịch mặc định |
| 7 | category | Danh mục áp dụng cho mẫu |
| 8 | note | Ghi chú đi kèm |
| 9 | iconName | Icon đại diện cho mẫu |

### 6.7. Thực thể UserCategory

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | category_id | Khóa chính của danh mục cá nhân |
| 2 | user_id | Khóa ngoại tham chiếu người dùng sở hữu danh mục |
| 3 | name | Tên danh mục |
| 4 | type | Loại danh mục thu hoặc chi |
| 5 | iconName | Tên icon hiển thị |
| 6 | isDefault | Cờ cho biết danh mục mặc định hay do người dùng tạo |
| 7 | updatedAt | Thời điểm cập nhật gần nhất |

### 6.8. Thực thể GlobalCategory

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | global_category_id | Khóa chính của danh mục toàn hệ thống |
| 2 | name | Tên danh mục mặc định |
| 3 | type | Loại danh mục thu hoặc chi |
| 4 | iconName | Icon hiển thị của danh mục |
| 5 | createdAt | Thời điểm tạo danh mục |
| 6 | updatedAt | Thời điểm cập nhật gần nhất |

### 6.9. Thực thể SystemBroadcast

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | broadcast_id | Khóa chính của thông báo hệ thống |
| 2 | title | Tiêu đề thông báo |
| 3 | content | Nội dung chi tiết |
| 4 | type | Loại thông báo |
| 5 | status | Trạng thái phát hành |
| 6 | createdAt | Thời điểm tạo thông báo |
| 7 | updatedAt | Thời điểm cập nhật thông báo |
| 8 | createdByEmail | Email admin đã tạo thông báo |

### 6.10. Thực thể SystemConfig

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | config_id | Khóa chính của cấu hình hệ thống |
| 2 | configData | Dữ liệu cấu hình được lưu dưới dạng tổng hợp |

### 6.11. Thực thể AdminLog

| STT | Thuộc tính | Mô tả ngắn |
|---|---|---|
| 1 | log_id | Khóa chính của bản ghi log quản trị |
| 2 | action | Hành động được thực hiện |
| 3 | target | Đối tượng bị tác động |
| 4 | adminUid | Mã admin thực hiện thao tác |
| 5 | adminEmail | Email admin thực hiện thao tác |
| 6 | createdAt | Thời điểm tạo log |

## 7. Ghi chú đối chiếu

1. Các bảng use case ở mục 3 được viết đúng theo từng sơ đồ use case trong `sơ đồ.docx`.
2. Class diagram ở mục 5 được mô tả theo góc nhìn lớp nghiệp vụ, dùng tên lớp và thuộc tính đúng với sơ đồ lớp.
3. ERD ở mục 6 được mô tả theo góc nhìn thực thể dữ liệu, ưu tiên tên khóa chính, khóa ngoại và trường lưu trữ trong sơ đồ ERD.
4. Nội dung thực thể đã được đối chiếu với `bang_erd_quy_doi_thuc_the.docx`, `quan_ly_tai_chinh_staruml_sample.mdj` và các model chính trong `lib/models/`.
