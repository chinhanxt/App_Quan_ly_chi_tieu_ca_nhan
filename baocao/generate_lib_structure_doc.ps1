$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_mo_ta_cau_truc_lib.docx"

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
    @('main.dart', 'Điểm khởi đầu của ứng dụng Mobile. Cấu hình theme, điều hướng ban đầu và khởi tạo các dịch vụ cho người dùng cuối.', 'Tầng giao diện'),
    @('main_admin_web.dart', 'Điểm khởi đầu của ứng dụng Admin Web. Thiết lập môi trường chạy trên trình duyệt và các cấu hình đặc thù cho quản trị viên.', 'Tầng giao diện'),
    @('admin_web/', 'Phân hệ dành riêng cho Admin. Chứa shell giao diện web, repository nghiệp vụ quản trị và các trang phục vụ quản trị người dùng, danh mục và dashboard.', 'Tầng giao diện và nghiệp vụ'),
    @('screens/', 'Chứa các màn hình nghiệp vụ chính cho Mobile như Home, Transaction, Budget, Chat AI. Quản lý luồng hiển thị của từng tính năng cụ thể.', 'Tầng giao diện'),
    @('widgets/', 'Tập hợp các thành phần UI tái sử dụng như button, form, card, chart widget nhằm bảo đảm tính nhất quán giao diện.', 'Tầng giao diện'),
    @('services/', 'Chứa logic nghiệp vụ và giao tiếp với dữ liệu như xác thực, Firestore, AI runtime và các phép tính xử lý chính của hệ thống.', 'Tầng nghiệp vụ'),
    @('models/', 'Định nghĩa cấu trúc dữ liệu và ánh xạ giữa code với Firestore thông qua các model và hàm chuyển đổi dữ liệu.', 'Tầng dữ liệu'),
    @('providers/', 'Quản lý trạng thái ứng dụng, đồng bộ dữ liệu từ services ra giao diện và hỗ trợ cập nhật dữ liệu theo luồng phản ứng.', 'Tầng nghiệp vụ'),
    @('utils/', 'Chứa hằng số, hàm tiện ích và helper dùng chung cho toàn bộ dự án như định dạng dữ liệu và kiểm tra chuỗi.', 'Bổ trợ')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text 'BANG MO TA CAU TRUC THU MUC LIB' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Thu muc lib chua phan lon ma nguon cua he thong. main.dart la entry point cho mobile app, main_admin_web.dart la entry point cho admin web. screens chua cac man hinh nghiep vu; widgets chua thanh phan tai su dung; services chua logic va giao tiep voi du lieu; models chua cau truc du lieu; admin_web chua repository, shell va cac page phuc vu quan tri. Viec tach admin_web rieng la hop ly vi day la mot phan he co trai nghiem, luong dieu huong va nghiep vu quan tri khac biet voi nguoi dung mobile. Tuy van dung cung codebase Flutter, cach to chuc tach biet giup de phat trien va tranh lan logic nguoi dung voi logic admin.' -Alignment 3 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text '[BANG - UU TIEN TRUNG BINH] Bang mo ta tung thu muc chinh trong lib va trach nhiem cua tung thu muc.' -FontSize 12 -Bold $true -SpaceAfter 8

    $range = $doc.Bookmarks.Item('\endofdoc').Range
    $table = $doc.Tables.Add($range, $rows.Count + 1, 3)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1, 1) -Text 'Thu muc / Tep tin' -Bold $true
    Set-CellText -Cell $table.Cell(1, 2) -Text 'Trach nhiem va vai tro' -Bold $true
    Set-CellText -Cell $table.Cell(1, 3) -Text 'Thuoc tang kien truc' -Bold $true

    for ($i = 0; $i -lt $rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r, 1) -Text $rows[$i][0]
        Set-CellText -Cell $table.Cell($r, 2) -Text $rows[$i][1]
        Set-CellText -Cell $table.Cell($r, 3) -Text $rows[$i][2]
    }

    $table.Columns.Item(1).PreferredWidth = 110
    $table.Columns.Item(2).PreferredWidth = 300
    $table.Columns.Item(3).PreferredWidth = 110
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
