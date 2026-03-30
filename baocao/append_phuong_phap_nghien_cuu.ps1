$ErrorActionPreference = 'Stop'

$docPath = "C:\Users\admin\Documents\VS\app\baocao\loi_cam_doan_loi_cam_on_va_tu_viet_tat.docx"
$outputPath = "C:\Users\admin\Documents\VS\app\baocao\loi_cam_doan_loi_cam_on_tu_viet_tat_va_phuong_phap_nghien_cuu.docx"

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

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Open($docPath)

    Add-Paragraph -Doc $doc -Text 'PHƯƠNG PHÁP NGHIÊN CỨU' -FontSize 15 -Bold $true -Alignment 1 -SpaceAfter 10
    Add-Paragraph -Doc $doc -Text 'Trong quá trình thực hiện đề tài, nhóm TRACKER sử dụng kết hợp nhiều phương pháp nghiên cứu nhằm bảo đảm sản phẩm được xây dựng có cơ sở, có định hướng rõ ràng và bám sát yêu cầu thực tiễn. Trước hết, nhóm áp dụng phương pháp nghiên cứu tài liệu để tìm hiểu các kiến thức nền liên quan đến quản lý tài chính cá nhân, phát triển ứng dụng đa nền tảng bằng Flutter, cơ sở dữ liệu Firebase Firestore, cơ chế xác thực người dùng, cũng như các kỹ thuật xử lý ngôn ngữ tự nhiên và nhận diện văn bản từ ảnh. Việc tham khảo tài liệu chính thống giúp nhóm lựa chọn được công nghệ phù hợp và giảm rủi ro trong quá trình triển khai.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Bên cạnh đó, nhóm sử dụng phương pháp phân tích và thiết kế hệ thống để xác định các tác nhân, chức năng, luồng xử lý dữ liệu, thực thể dữ liệu và mối quan hệ giữa các thành phần trong hệ thống. Từ quá trình phân tích yêu cầu, nhóm xây dựng các sơ đồ use case, activity, ERD quy đổi và đặc tả các chức năng chính cho hai phân hệ User và Admin. Đây là cơ sở để chuyển từ ý tưởng nghiệp vụ sang thiết kế có thể cài đặt được bằng mã nguồn.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Ngoài ra, nhóm còn áp dụng phương pháp thực nghiệm thông qua quá trình xây dựng, chạy thử, kiểm thử và đánh giá hệ thống trên các luồng chức năng quan trọng như đăng nhập, thêm giao dịch, AI parser, quản lý ngân sách, báo cáo và quản trị hệ thống. Trong quá trình này, nhóm quan sát kết quả thực tế, đối chiếu với yêu cầu đề ra và điều chỉnh dần sản phẩm để đạt mức hoàn thiện tốt hơn. Sự kết hợp giữa nghiên cứu tài liệu, phân tích thiết kế và thực nghiệm triển khai đã giúp nhóm hình thành được một hệ thống có tính ứng dụng, đồng thời phù hợp với mục tiêu của đồ án.' -Alignment 3

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
