$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\loi_cam_doan_loi_cam_on_va_tu_viet_tat.docx"

function Add-Paragraph {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$Text,
        [int]$FontSize = 12,
        [bool]$Bold = $false,
        [int]$Alignment = 0,
        [int]$SpaceAfter = 6,
        [bool]$Italic = $false
    )

    $p = $Doc.Content.Paragraphs.Add()
    $p.Range.Text = $Text
    $p.Range.Font.Name = 'Times New Roman'
    $p.Range.Font.Size = $FontSize
    $p.Range.Font.Bold = [int]$Bold
    $p.Range.Font.Italic = [int]$Italic
    $p.Alignment = $Alignment
    $p.SpaceAfter = $SpaceAfter
    $p.Range.InsertParagraphAfter() | Out-Null
}

function Set-CellText {
    param(
        [Parameter(Mandatory = $true)][object]$Cell,
        [AllowEmptyString()][string]$Text,
        [bool]$Bold = $false,
        [int]$FontSize = 12
    )

    $Cell.Range.Text = $Text
    $Cell.Range.Font.Name = 'Times New Roman'
    $Cell.Range.Font.Size = $FontSize
    $Cell.Range.Font.Bold = [int]$Bold
}

$abbrs = @(
    @('AI', 'Artificial Intelligence', 'Trí tuệ nhân tạo'),
    @('API', 'Application Programming Interface', 'Giao diện lập trình ứng dụng'),
    @('BaaS', 'Backend as a Service', 'Mô hình backend cung cấp như một dịch vụ'),
    @('CRUD', 'Create, Read, Update, Delete', 'Các thao tác tạo, đọc, cập nhật và xóa dữ liệu'),
    @('CSV', 'Comma-Separated Values', 'Định dạng tệp dữ liệu phân tách bằng dấu phẩy'),
    @('DB', 'Database', 'Cơ sở dữ liệu'),
    @('ERD', 'Entity Relationship Diagram', 'Sơ đồ thực thể liên kết'),
    @('Firebase Auth', 'Firebase Authentication', 'Dịch vụ xác thực người dùng của Firebase'),
    @('Firestore', 'Cloud Firestore', 'Cơ sở dữ liệu thời gian thực dạng NoSQL của Firebase'),
    @('HTML', 'HyperText Markup Language', 'Ngôn ngữ đánh dấu siêu văn bản'),
    @('HTTP', 'HyperText Transfer Protocol', 'Giao thức truyền tải siêu văn bản'),
    @('ID', 'Identifier', 'Mã định danh'),
    @('JSON', 'JavaScript Object Notation', 'Định dạng dữ liệu dạng đối tượng'),
    @('MSSV', 'Mã số sinh viên', 'Mã số sinh viên'),
    @('NoSQL', 'Not Only SQL', 'Mô hình cơ sở dữ liệu phi quan hệ'),
    @('OCR', 'Optical Character Recognition', 'Nhận dạng ký tự quang học từ ảnh'),
    @('OTP', 'One-Time Password', 'Mật khẩu sử dụng một lần'),
    @('PDF', 'Portable Document Format', 'Định dạng tài liệu điện tử'),
    @('RBAC', 'Role-Based Access Control', 'Cơ chế phân quyền theo vai trò'),
    @('SDK', 'Software Development Kit', 'Bộ công cụ phát triển phần mềm'),
    @('UI', 'User Interface', 'Giao diện người dùng'),
    @('UID', 'User Identifier', 'Mã định danh người dùng'),
    @('UX', 'User Experience', 'Trải nghiệm người dùng'),
    @('Web', 'Web Application', 'Ứng dụng chạy trên trình duyệt')
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text 'LỜI CAM ĐOAN' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Nhóm TRACKER xin cam đoan rằng toàn bộ nội dung trình bày trong báo cáo này là kết quả của quá trình học tập, nghiên cứu, phân tích, thiết kế, cài đặt và kiểm thử do chính nhóm thực hiện dưới sự hướng dẫn của giảng viên phụ trách là cô Trần Thị Vân Anh. Các nội dung về ý tưởng, mô hình triển khai, mã nguồn, sơ đồ, bảng biểu và phần trình bày trong báo cáo đều được nhóm xây dựng dựa trên quá trình thực hiện đề tài, bám sát phạm vi môn học và mục tiêu đã đề ra.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Nhóm hiểu rõ trách nhiệm học thuật đối với một báo cáo tốt nghiệp hoặc đồ án môn học, vì vậy các tài liệu, công nghệ, thư viện và nguồn tham khảo được sử dụng trong quá trình thực hiện đều đã được cân nhắc, đối chiếu và trích dẫn theo mức độ phù hợp. Nhóm không cố ý sao chép nguyên văn công trình của cá nhân hoặc tổ chức khác để nhận là kết quả của mình. Trong trường hợp có sử dụng tư liệu, tài liệu kỹ thuật hoặc nội dung tham khảo từ các nguồn chính thống, nhóm đều có ý thức ghi nhận nguồn để bảo đảm tính trung thực và tôn trọng quyền sở hữu trí tuệ.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Nếu có sai sót, thiếu sót hoặc vấn đề phát sinh liên quan đến tính chính xác của nội dung báo cáo, nhóm TRACKER xin nghiêm túc tiếp thu ý kiến góp ý của giảng viên và hoàn toàn chịu trách nhiệm trong phạm vi phần việc mà nhóm đã thực hiện. Nhóm rất mong nhận được sự chỉ bảo và góp ý thêm từ cô để có thể hoàn thiện đề tài tốt hơn.' -Alignment 3 -SpaceAfter 12

    Add-Paragraph -Doc $doc -Text 'LỜI CẢM ƠN' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Nhóm TRACKER xin bày tỏ lòng biết ơn chân thành và sâu sắc đến cô Trần Thị Vân Anh, giảng viên hướng dẫn, người đã tận tình định hướng, góp ý và hỗ trợ nhóm trong suốt quá trình thực hiện đề tài. Những nhận xét chuyên môn, sự nghiêm túc trong học thuật cùng sự động viên kịp thời của cô đã giúp nhóm từng bước hoàn thiện cả về nội dung báo cáo lẫn chất lượng sản phẩm.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Nhóm cũng xin chân thành cảm ơn quý thầy cô trong khoa đã trang bị cho chúng em nền tảng kiến thức cần thiết về công nghệ phần mềm, phân tích thiết kế hệ thống, lập trình ứng dụng và kiểm thử phần mềm. Đây là cơ sở quan trọng để nhóm có thể vận dụng vào quá trình xây dựng hệ thống quản lý tài chính cá nhân tích hợp AI và phân hệ quản trị web.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Bên cạnh đó, nhóm xin cảm ơn các thành viên trong nhóm TRACKER đã cùng nhau phối hợp, trao đổi và hỗ trợ trong suốt quá trình thực hiện đề tài. Dù còn những hạn chế nhất định về thời gian, kinh nghiệm và phạm vi triển khai, nhóm đã luôn cố gắng làm việc với tinh thần trách nhiệm, cầu thị và mong muốn hoàn thiện sản phẩm ở mức tốt nhất có thể. Nhóm kính mong tiếp tục nhận được sự góp ý quý báu từ cô và quý thầy cô để đề tài được hoàn thiện hơn trong thời gian tới.' -Alignment 3 -SpaceAfter 12

    Add-Paragraph -Doc $doc -Text 'BẢNG CÁC TỪ VIẾT TẮT' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Bảng dưới đây tổng hợp các từ viết tắt xuất hiện phổ biến trong báo cáo chi tiết nhằm giúp việc theo dõi nội dung được thuận tiện và thống nhất hơn.' -Alignment 3 -SpaceAfter 8

    $range = $doc.Bookmarks.Item('\endofdoc').Range
    $table = $doc.Tables.Add($range, $abbrs.Count + 1, 3)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1,1) -Text 'Từ viết tắt' -Bold $true
    Set-CellText -Cell $table.Cell(1,2) -Text 'Tên đầy đủ' -Bold $true
    Set-CellText -Cell $table.Cell(1,3) -Text 'Ý nghĩa / Diễn giải' -Bold $true

    for ($i = 0; $i -lt $abbrs.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r,1) -Text $abbrs[$i][0]
        Set-CellText -Cell $table.Cell($r,2) -Text $abbrs[$i][1]
        Set-CellText -Cell $table.Cell($r,3) -Text $abbrs[$i][2]
    }

    $table.Columns.Item(1).PreferredWidth = 80
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
