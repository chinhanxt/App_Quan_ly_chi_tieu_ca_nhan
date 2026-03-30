$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_cong_nghe_va_thu_vien.docx"

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
    @('Flutter', 'Framework', 'Nền tảng phát triển giao diện đa nền tảng cho mobile và web admin'),
    @('Dart SDK 3.x', 'Ngôn ngữ / SDK', 'Ngôn ngữ lập trình và môi trường biên dịch của dự án'),
    @('firebase_core', 'Package', 'Khởi tạo và kết nối ứng dụng Flutter với Firebase'),
    @('firebase_auth', 'Package', 'Xử lý xác thực người dùng và đăng nhập'),
    @('cloud_firestore', 'Package', 'Lưu trữ và truy vấn dữ liệu thời gian thực trên Firestore'),
    @('provider', 'Package', 'Quản lý trạng thái và truyền dữ liệu trong ứng dụng'),
    @('intl', 'Package', 'Hỗ trợ định dạng ngày giờ, số và nội địa hóa'),
    @('fl_chart', 'Package', 'Vẽ biểu đồ phục vụ báo cáo và thống kê'),
    @('pdf', 'Package', 'Tạo tài liệu PDF từ dữ liệu của hệ thống'),
    @('printing', 'Package', 'Hỗ trợ xem trước, in và xuất tài liệu PDF'),
    @('google_mlkit_text_recognition', 'Package', 'Nhận diện văn bản từ ảnh, phục vụ OCR'),
    @('share_plus', 'Package', 'Chia sẻ file hoặc nội dung sang ứng dụng khác'),
    @('open_filex', 'Package', 'Mở file đã tạo bằng ứng dụng phù hợp trên thiết bị'),
    @('image_picker', 'Package', 'Chọn ảnh từ thư viện hoặc chụp ảnh bằng camera'),
    @('permission_handler', 'Package', 'Yêu cầu và kiểm soát quyền truy cập thiết bị'),
    @('email_otp', 'Package', 'Hỗ trợ xác thực OTP qua email'),
    @('http', 'Package', 'Gửi request HTTP tới API hoặc dịch vụ ngoài')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text 'BANG CONG NGHE VA THU VIEN SU DUNG' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Du an duoc phat trien bang Flutter va Dart SDK 3.x. Cac goi chinh gom firebase_core, firebase_auth, cloud_firestore, provider, intl, fl_chart, pdf, printing, google_mlkit_text_recognition, share_plus, open_filex, image_picker, permission_handler, email_otp va http.' -Alignment 3 -SpaceAfter 10

    $range = $doc.Bookmarks.Item('\endofdoc').Range
    $table = $doc.Tables.Add($range, $rows.Count + 1, 3)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1, 1) -Text 'Công nghệ / Gói' -Bold $true
    Set-CellText -Cell $table.Cell(1, 2) -Text 'Loại' -Bold $true
    Set-CellText -Cell $table.Cell(1, 3) -Text 'Vai trò trong dự án' -Bold $true

    for ($i = 0; $i -lt $rows.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r, 1) -Text $rows[$i][0]
        Set-CellText -Cell $table.Cell($r, 2) -Text $rows[$i][1]
        Set-CellText -Cell $table.Cell($r, 3) -Text $rows[$i][2]
    }

    $table.Columns.Item(1).PreferredWidth = 150
    $table.Columns.Item(2).PreferredWidth = 80
    $table.Columns.Item(3).PreferredWidth = 260
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
