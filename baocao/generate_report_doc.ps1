$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bao_cao_6_chuong.docx"

function Add-Paragraph {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text,
        [int]$FontSize = 13,
        [bool]$Bold = $false,
        [int]$Alignment = 0,
        [int]$SpaceAfter = 6
    )

    $p = $Doc.Content.Paragraphs.Add()
    $p.Range.Text = $Text
    $p.Range.Font.Name = 'Times New Roman'
    $p.Range.Font.Size = $FontSize
    $p.Range.Font.Bold = [int]$Bold
    $p.Alignment = $Alignment
    $p.SpaceAfter = $SpaceAfter
    $p.Range.InsertParagraphAfter() | Out-Null
}

function Add-Heading1 {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text
    )

    Add-Paragraph -Doc $Doc -Text $Text -FontSize 16 -Bold $true -Alignment 1 -SpaceAfter 10
}

function Add-Heading2 {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text
    )

    Add-Paragraph -Doc $Doc -Text $Text -FontSize 14 -Bold $true -SpaceAfter 8
}

function Add-Note {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text
    )

    Add-Paragraph -Doc $Doc -Text "[BỔ SUNG SƠ ĐỒ/HÌNH ẢNH: $Text]" -FontSize 12 -Bold $true -SpaceAfter 8
}

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    $selection = $word.Selection
    $selection.WholeStory()
    $selection.Font.Name = 'Times New Roman'
    $selection.Font.Size = 13

    Add-Heading1 -Doc $doc -Text 'BÁO CÁO MÔN CÔNG NGHỆ PHẦN MỀM'
    Add-Paragraph -Doc $doc -Text 'Đề tài: Ứng dụng quản lý tài chính cá nhân thông minh đa nền tảng tích hợp AI và cổng quản trị hệ thống' -Bold $true -Alignment 1
    Add-Paragraph -Doc $doc -Text 'Sản phẩm được phát triển trên Flutter cho mobile và web admin, sử dụng Firebase cho xác thực và lưu trữ thời gian thực, đồng thời tích hợp AI để hỗ trợ nhập liệu giao dịch bằng ngôn ngữ tự nhiên và ảnh/OCR.' -Alignment 1 -SpaceAfter 12

    Add-Heading2 -Doc $doc -Text 'CHƯƠNG 1. THÔNG TIN NHÓM'
    Add-Paragraph -Doc $doc -Text '1.1. Đề tài nhóm'
    Add-Paragraph -Doc $doc -Text 'Đề tài của nhóm là xây dựng hệ thống quản lý tài chính cá nhân thông minh, cho phép người dùng ghi nhận thu chi, quản lý ngân sách, theo dõi mục tiêu tiết kiệm, xem báo cáo thống kê và sử dụng AI để nhập giao dịch nhanh bằng câu nói tự nhiên hoặc hình ảnh hóa đơn.'
    Add-Paragraph -Doc $doc -Text '1.2. Tên nhóm'
    Add-Paragraph -Doc $doc -Text 'Nhóm: .................................................................'
    Add-Paragraph -Doc $doc -Text '1.3. Ý nghĩa tên nhóm'
    Add-Paragraph -Doc $doc -Text 'Ý nghĩa: ........................................................................................................................................................................................'
    Add-Paragraph -Doc $doc -Text '1.4. Danh sách thành viên'
    Add-Paragraph -Doc $doc -Text 'Sinh viên điền bổ sung bảng gồm các cột: STT, Họ và tên, MSSV, Lớp, Số điện thoại, Email, Vai trò trong nhóm, Ghi chú trưởng nhóm.'
    Add-Paragraph -Doc $doc -Text '1.5. Giới thiệu chung về dự án'
    Add-Paragraph -Doc $doc -Text 'Trong thực tế, việc ghi chép thu chi cá nhân thường bị bỏ quên do thao tác nhập liệu thủ công mất thời gian và khó duy trì lâu dài. Từ bài toán đó, nhóm xây dựng một ứng dụng hỗ trợ quản lý tài chính cá nhân theo hướng hiện đại: dữ liệu đồng bộ thời gian thực, giao diện trực quan, phân tách rõ vai trò người dùng và quản trị viên, đồng thời giảm số bước nhập liệu nhờ AI. Bên cạnh các chức năng cơ bản như thêm, sửa, xóa giao dịch, hệ thống còn có quản lý ngân sách, mục tiêu tiết kiệm, báo cáo phân tích, xuất PDF, quản trị người dùng, quản trị danh mục và cấu hình AI runtime ở phía admin.'

    Add-Heading2 -Doc $doc -Text 'CHƯƠNG 2. PHÂN TÍCH VÀ ĐẶC TẢ YÊU CẦU'
    Add-Paragraph -Doc $doc -Text '2.1. Tổng quan về đề tài'
    Add-Paragraph -Doc $doc -Text 'Hệ thống gồm hai phân hệ chính. Phân hệ thứ nhất là ứng dụng người dùng chạy trên Flutter mobile, cung cấp các chức năng quản lý tài chính cá nhân như tài khoản, giao dịch, ngân sách, mục tiêu tiết kiệm, báo cáo thống kê và AI chat. Phân hệ thứ hai là cổng quản trị chạy trên Flutter Web, cho phép admin theo dõi người dùng, giao dịch, danh mục dùng chung, thông báo hệ thống, cấu hình AI và các tham số vận hành.'
    Add-Paragraph -Doc $doc -Text '2.2. Đặc tả yêu cầu chức năng'
    Add-Paragraph -Doc $doc -Text 'Nhóm người dùng thông thường có các yêu cầu chính: đăng ký, đăng nhập, quên mật khẩu/đổi mật khẩu bằng OTP, cập nhật thông tin cá nhân, thêm sửa xóa giao dịch, nhập giao dịch thủ công, nhập giao dịch bằng AI từ văn bản, nhập giao dịch từ ảnh thông qua OCR/vision, quản lý danh mục cá nhân, quản lý ngân sách theo tháng, theo dõi mục tiêu tiết kiệm, xem báo cáo thu chi, phân tích theo danh mục và xuất dữ liệu PDF.'
    Add-Paragraph -Doc $doc -Text 'Nhóm quản trị viên có các yêu cầu chính: đăng nhập cổng quản trị, xem dashboard tổng quan hệ thống, xem danh sách người dùng, đổi role, khóa/mở khóa tài khoản, xem giao dịch gần đây toàn hệ thống, quản lý danh mục mặc định, quản lý thông báo broadcast, chỉnh sửa cấu hình hệ thống và cấu hình AI runtime/lexicon.'
    Add-Paragraph -Doc $doc -Text '2.3. Đặc tả yêu cầu phi chức năng'
    Add-Paragraph -Doc $doc -Text 'Hệ thống cần đảm bảo tính bảo mật dữ liệu, trong đó mỗi người dùng chỉ được phép truy cập dữ liệu của chính mình. Hệ thống cần phản hồi nhanh, giao diện thân thiện, hỗ trợ theme sáng/tối, đồng bộ dữ liệu thời gian thực qua Firestore và có khả năng mở rộng cho mobile lẫn web. Các thao tác gọi mạng, đọc ghi dữ liệu và AI đều phải xử lý bất đồng bộ để tránh treo giao diện.'
    Add-Paragraph -Doc $doc -Text '2.4. Phân tích actor và use case'
    Add-Paragraph -Doc $doc -Text 'Actor User tương tác với các ca sử dụng: quản lý tài khoản, quản lý giao dịch, nhập giao dịch bằng AI, quản lý ngân sách, quản lý mục tiêu tiết kiệm, xem báo cáo và phân tích. Actor Admin tương tác với các ca sử dụng: đăng nhập admin web, quản lý người dùng, quản lý danh mục hệ thống, quản lý thông báo, theo dõi giao dịch và cấu hình hệ thống.'
    Add-Note -Doc $doc -Text 'Sơ đồ use case tổng quát của hệ thống với 2 actor User và Admin'
    Add-Paragraph -Doc $doc -Text '2.5. Phân tích 5 chức năng chính'
    Add-Paragraph -Doc $doc -Text 'Chức năng 1 - Đăng nhập và phân quyền: người dùng xác thực qua Firebase Auth; sau đó hệ thống kiểm tra hồ sơ Firestore để đọc role và status. Nếu tài khoản bị khóa hoặc hệ thống đang bảo trì thì chặn truy cập.'
    Add-Note -Doc $doc -Text 'Sơ đồ sequence cho chức năng đăng nhập và phân quyền'
    Add-Paragraph -Doc $doc -Text 'Chức năng 2 - Thêm giao dịch thủ công: người dùng nhập tiêu đề, số tiền, loại giao dịch, danh mục, thời gian và ghi chú; ứng dụng kiểm tra hợp lệ dữ liệu trước khi ghi vào sub-collection transactions của người dùng.'
    Add-Note -Doc $doc -Text 'Sơ đồ activity hoặc sequence cho chức năng thêm giao dịch thủ công'
    Add-Paragraph -Doc $doc -Text 'Chức năng 3 - Thêm giao dịch bằng AI/ảnh: người dùng nhập câu tự nhiên hoặc chọn ảnh hóa đơn. AIService sẽ phân tích câu, tách giao dịch, chuẩn hóa số tiền, suy luận loại thu/chi, suy luận danh mục, thời điểm và độ tin cậy; nếu dùng AI thật thì còn hỗ trợ remote runtime config và fallback sang local parse.'
    Add-Note -Doc $doc -Text 'Sơ đồ sequence cho chức năng thêm giao dịch bằng AI hoặc OCR/vision'
    Add-Paragraph -Doc $doc -Text 'Chức năng 4 - Quản lý ngân sách và cảnh báo: người dùng thiết lập hạn mức theo danh mục và tháng. Khi phát sinh chi tiêu, hệ thống so sánh số chi đã dùng với hạn mức để cảnh báo an toàn, sắp vượt hoặc vượt mức.'
    Add-Note -Doc $doc -Text 'Sơ đồ activity hoặc sequence cho chức năng kiểm tra ngân sách'
    Add-Paragraph -Doc $doc -Text 'Chức năng 5 - Quản trị hệ thống: admin theo dõi dashboard, cập nhật role/status người dùng, quản lý danh mục mặc định, phát broadcast và cấu hình các tham số hệ thống. Dữ liệu thay đổi được đẩy thời gian thực tới client liên quan.'
    Add-Note -Doc $doc -Text 'Sơ đồ sequence cho chức năng admin khóa user hoặc cập nhật danh mục/broadcast hệ thống'
    Add-Paragraph -Doc $doc -Text '2.6. Nhận xét phân tích'
    Add-Paragraph -Doc $doc -Text 'Phân tích yêu cầu cho thấy đề tài có tính thực tiễn cao vì giải quyết trực tiếp nhu cầu quản lý thu chi hằng ngày. So với ứng dụng ghi chép truyền thống, hệ thống nổi bật ở khả năng nhập liệu thông minh, đồng bộ realtime và có lớp quản trị riêng để vận hành toàn hệ thống.'

    Add-Heading2 -Doc $doc -Text 'CHƯƠNG 3. THIẾT KẾ VÀ TỔ CHỨC DỮ LIỆU'
    Add-Paragraph -Doc $doc -Text '3.1. Kiến trúc tổng thể'
    Add-Paragraph -Doc $doc -Text 'Ứng dụng áp dụng kiến trúc phân tầng. Tầng trình bày gồm các màn hình Flutter mobile và web admin. Tầng dịch vụ nghiệp vụ gồm các lớp như AuthService, AIService, ReportService, CategoryService, Db và repository cho admin web. Tầng dữ liệu gồm các model như Budget, SavingGoal, AIChatMessage, report models và dữ liệu lưu trên Firebase Firestore.'
    Add-Note -Doc $doc -Text 'Sơ đồ kiến trúc tổng thể Client - Firebase - AI Service - Admin Web'
    Add-Paragraph -Doc $doc -Text '3.2. Thiết kế cơ sở dữ liệu theo Firestore'
    Add-Paragraph -Doc $doc -Text 'Dự án sử dụng cơ sở dữ liệu NoSQL trên Cloud Firestore. Collection gốc users lưu thông tin người dùng như email, name hoặc username, role, status, totalCredit, totalDebit, remainingAmount, createdAt, updatedAt. Mỗi user có các sub-collection chính gồm transactions, budgets và saving_goals. Ngoài ra hệ thống có collection categories dùng cho danh mục mặc định toàn cục, system_broadcasts cho thông báo hệ thống, system_configs cho cấu hình hệ thống và admin_logs để ghi nhận hoạt động quản trị.'
    Add-Paragraph -Doc $doc -Text '3.3. Mô hình thực thể liên kết quy đổi từ Firestore'
    Add-Paragraph -Doc $doc -Text 'Dù Firestore là mô hình tài liệu, nhóm vẫn có thể quy đổi sang ERD mức logic với các thực thể: User, Transaction, Budget, SavingGoal, Contribution, Category, Broadcast, SystemConfig, AdminLog. Quan hệ chính là User một-nhiều Transaction, User một-nhiều Budget, User một-nhiều SavingGoal, SavingGoal một-nhiều Contribution. Category, Broadcast và SystemConfig là thực thể dùng chung toàn hệ thống.'
    Add-Note -Doc $doc -Text 'ERD hoặc sơ đồ quan hệ logic quy đổi từ các collection/sub-collection Firestore'
    Add-Paragraph -Doc $doc -Text '3.4. Mô tả chi tiết các thực thể chính'
    Add-Paragraph -Doc $doc -Text 'Bảng logic User: id, email, name hoặc username, role, status, totalCredit, totalDebit, remainingAmount, createdAt, updatedAt. Thực thể này là trung tâm để xác định phân quyền, số dư và thông tin hồ sơ.'
    Add-Paragraph -Doc $doc -Text 'Bảng logic Transaction: id, title, amount, type, category, note, timestamp, monthyear, totalCredit, totalDebit, remainingAmount. Dùng để ghi nhận từng khoản thu hoặc chi của người dùng.'
    Add-Paragraph -Doc $doc -Text 'Bảng logic Budget: id, categoryName hoặc category, limitAmount, monthyear, spentAmount và các thông tin hiển thị. Dùng cho việc kiểm soát chi tiêu theo tháng.'
    Add-Paragraph -Doc $doc -Text 'Bảng logic SavingGoal: id, name, targetAmount, currentAmount, startDate, targetDate, icon, color, status, createdAt. Kèm theo sub-collection contributions để ghi lịch sử nạp tiền vào mục tiêu.'
    Add-Paragraph -Doc $doc -Text 'Bảng logic Category: id, name, type, iconName, isDefault, createdAt, updatedAt. Dùng cho danh mục mặc định của hệ thống và hỗ trợ AI suy luận danh mục.'
    Add-Paragraph -Doc $doc -Text 'Bảng logic Broadcast và SystemConfig: phục vụ vận hành hệ thống, bật tắt thông báo, chế độ bảo trì, cấu hình AI runtime và lexicon.'
    Add-Paragraph -Doc $doc -Text '3.5. Tổ chức dữ liệu và lý do lựa chọn'
    Add-Paragraph -Doc $doc -Text 'Việc chọn Firestore giúp hệ thống đồng bộ dữ liệu thời gian thực, phù hợp mô hình mobile-first, dễ mở rộng cho nhiều thiết bị và phù hợp với việc lưu dữ liệu theo từng người dùng. Cấu trúc sub-collection giúp mỗi hồ sơ người dùng được cô lập dữ liệu, thuận tiện áp dụng security rules và tối ưu truy vấn theo nhu cầu nghiệp vụ.'

    Add-Heading2 -Doc $doc -Text 'CHƯƠNG 4. THIẾT KẾ GIAO DIỆN'
    Add-Paragraph -Doc $doc -Text '4.1. Sơ đồ màn hình'
    Add-Paragraph -Doc $doc -Text 'Ở phía mobile, luồng màn hình chính gồm: đăng nhập/đăng ký/quên mật khẩu -> dashboard -> home -> transaction -> budget -> report -> settings -> AI input -> saving goals -> category analysis và các màn hình chỉnh sửa liên quan. Ở phía admin web, luồng chính gồm: admin login -> admin shell -> overview -> users -> transactions -> categories -> reports -> broadcasts -> system configs -> AI config.'
    Add-Note -Doc $doc -Text 'Sơ đồ màn hình của mobile app'
    Add-Note -Doc $doc -Text 'Sơ đồ màn hình của admin web'
    Add-Paragraph -Doc $doc -Text '4.2. Thiết kế giao diện người dùng mobile'
    Add-Paragraph -Doc $doc -Text 'Dashboard sử dụng thanh điều hướng dưới để truy cập nhanh các khu vực Home, Transactions, Budget, Report và Settings. Giao diện được xây trên Material 3, hỗ trợ theme sáng/tối, ưu tiên khả năng đọc số liệu tài chính và điều hướng nhanh.'
    Add-Paragraph -Doc $doc -Text 'Màn hình AI Input là điểm nhấn của hệ thống. Người dùng có thể nhập nội dung tự nhiên, xem gợi ý nhanh, dùng ảnh hóa đơn, nhận phản hồi dạng chat và xác nhận trước khi lưu giao dịch. Màn hình này hỗ trợ lịch sử chat theo người dùng, quick templates và các trạng thái clarification/success/error.'
    Add-Paragraph -Doc $doc -Text 'Màn hình Budget hiển thị hạn mức chi tiêu theo danh mục và tháng, dùng progress để người dùng nhận biết vùng an toàn, vùng cảnh báo và vùng vượt mức. Màn hình Report và Category Analysis cung cấp góc nhìn trực quan về thu chi theo thời gian và theo danh mục.'
    Add-Paragraph -Doc $doc -Text 'Màn hình Saving Goals cho phép tạo mục tiêu tiết kiệm, nạp tiền từ số dư chính, rút tiền hoàn thành hoặc rút sớm và theo dõi tiến độ bằng thanh progress. Đây là phần mở rộng giá trị thực tế cho ứng dụng, vượt ra ngoài bài toán ghi chép thu chi đơn thuần.'
    Add-Note -Doc $doc -Text 'Ảnh chụp hoặc mockup các màn hình mobile chính: đăng nhập, dashboard, AI input, budget, report, saving goals'
    Add-Paragraph -Doc $doc -Text '4.3. Thiết kế giao diện admin web'
    Add-Paragraph -Doc $doc -Text 'Admin web có giao diện dashboard tổng quan với các thẻ số liệu về người dùng, danh mục, broadcast, giao dịch tháng, tổng thu, tổng chi và số dư toàn hệ thống. Các trang con được tổ chức theo mô hình shell để quản trị viên thao tác tập trung trên trình duyệt.'
    Add-Paragraph -Doc $doc -Text 'Trang Users cho phép xem hồ sơ, đổi vai trò và cập nhật trạng thái người dùng. Trang Categories dùng để thêm, sửa, xóa danh mục mặc định. Trang Broadcasts dùng để phát thông báo cho toàn hệ thống. Trang AI Config hỗ trợ quản trị runtime, prompt/lexicon và các tùy chọn AI để cải thiện khả năng phân tích giao dịch.'
    Add-Note -Doc $doc -Text 'Ảnh chụp hoặc mockup các màn hình admin web chính: overview, users, categories, broadcasts, AI config'
    Add-Paragraph -Doc $doc -Text '4.4. Đánh giá thiết kế giao diện'
    Add-Paragraph -Doc $doc -Text 'Thiết kế giao diện của hệ thống hướng tới tính rõ ràng, dễ thao tác và trực quan. Mobile chú trọng tốc độ nhập liệu và hiển thị dữ liệu cá nhân; admin web tập trung khả năng giám sát và vận hành. Cách phân tách này giúp mỗi nhóm người dùng làm việc đúng ngữ cảnh của mình.'

    Add-Heading2 -Doc $doc -Text 'CHƯƠNG 5. DEMO XÂY DỰNG CHƯƠNG TRÌNH'
    Add-Paragraph -Doc $doc -Text '5.1. Môi trường và công nghệ triển khai'
    Add-Paragraph -Doc $doc -Text 'Dự án được phát triển bằng Dart và Flutter, sử dụng Firebase Core, Firebase Auth và Cloud Firestore cho backend dịch vụ. Ngoài ra còn có Provider cho quản lý trạng thái, fl_chart cho biểu đồ, pdf/printing cho xuất báo cáo, google_mlkit_text_recognition cho OCR, email_otp cho xác thực OTP và HTTP để kết nối AI runtime từ xa.'
    Add-Paragraph -Doc $doc -Text '5.2. Demo chức năng chính và cách sử dụng'
    Add-Paragraph -Doc $doc -Text 'Chức năng đăng ký/đăng nhập: người dùng tạo tài khoản bằng email và mật khẩu; sau đó đăng nhập để vào dashboard. Nếu quên mật khẩu có thể dùng quy trình OTP hoặc gửi email reset tùy màn hình triển khai.'
    Add-Paragraph -Doc $doc -Text 'Chức năng thêm giao dịch thủ công: từ màn hình giao dịch, người dùng nhập thông tin cần thiết và lưu. Sau khi lưu, số dư và thống kê liên quan được cập nhật lại.'
    Add-Paragraph -Doc $doc -Text 'Chức năng thêm giao dịch bằng AI: từ màn hình AI chat, người dùng nhập câu như "ăn sáng 30k" hoặc "lương 15 triệu". Hệ thống phân tích, sinh card giao dịch, cho phép chọn lại danh mục nếu cần và chỉ lưu khi người dùng xác nhận.'
    Add-Paragraph -Doc $doc -Text 'Chức năng nhập giao dịch bằng ảnh: người dùng chụp hoặc chọn ảnh hóa đơn. Hệ thống OCR/vision trích xuất dữ liệu rồi chuyển thành giao dịch đề xuất.'
    Add-Paragraph -Doc $doc -Text 'Chức năng quản lý ngân sách: người dùng tạo ngân sách theo danh mục/tháng, theo dõi thanh tiến độ và xử lý khi gần vượt hoặc vượt mức.'
    Add-Paragraph -Doc $doc -Text 'Chức năng mục tiêu tiết kiệm: người dùng tạo mục tiêu, nạp thêm tiền từ số dư chính, theo dõi mức hoàn thành và rút tiền khi cần.'
    Add-Paragraph -Doc $doc -Text 'Chức năng admin web: quản trị viên đăng nhập, xem tổng quan hệ thống, khóa/mở khóa người dùng, quản trị danh mục, theo dõi giao dịch, đăng broadcast và cấu hình AI runtime.'
    Add-Note -Doc $doc -Text 'Bổ sung hình demo theo từng chức năng chính hoặc ảnh chụp lúc chạy thực tế'
    Add-Paragraph -Doc $doc -Text '5.3. Điểm nổi bật trong phần xây dựng'
    Add-Paragraph -Doc $doc -Text 'Điểm nổi bật đầu tiên là AIService có khả năng parse cục bộ lẫn parse từ AI thật, hỗ trợ fallback khi mạng lỗi và có bước làm giàu kết quả như chuẩn hóa tiền tệ, suy luận danh mục, suy luận thời gian. Điểm nổi bật thứ hai là admin web không chỉ dừng ở quản lý user mà còn có các phần vận hành sâu hơn như broadcast và AI config. Điểm nổi bật thứ ba là hệ thống hỗ trợ cả bài toán tiết kiệm, điều mà nhiều đồ án tương tự thường bỏ qua.'

    Add-Heading2 -Doc $doc -Text 'CHƯƠNG 6. KIỂM THỬ PHẦN MỀM'
    Add-Paragraph -Doc $doc -Text '6.1. Mục tiêu kiểm thử'
    Add-Paragraph -Doc $doc -Text 'Kiểm thử nhằm xác nhận các chức năng cốt lõi hoạt động đúng theo yêu cầu, giảm lỗi nghiệp vụ và đảm bảo luồng dữ liệu từ client tới Firestore/AI được xử lý ổn định.'
    Add-Paragraph -Doc $doc -Text '6.2. Danh sách 5 chức năng chính được chọn để viết test case'
    Add-Paragraph -Doc $doc -Text 'Năm chức năng chính được ưu tiên kiểm thử gồm: đăng nhập và phân quyền; thêm giao dịch thủ công; thêm giao dịch bằng AI; quản lý ngân sách; quản trị người dùng trên admin web.'
    Add-Paragraph -Doc $doc -Text '6.3. Test case đề xuất'
    Add-Paragraph -Doc $doc -Text 'TC01 - Đăng nhập hợp lệ: nhập email và mật khẩu đúng. Kết quả mong đợi là đăng nhập thành công và điều hướng vào khu vực phù hợp với role.'
    Add-Paragraph -Doc $doc -Text 'TC02 - Đăng nhập với tài khoản bị khóa: nhập tài khoản có status locked. Kết quả mong đợi là hệ thống từ chối truy cập và hiển thị thông báo tài khoản bị khóa.'
    Add-Paragraph -Doc $doc -Text 'TC03 - Thêm giao dịch thủ công hợp lệ: nhập đầy đủ tiêu đề, số tiền, loại, danh mục, ngày và ghi chú. Kết quả mong đợi là giao dịch được lưu và số dư được cập nhật.'
    Add-Paragraph -Doc $doc -Text 'TC04 - Thêm giao dịch AI đơn giản: nhập câu "Ăn sáng 30k". Kết quả mong đợi là hệ thống nhận diện khoản chi, số tiền 30000 và danh mục phù hợp như Ăn uống.'
    Add-Paragraph -Doc $doc -Text 'TC05 - Thêm giao dịch AI nhiều vế: nhập câu "Ăn tối 50k và đổ xăng 30k". Kết quả mong đợi là hệ thống tách được 2 giao dịch riêng.'
    Add-Paragraph -Doc $doc -Text 'TC06 - Cảnh báo ngân sách: đặt hạn mức 1.000.000 đồng cho danh mục ăn uống, sau đó thêm giao dịch khiến tổng chi vượt hạn mức. Kết quả mong đợi là hệ thống hiển thị cảnh báo vượt mức.'
    Add-Paragraph -Doc $doc -Text 'TC07 - Admin khóa user: admin cập nhật status của một tài khoản sang locked. Kết quả mong đợi là user không thể tiếp tục sử dụng ứng dụng ở lần kiểm tra trạng thái tiếp theo.'
    Add-Paragraph -Doc $doc -Text 'TC08 - Admin thêm danh mục hệ thống: admin tạo danh mục mặc định mới. Kết quả mong đợi là danh mục xuất hiện trong dữ liệu dùng chung và được client đọc về khi tải danh sách.'
    Add-Paragraph -Doc $doc -Text '6.4. Kết quả run test'
    Add-Paragraph -Doc $doc -Text 'Phần này đề nghị nhóm bổ sung bảng kết quả run test thực tế theo file Excel testcase riêng của môn học, gồm các cột: mã test case, bước thực hiện, dữ liệu đầu vào, kết quả mong đợi, kết quả thực tế, trạng thái Pass/Fail và ghi chú minh chứng.'
    Add-Note -Doc $doc -Text 'Bảng tổng hợp run test hoặc ảnh minh họa thực hiện test'
    Add-Paragraph -Doc $doc -Text '6.5. Đánh giá chung'
    Add-Paragraph -Doc $doc -Text 'Qua quá trình phân tích, thiết kế và xây dựng, hệ thống đáp ứng khá tốt mục tiêu đề tài: hỗ trợ quản lý tài chính cá nhân thuận tiện hơn, tăng trải nghiệm nhập liệu nhờ AI và bảo đảm khả năng vận hành thực tế nhờ cổng quản trị riêng. Trong tương lai, nhóm có thể tiếp tục hoàn thiện bằng cách bổ sung OCR mạnh hơn cho hóa đơn, mở rộng phân tích tiết kiệm, thêm đa ngôn ngữ và xây dựng bộ kiểm thử tự động sâu hơn.'

    Add-Paragraph -Doc $doc -Text 'Ghi chú cuối: các vị trí đã đánh dấu [BỔ SUNG SƠ ĐỒ/HÌNH ẢNH] là nơi người dùng chèn sơ đồ use case, activity, sequence, ERD, sơ đồ màn hình hoặc ảnh demo thực tế theo yêu cầu nộp bài.' -Bold $true -SpaceAfter 10

    $doc.SaveAs([ref]$outputPath)
}
finally {
    if ($doc -ne $null) {
        $doc.Close()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    }
    if ($word -ne $null) {
        $word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Output "Created: $outputPath"
