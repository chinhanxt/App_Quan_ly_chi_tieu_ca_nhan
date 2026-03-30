$ErrorActionPreference = 'Stop'

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\chuong_7_ket_luan.docx"

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

$references = @(
    '1. Flutter Documentation. https://docs.flutter.dev/ (truy cập ngày 30/03/2026).',
    '2. Dart Documentation. https://dart.dev/ (truy cập ngày 30/03/2026).',
    '3. Firebase Documentation. https://firebase.google.com/docs/ (truy cập ngày 30/03/2026).',
    '4. Cloud Firestore - Firebase. https://firebase.google.com/products/firestore (truy cập ngày 30/03/2026).',
    '5. Provider package on pub.dev. https://pub.dev/packages/provider (truy cập ngày 30/03/2026).',
    '6. fl_chart package on pub.dev. https://pub.dev/packages/fl_chart (truy cập ngày 30/03/2026).',
    '7. pdf package on pub.dev. https://pub.dev/packages/pdf (truy cập ngày 30/03/2026).',
    '8. printing package on pub.dev. https://pub.dev/packages/printing (truy cập ngày 30/03/2026).',
    '9. image_picker package on pub.dev. https://pub.dev/packages/image_picker (truy cập ngày 30/03/2026).',
    '10. google_mlkit_text_recognition package on pub.dev. https://pub.dev/packages/google_mlkit_text_recognition (truy cập ngày 30/03/2026).',
    '11. permission_handler package on pub.dev. https://pub.dev/packages/permission_handler (truy cập ngày 30/03/2026).',
    '12. share_plus package on pub.dev. https://pub.dev/packages/share_plus (truy cập ngày 30/03/2026).',
    '13. open_filex package on pub.dev. https://pub.dev/packages/open_filex (truy cập ngày 30/03/2026).',
    '14. email_otp package on pub.dev. https://pub.dev/packages/email_otp (truy cập ngày 30/03/2026).',
    '15. http package on pub.dev. https://pub.dev/packages/http (truy cập ngày 30/03/2026).'
)

$word = $null
$doc = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()

    Add-Paragraph -Doc $doc -Text 'CHƯƠNG 7. KẾT LUẬN' -FontSize 16 -Bold $true -Alignment 1 -SpaceAfter 12

    Add-Paragraph -Doc $doc -Text '7.1. Kết quả đạt được' -FontSize 14 -Bold $true -SpaceAfter 8
    Add-Paragraph -Doc $doc -Text 'Nhìn tổng thể, hệ thống đã đi xa hơn một ứng dụng CRUD cơ bản. Đề tài đã xây dựng được một sản phẩm có tính định hướng thực tế, hỗ trợ quản lý tài chính cá nhân trên nền tảng Flutter, kết hợp dữ liệu thời gian thực với Firebase, tích hợp AI để giảm thao tác nhập liệu, đồng thời có thêm phân hệ quản trị web phục vụ giám sát và điều hành hệ thống.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Về mặt chức năng, hệ thống đã hoàn thiện các nhóm nghiệp vụ quan trọng như xác thực và phân quyền, quản lý giao dịch thu chi, nhập liệu thông minh bằng AI, quản lý ngân sách, báo cáo thống kê, mục tiêu tiết kiệm và quản trị hệ thống. Việc tổ chức code theo các nhóm screens, widgets, services, models, providers và admin_web cũng cho thấy dự án được xây dựng theo hướng có cấu trúc, thuận lợi cho mở rộng và bảo trì.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Điểm nổi bật nhất của đề tài là đã thể hiện được yếu tố thông minh và giá trị khác biệt so với các ứng dụng ghi chép truyền thống. Người dùng không chỉ nhập giao dịch bằng form thủ công mà còn có thể sử dụng câu lệnh tự nhiên, ảnh hóa đơn và các luồng realtime để tương tác với hệ thống. Ở phía quản trị, admin có thể theo dõi dashboard tổng quan, khóa người dùng, quản lý danh mục, broadcast và cấu hình AI runtime. Đây là các yếu tố rất đáng nhấn mạnh khi đánh giá kết quả cuối cùng của đồ án.' -Alignment 3

    Add-Paragraph -Doc $doc -Text '7.2. Hạn chế của hệ thống' -FontSize 14 -Bold $true -SpaceAfter 8
    Add-Paragraph -Doc $doc -Text 'Mặc dù đã đạt được nhiều kết quả tích cực, hệ thống vẫn còn một số hạn chế cần nhìn nhận rõ. Thứ nhất, độ chính xác của AI và OCR vẫn phụ thuộc vào chất lượng dữ liệu đầu vào. Với các câu quá mơ hồ, quá ngắn hoặc chứa nhiều ngữ cảnh thời gian phức tạp, hệ thống vẫn có thể cần hỏi lại người dùng trước khi lưu. Tương tự, chức năng nhận diện văn bản từ ảnh phụ thuộc vào độ rõ của hóa đơn, góc chụp và ánh sáng.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Thứ hai, phân hệ admin web hiện được thiết kế cho ngữ cảnh chạy trên trình duyệt, chưa tối ưu cho các nền tảng desktop native. Ngoài ra, một số gói thư viện tích hợp như nhận diện văn bản bằng ML Kit hoặc xác thực OTP qua email còn chịu ràng buộc bởi giới hạn nền tảng, cấu hình môi trường hoặc yêu cầu SMTP/permission cụ thể.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Thứ ba, hệ thống hiện tập trung mạnh vào luồng nghiệp vụ và trải nghiệm tính năng, nhưng chưa đi sâu vào các khía cạnh sản phẩm ở mức triển khai thực tế quy mô lớn như giám sát logging tập trung, phân tích hiệu năng sâu, kiểm thử tự động diện rộng, tối ưu truy vấn dữ liệu lớn hoặc bảo vệ nâng cao trước các tình huống lạm dụng dịch vụ AI.' -Alignment 3

    Add-Paragraph -Doc $doc -Text '7.3. Hướng phát triển' -FontSize 14 -Bold $true -SpaceAfter 8
    Add-Paragraph -Doc $doc -Text 'Trong tương lai, hệ thống có thể được mở rộng theo nhiều hướng có giá trị thực tiễn cao. Trước hết, nhóm có thể nâng cấp tính năng OCR và AI parser để hiểu tốt hơn các hóa đơn nhiều dòng, tiếng Việt không dấu, viết tắt, câu hội thoại nhiều bước hoặc ngữ cảnh thời gian phức tạp. Việc bổ sung cơ chế học theo thói quen người dùng cũng có thể giúp tăng độ chính xác phân loại danh mục.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Một hướng phát triển quan trọng khác là mở rộng từ quản lý thu chi sang hỗ trợ ra quyết định tài chính, ví dụ gợi ý tiết kiệm theo thu nhập, dự báo xu hướng chi tiêu, cảnh báo rủi ro vượt ngân sách sớm hoặc gợi ý điều chỉnh kế hoạch tài chính cá nhân. Hệ thống cũng có thể bổ sung nhiều hình thức nhập liệu mới như quét hóa đơn tốt hơn, import sao kê hoặc đồng bộ từ ví điện tử và tài khoản ngân hàng nếu có điều kiện tích hợp phù hợp.' -Alignment 3
    Add-Paragraph -Doc $doc -Text 'Đối với phân hệ quản trị, có thể phát triển thêm các tính năng như phân quyền admin nhiều cấp, nhật ký thao tác chi tiết, cấu hình luật kiểm duyệt tự động, dashboard phân tích nâng cao và cơ chế giám sát realtime sâu hơn cho AI runtime. Nếu tiếp tục đầu tư, đề tài có thể tiến dần từ đồ án học phần sang một sản phẩm thử nghiệm có khả năng ứng dụng thực tế.' -Alignment 3

    Add-Paragraph -Doc $doc -Text '7.4. Tài liệu tham khảo' -FontSize 14 -Bold $true -SpaceAfter 8
    Add-Paragraph -Doc $doc -Text 'Danh mục dưới đây ưu tiên các nguồn chính thống như tài liệu chính thức của Flutter, Dart, Firebase và các trang package công khai trên pub.dev. Không sử dụng nguồn tổng hợp không rõ xuất xứ hoặc nội dung do AI tự tạo làm tài liệu tham khảo.' -Alignment 3

    foreach ($ref in $references) {
        Add-Paragraph -Doc $doc -Text $ref -FontSize 12 -SpaceAfter 4
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
