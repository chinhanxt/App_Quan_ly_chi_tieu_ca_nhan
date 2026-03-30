$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\thiet_ke_luong_man_hinh_mobile.docx"

function Add-Paragraph {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text,
        [int]$FontSize = 12,
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

function Set-CellText {
    param(
        [Parameter(Mandatory = $true)][object]$Cell,
        [Parameter(Mandatory = $true)][string]$Text,
        [bool]$Bold = $false,
        [int]$FontSize = 12
    )

    $Cell.Range.Text = $Text
    $Cell.Range.Font.Name = 'Times New Roman'
    $Cell.Range.Font.Size = $FontSize
    $Cell.Range.Font.Bold = [int]$Bold
}

$rows = @(
    @('AuthGate', 'lib/widgets/auth_gate.dart', 'Điểm kiểm tra trạng thái đăng nhập và quyền truy cập trước khi vào luồng mobile'),
    @('LoginView', 'lib/screens/login_screen.dart', 'Màn hình đăng nhập của người dùng chưa xác thực'),
    @('Dashboard', 'lib/screens/dashboard.dart', 'Màn hình trung tâm sau khi đăng nhập thành công với quyền user'),
    @('HomeScreen', 'lib/screens/home_screen.dart', 'Màn hình trang chủ trong thanh điều hướng dưới'),
    @('TransactionScreen', 'lib/screens/transaction_screen.dart', 'Màn hình quản lý và xem danh sách giao dịch'),
    @('BudgetScreen', 'lib/screens/budget_screen.dart', 'Màn hình quản lý ngân sách chi tiêu'),
    @('ReportScreen', 'lib/screens/report_screen.dart', 'Màn hình báo cáo và thống kê'),
    @('SettingsScreen', 'lib/screens/settings_screen.dart', 'Màn hình cài đặt tài khoản và ứng dụng'),
    @('AddTransactionScreen', 'lib/screens/add_transaction_screen.dart', 'Màn hình thêm giao dịch mới'),
    @('EditTransactionScreen', 'lib/screens/edit_transaction_screen.dart', 'Màn hình chỉnh sửa giao dịch đã có'),
    @('AIInputScreen', 'lib/screens/ai_input_screen.dart', 'Màn hình nhập liệu bằng AI hoặc câu lệnh tự nhiên'),
    @('SavingGoalsScreen', 'lib/screens/saving_goals_screen.dart', 'Màn hình danh sách mục tiêu tiết kiệm'),
    @('SavingGoalDetailScreen', 'lib/screens/saving_goal_detail_screen.dart', 'Màn hình chi tiết một mục tiêu tiết kiệm'),
    @('CategoryAnalysisScreen', 'lib/screens/category_analysis_screen.dart', 'Màn hình phân tích dữ liệu theo danh mục'),
    @('SearchScreen', 'lib/screens/search_screen.dart', 'Màn hình tìm kiếm giao dịch hoặc dữ liệu liên quan'),
    @('ForgotPasswordOtpScreen', 'lib/screens/forgot_password_otp_screen.dart', 'Màn hình hỗ trợ quên mật khẩu bằng OTP'),
    @('ChangePasswordOtpScreen', 'lib/screens/change_password_otp_screen.dart', 'Màn hình đổi mật khẩu có xác thực OTP')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text '4.2. THIET KE LUONG MAN HINH MOBILE' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Tu AuthGate, nguoi dung chua dang nhap se vao LoginView. Khi dang nhap thanh cong va co quyen user, he thong vao Dashboard. Dashboard su dung thanh dieu huong duoi de truy cap HomeScreen, TransactionScreen, BudgetScreen, ReportScreen va SettingsScreen. Ngoai cac man hinh chinh, mobile con co cac man hinh chuyen biet nhu AddTransactionScreen, EditTransactionScreen, AIInputScreen, SavingGoalsScreen, SavingGoalDetailScreen, CategoryAnalysisScreen, SearchScreen, ForgotPasswordOtpScreen va ChangePasswordOtpScreen.' -Alignment 3 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Bang duoi day quy doi ten man hinh trong tai lieu sang ten file thuc te trong du an de phuc vu phan thiet ke va doi chieu ma nguon.' -SpaceAfter 8

    $range = $doc.Bookmarks.Item('\endofdoc').Range
    $table = $doc.Tables.Add($range, $rows.Count + 1, 3)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1, 1) -Text 'Tên màn hình / thành phần' -Bold $true
    Set-CellText -Cell $table.Cell(1, 2) -Text 'Tên file thực tế' -Bold $true
    Set-CellText -Cell $table.Cell(1, 3) -Text 'Vai trò trong luồng mobile' -Bold $true

    for ($i = 0; $i -lt $rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r, 1) -Text $rows[$i][0]
        Set-CellText -Cell $table.Cell($r, 2) -Text $rows[$i][1]
        Set-CellText -Cell $table.Cell($r, 3) -Text $rows[$i][2]
    }

    $table.Columns.Item(1).PreferredWidth = 130
    $table.Columns.Item(2).PreferredWidth = 170
    $table.Columns.Item(3).PreferredWidth = 220
    $table.Rows.Item(1).Range.Shading.BackgroundPatternColor = 12632256

    $doc.SaveAs([ref]$outputPath)
    $doc.Close()
    $word.Quit()

    Write-Output "Created: $outputPath"
}
catch {
    if ($doc -ne $null) { $doc.Close($false) }
    if ($word -ne $null) { $word.Quit() }
    throw
}
