$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_tom_tat_testcase_muc_6_3.docx"

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
        [AllowEmptyString()][string]$Text,
        [bool]$Bold = $false,
        [int]$FontSize = 11
    )
    $Cell.Range.Text = $Text
    $Cell.Range.Font.Name = 'Times New Roman'
    $Cell.Range.Font.Size = $FontSize
    $Cell.Range.Font.Bold = [int]$Bold
}

$rows = @(
    @('TC01', 'Đăng nhập đúng thông tin', '', 'Vào đúng dashboard theo vai trò'),
    @('TC02', 'Đăng nhập sai mật khẩu', '', 'Báo lỗi chính xác và không vào hệ thống'),
    @('TC03', 'Tài khoản bị khóa', '', 'Bị chặn truy cập và hiển thị thông báo tương ứng'),
    @('TC04', 'Thêm giao dịch thủ công đầy đủ dữ liệu', '', 'Giao dịch được lưu, số dư cập nhật'),
    @('TC05', 'Sửa giao dịch', '', 'Tổng thu hoặc tổng chi hoặc số dư được tính lại đúng'),
    @('TC06', 'Xóa giao dịch', '', 'Dữ liệu bị xóa và hồ sơ tài chính được rollback đúng'),
    @('TC07', 'AI parse câu đơn', 'Ăn sáng 30k', 'Amount bằng 30000, type là debit, category phù hợp'),
    @('TC08', 'AI parse câu nhiều vế', 'Ăn tối 50k và đổ xăng 30k', 'Tạo 2 transaction draft'),
    @('TC09', 'AI gặp câu mơ hồ', 'Hôm trước mua đồ 200k', 'Hệ thống hỏi lại ngày chính xác nếu cần'),
    @('TC10', 'Tạo ngân sách và thêm giao dịch dưới ngưỡng 80 phần trăm', '', 'Màu xanh'),
    @('TC11', 'Tạo ngân sách và thêm giao dịch đạt vùng 80 đến 100 phần trăm', '', 'Màu cam'),
    @('TC12', 'Thêm giao dịch vượt ngân sách', '', 'Màu đỏ và hiển thị mức vượt'),
    @('TC13', 'Admin khóa user', '', 'User không truy cập được hệ thống'),
    @('TC14', 'Admin thêm broadcast', '', 'Dữ liệu broadcast được lưu và client liên quan có thể đọc được'),
    @('TC15', 'Admin publish runtime AI', '', 'Cấu hình mới được ghi vào system_configs và có log quản trị tương ứng')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text '6.3. BỘ TEST CASE CHO 5 CHỨC NĂNG CHÍNH' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Để phục vụ kiểm thử chức năng, nhóm xây dựng bộ test case tóm tắt cho 5 nhóm chức năng chính của hệ thống. Bảng dưới đây liệt kê mã test, nội dung kiểm thử, dữ liệu đầu vào tiêu biểu và kết quả mong đợi tương ứng. Các bảng chi tiết và kết quả thực thi sẽ được trình bày ở mục 6.4.' -Alignment 3 -SpaceAfter 10

    $range = $doc.Bookmarks.Item('\endofdoc').Range
    $table = $doc.Tables.Add($range, $rows.Count + 1, 4)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 11
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1,1) -Text 'Mã test' -Bold $true
    Set-CellText -Cell $table.Cell(1,2) -Text 'Nội dung kiểm thử' -Bold $true
    Set-CellText -Cell $table.Cell(1,3) -Text 'Dữ liệu đầu vào tiêu biểu' -Bold $true
    Set-CellText -Cell $table.Cell(1,4) -Text 'Kết quả mong đợi' -Bold $true

    for ($i = 0; $i -lt $rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r,1) -Text $rows[$i][0]
        Set-CellText -Cell $table.Cell($r,2) -Text $rows[$i][1]
        Set-CellText -Cell $table.Cell($r,3) -Text $rows[$i][2]
        Set-CellText -Cell $table.Cell($r,4) -Text $rows[$i][3]
    }

    $table.Columns.Item(1).PreferredWidth = 55
    $table.Columns.Item(2).PreferredWidth = 180
    $table.Columns.Item(3).PreferredWidth = 130
    $table.Columns.Item(4).PreferredWidth = 180
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
