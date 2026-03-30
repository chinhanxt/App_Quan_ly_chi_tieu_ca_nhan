$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_kich_ban_demo_user_admin.docx"

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

function Add-DemoTable {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][array]$Rows
    )

    Add-Paragraph -Doc $Doc -Text $Title -FontSize 13 -Bold $true -SpaceAfter 6

    $range = $Doc.Bookmarks.Item('\endofdoc').Range
    $table = $Doc.Tables.Add($range, $Rows.Count + 1, 4)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1, 1) -Text 'Kịch bản demo' -Bold $true
    Set-CellText -Cell $table.Cell(1, 2) -Text 'Người thực hiện' -Bold $true
    Set-CellText -Cell $table.Cell(1, 3) -Text 'Dữ liệu dùng để demo' -Bold $true
    Set-CellText -Cell $table.Cell(1, 4) -Text 'Kết quả mong đợi' -Bold $true

    for ($i = 0; $i -lt $Rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r, 1) -Text $Rows[$i][0]
        Set-CellText -Cell $table.Cell($r, 2) -Text $Rows[$i][1]
        Set-CellText -Cell $table.Cell($r, 3) -Text $Rows[$i][2]
        Set-CellText -Cell $table.Cell($r, 4) -Text $Rows[$i][3]
    }

    $table.Columns.Item(1).PreferredWidth = 130
    $table.Columns.Item(2).PreferredWidth = 90
    $table.Columns.Item(3).PreferredWidth = 170
    $table.Columns.Item(4).PreferredWidth = 170
    $table.Rows.Item(1).Range.Shading.BackgroundPatternColor = 12632256

    $Doc.Range($Doc.Content.End - 1, $Doc.Content.End - 1).InsertParagraphAfter() | Out-Null
}

$userRows = @(
    @('Bước 1. Đăng ký hoặc đăng nhập', 'Người dùng', 'Email, mật khẩu, thông tin hồ sơ cơ bản', 'Xác thực thành công, hệ thống kiểm tra hồ sơ và điều hướng vào khu vực người dùng'),
    @('Bước 2. Thêm giao dịch thủ công', 'Người dùng', 'Số tiền, loại giao dịch, danh mục, ngày, ghi chú', 'Transaction mới xuất hiện trong lịch sử và số dư thay đổi tương ứng'),
    @('Bước 3. Ghi nhận giao dịch bằng AI chat', 'Người dùng', 'Câu đơn, câu nhiều vế, câu mơ hồ, câu có danh mục mới', 'AI phân tích, hỏi lại nếu cần, tạo card xác nhận và lưu đúng giao dịch sau khi đồng ý'),
    @('Bước 4. Nhập giao dịch từ ảnh hóa đơn', 'Người dùng', 'Ảnh hóa đơn hoặc ảnh chụp văn bản chứa nội dung mua bán', 'OCR hoặc vision phân tích và dựng card đề xuất để người dùng xác nhận'),
    @('Bước 5. Tạo ngân sách và kiểm tra cảnh báo', 'Người dùng', 'Hạn mức theo danh mục và giao dịch chi tiêu mới', 'Thanh cảnh báo ngân sách đổi màu theo thời gian thực khi gần chạm hoặc vượt ngưỡng'),
    @('Bước 6. Xem báo cáo và xuất file', 'Người dùng', 'Dữ liệu giao dịch theo tháng và bộ lọc báo cáo', 'Biểu đồ theo tháng, phân tích theo danh mục và file báo cáo được xuất thành công'),
    @('Bước 7. Tạo mục tiêu tiết kiệm và nạp tiền', 'Người dùng', 'Tên mục tiêu, số tiền mục tiêu, số tiền nạp', 'Mục tiêu được tạo, số tiền tích lũy tăng và tiến độ thay đổi trực quan')
)

$adminRows = @(
    @('Bước 1. Đăng nhập web admin', 'Admin', 'Tài khoản admin hợp lệ', 'Đăng nhập thành công vào khu vực quản trị web'),
    @('Bước 2. Xem overview hệ thống', 'Admin', 'Dữ liệu tổng quan về user, giao dịch, danh mục, broadcast', 'Hiển thị các chỉ số hệ thống trên overview page'),
    @('Bước 3. Khóa một user', 'Admin', 'Một tài khoản user đang hoạt động', 'User bị đổi trạng thái và client đang lắng nghe sẽ nhận cập nhật mới rồi bị chặn truy cập'),
    @('Bước 4. Thêm danh mục hệ thống hoặc broadcast', 'Admin', 'Tên danh mục mới hoặc nội dung broadcast', 'Backend cập nhật thành công và client nhận thay đổi theo luồng realtime'),
    @('Bước 5. Cấu hình AI runtime', 'Admin', 'Runtime draft, câu giao dịch mẫu để preview, cấu hình publish', 'Admin xem preview, thay đổi cấu hình và publish thành công để áp dụng vào hệ thống')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text 'BANG MO TA KICH BAN DEMO USER VA ADMIN' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Phan nay trinh bay cac kich ban demo chinh cua he thong theo hai nhom User va Admin. Moi bang mo ta ro kich ban demo, nguoi thuc hien, du lieu dung de demo va ket qua mong doi, phuc vu cho viec thuyet trinh va bao ve do an.' -Alignment 3 -SpaceAfter 10

    Add-DemoTable -Doc $doc -Title 'Bảng 1. Kịch bản demo các chức năng người dùng' -Rows $userRows
    Add-DemoTable -Doc $doc -Title 'Bảng 2. Kịch bản demo các chức năng admin' -Rows $adminRows

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
