$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bao_cao_6_chuong_chi_tiet.docx"

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

function Add-Title {
    param([object]$Doc, [string]$Text)
    Add-Paragraph -Doc $Doc -Text $Text -FontSize 17 -Bold $true -Alignment 1 -SpaceAfter 10
}

function Add-H1 {
    param([object]$Doc, [string]$Text)
    Add-Paragraph -Doc $Doc -Text $Text -FontSize 15 -Bold $true -SpaceAfter 10
}

function Add-H2 {
    param([object]$Doc, [string]$Text)
    Add-Paragraph -Doc $Doc -Text $Text -FontSize 14 -Bold $true -SpaceAfter 8
}

function Add-H3 {
    param([object]$Doc, [string]$Text)
    Add-Paragraph -Doc $Doc -Text $Text -FontSize 13 -Bold $true -SpaceAfter 6
}

function Add-Note {
    param(
        [object]$Doc,
        [string]$Kind,
        [string]$Priority,
        [string]$Text
    )
    Add-Paragraph -Doc $Doc -Text "[${Kind} - ${Priority}] $Text" -FontSize 12 -Bold $true -SpaceAfter 8
}

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Title -Doc $doc -Text 'BÁO CÁO CÔNG NGHỆ PHẦN MỀM'
    Add-Paragraph -Doc $doc -Text 'Đề tài: Hệ thống quản lý tài chính cá nhân thông minh đa nền tảng tích hợp AI và cổng quản trị hệ thống' -Bold $true -Alignment 1
    Add-Paragraph -Doc $doc -Text 'Bản chi tiết này được biên soạn bám sát 6 chương theo yêu cầu nộp bài, đồng thời mở rộng phần nghiệp vụ, công nghệ, kiến trúc, dữ liệu, AI, luồng hệ thống và kiểm thử để phục vụ mục tiêu trình bày đồ án một cách rõ ràng, chính xác và có chiều sâu hơn.' -Alignment 1 -SpaceAfter 12

    Add-H1 -Doc $doc -Text 'CHƯƠNG 1. THÔNG TIN NHÓM'
    Add-H2 -Doc $doc -Text '1.1. Giới thiệu đề tài'
    Add-Paragraph -Doc $doc -Text 'Đề tài của nhóm là xây dựng một hệ thống quản lý tài chính cá nhân hiện đại, hỗ trợ ghi nhận thu nhập và chi tiêu bằng nhiều phương thức: nhập tay truyền thống, nhập bằng câu lệnh ngôn ngữ tự nhiên qua AI, nhập từ ảnh hóa đơn thông qua OCR/vision, kết hợp với quản lý ngân sách, mục tiêu tiết kiệm, báo cáo phân tích và một cổng quản trị riêng cho quản trị viên.'
    Add-Paragraph -Doc $doc -Text 'Điểm khác biệt quan trọng của đề tài không nằm ở việc chỉ tạo ra một ứng dụng ghi chép thu chi, mà nằm ở cách hệ thống biến quá trình nhập liệu tài chính vốn nhiều bước, dễ chán và khó duy trì thành một trải nghiệm thông minh hơn, tự nhiên hơn và gần với thói quen giao tiếp hằng ngày của người dùng.'
    Add-H2 -Doc $doc -Text '1.2. Tên nhóm, ý nghĩa nhóm và thành viên'
    Add-Paragraph -Doc $doc -Text 'Tên nhóm: ................................................................................................................'
    Add-Paragraph -Doc $doc -Text 'Ý nghĩa tên nhóm: ....................................................................................................'
    Add-Paragraph -Doc $doc -Text 'Danh sách thành viên: bổ sung đầy đủ STT, Họ tên, MSSV, lớp, số điện thoại, email, vai trò phụ trách, trưởng nhóm.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN CAO' -Text 'Bảng thông tin thành viên nhóm và phân công công việc cụ thể cho từng người.'
    Add-H2 -Doc $doc -Text '1.3. Bối cảnh và ý nghĩa thực tiễn'
    Add-Paragraph -Doc $doc -Text 'Trong đời sống hiện nay, người dùng thường có nhiều khoản chi nhỏ phát sinh liên tục như ăn uống, di chuyển, hóa đơn, mua sắm, chi phí học tập hoặc giải trí. Nếu mỗi lần ghi chép phải đi qua nhiều trường dữ liệu như số tiền, loại thu chi, danh mục, ngày giờ và ghi chú thì việc duy trì thói quen ghi sổ tài chính sẽ nhanh chóng bị bỏ dở. Đó là lý do bài toán giảm ma sát nhập liệu trở thành trọng tâm chính của hệ thống.'
    Add-Paragraph -Doc $doc -Text 'Từ góc nhìn công nghệ phần mềm, đề tài còn có giá trị ở chỗ kết hợp được nhiều xu hướng hiện đại trong cùng một hệ thống: phát triển đa nền tảng bằng Flutter, backend dạng dịch vụ với Firebase, dữ liệu thời gian thực với Firestore Stream, tích hợp AI cho xử lý ngôn ngữ tự nhiên, và một cổng quản trị web giúp quản lý vận hành toàn bộ hệ thống.'
    Add-H2 -Doc $doc -Text '1.4. Mục tiêu của đề tài'
    Add-Paragraph -Doc $doc -Text 'Mục tiêu thứ nhất là giúp người dùng cá nhân quản lý tài chính dễ dàng hơn, nhanh hơn và trực quan hơn.'
    Add-Paragraph -Doc $doc -Text 'Mục tiêu thứ hai là xây dựng một kiến trúc có thể triển khai thực tế, dễ mở rộng, tiết kiệm chi phí hạ tầng, tận dụng được khả năng realtime và bảo mật của Firebase.'
    Add-Paragraph -Doc $doc -Text 'Mục tiêu thứ ba là thể hiện yếu tố thông minh bằng AI parser có khả năng hiểu câu đời thường, viết tắt, tiếng lóng, cụm tiền tệ phổ biến và tách nhiều giao dịch trong một câu.'
    Add-Paragraph -Doc $doc -Text 'Mục tiêu thứ tư là xây dựng được phân hệ quản trị đủ sâu, không chỉ xem số liệu mà còn có thể khóa người dùng, quản lý danh mục, phát broadcast hệ thống và chỉnh runtime AI.'
    Add-Note -Doc $doc -Kind 'HÌNH ẢNH' -Priority 'ƯU TIÊN TRUNG BÌNH' -Text 'Hình tổng quan đề tài hoặc poster giới thiệu hệ thống.'

    Add-H1 -Doc $doc -Text 'CHƯƠNG 2. PHÂN TÍCH VÀ ĐẶC TẢ YÊU CẦU'
    Add-H2 -Doc $doc -Text '2.1. Tổng quan hệ thống'
    Add-Paragraph -Doc $doc -Text 'Hệ thống được xây dựng cho hai nhóm tác nhân chính. Nhóm thứ nhất là người dùng cuối sử dụng ứng dụng mobile để quản lý tài chính cá nhân. Nhóm thứ hai là quản trị viên sử dụng cổng quản trị web để theo dõi, điều phối và cấu hình hệ thống.'
    Add-Paragraph -Doc $doc -Text 'Từ góc nhìn luồng nghiệp vụ, hệ thống cho phép dữ liệu di chuyển theo hai hướng. Ở chiều thuận, người dùng tạo ra dữ liệu bằng đăng ký, nhập giao dịch, thiết lập ngân sách, nạp mục tiêu tiết kiệm hoặc hỏi AI. Ở chiều ngược lại, hệ thống và admin tác động trở lại người dùng bằng broadcast, maintenance mode, trạng thái khóa tài khoản, danh mục mặc định mới hoặc phản hồi AI.'
    Add-H2 -Doc $doc -Text '2.2. Yêu cầu chức năng của phân hệ người dùng'
    Add-H3 -Doc $doc -Text '2.2.1. Quản lý tài khoản'
    Add-Paragraph -Doc $doc -Text 'Người dùng có thể đăng ký tài khoản bằng email và mật khẩu. Sau khi tạo tài khoản, hồ sơ người dùng được tạo trong collection users với các trường mặc định như role, status, createdAt. Người dùng cũng có thể đăng nhập, đổi hoặc khôi phục mật khẩu bằng các luồng OTP/reset được cài trong ứng dụng.'
    Add-H3 -Doc $doc -Text '2.2.2. Quản lý giao dịch'
    Add-Paragraph -Doc $doc -Text 'Hệ thống hỗ trợ thêm, sửa, xóa giao dịch thủ công. Mỗi giao dịch bao gồm tiêu đề, số tiền, loại giao dịch, danh mục, ghi chú, timestamp và monthyear. Khi giao dịch thay đổi, số dư hiện tại, tổng thu và tổng chi của người dùng cũng được tính lại.'
    Add-H3 -Doc $doc -Text '2.2.3. Quản lý ngân sách'
    Add-Paragraph -Doc $doc -Text 'Người dùng có thể đặt hạn mức theo danh mục và theo tháng. Ứng dụng theo dõi tổng chi của từng danh mục trong tháng được chọn, so sánh với ngưỡng ngân sách và hiển thị bằng thanh tiến độ với ba mức màu sắc: xanh an toàn, cam cảnh báo, đỏ vượt mức.'
    Add-H3 -Doc $doc -Text '2.2.4. Mục tiêu tiết kiệm'
    Add-Paragraph -Doc $doc -Text 'Người dùng có thể tạo mục tiêu tiết kiệm với số tiền mục tiêu, ngày đích, màu sắc và biểu tượng. Người dùng có thể nạp thêm tiền từ số dư chính vào mục tiêu, rút tiền khi hoàn thành hoặc rút sớm. Hệ thống còn hiển thị gợi ý mức tiết kiệm mỗi ngày để đạt tiến độ.'
    Add-H3 -Doc $doc -Text '2.2.5. Báo cáo và phân tích'
    Add-Paragraph -Doc $doc -Text 'Ứng dụng cho phép xem báo cáo theo tháng, so sánh với tháng trước, phân tích theo danh mục, xác định giao dịch lớn nhất hoặc nhỏ nhất và dự báo theo lịch sử bằng weighted average. Ngoài ra người dùng còn có thể xuất báo cáo dạng HTML hoặc CSV.'
    Add-H3 -Doc $doc -Text '2.2.6. Chức năng AI'
    Add-Paragraph -Doc $doc -Text 'Đây là chức năng nổi bật nhất của dự án. Người dùng có thể nhập câu đời thường như ăn sáng 30k, lương 15 triệu, ăn tối 50k và đổ xăng 30k, hoặc đưa ảnh hóa đơn để hệ thống phân tích. AI không lưu thẳng dữ liệu ngay mà trả về card xác nhận, giúp người dùng kiểm soát trước khi commit.'
    Add-H2 -Doc $doc -Text '2.3. Yêu cầu chức năng của phân hệ quản trị'
    Add-Paragraph -Doc $doc -Text 'Admin có thể đăng nhập web admin, xem dashboard tổng quan, theo dõi số lượng người dùng, giao dịch tháng, tổng thu, tổng chi và số dư toàn hệ thống. Admin có thể khóa hoặc mở khóa người dùng, chỉnh role, quản lý danh mục mặc định, quản lý broadcast, quản lý cấu hình hệ thống, xem feed giao dịch và cấu hình AI.'
    Add-Paragraph -Doc $doc -Text 'Khác với nhiều đồ án chỉ có admin xem danh sách user, hệ thống này có chiều sâu vận hành rõ hơn: admin có thể đổi runtime AI, lưu nháp, preview prompt, publish prompt hoặc lexicon, theo dõi log, bật maintenance mode và can thiệp vào trải nghiệm thời gian thực của người dùng.'
    Add-H2 -Doc $doc -Text '2.4. Yêu cầu phi chức năng'
    Add-Paragraph -Doc $doc -Text 'Hệ thống cần đảm bảo bảo mật dữ liệu cá nhân, khả năng phản hồi nhanh, khả năng đồng bộ realtime, khả năng chạy trên nhiều nền tảng, giao diện dễ dùng, hỗ trợ tiếng Việt tốt, và có khả năng chịu lỗi tốt ở các thao tác bất đồng bộ như gọi API, gọi Firestore và parse dữ liệu AI.'
    Add-Paragraph -Doc $doc -Text 'Các thành phần liên quan đến mạng và I/O đều dùng async hoặc await. Với dữ liệu thời gian thực, hệ thống ưu tiên StreamBuilder để nhận cập nhật ngay thay vì yêu cầu người dùng tải lại thủ công.'
    Add-H2 -Doc $doc -Text '2.5. Phân tích nghiệp vụ tổng thể'
    Add-Paragraph -Doc $doc -Text 'Nghiệp vụ cốt lõi của hệ thống xoay quanh việc biến một hành vi tài chính đời thường thành một bản ghi có cấu trúc trong hệ thống. Điều này có thể diễn ra theo nhiều con đường: nhập form, nhập chat, nhập từ ảnh, hoặc chỉnh sửa lại giao dịch cũ. Sau đó dữ liệu được phản chiếu sang ngân sách, báo cáo, số dư và các thống kê khác.'
    Add-Paragraph -Doc $doc -Text 'Tức là trong hệ thống này, giao dịch là thực thể lõi, còn ngân sách, báo cáo, dashboard và mục tiêu tiết kiệm là các thực thể phân tích hoặc dẫn xuất xoay quanh giao dịch.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sơ đồ use case tổng quát với 2 actor User và Admin.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sơ đồ activity nghiệp vụ tổng quát từ lúc người dùng phát sinh giao dịch đến khi dữ liệu xuất hiện ở báo cáo.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN CAO' -Text 'Bảng đặc tả yêu cầu chức năng chia theo 2 phân hệ: User và Admin.'
    Add-H2 -Doc $doc -Text '2.6. Phân tích 5 chức năng chính theo yêu cầu môn học'
    Add-Paragraph -Doc $doc -Text 'Chức năng 1: Đăng nhập và phân quyền. Firebase Auth xác thực danh tính, sau đó Firestore cung cấp role, status và trạng thái maintenance. AuthGate lắng nghe toàn bộ các thay đổi này bằng stream để quyết định điều hướng.'
    Add-Paragraph -Doc $doc -Text 'Chức năng 2: Thêm giao dịch thủ công. Dữ liệu được nhập qua form, kiểm tra hợp lệ, lưu vào users/{uid}/transactions và cập nhật các chỉ số tài chính.'
    Add-Paragraph -Doc $doc -Text 'Chức năng 3: Thêm giao dịch bằng AI. AIService tách câu, chuẩn hóa tiền tệ, suy luận loại, danh mục, thời gian, độ tin cậy và tạo card xác nhận.'
    Add-Paragraph -Doc $doc -Text 'Chức năng 4: Quản lý ngân sách. Hệ thống tính tổng chi theo danh mục trong tháng, đối chiếu limitAmount và hiển thị cảnh báo trực tiếp trên giao diện.'
    Add-Paragraph -Doc $doc -Text 'Chức năng 5: Quản trị hệ thống. Admin giám sát, khóa user, cập nhật danh mục hệ thống, broadcast và AI runtime.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sequence đăng nhập, phân quyền và chặn truy cập khi locked hoặc maintenance.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sequence thêm giao dịch AI với bước parse, draft, xác nhận và lưu.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sequence admin khóa user và tác động realtime đến client.'

    Add-H1 -Doc $doc -Text 'CHƯƠNG 3. THIẾT KẾ VÀ TỔ CHỨC DỮ LIỆU'
    Add-H2 -Doc $doc -Text '3.1. Công nghệ sử dụng và lý do lựa chọn'
    Add-Paragraph -Doc $doc -Text 'Ngôn ngữ chính của dự án là Dart. Framework sử dụng là Flutter, giúp tái sử dụng phần lớn mã nguồn cho mobile và web admin. Đây là lựa chọn hợp lý vì dự án cần tốc độ phát triển nhanh, giao diện đồng nhất và một codebase đủ linh hoạt để mở rộng sang nhiều nền tảng.'
    Add-Paragraph -Doc $doc -Text 'Backend được xây theo mô hình BaaS với Firebase. Lợi ích của lựa chọn này gồm: không phải tự dựng server API riêng trong giai đoạn đồ án, giảm chi phí vận hành, tích hợp sẵn xác thực người dùng, có Firestore realtime, hỗ trợ security rules, và rất phù hợp với mô hình ứng dụng mobile-first.'
    Add-Paragraph -Doc $doc -Text 'State management hiện tại dùng Provider cho các thành phần như cài đặt giao diện. Bên cạnh đó hệ thống dùng StreamBuilder rộng rãi để bind trực tiếp luồng dữ liệu Firestore lên UI. Đây là một sự kết hợp hợp lý giữa quản lý state cục bộ và state đến từ cloud realtime.'
    Add-H2 -Doc $doc -Text '3.2. Kiến trúc tổng thể của hệ thống'
    Add-Paragraph -Doc $doc -Text 'Hệ thống tuân theo tư duy phân tầng: tầng giao diện, tầng nghiệp vụ, tầng dữ liệu và tầng dịch vụ cloud hoặc AI.'
    Add-Paragraph -Doc $doc -Text 'Tầng giao diện bao gồm các screen và widget ở mobile cùng với các page hoặc admin shell ở web. Nhiệm vụ của tầng này là nhận tương tác, hiển thị dữ liệu và điều hướng, không ôm các xử lý nghiệp vụ nặng.'
    Add-Paragraph -Doc $doc -Text 'Tầng nghiệp vụ bao gồm các service như AuthService, AIService, ReportService, CategoryService, Db và AdminWebRepository. Đây là nơi đóng vai trò bộ não ứng dụng, thực hiện suy luận, phân loại, tổng hợp, so sánh, tính toán và ra quyết định.'
    Add-Paragraph -Doc $doc -Text 'Tầng dữ liệu bao gồm các model như Budget, SavingGoal, AIChatMessage, report models, runtime config và cấu trúc Firestore. Tầng này định nghĩa cách dữ liệu được biểu diễn trong code, được convert từ hoặc ra Firestore và truyền sang UI.'
    Add-Paragraph -Doc $doc -Text 'Tầng dịch vụ cloud và AI bao gồm Firebase Auth, Cloud Firestore, OCR, và endpoint AI runtime bên ngoài. Đây là tầng hạ tầng, nơi cung cấp khả năng xác thực, lưu trữ, realtime và suy luận ngôn ngữ.'
    Add-H2 -Doc $doc -Text '3.3. Ý nghĩa của việc phân tầng và lý do sắp xếp'
    Add-Paragraph -Doc $doc -Text 'Phân tầng giúp dự án dễ đọc, dễ bảo trì và dễ mở rộng. Nếu UI thay đổi, phần service không cần đổi quá nhiều. Nếu logic AI thay đổi, chỉ cần tập trung vào AIService và runtime config. Nếu cấu trúc dữ liệu đổi, model và repository có thể được cập nhật có kiểm soát.'
    Add-Paragraph -Doc $doc -Text 'Về mặt học thuật, cách tổ chức này cũng giúp báo cáo thể hiện đúng tinh thần của công nghệ phần mềm: tách biệt concern, giảm coupling, tăng cohesion và giúp kiểm thử từng lớp rõ ràng hơn.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sơ đồ kiến trúc phân tầng của toàn hệ thống: Mobile App, Admin Web, Services, Firestore/Auth, AI Runtime.'
    Add-H2 -Doc $doc -Text '3.4. Cấu trúc thư mục và tổ chức mã nguồn'
    Add-Paragraph -Doc $doc -Text 'Thư mục lib chứa phần lớn mã nguồn. main.dart là entry point cho mobile app, main_admin_web.dart là entry point cho admin web. screens chứa các màn hình nghiệp vụ; widgets chứa thành phần tái sử dụng; services chứa logic và giao tiếp với dữ liệu; models chứa cấu trúc dữ liệu; admin_web chứa repository, shell và các page phục vụ quản trị.'
    Add-Paragraph -Doc $doc -Text 'Việc tách admin_web riêng là hợp lý vì đây là một phân hệ có trải nghiệm, luồng điều hướng và nghiệp vụ quản trị khác biệt với người dùng mobile. Tuy vẫn dùng cùng codebase Flutter, nhưng cách tổ chức tách biệt giúp dễ phát triển và tránh lẫn logic người dùng với logic admin.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN TRUNG BÌNH' -Text 'Bảng mô tả từng thư mục chính trong lib và trách nhiệm của từng thư mục.'
    Add-H2 -Doc $doc -Text '3.5. Thiết kế cơ sở dữ liệu Firestore'
    Add-Paragraph -Doc $doc -Text 'Collection users là trung tâm dữ liệu của hệ thống. Mỗi document người dùng lưu thông tin hồ sơ, role, status, tổng thu, tổng chi, số dư còn lại và các thông tin cấu hình cá nhân khác. Đây là nơi AuthGate và các service đọc để quyết định quyền truy cập và ngữ cảnh hiển thị.'
    Add-Paragraph -Doc $doc -Text 'Sub-collection transactions lưu từng giao dịch của một người dùng. Mỗi transaction có title, amount, type, category, note, timestamp, monthyear và một số chỉ số tổng hợp phục vụ hiển thị. Việc tách sub-collection theo user đảm bảo phân tách dữ liệu tài chính cá nhân rõ ràng.'
    Add-Paragraph -Doc $doc -Text 'Sub-collection budgets lưu hạn mức theo danh mục và tháng. Việc tách budgets khỏi transactions là hợp lý vì budgets là thực thể cấu hình, còn transactions là thực thể phát sinh.'
    Add-Paragraph -Doc $doc -Text 'Sub-collection saving_goals lưu các mục tiêu tiết kiệm. Mỗi goal lại có sub-collection contributions để theo dõi lịch sử nạp tiền, giúp đáp ứng yêu cầu truy vết theo thời gian.'
    Add-Paragraph -Doc $doc -Text 'Collection categories lưu danh mục mặc định toàn hệ thống. Collection system_broadcasts lưu các thông báo hệ thống có thể hiển thị tới người dùng. Collection system_configs lưu app controls, AI lexicon, AI runtime config và các cấu hình vận hành khác. Collection admin_logs lưu các hành động nhạy cảm của quản trị viên, nhất là khi publish cấu hình AI.'
    Add-H2 -Doc $doc -Text '3.6. ERD quy đổi và mô tả các thực thể'
    Add-Paragraph -Doc $doc -Text 'Thực thể User: id, email, name hoặc username, role, status, totalCredit, totalDebit, remainingAmount, createdAt, updatedAt.'
    Add-Paragraph -Doc $doc -Text 'Thực thể Transaction: id, title, amount, type, category, note, timestamp, monthyear.'
    Add-Paragraph -Doc $doc -Text 'Thực thể Budget: id, categoryName, limitAmount, monthyear, createdAt.'
    Add-Paragraph -Doc $doc -Text 'Thực thể SavingGoal: id, name, targetAmount, currentAmount, startDate, targetDate, icon, color, status, createdAt.'
    Add-Paragraph -Doc $doc -Text 'Thực thể Contribution: amount, date, createdAt, liên kết thuộc về SavingGoal.'
    Add-Paragraph -Doc $doc -Text 'Thực thể Category: id, name, type, iconName, createdAt, updatedAt, isDefault.'
    Add-Paragraph -Doc $doc -Text 'Thực thể Broadcast: title, content, type, status, createdAt, updatedAt, createdByEmail.'
    Add-Paragraph -Doc $doc -Text 'Thực thể SystemConfig: id, data, updatedAt.'
    Add-H2 -Doc $doc -Text '3.7. Cơ chế realtime và luồng đồng bộ hệ thống'
    Add-Paragraph -Doc $doc -Text 'Một trong những điểm hiện đại nhất của hệ thống là cơ chế realtime sync. Hệ thống không chờ người dùng bấm làm mới. Thay vào đó, nhiều màn hình quan trọng được xây trên StreamBuilder. Ví dụ: AuthGate lắng nghe authStateChanges, user document và app controls; BudgetScreen lắng nghe danh sách ngân sách và giao dịch debit trong tháng; admin web có nhiều stream cho users, categories, broadcasts và transactions.'
    Add-Paragraph -Doc $doc -Text 'Ưu điểm của cách làm này là dữ liệu được phản ánh ngay sau khi Firestore thay đổi. Nếu admin khóa tài khoản, client có thể nhận trạng thái locked trong luồng user snapshot. Nếu admin thêm danh mục hệ thống, AI và client có thể đọc lại danh sách mới. Nếu giao dịch mới được thêm, dashboard hoặc báo cáo có thể cập nhật mà không cần load lại trang.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sơ đồ realtime sync giữa Mobile App, Firestore và Admin Web.'
    Add-H2 -Doc $doc -Text '3.8. Phân tích chi tiết chức năng AI và Prompt Engineering'
    Add-Paragraph -Doc $doc -Text 'AI trong dự án không chỉ là một chatbot trả lời tự do, mà là một bộ phân tích giao dịch có contract đầu ra rõ ràng. Trọng tâm không phải nói chuyện hay, mà là bóc tách đúng dữ liệu tài chính dưới dạng có cấu trúc.'
    Add-Paragraph -Doc $doc -Text 'Ở mức local parse, AIService sử dụng nhiều lớp xử lý: TransactionSegmenter để tách câu nhiều vế; TransactionAmountParser để chuẩn hóa số tiền; TransactionCategoryResolver để suy luận hoặc đối chiếu danh mục; TransactionTypeInference để xác định là credit hay debit; TransactionDateTimeInference để xử lý mốc thời gian; TransactionConfidence để chấm độ tin cậy; TransactionPhraseLexicon để hiểu ngôn ngữ đời thường, viết tắt, tiếng lóng và cách nói tiền tệ của người Việt.'
    Add-Paragraph -Doc $doc -Text 'Ở mức remote runtime AI, hệ thống không gửi câu người dùng lên model một cách mơ hồ mà xây dựng prompt nhiều lớp. Trong AiRuntimeConfig có rolePrompt để định vai chuyên gia bóc tách tài chính cá nhân; taskPrompt để định nhiệm vụ là phân loại ý định và tạo dữ liệu có cấu trúc; cardRulesPrompt để quy định khi nào mới được tạo card xác nhận; conversationRulesPrompt để kiểm soát xử lý hội thoại, thời gian và câu hỏi tư vấn; abbreviationRulesPrompt để chuẩn hóa tiếng lóng, teencode, từ địa phương và các biến thể viết tắt.'
    Add-Paragraph -Doc $doc -Text 'Sau khi tổng hợp các phần prompt này, hệ thống còn chèn thêm thông tin vận hành như thời điểm hiện tại, danh sách danh mục đang có, fallback policy và image strategy. Cuối cùng hệ thống ép AI tuân thủ một JSON contract chặt chẽ với các trường status, responseKind, message, transactions và data. Cách làm này rất quan trọng vì giúp frontend parse được kết quả một cách ổn định.'
    Add-Paragraph -Doc $doc -Text 'Điểm mạnh để nhấn trong báo cáo là AI ở đây không hoạt động kiểu trả gì cũng được, mà bị ràng buộc bởi quy tắc nghiệp vụ rất cụ thể: không được bịa dữ liệu, không được lên card khi thiếu dữ liệu, phải hỏi lại đúng phần thiếu, phải ưu tiên quy về danh mục hiện có, chỉ đánh dấu danh mục mới khi thật sự không quy được, và phải tách nhiều giao dịch nếu câu có nhiều vế.'
    Add-Paragraph -Doc $doc -Text 'Dữ liệu data.text đóng vai trò như một từ điển nghiệp vụ cho local parse. Trong đó hệ thống định nghĩa từ khóa thu, chi, phủ định, ý định tương lai, ý định công nợ, bộ tách nhiều giao dịch, bản đồ ưu tiên danh mục và các taxonomy danh mục như ăn uống, đi lại, mua sắm, hóa đơn, giải trí, nhà cửa, y tế, học tập, tài chính và khác. Điều này giúp AI hiểu ngôn ngữ người Việt sát thực tế hơn so với việc chỉ dựa vào model chung.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sequence AI parser từ user input đến JSON contract và card xác nhận.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN CAO' -Text 'Bảng mô tả các tầng prompt: rolePrompt, taskPrompt, cardRulesPrompt, conversationRulesPrompt, abbreviationRulesPrompt.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN TRUNG BÌNH' -Text 'Bảng ví dụ câu input và output JSON chuẩn tương ứng.'
    Add-H2 -Doc $doc -Text '3.9. Logic ngân sách và thuật toán cảnh báo'
    Add-Paragraph -Doc $doc -Text 'BudgetScreen lấy hai nguồn dữ liệu song song theo thời gian thực: danh sách budget của tháng được chọn và danh sách transaction loại debit của cùng tháng. Tại giao diện, hệ thống duyệt các transaction, cộng dồn theo category trùng với budget.categoryName để tính spentAmount.'
    Add-Paragraph -Doc $doc -Text 'Sau đó BudgetProgressCard tính percentage = spentAmount / limitAmount * 100. Nếu percentage nhỏ hơn 80 thì progressColor là xanh, thể hiện an toàn. Nếu percentage từ 80 đến dưới 100 thì chuyển sang cam, thể hiện cảnh báo gần chạm ngưỡng. Nếu percentage lớn hơn hoặc bằng 100 thì chuyển đỏ, đồng thời hiển thị phần tiền vượt mức thay vì phần còn lại.'
    Add-Paragraph -Doc $doc -Text 'Điểm hay của thuật toán này là đơn giản, trực quan, nhưng đủ hiệu quả và dễ giải thích trong báo cáo. Nó còn tận dụng tốt mô hình realtime: hễ giao dịch tháng đó thay đổi thì stream transaction đổi, spentAmount đổi và thanh budget đổi ngay trên UI.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Activity hoặc sequence của thuật toán kiểm tra ngân sách và đổi màu cảnh báo.'
    Add-H2 -Doc $doc -Text '3.10. Bảo mật, phân quyền và vận hành'
    Add-Paragraph -Doc $doc -Text 'AuthService và AuthGate cùng tham gia bảo vệ truy cập. AuthService xử lý xác thực và kiểm tra ban đầu; AuthGate tiếp tục lắng nghe realtime role, status và maintenance mode để điều hướng. Điều này giúp ứng dụng không chỉ an toàn ở thời điểm login, mà còn phản ứng nếu trạng thái tài khoản thay đổi khi người dùng đang online.'
    Add-Paragraph -Doc $doc -Text 'Mô hình phân quyền chia ít nhất hai vai trò: user và admin. User thường được vào dashboard người dùng. Admin trên web được vào AdminDashboard. Nếu admin dùng mobile thì được điều hướng tới màn hình redirect phù hợp. Nếu status là locked hoặc app_controls bật maintenanceMode thì người dùng bị chặn bằng SystemAccessBlockedScreen.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN TRUNG BÌNH' -Text 'Bảng phân quyền hệ thống theo vai trò User hoặc Admin và theo tài nguyên.'

    Add-H1 -Doc $doc -Text 'CHƯƠNG 4. THIẾT KẾ GIAO DIỆN'
    Add-H2 -Doc $doc -Text '4.1. Mục tiêu thiết kế giao diện'
    Add-Paragraph -Doc $doc -Text 'Giao diện mobile được thiết kế để giảm thao tác, dễ nhìn số liệu và tạo cảm giác sử dụng liên tục mỗi ngày. Giao diện admin web được thiết kế để quản trị viên có thể bao quát toàn bộ hệ thống, xem số liệu quan trọng trong một màn hình và đi sâu vào từng nhóm chức năng quản trị.'
    Add-H2 -Doc $doc -Text '4.2. Thiết kế luồng màn hình mobile'
    Add-Paragraph -Doc $doc -Text 'Từ AuthGate, người dùng chưa đăng nhập sẽ vào LoginView. Khi đăng nhập thành công và có quyền user, hệ thống vào Dashboard. Dashboard dùng thanh điều hướng dưới để truy cập HomeScreen, TransactionScreen, BudgetScreen, ReportScreen và SettingsScreen.'
    Add-Paragraph -Doc $doc -Text 'Ngoài các màn hình chính, mobile còn có các màn hình chuyên biệt như AddTransactionScreen, EditTransactionScreen, AIInputScreen, SavingGoalsScreen, SavingGoalDetailScreen, CategoryAnalysisScreen, SearchScreen, ForgotPasswordOtpScreen và ChangePasswordOtpScreen.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN CAO' -Text 'Sơ đồ màn hình mobile và các quan hệ điều hướng chính.'
    Add-H2 -Doc $doc -Text '4.3. Thiết kế giao diện từng màn hình người dùng'
    Add-Paragraph -Doc $doc -Text 'Màn hình Dashboard là trung tâm điều hướng. Mục tiêu của màn hình này là cho phép chuyển nhanh giữa các phân hệ quan trọng mà không tạo cảm giác rối. Thanh navbar bên dưới giúp phù hợp với thói quen sử dụng trên di động.'
    Add-Paragraph -Doc $doc -Text 'Màn hình giao dịch phục vụ xem lịch sử, chỉnh sửa và xóa giao dịch. Đây là màn hình có ý nghĩa nghiệp vụ lớn vì phản ánh toàn bộ dữ liệu gốc của người dùng.'
    Add-Paragraph -Doc $doc -Text 'Màn hình Budget dùng thẻ progress để biểu diễn trạng thái ngân sách. Việc dùng màu sắc thay vì chỉ hiển thị chữ giúp người dùng nhìn là hiểu ngay tình hình tài chính.'
    Add-Paragraph -Doc $doc -Text 'Màn hình Report là khu vực phân tích. Báo cáo không chỉ cho xem tổng tiền mà còn có so sánh tháng trước, biểu đồ danh mục, đường xu hướng lịch sử và giao dịch cực trị. Đây là phần thể hiện giá trị biến dữ liệu thành thông tin.'
    Add-Paragraph -Doc $doc -Text 'Màn hình AIInputScreen có tính tương tác cao nhất. Giao diện dạng chat làm giảm cảm giác nhập form cứng nhắc. Người dùng có thể dùng quick templates, nhập ảnh, xem các trạng thái clarification hoặc success hoặc error và xác nhận giao dịch ngay trong ngữ cảnh hội thoại.'
    Add-Paragraph -Doc $doc -Text 'Màn hình SavingGoalsScreen làm tăng chiều sâu sản phẩm. Không chỉ theo dõi chi tiêu, người dùng còn có mục tiêu tích lũy. Progress bar, các nút thêm tiền hoặc rút tiền và phần gợi ý tiết kiệm mỗi ngày giúp tính năng này vừa trực quan vừa có giá trị sử dụng thực tế.'
    Add-Note -Doc $doc -Kind 'HÌNH ẢNH' -Priority 'ƯU TIÊN CAO' -Text 'Ảnh giao diện đăng nhập, dashboard, giao dịch, budget, report, AI chat, saving goals.'
    Add-H2 -Doc $doc -Text '4.4. Thiết kế giao diện admin web'
    Add-Paragraph -Doc $doc -Text 'Admin web có entry riêng từ main_admin_web.dart, chỉ hỗ trợ khi chạy trên trình duyệt. Điều này cho thấy dự án có định hướng đa nền tảng nhưng vẫn biết phân định ngữ cảnh sử dụng của từng phân hệ.'
    Add-Paragraph -Doc $doc -Text 'OverviewPage là trang tổng quan với hero panel, summary panel và nhiều metric card như số người dùng, số admin, danh mục hệ thống, broadcast đang bật, giao dịch tháng, tổng thu, tổng chi và số dư toàn hệ thống. Việc gom nhiều chỉ số ở đây giúp admin có một cockpit để điều hành.'
    Add-Paragraph -Doc $doc -Text 'UsersPage, TransactionsPage, CategoriesPage, ReportsPage, BroadcastsPage, SystemConfigsPage và AiConfigPage tạo thành bộ công cụ quản trị đầy đủ. Trong đó AiConfigPage đặc biệt quan trọng vì cho thấy hệ thống không xem AI là một khối đen cố định mà cho phép giám sát, chỉnh prompt, preview và publish.'
    Add-Note -Doc $doc -Kind 'SƠ ĐỒ' -Priority 'ƯU TIÊN TRUNG BÌNH' -Text 'Sơ đồ điều hướng các trang admin web.'
    Add-Note -Doc $doc -Kind 'HÌNH ẢNH' -Priority 'ƯU TIÊN CAO' -Text 'Ảnh overview, users, categories, broadcasts, system config và AI config.'
    Add-H2 -Doc $doc -Text '4.5. Nhận xét về trải nghiệm người dùng'
    Add-Paragraph -Doc $doc -Text 'Điểm đáng nhấn mạnh trong báo cáo là giao diện được tổ chức quanh hành vi sử dụng thực tế. Mobile phục vụ ghi chép nhanh và xem số liệu cá nhân. Web admin phục vụ giám sát hệ thống. Đây là cách chia vai trò đúng bối cảnh, hợp với nguyên tắc thiết kế sản phẩm hiện đại.'

    Add-H1 -Doc $doc -Text 'CHƯƠNG 5. DEMO XÂY DỰNG CHƯƠNG TRÌNH'
    Add-H2 -Doc $doc -Text '5.1. Môi trường phát triển'
    Add-Paragraph -Doc $doc -Text 'Dự án được phát triển bằng Flutter và Dart SDK 3.x. Các gói chính gồm firebase_core, firebase_auth, cloud_firestore, provider, intl, fl_chart, pdf, printing, google_mlkit_text_recognition, share_plus, open_filex, image_picker, permission_handler, email_otp và http.'
    Add-H2 -Doc $doc -Text '5.2. Quy trình khởi động hệ thống'
    Add-Paragraph -Doc $doc -Text 'main.dart khởi tạo Firebase, cấu hình locale tiếng Việt và bọc ứng dụng bằng SettingsProvider. Sau đó AuthGate quyết định sẽ vào login, dashboard user hay admin. main_admin_web.dart đóng vai trò khởi tạo riêng cho cổng admin.'
    Add-H2 -Doc $doc -Text '5.3. Demo các chức năng người dùng'
    Add-Paragraph -Doc $doc -Text 'Bước 1: Người dùng đăng ký hoặc đăng nhập. Sau khi xác thực thành công, hệ thống kiểm tra hồ sơ và điều hướng vào khu vực phù hợp.'
    Add-Paragraph -Doc $doc -Text 'Bước 2: Người dùng thêm giao dịch thủ công bằng form. Kết quả là transaction mới xuất hiện trong lịch sử và ảnh hưởng đến số dư.'
    Add-Paragraph -Doc $doc -Text 'Bước 3: Người dùng dùng AI chat để ghi nhận giao dịch chỉ bằng một câu. Đây là phần nên demo kỹ vì thể hiện rõ yếu tố thông minh. Có thể demo cả câu đơn, câu nhiều vế, câu mơ hồ cần hỏi lại và câu có danh mục mới.'
    Add-Paragraph -Doc $doc -Text 'Bước 4: Người dùng dùng ảnh hóa đơn. Hệ thống OCR hoặc vision phân tích và dựng card đề xuất.'
    Add-Paragraph -Doc $doc -Text 'Bước 5: Người dùng tạo ngân sách và thêm giao dịch để quan sát thanh cảnh báo đổi màu theo thời gian thực.'
    Add-Paragraph -Doc $doc -Text 'Bước 6: Người dùng xem báo cáo tháng, phân tích theo danh mục và xuất file.'
    Add-Paragraph -Doc $doc -Text 'Bước 7: Người dùng tạo mục tiêu tiết kiệm, nạp tiền và quan sát tiến độ.'
    Add-H2 -Doc $doc -Text '5.4. Demo các chức năng admin'
    Add-Paragraph -Doc $doc -Text 'Bước 1: Admin đăng nhập web admin.'
    Add-Paragraph -Doc $doc -Text 'Bước 2: Admin xem overview với các chỉ số hệ thống.'
    Add-Paragraph -Doc $doc -Text 'Bước 3: Admin khóa một user. Nếu user đó đang sử dụng app và client đang lắng nghe đúng document thì sẽ nhận trạng thái mới và bị chặn truy cập.'
    Add-Paragraph -Doc $doc -Text 'Bước 4: Admin thêm danh mục hệ thống hoặc broadcast để thể hiện luồng realtime từ backend sang client.'
    Add-Paragraph -Doc $doc -Text 'Bước 5: Admin vào AI config, thay đổi runtime draft, preview câu giao dịch và publish cấu hình.'
    Add-H2 -Doc $doc -Text '5.5. Những điểm hiện đại và giá trị nổi bật khi trình bày demo'
    Add-Paragraph -Doc $doc -Text 'Thứ nhất, AI parser giúp rút ngắn số bước nhập liệu. Thay vì mở form và điền nhiều trường, người dùng có thể dùng ngôn ngữ tự nhiên. Đây là giá trị sản phẩm rất dễ thấy khi demo trực tiếp.'
    Add-Paragraph -Doc $doc -Text 'Thứ hai, realtime sync khiến hệ thống sống động và có cảm giác hệ thống thật, không phải ứng dụng demo tĩnh. Khi dữ liệu đổi ở Firestore, UI đổi theo ngay.'
    Add-Paragraph -Doc $doc -Text 'Thứ ba, kiến trúc BaaS cho thấy nhóm có lựa chọn kỹ thuật hợp lý: dùng Firebase để đi nhanh, bảo mật tốt và tối ưu chi phí.'
    Add-Paragraph -Doc $doc -Text 'Thứ tư, admin AI config cho thấy sản phẩm có khả năng vận hành và cải tiến sau triển khai, không bị đóng cứng.'
    Add-Note -Doc $doc -Kind 'HÌNH ẢNH' -Priority 'ƯU TIÊN CAO' -Text 'Ảnh demo từng bước chức năng chính hoặc ảnh chụp màn hình khi chạy thực tế.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN TRUNG BÌNH' -Text 'Bảng mô tả kịch bản demo, người thực hiện, dữ liệu dùng để demo và kết quả mong đợi.'

    Add-H1 -Doc $doc -Text 'CHƯƠNG 6. KIỂM THỬ PHẦN MỀM'
    Add-H2 -Doc $doc -Text '6.1. Mục tiêu kiểm thử'
    Add-Paragraph -Doc $doc -Text 'Kiểm thử nhằm đảm bảo hệ thống hoạt động đúng với yêu cầu nghiệp vụ, đặc biệt ở các luồng nhạy cảm như xác thực, phân quyền, thêm giao dịch, xử lý AI, ngân sách và quản trị hệ thống.'
    Add-H2 -Doc $doc -Text '6.2. Chiến lược kiểm thử đề xuất'
    Add-Paragraph -Doc $doc -Text 'Do đồ án tập trung vào chức năng, nhóm có thể ưu tiên kiểm thử hộp đen theo test case nghiệp vụ. Ngoài ra cần chú ý các tình huống biên như dữ liệu thiếu, AI trả kết quả không đủ, tài khoản bị khóa, maintenance mode, budget vừa chạm ngưỡng 80 phần trăm, budget vừa chạm 100 phần trăm và giao dịch AI có nhiều vế.'
    Add-H2 -Doc $doc -Text '6.3. Bộ test case cho 5 chức năng chính'
    Add-Paragraph -Doc $doc -Text 'Nhóm nên xây file Excel testcase riêng theo yêu cầu môn. Trong Word này chỉ trình bày định hướng và ví dụ quan trọng.'
    Add-Paragraph -Doc $doc -Text 'TC01: Đăng nhập đúng thông tin. Kết quả mong đợi: vào đúng dashboard theo vai trò.'
    Add-Paragraph -Doc $doc -Text 'TC02: Đăng nhập sai mật khẩu. Kết quả mong đợi: báo lỗi chính xác và không vào hệ thống.'
    Add-Paragraph -Doc $doc -Text 'TC03: Tài khoản bị khóa. Kết quả mong đợi: bị chặn truy cập và hiển thị thông báo tương ứng.'
    Add-Paragraph -Doc $doc -Text 'TC04: Thêm giao dịch thủ công đầy đủ dữ liệu. Kết quả mong đợi: giao dịch được lưu, số dư cập nhật.'
    Add-Paragraph -Doc $doc -Text 'TC05: Sửa giao dịch. Kết quả mong đợi: tổng thu hoặc tổng chi hoặc số dư được tính lại đúng.'
    Add-Paragraph -Doc $doc -Text 'TC06: Xóa giao dịch. Kết quả mong đợi: dữ liệu bị xóa và hồ sơ tài chính được rollback đúng.'
    Add-Paragraph -Doc $doc -Text 'TC07: AI parse câu đơn. Input: ăn sáng 30k. Kết quả mong đợi: amount bằng 30000, type là debit, category phù hợp.'
    Add-Paragraph -Doc $doc -Text 'TC08: AI parse câu nhiều vế. Input: ăn tối 50k và đổ xăng 30k. Kết quả mong đợi: tạo 2 transaction draft.'
    Add-Paragraph -Doc $doc -Text 'TC09: AI gặp câu mơ hồ. Input: hôm trước mua đồ 200k. Kết quả mong đợi: hệ thống hỏi lại ngày chính xác nếu cần.'
    Add-Paragraph -Doc $doc -Text 'TC10: Tạo ngân sách và thêm giao dịch dưới ngưỡng 80 phần trăm. Kết quả mong đợi: màu xanh.'
    Add-Paragraph -Doc $doc -Text 'TC11: Tạo ngân sách và thêm giao dịch đạt vùng 80 đến 100 phần trăm. Kết quả mong đợi: màu cam.'
    Add-Paragraph -Doc $doc -Text 'TC12: Thêm giao dịch vượt ngân sách. Kết quả mong đợi: màu đỏ và hiển thị mức vượt.'
    Add-Paragraph -Doc $doc -Text 'TC13: Admin khóa user. Kết quả mong đợi: user không truy cập được hệ thống.'
    Add-Paragraph -Doc $doc -Text 'TC14: Admin thêm broadcast. Kết quả mong đợi: dữ liệu broadcast được lưu và client liên quan có thể đọc được.'
    Add-Paragraph -Doc $doc -Text 'TC15: Admin publish runtime AI. Kết quả mong đợi: cấu hình mới được ghi vào system_configs và có log quản trị tương ứng.'
    Add-H2 -Doc $doc -Text '6.4. Kết quả kiểm thử và cách trình bày để đạt điểm cao'
    Add-Paragraph -Doc $doc -Text 'Khi điền vào file Excel testcase, nhóm nên ghi rõ: mã test, mục tiêu test, bước thực hiện, dữ liệu đầu vào, kết quả mong đợi, kết quả thực tế, trạng thái pass hoặc fail, ảnh minh chứng và người thực hiện. Nên ưu tiên các minh chứng có tính trực quan như ảnh budget đổi màu, ảnh AI sinh card, ảnh admin khóa user và ảnh overview cập nhật realtime.'
    Add-Note -Doc $doc -Kind 'BẢNG' -Priority 'ƯU TIÊN CAO' -Text 'Bảng test case chi tiết cho 5 chức năng chính, mỗi người phụ trách ít nhất một nhóm test.'
    Add-Note -Doc $doc -Kind 'HÌNH ẢNH' -Priority 'ƯU TIÊN CAO' -Text 'Ảnh minh chứng kết quả chạy test, đặc biệt các ca AI, budget và admin.'
    Add-H2 -Doc $doc -Text '6.5. Đánh giá chung và hướng phát triển'
    Add-Paragraph -Doc $doc -Text 'Nhìn tổng thể, hệ thống đã đi xa hơn một ứng dụng CRUD cơ bản. Dự án có tính sản phẩm, có khả năng vận hành, có yếu tố AI, có realtime, có quản trị và có dữ liệu phân tích. Đây là những điểm rất nên nhấn mạnh khi bảo vệ.'
    Add-Paragraph -Doc $doc -Text 'Trong tương lai có thể mở rộng theo các hướng: nâng cấp OCR để đọc hóa đơn chính xác hơn, thêm ví hoặc tài khoản ngân hàng, đồng bộ đa thiết bị sâu hơn, thêm đa ngôn ngữ, thêm thống kê nâng cao bằng machine learning, hoặc nâng cấp xuất PDF thành PDF thật thay vì HTML giả lập.'

    Add-H1 -Doc $doc -Text 'PHỤ LỤC GỢI Ý CHÈN BẢNG, SƠ ĐỒ, HÌNH ẢNH'
    Add-Paragraph -Doc $doc -Text 'Để báo cáo đạt điểm cao, nên ưu tiên chèn minh họa theo thứ tự sau.'
    Add-Paragraph -Doc $doc -Text '1. Sơ đồ use case tổng quát của hệ thống.'
    Add-Paragraph -Doc $doc -Text '2. Sơ đồ kiến trúc tổng thể và sơ đồ realtime sync.'
    Add-Paragraph -Doc $doc -Text '3. Sequence AI parser, sequence đăng nhập hoặc phân quyền, sequence admin khóa user.'
    Add-Paragraph -Doc $doc -Text '4. ERD logic của Firestore và bảng mô tả từng thực thể.'
    Add-Paragraph -Doc $doc -Text '5. Ảnh giao diện mobile các màn hình trọng điểm.'
    Add-Paragraph -Doc $doc -Text '6. Ảnh giao diện admin web, đặc biệt overview và AI config.'
    Add-Paragraph -Doc $doc -Text '7. Bảng đặc tả yêu cầu, bảng công nghệ, bảng test case và bảng mapping thư mục hoặc chức năng.'
    Add-Paragraph -Doc $doc -Text 'Các đoạn đã đánh dấu BẢNG hoặc SƠ ĐỒ hoặc HÌNH ẢNH trong tài liệu chính là nơi nên bổ sung minh họa tương ứng khi hoàn thiện bản nộp cuối.' -Bold $true

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
