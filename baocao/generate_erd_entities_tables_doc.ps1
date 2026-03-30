$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_erd_quy_doi_thuc_the.docx"

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

function Add-EntityTable {
    param(
        [Parameter(Mandatory = $true)][object]$Doc,
        [Parameter(Mandatory = $true)][string]$EntityName,
        [Parameter(Mandatory = $true)][array]$Fields,
        [string]$Description = ''
    )

    Add-Paragraph -Doc $Doc -Text "Bảng thực thể $EntityName" -FontSize 13 -Bold $true -SpaceAfter 6
    if ($Description) {
        Add-Paragraph -Doc $Doc -Text $Description -FontSize 12 -SpaceAfter 6
    }

    $range = $Doc.Bookmarks.Item('\endofdoc').Range
    $table = $Doc.Tables.Add($range, $Fields.Count + 1, 3)
    $table.Borders.Enable = 1
    $table.Range.Font.Name = 'Times New Roman'
    $table.Range.Font.Size = 12
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Rows.Alignment = 1
    $table.AllowAutoFit = $true

    Set-CellText -Cell $table.Cell(1, 1) -Text 'STT' -Bold $true
    Set-CellText -Cell $table.Cell(1, 2) -Text 'Thuộc tính' -Bold $true
    Set-CellText -Cell $table.Cell(1, 3) -Text 'Mô tả ngắn' -Bold $true

    for ($i = 0; $i -lt $Fields.Count; $i++) {
        $r = $i + 2
        Set-CellText -Cell $table.Cell($r, 1) -Text ([string]($i + 1))
        Set-CellText -Cell $table.Cell($r, 2) -Text $Fields[$i][0]
        Set-CellText -Cell $table.Cell($r, 3) -Text $Fields[$i][1]
    }

    $table.Columns.Item(1).PreferredWidth = 35
    $table.Columns.Item(2).PreferredWidth = 120
    $table.Columns.Item(3).PreferredWidth = 290
    $table.Rows.Item(1).Range.Shading.BackgroundPatternColor = 12632256

    $Doc.Range($Doc.Content.End - 1, $Doc.Content.End - 1).InsertParagraphAfter() | Out-Null
}

$entities = @(
    @{
        Name = 'User'
        Description = 'Thực thể lưu thông tin tài khoản người dùng và các chỉ số tài chính tổng hợp.'
        Fields = @(
            @('id', 'Mã định danh duy nhất của người dùng'),
            @('email', 'Địa chỉ email đăng nhập'),
            @('name / username', 'Tên hiển thị hoặc tên người dùng'),
            @('role', 'Vai trò trong hệ thống như user hoặc admin'),
            @('status', 'Trạng thái tài khoản như active hoặc locked'),
            @('totalCredit', 'Tổng số tiền thu vào đã ghi nhận'),
            @('totalDebit', 'Tổng số tiền chi ra đã ghi nhận'),
            @('remainingAmount', 'Số dư còn lại của người dùng'),
            @('createdAt', 'Thời điểm tạo tài khoản'),
            @('updatedAt', 'Thời điểm cập nhật gần nhất')
        )
    },
    @{
        Name = 'Transaction'
        Description = 'Thực thể lưu các giao dịch thu chi phát sinh của người dùng.'
        Fields = @(
            @('id', 'Mã định danh duy nhất của giao dịch'),
            @('title', 'Tiêu đề hoặc tên ngắn của giao dịch'),
            @('amount', 'Số tiền của giao dịch'),
            @('type', 'Loại giao dịch như credit hoặc debit'),
            @('category', 'Danh mục giao dịch'),
            @('note', 'Ghi chú bổ sung cho giao dịch'),
            @('timestamp', 'Thời điểm giao dịch phát sinh'),
            @('monthyear', 'Tháng năm dùng để gom nhóm báo cáo')
        )
    },
    @{
        Name = 'Budget'
        Description = 'Thực thể lưu hạn mức chi tiêu theo danh mục và theo tháng.'
        Fields = @(
            @('id', 'Mã định danh duy nhất của ngân sách'),
            @('categoryName', 'Tên danh mục áp dụng ngân sách'),
            @('limitAmount', 'Hạn mức chi tối đa'),
            @('monthyear', 'Tháng năm áp dụng ngân sách'),
            @('createdAt', 'Thời điểm tạo ngân sách')
        )
    },
    @{
        Name = 'SavingGoal'
        Description = 'Thực thể lưu mục tiêu tiết kiệm mà người dùng thiết lập.'
        Fields = @(
            @('id', 'Mã định danh duy nhất của mục tiêu tiết kiệm'),
            @('name', 'Tên mục tiêu tiết kiệm'),
            @('targetAmount', 'Số tiền mục tiêu cần đạt'),
            @('currentAmount', 'Số tiền hiện đã tích lũy'),
            @('startDate', 'Ngày bắt đầu mục tiêu'),
            @('targetDate', 'Ngày dự kiến hoàn thành'),
            @('icon', 'Biểu tượng đại diện cho mục tiêu'),
            @('color', 'Màu sắc hiển thị của mục tiêu'),
            @('status', 'Trạng thái mục tiêu như active hoặc completed'),
            @('createdAt', 'Thời điểm tạo mục tiêu')
        )
    },
    @{
        Name = 'Contribution'
        Description = 'Thực thể lưu các lần đóng góp tiền vào một SavingGoal cụ thể.'
        Fields = @(
            @('amount', 'Số tiền đóng góp vào mục tiêu'),
            @('date', 'Ngày thực hiện đóng góp'),
            @('createdAt', 'Thời điểm tạo bản ghi đóng góp'),
            @('savingGoalId', 'Khóa liên kết cho biết đóng góp thuộc về SavingGoal nào')
        )
    },
    @{
        Name = 'Category'
        Description = 'Thực thể lưu danh mục giao dịch dùng cho người dùng hoặc hệ thống.'
        Fields = @(
            @('id', 'Mã định danh duy nhất của danh mục'),
            @('name', 'Tên danh mục'),
            @('type', 'Loại danh mục như thu hoặc chi'),
            @('iconName', 'Tên icon hiển thị cho danh mục'),
            @('createdAt', 'Thời điểm tạo danh mục'),
            @('updatedAt', 'Thời điểm cập nhật danh mục gần nhất'),
            @('isDefault', 'Cho biết danh mục có phải mặc định của hệ thống hay không')
        )
    },
    @{
        Name = 'Broadcast'
        Description = 'Thực thể lưu các thông báo hoặc bản tin do quản trị viên phát ra.'
        Fields = @(
            @('title', 'Tiêu đề thông báo'),
            @('content', 'Nội dung chi tiết của thông báo'),
            @('type', 'Loại broadcast như info, warning hoặc maintenance'),
            @('status', 'Trạng thái hiển thị của broadcast'),
            @('createdAt', 'Thời điểm tạo broadcast'),
            @('updatedAt', 'Thời điểm cập nhật broadcast gần nhất'),
            @('createdByEmail', 'Email của quản trị viên đã tạo broadcast')
        )
    },
    @{
        Name = 'SystemConfig'
        Description = 'Thực thể lưu cấu hình tổng quát của hệ thống.'
        Fields = @(
            @('id', 'Mã định danh của cấu hình hệ thống'),
            @('data', 'Nội dung cấu hình được lưu dưới dạng dữ liệu tổng hợp'),
            @('updatedAt', 'Thời điểm cập nhật cấu hình gần nhất')
        )
    }
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text '3.6. ERD QUY DOI VA MO TA CAC THUC THE' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Phan nay quy doi cac thuc the chinh trong he thong thanh cac bang mo ta de phuc vu trinh bay ERD va giai thich cau truc du lieu. Moi thuc the duoc trinh bay thanh mot bang rieng de de quan sat, de chen vao bao cao va de doi chieu voi thiet ke co so du lieu.' -FontSize 12 -Alignment 3 -SpaceAfter 10

    foreach ($entity in $entities) {
        Add-EntityTable -Doc $doc -EntityName $entity.Name -Fields $entity.Fields -Description $entity.Description
    }

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
