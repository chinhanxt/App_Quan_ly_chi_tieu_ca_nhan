$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_dac_ta_yeu_cau_chuc_nang.docx"

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

function Add-Title {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text
    )

    $p = $Doc.Content.Paragraphs.Add()
    $p.Range.Text = $Text
    $p.Range.Font.Name = 'Times New Roman'
    $p.Range.Font.Size = 15
    $p.Range.Font.Bold = 1
    $p.Alignment = 1
    $p.SpaceAfter = 10
    $p.Range.InsertParagraphAfter() | Out-Null
}

function Add-Intro {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text
    )

    $p = $Doc.Content.Paragraphs.Add()
    $p.Range.Text = $Text
    $p.Range.Font.Name = 'Times New Roman'
    $p.Range.Font.Size = 12
    $p.Alignment = 3
    $p.SpaceAfter = 10
    $p.Range.InsertParagraphAfter() | Out-Null
}

$rows = @(
    @('U01', 'User', 'Quản lý tài khoản và đăng nhập', 'Đăng ký, đăng nhập, quên mật khẩu, cập nhật hồ sơ cá nhân', 'Email, mật khẩu, thông tin hồ sơ', 'Tài khoản được tạo hoặc truy cập thành công'),
    @('U02', 'User', 'Quản lý giao dịch thu chi', 'Thêm, sửa, xóa và xem lịch sử giao dịch thu nhập hoặc chi tiêu', 'Số tiền, loại giao dịch, danh mục, ngày, ghi chú', 'Giao dịch được lưu và hiển thị trong lịch sử'),
    @('U03', 'User', 'Nhập liệu thông minh bằng AI', 'Người dùng nhập câu lệnh tự nhiên hoặc giọng nói để AI phân tích và tạo giao dịch', 'Nội dung chat hoặc giọng nói', 'Giao dịch nháp hoặc giao dịch được lưu sau khi xác nhận'),
    @('U04', 'User', 'Quản lý ngân sách chi tiêu', 'Thiết lập hạn mức theo danh mục và theo tháng, theo dõi mức độ sử dụng ngân sách', 'Danh mục, hạn mức, tháng áp dụng', 'Ngân sách được lưu và trạng thái cảnh báo được cập nhật'),
    @('U05', 'User', 'Xem báo cáo và thống kê', 'Xem biểu đồ, tổng hợp thu chi, phân tích theo tháng, năm và danh mục', 'Khoảng thời gian, bộ lọc báo cáo', 'Báo cáo và số liệu thống kê được hiển thị'),
    @('A01', 'Admin', 'Xem dashboard hệ thống', 'Theo dõi tình hình hoạt động chung của hệ thống', 'Bộ lọc thời gian nếu có', 'Số lượng người dùng, giao dịch và chỉ số tổng quan'),
    @('A02', 'Admin', 'Quản lý người dùng hệ thống', 'Xem danh sách người dùng, tìm kiếm, khóa hoặc mở khóa tài khoản', 'Mã người dùng, từ khóa tìm kiếm, trạng thái', 'Thông tin người dùng và trạng thái tài khoản được cập nhật'),
    @('A03', 'Admin', 'Quản lý danh mục mặc định', 'Thêm, sửa, xóa danh mục mặc định dùng chung cho hệ thống', 'Tên danh mục, loại, mô tả', 'Danh mục hệ thống được cập nhật')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Title -Doc $doc -Text 'BANG DAC TA YEU CAU CHUC NANG'
    Add-Intro -Doc $doc -Text 'Bang duoi day trinh bay dac ta yeu cau chuc nang theo hai phan he chinh cua he thong la User va Admin. Muc dich la tong hop cac chuc nang tong quat o muc de hieu, de dua vao bao cao hoac nop kem phan phan tich he thong.'

    $range = $doc.Bookmarks.Item('\endofdoc').Range
    $table = $doc.Tables.Add($range, $rows.Count + 1, 6)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Rows.Alignment = 1
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1, 1) -Text 'Mã CN' -Bold $true
    Set-CellText -Cell $table.Cell(1, 2) -Text 'Phân hệ' -Bold $true
    Set-CellText -Cell $table.Cell(1, 3) -Text 'Tên chức năng' -Bold $true
    Set-CellText -Cell $table.Cell(1, 4) -Text 'Mô tả' -Bold $true
    Set-CellText -Cell $table.Cell(1, 5) -Text 'Dữ liệu vào' -Bold $true
    Set-CellText -Cell $table.Cell(1, 6) -Text 'Kết quả đầu ra' -Bold $true

    for ($i = 0; $i -lt $rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r, 1) -Text $rows[$i][0]
        Set-CellText -Cell $table.Cell($r, 2) -Text $rows[$i][1]
        Set-CellText -Cell $table.Cell($r, 3) -Text $rows[$i][2]
        Set-CellText -Cell $table.Cell($r, 4) -Text $rows[$i][3]
        Set-CellText -Cell $table.Cell($r, 5) -Text $rows[$i][4]
        Set-CellText -Cell $table.Cell($r, 6) -Text $rows[$i][5]
    }

    $table.Columns.Item(1).PreferredWidth = 45
    $table.Columns.Item(2).PreferredWidth = 60
    $table.Columns.Item(3).PreferredWidth = 110
    $table.Columns.Item(4).PreferredWidth = 170
    $table.Columns.Item(5).PreferredWidth = 120
    $table.Columns.Item(6).PreferredWidth = 120

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
