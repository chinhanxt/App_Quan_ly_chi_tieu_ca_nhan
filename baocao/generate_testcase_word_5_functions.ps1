$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_testcase_5_chuc_nang_cho_bao_cao.docx"

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
        [int]$FontSize = 11
    )
    $Cell.Range.Text = $Text
    $Cell.Range.Font.Name = 'Times New Roman'
    $Cell.Range.Font.Size = $FontSize
    $Cell.Range.Font.Bold = [int]$Bold
}

function Add-TestTable {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][array]$Rows
    )

    Add-Paragraph -Doc $Doc -Text $Title -FontSize 13 -Bold $true -SpaceAfter 6

    $range = $Doc.Bookmarks.Item('\endofdoc').Range
    $table = $Doc.Tables.Add($range, $Rows.Count + 1, 7)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 11
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1,1) -Text 'ID' -Bold $true
    Set-CellText -Cell $table.Cell(1,2) -Text 'Items' -Bold $true
    Set-CellText -Cell $table.Cell(1,3) -Text 'Sub-items' -Bold $true
    Set-CellText -Cell $table.Cell(1,4) -Text 'Description' -Bold $true
    Set-CellText -Cell $table.Cell(1,5) -Text 'PreCondition' -Bold $true
    Set-CellText -Cell $table.Cell(1,6) -Text 'Expected output' -Bold $true
    Set-CellText -Cell $table.Cell(1,7) -Text 'Test Data / Parameters' -Bold $true

    for ($i = 0; $i -lt $Rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r,1) -Text $Rows[$i][0]
        Set-CellText -Cell $table.Cell($r,2) -Text $Rows[$i][1]
        Set-CellText -Cell $table.Cell($r,3) -Text $Rows[$i][2]
        Set-CellText -Cell $table.Cell($r,4) -Text $Rows[$i][3]
        Set-CellText -Cell $table.Cell($r,5) -Text $Rows[$i][4]
        Set-CellText -Cell $table.Cell($r,6) -Text $Rows[$i][5]
        Set-CellText -Cell $table.Cell($r,7) -Text $Rows[$i][6]
    }

    $table.Columns.Item(1).PreferredWidth = 45
    $table.Columns.Item(2).PreferredWidth = 70
    $table.Columns.Item(3).PreferredWidth = 80
    $table.Columns.Item(4).PreferredWidth = 115
    $table.Columns.Item(5).PreferredWidth = 100
    $table.Columns.Item(6).PreferredWidth = 120
    $table.Columns.Item(7).PreferredWidth = 110
    $table.Rows.Item(1).Range.Shading.BackgroundPatternColor = 12632256

    $Doc.Range($Doc.Content.End - 1, $Doc.Content.End - 1).InsertParagraphAfter() | Out-Null
}

$loginRows = @(
    @('TC01','Đăng nhập','Đúng thông tin','Đăng nhập đúng thông tin tài khoản','Đã có tài khoản user hợp lệ','Xác thực thành công và vào đúng dashboard theo vai trò','Email: userdemo@app.com; Mật khẩu: User@123'),
    @('TC02','Đăng nhập','Sai mật khẩu','Đăng nhập với mật khẩu không chính xác','Đã có tài khoản user hợp lệ','Báo lỗi xác thực và không cho truy cập','Email: userdemo@app.com; Mật khẩu sai: 123456'),
    @('TC03','Đăng nhập','Tài khoản bị khóa','Tài khoản đã bị admin khóa thử đăng nhập','Tài khoản có status locked','Hệ thống chặn truy cập và hiển thị thông báo phù hợp','Email: locked_user@app.com; Mật khẩu: User@123')
)

$transactionRows = @(
    @('TC04','Giao dịch','Thêm mới','Thêm giao dịch thủ công đầy đủ dữ liệu','Người dùng đã đăng nhập','Giao dịch được lưu, xuất hiện trong lịch sử và cập nhật số dư','Debit; 50000; Ăn uống; Ăn sáng'),
    @('TC05','Giao dịch','Sửa giao dịch','Chỉnh sửa một giao dịch đã tồn tại','Đã có ít nhất một giao dịch','Dữ liệu giao dịch được cập nhật và các tổng số được tính lại đúng','Từ 50000 thành 80000'),
    @('TC06','Giao dịch','Xóa giao dịch','Xóa một giao dịch đã tạo trước đó','Đã có ít nhất một giao dịch','Giao dịch bị xóa và hồ sơ tài chính rollback đúng','Giao dịch: Mua trà sữa 30000')
)

$aiRows = @(
    @('TC07','AI Parser','Câu đơn','AI phân tích một câu đơn giản để tạo giao dịch','Đã vào AI Input Screen','AI trả amount 30000, type debit và category phù hợp','Input: ăn sáng 30k'),
    @('TC08','AI Parser','Câu nhiều vế','AI tách một câu nhiều hành động thành nhiều giao dịch','Đã vào AI Input Screen','Tạo 2 transaction draft riêng biệt trước khi xác nhận','Input: ăn tối 50k và đổ xăng 30k'),
    @('TC09','AI Parser','Câu mơ hồ','AI gặp câu chưa rõ thời gian hoặc ngữ cảnh','Đã vào AI Input Screen','Yêu cầu người dùng bổ sung thông tin nếu cần','Input: hôm trước mua đồ 200k')
)

$budgetRows = @(
    @('TC10','Ngân sách','Dưới 80%','Tạo ngân sách và thêm giao dịch dưới ngưỡng cảnh báo','Đã có danh mục và tháng hiện tại','Thanh tiến độ hiển thị màu xanh','Ngân sách 1000000; Tổng chi 300000'),
    @('TC11','Ngân sách','Từ 80%-100%','Thêm giao dịch để ngân sách vào vùng cảnh báo','Đã có ngân sách tháng hiện tại','Thanh tiến độ đổi sang màu cam hoặc vàng','Ngân sách 1000000; Tổng chi 900000'),
    @('TC12','Ngân sách','Vượt ngưỡng','Thêm giao dịch vượt quá hạn mức ngân sách','Đã có ngân sách tháng hiện tại','Thanh tiến độ chuyển sang màu đỏ và hiển thị mức vượt','Ngân sách 1000000; Tổng chi 1200000')
)

$adminRows = @(
    @('TC13','Admin','Khóa user','Admin khóa tài khoản người dùng đang hoạt động','Admin đã đăng nhập web admin','User bị đổi trạng thái và client bị chặn truy cập','User mục tiêu: userdemo@app.com'),
    @('TC14','Admin','Thêm broadcast','Admin tạo một broadcast mới cho hệ thống','Admin đã đăng nhập web admin','Broadcast được lưu và client liên quan đọc được theo realtime','Tiêu đề: Bảo trì hệ thống'),
    @('TC15','Admin','Publish AI runtime','Admin thay đổi cấu hình runtime AI và publish','Admin có quyền cấu hình AI','Cấu hình mới được ghi vào system_configs và có log quản trị','Prompt mẫu: ăn sáng 30k; Runtime draft mới')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text '6.3. BO TEST CASE CHO 5 CHUC NANG CHINH' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Bang duoi day trinh bay cac test case tieu bieu cho 5 chuc nang chinh cua he thong. Cau truc bang duoc thiet ke kha tuong dong voi file Excel testcase de de doi chieu, dong thoi gon hon de phu hop khi chen vao bao cao Word.' -Alignment 3 -SpaceAfter 10

    Add-TestTable -Doc $doc -Title 'Bảng 6.1. Nhóm test chức năng đăng nhập và xác thực' -Rows $loginRows
    Add-TestTable -Doc $doc -Title 'Bảng 6.2. Nhóm test chức năng quản lý giao dịch thủ công' -Rows $transactionRows
    Add-TestTable -Doc $doc -Title 'Bảng 6.3. Nhóm test chức năng ghi nhận giao dịch bằng AI' -Rows $aiRows
    Add-TestTable -Doc $doc -Title 'Bảng 6.4. Nhóm test chức năng quản lý ngân sách' -Rows $budgetRows
    Add-TestTable -Doc $doc -Title 'Bảng 6.5. Nhóm test chức năng quản trị hệ thống' -Rows $adminRows

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
