$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\thiet_ke_giao_dien_admin_web.docx"

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
    @('Entry admin web', 'lib/main_admin_web.dart', 'Điểm khởi tạo riêng cho phân hệ quản trị và chỉ hỗ trợ khi chạy trên trình duyệt'),
    @('AdminWebApp', 'lib/admin_web/admin_web_app.dart', 'Ứng dụng gốc của admin web'),
    @('AdminWebShell', 'lib/admin_web/admin_web_shell.dart', 'Khung điều hướng và bố cục tổng thể của giao diện admin'),
    @('OverviewPage', 'lib/admin_web/pages/overview_page.dart', 'Trang tổng quan với hero panel, summary panel và các metric card điều hành'),
    @('UsersPage', 'lib/admin_web/pages/users_page.dart', 'Trang quản lý danh sách người dùng và trạng thái tài khoản'),
    @('TransactionsPage', 'lib/admin_web/pages/transactions_page.dart', 'Trang theo dõi giao dịch toàn hệ thống'),
    @('CategoriesPage', 'lib/admin_web/pages/categories_page.dart', 'Trang quản lý danh mục hệ thống'),
    @('ReportsPage', 'lib/admin_web/pages/reports_page.dart', 'Trang báo cáo và thống kê quản trị'),
    @('BroadcastsPage', 'lib/admin_web/pages/broadcasts_page.dart', 'Trang quản lý thông báo hệ thống và broadcast'),
    @('SystemConfigsPage', 'lib/admin_web/pages/system_configs_page.dart', 'Trang quản lý cấu hình hệ thống'),
    @('AiConfigPage', 'lib/admin_web/pages/ai_config_page.dart', 'Trang giám sát, chỉnh prompt, preview và publish cấu hình AI'),
    @('AdminWebRepository', 'lib/admin_web/admin_web_repository.dart', 'Lớp truy cập dữ liệu và nghiệp vụ phục vụ toàn bộ admin web')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text 'THIET KE GIAO DIEN ADMIN WEB' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Admin web co entry rieng tu main_admin_web.dart, chi ho tro khi chay tren trinh duyet. Dieu nay cho thay du an co dinh huong da nen tang nhung van biet phan dinh ngu canh su dung cua tung phan he.' -Alignment 3 -SpaceAfter 8
    Add-Paragraph -Doc $doc -Text 'OverviewPage la trang tong quan voi hero panel, summary panel va nhieu metric card nhu so nguoi dung, so admin, danh muc he thong, broadcast dang bat, giao dich thang, tong thu, tong chi va so du toan he thong. Viec gom nhieu chi so o day giup admin co mot cockpit de dieu hanh.' -Alignment 3 -SpaceAfter 8
    Add-Paragraph -Doc $doc -Text 'UsersPage, TransactionsPage, CategoriesPage, ReportsPage, BroadcastsPage, SystemConfigsPage va AiConfigPage tao thanh bo cong cu quan tri day du. Trong do AiConfigPage dac biet quan trong vi cho thay he thong khong xem AI la mot khoi den co dinh ma cho phep giam sat, chinh prompt, preview va publish.' -Alignment 3 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Bang duoi day quy doi cac thanh phan va trang admin web sang ten file thuc te trong du an.' -SpaceAfter 8

    $range = $doc.Bookmarks.Item('\endofdoc').Range
    $table = $doc.Tables.Add($range, $rows.Count + 1, 3)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1, 1) -Text 'Thành phần / Trang' -Bold $true
    Set-CellText -Cell $table.Cell(1, 2) -Text 'Tên file thực tế' -Bold $true
    Set-CellText -Cell $table.Cell(1, 3) -Text 'Vai trò trong admin web' -Bold $true

    for ($i = 0; $i -lt $rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r, 1) -Text $rows[$i][0]
        Set-CellText -Cell $table.Cell($r, 2) -Text $rows[$i][1]
        Set-CellText -Cell $table.Cell($r, 3) -Text $rows[$i][2]
    }

    $table.Columns.Item(1).PreferredWidth = 125
    $table.Columns.Item(2).PreferredWidth = 180
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
